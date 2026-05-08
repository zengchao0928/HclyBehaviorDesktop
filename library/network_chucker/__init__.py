"""
网络请求查看库入口。
"""

from library.network_chucker.inspector import NetworkInspector, NetworkLogModel
from library.network_chucker.registry import get_global_inspector, set_global_inspector

__all__ = [
    "NetworkInspector",
    "NetworkLogModel",
    "get_global_inspector",
    "set_global_inspector",
]
