#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
登录相关接口。
"""
from PySide6.QtCore import QObject, Signal

from src.config.settings import API_BASE_URL
from src.core.network import NetworkManager


class LoginApi(QObject):
    """登录接口。"""

    requestFinished = Signal(bool, str)

    def __init__(self):
        super().__init__()
        self.network_manager = NetworkManager(API_BASE_URL)
        self.network_manager.requestFinished.connect(self._on_request_finished)

    def login(self, username, password):
        """调用 Flutter 项目同款登录接口。"""
        body = {
            "userName": username,
            "userPwd": password,
        }
        self.network_manager.post_form("/api/login/getTokenWithoutIP", body)

    def _on_request_finished(self, success, response):
        """转发请求结果。"""
        self.requestFinished.emit(success, response)
