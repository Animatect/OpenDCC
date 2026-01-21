@echo off
REM ============================================================================
REM Build USD with all dependencies needed for OpenDCC
REM ============================================================================
REM This script builds USD using build_usd.py with all the dependencies
REM required by OpenDCC. It will take 1-4 hours depending on your system.
REM
REM Prerequisites:
REM   - Visual Studio 2019 or 2022 installed
REM   - Python 3.9 or 3.10 installed and in PATH
REM   - CMake installed
REM   - NASM installed and in PATH
REM   - Run from "x64 Native Tools Command Prompt for VS"
REM ============================================================================

echo ============================================================================
echo Building USD with OpenDCC Dependencies
echo ============================================================================
echo.

REM Check if running in Visual Studio command prompt
if not defined VSINSTALLDIR (
    echo ERROR: This script must be run from Visual Studio command prompt
    echo Please open "x64 Native Tools Command Prompt for VS 2022" or VS 2019
    echo and run this script again.
    pause
    exit /b 1
)

REM Check Python
python --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Python not found in PATH
    echo Please install Python 3.9 or 3.10 and add to PATH
    pause
    exit /b 1
)

echo Checking Python version...
python -c "import sys; v=sys.version_info; exit(0 if (v.major==3 and v.minor in [9,10,11]) else 1)"
if errorlevel 1 (
    echo WARNING: Python version should be 3.9, 3.10, or 3.11 for VFX Platform compatibility
    echo Current version:
    python --version
    echo.
    echo Continue anyway? (Y/N^)
    choice /c YN /n
    if errorlevel 2 exit /b 1
)

REM Check CMake
cmake --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: CMake not found in PATH
    echo Please install CMake 3.18+ and add to PATH
    pause
    exit /b 1
)

REM Check NASM (needed for some image libraries)
nasm -v >nul 2>&1
if errorlevel 1 (
    echo WARNING: NASM not found in PATH
    echo Some image format builds may fail without NASM
    echo Download from: https://www.nasm.us/
    echo.
    echo Continue anyway? (Y/N^)
    choice /c YN /n
    if errorlevel 2 exit /b 1
)

echo.
echo ============================================================================
echo Configuration
echo ============================================================================

REM Configure paths - EDIT THESE if you want different locations
set "VFX_ROOT=C:\VFX"
set "USD_SOURCE=%VFX_ROOT%\OpenUSD"
set "USD_INSTALL=%VFX_ROOT%\USD_install"
set "BUILD_TYPE=release"

REM Detect Visual Studio version
if defined VisualStudioVersion (
    if "%VisualStudioVersion%"=="17.0" (
        set "VS_GENERATOR=Visual Studio 17 2022"
        set "VS_VERSION=2022"
    ) else if "%VisualStudioVersion%"=="16.0" (
        set "VS_GENERATOR=Visual Studio 16 2019"
        set "VS_VERSION=2019"
    ) else (
        set "VS_GENERATOR=Visual Studio 17 2022"
        set "VS_VERSION=2022"
    )
) else (
    set "VS_GENERATOR=Visual Studio 17 2022"
    set "VS_VERSION=2022"
)

REM Detect CPU cores for parallel builds
if not defined NUMBER_OF_PROCESSORS set NUMBER_OF_PROCESSORS=4
set /a JOBS=%NUMBER_OF_PROCESSORS%
if %JOBS% GTR 16 set JOBS=16

echo VFX Root Directory:     %VFX_ROOT%
echo USD Source:             %USD_SOURCE%
echo USD Install Location:   %USD_INSTALL%
echo Build Type:             %BUILD_TYPE%
echo Visual Studio:          %VS_VERSION%
echo CMake Generator:        %VS_GENERATOR%
echo Parallel Jobs:          %JOBS%
echo.
echo This will build USD and dependencies to: %USD_INSTALL%
echo Estimated time: 1-4 hours
echo Estimated disk space: ~30 GB during build, ~10 GB after
echo.
echo Continue? (Y/N^)
choice /c YN /n
if errorlevel 2 exit /b 0

echo.
echo ============================================================================
echo Step 1: Creating directories and cloning USD
echo ============================================================================

if not exist "%VFX_ROOT%" (
    echo Creating %VFX_ROOT%...
    mkdir "%VFX_ROOT%"
)

cd /d "%VFX_ROOT%"

if exist "%USD_SOURCE%" (
    echo USD source already exists at %USD_SOURCE%
    echo Do you want to update it? (Y/N^)
    choice /c YN /n
    if errorlevel 1 (
        cd "%USD_SOURCE%"
        git pull
    )
) else (
    echo Cloning USD repository...
    git clone https://github.com/PixarAnimationStudios/OpenUSD.git
    if errorlevel 1 (
        echo ERROR: Failed to clone USD repository
        pause
        exit /b 1
    )
)

echo.
echo ============================================================================
echo Step 2: Running build_usd.py
echo ============================================================================
echo.
echo Building USD with the following options:
echo   --python           : Python bindings (required for OpenDCC^)
echo   --imaging          : Imaging components (required for OpenDCC^)
echo   --openimageio      : OpenImageIO (required for OpenDCC^)
echo   --opencolorio      : OpenColorIO (required for OpenDCC^)
echo   --alembic          : Alembic support (required for OpenDCC^)
echo   --embree           : Embree ray tracing (required for OpenDCC^)
echo   --materialx        : MaterialX shading (enabled by default^)
echo   --onetbb           : Use OneTBB instead of TBB (VFX Platform 2023+^)
echo.
echo This will automatically build:
echo   - USD
echo   - Boost (with Python support^)
echo   - TBB / OneTBB
echo   - OpenEXR + Imath
echo   - OpenSubdiv
echo   - OpenImageIO
echo   - OpenColorIO
echo   - GLEW
echo   - Embree
echo   - Alembic
echo   - MaterialX
echo   - Image format libraries (JPEG, PNG, TIFF, etc.^)
echo.
echo Starting build in 5 seconds... (Press Ctrl+C to cancel^)
timeout /t 5

cd /d "%USD_SOURCE%"

python build_scripts\build_usd.py ^
  --build-variant %BUILD_TYPE% ^
  --generator "%VS_GENERATOR%" ^
  -j %JOBS% ^
  --python ^
  --imaging ^
  --openimageio ^
  --opencolorio ^
  --alembic ^
  --embree ^
  --materialx ^
  --onetbb ^
  --tests ^
  "%USD_INSTALL%"

if errorlevel 1 (
    echo.
    echo ============================================================================
    echo BUILD FAILED
    echo ============================================================================
    echo.
    echo The USD build failed. Check the error messages above.
    echo.
    echo Common solutions:
    echo   1. Ensure you are running from VS Native Tools Command Prompt
    echo   2. Check you have enough disk space (~30 GB^)
    echo   3. Try building without optional components first
    echo   4. Check Python version is 3.9, 3.10, or 3.11
    echo.
    echo For a minimal build, edit this script and remove:
    echo   --openimageio --opencolorio --alembic --embree
    echo.
    pause
    exit /b 1
)

echo.
echo ============================================================================
echo Step 3: Verifying build
echo ============================================================================

if not exist "%USD_INSTALL%\bin\usdcat.exe" (
    echo ERROR: Build completed but usdcat.exe not found
    echo Build may have failed silently
    pause
    exit /b 1
)

echo Testing USD installation...
"%USD_INSTALL%\bin\usdcat.exe" --version
if errorlevel 1 (
    echo ERROR: usdcat.exe failed to run
    pause
    exit /b 1
)

echo.
echo Testing Python USD import...
set "USD_PYTHON_PATH=%USD_INSTALL%\lib\python"
set "PYTHONPATH=%USD_PYTHON_PATH%;%PYTHONPATH%"
set "PATH=%USD_INSTALL%\bin;%USD_INSTALL%\lib;%PATH%"

python -c "from pxr import Usd; print('USD version:', Usd.GetVersion())"
if errorlevel 1 (
    echo ERROR: Failed to import USD in Python
    pause
    exit /b 1
)

echo.
echo ============================================================================
echo SUCCESS! USD built successfully
echo ============================================================================
echo.
echo Installation location: %USD_INSTALL%
echo.
echo Next steps:
echo   1. Set environment variables (see usd_env.bat^)
echo   2. Install Qt5 and PySide2 (Phase 2^)
echo   3. Build remaining dependencies (Phase 3^)
echo   4. Build OpenDCC (Phase 4^)
echo.
echo Creating environment setup script...

REM Create environment setup script
set "ENV_SCRIPT=%USD_INSTALL%\usd_env.bat"
(
echo @echo off
echo REM USD Environment Setup
echo REM Source: Generated by build_usd_for_opendcc.bat
echo.
echo set "USD_ROOT=%USD_INSTALL%"
echo set "PATH=%USD_INSTALL%\bin;%USD_INSTALL%\lib;%%PATH%%"
echo set "PYTHONPATH=%USD_INSTALL%\lib\python;%%PYTHONPATH%%"
echo.
echo echo USD environment set up:
echo echo   USD_ROOT=%%USD_ROOT%%
echo echo.
echo echo Test with: python -c "from pxr import Usd; print(Usd.GetVersion(^)^)"
) > "%ENV_SCRIPT%"

echo Created: %ENV_SCRIPT%
echo.
echo To use USD in future sessions, run:
echo   %ENV_SCRIPT%
echo.
echo ============================================================================

pause
