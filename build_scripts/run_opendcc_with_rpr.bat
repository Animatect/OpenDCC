@echo off
REM ============================================================================
REM Run OpenDCC with Radeon Pro Render (hdRpr) Support
REM ============================================================================
setlocal

REM ============================================================================
REM CONFIGURATION
REM ============================================================================

set "OPENDCC_INSTALL=C:\VFX\OpenDCC_houdini"
set "HDRPR_INSTALL=C:\VFX\hdRpr_opendcc"

REM Auto-detect Houdini
set "HOUDINI_ROOT="
for /d %%i in ("C:\Program Files\Side Effects Software\Houdini 20*") do set "HOUDINI_ROOT=%%i"
if not defined HOUDINI_ROOT for /d %%i in ("C:\Program Files\Side Effects Software\Houdini 21*") do set "HOUDINI_ROOT=%%i"
if not defined HOUDINI_ROOT for /d %%i in ("C:\Program Files\Side Effects Software\Houdini 19*") do set "HOUDINI_ROOT=%%i"

REM Auto-detect Qt5
set "QT5_DIR="
for /d %%i in ("C:\Qt\5.15*\msvc2019_64") do set "QT5_DIR=%%i"

REM ============================================================================
REM VALIDATE
REM ============================================================================

if not exist "%OPENDCC_INSTALL%\bin\dcc_base.exe" (
    echo ERROR: OpenDCC not found at %OPENDCC_INSTALL%
    pause
    exit /b 1
)

echo Found Houdini: %HOUDINI_ROOT%
echo Found Qt5: %QT5_DIR%

REM ============================================================================
REM DETECT HOUDINI PYTHON VERSION
REM ============================================================================

set "HOUDINI_PYTHON_DIR="
if exist "%HOUDINI_ROOT%\python39\python.exe" set "HOUDINI_PYTHON_DIR=%HOUDINI_ROOT%\python39"
if exist "%HOUDINI_ROOT%\python310\python.exe" set "HOUDINI_PYTHON_DIR=%HOUDINI_ROOT%\python310"
if exist "%HOUDINI_ROOT%\python311\python.exe" set "HOUDINI_PYTHON_DIR=%HOUDINI_ROOT%\python311"

echo Found Houdini Python: %HOUDINI_PYTHON_DIR%

REM ============================================================================
REM SETUP PYTHON ENVIRONMENT
REM ============================================================================

REM CRITICAL: Set PYTHONHOME so Python can find its standard library (encodings, etc.)
set "PYTHONHOME=%HOUDINI_PYTHON_DIR%"

REM Add Houdini Python to PATH
set "PATH=%HOUDINI_PYTHON_DIR%;%HOUDINI_ROOT%\bin;%PATH%"

REM Setup PYTHONPATH for OpenDCC and Houdini USD modules
set "PYTHONPATH=%OPENDCC_INSTALL%\lib\python"
set "PYTHONPATH=%HOUDINI_PYTHON_DIR%\lib\site-packages;%PYTHONPATH%"
set "PYTHONPATH=%HOUDINI_PYTHON_DIR%\lib\site-packages-forced;%PYTHONPATH%"

REM ============================================================================
REM SETUP QT AND OPENDCC
REM ============================================================================

set "PATH=%QT5_DIR%\bin;%PATH%"
set "PATH=%OPENDCC_INSTALL%\bin;%PATH%"

REM ============================================================================
REM SETUP HDRPR (if available)
REM ============================================================================

if not exist "%HDRPR_INSTALL%\plugin" goto :skip_hdrpr

echo Found hdRpr: %HDRPR_INSTALL%
set "PXR_PLUGINPATH_NAME=%HDRPR_INSTALL%\plugin"
set "PATH=%HDRPR_INSTALL%\lib;%PATH%"
set "PYTHONPATH=%HDRPR_INSTALL%\lib\python;%PYTHONPATH%"
echo hdRpr Radeon Pro Render enabled

:skip_hdrpr

REM ============================================================================
REM COPY MISSING DLLS (required for UI/menus/shelves)
REM ============================================================================

echo.
echo Checking for missing DLLs...

REM Determine Python version suffix for DLL names
set "PY_SUFFIX=cp39"
if "%HOUDINI_PYTHON_DIR%"=="%HOUDINI_ROOT%\python310" set "PY_SUFFIX=cp310"
if "%HOUDINI_PYTHON_DIR%"=="%HOUDINI_ROOT%\python311" set "PY_SUFFIX=cp311"

REM Copy shiboken2 DLL from Houdini if missing
if not exist "%OPENDCC_INSTALL%\bin\shiboken2.%PY_SUFFIX%-win_amd64.dll" (
    if exist "%HOUDINI_PYTHON_DIR%\lib\site-packages-forced\shiboken2\shiboken2.%PY_SUFFIX%-win_amd64.dll" (
        echo   Copying shiboken2.%PY_SUFFIX%-win_amd64.dll...
        copy /Y "%HOUDINI_PYTHON_DIR%\lib\site-packages-forced\shiboken2\shiboken2.%PY_SUFFIX%-win_amd64.dll" "%OPENDCC_INSTALL%\bin\" >nul
    )
)

REM Copy PySide2 DLL from Houdini if missing
if not exist "%OPENDCC_INSTALL%\bin\pyside2.%PY_SUFFIX%-win_amd64.dll" (
    if exist "%HOUDINI_PYTHON_DIR%\lib\site-packages-forced\PySide2\pyside2.%PY_SUFFIX%-win_amd64.dll" (
        echo   Copying pyside2.%PY_SUFFIX%-win_amd64.dll...
        copy /Y "%HOUDINI_PYTHON_DIR%\lib\site-packages-forced\PySide2\pyside2.%PY_SUFFIX%-win_amd64.dll" "%OPENDCC_INSTALL%\bin\" >nul
    )
)

REM Copy Qt5 DLLs if missing
for %%f in (Qt5Multimedia Qt5Svg Qt5Network Qt5Xml Qt5XmlPatterns) do (
    if not exist "%OPENDCC_INSTALL%\bin\%%f.dll" (
        if exist "%QT5_DIR%\bin\%%f.dll" (
            echo   Copying %%f.dll...
            copy /Y "%QT5_DIR%\bin\%%f.dll" "%OPENDCC_INSTALL%\bin\" >nul
        )
    )
)

REM ============================================================================
REM DEBUG OUTPUT
REM ============================================================================

echo.
echo Environment:
echo   PYTHONHOME=%PYTHONHOME%
echo   HOUDINI_PYTHON_DIR=%HOUDINI_PYTHON_DIR%
echo   PXR_PLUGINPATH_NAME=%PXR_PLUGINPATH_NAME%
echo.

REM ============================================================================
REM LAUNCH
REM ============================================================================

echo Launching OpenDCC...
"%OPENDCC_INSTALL%\bin\dcc_base.exe" %*
