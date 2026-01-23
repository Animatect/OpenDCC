@echo off
REM ============================================================================
REM OpenDCC launcher script for Houdini-based builds
REM Sets up PATH and Python environment for running with Houdini's libraries
REM ============================================================================

set HOUDINI_ROOT=C:\Program Files\Side Effects Software\Houdini 20.5.487
set QT_DIR=C:\Qt\5.15.2\msvc2019_64

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

REM PYTHONPATH adds our OpenDCC Python modules plus Houdini's packages
REM site-packages: standard Python packages
REM site-packages-forced: PySide2, shiboken2, and Houdini-specific packages
set PYTHONPATH=%HOUDINI_ROOT%\python311\lib\site-packages;%HOUDINI_ROOT%\python311\lib\site-packages-forced

REM Set USD plugin path if needed
set PXR_PLUGINPATH_NAME=%HOUDINI_ROOT%\houdini\dso\usd_plugins

REM ============================================================================
REM Run the application
REM ============================================================================
cd /d "%~dp0..\build_houdini\src\bin\dcc_base\Release"
echo Starting OpenDCC (Houdini build)...
echo   HOUDINI_ROOT: %HOUDINI_ROOT%
echo   PYTHONHOME:   %PYTHONHOME%
echo.
dcc_base.exe %*
