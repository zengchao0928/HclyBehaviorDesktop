#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
应用配置管理器，将 Python 配置暴露给 QML。
"""
from PySide6.QtCore import QObject, Property

from src.config.settings import (
    APP_NAME,
    APP_VERSION,
    APP_VERSION_CODE,
    APP_VERSION_NAME,
    WINDOW_HEIGHT,
    WINDOW_MIN_HEIGHT,
    WINDOW_MIN_WIDTH,
    WINDOW_WIDTH,
)


class AppConfig(QObject):
    """应用配置管理器。"""

    @Property(int, constant=True)
    def windowWidth(self):
        """窗口宽度。"""
        return WINDOW_WIDTH

    @Property(int, constant=True)
    def windowHeight(self):
        """窗口高度。"""
        return WINDOW_HEIGHT

    @Property(int, constant=True)
    def windowMinWidth(self):
        """窗口最小宽度。"""
        return WINDOW_MIN_WIDTH

    @Property(int, constant=True)
    def windowMinHeight(self):
        """窗口最小高度。"""
        return WINDOW_MIN_HEIGHT

    @Property(str, constant=True)
    def appName(self):
        """应用名称。"""
        return APP_NAME

    @Property(str, constant=True)
    def appVersion(self):
        """应用版本。"""
        return APP_VERSION

    @Property(str, constant=True)
    def appVersionName(self):
        """应用版本名。"""
        return APP_VERSION_NAME

    @Property(int, constant=True)
    def appVersionCode(self):
        """应用版本号。"""
        return APP_VERSION_CODE
