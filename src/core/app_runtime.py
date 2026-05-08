#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
应用运行时控制器。
"""
from __future__ import annotations

import logging
import os
from logging.handlers import RotatingFileHandler
from pathlib import Path

from PySide6.QtCore import QObject, Property, QCoreApplication, Signal, Slot

from src.config.settings import AUTO_RESTART_DELAY_MS, AUTO_RESTART_ON_FATAL


LOG_DIR = Path.home() / ".hcly_behavior_desktop" / "logs"
APP_LOG = LOG_DIR / "app.log"
FATAL_LOG = LOG_DIR / "fatal.log"


def get_log_paths():
    return {
        "dir": LOG_DIR,
        "app": APP_LOG,
        "fatal": FATAL_LOG,
    }


def setup_logging():
    """初始化应用日志。"""
    LOG_DIR.mkdir(parents=True, exist_ok=True)

    root_logger = logging.getLogger()
    root_logger.setLevel(logging.INFO)
    formatter = logging.Formatter(
        "%(asctime)s %(levelname)s [%(name)s] %(message)s"
    )

    has_file_handler = any(
        isinstance(handler, RotatingFileHandler)
        and Path(getattr(handler, "baseFilename", "")) == APP_LOG
        for handler in root_logger.handlers
    )
    if not has_file_handler:
        file_handler = RotatingFileHandler(
            APP_LOG,
            maxBytes=5 * 1024 * 1024,
            backupCount=3,
            encoding="utf-8",
        )
        file_handler.setFormatter(formatter)
        root_logger.addHandler(file_handler)

    has_console_handler = any(
        isinstance(handler, logging.StreamHandler)
        and not isinstance(handler, RotatingFileHandler)
        for handler in root_logger.handlers
    )
    if not has_console_handler:
        console_handler = logging.StreamHandler()
        console_handler.setFormatter(formatter)
        root_logger.addHandler(console_handler)

    return get_log_paths()


class AppRuntime(QObject):
    """负责全局 Toast 和致命错误状态。"""

    fatalErrorChanged = Signal()
    toastRequested = Signal(str, str, int)

    def __init__(self):
        super().__init__()
        self._fatal_error_visible = False
        self._fatal_error_title = ""
        self._fatal_error_message = ""
        self._fatal_error_details = ""

    @Property(bool, notify=fatalErrorChanged)
    def fatalErrorVisible(self):
        """致命错误浮层是否可见。"""
        return self._fatal_error_visible

    @Property(str, notify=fatalErrorChanged)
    def fatalErrorTitle(self):
        """致命错误标题。"""
        return self._fatal_error_title

    @Property(str, notify=fatalErrorChanged)
    def fatalErrorMessage(self):
        """致命错误简要信息。"""
        return self._fatal_error_message

    @Property(str, notify=fatalErrorChanged)
    def fatalErrorDetails(self):
        """致命错误详细信息。"""
        return self._fatal_error_details

    @Property(bool, constant=True)
    def autoRestartOnFatal(self):
        """致命错误后是否自动重启。"""
        return AUTO_RESTART_ON_FATAL

    @Property(int, constant=True)
    def autoRestartDelayMs(self):
        """致命错误后自动重启延迟。"""
        return AUTO_RESTART_DELAY_MS

    @Slot(str, str, int)
    def showToast(self, message, toast_type="info", duration=3000):
        """展示全局 Toast。"""
        self.toastRequested.emit(str(message or ""), str(toast_type or "info"), int(duration or 3000))

    @Slot(str, str, str)
    def showFatalError(self, title, message, details=""):
        """展示致命错误浮层。"""
        self._fatal_error_title = str(title or "程序异常")
        self._fatal_error_message = str(message or "发生未处理异常")
        self._fatal_error_details = str(details or "")
        self._fatal_error_visible = True
        self.fatalErrorChanged.emit()

        with FATAL_LOG.open("a", encoding="utf-8") as fatal_file:
            fatal_file.write(f"{self._fatal_error_title}\n")
            fatal_file.write(f"{self._fatal_error_message}\n")
            fatal_file.write(f"{self._fatal_error_details}\n\n")

    @Slot()
    def clearFatalError(self):
        """清除致命错误浮层。"""
        self._fatal_error_visible = False
        self._fatal_error_title = ""
        self._fatal_error_message = ""
        self._fatal_error_details = ""
        self.fatalErrorChanged.emit()

    @Slot()
    def quitApplication(self):
        """退出应用。"""
        logging.getLogger(__name__).info("Quit requested by application")
        app = QCoreApplication.instance()
        if app is not None:
            app.quit()
            return

        os._exit(0)
