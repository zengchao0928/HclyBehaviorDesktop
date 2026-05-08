#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
登录页面控制器。
"""
import json

from PySide6.QtCore import QObject, Property, Signal, Slot

from src.api.login_api import LoginApi
from src.utils.storage import StorageManager
from src.utils.exception_handler import fatal_slot


class LoginController(QObject):
    """登录页面控制器。"""

    loginStatusChanged = Signal(bool, str)
    loadingChanged = Signal(bool)
    validationFailed = Signal(str)

    def __init__(self):
        super().__init__()
        self._token = ""
        self._username = ""
        self._login_pending = False
        self._suggested_username = "kljw"
        self._suggested_password = "123456"
        self._login_api = LoginApi()
        self._login_api.requestFinished.connect(self._on_login_response)
        self._storage = StorageManager()

    @Property(str, constant=True)
    def suggestedUsername(self):
        """登录页默认展示的测试用户名。"""
        return self._suggested_username

    @Property(str, constant=True)
    def suggestedPassword(self):
        """登录页默认展示的测试密码。"""
        return self._suggested_password

    @Slot(str, str)
    @fatal_slot
    def login(self, username, password):
        """执行账号密码登录。"""
        if self._login_pending:
            return

        username = str(username or "").strip()
        password = str(password or "")

        if not username:
            if not password:
                self.validationFailed.emit("请输入用户名和密码")
            else:
                self.validationFailed.emit("请输入用户名")
            return

        if not password:
            self.validationFailed.emit("请输入密码")
            return

        self._login_pending = True
        self.loadingChanged.emit(True)
        self._username = username
        self._login_api.login(username, password)

    def _finish_login(self, success: bool, message: str) -> None:
        """结束登录流程并通知 QML。"""
        self._login_pending = False
        self.loadingChanged.emit(False)
        self.loginStatusChanged.emit(bool(success), str(message or "").strip())

    def _save_login_result(self, result: dict, username: str) -> None:
        """保存登录成功后的 token 和用户信息。"""
        token = str(result.get("data", "") or "")
        self._token = token
        self._username = username
        self._storage.save("token", token)
        self._storage.save("accessToken", token)
        self._storage.save("username", username)
        self._storage.save("userInfo", json.dumps(result, ensure_ascii=False))

    def _on_login_response(self, success, response):
        """处理登录接口响应。"""
        if not self._login_pending:
            return

        if not success:
            self._finish_login(False, response or "登录失败")
            return

        try:
            result = json.loads(response) if isinstance(response, str) else dict(response)
        except json.JSONDecodeError:
            self._finish_login(False, "服务器返回数据格式错误")
            return
        except Exception as exc:
            self._finish_login(False, f"解析登录响应失败: {exc}")
            return

        try:
            code = int(result.get("code"))
        except (TypeError, ValueError):
            code = None

        token = str(result.get("data", "") or "")
        if code != 0 or not token:
            self._finish_login(False, result.get("msg") or "登录失败")
            return

        self._save_login_result(result, self._username)
        self._finish_login(True, "登录成功")

    @Slot()
    @fatal_slot
    def cancelLogin(self):
        """取消当前登录流程。"""
        self._login_pending = False
        self.loadingChanged.emit(False)

    @Slot(result=str)
    @fatal_slot
    def getToken(self):
        """获取 token。"""
        return self._token

    @Slot(result=str)
    @fatal_slot
    def getUsername(self):
        """获取用户名。"""
        return self._username
