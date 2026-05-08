#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
    printf '用法: %s deb\n' "$0"
}

die() {
    printf '错误: %s\n' "$*" >&2
    exit 1
}

log() {
    printf '\n==> %s\n' "$*"
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# shellcheck source=/dev/null
source "${SCRIPT_DIR}/package.env"

KIND="${1:-}"
case "${KIND}" in
    deb) ;;
    *) usage; exit 2 ;;
esac

export PROJECT_ROOT APP_ID ENABLE_UPX

DOCKER_DIR="${PROJECT_ROOT}/docker"
BUILD_ROOT="${DOCKER_DIR}/build"
DIST_ROOT="${DOCKER_DIR}/dist"
PYINSTALLER_DIST="${DIST_ROOT}/pyinstaller"
APP_BUNDLE="${PYINSTALLER_DIST}/${APP_ID}"
APP_BIN="${APP_BUNDLE}/${APP_ID}-bin"
APP_LAUNCHER="${APP_BUNDLE}/${APP_ID}"

prepare_dirs() {
    rm -rf "${DIST_ROOT}"
    mkdir -p "${BUILD_ROOT}" "${DIST_ROOT}"
}

build_app() {
    log "使用 PyInstaller 构建 Linux onedir 产物"
    rm -rf "${BUILD_ROOT}/pyinstaller" "${APP_BUNDLE}"
    python -m PyInstaller \
        --clean \
        --noconfirm \
        --distpath "${PYINSTALLER_DIST}" \
        --workpath "${BUILD_ROOT}/pyinstaller" \
        "${DOCKER_DIR}/hcly-behavior-desktop.spec"

    [[ -x "${APP_BIN}" ]] || die "未找到 PyInstaller 主程序: ${APP_BIN}"
}

write_launcher() {
    log "写入应用启动脚本"
    cat > "${APP_LAUNCHER}" <<EOF
#!/usr/bin/env bash
set -Eeuo pipefail

SELF_PATH="\${BASH_SOURCE[0]}"
while [[ -L "\${SELF_PATH}" ]]; do
    SELF_DIR="\$(cd -P "\$(dirname "\${SELF_PATH}")" && pwd)"
    SELF_PATH="\$(readlink "\${SELF_PATH}")"
    [[ "\${SELF_PATH}" == /* ]] || SELF_PATH="\${SELF_DIR}/\${SELF_PATH}"
done
APP_DIR="\$(cd -P "\$(dirname "\${SELF_PATH}")" && pwd)"

if [[ "\${HCLY_LAUNCH_LOG:-1}" == "1" ]]; then
    if [[ -n "\${HOME:-}" && -d "\${HOME}/Desktop" ]]; then
        LOG_DIR="\${HOME}/Desktop"
    elif [[ -n "\${HOME:-}" && -d "\${HOME}/桌面" ]]; then
        LOG_DIR="\${HOME}/桌面"
    else
        LOG_DIR="\${HOME:-/tmp}/.hcly_behavior_desktop/logs"
    fi
    LAUNCH_LOG="\${LOG_DIR}/launcher.log"
    if mkdir -p "\${LOG_DIR}" 2>/dev/null && touch "\${LAUNCH_LOG}" 2>/dev/null; then
        exec >> "\${LAUNCH_LOG}" 2>&1
        printf '\n[%s] 启动器开始\n' "\$(date '+%F %T')"
        printf 'APP_DIR=%s\n' "\${APP_DIR}"
        printf 'HOME=%s\n' "\${HOME:-}"
        printf 'USER=%s\n' "\${USER:-}"
        printf 'SHELL=%s\n' "\${SHELL:-}"
        printf 'UNAME=%s\n' "\$(uname -a 2>/dev/null || true)"
        printf 'DISPLAY=%s\n' "\${DISPLAY:-}"
        printf 'XDG_SESSION_TYPE=%s\n' "\${XDG_SESSION_TYPE:-}"
        printf 'QT_QPA_PLATFORM(before)=%s\n' "\${QT_QPA_PLATFORM:-}"
    fi
fi

export QT_QUICK_CONTROLS_STYLE="\${QT_QUICK_CONTROLS_STYLE:-Basic}"
export QT_QPA_PLATFORM="\${QT_QPA_PLATFORM:-xcb}"
export QT_PLUGIN_PATH="\${APP_DIR}/_internal/PySide6/Qt/plugins\${QT_PLUGIN_PATH:+:\${QT_PLUGIN_PATH}}"
export QT_QPA_PLATFORM_PLUGIN_PATH="\${APP_DIR}/_internal/PySide6/Qt/plugins/platforms"
export QML_IMPORT_PATH="\${APP_DIR}/_internal/PySide6/Qt/qml:\${APP_DIR}/_internal/qml:\${APP_DIR}/_internal/library/network_chucker/qml\${QML_IMPORT_PATH:+:\${QML_IMPORT_PATH}}"
APP_NATIVE_LIBRARY_PATH="\${APP_DIR}/lib/system:\${APP_DIR}/_internal:\${APP_DIR}/_internal/PySide6/Qt/lib"
APP_GLIBC_LIBRARY_PATH="\${APP_DIR}/lib/glibc:\${APP_NATIVE_LIBRARY_PATH}"

if [[ "\${HCLY_SOFTWARE_RENDERING:-1}" == "1" ]]; then
    export QT_QUICK_BACKEND="\${QT_QUICK_BACKEND:-software}"
    export LIBGL_ALWAYS_SOFTWARE="\${LIBGL_ALWAYS_SOFTWARE:-1}"
fi

case "\$(uname -m)" in
    aarch64|arm64) GLIBC_LOADER="\${APP_DIR}/lib/glibc/ld-linux-aarch64.so.1" ;;
    x86_64|amd64) GLIBC_LOADER="\${APP_DIR}/lib/glibc/ld-linux-x86-64.so.2" ;;
    *) GLIBC_LOADER="" ;;
esac

version_lt() {
    [[ "\$(printf '%s\n%s\n' "\$1" "\$2" | sort -V | head -n 1)" != "\$2" ]]
}

SYSTEM_GLIBC_VERSION="\$(getconf GNU_LIBC_VERSION 2>/dev/null | awk '{print \$2}')"
USE_BUNDLED_GLIBC=0
case "\${HCLY_USE_BUNDLED_GLIBC:-auto}" in
    1|true|yes|on)
        USE_BUNDLED_GLIBC=1
        ;;
    0|false|no|off)
        USE_BUNDLED_GLIBC=0
        ;;
    *)
        if [[ -n "\${SYSTEM_GLIBC_VERSION}" ]] && version_lt "\${SYSTEM_GLIBC_VERSION}" "2.31"; then
            USE_BUNDLED_GLIBC=1
        fi
        ;;
esac

if [[ "\${HCLY_DEBUG_LAUNCH:-0}" == "1" ]]; then
    printf 'APP_DIR=%s\n' "\${APP_DIR}" >&2
    printf 'SYSTEM_GLIBC_VERSION=%s\n' "\${SYSTEM_GLIBC_VERSION:-unknown}" >&2
    printf 'USE_BUNDLED_GLIBC=%s\n' "\${USE_BUNDLED_GLIBC}" >&2
    printf 'QT_QPA_PLATFORM=%s\n' "\${QT_QPA_PLATFORM}" >&2
    printf 'HCLY_SOFTWARE_RENDERING=%s\n' "\${HCLY_SOFTWARE_RENDERING:-1}" >&2
fi

if [[ "\${USE_BUNDLED_GLIBC}" == "1" && -n "\${GLIBC_LOADER}" && -x "\${GLIBC_LOADER}" ]]; then
    export LD_LIBRARY_PATH="\${APP_GLIBC_LIBRARY_PATH}\${LD_LIBRARY_PATH:+:\${LD_LIBRARY_PATH}}"
    exec "\${GLIBC_LOADER}" --library-path "\${APP_GLIBC_LIBRARY_PATH}" "\${APP_DIR}/${APP_ID}-bin" "\$@"
fi

export LD_LIBRARY_PATH="\${APP_NATIVE_LIBRARY_PATH}\${LD_LIBRARY_PATH:+:\${LD_LIBRARY_PATH}}"
exec "\${APP_DIR}/${APP_ID}-bin" "\$@"
EOF
    chmod 0755 "${APP_LAUNCHER}"
}

is_elf_file() {
    local file_path="$1"
    [[ -f "${file_path}" ]] || return 1
    file -b "${file_path}" | grep -q 'ELF'
}

find_elf_candidates() {
    find "${APP_BUNDLE}" \
        -path "${APP_BUNDLE}/lib/glibc" -prune \
        -o -type f \( \
            -name "${APP_ID}-bin" \
            -o -name '*.so' \
            -o -name '*.so.*' \
            -o -name '*.abi3.so' \
            -o -name '*.cpython-*.so' \
        \) -print0
}

should_skip_system_lib() {
    local lib_path="$1"
    case "${lib_path}" in
        "${APP_BUNDLE}"/*) return 0 ;;
        /lib*/ld-linux*.so*|/usr/lib*/ld-linux*.so*) return 0 ;;
        /lib*/libc.so.*|/usr/lib*/libc.so.*) return 0 ;;
        /lib*/libm.so.*|/usr/lib*/libm.so.*) return 0 ;;
        /lib*/libdl.so.*|/usr/lib*/libdl.so.*) return 0 ;;
        /lib*/libpthread.so.*|/usr/lib*/libpthread.so.*) return 0 ;;
        /lib*/librt.so.*|/usr/lib*/librt.so.*) return 0 ;;
        /lib*/libresolv.so.*|/usr/lib*/libresolv.so.*) return 0 ;;
        /lib*/libutil.so.*|/usr/lib*/libutil.so.*) return 0 ;;
        /lib*/libnsl.so.*|/usr/lib*/libnsl.so.*) return 0 ;;
        /lib*/libanl.so.*|/usr/lib*/libanl.so.*) return 0 ;;
        /lib*/libBrokenLocale.so.*|/usr/lib*/libBrokenLocale.so.*) return 0 ;;
    esac
    return 1
}

copy_needed_libs_for_file() {
    local elf_file="$1"
    local system_lib_dir="$2"
    local copied=0

    while IFS= read -r lib_path; do
        [[ -n "${lib_path}" ]] || continue
        [[ -f "${lib_path}" ]] || continue
        should_skip_system_lib "${lib_path}" && continue

        local target_path="${system_lib_dir}/$(basename "${lib_path}")"
        if [[ ! -e "${target_path}" ]]; then
            cp -L "${lib_path}" "${target_path}"
            copied=1
        fi
    done < <(
        ldd "${elf_file}" 2>/dev/null | awk '
            /=> \// { print $(NF - 1) }
            /^\// { print $1 }
        '
    )

    if [[ "${copied}" == "1" ]]; then
        return 0
    fi
    return 1
}

bundle_system_libs() {
    if [[ "${BUNDLE_SYSTEM_LIBS}" != "1" ]]; then
        remove_if_exists "${APP_BUNDLE}/lib/system"
        return 0
    fi

    log "收集离线运行所需的非 glibc 系统库"
    local system_lib_dir="${APP_BUNDLE}/lib/system"
    mkdir -p "${system_lib_dir}"

    local round
    for round in 1 2 3; do
        printf '    扫描依赖轮次 %s/3\n' "${round}"
        local copied_any=0
        while IFS= read -r -d '' file_path; do
            if copy_needed_libs_for_file "${file_path}" "${system_lib_dir}"; then
                copied_any=1
            fi
        done < <(find_elf_candidates)

        [[ "${copied_any}" == "1" ]] || break
    done
}

bundle_glibc_runtime() {
    if [[ "${BUNDLE_GLIBC}" != "1" ]]; then
        remove_if_exists "${APP_BUNDLE}/lib/glibc"
        return 0
    fi

    log "携带 glibc 运行库以兼容老系统"
    local arch
    local multiarch
    local loader_name
    arch="$(dpkg --print-architecture)"

    case "${arch}" in
        arm64)
            multiarch="aarch64-linux-gnu"
            loader_name="ld-linux-aarch64.so.1"
            ;;
        amd64)
            multiarch="x86_64-linux-gnu"
            loader_name="ld-linux-x86-64.so.2"
            ;;
        *)
            log "未知架构 ${arch}，跳过 glibc 携带"
            return 0
            ;;
    esac

    local glibc_dir="${APP_BUNDLE}/lib/glibc"
    local source_dir="/lib/${multiarch}"
    local lib_name
    mkdir -p "${glibc_dir}"

    cp -L "${source_dir}/${loader_name}" "${glibc_dir}/${loader_name}"
    chmod 0755 "${glibc_dir}/${loader_name}"

    for lib_name in \
        libc.so.6 \
        libm.so.6 \
        libpthread.so.0 \
        libdl.so.2 \
        librt.so.1 \
        libresolv.so.2 \
        libutil.so.1 \
        libanl.so.1 \
        libBrokenLocale.so.1 \
        libcrypt.so.1 \
        libnsl.so.1 \
        libnss_files.so.2 \
        libnss_dns.so.2 \
        libnss_compat.so.2 \
        libnss_hesiod.so.2; do
        if [[ -f "${source_dir}/${lib_name}" ]]; then
            cp -L "${source_dir}/${lib_name}" "${glibc_dir}/${lib_name}"
        fi
    done
}

strip_elf_files() {
    log "剥离符号表以减小体积"
    while IFS= read -r -d '' file_path; do
        strip --strip-unneeded "${file_path}" 2>/dev/null || true
    done < <(find_elf_candidates)
}

remove_if_exists() {
    local path="$1"
    [[ -e "${path}" ]] || return 0
    rm -rf "${path}"
}

prune_qt_bundle() {
    log "清理 Qt/PySide6 中未用到的开发文件和插件"

    find "${APP_BUNDLE}" -type d -name '__pycache__' -prune -exec rm -rf {} +
    find "${APP_BUNDLE}" -type f \( -name '*.pyc' -o -name '*.pyo' \) -delete

    remove_if_exists "${APP_BUNDLE}/_internal/PySide6/examples"
    remove_if_exists "${APP_BUNDLE}/_internal/PySide6/include"
    remove_if_exists "${APP_BUNDLE}/_internal/PySide6/typesystems"
    remove_if_exists "${APP_BUNDLE}/_internal/PySide6/doc"
    remove_if_exists "${APP_BUNDLE}/_internal/PySide6/support"
    remove_if_exists "${APP_BUNDLE}/_internal/PySide6/Qt/translations"
    remove_if_exists "${APP_BUNDLE}/_internal/PySide6/Qt/resources"
    remove_if_exists "${APP_BUNDLE}/_internal/PySide6/Qt/libexec"

    local plugins_dir="${APP_BUNDLE}/_internal/PySide6/Qt/plugins"
    if [[ -d "${plugins_dir}" ]]; then
        for dir_name in \
            assetimporters \
            canbus \
            designer \
            egldeviceintegrations \
            generic \
            geometryloaders \
            geoservices \
            gamepads \
            multimedia \
            networkinformation \
            playlistformats \
            positioning \
            printsupport \
            qmltooling \
            renderers \
            renderplugins \
            sceneparsers \
            scxmldatamodel \
            sqldrivers \
            texttospeech \
            tls \
            virtualkeyboard \
            webview \
            xcbglintegrations; do
            remove_if_exists "${plugins_dir}/${dir_name}"
        done

        if [[ -d "${plugins_dir}/platforms" ]]; then
            if [[ "${KEEP_WAYLAND}" == "1" ]]; then
                find "${plugins_dir}/platforms" -type f -name '*.so' \
                    ! -name 'libqxcb.so' \
                    ! -name 'libqminimal.so' \
                    ! -name 'libqoffscreen.so' \
                    ! -name '*wayland*.so' \
                    -delete
            else
                find "${plugins_dir}/platforms" -type f -name '*.so' \
                    ! -name 'libqxcb.so' \
                    ! -name 'libqminimal.so' \
                    ! -name 'libqoffscreen.so' \
                    -delete
                find "${plugins_dir}/platforms" -type f -name '*wayland*.so' -delete
            fi
        fi

        if [[ -d "${plugins_dir}/imageformats" ]]; then
            find "${plugins_dir}/imageformats" -type f -name '*.so' \
                ! -name 'libqico.so' \
                ! -name 'libqjpeg.so' \
                ! -name 'libqsvg.so' \
                ! -name 'libqwebp.so' \
                -delete
        fi
    fi

    local pyside_qml_dir="${APP_BUNDLE}/_internal/PySide6/Qt/qml"
    if [[ -d "${pyside_qml_dir}" ]]; then
        find "${pyside_qml_dir}" -type f \( \
            -name '*.debug' \
            -o -name '*.pdb' \
            -o -name '*.qmltypes' \
            -o -name 'plugins.qmltypes' \
            -o -name 'designer.qmltypes' \
        \) -delete
    fi

    local controls_dir="${APP_BUNDLE}/_internal/PySide6/Qt/qml/QtQuick/Controls"
    if [[ -d "${controls_dir}" ]]; then
        for style_name in Fusion Imagine Material Universal macOS Windows; do
            remove_if_exists "${controls_dir}/${style_name}"
        done
    fi

    local qt_qml_dir="${APP_BUNDLE}/_internal/PySide6/Qt/qml"
    if [[ "${KEEP_EXTRA_QML}" != "1" && -d "${qt_qml_dir}" ]]; then
        find "${qt_qml_dir}" -mindepth 1 -maxdepth 1 \
            ! -name 'builtins.qmltypes' \
            ! -name 'jsroot.qmltypes' \
            ! -name 'Qt' \
            ! -name 'QtCore' \
            ! -name 'QtQml' \
            ! -name 'QtQuick' \
            -exec rm -rf {} +
    fi

    local python_lib_dir="${APP_BUNDLE}/_internal"
    remove_if_exists "${python_lib_dir}/lib-dynload/_tkinter"*
    remove_if_exists "${python_lib_dir}/tkinter"
    remove_if_exists "${python_lib_dir}/test"
    remove_if_exists "${python_lib_dir}/unittest/test"
    find "${APP_BUNDLE}/_internal" -type d \( \
        -name 'tests' \
        -o -name 'testing' \
        -o -name '__pycache__' \
    \) -prune -exec rm -rf {} + 2>/dev/null || true
    find "${APP_BUNDLE}/_internal" -type f \( \
        -name '*.a' \
        -o -name '*.la' \
        -o -name '*.prl' \
    \) -delete
}

report_bundle_size() {
    log "统计打包体积大项"
    du -ah "${APP_BUNDLE}" 2>/dev/null | sort -h | tail -30 || true
}

make_deb_package() {
    log "生成 dpkg 离线安装 deb"
    local arch
    arch="$(dpkg --print-architecture)"

    local deb_root="${BUILD_ROOT}/deb-root"
    local package_root="${deb_root}/opt/${APP_ID}"
    local deb_path="${DIST_ROOT}/${APP_ID}_${APP_VERSION}_${arch}.deb"

    rm -rf "${deb_root}" "${deb_path}"
    install -d "${deb_root}/DEBIAN"
    install -d "${package_root}"
    install -d "${deb_root}/usr/bin"
    install -d "${deb_root}/usr/share/applications"
    install -d "${deb_root}/usr/share/pixmaps"

    cp -a "${APP_BUNDLE}/." "${package_root}/"
    install -m 0644 "${PROJECT_ROOT}/resources/icons/app_icon.png" "${deb_root}/usr/share/pixmaps/${APP_ID}.png"

    cat > "${deb_root}/usr/bin/${APP_ID}" <<EOF
#!/usr/bin/env bash
export QT_QPA_PLATFORM="\${QT_QPA_PLATFORM:-xcb}"
exec /opt/${APP_ID}/${APP_ID} "\$@"
EOF
    chmod 0755 "${deb_root}/usr/bin/${APP_ID}"

    cat > "${deb_root}/usr/share/applications/${APP_ID}.desktop" <<EOF
[Desktop Entry]
Type=Application
Version=1.0
Name=${APP_DISPLAY_NAME}
Exec=env QT_QPA_PLATFORM=xcb /usr/bin/${APP_ID}
Icon=${APP_ID}
Terminal=false
Categories=Utility;
StartupNotify=true
X-GNOME-Autostart-enabled=false
EOF

    cat > "${deb_root}/DEBIAN/postinst" <<EOF
#!/usr/bin/env bash
set -Eeuo pipefail

APP_ID="${APP_ID}"
APP_DISPLAY_NAME="${APP_DISPLAY_NAME}"

find_target_user() {
    if [[ -n "\${SUDO_USER:-}" && "\${SUDO_USER}" != "root" ]]; then
        printf '%s\n' "\${SUDO_USER}"
        return 0
    fi

    if [[ -n "\${PKEXEC_UID:-}" ]]; then
        getent passwd "\${PKEXEC_UID}" | cut -d: -f1
        return 0
    fi

    local login_user
    login_user="\$(logname 2>/dev/null || true)"
    if [[ -n "\${login_user}" && "\${login_user}" != "root" ]]; then
        printf '%s\n' "\${login_user}"
        return 0
    fi

    return 1
}

user_home() {
    getent passwd "\$1" | cut -d: -f6
}

desktop_dir_for_user() {
    local user="\$1"
    local home_dir
    home_dir="\$(user_home "\${user}")"
    [[ -n "\${home_dir}" ]] || return 1

    if command -v runuser >/dev/null 2>&1 && command -v xdg-user-dir >/dev/null 2>&1; then
        local xdg_dir
        xdg_dir="\$(HOME="\${home_dir}" runuser -u "\${user}" -- xdg-user-dir DESKTOP 2>/dev/null || true)"
        if [[ -n "\${xdg_dir}" && "\${xdg_dir}" != "\${home_dir}" ]]; then
            printf '%s\n' "\${xdg_dir}"
            return 0
        fi
    fi

    local user_dirs_file="\${home_dir}/.config/user-dirs.dirs"
    if [[ -f "\${user_dirs_file}" ]]; then
        local configured_dir
        configured_dir="\$(awk -F= '/^XDG_DESKTOP_DIR=/ { gsub(/"/, "", \$2); print \$2; exit }' "\${user_dirs_file}")"
        if [[ -n "\${configured_dir}" ]]; then
            configured_dir="\${configured_dir//\\\$HOME/\${home_dir}}"
            printf '%s\n' "\${configured_dir}"
            return 0
        fi
    fi

    if [[ -d "\${home_dir}/桌面" ]]; then
        printf '%s\n' "\${home_dir}/桌面"
        return 0
    fi

    printf '%s\n' "\${home_dir}/Desktop"
}

install_desktop_icon() {
    local target_user
    target_user="\$(find_target_user || true)"
    [[ -n "\${target_user}" ]] || return 0

    local desktop_dir
    desktop_dir="\$(desktop_dir_for_user "\${target_user}" || true)"
    [[ -n "\${desktop_dir}" ]] || return 0

    local target_group
    target_group="\$(id -gn "\${target_user}" 2>/dev/null || printf '%s' "\${target_user}")"
    install -d -m 0755 -o "\${target_user}" -g "\${target_group}" "\${desktop_dir}"

    local desktop_file="\${desktop_dir}/\${APP_ID}.desktop"
    cp "/usr/share/applications/\${APP_ID}.desktop" "\${desktop_file}"
    chmod 0755 "\${desktop_file}"
    chown "\${target_user}:\${target_group}" "\${desktop_file}"

    if command -v runuser >/dev/null 2>&1 && command -v gio >/dev/null 2>&1; then
        local target_uid
        local target_home
        local runtime_dir
        local session_bus
        target_uid="\$(id -u "\${target_user}" 2>/dev/null || true)"
        target_home="\$(user_home "\${target_user}")"
        runtime_dir="/run/user/\${target_uid}"
        session_bus="unix:path=\${runtime_dir}/bus"

        if [[ -n "\${target_uid}" && -S "\${runtime_dir}/bus" ]]; then
            HOME="\${target_home}" XDG_RUNTIME_DIR="\${runtime_dir}" DBUS_SESSION_BUS_ADDRESS="\${session_bus}" \
                runuser -u "\${target_user}" -- gio set "\${desktop_file}" metadata::trusted true >/dev/null 2>&1 || true
        else
            HOME="\${target_home}" runuser -u "\${target_user}" -- \
                gio set "\${desktop_file}" metadata::trusted true >/dev/null 2>&1 || true
        fi
    fi

    if command -v update-desktop-database >/dev/null 2>&1; then
        update-desktop-database /usr/share/applications >/dev/null 2>&1 || true
    fi
}

case "\${1:-}" in
    configure)
        install_desktop_icon
        ;;
esac

exit 0
EOF

    cat > "${deb_root}/DEBIAN/postrm" <<EOF
#!/usr/bin/env bash
set -Eeuo pipefail

APP_ID="${APP_ID}"

find_target_user() {
    if [[ -n "\${SUDO_USER:-}" && "\${SUDO_USER}" != "root" ]]; then
        printf '%s\n' "\${SUDO_USER}"
        return 0
    fi

    if [[ -n "\${PKEXEC_UID:-}" ]]; then
        getent passwd "\${PKEXEC_UID}" | cut -d: -f1
        return 0
    fi

    local login_user
    login_user="\$(logname 2>/dev/null || true)"
    if [[ -n "\${login_user}" && "\${login_user}" != "root" ]]; then
        printf '%s\n' "\${login_user}"
        return 0
    fi

    return 1
}

user_home() {
    getent passwd "\$1" | cut -d: -f6
}

desktop_dir_for_user() {
    local user="\$1"
    local home_dir
    home_dir="\$(user_home "\${user}")"
    [[ -n "\${home_dir}" ]] || return 1

    if command -v runuser >/dev/null 2>&1 && command -v xdg-user-dir >/dev/null 2>&1; then
        local xdg_dir
        xdg_dir="\$(HOME="\${home_dir}" runuser -u "\${user}" -- xdg-user-dir DESKTOP 2>/dev/null || true)"
        if [[ -n "\${xdg_dir}" && "\${xdg_dir}" != "\${home_dir}" ]]; then
            printf '%s\n' "\${xdg_dir}"
            return 0
        fi
    fi

    local user_dirs_file="\${home_dir}/.config/user-dirs.dirs"
    if [[ -f "\${user_dirs_file}" ]]; then
        local configured_dir
        configured_dir="\$(awk -F= '/^XDG_DESKTOP_DIR=/ { gsub(/"/, "", \$2); print \$2; exit }' "\${user_dirs_file}")"
        if [[ -n "\${configured_dir}" ]]; then
            configured_dir="\${configured_dir//\\\$HOME/\${home_dir}}"
            printf '%s\n' "\${configured_dir}"
            return 0
        fi
    fi

    printf '%s\n' "\${home_dir}/桌面"
    printf '%s\n' "\${home_dir}/Desktop"
}

remove_desktop_icon_for_user() {
    local target_user="\$1"
    local desktop_dir
    while IFS= read -r desktop_dir; do
        [[ -n "\${desktop_dir}" ]] || continue
        rm -f "\${desktop_dir}/\${APP_ID}.desktop"
    done < <(desktop_dir_for_user "\${target_user}" || true)
}

remove_desktop_icons() {
    local target_user
    target_user="\$(find_target_user || true)"
    if [[ -n "\${target_user}" ]]; then
        remove_desktop_icon_for_user "\${target_user}"
        return 0
    fi

    while IFS=: read -r user _ uid _ _ home_dir _; do
        [[ "\${uid}" =~ ^[0-9]+$ ]] || continue
        [[ "\${uid}" -ge 1000 ]] || continue
        [[ -d "\${home_dir}" ]] || continue
        remove_desktop_icon_for_user "\${user}"
    done < /etc/passwd
}

case "\${1:-}" in
    remove|purge)
        remove_desktop_icons
        ;;
esac

exit 0
EOF

    local installed_size
    installed_size="$(du -sk "${deb_root}/opt" "${deb_root}/usr" | awk '{sum += $1} END {print sum}')"

    cat > "${deb_root}/DEBIAN/control" <<EOF
Package: ${APP_ID}
Version: ${APP_VERSION}
Section: utils
Priority: optional
Architecture: ${arch}
Maintainer: ${APP_MAINTAINER}
Installed-Size: ${installed_size}
Description: ${APP_DISPLAY_NAME} 桌面客户端
 使用 PySide6/QML 构建，支持离线 dpkg 安装。
EOF

    find "${deb_root}" -type d -exec chmod 0755 {} +
    chmod 0755 "${deb_root}/DEBIAN/postinst" "${deb_root}/DEBIAN/postrm"
    dpkg-deb --root-owner-group -Zxz -z9 --build "${deb_root}" "${deb_path}"
    find "${DIST_ROOT}" -mindepth 1 -maxdepth 1 ! -name "$(basename "${deb_path}")" -exec rm -rf {} +
    log "deb 输出: ${deb_path}"
    log "目标机安装命令: sudo dpkg -i ${APP_ID}_${APP_VERSION}_${arch}.deb"
}

main() {
    prepare_dirs
    build_app
    write_launcher
    prune_qt_bundle
    bundle_system_libs
    bundle_glibc_runtime
    strip_elf_files
    report_bundle_size

    make_deb_package
}

main "$@"
