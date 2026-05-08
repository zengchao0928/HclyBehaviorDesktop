#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
本地存储工具。
"""
from PySide6.QtCore import QObject, QSettings, Slot


class StorageManager(QObject):
    """本地存储管理器。"""

    def __init__(self):
        super().__init__()
        self.settings = QSettings()

    @Slot(str, str)
    def save(self, key, value):
        """保存数据。"""
        self.settings.setValue(key, value)
        self.settings.sync()

    @Slot(str, result=str)
    def load(self, key):
        """读取数据。"""
        return self.settings.value(key, "")

    @Slot(str)
    def remove(self, key):
        """删除数据。"""
        self.settings.remove(key)
        self.settings.sync()

    @Slot()
    def clear(self):
        """清空所有数据。"""
        self.settings.clear()
        self.settings.sync()
