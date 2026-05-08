#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
登录页兼容用的屏幕类型控制器。
"""
from PySide6.QtCore import QObject, Property, Signal, Slot

from src.utils.exception_handler import fatal_slot


class ScreenTypeController(QObject):
    """暂时只为登录页提供登录后路由兼容。"""

    screenTypeChanged = Signal()

    @Property(str, notify=screenTypeChanged)
    def screenType(self):
        """当前屏幕类型标识。"""
        return "behavior"

    @Property(str, notify=screenTypeChanged)
    def screenTypeName(self):
        """当前屏幕类型中文名称。"""
        return "行为记录屏"

    @Property(bool, notify=screenTypeChanged)
    def hasScreenType(self):
        """是否已经选择屏幕类型。"""
        return True

    @Property(str, notify=screenTypeChanged)
    def routePage(self):
        """登录成功后的目标页面。"""
        return "login"

    @Property(bool, notify=screenTypeChanged)
    def hasRoutePage(self):
        """当前屏幕类型是否有可进入的页面。"""
        return True

    @Property(str, constant=True)
    def missingRouteMessage(self):
        """找不到屏幕类型页面时的提示。"""
        return "当前项目暂未配置登录后的页面"

    @Slot()
    @fatal_slot
    def refreshScreenType(self):
        """刷新屏幕类型。"""
        self.screenTypeChanged.emit()

    @Slot(result=str)
    @fatal_slot
    def currentRoutePage(self):
        """获取当前屏幕类型登录成功后的目标页面。"""
        return "login"

    @Slot(result=bool)
    @fatal_slot
    def currentRouteAvailable(self):
        """当前屏幕类型是否有可进入的页面。"""
        return True
