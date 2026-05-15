#!/usr/bin/env python3
"""
为 PySide6 的 Qt 运行时生成最小的 CMake 配置文件，用于编译 fcitx5-qt 插件。

用法: python generate_qt6_cmake.py <QT6_PREFIX>
"""
from __future__ import annotations

import sys
from pathlib import Path


def get_qt_version() -> str:
    import PySide6.QtCore
    return PySide6.QtCore.qVersion()


def find_lib(lib_dir: Path, name: str) -> str:
    for pattern in [f"lib{name}.so", f"lib{name}.so.*"]:
        matches = list(lib_dir.glob(pattern))
        if matches:
            return str(sorted(matches, key=lambda p: len(str(p)))[0])
    return f"{lib_dir}/lib{name}.so"


def main() -> None:
    if len(sys.argv) < 2:
        print(f"用法: {sys.argv[0]} <QT6_PREFIX>", file=sys.stderr)
        sys.exit(1)

    prefix = Path(sys.argv[1]).resolve()
    lib_dir = prefix / "lib"
    cmake_base = lib_dir / "cmake"
    version = get_qt_version()
    major, minor, patch = version.split(".")

    print(f"Generating Qt6 CMake configs: version={version}, prefix={prefix}")

    # Qt6Config.cmake
    qt6_dir = cmake_base / "Qt6"
    qt6_dir.mkdir(parents=True, exist_ok=True)

    (qt6_dir / "Qt6Config.cmake").write_text(f"""\
cmake_minimum_required(VERSION 3.16)
set(QT_VERSION_MAJOR {major})
set(QT_VERSION_MINOR {minor})
set(QT_VERSION_PATCH {patch})
set(QT_VERSION "{version}")
set(Qt6_VERSION "{version}")
set(Qt6_VERSION_MAJOR {major})
set(Qt6_VERSION_MINOR {minor})
set(Qt6_VERSION_PATCH {patch})
set(Qt6_FOUND TRUE)
set(QT6_INSTALL_PREFIX "{prefix}")

macro(qt6_find_component comp)
    set(Qt6${{comp}}_FOUND TRUE)
    include("${{CMAKE_CURRENT_LIST_DIR}}/../Qt6${{comp}}/Qt6${{comp}}Config.cmake" OPTIONAL)
endmacro()

if(Qt6_FIND_COMPONENTS)
    foreach(_comp ${{Qt6_FIND_COMPONENTS}})
        qt6_find_component(${{_comp}})
    endforeach()
endif()
""")

    (qt6_dir / "Qt6ConfigVersion.cmake").write_text(f"""\
set(PACKAGE_VERSION "{version}")
if(PACKAGE_FIND_VERSION_MAJOR STREQUAL "{major}")
    set(PACKAGE_VERSION_COMPATIBLE TRUE)
    if(PACKAGE_FIND_VERSION VERSION_EQUAL PACKAGE_VERSION)
        set(PACKAGE_VERSION_EXACT TRUE)
    endif()
else()
    set(PACKAGE_VERSION_COMPATIBLE FALSE)
endif()
""")

    # Component configs
    components = {
        "Core": {"subdirs": ["QtCore"], "deps": []},
        "Gui": {"subdirs": ["QtGui"], "deps": ["Core"]},
        "Widgets": {"subdirs": ["QtWidgets"], "deps": ["Core", "Gui"]},
        "DBus": {"subdirs": ["QtDBus"], "deps": ["Core"]},
    }

    for comp, info in components.items():
        comp_dir = cmake_base / f"Qt6{comp}"
        comp_dir.mkdir(parents=True, exist_ok=True)

        lib_file = find_lib(lib_dir, f"Qt6{comp}")
        include_dirs = ";".join(
            [str(prefix / "include")] +
            [str(prefix / "include" / d) for d in info["subdirs"]]
        )
        dep_libs = ""
        if info["deps"]:
            dep_libs = '\n  INTERFACE_LINK_LIBRARIES "' + ";".join(f"Qt6::{d}" for d in info["deps"]) + '"'

        (comp_dir / f"Qt6{comp}Config.cmake").write_text(f"""\
set(Qt6{comp}_FOUND TRUE)
set(Qt6{comp}_VERSION "{version}")
if(NOT TARGET Qt6::{comp})
    add_library(Qt6::{comp} SHARED IMPORTED)
    set_target_properties(Qt6::{comp} PROPERTIES
      IMPORTED_LOCATION "{lib_file}"
      INTERFACE_INCLUDE_DIRECTORIES "{include_dirs}"{dep_libs}
    )
endif()
set(Qt6{comp}_INCLUDE_DIRS "{include_dirs}")
set(Qt6{comp}_LIBRARIES "{lib_file}")
""")

        (comp_dir / f"Qt6{comp}ConfigVersion.cmake").write_text(f"""\
set(PACKAGE_VERSION "{version}")
set(PACKAGE_VERSION_COMPATIBLE TRUE)
set(PACKAGE_VERSION_EXACT TRUE)
""")

    print("Done.")


if __name__ == "__main__":
    main()
