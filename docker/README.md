# Linux Docker 打包说明

这里的文件只负责把当前项目打成 Linux deb 安装包，输出统一放在 `docker/dist/`。构建环境使用 Debian 11，因为 PySide6 官方 arm64 wheel 最低要求 `manylinux_2_31_aarch64`。默认生成兼顾体积和兼容性的包，只携带应用、Python/PySide6、必要 Qt 文件和 glibc 兼容层；如果目标机缺 Qt/X11 系统库，再打开系统库兼容开关。

## deb 离线包

```bash
bash docker/build-deb-amd64.sh
bash docker/build-deb-arm64.sh
```

输出示例：

```text
docker/dist/hcly-behavior-desktop_1.0.0_amd64.deb
docker/dist/hcly-behavior-desktop_1.0.0_arm64.deb
```

目标机安装：

```bash
sudo dpkg -i hcly-behavior-desktop_1.0.0_amd64.deb
sudo dpkg -i hcly-behavior-desktop_1.0.0_arm64.deb
```

卸载：

```bash
sudo dpkg -r hcly-behavior-desktop
```

这个 deb 默认不声明外部 apt 依赖，包内会携带 Python、PySide6、QML、图片资源和 glibc 兼容层；arm64 包还会默认携带 Qt/xcb 依赖，避免 RK 板图形库缺失时启动 abort。目标机仍需要 Linux 图形桌面、内核以及显示驱动。安装时会给执行 `sudo dpkg -i` 的桌面用户创建桌面快捷方式，`sudo dpkg -r` 卸载时会删除这个快捷方式。

启动器日志默认写入 `/opt/hcly-behavior-desktop/logs/launcher.log`，只有应用目录日志不可写时才回退到用户目录 `~/.hcly_behavior_desktop/logs/launcher.log`。

## 接口地址配置

项目的接口基础地址由 `src/config/settings.py` 中的 `API_BASE_URL` 提供。启动时会先读取运行目录下的 `config.json`，取其中的 `baseUrl` 字段；如果文件不存在、格式错误或 `baseUrl` 为空，则回退到 `DEFAULT_API_BASE_URL`，当前默认值为 `http://10.1.100.126:8085/`。

Linux deb 安装后，运行目录固定在 `/opt/hcly-behavior-desktop`，所以目标机上修改接口地址时编辑：

```bash
sudo nano /opt/hcly-behavior-desktop/config.json
```

文件内容示例：

```json
{
  "baseUrl": "http://10.1.100.126:8085/"
}
```

修改后重新启动应用生效。Docker 打包脚本会在构建时把默认 `config.json` 写入安装包，并在 deb 中放到 `/opt/hcly-behavior-desktop/config.json`；该文件会设置为可写，便于现场部署时直接调整。

## 可选参数

```bash
APP_VERSION=1.2.3 bash docker/build-deb-amd64.sh
KEEP_WAYLAND=1 bash docker/build-deb-amd64.sh
KEEP_EXTRA_QML=1 bash docker/build-deb-amd64.sh
ENABLE_UPX=1 bash docker/build-deb-amd64.sh
BUNDLE_SYSTEM_LIBS=1 bash docker/build-deb-amd64.sh
BUNDLE_GLIBC=0 bash docker/build-deb-amd64.sh
```

- `APP_VERSION`：修改输出包版本；不传时默认读取 `src/config/settings.py` 中的 `APP_VERSION`。
- `KEEP_WAYLAND=1`：额外保留 Wayland 平台插件，体积会稍大。
- `KEEP_EXTRA_QML=1`：保留更多 Qt QML 模块，适合遇到缺模块错误时排查。
- `ENABLE_UPX=1`：启用 UPX 压缩；体积更小，但 Qt 动态库在部分系统上可能不稳定。
- `BUNDLE_SYSTEM_LIBS=1`：额外携带 Qt/X11 等系统库，兼容性更强但体积明显变大；arm64 构建脚本默认启用，可用 `BUNDLE_SYSTEM_LIBS=0 bash docker/build-deb-arm64.sh` 关闭。
- `BUNDLE_GLIBC=0`：不携带 glibc，体积更小，但目标机 glibc 偏老时会无法启动。

## 目标机排查

如果目标机直接报“段错误”，先在解压目录里执行：

```bash
HCLY_DEBUG_LAUNCH=1 /usr/bin/hcly-behavior-desktop
HCLY_QT_QPA_PLATFORM=wayland /usr/bin/hcly-behavior-desktop
HCLY_USE_BUNDLED_GLIBC=0 /usr/bin/hcly-behavior-desktop
HCLY_SOFTWARE_RENDERING=0 /usr/bin/hcly-behavior-desktop
QT_DEBUG_PLUGINS=1 /usr/bin/hcly-behavior-desktop
```

- `HCLY_DEBUG_LAUNCH=1`：打印当前 glibc 和启动模式。
- `HCLY_QT_QPA_PLATFORM=wayland HCLY_WAYLAND_DISPLAY=wayland-0`：临时尝试 Wayland 后端；默认启动脚本会固定使用 `xcb` 并清空 `WAYLAND_DISPLAY`，让输入法走 X11/XIM。
- `HCLY_USE_BUNDLED_GLIBC=0`：禁用包内 glibc，适合目标机系统 glibc 已经足够新时排查。
- `HCLY_SOFTWARE_RENDERING=0`：关闭默认软件渲染，适合排查 Qt 图形后端问题。
- `QT_DEBUG_PLUGINS=1`：输出 Qt 插件加载日志，用于确认 `platforminputcontexts/libfcitx5platforminputcontextplugin.so` 是否被找到。

Docker 镜像构建阶段需要外网下载 apt 和 pip 包；目标 Linux 机器安装 deb 时只用 `dpkg`，不需要 `apt` 下载依赖。

## Git 仓库推送说明

本项目配置了两个远程仓库：

- **origin**（Gitee）：`https://gitee.com/gzhcly_1/hcly-behavior-desktop.git`
- **github**（GitHub）：`https://github.com/zengchao0928/HclyBehaviorDesktop.git`

当前分支名为 `master`。

### 推送到 Gitee（默认）

```bash
git push origin master
```

### 推送到 GitHub

```bash
git push github master
```

### 同时推送到两个仓库

```bash
git push origin master && git push github master
```

或者配置 `origin` 同时推送到两个地址：

```bash
# 添加 GitHub 作为 origin 的第二个推送地址
git remote set-url --add --push origin https://github.com/zengchao0928/HclyBehaviorDesktop.git
git remote set-url --add --push origin https://gitee.com/gzhcly_1/hcly-behavior-desktop.git

# 之后执行 git push 会同时推送到两个仓库
git push origin master
```

### 查看当前远程仓库配置

```bash
git remote -v
```
