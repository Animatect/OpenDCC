@echo off
REM ============================================================================
REM Build OpenDCC using Houdini's USD and VFX Libraries
REM ============================================================================
REM This script builds OpenDCC against Houdini's bundled USD and dependencies.
REM This is MUCH faster than building USD from scratch.
REM
REM Prerequisites:
REM   - Houdini 19.5+ installed (Apprentice/Indie/FX)
REM   - Visual Studio 2019 or 2022 installed
REM   - Qt5 5.15.x installed
REM   - PySide2 installed (pip install PySide2)
REM   - Run from "x64 Native Tools Command Prompt for VS"
REM
REM What Houdini provides:
REM   - USD (Solaris)
REM   - Boost (hboost)
REM   - TBB
REM   - Python 3.9/3.10
REM   - OpenEXR/Imath
REM   - OpenColorIO
REM   - OpenImageIO
REM
REM What you still need:
REM   - Qt5, PySide2/Shiboken2
REM   - ZMQ, Eigen3, doctest, sentry, qtadvanceddocking (via vcpkg)
REM ============================================================================

setlocal enabledelayedexpansion

echo ============================================================================
echo Building OpenDCC with Houdini USD
echo ============================================================================
echo.

REM ============================================================================
REM CONFIGURATION - EDIT THESE PATHS
REM ============================================================================

REM Auto-detect Houdini installation
set "HOUDINI_ROOT="
for /d %%i in ("C:\Program Files\Side Effects Software\Houdini 20*") do set "HOUDINI_ROOT=%%i"
for /d %%i in ("C:\Program Files\Side Effects Software\Houdini 19*") do if not defined HOUDINI_ROOT set "HOUDINI_ROOT=%%i"

REM Qt5 installation path (adjust to your installation)
set "QT5_DIR=C:\Qt\5.15.2\msvc2019_64"

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

REM Check Qt5
if not exist "%QT5_DIR%\bin\Qt5Core.dll" (
    echo.
    echo WARNING: Qt5 not found at %QT5_DIR%
    echo.
    echo Please install Qt5 from https://www.qt.io/download-qt-installer
    echo Then edit this script to set QT5_DIR to your Qt installation.
    echo.
    echo Example paths:
    echo   C:\Qt\5.15.2\msvc2019_64
    echo   C:\Qt\5.15.14\msvc2019_64
    echo.
    set /p QT5_DIR="Enter Qt5 path (or press Enter to exit): "
    if "!QT5_DIR!"=="" exit /b 1
    if not exist "!QT5_DIR!\bin\Qt5Core.dll" (
        echo ERROR: Qt5Core.dll not found in !QT5_DIR!\bin
        pause
        exit /b 1
    )
)
echo Found Qt5: %QT5_DIR%

REM ============================================================================
REM USE HOUDINI'S BUNDLED PYTHON AND PYSIDE2
REM ============================================================================
REM Houdini includes Python with PySide2 and shiboken2_generator pre-installed
REM This avoids compatibility issues with system Python versions

REM Detect Houdini's Python version (prefer 3.11, fallback to 3.9)
set "HOUDINI_PYTHON_DIR="
if exist "%HOUDINI_ROOT%\python311\python.exe" (
    set "HOUDINI_PYTHON_DIR=%HOUDINI_ROOT%\python311"
    set "HOUDINI_PYTHON_VER=3.11"
) else if exist "%HOUDINI_ROOT%\python39\python.exe" (
    set "HOUDINI_PYTHON_DIR=%HOUDINI_ROOT%\python39"
    set "HOUDINI_PYTHON_VER=3.9"
) else if exist "%HOUDINI_ROOT%\python37\python.exe" (
    set "HOUDINI_PYTHON_DIR=%HOUDINI_ROOT%\python37"
    set "HOUDINI_PYTHON_VER=3.7"
)

if not defined HOUDINI_PYTHON_DIR (
    echo ERROR: Could not find Python in Houdini installation
    echo Looked in: %HOUDINI_ROOT%\python311, python39, python37
    pause
    exit /b 1
)

set "PYTHON_EXECUTABLE=%HOUDINI_PYTHON_DIR%\python.exe"
echo Found Houdini Python %HOUDINI_PYTHON_VER%: %PYTHON_EXECUTABLE%

REM Houdini stores PySide2 and shiboken2 in site-packages-forced
set "HOUDINI_SITE_PACKAGES=%HOUDINI_PYTHON_DIR%\lib\site-packages-forced"

REM Verify PySide2 exists
if not exist "%HOUDINI_SITE_PACKAGES%\PySide2" (
    echo ERROR: PySide2 not found in Houdini installation
    echo Expected: %HOUDINI_SITE_PACKAGES%\PySide2
    pause
    exit /b 1
)
set "PYSIDE2_DIR=%HOUDINI_SITE_PACKAGES%\PySide2"
echo Found PySide2: %PYSIDE2_DIR%

REM Verify shiboken2_generator exists
if not exist "%HOUDINI_SITE_PACKAGES%\shiboken2_generator\shiboken2.exe" (
    echo ERROR: shiboken2_generator not found in Houdini installation
    echo Expected: %HOUDINI_SITE_PACKAGES%\shiboken2_generator\shiboken2.exe
    pause
    exit /b 1
)
set "SHIBOKEN_GENERATOR_DIR=%HOUDINI_SITE_PACKAGES%\shiboken2_generator"
echo Found shiboken2_generator: %SHIBOKEN_GENERATOR_DIR%

REM Add Houdini's site-packages to PYTHONPATH for CMake's pyside2_config.py
set "PYTHONPATH=%HOUDINI_SITE_PACKAGES%;%PYTHONPATH%"

REM Skip the old shiboken detection logic since we found it in Houdini
goto :shiboken_found

REM Legacy code path for non-Houdini Python (kept for reference but skipped)
if 1==0 (
            echo.
            echo Attempting to force install shiboken2_generator wheel...
            pip install https://download.qt.io/official_releases/QtForPython/shiboken2-generator/shiboken2_generator-5.15.2-5.15.2-cp35.cp36.cp37.cp38.cp39-none-win_amd64.whl --ignore-requires-python
            if errorlevel 1 (
                echo.
                echo ERROR: Failed to install shiboken2_generator even with --ignore-requires-python
                echo Please use Python 3.9 instead.
                pause
                exit /b 1
            )
            REM Retry finding the generator
            for /f "tokens=*" %%i in ('python -c "import shiboken2_generator, os; print(os.path.dirname(shiboken2_generator.__file__))" 2^>nul') do set "SHIBOKEN_GENERATOR_DIR=%%i"
        ) else (
            echo.
            echo Please install Python 3.9 and try again.
            pause
            exit /b 1
        )

        :shiboken_check_done
        if not defined SHIBOKEN_GENERATOR_DIR (
            echo ERROR: shiboken2_generator installation failed or not found
            pause
            exit /b 1
        )
    )
) else (
    REM Found as importable module
    for /f "tokens=*" %%i in ('python -c "import shiboken2_generator, os; print(os.path.dirname(shiboken2_generator.__file__))"') do set "SHIBOKEN_GENERATOR_DIR=%%i"
)

if not defined SHIBOKEN_GENERATOR_DIR (
    echo ERROR: Could not locate shiboken2 generator directory
    pause
    exit /b 1
)

REM Verify shiboken2.exe exists
if not exist "!SHIBOKEN_GENERATOR_DIR!\shiboken2.exe" (
    echo.
    echo WARNING: shiboken2.exe not found in !SHIBOKEN_GENERATOR_DIR!
    echo Using PySide2 directory as fallback...
    set "SHIBOKEN_GENERATOR_DIR=!PYSIDE2_DIR!"
)

echo Found Shiboken generator (legacy): %SHIBOKEN_GENERATOR_DIR%
)
REM End of legacy code path (if 1==0)

:shiboken_found
REM At this point we have:
REM   PYTHON_EXECUTABLE - path to python.exe
REM   PYSIDE2_DIR - path to PySide2 package
REM   SHIBOKEN_GENERATOR_DIR - path to shiboken2_generator with shiboken2.exe

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
echo   Houdini:     %HOUDINI_ROOT%
echo   Qt5:         %QT5_DIR%
echo   vcpkg:       %VCPKG_ROOT%
echo   Shiboken:    %SHIBOKEN_GENERATOR_DIR%
echo   PySide2:     %PYSIDE2_DIR%
echo   Python:      %PYTHON_EXECUTABLE%
echo   Generator:   %VS_GENERATOR%
echo   Build Dir:   %OPENDCC_BUILD%
echo   Install Dir: %OPENDCC_INSTALL%
echo.

REM Set environment variables for pyside2_config.py and USD schema parsing
REM PYTHONPATH must include:
REM   1. Houdini's site-packages (for pxr/USD Python modules)
REM   2. Houdini's site-packages-forced (for PySide2/shiboken2)
REM   3. Houdini's python libs (for hou module and dependencies)
set "SHIBOKEN_GENERATOR_DIR=%SHIBOKEN_GENERATOR_DIR%"
set "HOUDINI_PYTHON_SITE=%HOUDINI_PYTHON_DIR%\lib\site-packages"
set "HOUDINI_PYTHON_LIBS=%HOUDINI_ROOT%\houdini\python%HOUDINI_PYTHON_VER:.=%libs"

REM Build PYTHONPATH with Houdini paths FIRST to override any external USD
set "PYTHONPATH=%HOUDINI_PYTHON_SITE%;%HOUDINI_SITE_PACKAGES%;%HOUDINI_PYTHON_LIBS%;%PYTHONPATH%"

REM Also set PATH to include Houdini bin for DLL loading
set "PATH=%HOUDINI_ROOT%\bin;%PATH%"

echo Using PYTHONPATH: %PYTHONPATH%
echo.

cmake -G "%VS_GENERATOR%" -A x64 ^
  -DDCC_HOUDINI_SUPPORT=ON ^
  -DHOUDINI_ROOT="%HOUDINI_ROOT%" ^
  -DPYTHON_EXECUTABLE="%PYTHON_EXECUTABLE%" ^
  -DDCC_EMBEDDED_PYTHON_HOME=OFF ^
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
  -DDCC_BUILD_CYCLES_SUPPORT=OFF ^
  -DDCC_USD_FALLBACK_PROXY_BUILD_CYCLES=OFF ^
  -DDCC_BUILD_RENDERMAN_SUPPORT=OFF ^
  -DDCC_BUILD_BULLET_PHYSICS=OFF ^
  -DDCC_BUILD_HYDRA_OP=OFF ^
  -DDCC_BUILD_TESTS=ON ^
  -DDCC_INSTALL_ADS=OFF ^
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
