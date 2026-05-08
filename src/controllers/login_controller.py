#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
登录页面控制器。
"""
from PySide6.QtCore import QObject, Property, Signal, Slot

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
        self._suggested_username = "lpsjw"
        self._suggested_password = "123456"

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
        self._token = "local-dev-token"
        self._login_pending = False
        self.loadingChanged.emit(False)
        self.loginStatusChanged.emit(True, "登录成功")

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
