#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
全局异常处理。
"""
from functools import wraps
import logging
import sys
import threading
import traceback

from PySide6.QtCore import QTimer


_app_runtime = None


def set_app_runtime(app_runtime):
    """设置应用运行时控制器。"""
    global _app_runtime
    _app_runtime = app_runtime


def _report_exception(exc_type, exc_value, exc_traceback):
    details = "".join(traceback.format_exception(exc_type, exc_value, exc_traceback))
    logging.getLogger(__name__).error("Unhandled exception\n%s", details)

    if _app_runtime is not None:
        title = exc_type.__name__
        message = str(exc_value) or "发生未处理异常"
        QTimer.singleShot(
            0,
            lambda: _app_runtime.showFatalError(title, message, details),
        )


def install_global_exception_handlers(app_runtime):
    """安装 Python 全局异常处理器。"""
    set_app_runtime(app_runtime)

    def _sys_excepthook(exc_type, exc_value, exc_traceback):
        _report_exception(exc_type, exc_value, exc_traceback)

    def _thread_excepthook(args):
        _report_exception(args.exc_type, args.exc_value, args.exc_traceback)

    sys.excepthook = _sys_excepthook
    threading.excepthook = _thread_excepthook


def fatal_slot(func):
    """保护暴露给 QML 的槽函数，避免异常直接打断 Qt 事件循环。"""
    @wraps(func)
    def wrapper(*args, **kwargs):
        try:
            return func(*args, **kwargs)
        except Exception:
            exc_type, exc_value, exc_traceback = sys.exc_info()
            _report_exception(exc_type, exc_value, exc_traceback)
            return None

    return wrapper
