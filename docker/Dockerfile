# ============================================================
# 阶段 1: 在 Debian Bookworm 中编译 fcitx5-qt Qt6 输入法插件
# ============================================================
# 国产 Linux 系统（统信 UOS / 麒麟）使用 fcitx 输入法，但只提供 Qt5 版本的插件，
# PySide6 (Qt6) 需要 Qt6 版本的 fcitx 插件才能输入中文。
#
# PySide6 pip wheel 不包含 Qt6 C++ 开发头文件，Debian Bullseye 也没有 Qt6 包，
# 因此在 Bookworm（有 qt6-base-dev）中编译插件，再复制到最终镜像。
#
# 编译出的 .so 只依赖 Qt6 的 C++ ABI（libQt6Core/Gui/DBus），
# PySide6 自带的 Qt6 运行时可以满足这些依赖。
FROM debian:bookworm-slim AS fcitx5-builder

ENV DEBIAN_FRONTEND=noninteractive

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
            libegl-dev \
            qt6-base-dev \
            qt6-base-private-dev \
            libqt6dbus6 && \
        break; \
        if [ "${attempt}" = "5" ]; then exit 1; fi; \
        rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/partial/*; \
        sleep "$((attempt * 10))"; \
    done; \
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
        -DCMAKE_BUILD_TYPE=Release \
        -DENABLE_QT4=OFF \
        -DENABLE_QT5=OFF \
        -DENABLE_QT6=ON \
        -DBUILD_ONLY_PLUGIN=ON && \
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
