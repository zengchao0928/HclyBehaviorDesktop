#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
行为记录页面控制器。
"""
from __future__ import annotations

import json
from datetime import datetime

from PySide6.QtCore import QObject, Property, QTimer, Signal, Slot

from src.api.behavior_api import BehaviorApi
from src.config.settings import API_BASE_URL
from src.core.image_cache import ImageCache
from src.utils.exception_handler import fatal_slot


class BehaviorController(QObject):
    """行为记录页面控制器。"""

    dataChanged = Signal()
    timeChanged = Signal()
    loadingChanged = Signal(bool)
    toastRequested = Signal(str, str)

    def __init__(self):
        super().__init__()
        self._api = BehaviorApi()
        self._api.requestFinished.connect(self._on_request_finished)
        self._image_cache = ImageCache()
        self._image_cache.imageReady.connect(self._on_image_ready)

        self._current_time = self._format_current_time()
        self._liens = []
        self._actions = []
        self._records = []
        self._matters = []
        self._goods = []
        self._selected_lien_index = 0
        self._selected_title_index = 0
        self._selected_content = {}
        self._remark = ""
        self._page = 1
        self._page_size = 20
        self._loading = False
        self._startup_queue = []
        self._pending_dialog_type = ""

        self._timer = QTimer(self)
        self._timer.setInterval(1000)
        self._timer.timeout.connect(self._tick)
        self._timer.start()

    @Property(str, notify=timeChanged)
    def currentTime(self):
        """当前时间。"""
        return self._current_time

    @Property(str, notify=timeChanged)
    def currentDateText(self):
        """当前日期标题。"""
        return self._current_time.split(" ")[0] if self._current_time else ""

    @Property("QVariantList", notify=dataChanged)
    def liens(self):
        """留置对象列表。"""
        return self._liens

    @Property("QVariantList", notify=dataChanged)
    def actions(self):
        """行为分类列表。"""
        return self._actions

    @Property("QVariantList", notify=dataChanged)
    def currentContents(self):
        """当前分类下的行为项。"""
        if not self._actions:
            return []
        if self._selected_title_index < 0 or self._selected_title_index >= len(self._actions):
            return []
        return self._actions[self._selected_title_index].get("content", [])

    @Property("QVariantList", notify=dataChanged)
    def records(self):
        """当前对象的行为记录。"""
        return self._records

    @Property("QVariantList", notify=dataChanged)
    def matters(self):
        """事项列表。"""
        return self._matters

    @Property("QVariantList", notify=dataChanged)
    def goods(self):
        """物品列表。"""
        return self._goods

    @Property(int, notify=dataChanged)
    def selectedLienIndex(self):
        """当前选中的对象索引。"""
        return self._selected_lien_index

    @Property(int, notify=dataChanged)
    def selectedTitleIndex(self):
        """当前选中的行为分类索引。"""
        return self._selected_title_index

    @Property("QVariant", notify=dataChanged)
    def selectedContent(self):
        """当前选中的行为项。"""
        return self._selected_content

    @Property(str, notify=dataChanged)
    def selectedContentName(self):
        """当前选中的行为名称。"""
        return self._selected_content.get("name", "")

    @Property(str, notify=dataChanged)
    def selectedContentIconUrl(self):
        """当前选中的行为图标地址。"""
        return self._selected_content.get("localIconUrl") or self._selected_content.get("iconUrl", "")

    @Property(str, notify=dataChanged)
    def selectedLienCodeText(self):
        """当前选中的对象代号文案。"""
        if not self._liens:
            return ""
        lien = self._liens[self._selected_lien_index]
        return f"选中的对象代号：{lien.get('code', '')}"

    @Property(str, notify=dataChanged)
    def remark(self):
        """备注内容。"""
        return self._remark

    @Property(bool, notify=dataChanged)
    def hasMoreRecords(self):
        """是否可能还有更多记录。"""
        return len(self._records) >= self._page * self._page_size

    @Property(str, constant=True)
    def baseUrl(self):
        """接口基础地址。"""
        return API_BASE_URL.rstrip("/")

    def _format_current_time(self) -> str:
        return datetime.now().strftime("%Y年%m月%d日 %H:%M:%S")

    def _tick(self):
        self._current_time = self._format_current_time()
        self.timeChanged.emit()

    def _set_loading(self, loading: bool):
        if self._loading == loading:
            return
        self._loading = loading
        self.loadingChanged.emit(loading)

    def _parse_response(self, success, response):
        if not success:
            self.toastRequested.emit(str(response or "请求失败"), "error")
            return None

        try:
            payload = json.loads(response) if isinstance(response, str) else dict(response)
        except Exception:
            self.toastRequested.emit("服务器返回数据格式错误", "error")
            return None

        try:
            code = int(payload.get("code"))
        except (TypeError, ValueError):
            code = None

        if code != 0:
            self.toastRequested.emit(str(payload.get("msg") or "请求失败"), "error")
            return None

        return payload.get("data")

    def _normalize_lien(self, item):
        item = item if isinstance(item, dict) else {}
        room = item.get("room") if isinstance(item.get("room"), dict) else {}
        return {
            "id": str(item.get("id") or ""),
            "code": str(item.get("code") or ""),
            "faceImg": str(item.get("faceImg") or ""),
            "faceUrl": self.absoluteUrl(item.get("faceImg") or ""),
            "localFaceUrl": "",
            "roomName": str(room.get("name") or ""),
        }

    def _normalize_content(self, item):
        item = item if isinstance(item, dict) else {}
        return {
            "id": str(item.get("id") or ""),
            "name": str(item.get("name") or ""),
            "type": str(item.get("type") or ""),
            "icon": str(item.get("icon") or ""),
            "iconUrl": self.absoluteUrl(item.get("icon") or ""),
            "localIconUrl": "",
            "checkedIcon": str(item.get("checkedIcon") or ""),
            "createTime": str(item.get("createTime") or ""),
            "createBy": str(item.get("createBy") or ""),
            "remark": item.get("remark") or "",
        }

    def _normalize_action(self, item):
        item = item if isinstance(item, dict) else {}
        contents = item.get("content") if isinstance(item.get("content"), list) else []
        return {
            "name": str(item.get("name") or ""),
            "content": [self._normalize_content(content) for content in contents],
        }

    def _normalize_record(self, item):
        item = item if isinstance(item, dict) else {}
        create_time = str(item.get("createTime") or "")
        time_text = create_time.split(" ")[1] if " " in create_time else create_time
        return {
            "id": str(item.get("id") or ""),
            "lienId": str(item.get("lienId") or ""),
            "content": str(item.get("content") or ""),
            "createTime": create_time,
            "timeText": time_text,
        }

    def _normalize_matter(self, item):
        item = item if isinstance(item, dict) else {}
        return {
            "id": str(item.get("id") or ""),
            "name": str(item.get("name") or ""),
            "icon": str(item.get("icon") or ""),
            "iconUrl": self.absoluteUrl(item.get("icon") or ""),
            "localIconUrl": "",
            "processId": str(item.get("processId") or ""),
            "createTime": str(item.get("createTime") or ""),
            "createBy": str(item.get("createBy") or ""),
            "remark": str(item.get("remark") or ""),
        }

    def _cache_lien_images(self):
        jobs = [("lien", lien.get("id", ""), lien.get("faceUrl", "")) for lien in self._liens]
        self._image_cache.request_images(jobs)

    def _cache_action_images(self):
        jobs = []
        for action in self._actions:
            for content in action.get("content", []):
                jobs.append(("content", content.get("id", ""), content.get("iconUrl", "")))
        self._image_cache.request_images(jobs)

    def _cache_apply_images(self, kind, items):
        jobs = [(kind, item.get("id", ""), item.get("iconUrl", "")) for item in items]
        self._image_cache.request_images(jobs)

    def _selected_lien_id(self) -> str:
        if not self._liens:
            return ""
        return self._liens[self._selected_lien_index].get("id", "")

    def _request_records(self, page: int = 1):
        lien_id = self._selected_lien_id()
        if not lien_id:
            self._records = []
            self._page = 1
            self._set_loading(False)
            self.dataChanged.emit()
            return

        self._page = max(1, int(page or 1))
        self._api.get_records(lien_id, self._page, self._page_size)

    def _load_next_startup_request(self):
        if not self._startup_queue:
            self._request_records(1)
            return

        next_request = self._startup_queue.pop(0)
        if next_request == "liens":
            self._api.get_liens()
        elif next_request == "actions":
            self._api.get_actions()

    @Slot()
    @fatal_slot
    def requestData(self):
        """刷新基础数据。"""
        self._set_loading(True)
        self._startup_queue = ["liens", "actions"]
        self._load_next_startup_request()

    @Slot()
    @fatal_slot
    def refreshRecords(self):
        """刷新当前对象记录。"""
        self._set_loading(True)
        self._request_records(1)

    @Slot()
    @fatal_slot
    def loadMoreRecords(self):
        """加载更多行为记录。"""
        if not self._liens:
            self._set_loading(False)
            return
        self._set_loading(True)
        self._request_records(self._page + 1)

    @Slot(int)
    @fatal_slot
    def selectLienInfo(self, index):
        """选择留置对象。"""
        if index < 0 or index >= len(self._liens):
            return
        self._selected_lien_index = index
        self.dataChanged.emit()
        self.refreshRecords()

    @Slot(int)
    @fatal_slot
    def selectTitle(self, index):
        """选择行为分类。"""
        if index < 0 or index >= len(self._actions):
            return
        self._selected_title_index = index
        self.dataChanged.emit()

    @Slot("QVariant")
    @fatal_slot
    def selectBehaviour(self, content):
        """选择行为项。"""
        if not isinstance(content, dict):
            return
        self._selected_content = dict(content)
        self._remark = self._selected_content.get("name", "")
        self.dataChanged.emit()

    @Slot(str)
    @fatal_slot
    def setRemark(self, remark):
        """设置备注内容。"""
        self._remark = str(remark or "")
        self.dataChanged.emit()

    @Slot()
    @fatal_slot
    def addActionRecord(self):
        """提交行为记录。"""
        remark = self._remark.strip()
        lien_id = self._selected_lien_id()
        if not remark:
            self.toastRequested.emit("请选择下面行为", "error")
            return
        if not lien_id:
            self.toastRequested.emit("请选择留置对象", "error")
            return

        self._set_loading(True)
        self._api.add_action_record(lien_id, remark)

    @Slot(str)
    @fatal_slot
    def openApplyDialog(self, dialog_type):
        """打开申请弹窗并加载对应列表。"""
        normalized = str(dialog_type or "")
        if normalized not in {"matter", "goods"}:
            return

        self._pending_dialog_type = normalized
        self._set_loading(True)
        if normalized == "matter":
            self._api.get_matter_list()
        else:
            self._api.get_goods_list()

    @Slot(str)
    @fatal_slot
    def applyMatter(self, matter_id):
        """提交事项申请。"""
        lien_id = self._selected_lien_id()
        if not lien_id:
            self.toastRequested.emit("请选择留置对象", "error")
            return
        matter = self._find_item(self._matters, matter_id)
        if not matter:
            self.toastRequested.emit("请选择事项", "error")
            return

        self._set_loading(True)
        self._api.add_lien_apply_matter(lien_id, matter["id"], matter.get("remark", ""))

    @Slot(str, int)
    @fatal_slot
    def applyGoods(self, goods_id, count):
        """提交物品申请。"""
        lien_id = self._selected_lien_id()
        if not lien_id:
            self.toastRequested.emit("请选择留置对象", "error")
            return
        goods = self._find_item(self._goods, goods_id)
        if not goods:
            self.toastRequested.emit("请选择物品", "error")
            return

        self._set_loading(True)
        self._api.add_lien_apply_goods(lien_id, goods["id"], count, goods.get("remark", ""))

    def _find_item(self, items, item_id):
        item_id = str(item_id or "")
        for item in items:
            if item.get("id") == item_id:
                return item
        return None

    @Slot(str, result=str)
    def absoluteUrl(self, path):
        """把接口返回的相对资源地址转成完整 URL。"""
        value = str(path or "")
        if not value:
            return ""
        if value.startswith(("http://", "https://", "file:")):
            return value
        return API_BASE_URL.rstrip("/") + "/" + value.lstrip("/")

    def _on_request_finished(self, request_name, success, response):
        data = self._parse_response(success, response)
        if data is None:
            self._set_loading(False)
            return

        if request_name == "liens":
            source = data if isinstance(data, list) else []
            self._liens = [self._normalize_lien(item) for item in source]
            if self._selected_lien_index >= len(self._liens):
                self._selected_lien_index = 0
            self._cache_lien_images()
            self.dataChanged.emit()
            self._load_next_startup_request()
            return

        if request_name == "actions":
            source = data if isinstance(data, list) else []
            self._actions = [self._normalize_action(item) for item in source]
            self._selected_title_index = 0
            if not self._actions:
                self._selected_content = {}
                self._remark = ""
            self._cache_action_images()
            self.dataChanged.emit()
            self._load_next_startup_request()
            return

        if request_name == "records":
            source = data if isinstance(data, list) else []
            records = [self._normalize_record(item) for item in source]
            if self._page <= 1:
                self._records = records
            else:
                self._records.extend(records)
            self._set_loading(False)
            self.dataChanged.emit()
            return

        if request_name == "add_record":
            record = self._normalize_record(data if isinstance(data, dict) else {})
            if record.get("id") or record.get("content"):
                self._records.insert(0, record)
            self._set_loading(False)
            self.toastRequested.emit("提交成功", "success")
            self.dataChanged.emit()
            return

        if request_name == "matters":
            source = data if isinstance(data, list) else []
            self._matters = [self._normalize_matter(item) for item in source]
            self._cache_apply_images("matter", self._matters)
            self._set_loading(False)
            self.dataChanged.emit()
            return

        if request_name == "goods":
            source = data if isinstance(data, list) else []
            self._goods = [self._normalize_matter(item) for item in source]
            self._cache_apply_images("goods", self._goods)
            self._set_loading(False)
            self.dataChanged.emit()
            return

        if request_name in {"apply_matter", "apply_goods"}:
            self._set_loading(False)
            self.toastRequested.emit("申请成功", "success")
            self.dataChanged.emit()
            return

        self._set_loading(False)

    def _on_image_ready(self, kind, item_id, local_url):
        item_id = str(item_id or "")
        local_url = str(local_url or "")
        changed = False

        if kind == "lien":
            for lien in self._liens:
                if lien.get("id") == item_id:
                    lien["localFaceUrl"] = local_url
                    changed = True
                    break
        elif kind == "content":
            for action in self._actions:
                for content in action.get("content", []):
                    if content.get("id") == item_id:
                        content["localIconUrl"] = local_url
                        if self._selected_content.get("id") == item_id:
                            self._selected_content = dict(content)
                        changed = True
                        break
                if changed:
                    break
        elif kind == "matter":
            for matter in self._matters:
                if matter.get("id") == item_id:
                    matter["localIconUrl"] = local_url
                    changed = True
                    break
        elif kind == "goods":
            for goods in self._goods:
                if goods.get("id") == item_id:
                    goods["localIconUrl"] = local_url
                    changed = True
                    break

        if changed:
            self.dataChanged.emit()
