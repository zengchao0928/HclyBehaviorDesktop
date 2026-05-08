Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Read-AppVersion {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    if (-not [string]::IsNullOrWhiteSpace($env:APP_VERSION)) {
        return $env:APP_VERSION
    }

    $settingsPath = Join-Path $ProjectRoot "src/config/settings.py"
    $script = @"
import ast
import sys
from pathlib import Path

values = {}
module = ast.parse(Path(sys.argv[1]).read_text(encoding="utf-8"))
for node in module.body:
    if not isinstance(node, ast.Assign) or len(node.targets) != 1:
        continue
    target = node.targets[0]
    if not isinstance(target, ast.Name):
        continue
    try:
        values[target.id] = ast.literal_eval(node.value)
    except (ValueError, SyntaxError):
        if isinstance(node.value, ast.Name):
            values[target.id] = values.get(node.value.id, "")

print(values.get("APP_VERSION") or values.get("APP_VERSION_NAME") or "1.0.0")
"@

    return (python -c $script $settingsPath).Trim()
}

function Read-DefaultBaseUrl {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    $settingsPath = Join-Path $ProjectRoot "src/config/settings.py"
    $script = @"
import ast
import sys
from pathlib import Path

values = {}
module = ast.parse(Path(sys.argv[1]).read_text(encoding="utf-8"))
for node in module.body:
    if not isinstance(node, ast.Assign) or len(node.targets) != 1:
        continue
    target = node.targets[0]
    if not isinstance(target, ast.Name):
        continue
    try:
        values[target.id] = ast.literal_eval(node.value)
    except (ValueError, SyntaxError):
        pass

print(values.get("DEFAULT_API_BASE_URL") or "http://10.1.100.126:8085/")
"@

    return (python -c $script $settingsPath).Trim()
}

$ScriptDir = Split-Path -Parent $PSCommandPath
$ProjectRoot = (Resolve-Path (Join-Path $ScriptDir "..")).Path
$AppId = if ([string]::IsNullOrWhiteSpace($env:APP_ID)) { "hcly-behavior-desktop" } else { $env:APP_ID }
$AppVersion = Read-AppVersion -ProjectRoot $ProjectRoot
$DefaultBaseUrl = Read-DefaultBaseUrl -ProjectRoot $ProjectRoot

$DistRoot = Join-Path $ProjectRoot "dist/windows-x64"
$WorkRoot = Join-Path $ProjectRoot "build/pyinstaller-windows-x64"
$BundleDir = Join-Path $DistRoot $AppId
$ExePath = Join-Path $BundleDir "$AppId.exe"

Write-Host "==> 构建 Windows x64 exe: $AppId $AppVersion"

Remove-Item -Recurse -Force $DistRoot, $WorkRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path $DistRoot, $WorkRoot | Out-Null

$hiddenImports = @(
    "PySide6.QtCore",
    "PySide6.QtGui",
    "PySide6.QtNetwork",
    "PySide6.QtOpenGL",
    "PySide6.QtQml",
    "PySide6.QtQuick",
    "PySide6.QtQuickControls2",
    "PySide6.QtQuickLayouts",
    "PySide6.QtSvg"
)

$excludedModules = @(
    "PySide6.Qt3DAnimation",
    "PySide6.Qt3DCore",
    "PySide6.Qt3DExtras",
    "PySide6.Qt3DInput",
    "PySide6.Qt3DLogic",
    "PySide6.Qt3DRender",
    "PySide6.QtBluetooth",
    "PySide6.QtCharts",
    "PySide6.QtDataVisualization",
    "PySide6.QtDesigner",
    "PySide6.QtHelp",
    "PySide6.QtLocation",
    "PySide6.QtMultimedia",
    "PySide6.QtMultimediaWidgets",
    "PySide6.QtPdf",
    "PySide6.QtPdfWidgets",
    "PySide6.QtPositioning",
    "PySide6.QtPrintSupport",
    "PySide6.QtRemoteObjects",
    "PySide6.QtScxml",
    "PySide6.QtSensors",
    "PySide6.QtSerialBus",
    "PySide6.QtSerialPort",
    "PySide6.QtSpatialAudio",
    "PySide6.QtSql",
    "PySide6.QtStateMachine",
    "PySide6.QtTextToSpeech",
    "PySide6.QtUiTools",
    "PySide6.QtWebChannel",
    "PySide6.QtWebEngineCore",
    "PySide6.QtWebEngineQuick",
    "PySide6.QtWebEngineWidgets",
    "PySide6.QtWebSockets",
    "PySide6.QtWidgets"
)

$pyinstallerArgs = @(
    "--clean",
    "--noconfirm",
    "--windowed",
    "--onedir",
    "--name", $AppId,
    "--distpath", $DistRoot,
    "--workpath", $WorkRoot,
    "--icon", (Join-Path $ProjectRoot "resources/icons/app_icon.ico"),
    "--collect-submodules", "src",
    "--collect-submodules", "library.network_chucker",
    "--add-data", "$(Join-Path $ProjectRoot "qml");qml",
    "--add-data", "$(Join-Path $ProjectRoot "resources");resources",
    "--add-data", "$(Join-Path $ProjectRoot "library/network_chucker/qml");library/network_chucker/qml"
)

foreach ($hiddenImport in $hiddenImports) {
    $pyinstallerArgs += @("--hidden-import", $hiddenImport)
}

foreach ($excludedModule in $excludedModules) {
    $pyinstallerArgs += @("--exclude-module", $excludedModule)
}

$pyinstallerArgs += (Join-Path $ProjectRoot "main.py")

Push-Location $ProjectRoot
try {
    python -m PyInstaller @pyinstallerArgs
}
finally {
    Pop-Location
}

if (-not (Test-Path $ExePath)) {
    throw "未找到 Windows exe 输出: $ExePath"
}

$configPath = Join-Path $BundleDir "config.json"
@{ baseUrl = $DefaultBaseUrl } |
    ConvertTo-Json |
    Set-Content -Path $configPath -Encoding UTF8

Write-Host "==> Windows exe 输出: $ExePath"
