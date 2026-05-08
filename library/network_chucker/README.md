# network_chucker

`network_chucker` 是一个可复制到其他 PySide6/QML 项目的网络请求查看库，作用类似 Android Chucker：记录请求方法、URL、请求头、请求体、状态码、响应头、响应体、耗时和错误信息，并提供 QML 列表与详情页。

## 目录职责

- `inspector.py`：网络请求记录模型，向 QML 暴露 `enabled`、`count` 和 `logModel`。其中 `enabled` 只表示调试入口是否显示，不控制记录行为。
- `registry.py`：全局查看器注册表，便于业务网络层拿到同一个 `NetworkInspector`。
- `qml/NetworkInspector/`：可复用 QML 组件，包含悬浮按钮、请求列表页和详情页。

## 在项目中接入

1. 复制 `library/network_chucker/` 到目标项目，并保证能通过 `library.network_chucker` 导入。
2. 在应用入口创建并暴露查看器：

```python
from pathlib import Path
from library.network_chucker import NetworkInspector, set_global_inspector

network_inspector = NetworkInspector()
set_global_inspector(network_inspector)

engine.addImportPath(str(Path(__file__).parent / "library" / "network_chucker" / "qml"))
engine.rootContext().setContextProperty("networkInspector", network_inspector)
```

3. 在统一网络层记录请求开始和结束：

```python
from library.network_chucker import get_global_inspector

inspector = get_global_inspector()
if inspector:
    inspector.record_request_started({
        "request_id": request_id,
        "method": "POST",
        "url": url,
        "headers": headers,
        "body": body,
        "started_at": started_at,
    })

if inspector:
    inspector.record_request_finished({
        "request_id": request_id,
        "success": success,
        "status_code": status_code,
        "reason": reason,
        "response_headers": response_headers,
        "response_body": response_body,
        "elapsed_ms": elapsed_ms,
        "error_message": error_message,
    })
```

4. 在 QML 中使用组件：

```qml
import NetworkInspector 1.0

NetworkFloatingButton {
    inspector: networkInspector
    onClicked: windowManager.switchToPage("network")
}
```

列表页可以直接嵌入业务页面：

```qml
NetworkLogPage {
    anchors.fill: parent
    inspector: networkInspector
    onBackRequested: windowManager.goBack()
}
```

5. 如果要在登录页重新进入时清空历史记录：

```qml
Component.onCompleted: {
    if (typeof networkInspector !== "undefined" && networkInspector) {
        networkInspector.clear()
    }
}
```

## 开关约定

网络记录始终开启，只要业务网络层调用 `record_request_started()` 和 `record_request_finished()`，请求就会进入列表。

`NetworkInspector.enabled` 只用于控制调试入口是否显示，例如设置页开关和悬浮按钮可绑定这个属性。关闭入口后不会清空记录，也不会停止记录；再次打开后可以看到之前已经发生的请求。

## 记录字段

- 请求开始：`request_id`、`method`、`url`、`headers`、`body`、`started_at`
- 请求结束：`request_id`、`success`、`status_code`、`reason`、`response_headers`、`response_body`、`elapsed_ms`、`error_message`

`request_id` 必须在开始和结束时保持一致，否则详情页无法把同一次请求的返回数据合并到一起。
