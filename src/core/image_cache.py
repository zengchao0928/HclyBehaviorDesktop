#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
网络图片缓存下载器。
"""
from __future__ import annotations

import hashlib
import logging
from pathlib import Path
from urllib.parse import urlparse

import requests
from PySide6.QtCore import QObject, QThread, QUrl, Signal

from src.config.settings import API_CONNECT_TIMEOUT, API_TIMEOUT
from src.utils.storage import StorageManager


_logger = logging.getLogger(__name__)
_CACHE_DIR = Path.home() / ".hcly_behavior_desktop" / "image_cache"


def _cache_path_for_url(url: str) -> Path:
    """根据图片 URL 生成稳定缓存路径。"""
    parsed = urlparse(url)
    suffix = Path(parsed.path).suffix.lower()
    if suffix not in {".png", ".jpg", ".jpeg", ".webp", ".gif"}:
        suffix = ".img"
    digest = hashlib.sha256(url.encode("utf-8")).hexdigest()
    return _CACHE_DIR / f"{digest}{suffix}"


class ImageDownloadWorker(QThread):
    """在后台线程下载网络图片。"""

    imageReady = Signal(str, str, str)

    def __init__(self, jobs):
        super().__init__()
        self._jobs = list(jobs or [])

    def run(self):
        """下载任务入口。"""
        if not self._jobs:
            return

        _CACHE_DIR.mkdir(parents=True, exist_ok=True)
        token = StorageManager().load("token")
        headers = {"token": token} if token else {}
        session = requests.Session()
        session.trust_env = False

        for kind, item_id, url in self._jobs:
            image_url = str(url or "")
            if not image_url:
                continue

            cache_path = _cache_path_for_url(image_url)
            try:
                if not cache_path.exists() or cache_path.stat().st_size <= 0:
                    response = session.get(
                        image_url,
                        headers=headers,
                        timeout=(API_CONNECT_TIMEOUT, API_TIMEOUT),
                    )
                    response.raise_for_status()
                    cache_path.write_bytes(response.content)

                self.imageReady.emit(
                    str(kind or ""),
                    str(item_id or ""),
                    QUrl.fromLocalFile(str(cache_path)).toString(),
                )
            except Exception as exc:
                _logger.warning("图片缓存失败: url=%s error=%s", image_url, exc)


class ImageCache(QObject):
    """管理图片下载线程并向控制器回推本地路径。"""

    imageReady = Signal(str, str, str)

    def __init__(self):
        super().__init__()
        self._workers = []

    def request_images(self, jobs):
        """批量请求缓存图片。"""
        normalized_jobs = [tuple(job) for job in (jobs or []) if len(job) == 3 and job[2]]
        if not normalized_jobs:
            return

        worker = ImageDownloadWorker(normalized_jobs)
        worker.imageReady.connect(self._emit_image_ready)
        worker.finished.connect(lambda worker=worker: self._cleanup_worker(worker))
        self._workers.append(worker)
        worker.start()

    def _emit_image_ready(self, kind, item_id, local_url):
        """向外转发图片就绪信号。"""
        self.imageReady.emit(kind, item_id, local_url)

    def _cleanup_worker(self, worker):
        """清理已经结束的下载线程。"""
        if worker in self._workers:
            self._workers.remove(worker)
        worker.deleteLater()
