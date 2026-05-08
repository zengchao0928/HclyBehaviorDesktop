#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
窗口管理器，负责单窗口应用的页面切换。
"""
import logging

from PySide6.QtCore import QObject, Signal, Slot

from src.utils.exception_handler import fatal_slot


class WindowManager(QObject):
    """窗口管理器。"""

    switchPage = Signal(str)
    replacePage = Signal(str)
    goBackRequested = Signal()

    def __init__(self):
        super().__init__()
        self._current_page = "login"
        self._history = ["login"]
        self._logger = logging.getLogger(__name__)

    @Slot(str)
    @fatal_slot
    def switchToPage(self, page_name: str):
        """切换到指定页面。"""
        if not page_name or page_name == self._current_page:
            return

        self._logger.info("Switch page: %s -> %s", self._current_page, page_name)
        self._current_page = page_name
        self._history.append(page_name)
        self.switchPage.emit(page_name)

    @Slot()
    @fatal_slot
    def goBack(self):
        """返回上一个页面。"""
        if len(self._history) <= 1:
            return

        self._history.pop()
        self._current_page = self._history[-1]
        self._logger.info("Go back to page: %s", self._current_page)
        self.goBackRequested.emit()

    @Slot(str)
    @fatal_slot
    def replaceWithPage(self, page_name: str):
        """用新页面替换当前页面。"""
        if not page_name or page_name == self._current_page:
            return

        previous_page = self._current_page
        self._current_page = page_name

        if self._history:
            self._history[-1] = page_name
        else:
            self._history.append(page_name)

        self._logger.info("Replace page: %s -> %s", previous_page, page_name)
        self.replacePage.emit(page_name)

    @Slot(result=str)
    @fatal_slot
    def getCurrentPage(self):
        """获取当前页面名称。"""
        return self._current_page
