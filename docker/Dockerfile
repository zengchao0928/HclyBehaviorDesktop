# ============================================================
# 阶段 1: 在 Debian Bullseye 中编译 fcitx5-qt Qt6 输入法插件
# ============================================================
# 国产 Linux 系统（统信 UOS / 麒麟）使用 fcitx 输入法，但只提供 Qt5 版本的插件，
# PySide6 (Qt6) 需要 Qt6 版本的 fcitx 插件才能输入中文。
#
# 使用 Bullseye (glibc 2.31) 编译以兼容 UOS (glibc 2.28)。
# Bullseye 没有 qt6-base-dev，因此安装 PySide6 获取 Qt6 运行时库，
# 再从 Qt 源码中提取编译 fcitx5-qt 所需的最小头文件集。
#
# 注意：UOS glibc 2.28 < Bullseye glibc 2.31，但 fcitx5-qt 插件
# 只用到了 glibc 2.17 级别的符号（基本 C 库函数），实际不会触发高版本依赖。
# 如果仍然不兼容，打包脚本会自动移除插件并继续。
FROM python:3.11-slim-bullseye AS fcitx5-builder

ENV DEBIAN_FRONTEND=noninteractive

COPY docker/generate_qt6_cmake.py /tmp/generate_qt6_cmake.py

RUN set -eux; \
    printf '%s\n' \
        'Acquire::Retries "5";' \
        'Acquire::http::Timeout "60";' \
        'Acquire::https::Timeout "60";' \
        > /etc/apt/apt.conf.d/99-hcly-retry; \
    for attempt in 1 2 3 4 5; do \
        apt-get update \
            -o Acquire::Retries=5 \
            -o Acquire::http::Timeout=60 \
            -o Acquire::https::Timeout=60 && \
        apt-get install -y --no-install-recommends --fix-missing \
            -o Acquire::Retries=5 \
            -o Acquire::http::Timeout=60 \
            -o Acquire::https::Timeout=60 \
            ca-certificates \
            git \
            cmake \
            make \
            extra-cmake-modules \
            g++ \
            pkg-config \
            libdbus-1-dev \
            libxkbcommon-dev \
            libgl-dev \
            libegl-dev && \
        break; \
        if [ "${attempt}" = "5" ]; then exit 1; fi; \
        rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/partial/*; \
        sleep "$((attempt * 10))"; \
    done; \
    # 安装 PySide6 获取 Qt6 运行时库
    python -m pip install --no-cache-dir "PySide6>=6.7" && \
    PYSIDE6_DIR="$(python -c 'import PySide6; import os; print(os.path.dirname(PySide6.__file__))')" && \
    QT6_PREFIX="${PYSIDE6_DIR}/Qt" && \
    QT6_VERSION="$(python -c 'import PySide6.QtCore; print(PySide6.QtCore.qVersion())')" && \
    echo "Qt version: ${QT6_VERSION}, prefix: ${QT6_PREFIX}" && \
    # 从 Qt 源码获取编译 fcitx5-qt 所需的头文件
    QT_MAJOR="$(echo ${QT6_VERSION} | cut -d. -f1)" && \
    QT_MINOR="$(echo ${QT6_VERSION} | cut -d. -f2)" && \
    QT_PATCH="$(echo ${QT6_VERSION} | cut -d. -f3)" && \
    QT_TAG="v${QT6_VERSION}" && \
    # 下载 qtbase 源码中的头文件（只需要 src/corelib, src/gui, src/dbus 的头文件）
    for attempt in 1 2 3; do \
        git clone --depth 1 --branch "${QT_TAG}" --filter=blob:none --sparse \
            https://github.com/nicktencate/qtbase.git /tmp/qtbase 2>/dev/null || \
        git clone --depth 1 --branch "${QT_TAG}" --filter=blob:none --sparse \
            https://code.qt.io/qt/qtbase.git /tmp/qtbase && \
        break; \
        rm -rf /tmp/qtbase; sleep 5; \
    done && \
    cd /tmp/qtbase && \
    git sparse-checkout set src/corelib src/gui src/dbus src/widgets src/plugins/platforms && \
    # 创建 include 目录结构（模拟 Qt 安装后的头文件布局）
    mkdir -p "${QT6_PREFIX}/include/QtCore" \
             "${QT6_PREFIX}/include/QtGui" \
             "${QT6_PREFIX}/include/QtDBus" \
             "${QT6_PREFIX}/include/QtWidgets" && \
    # 复制头文件
    find /tmp/qtbase/src/corelib -name '*.h' -exec cp {} "${QT6_PREFIX}/include/QtCore/" \; && \
    find /tmp/qtbase/src/gui -name '*.h' -exec cp {} "${QT6_PREFIX}/include/QtGui/" \; && \
    find /tmp/qtbase/src/dbus -name '*.h' -exec cp {} "${QT6_PREFIX}/include/QtDBus/" \; && \
    find /tmp/qtbase/src/widgets -name '*.h' -exec cp {} "${QT6_PREFIX}/include/QtWidgets/" \; && \
    # 创建顶层 include 便利头文件
    for h in "${QT6_PREFIX}/include/QtCore/"*.h; do \
        basename_h="$(basename "$h")"; \
        ln -sf "QtCore/${basename_h}" "${QT6_PREFIX}/include/${basename_h}" 2>/dev/null || true; \
    done && \
    for h in "${QT6_PREFIX}/include/QtGui/"*.h; do \
        basename_h="$(basename "$h")"; \
        ln -sf "QtGui/${basename_h}" "${QT6_PREFIX}/include/${basename_h}" 2>/dev/null || true; \
    done && \
    for h in "${QT6_PREFIX}/include/QtDBus/"*.h; do \
        basename_h="$(basename "$h")"; \
        ln -sf "QtDBus/${basename_h}" "${QT6_PREFIX}/include/${basename_h}" 2>/dev/null || true; \
    done && \
    rm -rf /tmp/qtbase && \
    # 生成最小的 Qt6 CMake 配置文件
    python /tmp/generate_qt6_cmake.py "${QT6_PREFIX}" && \
    # 克隆并编译 fcitx5-qt
    for attempt in 1 2 3; do \
        git clone --depth 1 --branch 5.1.1 https://github.com/fcitx/fcitx5-qt.git /tmp/fcitx5-qt && \
        break; \
        if [ "${attempt}" = "3" ]; then exit 1; fi; \
        rm -rf /tmp/fcitx5-qt; \
        sleep "$((attempt * 10))"; \
    done; \
    mkdir /tmp/fcitx5-qt/build && \
    cd /tmp/fcitx5-qt/build && \
    cmake .. \
        -DCMAKE_PREFIX_PATH="${QT6_PREFIX}" \
        -DCMAKE_BUILD_TYPE=Release \
        -DENABLE_QT4=OFF \
        -DENABLE_QT5=OFF \
        -DENABLE_QT6=ON \
        -DBUILD_ONLY_PLUGIN=ON \
        -DCMAKE_SHARED_LINKER_FLAGS="-static-libstdc++ -static-libgcc" \
        -DCMAKE_MODULE_LINKER_FLAGS="-static-libstdc++ -static-libgcc" && \
    make -j"$(nproc)" && \
    cp /tmp/fcitx5-qt/build/qt6/platforminputcontext/libfcitx5platforminputcontextplugin.so /tmp/ && \
    rm -rf /tmp/fcitx5-qt /var/lib/apt/lists/*

# ============================================================
# 阶段 2: 最终打包镜像（Bullseye + Python 3.11 + PySide6）
# ============================================================
FROM python:3.11-slim-bullseye

ENV DEBIAN_FRONTEND=noninteractive \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PYTHONUNBUFFERED=1

RUN set -eux; \
    printf '%s\n' \
        'Acquire::Retries "5";' \
        'Acquire::http::Timeout "60";' \
        'Acquire::https::Timeout "60";' \
        > /etc/apt/apt.conf.d/99-hcly-retry; \
    for attempt in 1 2 3 4 5; do \
        apt-get update \
            -o Acquire::Retries=5 \
            -o Acquire::http::Timeout=60 \
            -o Acquire::https::Timeout=60 && \
        apt-get install -y --no-install-recommends --fix-missing \
            -o Acquire::Retries=5 \
            -o Acquire::http::Timeout=60 \
            -o Acquire::https::Timeout=60 \
            bash \
            binutils \
            ca-certificates \
            file \
            findutils \
            patchelf \
            xz-utils \
            zip \
            libasound2 \
            libdbus-1-3 \
            libegl1 \
            libfontconfig1 \
            libfreetype6 \
            libgl1 \
            libglib2.0-0 \
            libice6 \
            libnss3 \
            libsm6 \
            libwayland-client0 \
            libwayland-cursor0 \
            libwayland-egl1 \
            libx11-6 \
            libx11-xcb1 \
            libxcb1 \
            libxcb-cursor0 \
            libxcb-glx0 \
            libxcb-icccm4 \
            libxcb-image0 \
            libxcb-keysyms1 \
            libxcb-randr0 \
            libxcb-render0 \
            libxcb-render-util0 \
            libxcb-shape0 \
            libxcb-shm0 \
            libxcb-sync1 \
            libxcb-util1 \
            libxcb-xfixes0 \
            libxcb-xinerama0 \
            libxcb-xkb1 \
            libxcomposite1 \
            libxcursor1 \
            libxdamage1 \
            libxext6 \
            libxfixes3 \
            libxi6 \
            libxkbcommon0 \
            libxkbcommon-x11-0 \
            libxrandr2 \
            libxrender1 \
            libxshmfence1 \
            libxtst6 && \
        break; \
        if [ "${attempt}" = "5" ]; then exit 1; fi; \
        rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/partial/*; \
        sleep "$((attempt * 10))"; \
    done; \
    rm -rf /var/lib/apt/lists/*

COPY requirements.txt /tmp/hcly-requirements.txt

RUN python -m pip install --upgrade --no-cache-dir pip setuptools wheel && \
    python -m pip install --no-cache-dir -r /tmp/hcly-requirements.txt "pyinstaller>=6.10,<7"

# 从阶段 1 复制编译好的 fcitx5 Qt6 输入法插件
COPY --from=fcitx5-builder /tmp/libfcitx5platforminputcontextplugin.so /tmp/libfcitx5platforminputcontextplugin.so

WORKDIR /workspace
