"""
网络查看器全局注册表。
"""

_global_inspector = None


def set_global_inspector(inspector) -> None:
    """设置当前应用使用的网络查看器实例。"""
    global _global_inspector
    _global_inspector = inspector


def get_global_inspector():
    """获取当前应用使用的网络查看器实例。"""
    return _global_inspector
