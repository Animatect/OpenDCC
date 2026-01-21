# OpenDCC Windows Build Checklist

Use this checklist to track your progress building OpenDCC on Windows.

**Last Updated:** ___________

---

## Phase 0: Prerequisites

- [ ] **Visual Studio 2019 or 2022** installed with C++ tools
  - Version: ___________
  - Location: ___________

- [ ] **Python 3.9/3.10/3.11** installed (64-bit)
  - Version: ___________
  - Location: ___________
  - [ ] Added to PATH
  - [ ] Verified: `python --version` works

- [ ] **CMake 3.18+** installed
  - Version: ___________
  - [ ] Verified: `cmake --version` works

- [ ] **NASM** installed (optional but recommended)
  - Version: ___________
  - [ ] Added to PATH
  - [ ] Verified: `nasm -v` works

- [ ] **Git** installed
  - [ ] Verified: `git --version` works

- [ ] **Disk space** available: _____ GB free (need ~30 GB)

---

## Phase 1: Build USD with Dependencies

**Estimated Time:** 1-4 hours
**Automation:** ✅ Fully automated via script

### Build Process

- [ ] **Opened correct terminal**
  - [ ] "x64 Native Tools Command Prompt for VS 2022" (for .bat)
  - OR [ ] "Developer PowerShell for VS 2022" (for .ps1)

- [ ] **Navigated to scripts:**
  ```cmd
  cd C:\GitHub\OpenDCC\build_scripts
  ```

- [ ] **Ran build script:**
  - [ ] `build_usd_for_opendcc.bat` OR
  - [ ] `.\build_usd_for_opendcc.ps1`

- [ ] **Build started successfully**
  - Start time: ___________

- [ ] **Build completed without errors**
  - End time: ___________
  - Duration: ___________

### Verification

- [ ] **USD installed** at: `C:\VFX\USD_install` (or custom path)
  - Install path: ___________
  - Install size: _____ GB

- [ ] **usdcat works:**
  ```cmd
  C:\VFX\USD_install\bin\usdcat.exe --version
  ```
  - USD version: ___________

- [ ] **Python import works:**
  ```cmd
  C:\VFX\USD_install\usd_env.bat
  python -c "from pxr import Usd; print(Usd.GetVersion())"
  ```

- [ ] **Environment scripts created:**
  - [ ] `usd_env.bat` exists
  - [ ] `usd_env.ps1` exists

### Dependencies Included (auto-built by USD)

- [x] USD
- [x] Boost (with Python support)
- [x] TBB / OneTBB
- [x] OpenEXR
- [x] Imath
- [x] OpenSubdiv
- [x] OpenImageIO (OIIO)
- [x] OpenColorIO (OCIO)
- [x] GLEW
- [x] Embree
- [x] Alembic
- [x] MaterialX
- [x] Image libraries (JPEG, PNG, TIFF, etc.)

**Progress:** ~40-50% of OpenDCC dependencies complete! ✅

---

## Phase 2: Install Qt5 and PySide2

**Estimated Time:** 30 mins - 1 hour
**Automation:** ⚠️ Manual installation

### Qt5 Installation

- [ ] **Downloaded Qt installer** from https://www.qt.io/download-qt-installer
  - File: ___________

- [ ] **Ran Qt installer**
  - [ ] Selected Qt 5.15.x
  - [ ] Selected MSVC 2019 or MSVC 2022 64-bit
  - Install path: ___________ (e.g., C:\Qt\5.15.x)

- [ ] **Qt installed successfully**
  - Version: ___________
  - Location: ___________

- [ ] **Set Qt environment variable:**
  ```cmd
  set Qt5_DIR=C:\Qt\5.15.x\msvc2019_64\lib\cmake\Qt5
  ```
  - Added to system environment: [ ] Yes [ ] No

### PySide2 Installation

- [ ] **Installed PySide2 via pip:**
  ```cmd
  pip install PySide2
  ```

- [ ] **Verified PySide2:**
  ```cmd
  python -c "import PySide2; print(PySide2.__version__)"
  ```
  - Version: ___________

- [ ] **Verified Shiboken2:**
  ```cmd
  python -c "import shiboken2; print(shiboken2.__version__)"
  ```
  - Version: ___________

- [ ] **Found Shiboken clang directory:**
  ```cmd
  python -c "import shiboken2_generator; import os; print(os.path.dirname(shiboken2_generator.__file__))"
  ```
  - Path: ___________

- [ ] **Set SHIBOKEN_CLANG_INSTALL_DIR:**
  ```cmd
  set SHIBOKEN_CLANG_INSTALL_DIR=<path from above>
  ```
  - Path used: ___________

---

## Phase 3: Build Remaining Dependencies

**Estimated Time:** 2-4 hours
**Automation:** ⚠️ Manual builds or vcpkg

### Option A: Using vcpkg (Recommended)

- [ ] **Installed vcpkg:**
  ```cmd
  cd C:\VFX
  git clone https://github.com/microsoft/vcpkg.git
  cd vcpkg
  bootstrap-vcpkg.bat
  ```
  - Location: ___________

- [ ] **Built packages via vcpkg:**
  ```cmd
  vcpkg install zeromq:x64-windows
  vcpkg install eigen3:x64-windows
  vcpkg install openmesh:x64-windows
  vcpkg install doctest:x64-windows
  vcpkg install graphviz:x64-windows
  ```

- [ ] **Set CMAKE_TOOLCHAIN_FILE:**
  ```cmd
  set CMAKE_TOOLCHAIN_FILE=C:\VFX\vcpkg\scripts\buildsystems\vcpkg.cmake
  ```

### Option B: Manual Builds

#### Required Dependencies

- [ ] **ZMQ (ZeroMQ)**
  - Built: [ ] Yes [ ] No
  - Location: ___________
  - Version: ___________

- [ ] **Eigen3**
  - Built: [ ] Yes [ ] No
  - Location: ___________
  - Version: ___________

- [ ] **OpenMesh**
  - Built: [ ] Yes [ ] No
  - Location: ___________
  - Version: ___________

- [ ] **doctest**
  - Built: [ ] Yes [ ] No
  - Location: ___________
  - Version: ___________

- [ ] **sentry**
  - Built: [ ] Yes [ ] No
  - Location: ___________
  - Version: ___________

- [ ] **qtadvanceddocking**
  - Built: [ ] Yes [ ] No
  - Location: ___________
  - Version: ___________

- [ ] **OSL (OpenShadingLanguage)**
  - Built: [ ] Yes [ ] No [ ] Skipped (complex)
  - Location: ___________
  - Version: ___________

#### Optional Dependencies

- [ ] **IGL (libigl)** - Required for USD >= 22.05
  - Built: [ ] Yes [ ] No [ ] Not needed
  - Location: ___________

- [ ] **Skia** - Required for canvas in USD >= 22.05
  - Built: [ ] Yes [ ] No [ ] Not needed
  - Location: ___________

- [ ] **Graphviz** - For node editor
  - Built: [ ] Yes [ ] No [ ] Not needed
  - Location: ___________

- [ ] **Bullet3** - For physics
  - Built: [ ] Yes [ ] No [ ] Disabled
  - Location: ___________

- [ ] **Arnold + ArnoldUSD** - Render delegate
  - Built: [ ] Yes [ ] No [ ] Disabled
  - Location: ___________

- [ ] **Cycles** - Render delegate
  - Built: [ ] Yes [ ] No [ ] Disabled
  - Location: ___________

- [ ] **Renderman** - Render delegate
  - Built: [ ] Yes [ ] No [ ] Disabled
  - Location: ___________

---

## Phase 4: Build OpenDCC

**Estimated Time:** 30 mins - 2 hours
**Automation:** ⚠️ Manual CMake build

### Environment Setup

- [ ] **Created environment script** at `C:\VFX\opendcc_env.bat`
  - [ ] Set all dependency paths
  - [ ] Tested: runs without errors

### CMake Configuration

- [ ] **Created build directory:**
  ```cmd
  cd C:\GitHub\OpenDCC
  mkdir build
  cd build
  ```

- [ ] **Ran CMake configure:**
  ```cmd
  cmake -G "Visual Studio 17 2022" -A x64 [OPTIONS] ..
  ```
  - [ ] No missing dependency errors
  - Notes on issues: ___________

- [ ] **CMake options used:**
  - CMAKE_BUILD_TYPE: ___________
  - CMAKE_INSTALL_PREFIX: ___________
  - CMAKE_PREFIX_PATH: ___________
  - DCC_BUILD_ARNOLD_SUPPORT: [ ] ON [ ] OFF
  - DCC_BUILD_CYCLES_SUPPORT: [ ] ON [ ] OFF
  - DCC_BUILD_RENDERMAN_SUPPORT: [ ] ON [ ] OFF
  - DCC_BUILD_BULLET_PHYSICS: [ ] ON [ ] OFF
  - DCC_BUILD_TESTS: [ ] ON [ ] OFF
  - Other options: ___________

### Build

- [ ] **Ran build:**
  ```cmd
  cmake --build . --config Release --parallel
  ```
  - Start time: ___________
  - End time: ___________
  - Duration: ___________
  - [ ] Completed without errors

### Install

- [ ] **Ran install:**
  ```cmd
  cmake --install . --config Release
  ```
  - Install location: ___________
  - [ ] `bin\dcc_base.exe` exists

---

## Phase 5: Run OpenDCC

**Estimated Time:** 5-30 mins
**Automation:** ⚠️ Manual testing

### Runtime Environment

- [ ] **Created runtime script** at `C:\VFX\OpenDCC_install\run_opendcc.bat`
  - [ ] Set all PATH and PYTHONPATH variables
  - [ ] Tested: runs without errors

### First Run

- [ ] **Launched OpenDCC GUI:**
  ```cmd
  cd C:\VFX\OpenDCC_install
  run_opendcc.bat
  ```
  - [ ] Application window appeared
  - [ ] No crash on startup
  - [ ] UI responsive

- [ ] **Tested Python shell:**
  ```cmd
  run_opendcc.bat --shell
  ```
  - [ ] Python prompt appeared
  - [ ] Can import opendcc: `import opendcc.core`

- [ ] **Ran tests (if built):**
  ```cmd
  run_opendcc.bat --with-tests
  ```
  - Tests passed: _____ / _____
  - Tests failed: _____

### Verification

- [ ] Can open/create USD stage
- [ ] Viewport renders correctly
- [ ] Can manipulate objects
- [ ] Menus work
- [ ] Panels can be docked/undocked
- [ ] Python console works

---

## Build Complete! 🎉

**Total build time:** ___________
**Total install size:** _____ GB

### Next Steps

- [ ] Read [CLAUDE.md](CLAUDE.md) for architecture overview
- [ ] Explore example plugins in `src/packages/`
- [ ] Try creating a simple plugin
- [ ] Experiment with Python API
- [ ] Read OpenUSD documentation

---

## Notes / Issues Encountered

```
[Write any issues you encountered and how you solved them]







```

---

## Build Environment Summary

**For future reference:**

| Component | Version | Location |
|-----------|---------|----------|
| Visual Studio | | |
| Python | | |
| CMake | | |
| USD | | |
| Qt5 | | |
| PySide2 | | |
| OpenDCC | | |

**Environment variables to set:**
```bat
set USD_ROOT=
set Qt5_DIR=
set SHIBOKEN_CLANG_INSTALL_DIR=
set CMAKE_PREFIX_PATH=
```

---

## Useful Commands

**Rebuild OpenDCC only (after changes):**
```cmd
cd C:\GitHub\OpenDCC\build
cmake --build . --config Release --parallel
cmake --install . --config Release
```

**Clean build:**
```cmd
cd C:\GitHub\OpenDCC
rmdir /s /q build
mkdir build
cd build
[run cmake configure again]
```

**Update USD:**
```cmd
cd C:\VFX\OpenUSD
git pull
[run build_usd_for_opendcc.bat again]
```
