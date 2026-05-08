"""
网络请求查看器。
"""
import json
import time
import uuid
from datetime import datetime
from urllib.parse import urlparse

from PySide6.QtCore import (
    QAbstractListModel,
    QByteArray,
    QModelIndex,
    QObject,
    Property,
    Qt,
    Signal,
    Slot,
)


class NetworkLogModel(QAbstractListModel):
    """给 QML 使用的网络请求列表模型。"""

    countChanged = Signal()

    _ROLE_NAMES = [
        "requestId",
        "method",
        "url",
        "host",
        "path",
        "state",
        "success",
        "statusCode",
        "statusText",
        "elapsedText",
        "startedAtText",
        "fullStartedAtText",
        "requestHeadersText",
        "requestBodyText",
        "responseHeadersText",
        "responseBodyText",
        "responseSizeText",
        "contentType",
        "errorMessage",
        "title",
        "subtitle",
    ]
    _ROLE_KEYS = {
        Qt.ItemDataRole.UserRole.value + index: name
        for index, name in enumerate(_ROLE_NAMES)
    }

    def __init__(self, max_records: int = 200, parent=None):
        super().__init__(parent)
        self._entries = []
        self._max_records = max(1, int(max_records or 200))

    def rowCount(self, parent=QModelIndex()):
        if parent.isValid():
            return 0
        return len(self._entries)

    def data(self, index, role=Qt.ItemDataRole.DisplayRole):
        if not index.isValid():
            return None

        row = index.row()
        if row < 0 or row >= len(self._entries):
            return None

        key = self._ROLE_KEYS.get(role)
        if not key:
            return None

        return self._entries[row].get(key, "")

    def roleNames(self):
        return {
            role: QByteArray(name.encode("utf-8"))
            for role, name in self._ROLE_KEYS.items()
        }

    @property
    def count(self) -> int:
        return len(self._entries)

    def contains(self, request_id: str) -> bool:
        request_id = str(request_id or "")
        return any(entry.get("requestId") == request_id for entry in self._entries)

    def clear(self) -> None:
        if not self._entries:
            return

        self.beginResetModel()
        self._entries.clear()
        self.endResetModel()
        self.countChanged.emit()

    def add_request(self, payload: dict) -> str:
        entry = self._build_start_entry(payload)

        self.beginInsertRows(QModelIndex(), 0, 0)
        self._entries.insert(0, entry)
        self.endInsertRows()
        self.countChanged.emit()

        if len(self._entries) > self._max_records:
            first_remove_row = self._max_records
            last_remove_row = len(self._entries) - 1
            self.beginRemoveRows(QModelIndex(), first_remove_row, last_remove_row)
            del self._entries[first_remove_row:]
            self.endRemoveRows()
            self.countChanged.emit()

        return entry["requestId"]

    def finish_request(self, payload: dict) -> bool:
        request_id = str(payload.get("request_id") or payload.get("requestId") or uuid.uuid4().hex)
        if not request_id:
            return False

        for row, entry in enumerate(self._entries):
            if entry.get("requestId") != request_id:
                continue

            entry.update(self._build_finish_fields(payload))
            changed_index = self.index(row, 0)
            self.dataChanged.emit(
                changed_index,
                changed_index,
                list(self._ROLE_KEYS.keys()),
            )
            return True

        return False

    def _build_start_entry(self, payload: dict) -> dict:
        request_id = str(payload.get("request_id") or payload.get("requestId") or "")
        method = str(payload.get("method", "") or "").upper()
        url = str(payload.get("url", "") or "")
        parsed_url = urlparse(url)
        started_at = _as_float(
            payload.get("started_at") or payload.get("startedAt"),
            time.time(),
        )
        started_datetime = datetime.fromtimestamp(started_at)
        request_body = payload.get("body")
        request_headers = payload.get("headers") or {}

        return {
            "requestId": request_id,
            "method": method,
            "url": url,
            "host": parsed_url.netloc,
            "path": parsed_url.path or "/",
            "state": "请求中",
            "success": False,
            "statusCode": "",
            "statusText": "请求中",
            "elapsedText": "-",
            "startedAtText": started_datetime.strftime("%H:%M:%S"),
            "fullStartedAtText": started_datetime.strftime("%Y-%m-%d %H:%M:%S"),
            "requestHeadersText": _format_value(request_headers),
            "requestBodyText": _format_value(request_body),
            "responseHeadersText": "",
            "responseBodyText": "",
            "responseSizeText": "-",
            "contentType": "",
            "errorMessage": "",
            "title": f"{method} {parsed_url.path or url}",
            "subtitle": parsed_url.netloc or url,
        }

    def _build_finish_fields(self, payload: dict) -> dict:
        response_headers = payload.get("response_headers") or payload.get("responseHeaders") or {}
        response_body = payload.get("response_body")
        if response_body is None:
            response_body = payload.get("responseBody")
        status_code = payload.get("status_code") or payload.get("statusCode") or ""
        reason = str(payload.get("reason", "") or "").strip()
        elapsed_ms = _as_float(
            payload.get("elapsed_ms") or payload.get("elapsedMs"),
            0.0,
        )
        error_message = str(payload.get("error_message") or payload.get("errorMessage") or "")
        success = bool(payload.get("success", False))

        if status_code:
            status_text = f"{status_code} {reason}".strip()
        elif error_message:
            status_text = "请求异常"
        else:
            status_text = "未完成"

        return {
            "state": "成功" if success else "失败",
            "success": success,
            "statusCode": str(status_code),
            "statusText": status_text,
            "elapsedText": _format_elapsed(elapsed_ms),
            "responseHeadersText": _format_value(response_headers),
            "responseBodyText": _format_value(response_body),
            "responseSizeText": _format_size(response_body),
            "contentType": _header_value(response_headers, "content-type"),
            "errorMessage": error_message,
        }


class NetworkInspector(QObject):
    """记录网络请求并向 QML 暴露列表模型。"""

    enabledChanged = Signal()
    countChanged = Signal()

    def __init__(self, parent=None, max_records: int = 200):
        super().__init__(parent)
        self._enabled = False
        self._model = NetworkLogModel(max_records=max_records, parent=self)
        self._model.countChanged.connect(self.countChanged.emit)

    @Property(bool, notify=enabledChanged)
    def enabled(self):
        return self._enabled

    @enabled.setter
    def enabled(self, value):
        next_value = bool(value)
        if self._enabled == next_value:
            return

        self._enabled = next_value
        self.enabledChanged.emit()

    @Property(QObject, constant=True)
    def logModel(self):
        return self._model

    @Property(int, notify=countChanged)
    def count(self):
        return self._model.count

    @Slot(bool)
    def setEnabled(self, enabled):
        """设置调试入口是否显示，不影响请求记录。"""
        self.enabled = enabled

    @Slot()
    def clear(self):
        """清空已记录的请求。"""
        self._model.clear()

    def record_request_started(self, payload: dict) -> None:
        """记录请求开始。"""
        self._model.add_request(payload or {})

    def record_request_finished(self, payload: dict) -> None:
        """记录请求结束。"""
        payload = payload or {}
        self._model.finish_request(payload)


def _as_float(value, fallback: float) -> float:
    try:
        return float(value)
    except (TypeError, ValueError):
        return fallback


def _format_value(value) -> str:
    if value is None or value == "":
        return ""

    if isinstance(value, bytes):
        try:
            value = value.decode("utf-8")
        except UnicodeDecodeError:
            return value.decode("utf-8", errors="replace")

    if isinstance(value, str):
        text = value.strip()
        if not text:
            return ""
        if text.startswith("{") or text.startswith("["):
            try:
                parsed = json.loads(text)
                return json.dumps(parsed, ensure_ascii=False, indent=2)
            except json.JSONDecodeError:
                return value
        return value

    try:
        return json.dumps(value, ensure_ascii=False, indent=2, default=str)
    except TypeError:
        return str(value)


def _format_elapsed(elapsed_ms: float) -> str:
    if elapsed_ms <= 0:
        return "-"
    if elapsed_ms < 1000:
        return f"{elapsed_ms:.0f} ms"
    return f"{elapsed_ms / 1000:.2f} s"


def _format_size(value) -> str:
    if value is None:
        return "-"

    if isinstance(value, bytes):
        size = len(value)
    else:
        size = len(str(value).encode("utf-8"))

    if size < 1024:
        return f"{size} B"
    return f"{size / 1024:.1f} KB"


def _header_value(headers: dict, name: str) -> str:
    if not isinstance(headers, dict):
        return ""

    expected = name.lower()
    for key, value in headers.items():
        if str(key).lower() == expected:
            return str(value)
    return ""
