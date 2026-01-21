# ============================================================================
# Build USD with all dependencies needed for OpenDCC (PowerShell version)
# ============================================================================
# This script builds USD using build_usd.py with all the dependencies
# required by OpenDCC. It will take 1-4 hours depending on your system.
#
# Prerequisites:
#   - Visual Studio 2019 or 2022 installed
#   - Python 3.9 or 3.10 installed and in PATH
#   - CMake installed
#   - NASM installed and in PATH
#
# Usage:
#   From Visual Studio Developer PowerShell:
#   .\build_usd_for_opendcc.ps1
#
#   Or from regular PowerShell (will attempt to load VS tools):
#   .\build_usd_for_opendcc.ps1 -AutoLoadVS
# ============================================================================

param(
    [string]$VfxRoot = "C:\VFX",
    [string]$BuildType = "release",
    [switch]$AutoLoadVS,
    [switch]$SkipTests,
    [int]$Jobs = 0
)

$ErrorActionPreference = "Stop"

# Colors for output
function Write-Header($text) {
    Write-Host "`n============================================================================" -ForegroundColor Cyan
    Write-Host $text -ForegroundColor Cyan
    Write-Host "============================================================================`n" -ForegroundColor Cyan
}

function Write-Success($text) {
    Write-Host $text -ForegroundColor Green
}

function Write-Warning($text) {
    Write-Host $text -ForegroundColor Yellow
}

function Write-Error($text) {
    Write-Host $text -ForegroundColor Red
}

function Write-Info($text) {
    Write-Host $text -ForegroundColor White
}

# Check if running in Visual Studio environment
function Test-VSEnvironment {
    if ($env:VSINSTALLDIR -or $env:VSCMD_ARG_TGT_ARCH -eq "x64") {
        return $true
    }
    return $false
}

# Load Visual Studio environment
function Initialize-VSEnvironment {
    Write-Header "Loading Visual Studio Environment"

    # Try to find VS 2022 first, then VS 2019
    $vsWhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"

    if (Test-Path $vsWhere) {
        $vsPath = & $vsWhere -latest -property installationPath
        if ($vsPath) {
            $vsDevCmd = Join-Path $vsPath "Common7\Tools\Launch-VsDevShell.ps1"
            if (Test-Path $vsDevCmd) {
                Write-Info "Found Visual Studio at: $vsPath"
                & $vsDevCmd -Arch amd64 -SkipAutomaticLocation
                Write-Success "Visual Studio environment loaded"
                return $true
            }
        }
    }

    Write-Error "Could not find Visual Studio 2019 or 2022"
    Write-Info "Please run this script from 'Developer PowerShell for VS' or pass -AutoLoadVS"
    return $false
}

# Main script
Write-Header "Building USD with OpenDCC Dependencies"

# Check/Load VS environment
if (-not (Test-VSEnvironment)) {
    if ($AutoLoadVS) {
        if (-not (Initialize-VSEnvironment)) {
            exit 1
        }
    } else {
        Write-Error "Not running in Visual Studio environment"
        Write-Info "Please run from 'Developer PowerShell for VS 2022/2019'"
        Write-Info "Or pass -AutoLoadVS parameter to auto-load"
        exit 1
    }
}

Write-Success "Running in Visual Studio environment"

# Check Python
Write-Header "Checking Prerequisites"

try {
    $pythonVersion = python --version 2>&1
    Write-Success "Python found: $pythonVersion"

    # Check Python version
    $versionMatch = $pythonVersion -match "Python (\d+)\.(\d+)"
    if ($versionMatch) {
        $major = [int]$Matches[1]
        $minor = [int]$Matches[2]

        if ($major -eq 3 -and ($minor -eq 9 -or $minor -eq 10 -or $minor -eq 11)) {
            Write-Success "Python version is compatible with VFX Platform"
        } else {
            Write-Warning "Python version should be 3.9, 3.10, or 3.11 for VFX Platform"
            Write-Warning "Current: Python $major.$minor"
            $continue = Read-Host "Continue anyway? (Y/N)"
            if ($continue -ne 'Y' -and $continue -ne 'y') {
                exit 1
            }
        }
    }
} catch {
    Write-Error "Python not found in PATH"
    Write-Info "Install Python 3.9 or 3.10 from https://www.python.org/"
    exit 1
}

# Check CMake
try {
    $cmakeVersion = cmake --version | Select-Object -First 1
    Write-Success "CMake found: $cmakeVersion"
} catch {
    Write-Error "CMake not found in PATH"
    Write-Info "Install CMake from https://cmake.org/ or run: pip install cmake"
    exit 1
}

# Check NASM (optional but recommended)
try {
    $nasmVersion = nasm -v 2>&1 | Select-Object -First 1
    Write-Success "NASM found: $nasmVersion"
} catch {
    Write-Warning "NASM not found in PATH"
    Write-Warning "Some image format builds may fail without NASM"
    Write-Info "Download from: https://www.nasm.us/"
    $continue = Read-Host "Continue anyway? (Y/N)"
    if ($continue -ne 'Y' -and $continue -ne 'y') {
        exit 1
    }
}

# Configure paths
Write-Header "Configuration"

$usdSource = Join-Path $VfxRoot "OpenUSD"
$usdInstall = Join-Path $VfxRoot "USD_install"

# Detect Visual Studio version
$vsVersion = "2022"
$vsGenerator = "Visual Studio 17 2022"
if ($env:VisualStudioVersion -eq "16.0") {
    $vsVersion = "2019"
    $vsGenerator = "Visual Studio 16 2019"
}

# Determine number of parallel jobs
if ($Jobs -eq 0) {
    $Jobs = (Get-CimInstance -ClassName Win32_Processor).NumberOfLogicalProcessors
    if ($Jobs -gt 16) { $Jobs = 16 }
}

Write-Info "VFX Root Directory:     $VfxRoot"
Write-Info "USD Source:             $usdSource"
Write-Info "USD Install Location:   $usdInstall"
Write-Info "Build Type:             $BuildType"
Write-Info "Visual Studio:          $vsVersion"
Write-Info "CMake Generator:        $vsGenerator"
Write-Info "Parallel Jobs:          $Jobs"
Write-Info ""
Write-Warning "This will build USD and dependencies to: $usdInstall"
Write-Warning "Estimated time: 1-4 hours"
Write-Warning "Estimated disk space: ~30 GB during build, ~10 GB after"
Write-Info ""

$confirm = Read-Host "Continue? (Y/N)"
if ($confirm -ne 'Y' -and $confirm -ne 'y') {
    Write-Info "Build cancelled"
    exit 0
}

# Create directories
Write-Header "Step 1: Preparing directories and cloning USD"

if (-not (Test-Path $VfxRoot)) {
    Write-Info "Creating $VfxRoot..."
    New-Item -ItemType Directory -Path $VfxRoot | Out-Null
}

Set-Location $VfxRoot

if (Test-Path $usdSource) {
    Write-Info "USD source already exists at $usdSource"
    $update = Read-Host "Update existing repository? (Y/N)"
    if ($update -eq 'Y' -or $update -eq 'y') {
        Set-Location $usdSource
        Write-Info "Pulling latest changes..."
        git pull
    }
} else {
    Write-Info "Cloning USD repository..."
    git clone https://github.com/PixarAnimationStudios/OpenUSD.git
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to clone USD repository"
        exit 1
    }
}

# Run build_usd.py
Write-Header "Step 2: Running build_usd.py"

Write-Info "Building USD with the following options:"
Write-Info "  --python           : Python bindings (required for OpenDCC)"
Write-Info "  --imaging          : Imaging components (required for OpenDCC)"
Write-Info "  --openimageio      : OpenImageIO (required for OpenDCC)"
Write-Info "  --opencolorio      : OpenColorIO (required for OpenDCC)"
Write-Info "  --alembic          : Alembic support (required for OpenDCC)"
Write-Info "  --embree           : Embree ray tracing (required for OpenDCC)"
Write-Info "  --materialx        : MaterialX shading (enabled by default)"
Write-Info "  --onetbb           : Use OneTBB instead of TBB (VFX Platform 2023+)"
Write-Info ""
Write-Info "This will automatically build:"
Write-Info "  - USD, Boost, TBB/OneTBB, OpenEXR, Imath, OpenSubdiv"
Write-Info "  - OpenImageIO, OpenColorIO, GLEW, Embree, Alembic, MaterialX"
Write-Info "  - Image format libraries (JPEG, PNG, TIFF, etc.)"
Write-Info ""
Write-Warning "Starting build in 5 seconds... (Press Ctrl+C to cancel)"

Start-Sleep -Seconds 5

Set-Location $usdSource

$buildArgs = @(
    "build_scripts\build_usd.py",
    "--build-variant", $BuildType,
    "--generator", $vsGenerator,
    "-j", $Jobs,
    "--python",
    "--imaging",
    "--openimageio",
    "--opencolorio",
    "--alembic",
    "--embree",
    "--materialx",
    "--onetbb"
)

if (-not $SkipTests) {
    $buildArgs += "--tests"
}

$buildArgs += $usdInstall

Write-Info "Running: python $($buildArgs -join ' ')"
Write-Info ""

$startTime = Get-Date

& python @buildArgs

if ($LASTEXITCODE -ne 0) {
    Write-Header "BUILD FAILED"
    Write-Error "The USD build failed. Check the error messages above."
    Write-Info ""
    Write-Info "Common solutions:"
    Write-Info "  1. Ensure you are running from VS Developer PowerShell"
    Write-Info "  2. Check you have enough disk space (~30 GB)"
    Write-Info "  3. Try building without optional components first"
    Write-Info "  4. Check Python version is 3.9, 3.10, or 3.11"
    Write-Info ""
    Write-Info "For a minimal build, edit this script and remove:"
    Write-Info "  --openimageio --opencolorio --alembic --embree"
    exit 1
}

$endTime = Get-Date
$duration = $endTime - $startTime

# Verify build
Write-Header "Step 3: Verifying build"

$usdcatPath = Join-Path $usdInstall "bin\usdcat.exe"
if (-not (Test-Path $usdcatPath)) {
    Write-Error "Build completed but usdcat.exe not found"
    Write-Error "Build may have failed silently"
    exit 1
}

Write-Info "Testing USD installation..."
& $usdcatPath --version
if ($LASTEXITCODE -ne 0) {
    Write-Error "usdcat.exe failed to run"
    exit 1
}

Write-Info ""
Write-Info "Testing Python USD import..."
$env:USD_ROOT = $usdInstall
$env:PYTHONPATH = (Join-Path $usdInstall "lib\python") + ";" + $env:PYTHONPATH
$env:PATH = (Join-Path $usdInstall "bin") + ";" + (Join-Path $usdInstall "lib") + ";" + $env:PATH

$testScript = "from pxr import Usd; print('USD version:', Usd.GetVersion())"
& python -c $testScript
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to import USD in Python"
    exit 1
}

# Success!
Write-Header "SUCCESS! USD built successfully"
Write-Success "Build completed in: $($duration.ToString('hh\:mm\:ss'))"
Write-Info ""
Write-Info "Installation location: $usdInstall"
Write-Info ""
Write-Info "Next steps:"
Write-Info "  1. Set environment variables (see usd_env.bat)"
Write-Info "  2. Install Qt5 and PySide2 (Phase 2)"
Write-Info "  3. Build remaining dependencies (Phase 3)"
Write-Info "  4. Build OpenDCC (Phase 4)"
Write-Info ""

# Create environment setup script
Write-Info "Creating environment setup scripts..."

# Batch file version
$envBat = Join-Path $usdInstall "usd_env.bat"
@"
@echo off
REM USD Environment Setup
REM Source: Generated by build_usd_for_opendcc.ps1

set "USD_ROOT=$usdInstall"
set "PATH=$usdInstall\bin;$usdInstall\lib;%PATH%"
set "PYTHONPATH=$usdInstall\lib\python;%PYTHONPATH%"

echo USD environment set up:
echo   USD_ROOT=%USD_ROOT%
echo.
echo Test with: python -c "from pxr import Usd; print(Usd.GetVersion())"
"@ | Out-File -FilePath $envBat -Encoding ASCII

Write-Success "Created: $envBat"

# PowerShell version
$envPs1 = Join-Path $usdInstall "usd_env.ps1"
@"
# USD Environment Setup
# Source: Generated by build_usd_for_opendcc.ps1

`$env:USD_ROOT = "$usdInstall"
`$env:PATH = "$usdInstall\bin;$usdInstall\lib;" + `$env:PATH
`$env:PYTHONPATH = "$usdInstall\lib\python;" + `$env:PYTHONPATH

Write-Host "USD environment set up:" -ForegroundColor Green
Write-Host "  USD_ROOT=`$env:USD_ROOT"
Write-Host ""
Write-Host "Test with: python -c `"from pxr import Usd; print(Usd.GetVersion())`""
"@ | Out-File -FilePath $envPs1 -Encoding UTF8

Write-Success "Created: $envPs1"

Write-Info ""
Write-Info "To use USD in future sessions, run:"
Write-Info "  Batch:      $envBat"
Write-Info "  PowerShell: . $envPs1"
Write-Info ""

Write-Header "Build Summary"
Write-Success "✓ USD built successfully"
Write-Success "✓ All dependencies included"
Write-Success "✓ Python bindings working"
Write-Success "✓ Environment scripts created"
Write-Info ""
Write-Info "Build time: $($duration.ToString('hh\:mm\:ss'))"
Write-Info "Install size: $((Get-ChildItem $usdInstall -Recurse | Measure-Object -Property Length -Sum).Sum / 1GB | ForEach-Object { '{0:N2} GB' -f $_ })"
Write-Info ""
Write-Success "Ready for Phase 2: Install Qt5 and PySide2"
