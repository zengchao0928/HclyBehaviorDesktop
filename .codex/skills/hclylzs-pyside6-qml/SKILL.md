---
name: hclylzs-pyside6-qml
description: 当在 HclyLzs 项目中处理 PySide6、QML、页面控制器、StackView 导航、contextProperty 暴露、无边框全屏/kiosk、异常展示或基于 QThread 的网络请求时使用。该 skill 固化此仓库的目录约定、中文文档约束、QML 与 Python 分层方式以及当前代码中的已知偏差。
---

# HclyLzs PySide6/QML

## 适用范围

- 修改 `main.py`、`qml/**/*.qml`、`qml/pages/**`、`qml/components/**`、`apis/**`、`core/network.py`、`config/app_config.py`。
- 新增页面、组件、控制器、全局上下文对象、资源单例或窗口模式逻辑。
- 修复页面跳转、QML 与 Python 信号/槽对接、全屏/无标题栏、异常弹层、网络线程问题。

## 先做什么

1. 先读 [repo-patterns.md](references/repo-patterns.md)，确认入口、目录和命名约定。
2. 再读目标页面对应的 `qml/pages/<page>/<Page>Page.qml` 和 `qml/pages/<page>/<page>_controller.py`。
3. 如果改的是登录页、户外页、认证、网络或窗口行为，再读 [current-audit.md](references/current-audit.md)，避免把现有偏差继续扩散。

## 硬约束

- 所有注释、说明、文档、补充文本都使用中文。
- UI 只用 QML/Qt Quick，禁止引入 `PySide6.QtWidgets`。
- QML 只负责展示与交互，不写业务规则、网络请求或复杂状态判断。
- Python 控制器负责校验、状态、业务逻辑和信号回推；供 QML 调用的方法优先加 `@Slot`，有风险的入口优先加 `@fatal_slot`。
- 网络请求必须走后台线程模式，优先复用 `core/network.py` 和 `apis/*`；不要在 QML 或直接暴露给 QML 的槽函数里同步 `requests`。
- 资源路径优先走 `qml/ImageResources.qml` 单例；新增资源时同步更新 `qml/qmldir`/单例导出。
- 根窗口显示方式只在 `main.py` 的 `_apply_window_mode()` 中控制；不要重新把 `qml/MainWindow.qml` 改回 `visible: true` 或 `Window.FullScreen` 绑定。
- 所有主动创建的新文件都必须执行 `git add`；除非用户明确要求，否则禁止执行 `git commit` 和 `git push`。

## 仓库工作流

### 页面或组件修改

1. 先确认目标 QML 是页面、组件还是根窗口。
2. 页面改动优先检查是否已有对应控制器；没有就按现有结构补 `qml/pages/<page>/<page>_controller.py`。
3. 如果 QML 里要调用新的 Python 方法，同时补控制器槽函数、信号以及 `main.py` 暴露方式。
4. 页面跳转沿用 `windowManager.switchToPage(pageName)`，页面目录和文件名必须匹配 `qml/MainWindow.qml` 中的路径拼装规则。

### API 或状态修改

1. 新接口优先放进 `apis/`，控制器只组合调用，不直接拼所有请求细节。
2. 需要线程隔离时复用 `core/network.py` 的 `NetworkWorker`/`NetworkManager`。
3. 若返回错误需要统一展示，沿用 `appRuntime` 的致命错误浮层或页面内 `Toast`/`LoadingOverlay` 模式，不要在 QML 里散落重复逻辑。

### 窗口或全屏修改

1. 根窗口由 `qml/MainWindow.qml` 定义，但默认不自显示。
2. 显示、全屏、无边框、置顶、平台特判放在 `main.py::_apply_window_mode()`。
3. macOS 需要避免原生 `showFullScreen()`，否则鼠标到顶部会重新露出系统标题栏；此仓库应使用无边框铺满屏幕模式。

## 修改前自检

- 是否破坏了 “QML 展示 / Python 控制器逻辑” 分层？
- 是否新增了未暴露给 QML 的控制器方法，或在 QML 中调用了不存在的槽函数？
- 是否把同步网络请求放回 UI 线程？
- 是否绕开了现有的 `ImageResources`、`windowManager`、`appRuntime`、`fatal_slot` 模式？

## 验证方式

执行以下轻量检查：

```bash
python3 -m py_compile main.py config/app_config.py config/settings.py
```

如果改了根窗口或 QML 入口，再跑一次离屏加载：

```bash
QT_QPA_PLATFORM=offscreen python3 - <<'PY'
from pathlib import Path
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtCore import QUrl
from config.app_config import AppConfig
from core.app_runtime import AppRuntime
from core.window_manager import WindowManager
from qml.pages.login.login_controller import LoginController
from qml.pages.out.out_controller import OutController

app = QGuiApplication([])
engine = QQmlApplicationEngine()
qml_dir = Path.cwd() / "qml"
engine.addImportPath(str(qml_dir))

app_config = AppConfig()
app_runtime = AppRuntime()
login_controller = LoginController()
out_controller = OutController()
window_manager = WindowManager()

engine.rootContext().setContextProperty("appConfig", app_config)
engine.rootContext().setContextProperty("appRuntime", app_runtime)
engine.rootContext().setContextProperty("loginController", login_controller)
engine.rootContext().setContextProperty("outController", out_controller)
engine.rootContext().setContextProperty("windowManager", window_manager)
engine.load(QUrl.fromLocalFile(str(qml_dir / "MainWindow.qml")))
print(len(engine.rootObjects()))
PY
```

如果改了页面与控制器联动，额外用 `rg` 搜一遍控制器引用和方法定义是否一致。

## 参考文件

- [repo-patterns.md](references/repo-patterns.md)：目录、命名、上下文对象、资源和窗口模式的仓库事实。
- [current-audit.md](references/current-audit.md)：当前代码里的已知偏差和修改时要避开的坑。
