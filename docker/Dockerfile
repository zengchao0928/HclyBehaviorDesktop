# Linux 打包环境。
# 目标机安装 deb 时只需要 dpkg；这里的 apt 只用于构建 Docker 镜像。
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
            libxtst6 \
            libfcitx5utils2 \
            libfcitx5config6 \
            libfcitx5core7 && \
        break; \
        if [ "${attempt}" = "5" ]; then exit 1; fi; \
        rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/partial/*; \
        sleep "$((attempt * 10))"; \
    done; \
    rm -rf /var/lib/apt/lists/*

COPY requirements.txt /tmp/hcly-requirements.txt

RUN python -m pip install --upgrade --no-cache-dir pip setuptools wheel && \
    python -m pip install --no-cache-dir -r /tmp/hcly-requirements.txt "pyinstaller>=6.10,<7"

WORKDIR /workspace
