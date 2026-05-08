#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
运行时配置文件读取。
"""
from __future__ import annotations

import json
import logging
import sys
from pathlib import Path


CONFIG_FILE_NAME = "config.json"
_logger = logging.getLogger(__name__)


def get_runtime_dir() -> Path:
    """获取运行时配置所在目录。"""
    if getattr(sys, "frozen", False):
        return Path(sys.executable).resolve().parent
    return Path(__file__).resolve().parents[2]


def get_config_path() -> Path:
    """获取 config.json 的完整路径。"""
    return get_runtime_dir() / CONFIG_FILE_NAME


def _write_default_config(config_path: Path, default_base_url: str) -> None:
    """写入默认配置文件。"""
    config_path.parent.mkdir(parents=True, exist_ok=True)
    payload = {"baseUrl": str(default_base_url or "")}
    config_path.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def load_api_base_url(default_base_url: str) -> str:
    """读取接口基础地址，配置文件不存在时创建默认配置。"""
    fallback_base_url = str(default_base_url or "").strip()
    config_path = get_config_path()

    if not config_path.exists():
        try:
            _write_default_config(config_path, fallback_base_url)
            _logger.info("已创建默认配置文件: %s", config_path)
        except Exception:
            _logger.exception("创建默认配置文件失败: %s", config_path)
        return fallback_base_url

    try:
        payload = json.loads(config_path.read_text(encoding="utf-8"))
    except Exception:
        _logger.exception("读取配置文件失败，使用默认接口地址: %s", config_path)
        return fallback_base_url

    if not isinstance(payload, dict):
        _logger.warning("配置文件格式不是 JSON 对象，使用默认接口地址: %s", config_path)
        return fallback_base_url

    base_url = str(payload.get("baseUrl") or "").strip()
    if not base_url:
        _logger.warning("配置文件缺少 baseUrl，使用默认接口地址: %s", config_path)
        return fallback_base_url

    return base_url
