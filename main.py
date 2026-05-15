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


def _choose_linux_qpa_platform() -> str:
    """根据当前桌面会话选择 Qt 平台，Wayland 不可用时交给 Qt 回退到 xcb。"""
    explicit = os.environ.get("HCLY_QT_QPA_PLATFORM") or os.environ.get("QT_QPA_PLATFORM")
    if explicit:
        return explicit

    if os.environ.get("XDG_SESSION_TYPE", "").lower() == "wayland" and os.environ.get("WAYLAND_DISPLAY"):
        return "wayland;xcb"

    return "xcb"


def _choose_linux_input_method(qpa_platform: str) -> str:
    """为 Qt6 选择输入法模块，优先使用系统 fcitx5 插件以确保兼容性。"""
    if "HCLY_QT_IM_MODULE" in os.environ:
        return os.environ.get("HCLY_QT_IM_MODULE", "")

    import platform

    arch = platform.machine()
    system_plugin_dirs = [
        Path(f"/usr/lib/{arch}-linux-gnu/qt6/plugins/platforminputcontexts"),
        Path("/usr/lib64/qt6/plugins/platforminputcontexts"),
        Path("/usr/lib/qt6/plugins/platforminputcontexts"),
    ]

    app_dir = Path(__file__).resolve().parent
    bundled_plugin_dir = app_dir / "_internal" / "PySide6" / "Qt" / "plugins" / "platforminputcontexts"

    # 检查系统是否安装了 fcitx5 Qt6 插件（UOS/麒麟自带）
    system_fcitx_found = False
    system_fcitx_plugin_dir = None
    for sys_dir in system_plugin_dirs:
        if (sys_dir / "libfcitx5platforminputcontextplugin.so").is_file() or \
           (sys_dir / "libfcitxplatforminputcontextplugin-qt6.so").is_file():
            system_fcitx_found = True
            system_fcitx_plugin_dir = sys_dir
            break

    # 如果系统有 fcitx5 插件，确保 QT_PLUGIN_PATH 包含系统插件目录
    # 这样即使打包的插件因依赖缺失加载失败，Qt 也能找到系统的
    if system_fcitx_plugin_dir:
        qt_plugin_path = os.environ.get("QT_PLUGIN_PATH", "")
        system_plugins_root = str(system_fcitx_plugin_dir.parent)
        if system_plugins_root not in qt_plugin_path:
            if qt_plugin_path:
                os.environ["QT_PLUGIN_PATH"] = f"{qt_plugin_path}:{system_plugins_root}"
            else:
                os.environ["QT_PLUGIN_PATH"] = system_plugins_root

    bundled_fcitx_candidates = (
        bundled_plugin_dir / "libfcitx5platforminputcontextplugin.so",
        bundled_plugin_dir / "libfcitxplatforminputcontextplugin-qt6.so",
    )

    if "wayland" in qpa_platform:
        os.environ.setdefault("QT_IM_MODULES", "wayland;fcitx;ibus")
        return ""

    os.environ.setdefault("QT_IM_MODULES", "fcitx;ibus;xim")

    # 系统有 fcitx 插件或打包中有 fcitx 插件，都使用 fcitx
    if system_fcitx_found or any(path.is_file() for path in bundled_fcitx_candidates):
        return "fcitx"

    if (bundled_plugin_dir / "libibusplatforminputcontextplugin.so").is_file():
        return "ibus"

    return "xim"


def _diagnose_input_method(logger: logging.Logger) -> None:
    """诊断输入法环境，帮助排查中文输入问题。"""
    import subprocess

    # 检查 fcitx5 进程是否在运行
    try:
        result = subprocess.run(
            ["pgrep", "-x", "fcitx5"],
            capture_output=True, text=True, timeout=5,
        )
        fcitx5_running = result.returncode == 0
        logger.info("fcitx5 process running: %s (pid: %s)",
                    fcitx5_running, result.stdout.strip() if fcitx5_running else "N/A")
    except Exception as e:
        logger.info("fcitx5 process check failed: %s", e)

    # 检查 D-Bus session bus
    dbus_addr = os.environ.get("DBUS_SESSION_BUS_ADDRESS", "")
    logger.info("DBUS_SESSION_BUS_ADDRESS: %s", dbus_addr or "(not set)")

    # 检查 platforminputcontexts 目录中实际存在的插件
    app_dir = Path(__file__).resolve().parent
    pic_dir = app_dir / "_internal" / "PySide6" / "Qt" / "plugins" / "platforminputcontexts"
    if pic_dir.is_dir():
        plugins = [f.name for f in pic_dir.iterdir() if f.suffix == ".so"]
        logger.info("Bundled platforminputcontexts plugins: %s", plugins)
    else:
        logger.info("Bundled platforminputcontexts dir not found: %s", pic_dir)

    # 检查 LD_LIBRARY_PATH
    logger.info("LD_LIBRARY_PATH: %s", os.environ.get("LD_LIBRARY_PATH", "(not set)"))


def _configure_qt_quick_controls_style(logger: logging.Logger) -> None:
    """固定使用 Basic 样式，减少不同系统原生主题差异。"""
    style = os.environ.setdefault("QT_QUICK_CONTROLS_STYLE", "Basic")
    logger.info("Qt Quick Controls style: %s", style)

    # 国产 Linux 系统（统信 UOS / 麒麟）使用 fcitx 输入法框架，
    # Wayland 会话优先走 Qt6 原生 Wayland text-input，X11 下再回退到插件/ibus/XIM。
    if sys.platform.startswith("linux"):
        qpa_platform = _choose_linux_qpa_platform()
        os.environ["QT_QPA_PLATFORM"] = qpa_platform
        os.environ.setdefault("QT_XCB_GL_INTEGRATION", "none")
        os.environ.setdefault("GDK_BACKEND", "wayland,x11" if "wayland" in qpa_platform else "x11")
        os.environ.setdefault("GTK_IM_MODULE", "fcitx")
        qt_im_module = _choose_linux_input_method(qpa_platform)
        if qt_im_module:
            os.environ["QT_IM_MODULE"] = qt_im_module
        else:
            os.environ.pop("QT_IM_MODULE", None)
        os.environ.setdefault("QT_VIRTUALKEYBOARD_DESKTOP_DISABLE", "1")
        os.environ.setdefault("XMODIFIERS", "@im=fcitx")

        if qpa_platform == "xcb":
            os.environ["WAYLAND_DISPLAY"] = os.environ.get("HCLY_WAYLAND_DISPLAY", "")
        elif "HCLY_WAYLAND_DISPLAY" in os.environ:
            os.environ["WAYLAND_DISPLAY"] = os.environ["HCLY_WAYLAND_DISPLAY"]

        logger.info(
            "Linux input method environment: QT_QPA_PLATFORM=%s, GTK_IM_MODULE=%s, "
            "QT_IM_MODULE=%s, XMODIFIERS=%s, WAYLAND_DISPLAY=%s, "
            "QT_VIRTUALKEYBOARD_DESKTOP_DISABLE=%s, QT_PLUGIN_PATH=%s",
            os.environ.get("QT_QPA_PLATFORM", ""),
            os.environ.get("GTK_IM_MODULE", ""),
            os.environ.get("QT_IM_MODULE", ""),
            os.environ.get("XMODIFIERS", ""),
            os.environ.get("WAYLAND_DISPLAY", ""),
            os.environ.get("QT_VIRTUALKEYBOARD_DESKTOP_DISABLE", ""),
            os.environ.get("QT_PLUGIN_PATH", ""),
        )

        # 诊断：检查 fcitx5 是否在运行以及 D-Bus 是否可用
        _diagnose_input_method(logger)


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
    app.setApplicationName("留置中心打标")
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
