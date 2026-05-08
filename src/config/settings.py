#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
应用配置。
"""

APP_NAME = "留置中心"
APP_VERSION_NAME = "1.0.0"
APP_VERSION_CODE = 1
APP_VERSION = APP_VERSION_NAME

from src.config.runtime_config import get_config_path, load_api_base_url

DEFAULT_API_BASE_URL = "http://10.1.100.126:8085/"
API_BASE_URL = load_api_base_url(DEFAULT_API_BASE_URL)
CONFIG_FILE_PATH = str(get_config_path())
API_CONNECT_TIMEOUT = 5
API_TIMEOUT = 5

WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 800
WINDOW_MIN_WIDTH = 1280
WINDOW_MIN_HEIGHT = 800

AUTO_RESTART_ON_FATAL = False
AUTO_RESTART_DELAY_MS = 300
