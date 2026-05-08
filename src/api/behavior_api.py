#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
行为记录相关接口。
"""
from PySide6.QtCore import QObject, Signal

from src.config.settings import API_BASE_URL
from src.core.network import NetworkManager


class BehaviorApi(QObject):
    """行为记录接口。"""

    requestFinished = Signal(str, bool, str)

    def __init__(self):
        super().__init__()
        self._active_managers = {}
        self._request_index = 0

    def _send_post(self, request_name: str, path: str, data=None):
        self._request_index += 1
        request_id = f"{request_name}_{self._request_index}"
        manager = NetworkManager(API_BASE_URL)
        self._active_managers[request_id] = manager
        manager.requestFinished.connect(
            lambda success, response, rid=request_id, name=request_name: self._on_request_finished(
                rid,
                name,
                success,
                response,
            )
        )
        manager.idle.connect(lambda rid=request_id: self._release_manager(rid))
        manager.post_form(path, data or {})

    def get_liens(self):
        """获取留置对象列表。"""
        self._send_post("liens", "/api/lien/selectCustomList")

    def get_actions(self):
        """获取行为分类和行为项。"""
        self._send_post("actions", "/api/action/selectAction")

    def get_records(self, lien_id: str, page: int = 1, limit: int = 20):
        """获取指定对象的行为记录。"""
        self._send_post(
            "records",
            "/api/action/selectLienActionRecord",
            {
                "limit": limit,
                "page": page,
                "lienId": lien_id,
            },
        )

    def add_action_record(self, lien_id: str, content: str):
        """提交行为记录。"""
        self._send_post(
            "add_record",
            "/api/action/addActionRecord",
            {
                "content": content,
                "lienId": lien_id,
            },
        )

    def get_matter_list(self):
        """获取事项列表。"""
        self._send_post("matters", "/api/matter/selectMaterList")

    def get_goods_list(self):
        """获取物品列表。"""
        self._send_post("goods", "/api/goods/selectGoodsList")

    def add_lien_apply_matter(self, lien_id: str, matter_id: str, remark: str = ""):
        """提交事项申请。"""
        self._send_post(
            "apply_matter",
            "/api/matter/addLienApplyMatter",
            {
                "matterId": matter_id,
                "lienId": lien_id,
                "num": 1,
                "remark": remark,
            },
        )

    def add_lien_apply_goods(self, lien_id: str, goods_id: str, count: int = 1, remark: str = ""):
        """提交物品申请。"""
        self._send_post(
            "apply_goods",
            "/api/goods/addLienApplyGoods",
            {
                "goodsId": goods_id,
                "lienId": lien_id,
                "num": max(1, int(count or 1)),
                "remark": remark,
            },
        )

    def _on_request_finished(self, request_id, request_name, success, response):
        self.requestFinished.emit(request_name, success, response)

    def _release_manager(self, request_id):
        manager = self._active_managers.pop(request_id, None)
        if manager is not None:
            manager.deleteLater()
