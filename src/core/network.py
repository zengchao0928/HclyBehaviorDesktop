#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
网络请求模块。
"""
from __future__ import annotations

import json
import logging
from urllib.parse import urlparse
from urllib.parse import urljoin

import requests
from PySide6.QtCore import QObject, QThread, Signal, Slot

from src.config.settings import API_CONNECT_TIMEOUT, API_TIMEOUT


_logger = logging.getLogger(__name__)
_SENSITIVE_LOG_KEYS = (
    "authorization",
    "password",
    "passwd",
    "token",
    "secret",
    "access_token",
    "refresh_token",
    "userPwd",
)

_NO_PROXY_PREFIXES = (
    "10.",
    "172.16.",
    "172.17.",
    "172.18.",
    "172.19.",
    "172.20.",
    "172.21.",
    "172.22.",
    "172.23.",
    "172.24.",
    "172.25.",
    "172.26.",
    "172.27.",
    "172.28.",
    "172.29.",
    "172.30.",
    "172.31.",
    "192.168.",
    "127.",
)
_NO_PROXY_HOSTS = {"localhost", "::1"}


def _should_bypass_proxy(url: str) -> bool:
    """判断内网地址是否需要绕过系统/环境代理。"""
    host = urlparse(url).hostname or ""
    if not host:
        return False
    if host in _NO_PROXY_HOSTS or host.endswith(".local"):
        return True
    return any(host.startswith(prefix) for prefix in _NO_PROXY_PREFIXES)


def _redact_sensitive(value):
    """递归脱敏网络日志中的敏感字段。"""
    if isinstance(value, dict):
        if {"code", "data"}.issubset(value.keys()) and isinstance(value.get("data"), str):
            value = dict(value)
            value["data"] = "***"

        redacted = {}
        for key, item in value.items():
            key_text = str(key).lower()
            if any(sensitive_key.lower() in key_text for sensitive_key in _SENSITIVE_LOG_KEYS):
                redacted[key] = "***"
            else:
                redacted[key] = _redact_sensitive(item)
        return redacted

    if isinstance(value, list):
        return [_redact_sensitive(item) for item in value]

    return value


def _format_log_value(value, max_chars: int = 3000) -> str:
    """把网络请求/响应内容转成适合日志的短文本。"""
    if value is None or value == "":
        return ""

    redacted_value = _redact_sensitive(value)
    if isinstance(redacted_value, str):
        text = redacted_value.strip()
        if text.startswith("{") or text.startswith("["):
            try:
                parsed = json.loads(text)
                text = json.dumps(_redact_sensitive(parsed), ensure_ascii=False)
            except json.JSONDecodeError:
                pass
    else:
        text = json.dumps(redacted_value, ensure_ascii=False, default=str)

    if len(text) > max_chars:
        return f"{text[:max_chars]}...(已截断)"
    return text


class NetworkWorker(QThread):
    """网络请求工作线程。"""

    requestFinished = Signal(bool, str)

    def __init__(self, method, url, data=None, use_json=True, headers=None, timeout=None):
        super().__init__()
        self.method = str(method or "GET").upper()
        self.url = str(url or "")
        self.data = data
        self.use_json = use_json
        self.headers = headers or {}
        self.timeout = timeout or API_TIMEOUT
        self.bypass_proxy = _should_bypass_proxy(self.url)

    def run(self):
        """在子线程中执行网络请求。"""
        try:
            timeout_tuple = (API_CONNECT_TIMEOUT, self.timeout)
            session = requests.Session()
            if self.bypass_proxy:
                # requests 默认会读取 HTTP_PROXY/ALL_PROXY 等环境变量；内网地址需要显式禁用。
                session.trust_env = False
                proxies = {"http": None, "https": None}
            else:
                proxies = None

            _logger.info(
                "网络请求开始: method=%s url=%s bypass_proxy=%s headers=%s body=%s",
                self.method,
                self.url,
                self.bypass_proxy,
                _format_log_value(self.headers),
                _format_log_value(self.data),
            )

            if self.method == "POST":
                if self.use_json:
                    response = session.post(
                        self.url,
                        json=self.data,
                        headers=self.headers,
                        timeout=timeout_tuple,
                        proxies=proxies,
                    )
                else:
                    response = session.post(
                        self.url,
                        data=self.data,
                        headers=self.headers,
                        timeout=timeout_tuple,
                        proxies=proxies,
                    )
            elif self.method == "GET":
                response = session.get(
                    self.url,
                    params=self.data,
                    headers=self.headers,
                    timeout=timeout_tuple,
                    proxies=proxies,
                )
            else:
                raise ValueError(f"不支持的请求方法: {self.method}")

            success = response.status_code == 200
            response_body = response.text
            log_method = _logger.info if success else _logger.warning
            log_method(
                "网络请求完成: method=%s url=%s success=%s status=%s response=%s",
                self.method,
                self.url,
                success,
                response.status_code,
                _format_log_value(response_body),
            )

            if success:
                self.requestFinished.emit(True, response_body)
            else:
                self.requestFinished.emit(False, f"服务器错误: {response.status_code}")
        except requests.exceptions.Timeout:
            _logger.warning("网络请求超时: method=%s url=%s", self.method, self.url)
            self.requestFinished.emit(False, "请求超时，请检查网络连接")
        except requests.exceptions.ConnectionError:
            _logger.warning("网络连接失败: method=%s url=%s", self.method, self.url)
            self.requestFinished.emit(False, "无法连接到服务器，请检查网络")
        except Exception as exc:
            _logger.exception("网络请求异常: method=%s url=%s", self.method, self.url)
            self.requestFinished.emit(False, str(exc))


class NetworkManager(QObject):
    """网络请求管理器。"""

    requestFinished = Signal(bool, str)

    def __init__(self, base_url=""):
        super().__init__()
        self.base_url = str(base_url or "")
        self._worker = None

    def post_json(self, url, data):
        """POST 请求，JSON 格式。"""
        self._send_request("POST", url, data, use_json=True)

    def post_form(self, url, data):
        """POST 请求，表单格式。"""
        self._send_request("POST", url, data, use_json=False)

    def get(self, url, params=None):
        """GET 请求。"""
        self._send_request("GET", url, params, use_json=True)

    def _get_headers(self):
        """获取请求头。"""
        headers = {}
        try:
            from src.utils.storage import StorageManager

            token = StorageManager().load("token")
            if token:
                headers["token"] = token
        except Exception:
            _logger.exception("读取 token 失败")

        return headers

    def _build_url(self, url):
        """拼接完整请求地址。"""
        if str(url or "").startswith(("http://", "https://")):
            return str(url)
        return urljoin(self.base_url.rstrip("/") + "/", str(url or "").lstrip("/"))

    def _send_request(self, method, url, data, use_json, timeout=None):
        """发送网络请求。"""
        if self._worker and self._worker.isRunning():
            self.requestFinished.emit(False, "上一次请求仍在进行中")
            return

        headers = self._get_headers()
        full_url = self._build_url(url)
        self._worker = NetworkWorker(method, full_url, data, use_json, headers, timeout)
        self._worker.requestFinished.connect(self._on_request_finished)
        self._worker.finished.connect(self._on_worker_finished)
        self._worker.start()

    def _on_request_finished(self, success, response):
        """请求完成回调。"""
        self.requestFinished.emit(success, response)

    @Slot()
    def _on_worker_finished(self):
        """在线程真正结束后清理 QThread 对象。"""
        worker = self.sender()
        if worker is None:
            return

        worker.deleteLater()
        if self._worker is worker:
            self._worker = None
