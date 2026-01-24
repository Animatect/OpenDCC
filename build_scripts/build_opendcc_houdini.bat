@echo off
REM ============================================================================
REM Build OpenDCC using Houdini's USD and VFX Libraries
REM ============================================================================
REM This script builds OpenDCC against Houdini's bundled USD and dependencies.
REM This is MUCH faster than building USD from scratch.
REM
REM Prerequisites:
REM   - Houdini 19.5+ installed (Apprentice/Indie/FX)
REM     * Houdini 21.0.512: Only Python 3.11 available, Shiboken must be OFF
REM     * Houdini 20.x: Python 3.10, full Shiboken support available
REM     * Houdini 19.x: Python 3.9, full Shiboken support available
REM   - Visual Studio 2019 or 2022 installed
REM   - Qt5 5.15.x (auto-installed if not found)
REM   - Run from "x64 Native Tools Command Prompt for VS"
REM   - NO ADMIN RIGHTS REQUIRED
REM
REM What Houdini provides:
REM   - USD (Solaris)
REM   - Boost (hboost)
REM   - TBB
REM   - Python 3.11 (H21.0.512 only has 3.11, python37/39 dirs are empty)
REM   - OpenEXR/Imath
REM   - OpenColorIO
REM   - OpenImageIO
REM
REM What you still need:
REM   - Qt5 5.15.x (auto-installed if missing)
REM   - ZMQ, Eigen3, doctest, sentry, qtadvanceddocking (via vcpkg)
REM   - PySide2 (optional, only if Shiboken enabled with Python 3.9/3.10)
REM ============================================================================

setlocal enabledelayedexpansion

echo ============================================================================
echo Building OpenDCC with Houdini USD
echo ============================================================================
echo.

REM ============================================================================
REM CONFIGURATION - EDIT THESE PATHS
REM ============================================================================

REM Houdini version priority
REM Set to "20" to prefer Houdini 20.x (Python 3.9/3.10, full PySide2 support)
REM Set to "21" to prefer Houdini 21.x (Python 3.11, Shiboken must be OFF)
set "PREFER_HOUDINI_VERSION=20"

REM Shiboken bindings (Qt Python bindings)
REM Set to "ON" to build Shiboken bindings (requires Python 3.9/3.10 with PySide2)
REM Using Houdini 20.x's Shiboken2 - should work with MSVC 2022
set "BUILD_SHIBOKEN=ON"

REM Auto-detect Houdini installation
set "HOUDINI_ROOT="
if "%PREFER_HOUDINI_VERSION%"=="20" (
    REM Prioritize Houdini 20.x (better PySide2 support)
    for /d %%i in ("C:\Program Files\Side Effects Software\Houdini 20*") do if not defined HOUDINI_ROOT set "HOUDINI_ROOT=%%i"
    for /d %%i in ("C:\Program Files\Side Effects Software\Houdini 21*") do if not defined HOUDINI_ROOT set "HOUDINI_ROOT=%%i"
    for /d %%i in ("C:\Program Files\Side Effects Software\Houdini 19*") do if not defined HOUDINI_ROOT set "HOUDINI_ROOT=%%i"
) else (
    REM Prioritize Houdini 21.x (latest features)
    if exist "C:\Program Files\Side Effects Software\Houdini 21.0.512" (
        set "HOUDINI_ROOT=C:\Program Files\Side Effects Software\Houdini 21.0.512"
    ) else (
        for /d %%i in ("C:\Program Files\Side Effects Software\Houdini 21*") do if not defined HOUDINI_ROOT set "HOUDINI_ROOT=%%i"
        for /d %%i in ("C:\Program Files\Side Effects Software\Houdini 20*") do if not defined HOUDINI_ROOT set "HOUDINI_ROOT=%%i"
        for /d %%i in ("C:\Program Files\Side Effects Software\Houdini 19*") do if not defined HOUDINI_ROOT set "HOUDINI_ROOT=%%i"
    )
)

REM Qt5 installation path (will auto-detect or auto-install)
set "QT5_DIR="
set "QT5_TARGET_DIR=C:\Qt\5.15.2\msvc2019_64"

REM vcpkg installation (for remaining dependencies)
set "VCPKG_ROOT=C:\VFX\vcpkg"

REM OpenDCC source and build directories
set "OPENDCC_SOURCE=%~dp0.."
set "OPENDCC_BUILD=%OPENDCC_SOURCE%\build_houdini"
set "OPENDCC_INSTALL=C:\VFX\OpenDCC_houdini"

REM ============================================================================
REM CHECKS
REM ============================================================================

REM Check Visual Studio environment
if not defined VSINSTALLDIR (
    echo ERROR: This script must be run from Visual Studio command prompt
    echo Please open "x64 Native Tools Command Prompt for VS 2022" or VS 2019
    echo and run this script again.
    pause
    exit /b 1
)

REM Check Houdini
if not defined HOUDINI_ROOT (
    echo ERROR: Houdini not found!
    echo.
    echo Please install Houdini from https://www.sidefx.com/download/
    echo Or set HOUDINI_ROOT manually in this script.
    echo.
    echo Looking in: C:\Program Files\Side Effects Software\Houdini *
    pause
    exit /b 1
)

if not exist "%HOUDINI_ROOT%\toolkit\include\pxr\pxr.h" (
    echo ERROR: USD not found in Houdini installation!
    echo.
    echo Expected: %HOUDINI_ROOT%\toolkit\include\pxr\pxr.h
    echo.
    echo Make sure you have a full Houdini installation with USD/Solaris.
    pause
    exit /b 1
)

echo Found Houdini: %HOUDINI_ROOT%

REM Extract Houdini version
for %%i in ("%HOUDINI_ROOT%") do set "HOUDINI_FOLDER=%%~nxi"
echo Houdini Version: %HOUDINI_FOLDER%

REM ============================================================================
REM AUTO-DETECT OR AUTO-INSTALL QT5
REM ============================================================================

echo.
echo Checking Qt5 installation...

REM Try to auto-detect Qt5 in common locations
for /d %%i in ("C:\Qt\5.15*\msvc2019_64") do if not defined QT5_DIR set "QT5_DIR=%%i"
for /d %%i in ("C:\Qt\5.15*\msvc2017_64") do if not defined QT5_DIR set "QT5_DIR=%%i"
for /d %%i in ("C:\Qt\5.15*\msvc2022_64") do if not defined QT5_DIR set "QT5_DIR=%%i"

REM Check if we found a valid Qt5 installation
if defined QT5_DIR (
    if exist "%QT5_DIR%\bin\Qt5Core.dll" (
        echo Found Qt5: %QT5_DIR%
        goto :qt5_found
    )
)

echo.
echo Qt5 5.15.x not found in standard locations.
echo.
set /p INSTALL_QT5="Auto-install Qt5 5.15.2 using aqt? (Y/N): "

if /i "!INSTALL_QT5!"=="Y" (
    echo.
    echo Installing Qt5 5.15.2 via aqt...
    echo This may take 10-15 minutes.
    echo.

    REM Install aqt if not already installed
    pip show aqtinstall >nul 2>&1
    if errorlevel 1 (
        echo Installing aqt ^(Another Qt Installer^)...
        pip install aqtinstall
        if errorlevel 1 (
            echo ERROR: Failed to install aqt
            echo Please install manually: pip install aqtinstall
            pause
            exit /b 1
        )
    )

    REM Create Qt directory if it doesn't exist
    if not exist "C:\Qt" mkdir "C:\Qt"

    REM Install Qt5 5.15.2 for MSVC 2019 64-bit
    echo Downloading and installing Qt 5.15.2...
    aqt install-qt windows desktop 5.15.2 win64_msvc2019_64 -O "C:\Qt"

    if errorlevel 1 (
        echo ERROR: Qt5 installation failed
        echo.
        echo You can try installing manually:
        echo   1. Install aqt: pip install aqtinstall
        echo   2. Run: aqt install-qt windows desktop 5.15.2 win64_msvc2019_64 -O "C:\Qt"
        echo   3. Or download from: https://www.qt.io/download-qt-installer
        pause
        exit /b 1
    )

    set "QT5_DIR=C:\Qt\5.15.2\msvc2019_64"
    echo Qt5 installed successfully: !QT5_DIR!
) else (
    echo.
    echo Please install Qt5 manually:
    echo   Option 1 ^(Recommended^): Use aqt
    echo     pip install aqtinstall
    echo     aqt install-qt windows desktop 5.15.2 win64_msvc2019_64 -O "C:\Qt"
    echo.
    echo   Option 2: Download from https://www.qt.io/download-qt-installer
    echo.
    echo Then re-run this script.
    pause
    exit /b 1
)

:qt5_found
REM Verify Qt5Core.dll exists
if not exist "%QT5_DIR%\bin\Qt5Core.dll" (
    echo ERROR: Qt5Core.dll not found at %QT5_DIR%\bin
    echo The Qt installation appears to be incomplete.
    pause
    exit /b 1
)

echo Using Qt5: %QT5_DIR%

REM ============================================================================
REM USE HOUDINI'S BUNDLED PYTHON AND PYSIDE2
REM ============================================================================
REM Houdini includes Python with PySide2 and shiboken2_generator pre-installed
REM This avoids compatibility issues with system Python versions

REM ============================================================================
REM SELECT PYTHON VERSION BASED ON SHIBOKEN REQUIREMENT
REM ============================================================================
REM Note: Houdini 21.0.512 has python37/python39 directories but they are EMPTY
REM Only Python 3.11 is actually installed and functional
REM Python 3.11 has no PySide2 support, so Shiboken must be disabled

set "HOUDINI_PYTHON_DIR="

if "%BUILD_SHIBOKEN%"=="ON" (
    REM Shiboken enabled - try to find Python with PySide2 support
    echo Shiboken ENABLED - searching for Python version with PySide2 support...
    if exist "%HOUDINI_ROOT%\python39\python.exe" (
        set "HOUDINI_PYTHON_DIR=%HOUDINI_ROOT%\python39"
        set "HOUDINI_PYTHON_VER=3.9"
        echo Selected Python 3.9 ^(has PySide2 support^)
    ) else (
        if exist "%HOUDINI_ROOT%\python310\python.exe" (
            set "HOUDINI_PYTHON_DIR=%HOUDINI_ROOT%\python310"
            set "HOUDINI_PYTHON_VER=3.10"
            echo Selected Python 3.10 ^(has PySide2 support^)
        ) else (
            if exist "%HOUDINI_ROOT%\python37\python.exe" (
                set "HOUDINI_PYTHON_DIR=%HOUDINI_ROOT%\python37"
                set "HOUDINI_PYTHON_VER=3.7"
                echo Selected Python 3.7 ^(has PySide2 support^)
            ) else (
                if exist "%HOUDINI_ROOT%\python311\python.exe" (
                    set "HOUDINI_PYTHON_DIR=%HOUDINI_ROOT%\python311"
                    set "HOUDINI_PYTHON_VER=3.11"
                    echo.
                    echo WARNING: Only Python 3.11 found - no PySide2 support available
                    echo Houdini 21.0.512 has python37/python39 directories but they are empty.
                    echo.
                    echo Please set BUILD_SHIBOKEN=OFF in this script to continue.
                    echo.
                    pause
                    exit /b 1
                )
            )
        )
    )
) else (
    REM Shiboken disabled - use latest Python version
    if exist "%HOUDINI_ROOT%\python311\python.exe" (
        set "HOUDINI_PYTHON_DIR=%HOUDINI_ROOT%\python311"
        set "HOUDINI_PYTHON_VER=3.11"
        echo Using Python 3.11 ^(Shiboken disabled^)
    ) else (
        if exist "%HOUDINI_ROOT%\python39\python.exe" (
            set "HOUDINI_PYTHON_DIR=%HOUDINI_ROOT%\python39"
            set "HOUDINI_PYTHON_VER=3.9"
            echo Using Python 3.9
        ) else (
            if exist "%HOUDINI_ROOT%\python310\python.exe" (
                set "HOUDINI_PYTHON_DIR=%HOUDINI_ROOT%\python310"
                set "HOUDINI_PYTHON_VER=3.10"
                echo Using Python 3.10
            ) else (
                if exist "%HOUDINI_ROOT%\python37\python.exe" (
                    set "HOUDINI_PYTHON_DIR=%HOUDINI_ROOT%\python37"
                    set "HOUDINI_PYTHON_VER=3.7"
                    echo Using Python 3.7
                )
            )
        )
    )
)

if not defined HOUDINI_PYTHON_DIR (
    echo ERROR: Could not find Python in Houdini installation
    echo Looked in: %HOUDINI_ROOT%\python311, python39, python37
    pause
    exit /b 1
)

set "PYTHON_EXECUTABLE=%HOUDINI_PYTHON_DIR%\python.exe"
echo Found Houdini Python %HOUDINI_PYTHON_VER%: %PYTHON_EXECUTABLE%

REM Houdini stores PySide in site-packages-forced
set "HOUDINI_SITE_PACKAGES=%HOUDINI_PYTHON_DIR%\lib\site-packages-forced"

REM ============================================================================
REM PYSIDE VERSION DETECTION AND INSTALLATION
REM ============================================================================
REM Houdini 19.x/20.x use PySide2 (Qt5)
REM Houdini 21.x uses PySide6 (Qt6)
REM OpenDCC requires Qt5 and PySide2, so we need to install PySide2 separately for Houdini 21.x

if "%BUILD_SHIBOKEN%"=="OFF" (
    echo.
    echo ============================================================================
    echo Shiboken Bindings: DISABLED
    echo ============================================================================
    echo Using Python 3.11 without Shiboken bindings.
    echo.
    echo What this means:
    echo   - OpenDCC UI will work perfectly with Qt5
    echo   - All core functionality is available
    echo   - Python scripts can use OpenDCC API
    echo   - Python cannot directly access Qt widget internals
    echo.
    echo Note: To enable Shiboken, set BUILD_SHIBOKEN=ON and the script
    echo       will automatically use Python 3.9 which has PySide2 support.
    echo.
    echo Skipping PySide2 installation...
    echo ============================================================================
    echo.
    goto :skip_pyside_setup
)

echo.
echo Checking PySide installation...

REM Check if Houdini has PySide2 (Houdini 19.x/20.x)
if exist "%HOUDINI_SITE_PACKAGES%\PySide2" (
    echo Houdini includes PySide2 ^(Qt5^) - using bundled version
    set "PYSIDE2_DIR=%HOUDINI_SITE_PACKAGES%\PySide2"
    set "USE_HOUDINI_PYSIDE=1"

    REM Verify shiboken2_generator exists
    if exist "%HOUDINI_SITE_PACKAGES%\shiboken2_generator\shiboken2.exe" (
        set "SHIBOKEN_GENERATOR_DIR=%HOUDINI_SITE_PACKAGES%\shiboken2_generator"
        echo Found shiboken2_generator: !SHIBOKEN_GENERATOR_DIR!
    ) else (
        echo WARNING: shiboken2_generator not found in Houdini, will install separately
        set "USE_HOUDINI_PYSIDE=0"
    )
) else (
    echo Houdini uses PySide6 ^(Qt6^) - need to install PySide2 separately for Qt5 compatibility
    set "USE_HOUDINI_PYSIDE=0"
)

echo DEBUG: After PySide2 detection, USE_HOUDINI_PYSIDE=%USE_HOUDINI_PYSIDE%

REM If Houdini doesn't have PySide2, install it via pip
if "%USE_HOUDINI_PYSIDE%"=="0" (
    echo.
    echo Houdini 21.x detected - installing PySide2 and shiboken2_generator for Qt5 support...
    echo This will use Houdini's USD/Python but with separate PySide2 installation.
    echo.

    REM Check if PySide2 is already installed
    set "PYSIDE2_INSTALLED=0"
    "%PYTHON_EXECUTABLE%" -m pip show PySide2 >nul 2>&1
    if not errorlevel 1 set "PYSIDE2_INSTALLED=1"

    if "!PYSIDE2_INSTALLED!"=="0" (
        echo Installing PySide2...

        REM Try version-specific install first (works for Python 3.9/3.10)
        if "%HOUDINI_PYTHON_VER%"=="3.11" (
            echo WARNING: Python 3.11 detected. PySide2 has no official 3.11 builds.
            echo Trying alternative installation methods...
            echo.

            REM Method 1: Try any available PySide2 version
            echo [1/3] Trying latest available PySide2...
            "%PYTHON_EXECUTABLE%" -m pip install PySide2 --prefer-binary >nul 2>&1
            if not errorlevel 1 set "PYSIDE2_INSTALLED=1"

            if "!PYSIDE2_INSTALLED!"=="0" (
                REM Method 2: Try unofficial wheel repository
                echo [2/3] Trying unofficial PySide2 wheels...
                "%PYTHON_EXECUTABLE%" -m pip install PySide2==5.15.2.1 --extra-index-url https://download.qt.io/official_releases/QtForPython/ --trusted-host download.qt.io >nul 2>&1
                if not errorlevel 1 set "PYSIDE2_INSTALLED=1"
            )

            if "!PYSIDE2_INSTALLED!"=="0" (
                REM Method 3: All attempts failed
                echo [3/3] All PySide2 installation methods failed.
                echo.
                echo ============================================================================
                echo PySide2 Installation Failed - Python 3.11 Not Supported
                echo ============================================================================
                echo.
                echo PySide2 does not have official builds for Python 3.11 ^(Houdini 21.x^).
                echo.
                echo REQUIRED SOLUTION for Houdini 21.x:
                echo.
                echo   Disable Shiboken bindings ^(RECOMMENDED^)
                echo     - Edit line 54 in this script: set "BUILD_SHIBOKEN=OFF"
                echo     - OpenDCC will build successfully with full functionality
                echo     - Qt UI works perfectly, just no Python bindings for Qt widgets
                echo     - This is the standard approach for Python 3.11
                echo.
                echo ALTERNATIVE SOLUTIONS ^(Advanced^):
                echo.
                echo   Option 1: Build PySide2 from source for Python 3.11
                echo     - Follow: https://wiki.qt.io/Qt_for_Python/GettingStarted
                echo     - Requires Qt 5.15.2 source, C++ compiler, 2-4 hours
                echo     - Not officially supported by Qt
                echo.
                echo   Option 2: Use Houdini 20.x with Python 3.10
                echo     - Only if you have access to Houdini 20.x
                echo     - Has native PySide2 support
                echo.
                echo ============================================================================
                echo.
                pause
                exit /b 1
            )
        ) else (
            REM Python 3.9 or 3.10 - standard install should work
            echo Installing PySide2 5.15.2.1...
            "%PYTHON_EXECUTABLE%" -m pip install PySide2==5.15.2.1
            if errorlevel 1 (
                echo ERROR: Failed to install PySide2
                pause
                exit /b 1
            ) else (
                echo PySide2 installed successfully
            )
        )
    ) else (
        echo PySide2 already installed
    )

    REM Check if shiboken2_generator is already installed
    set "SHIBOKEN_INSTALLED=0"
    "%PYTHON_EXECUTABLE%" -m pip show shiboken2_generator >nul 2>&1
    if not errorlevel 1 set "SHIBOKEN_INSTALLED=1"

    if "!SHIBOKEN_INSTALLED!"=="0" (
        echo Installing shiboken2_generator...
        "%PYTHON_EXECUTABLE%" -m pip install shiboken2_generator==5.15.2.1 >nul 2>&1
        if errorlevel 1 (
            echo WARNING: Standard pip install failed, trying wheel...
            "%PYTHON_EXECUTABLE%" -m pip install https://download.qt.io/official_releases/QtForPython/shiboken2-generator/shiboken2_generator-5.15.2-5.15.2-cp35.cp36.cp37.cp38.cp39.cp310.cp311-none-win_amd64.whl --ignore-requires-python >nul 2>&1
            if errorlevel 1 (
                echo ERROR: Failed to install shiboken2_generator
                pause
                exit /b 1
            ) else (
                echo shiboken2_generator installed successfully from wheel
            )
        ) else (
            echo shiboken2_generator installed successfully
        )
    ) else (
        echo shiboken2_generator already installed
    )

    REM Locate installed PySide2
    for /f "tokens=*" %%i in ('"%PYTHON_EXECUTABLE%" -c "import PySide2, os; print(os.path.dirname(PySide2.__file__))" 2^>nul') do set "PYSIDE2_DIR=%%i"
    if not defined PYSIDE2_DIR (
        echo ERROR: PySide2 installation failed or not found
        pause
        exit /b 1
    )
    echo Found PySide2: !PYSIDE2_DIR!

    REM Locate shiboken2_generator
    for /f "tokens=*" %%i in ('"%PYTHON_EXECUTABLE%" -c "import shiboken2_generator, os; print(os.path.dirname(shiboken2_generator.__file__))" 2^>nul') do set "SHIBOKEN_GENERATOR_DIR=%%i"
    if not defined SHIBOKEN_GENERATOR_DIR (
        echo ERROR: shiboken2_generator not found after installation
        pause
        exit /b 1
    )
    echo Found shiboken2_generator: !SHIBOKEN_GENERATOR_DIR!

    REM ========================================================================
    REM Set environment variables for CMake to use separate PySide2
    REM ========================================================================
    REM CMake's PySideConfig.cmake now supports DCC_PYSIDE2_PATH override
    REM This is much cleaner than creating junctions and doesn't require admin rights

    echo.
    echo Configuring CMake to use separate PySide2 installation...

    REM Get the parent directory of PySide2 for PYTHONPATH
    for %%i in ("!PYSIDE2_DIR!") do set "PYSIDE2_PARENT=%%~dpi"
    set "PYSIDE2_PARENT=%PYSIDE2_PARENT:~0,-1%"

    REM Set environment variables that CMake will read
    set "DCC_PYSIDE2_PATH=%PYSIDE2_PARENT%"
    set "DCC_SHIBOKEN_GENERATOR_PATH=%SHIBOKEN_GENERATOR_DIR%"

    echo Set DCC_PYSIDE2_PATH=%DCC_PYSIDE2_PATH%
    echo Set DCC_SHIBOKEN_GENERATOR_PATH=%DCC_SHIBOKEN_GENERATOR_PATH%
)

echo DEBUG: After installation block, BUILD_SHIBOKEN=%BUILD_SHIBOKEN%

if "%BUILD_SHIBOKEN%"=="ON" (
    echo Using PySide2: %PYSIDE2_DIR%
    echo Using Shiboken: %SHIBOKEN_GENERATOR_DIR%
)

REM ============================================================================
REM PYSIDE/SHIBOKEN SETUP COMPLETE
REM ============================================================================
REM At this point we have:
REM   PYTHON_EXECUTABLE - path to python.exe
REM   PYSIDE2_DIR - path to PySide2 package (if BUILD_SHIBOKEN=ON)
REM   SHIBOKEN_GENERATOR_DIR - path to shiboken2_generator with shiboken2.exe (if BUILD_SHIBOKEN=ON)
REM   USE_HOUDINI_PYSIDE - 1 if using Houdini's PySide2, 0 if installed separately

:skip_pyside_setup

REM Check/Setup vcpkg
if not exist "%VCPKG_ROOT%\vcpkg.exe" (
    echo.
    echo vcpkg not found at %VCPKG_ROOT%
    echo.
    set /p INSTALL_VCPKG="Install vcpkg now? (Y/N): "
    if /i "!INSTALL_VCPKG!"=="Y" (
        echo Installing vcpkg...
        mkdir C:\VFX 2>nul
        cd /d C:\VFX
        git clone https://github.com/microsoft/vcpkg.git
        cd vcpkg
        call bootstrap-vcpkg.bat
        set "VCPKG_ROOT=C:\VFX\vcpkg"
    ) else (
        echo.
        echo Please install vcpkg manually:
        echo   cd C:\VFX
        echo   git clone https://github.com/microsoft/vcpkg.git
        echo   cd vcpkg
        echo   bootstrap-vcpkg.bat
        pause
        exit /b 1
    )
)
echo Found vcpkg: %VCPKG_ROOT%

REM ============================================================================
REM INSTALL VCPKG DEPENDENCIES
REM ============================================================================

echo.
echo ============================================================================
echo Step 1: Installing dependencies via vcpkg
echo ============================================================================
echo.

cd /d "%VCPKG_ROOT%"

REM Check if packages are already installed
set "NEED_INSTALL=0"
if not exist "%VCPKG_ROOT%\installed\x64-windows\lib\libzmq-mt-4_3_5.lib" set "NEED_INSTALL=1"
if not exist "%VCPKG_ROOT%\installed\x64-windows\include\Eigen" set "NEED_INSTALL=1"
if not exist "%VCPKG_ROOT%\installed\x64-windows\include\doctest" set "NEED_INSTALL=1"
if not exist "%VCPKG_ROOT%\installed\x64-windows\include\GL\glew.h" set "NEED_INSTALL=1"
if not exist "%VCPKG_ROOT%\installed\x64-windows\include\igl" set "NEED_INSTALL=1"
if not exist "%VCPKG_ROOT%\installed\x64-windows\share\pybind11" set "NEED_INSTALL=1"
if not exist "%VCPKG_ROOT%\installed\x64-windows\include\graphviz" set "NEED_INSTALL=1"
if not exist "%VCPKG_ROOT%\installed\x64-windows\include\OpenMesh" set "NEED_INSTALL=1"
if not exist "%VCPKG_ROOT%\installed\x64-windows\include\sentry.h" set "NEED_INSTALL=1"
REM Note: qtadvanceddocking is built from source via FetchContent (vcpkg version is Qt6 only)

if "%NEED_INSTALL%"=="1" (
    echo Installing required packages...
    vcpkg install zeromq:x64-windows eigen3:x64-windows doctest:x64-windows glew:x64-windows libigl:x64-windows pybind11:x64-windows graphviz:x64-windows openmesh:x64-windows sentry-native:x64-windows
    if errorlevel 1 (
        echo ERROR: vcpkg install failed
        pause
        exit /b 1
    )
) else (
    echo Dependencies already installed, skipping...
)

REM ============================================================================
REM CONFIGURE OPENDCC
REM ============================================================================

echo.
echo ============================================================================
echo Step 2: Configuring OpenDCC
echo ============================================================================
echo.

cd /d "%OPENDCC_SOURCE%"

if exist "%OPENDCC_BUILD%" (
    echo Build directory exists: %OPENDCC_BUILD%
    set /p CLEAN_BUILD="Clean and reconfigure? (Y/N): "
    if /i "!CLEAN_BUILD!"=="Y" (
        rmdir /s /q "%OPENDCC_BUILD%"
    )
)

mkdir "%OPENDCC_BUILD%" 2>nul
cd "%OPENDCC_BUILD%"

REM Detect Visual Studio generator
set "VS_GENERATOR=Visual Studio 17 2022"
if "%VisualStudioVersion%"=="16.0" set "VS_GENERATOR=Visual Studio 16 2019"

echo.
echo Configuration:
echo   Houdini:        %HOUDINI_ROOT%
echo   Houdini Python: %PYTHON_EXECUTABLE%
echo   Qt5:            %QT5_DIR%
if "%BUILD_SHIBOKEN%"=="ON" (
    echo   PySide2:        %PYSIDE2_DIR%
    if "%USE_HOUDINI_PYSIDE%"=="1" (
        echo   PySide Source:  Houdini bundled
    ) else (
        echo   PySide Source:  Separately installed ^(Houdini 21.x has Qt6/PySide6^)
    )
    echo   Shiboken:       %SHIBOKEN_GENERATOR_DIR%
) else (
    echo   Shiboken:       DISABLED ^(no Python Qt bindings^)
)
echo   vcpkg:          %VCPKG_ROOT%
echo   Generator:      %VS_GENERATOR%
echo   Build Dir:      %OPENDCC_BUILD%
echo   Install Dir:    %OPENDCC_INSTALL%
echo.

REM Set environment variables for pyside2_config.py and USD schema parsing
REM PYTHONPATH must include:
REM   1. Houdini's site-packages (for pxr/USD Python modules)
REM   2. Houdini's site-packages-forced (for PySide2/shiboken2 if using Houdini's)
REM   3. Houdini's python libs (for hou module and dependencies)
set "SHIBOKEN_GENERATOR_DIR=%SHIBOKEN_GENERATOR_DIR%"
set "HOUDINI_PYTHON_SITE=%HOUDINI_PYTHON_DIR%\lib\site-packages"
set "HOUDINI_PYTHON_LIBS=%HOUDINI_ROOT%\houdini\python%HOUDINI_PYTHON_VER:.=%libs"

REM Build PYTHONPATH with Houdini paths FIRST to override any external USD
if "%BUILD_SHIBOKEN%"=="OFF" (
    REM Shiboken disabled, don't include PySide paths
    set "PYTHONPATH=%HOUDINI_PYTHON_SITE%;%HOUDINI_PYTHON_LIBS%;%PYTHONPATH%"
) else (
    if "%USE_HOUDINI_PYSIDE%"=="1" (
        REM Using Houdini's PySide2, include site-packages-forced
        set "PYTHONPATH=%HOUDINI_PYTHON_SITE%;%HOUDINI_SITE_PACKAGES%;%HOUDINI_PYTHON_LIBS%;%PYTHONPATH%"
    ) else (
        REM Using separate PySide2, include its path but not site-packages-forced (to avoid PySide6 conflicts)
        set "PYTHONPATH=%DCC_PYSIDE2_PATH%;%HOUDINI_PYTHON_SITE%;%HOUDINI_PYTHON_LIBS%;%PYTHONPATH%"
    )
)

REM Also set PATH to include Houdini bin for DLL loading
set "PATH=%HOUDINI_ROOT%\bin;%PATH%"

echo Using PYTHONPATH: %PYTHONPATH%
echo.

cmake -G "%VS_GENERATOR%" -A x64 ^
  -DDCC_HOUDINI_SUPPORT=ON ^
  -DHOUDINI_ROOT="%HOUDINI_ROOT%" ^
  -DPYTHON_EXECUTABLE="%PYTHON_EXECUTABLE%" ^
  -DDCC_EMBEDDED_PYTHON_HOME=OFF ^
  -DDCC_BUILD_SHIBOKEN_BINDINGS=%BUILD_SHIBOKEN% ^
  -DDCC_BUILD_ARNOLD_SUPPORT=OFF ^
  -DDCC_USD_FALLBACK_PROXY_BUILD_ARNOLD_USD=OFF ^
  -DDCC_BUILD_CYCLES_SUPPORT=OFF ^
  -DDCC_USD_FALLBACK_PROXY_BUILD_CYCLES=OFF ^
  -DDCC_BUILD_RENDERMAN_SUPPORT=OFF ^
  -DTBB_ROOT_DIR="%HOUDINI_ROOT%\toolkit" ^
  -DTBB_INCLUDE_DIR="%HOUDINI_ROOT%\toolkit\include" ^
  -DTBB_LIBRARY="%HOUDINI_ROOT%\custom\houdini\dsolib" ^
  -DGLEW_ROOT="%VCPKG_ROOT%\installed\x64-windows" ^
  -DZMQ_ROOT="%VCPKG_ROOT%\installed\x64-windows" ^
  -DIGL_ROOT="%VCPKG_ROOT%\installed\x64-windows\include" ^
  -DGRAPHVIZ_ROOT="%VCPKG_ROOT%\installed\x64-windows" ^
  -DOPENMESH_ROOT="%VCPKG_ROOT%\installed\x64-windows" ^
  -DCMAKE_PREFIX_PATH="%QT5_DIR%;%VCPKG_ROOT%\installed\x64-windows" ^
  -DCMAKE_TOOLCHAIN_FILE="%VCPKG_ROOT%\scripts\buildsystems\vcpkg.cmake" ^
  -DSHIBOKEN_CLANG_INSTALL_DIR="%SHIBOKEN_GENERATOR_DIR%" ^
  -DCMAKE_INSTALL_PREFIX="%OPENDCC_INSTALL%" ^
  -DCMAKE_BUILD_TYPE=Release ^
  -DDCC_BUILD_ARNOLD_SUPPORT=OFF ^
  -DDCC_USD_FALLBACK_PROXY_BUILD_ARNOLD_USD=OFF ^
  -DDCC_BUILD_CYCLES_SUPPORT=OFF ^
  -DDCC_USD_FALLBACK_PROXY_BUILD_CYCLES=OFF ^
  -DDCC_BUILD_RENDERMAN_SUPPORT=OFF ^
  -DDCC_BUILD_BULLET_PHYSICS=OFF ^
  -DDCC_BUILD_HYDRA_OP=OFF ^
  -DDCC_BUILD_TESTS=ON ^
  -DDCC_INSTALL_ADS=OFF ^
  -DDCC_INSTALL_SENTRY=OFF ^
  "%OPENDCC_SOURCE%"

if errorlevel 1 (
    echo.
    echo ============================================================================
    echo CMAKE CONFIGURATION FAILED
    echo ============================================================================
    echo.
    echo Check the error messages above.
    echo.
    echo Common issues:
    echo   - Missing Qt5 components: Install full Qt5 with LinguistTools
    echo   - Missing sentry: May need to build separately or disable
    echo   - Missing qtadvanceddocking: May need to build separately
    echo.
    echo To see detailed errors, check:
    echo   %OPENDCC_BUILD%\CMakeFiles\CMakeError.log
    echo.
    pause
    exit /b 1
)

echo.
echo CMake configuration successful!

REM ============================================================================
REM BUILD OPENDCC
REM ============================================================================

echo.
echo ============================================================================
echo Step 3: Building OpenDCC
echo ============================================================================
echo.

set /a JOBS=%NUMBER_OF_PROCESSORS%
if %JOBS% GTR 8 set JOBS=8

echo Building with %JOBS% parallel jobs...
echo This may take 30-60 minutes.
echo.

cmake --build . --config Release --parallel %JOBS%

if errorlevel 1 (
    echo.
    echo ============================================================================
    echo BUILD FAILED
    echo ============================================================================
    echo.
    echo Check the error messages above.
    pause
    exit /b 1
)

echo.
echo Build successful!

REM ============================================================================
REM INSTALL OPENDCC
REM ============================================================================

echo.
echo ============================================================================
echo Step 4: Installing OpenDCC
echo ============================================================================
echo.

cmake --install . --config Release

if errorlevel 1 (
    echo.
    echo ============================================================================
    echo INSTALL FAILED
    echo ============================================================================
    pause
    exit /b 1
)

echo.
echo Installation successful!

REM ============================================================================
REM CREATE LAUNCH SCRIPT
REM ============================================================================

echo.
echo ============================================================================
echo Step 5: Creating launch script
echo ============================================================================
echo.

set "LAUNCH_SCRIPT=%OPENDCC_INSTALL%\run_opendcc.bat"

(
echo @echo off
echo REM OpenDCC Launch Script ^(Houdini Build^)
echo REM Generated by build_opendcc_houdini.bat
echo.
echo REM Houdini environment
echo set "HOUDINI_ROOT=%HOUDINI_ROOT%"
echo set "PATH=%%HOUDINI_ROOT%%\bin;%%PATH%%"
echo.
echo REM Qt environment
echo set "PATH=%QT5_DIR%\bin;%%PATH%%"
echo.
echo REM OpenDCC environment
echo set "OPENDCC_ROOT=%%~dp0"
echo set "PATH=%%OPENDCC_ROOT%%\bin;%%PATH%%"
echo set "PYTHONPATH=%%OPENDCC_ROOT%%\lib\python;%%PYTHONPATH%%"
echo.
echo REM Launch OpenDCC
echo "%%OPENDCC_ROOT%%\bin\dcc_base.exe" %%*
) > "%LAUNCH_SCRIPT%"

echo Created: %LAUNCH_SCRIPT%

REM ============================================================================
REM DONE
REM ============================================================================

echo.
echo ============================================================================
echo SUCCESS! OpenDCC built with Houdini USD
echo ============================================================================
echo.
echo Installation: %OPENDCC_INSTALL%
echo.
echo To run OpenDCC:
echo   %LAUNCH_SCRIPT%
echo.
echo Or with Python shell:
echo   %LAUNCH_SCRIPT% --shell
echo.
echo Or run tests:
echo   %LAUNCH_SCRIPT% --with-tests
echo.
echo ============================================================================

pause
