#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
应用程序主入口。
"""
from __future__ import annotations

import logging
import os
import sys
from pathlib import Path

from PySide6.QtCore import QUrl
from PySide6.QtGui import QFont, QFontDatabase, QGuiApplication, QIcon
from PySide6.QtQml import QQmlApplicationEngine

from src.config.app_config import AppConfig
from src.controllers.behavior_controller import BehaviorController
from src.controllers.login_controller import LoginController
from src.core.app_runtime import AppRuntime, setup_logging
from src.core.window_manager import WindowManager
from src.utils.exception_handler import install_global_exception_handlers
from library.network_chucker import NetworkInspector, set_global_inspector


def _configure_qt_quick_controls_style(logger: logging.Logger) -> None:
    """固定使用 Basic 样式，减少不同系统原生主题差异。"""
    style = os.environ.setdefault("QT_QUICK_CONTROLS_STYLE", "Basic")
    logger.info("Qt Quick Controls style: %s", style)


def _pick_font_family(available_families, candidates) -> str:
    """从系统已安装字体中挑选合适的简体中文界面字体。"""
    normalized = {family.casefold(): family for family in available_families}

    for candidate in candidates:
        matched = normalized.get(candidate.casefold())
        if matched:
            return matched

    for candidate in candidates:
        candidate_key = candidate.casefold()
        for family in available_families:
            family_key = family.casefold()
            if candidate_key in family_key or family_key in candidate_key:
                return family

    return ""


def _configure_app_font(app: QGuiApplication, logger: logging.Logger) -> None:
    """统一设置应用字体，避免跨平台中文字形差异过大。"""
    if sys.platform == "darwin":
        preferred_families = [
            "PingFang SC",
            "Hiragino Sans GB",
            "Noto Sans CJK SC",
            "Source Han Sans SC",
        ]
    elif sys.platform.startswith("linux"):
        preferred_families = [
            "Noto Sans CJK SC",
            "Noto Sans SC",
            "Source Han Sans SC",
            "WenQuanYi Micro Hei",
            "Microsoft YaHei",
            "PingFang SC",
        ]
    else:
        preferred_families = [
            "Microsoft YaHei UI",
            "Microsoft YaHei",
            "SimHei",
            "Noto Sans CJK SC",
            "Source Han Sans SC",
        ]

    selected_family = _pick_font_family(
        QFontDatabase().families(),
        preferred_families,
    )

    font = app.font()
    font.setStyleStrategy(QFont.PreferAntialias)

    if selected_family:
        font.setFamily(selected_family)
        logger.info("UI font configured: %s", selected_family)
    else:
        logger.warning("No preferred Chinese UI font found, keep default font")

    app.setFont(font)


def _configure_app_icon(app: QGuiApplication, logger: logging.Logger) -> None:
    """设置应用窗口图标。"""
    icon_path = Path(__file__).parent / "resources" / "icons" / "app_icon.png"
    if not icon_path.is_file():
        logger.warning("应用图标不存在: %s", icon_path)
        return

    app.setWindowIcon(QIcon(str(icon_path)))
    logger.info("Application icon configured: %s", icon_path)


def _apply_window_mode(root_window, logger: logging.Logger) -> None:
    """以普通桌面窗口启动，并限制最小窗口尺寸。"""
    app_icon = QGuiApplication.windowIcon()
    if not app_icon.isNull():
        root_window.setIcon(app_icon)

    root_window.show()
    root_window.requestActivate()
    logger.info(
        "Window started in normal mode: %sx%s min=%sx%s",
        root_window.width(),
        root_window.height(),
        root_window.minimumWidth(),
        root_window.minimumHeight(),
    )


def main() -> None:
    log_paths = setup_logging()
    logger = logging.getLogger(__name__)
    logger.info("Application starting")
    logger.info("Log files: %s", {key: str(value) for key, value in log_paths.items()})
    _configure_qt_quick_controls_style(logger)

    app = QGuiApplication(sys.argv)
    app.setOrganizationName("Hcly")
    app.setApplicationName("留置中心")
    _configure_app_font(app, logger)
    _configure_app_icon(app, logger)

    engine = QQmlApplicationEngine()
    qml_dir = Path(__file__).parent / "qml"
    engine.addImportPath(str(qml_dir))
    engine.addImportPath(str(Path(__file__).parent / "library" / "network_chucker" / "qml"))

    app_config = AppConfig()
    app_runtime = AppRuntime()
    install_global_exception_handlers(app_runtime)

    login_controller = LoginController()
    behavior_controller = BehaviorController()
    window_manager = WindowManager()
    network_inspector = NetworkInspector()
    set_global_inspector(network_inspector)

    engine.rootContext().setContextProperty("appConfig", app_config)
    engine.rootContext().setContextProperty("appRuntime", app_runtime)
    engine.rootContext().setContextProperty("loginController", login_controller)
    engine.rootContext().setContextProperty("behaviorController", behavior_controller)
    engine.rootContext().setContextProperty("windowManager", window_manager)
    engine.rootContext().setContextProperty("networkInspector", network_inspector)

    qml_file = qml_dir / "MainWindow.qml"
    engine.load(QUrl.fromLocalFile(str(qml_file)))

    if not engine.rootObjects():
        logger.error("QML root object load failed: %s", qml_file)
        sys.exit(-1)

    root_window = engine.rootObjects()[0]
    _apply_window_mode(root_window, logger)

    exit_code = app.exec()
    logger.info("Application exiting with code %s", exit_code)
    sys.exit(exit_code)


if __name__ == "__main__":
    main()
