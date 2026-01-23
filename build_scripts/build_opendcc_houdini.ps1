# ============================================================================
# Build OpenDCC using Houdini's USD and VFX Libraries (PowerShell)
# ============================================================================
# This script builds OpenDCC against Houdini's bundled USD and dependencies.
# This is MUCH faster than building USD from scratch.
#
# Prerequisites:
#   - Houdini 19.5+ installed (Apprentice/Indie/FX)
#   - Visual Studio 2019 or 2022 installed
#   - Qt5 5.15.x installed
#   - PySide2 installed (pip install PySide2)
#
# Usage:
#   .\build_opendcc_houdini.ps1
#   .\build_opendcc_houdini.ps1 -HoudiniRoot "D:\Houdini20"
#   .\build_opendcc_houdini.ps1 -Qt5Dir "C:\Qt\5.15.14\msvc2019_64"
# ============================================================================

param(
    [string]$HoudiniRoot = "",
    [string]$Qt5Dir = "C:\Qt\5.15.2\msvc2019_64",
    [string]$VcpkgRoot = "C:\VFX\vcpkg",
    [string]$InstallDir = "C:\VFX\OpenDCC_houdini",
    [switch]$Clean,
    [switch]$SkipVcpkg,
    [int]$Jobs = 0
)

$ErrorActionPreference = "Stop"

# Colors
function Write-Header($text) {
    Write-Host "`n============================================================================" -ForegroundColor Cyan
    Write-Host $text -ForegroundColor Cyan
    Write-Host "============================================================================`n" -ForegroundColor Cyan
}

function Write-Success($text) { Write-Host $text -ForegroundColor Green }
function Write-Warn($text) { Write-Host $text -ForegroundColor Yellow }
function Write-Err($text) { Write-Host $text -ForegroundColor Red }
function Write-Info($text) { Write-Host $text -ForegroundColor White }

# ============================================================================
# Find Houdini
# ============================================================================

Write-Header "Building OpenDCC with Houdini USD"

if (-not $HoudiniRoot) {
    Write-Info "Searching for Houdini installation..."

    $houdiniPaths = @(
        "C:\Program Files\Side Effects Software\Houdini 20*",
        "C:\Program Files\Side Effects Software\Houdini 19*",
        "D:\Program Files\Side Effects Software\Houdini 20*",
        "D:\Program Files\Side Effects Software\Houdini 19*"
    )

    foreach ($pattern in $houdiniPaths) {
        $found = Get-Item -Path $pattern -ErrorAction SilentlyContinue | Sort-Object Name -Descending | Select-Object -First 1
        if ($found) {
            $HoudiniRoot = $found.FullName
            break
        }
    }
}

if (-not $HoudiniRoot -or -not (Test-Path $HoudiniRoot)) {
    Write-Err "ERROR: Houdini not found!"
    Write-Info ""
    Write-Info "Please install Houdini from https://www.sidefx.com/download/"
    Write-Info "Or specify path: .\build_opendcc_houdini.ps1 -HoudiniRoot 'C:\Path\To\Houdini'"
    exit 1
}

$usdHeader = Join-Path $HoudiniRoot "toolkit\include\pxr\pxr.h"
if (-not (Test-Path $usdHeader)) {
    Write-Err "ERROR: USD not found in Houdini installation!"
    Write-Info "Expected: $usdHeader"
    exit 1
}

$houdiniVersion = Split-Path $HoudiniRoot -Leaf
Write-Success "Found Houdini: $HoudiniRoot"
Write-Info "Version: $houdiniVersion"

# ============================================================================
# Check Qt5
# ============================================================================

Write-Header "Checking Prerequisites"

$qt5Core = Join-Path $Qt5Dir "bin\Qt5Core.dll"
if (-not (Test-Path $qt5Core)) {
    Write-Warn "Qt5 not found at $Qt5Dir"
    Write-Info ""
    Write-Info "Please install Qt5 from https://www.qt.io/download-qt-installer"
    Write-Info "Then run: .\build_opendcc_houdini.ps1 -Qt5Dir 'C:\Qt\5.15.x\msvc2019_64'"
    Write-Info ""

    # Try to find Qt5
    $qtPaths = @(
        "C:\Qt\5.15*\msvc2019_64",
        "C:\Qt\5.15*\msvc2022_64",
        "D:\Qt\5.15*\msvc2019_64"
    )

    foreach ($pattern in $qtPaths) {
        $found = Get-Item -Path $pattern -ErrorAction SilentlyContinue | Sort-Object Name -Descending | Select-Object -First 1
        if ($found -and (Test-Path (Join-Path $found.FullName "bin\Qt5Core.dll"))) {
            Write-Info "Found Qt5 at: $($found.FullName)"
            $confirm = Read-Host "Use this path? (Y/N)"
            if ($confirm -eq 'Y' -or $confirm -eq 'y') {
                $Qt5Dir = $found.FullName
                break
            }
        }
    }

    if (-not (Test-Path (Join-Path $Qt5Dir "bin\Qt5Core.dll"))) {
        Write-Err "Qt5 is required. Please install it and try again."
        exit 1
    }
}
Write-Success "Found Qt5: $Qt5Dir"

# ============================================================================
# Check Python and PySide2
# ============================================================================

try {
    $pythonVersion = python --version 2>&1
    Write-Success "Found Python: $pythonVersion"
} catch {
    Write-Err "Python not found in PATH"
    exit 1
}

try {
    python -c "import PySide2" 2>&1 | Out-Null
    Write-Success "Found PySide2"
} catch {
    Write-Warn "PySide2 not found, installing..."
    pip install PySide2
}

# Find Shiboken
try {
    $shibokenPath = python -c "import shiboken2_generator, os; print(os.path.dirname(shiboken2_generator.__file__))" 2>&1
    if ($LASTEXITCODE -ne 0) {
        $shibokenPath = python -c "import PySide2, os; print(os.path.dirname(PySide2.__file__))" 2>&1
    }
    Write-Success "Found Shiboken: $shibokenPath"
} catch {
    Write-Err "Could not find Shiboken directory"
    exit 1
}

# ============================================================================
# Setup vcpkg
# ============================================================================

if (-not $SkipVcpkg) {
    Write-Header "Setting up vcpkg dependencies"

    if (-not (Test-Path (Join-Path $VcpkgRoot "vcpkg.exe"))) {
        Write-Warn "vcpkg not found at $VcpkgRoot"
        $install = Read-Host "Install vcpkg now? (Y/N)"

        if ($install -eq 'Y' -or $install -eq 'y') {
            Write-Info "Installing vcpkg..."
            New-Item -ItemType Directory -Path "C:\VFX" -Force | Out-Null
            Set-Location "C:\VFX"
            git clone https://github.com/microsoft/vcpkg.git
            Set-Location vcpkg
            & .\bootstrap-vcpkg.bat
            $VcpkgRoot = "C:\VFX\vcpkg"
        } else {
            Write-Err "vcpkg is required for remaining dependencies"
            exit 1
        }
    }

    Write-Success "Found vcpkg: $VcpkgRoot"

    # Install dependencies
    $packages = @("zeromq:x64-windows", "eigen3:x64-windows", "doctest:x64-windows")

    Set-Location $VcpkgRoot
    foreach ($pkg in $packages) {
        $pkgName = $pkg.Split(":")[0]
        Write-Info "Checking $pkgName..."
        & .\vcpkg.exe install $pkg
    }
}

# ============================================================================
# Configure OpenDCC
# ============================================================================

Write-Header "Configuring OpenDCC"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$sourceDir = Split-Path -Parent $scriptDir
$buildDir = Join-Path $sourceDir "build_houdini"

Write-Info "Source:  $sourceDir"
Write-Info "Build:   $buildDir"
Write-Info "Install: $InstallDir"

if ($Clean -and (Test-Path $buildDir)) {
    Write-Info "Cleaning build directory..."
    Remove-Item -Recurse -Force $buildDir
}

New-Item -ItemType Directory -Path $buildDir -Force | Out-Null
Set-Location $buildDir

# Detect VS generator
$vsGenerator = "Visual Studio 17 2022"
if ($env:VisualStudioVersion -eq "16.0") {
    $vsGenerator = "Visual Studio 16 2019"
}

Write-Info ""
Write-Info "Configuration:"
Write-Info "  Houdini:   $HoudiniRoot"
Write-Info "  Qt5:       $Qt5Dir"
Write-Info "  vcpkg:     $VcpkgRoot"
Write-Info "  Shiboken:  $shibokenPath"
Write-Info "  Generator: $vsGenerator"
Write-Info ""

$cmakeArgs = @(
    "-G", $vsGenerator,
    "-A", "x64",
    "-DDCC_HOUDINI_SUPPORT=ON",
    "-DHOUDINI_ROOT=$HoudiniRoot",
    "-DCMAKE_PREFIX_PATH=$Qt5Dir;$VcpkgRoot\installed\x64-windows",
    "-DCMAKE_TOOLCHAIN_FILE=$VcpkgRoot\scripts\buildsystems\vcpkg.cmake",
    "-DSHIBOKEN_CLANG_INSTALL_DIR=$shibokenPath",
    "-DCMAKE_INSTALL_PREFIX=$InstallDir",
    "-DCMAKE_BUILD_TYPE=Release",
    "-DDCC_BUILD_ARNOLD_SUPPORT=OFF",
    "-DDCC_BUILD_CYCLES_SUPPORT=OFF",
    "-DDCC_BUILD_RENDERMAN_SUPPORT=OFF",
    "-DDCC_BUILD_BULLET_PHYSICS=OFF",
    "-DDCC_BUILD_HYDRA_OP=OFF",
    "-DDCC_BUILD_TESTS=ON",
    $sourceDir
)

Write-Info "Running CMake configure..."
& cmake @cmakeArgs

if ($LASTEXITCODE -ne 0) {
    Write-Err "CMake configuration failed!"
    Write-Info ""
    Write-Info "Check errors above. Common issues:"
    Write-Info "  - Missing Qt5 LinguistTools"
    Write-Info "  - Missing sentry or qtadvanceddocking"
    Write-Info ""
    Write-Info "Error log: $buildDir\CMakeFiles\CMakeError.log"
    exit 1
}

Write-Success "CMake configuration successful!"

# ============================================================================
# Build OpenDCC
# ============================================================================

Write-Header "Building OpenDCC"

if ($Jobs -eq 0) {
    $Jobs = [Math]::Min((Get-CimInstance Win32_Processor).NumberOfLogicalProcessors, 8)
}

Write-Info "Building with $Jobs parallel jobs..."
Write-Info "This may take 30-60 minutes."

$startTime = Get-Date

& cmake --build . --config Release --parallel $Jobs

if ($LASTEXITCODE -ne 0) {
    Write-Err "Build failed!"
    exit 1
}

$buildTime = (Get-Date) - $startTime
Write-Success "Build completed in $($buildTime.ToString('hh\:mm\:ss'))"

# ============================================================================
# Install OpenDCC
# ============================================================================

Write-Header "Installing OpenDCC"

& cmake --install . --config Release

if ($LASTEXITCODE -ne 0) {
    Write-Err "Install failed!"
    exit 1
}

Write-Success "Installation successful!"

# ============================================================================
# Create launch scripts
# ============================================================================

Write-Header "Creating launch scripts"

# Batch launcher
$batLauncher = Join-Path $InstallDir "run_opendcc.bat"
@"
@echo off
REM OpenDCC Launch Script (Houdini Build)

REM Houdini environment
set "HOUDINI_ROOT=$HoudiniRoot"
set "PATH=%HOUDINI_ROOT%\bin;%PATH%"

REM Qt environment
set "PATH=$Qt5Dir\bin;%PATH%"

REM OpenDCC environment
set "OPENDCC_ROOT=%~dp0"
set "PATH=%OPENDCC_ROOT%\bin;%PATH%"
set "PYTHONPATH=%OPENDCC_ROOT%\lib\python;%PYTHONPATH%"

REM Launch OpenDCC
"%OPENDCC_ROOT%\bin\dcc_base.exe" %*
"@ | Out-File -FilePath $batLauncher -Encoding ASCII

Write-Success "Created: $batLauncher"

# PowerShell launcher
$ps1Launcher = Join-Path $InstallDir "run_opendcc.ps1"
@"
# OpenDCC Launch Script (Houdini Build)

`$env:HOUDINI_ROOT = "$HoudiniRoot"
`$env:PATH = "$HoudiniRoot\bin;$Qt5Dir\bin;`$PSScriptRoot\bin;" + `$env:PATH
`$env:PYTHONPATH = "`$PSScriptRoot\lib\python;" + `$env:PYTHONPATH

& "`$PSScriptRoot\bin\dcc_base.exe" @args
"@ | Out-File -FilePath $ps1Launcher -Encoding UTF8

Write-Success "Created: $ps1Launcher"

# ============================================================================
# Done!
# ============================================================================

Write-Header "SUCCESS! OpenDCC built with Houdini USD"

Write-Success "Installation: $InstallDir"
Write-Info ""
Write-Info "To run OpenDCC:"
Write-Info "  $batLauncher"
Write-Info ""
Write-Info "Or with Python shell:"
Write-Info "  $batLauncher --shell"
Write-Info ""
Write-Info "Or run tests:"
Write-Info "  $batLauncher --with-tests"
Write-Info ""
Write-Success "Build time: $($buildTime.ToString('hh\:mm\:ss'))"
