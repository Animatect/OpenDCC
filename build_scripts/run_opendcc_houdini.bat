@echo off
REM ============================================================================
REM OpenDCC launcher script for Houdini-based builds
REM Sets up PATH and Python environment for running with Houdini's libraries
REM ============================================================================

set HOUDINI_ROOT=C:\Program Files\Side Effects Software\Houdini 20.5.487
set QT_DIR=C:\Qt\5.15.2\msvc2019_64
set OPENDCC_SOURCE=%~dp0..
set BUILD_DIR=%OPENDCC_SOURCE%\build_houdini
set EXE_DIR=%BUILD_DIR%\src\bin\dcc_base\Release

REM ============================================================================
REM Copy required config files to executable directory
REM ============================================================================
if not exist "%EXE_DIR%\default.toml" (
    echo Copying default.toml to executable directory...
    copy "%BUILD_DIR%\configs\default.toml" "%EXE_DIR%\default.toml" >nul
)

REM ============================================================================
REM Copy built .pyd modules to opendcc source package directory
REM This ensures Python can find them as opendcc.module_name
REM ============================================================================
set OPENDCC_PY_PKG=%OPENDCC_SOURCE%\src\python\opendcc

echo Copying built Python modules to opendcc package...

REM Core _core.pyd module (opendcc.core._core)
if not exist "%OPENDCC_PY_PKG%\core\_core.pyd" (
    copy "%BUILD_DIR%\src\lib\opendcc\app\Release\_core.pyd" "%OPENDCC_PY_PKG%\core\_core.pyd" >nul
)

REM usd_fallback_proxy module (opendcc.usd_fallback_proxy)
if not exist "%OPENDCC_PY_PKG%\usd_fallback_proxy.pyd" (
    copy "%BUILD_DIR%\src\lib\usd\usd_fallback_proxy\py_usd_fallback_proxy\Release\usd_fallback_proxy.pyd" "%OPENDCC_PY_PKG%\usd_fallback_proxy.pyd" >nul
)

REM app_config module (opendcc.app_config)
if not exist "%OPENDCC_PY_PKG%\app_config.pyd" (
    copy "%BUILD_DIR%\src\lib\opendcc\base\app_config\python_bindings\Release\app_config.pyd" "%OPENDCC_PY_PKG%\app_config.pyd" >nul
)

REM cmds module (opendcc.cmds -> _cmds)
if not exist "%OPENDCC_PY_PKG%\_cmds.pyd" (
    copy "%BUILD_DIR%\src\lib\opendcc\base\commands_api\python_bindings\Release\_cmds.pyd" "%OPENDCC_PY_PKG%\_cmds.pyd" >nul
)

REM rendersystem module (opendcc.rendersystem)
if not exist "%OPENDCC_PY_PKG%\rendersystem.pyd" (
    copy "%BUILD_DIR%\src\lib\opendcc\render_system\Release\rendersystem.pyd" "%OPENDCC_PY_PKG%\rendersystem.pyd" >nul
)

REM color_theme module (opendcc.color_theme)
if not exist "%OPENDCC_PY_PKG%\color_theme.pyd" (
    copy "%BUILD_DIR%\src\lib\opendcc\ui\color_theme\wrap_color_theme\Release\color_theme.pyd" "%OPENDCC_PY_PKG%\color_theme.pyd" >nul
)

REM packaging module (opendcc.packaging)
if not exist "%OPENDCC_PY_PKG%\packaging.pyd" (
    copy "%BUILD_DIR%\src\lib\opendcc\base\packaging\packaging_py\Release\packaging.pyd" "%OPENDCC_PY_PKG%\packaging.pyd" >nul
)

REM Add Houdini bin directories to PATH (for USD, Python, hboost, etc.)
set PATH=%HOUDINI_ROOT%\bin;%PATH%
set PATH=%HOUDINI_ROOT%\custom\houdini\dsolib;%PATH%

REM Add Qt bin directory
set PATH=%QT_DIR%\bin;%PATH%

REM ============================================================================
REM CRITICAL: Python environment setup for Houdini's Python
REM ============================================================================
REM Houdini uses Python 3.11 with its own site-packages structure.
REM We must set PYTHONHOME to Houdini's Python root so that Python can find
REM the standard library (encodings, etc.) and site-packages.

set PYTHONHOME=%HOUDINI_ROOT%\python311

REM ============================================================================
REM PYTHONPATH setup - Order matters!
REM ============================================================================
REM 1. OpenDCC source Python modules (startup.py, actions, UI, etc.)
REM 2. OpenDCC built Python modules (.pyd files from core libs)
REM 3. OpenDCC built Python modules (.pyd files from packages)
REM 4. Houdini's site-packages (standard Python packages)
REM 5. Houdini's site-packages-forced (PySide2, shiboken2, pxr)

set PYTHONPATH=%OPENDCC_SOURCE%\src\python

REM Core library .pyd modules
set PYTHONPATH=%PYTHONPATH%;%OPENDCC_SOURCE%\build_houdini\src\lib\opendcc\app\Release
set PYTHONPATH=%PYTHONPATH%;%OPENDCC_SOURCE%\build_houdini\src\lib\opendcc\base\commands_api\python_bindings\Release
set PYTHONPATH=%PYTHONPATH%;%OPENDCC_SOURCE%\build_houdini\src\lib\opendcc\base\app_config\python_bindings\Release
set PYTHONPATH=%PYTHONPATH%;%OPENDCC_SOURCE%\build_houdini\src\lib\opendcc\base\packaging\packaging_py\Release
set PYTHONPATH=%PYTHONPATH%;%OPENDCC_SOURCE%\build_houdini\src\lib\opendcc\render_system\Release
set PYTHONPATH=%PYTHONPATH%;%OPENDCC_SOURCE%\build_houdini\src\lib\opendcc\ui\color_theme\wrap_color_theme\Release
set PYTHONPATH=%PYTHONPATH%;%OPENDCC_SOURCE%\build_houdini\src\lib\opendcc\usd\hydra_render_session_api\Release
set PYTHONPATH=%PYTHONPATH%;%OPENDCC_SOURCE%\build_houdini\src\lib\opendcc\usd\usd_live_share\python\Release
set PYTHONPATH=%PYTHONPATH%;%OPENDCC_SOURCE%\build_houdini\src\lib\usd\usd_fallback_proxy\py_usd_fallback_proxy\Release
set PYTHONPATH=%PYTHONPATH%;%OPENDCC_SOURCE%\build_houdini\src\lib\usd\usd_ui_ext\Release

REM Animation and expression engine modules
set PYTHONPATH=%PYTHONPATH%;%OPENDCC_SOURCE%\build_houdini\src\lib\opendcc\anim_engine\core\python\Release
set PYTHONPATH=%PYTHONPATH%;%OPENDCC_SOURCE%\build_houdini\src\lib\opendcc\expressions_engine\python\Release

REM Package Python modules (source)
set PYTHONPATH=%PYTHONPATH%;%OPENDCC_SOURCE%\src\packages

REM Package .pyd modules (built)
set PYTHONPATH=%PYTHONPATH%;%OPENDCC_SOURCE%\build_houdini\src\packages\opendcc.anim_engine.schema\Release
set PYTHONPATH=%PYTHONPATH%;%OPENDCC_SOURCE%\build_houdini\src\packages\opendcc.anim_engine.core\opendcc.anim_engine.core_py\Release
set PYTHONPATH=%PYTHONPATH%;%OPENDCC_SOURCE%\build_houdini\src\packages\opendcc.expression\Release
set PYTHONPATH=%PYTHONPATH%;%OPENDCC_SOURCE%\build_houdini\src\packages\opendcc.expression\expression_engine_extension_py\Release

REM Houdini's Python packages
set PYTHONPATH=%PYTHONPATH%;%HOUDINI_ROOT%\python311\lib\site-packages
set PYTHONPATH=%PYTHONPATH%;%HOUDINI_ROOT%\python311\lib\site-packages-forced

REM Set USD plugin path - include both Houdini's USD plugins and OpenDCC's
set PXR_PLUGINPATH_NAME=%HOUDINI_ROOT%\houdini\dso\usd_plugins

REM ============================================================================
REM Run the application
REM ============================================================================
cd /d "%OPENDCC_SOURCE%\build_houdini\src\bin\dcc_base\Release"
echo Starting OpenDCC (Houdini build)...
echo   HOUDINI_ROOT:   %HOUDINI_ROOT%
echo   PYTHONHOME:     %PYTHONHOME%
echo   OPENDCC_SOURCE: %OPENDCC_SOURCE%
echo.
dcc_base.exe %*
