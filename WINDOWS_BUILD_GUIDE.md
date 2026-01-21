# Step-by-Step Windows Build Guide for OpenDCC

This guide provides a practical, step-by-step approach to building OpenDCC on Windows by leveraging USD's `build_usd.py` script to automatically build most dependencies.

## Strategy Overview

Building OpenDCC on Windows is complex due to 20+ dependencies. This guide uses a **bootstrapping approach**:

1. ✅ **Build USD** with `build_usd.py` → This automatically builds ~40-50% of OpenDCC's dependencies
2. ✅ **Install Qt5 and PySide2** → Using official installers or pre-built packages
3. ✅ **Build remaining dependencies** → Small set of specialized libraries
4. ✅ **Build OpenDCC** → With all dependencies in place

## Prerequisites

### Required Software

1. **Visual Studio 2019 or 2022** with "Desktop development with C++" workload
   - Download: https://visualstudio.microsoft.com/downloads/
   - Community edition is free and sufficient

2. **Python 3.9 or 3.10** (matching VFX Reference Platform 2023/2024)
   - Download: https://www.python.org/downloads/
   - ⚠️ Use the 64-bit version
   - ✅ Add Python to PATH during installation

3. **CMake 3.18+**
   - Download: https://cmake.org/download/
   - Or install via: `pip install cmake`

4. **Git**
   - Download: https://git-scm.com/download/win

5. **NASM** (for some image format dependencies)
   - Download: https://www.nasm.us/
   - Add to PATH

### Recommended Tools

- **Ninja** (faster builds): `pip install ninja`
- **7-Zip** (for extracting archives): https://www.7-zip.org/

## Phase 1: Build USD with Dependencies

USD's `build_usd.py` will automatically build these OpenDCC dependencies:
- ✅ USD (core requirement)
- ✅ Boost (with Python support)
- ✅ TBB (Threading Building Blocks)
- ✅ OpenEXR + Imath
- ✅ OpenSubdiv
- ✅ OpenImageIO (OIIO)
- ✅ OpenColorIO (OCIO)
- ✅ GLEW
- ✅ Embree (ray tracing)
- ✅ Alembic
- ✅ MaterialX

### Step 1.1: Clone USD Repository

```cmd
cd C:\
mkdir VFX
cd VFX

git clone https://github.com/PixarAnimationStudios/OpenUSD.git
cd OpenUSD
```

### Step 1.2: Open Visual Studio Command Prompt

⚠️ **Important:** Use the correct Visual Studio command prompt with 64-bit tools.

**For Visual Studio 2022:**
- Search for "x64 Native Tools Command Prompt for VS 2022" in Start Menu
- Run as Administrator (recommended)

**For Visual Studio 2019:**
- Search for "x64 Native Tools Command Prompt for VS 2019"

### Step 1.3: Run build_usd.py

```cmd
cd C:\VFX\OpenUSD

python build_scripts\build_usd.py ^
  --build-variant release ^
  --generator "Visual Studio 17 2022" ^
  -j 8 ^
  --python ^
  --imaging ^
  --openimageio ^
  --opencolorio ^
  --alembic ^
  --embree ^
  --materialx ^
  --onetbb ^
  --tests ^
  C:\VFX\USD_install
```

**Options explained:**
- `--build-variant release` - Optimized build (use `relwithdebuginfo` for debugging)
- `--generator "Visual Studio 17 2022"` - Use Visual Studio 2022 (adjust for 2019)
- `-j 8` - Use 8 parallel jobs (adjust based on your CPU cores)
- `--python` - Build Python bindings (required for OpenDCC)
- `--imaging` - Build imaging components (required)
- `--openimageio` - Build OIIO (required for OpenDCC)
- `--opencolorio` - Build OCIO (required for OpenDCC)
- `--alembic` - Build Alembic support
- `--embree` - Build Embree ray tracing (required for OpenDCC)
- `--materialx` - Include MaterialX (enabled by default)
- `--onetbb` - Use OneTBB (VFX Platform 2023+)
- `--tests` - Include tests
- `C:\VFX\USD_install` - Installation directory

⏱️ **This will take 1-4 hours depending on your system.**

### Step 1.4: Verify USD Build

```cmd
cd C:\VFX\USD_install

:: Check USD version
bin\usdcat.exe --version

:: Set environment variables
set USD_ROOT=C:\VFX\USD_install
set PATH=%USD_ROOT%\bin;%USD_ROOT%\lib;%PATH%
set PYTHONPATH=%USD_ROOT%\lib\python;%PYTHONPATH%

:: Test Python import
python -c "from pxr import Usd; print('USD version:', Usd.GetVersion())"
```

If this works, you have successfully built USD with most of OpenDCC's dependencies! ✅

## Phase 2: Install Qt5 and PySide2

Qt and PySide2 are NOT built by USD's build_usd.py and must be installed separately.

### Option 2A: Qt Official Installer (Recommended)

1. **Download Qt Online Installer**
   - Visit: https://www.qt.io/download-qt-installer
   - Download the open-source installer

2. **Install Qt 5.15.x** (VFX Platform 2023/2024 uses Qt 5.15)
   - Run the installer
   - Select Qt 5.15.x for MSVC 2019 64-bit (or MSVC 2022)
   - Install to: `C:\Qt\5.15.x`
   - Select components:
     - Qt 5.15.x → MSVC 2019 64-bit (or MSVC 2022)
     - Qt 5.15.x Sources (optional, for debugging)

3. **Set environment variables**
   ```cmd
   set Qt5_DIR=C:\Qt\5.15.x\msvc2019_64\lib\cmake\Qt5
   set PATH=C:\Qt\5.15.x\msvc2019_64\bin;%PATH%
   ```

### Option 2B: Build Qt from Source (Advanced)

If you need a specific Qt configuration:

```cmd
:: Download Qt source
:: https://download.qt.io/official_releases/qt/5.15/

:: Build Qt (this takes hours)
configure.bat -release -opensource -confirm-license -nomake examples -nomake tests -prefix C:\VFX\Qt5
nmake
nmake install
```

### Step 2.2: Install PySide2 and Shiboken2

**Option A: Install from pip (Quick)**

```cmd
:: Use the same Python you used for USD
pip install PySide2

:: Verify installation
python -c "import PySide2; print(PySide2.__version__)"
python -c "import shiboken2; print(shiboken2.__version__)"
```

**Option B: Build from Source (Advanced)**

Follow PySide2 build instructions if you need a custom build:
https://doc.qt.io/qtforpython-5/gettingstarted.html

### Step 2.3: Set PySide2 Environment Variables

```cmd
:: Find PySide2 installation path
python -c "import PySide2; import os; print(os.path.dirname(PySide2.__file__))"

:: Example output: C:\Python310\Lib\site-packages\PySide2

:: Find Shiboken clang directory
:: Look in: C:\Python310\Lib\site-packages\shiboken2_generator
:: Or: C:\Python310\Lib\site-packages\PySide2

:: Set required environment variable
set SHIBOKEN_CLANG_INSTALL_DIR=C:\Python310\Lib\site-packages\shiboken2_generator
```

⚠️ **CRITICAL:** OpenDCC requires `SHIBOKEN_CLANG_INSTALL_DIR` to be set or CMake will fail.

## Phase 3: Build Remaining Dependencies

These libraries must be built or installed separately:

### Required Libraries

1. **ZMQ (ZeroMQ)** - Messaging for IPC
2. **Eigen3** - Linear algebra
3. **OpenMesh** - Mesh data structure
4. **doctest** - Testing framework
5. **sentry** - Crash reporting
6. **qtadvanceddocking** - Qt docking system
7. **OSL (OpenShadingLanguage)** - Shader language

### Optional Libraries (for advanced features)

8. **IGL (libigl)** - Required for USD >= 22.05 texture painting
9. **Skia** - Required for USD >= 22.05 canvas features
10. **Graphviz** - For node editor visualization
11. **Bullet3** - Physics simulation
12. **Arnold/Cycles/Renderman** - Render delegates

### Building Strategy Options

**Option A: Use vcpkg (Recommended for beginners)**

vcpkg is a Microsoft package manager that can build many dependencies:

```cmd
:: Install vcpkg
cd C:\VFX
git clone https://github.com/microsoft/vcpkg.git
cd vcpkg
bootstrap-vcpkg.bat

:: Install dependencies
vcpkg install zeromq:x64-windows
vcpkg install eigen3:x64-windows
vcpkg install openmesh:x64-windows
vcpkg install doctest:x64-windows
vcpkg install graphviz:x64-windows

:: Set CMAKE_TOOLCHAIN_FILE for OpenDCC build
set CMAKE_TOOLCHAIN_FILE=C:\VFX\vcpkg\scripts\buildsystems\vcpkg.cmake
```

**Option B: Build manually**

See individual library documentation for build instructions. Create a directory structure:

```
C:\VFX\
  ├── USD_install\       (from Phase 1)
  ├── Qt5\               (from Phase 2)
  ├── zeromq\
  ├── eigen3\
  ├── openmesh\
  ├── doctest\
  ├── sentry\
  ├── qtadvanceddocking\
  └── osl\
```

### Step 3.1: ZMQ (ZeroMQ)

```cmd
git clone https://github.com/zeromq/libzmq.git C:\VFX\libzmq_src
cd C:\VFX\libzmq_src
mkdir build && cd build

cmake -G "Visual Studio 17 2022" -A x64 ^
  -DCMAKE_INSTALL_PREFIX=C:\VFX\zeromq ^
  -DBUILD_SHARED=ON ^
  ..

cmake --build . --config Release
cmake --install . --config Release
```

### Step 3.2: Eigen3

```cmd
git clone https://gitlab.com/libeigen/eigen.git C:\VFX\eigen_src
cd C:\VFX\eigen_src
mkdir build && cd build

cmake -G "Visual Studio 17 2022" -A x64 ^
  -DCMAKE_INSTALL_PREFIX=C:\VFX\eigen3 ^
  ..

cmake --build . --config Release
cmake --install . --config Release
```

### Step 3.3: OpenMesh

```cmd
git clone https://www.graphics.rwth-aachen.de:9000/OpenMesh/OpenMesh.git C:\VFX\openmesh_src
cd C:\VFX\openmesh_src
mkdir build && cd build

cmake -G "Visual Studio 17 2022" -A x64 ^
  -DCMAKE_INSTALL_PREFIX=C:\VFX\openmesh ^
  -DBUILD_APPS=OFF ^
  ..

cmake --build . --config Release
cmake --install . --config Release
```

### Step 3.4: doctest

```cmd
git clone https://github.com/doctest/doctest.git C:\VFX\doctest_src
cd C:\VFX\doctest_src
mkdir build && cd build

cmake -G "Visual Studio 17 2022" -A x64 ^
  -DCMAKE_INSTALL_PREFIX=C:\VFX\doctest ^
  ..

cmake --build . --config Release
cmake --install . --config Release
```

### Step 3.5: Sentry Native

```cmd
git clone https://github.com/getsentry/sentry-native.git C:\VFX\sentry_src
cd C:\VFX\sentry_src
git submodule update --init --recursive
mkdir build && cd build

cmake -G "Visual Studio 17 2022" -A x64 ^
  -DCMAKE_INSTALL_PREFIX=C:\VFX\sentry ^
  -DSENTRY_BUILD_SHARED_LIBS=ON ^
  ..

cmake --build . --config Release
cmake --install . --config Release
```

### Step 3.6: Qt Advanced Docking System

```cmd
git clone https://github.com/githubuser0xFFFF/Qt-Advanced-Docking-System.git C:\VFX\qtads_src
cd C:\VFX\qtads_src
mkdir build && cd build

cmake -G "Visual Studio 17 2022" -A x64 ^
  -DCMAKE_INSTALL_PREFIX=C:\VFX\qtadvanceddocking ^
  -DCMAKE_PREFIX_PATH=C:\Qt\5.15.x\msvc2019_64 ^
  -DBUILD_EXAMPLES=OFF ^
  ..

cmake --build . --config Release
cmake --install . --config Release
```

### Step 3.7: OpenShadingLanguage (OSL)

OSL is complex and has dependencies (LLVM, etc.). Consider using a pre-built version from VFX Platform or your studio.

If building from source:
```cmd
:: Follow OSL build instructions
:: https://github.com/AcademySoftwareFoundation/OpenShadingLanguage
:: This requires LLVM and is quite involved
```

## Phase 4: Build OpenDCC

Now with all dependencies in place, we can build OpenDCC!

### Step 4.1: Create Build Environment Script

Create `C:\VFX\opendcc_env.bat`:

```bat
@echo off
echo Setting up OpenDCC build environment...

:: USD and its dependencies
set USD_ROOT=C:\VFX\USD_install
set PATH=%USD_ROOT%\bin;%USD_ROOT%\lib;%PATH%
set PYTHONPATH=%USD_ROOT%\lib\python;%PYTHONPATH%

:: Qt5
set Qt5_DIR=C:\Qt\5.15.x\msvc2019_64\lib\cmake\Qt5
set PATH=C:\Qt\5.15.x\msvc2019_64\bin;%PATH%

:: PySide2/Shiboken2
set SHIBOKEN_CLANG_INSTALL_DIR=C:\Python310\Lib\site-packages\shiboken2_generator

:: Additional dependencies
set ZMQ_ROOT=C:\VFX\zeromq
set Eigen3_ROOT=C:\VFX\eigen3
set OpenMesh_ROOT=C:\VFX\openmesh
set doctest_ROOT=C:\VFX\doctest
set sentry_ROOT=C:\VFX\sentry
set qtadvanceddocking_ROOT=C:\VFX\qtadvanceddocking

:: If you built OSL
set OSL_ROOT=C:\VFX\osl

:: Optional: vcpkg toolchain
:: set CMAKE_TOOLCHAIN_FILE=C:\VFX\vcpkg\scripts\buildsystems\vcpkg.cmake

echo Environment ready!
```

### Step 4.2: Configure OpenDCC Build

Open **x64 Native Tools Command Prompt for VS 2022** and:

```cmd
:: Load environment
call C:\VFX\opendcc_env.bat

:: Navigate to OpenDCC source
cd C:\GitHub\OpenDCC
mkdir build
cd build

:: Configure with CMake
cmake -G "Visual Studio 17 2022" -A x64 ^
  -DCMAKE_BUILD_TYPE=Release ^
  -DCMAKE_INSTALL_PREFIX=C:\VFX\OpenDCC_install ^
  -DCMAKE_PREFIX_PATH="%USD_ROOT%;%Qt5_DIR%;%ZMQ_ROOT%;%Eigen3_ROOT%;%OpenMesh_ROOT%;%doctest_ROOT%;%sentry_ROOT%;%qtadvanceddocking_ROOT%" ^
  -DDCC_BUILD_ARNOLD_SUPPORT=OFF ^
  -DDCC_BUILD_CYCLES_SUPPORT=OFF ^
  -DDCC_BUILD_RENDERMAN_SUPPORT=OFF ^
  -DDCC_BUILD_BULLET_PHYSICS=OFF ^
  -DDCC_BUILD_TESTS=ON ^
  ..
```

**If CMake reports missing packages:**
- Note which packages are missing
- Either build them (Phase 3) or disable the feature requiring them
- Adjust `-DDCC_BUILD_*` options to disable optional features

### Step 4.3: Build OpenDCC

```cmd
:: Build with all CPU cores
cmake --build . --config Release --parallel

:: Or specify number of parallel jobs
cmake --build . --config Release -- /maxcpucount:8
```

⏱️ **This will take 30 minutes to 2 hours depending on your system.**

### Step 4.4: Install OpenDCC

```cmd
cmake --install . --config Release
```

## Phase 5: Run OpenDCC

### Step 5.1: Create Runtime Environment Script

Create `C:\VFX\OpenDCC_install\run_opendcc.bat`:

```bat
@echo off
:: Set USD environment
set USD_ROOT=C:\VFX\USD_install
set PATH=%USD_ROOT%\bin;%USD_ROOT%\lib;%PATH%
set PYTHONPATH=%USD_ROOT%\lib\python;%PYTHONPATH%

:: Set Qt environment
set PATH=C:\Qt\5.15.x\msvc2019_64\bin;%PATH%

:: Set other dependency paths
set PATH=%PATH%;C:\VFX\zeromq\bin
set PATH=%PATH%;C:\VFX\sentry\bin

:: Set OpenDCC paths
set OPENDCC_ROOT=%~dp0
set PATH=%OPENDCC_ROOT%\bin;%PATH%
set PYTHONPATH=%OPENDCC_ROOT%\lib\python;%PYTHONPATH%

:: Run OpenDCC
bin\dcc_base.exe %*
```

### Step 5.2: Run OpenDCC

```cmd
cd C:\VFX\OpenDCC_install
run_opendcc.bat

:: Or with Python shell
run_opendcc.bat --shell

:: Or run a script
run_opendcc.bat --script path\to\script.py

:: Or run tests
run_opendcc.bat --with-tests
```

## Troubleshooting

### USD build_usd.py fails

**Problem:** Build errors during USD compilation

**Solutions:**
- Ensure you're using the correct Visual Studio command prompt (64-bit)
- Check you have enough disk space (USD build requires ~20-30 GB)
- Try building without optional components first (remove `--openimageio`, etc.)
- Check Python version matches (3.9 or 3.10 recommended)

### Missing DLLs at runtime

**Problem:** Application crashes with "DLL not found" errors

**Solutions:**
- Ensure all dependency `bin\` directories are in PATH
- Use Dependency Walker (https://dependencywalker.com/) to identify missing DLLs
- Copy missing DLLs to OpenDCC's `bin\` directory

### SHIBOKEN_CLANG_INSTALL_DIR not found

**Problem:** CMake configuration fails with this error

**Solutions:**
1. Find where PySide2/Shiboken2 installed:
   ```cmd
   python -c "import shiboken2_generator; import os; print(os.path.dirname(shiboken2_generator.__file__))"
   ```
2. Or look in: `C:\Python310\Lib\site-packages\shiboken2_generator`
3. Set the variable: `set SHIBOKEN_CLANG_INSTALL_DIR=<path>`

### OpenDCC CMake can't find USD

**Problem:** `Could not find USD`

**Solutions:**
- Ensure `USD_ROOT` is set: `set USD_ROOT=C:\VFX\USD_install`
- Or set `USD_CONFIG_FILE`: `set USD_CONFIG_FILE=C:\VFX\USD_install\pxrConfig.cmake`
- Check that `pxrConfig.cmake` exists in USD_ROOT

### Python version mismatch

**Problem:** Boost.Python or PySide2 version errors

**Solutions:**
- Ensure same Python version used for USD, PySide2, and OpenDCC
- Check Python version: `python --version`
- Rebuild USD with correct Python if needed

## Quick Reference: Full Dependency Checklist

Before building OpenDCC, verify you have:

- [x] USD (with Boost, TBB, OpenEXR, Imath, OpenSubdiv, OIIO, OCIO, GLEW, Embree)
- [x] Qt5 5.15.x
- [x] PySide2 + Shiboken2
- [x] ZMQ
- [x] Eigen3
- [x] OpenMesh
- [x] doctest
- [x] sentry
- [x] qtadvanceddocking
- [x] OSL
- [x] Python 3.9/3.10
- [x] Visual Studio 2019/2022
- [x] CMake 3.18+

## Next Steps

After successfully building:

1. Read [CLAUDE.md](CLAUDE.md) for architecture overview
2. Read [BUILDING_WINDOWS.md](BUILDING_WINDOWS.md) for detailed CMake options
3. Explore example plugins in [src/packages](src/packages)
4. Try the Python API in shell mode: `dcc_base.exe --shell`

## Getting Help

If you encounter issues:

1. Check the [OpenDCC GitHub Issues](https://github.com/OpenDCC/OpenDCC/issues)
2. Review [USD build documentation](https://github.com/PixarAnimationStudios/OpenUSD/blob/release/BUILDING.md)
3. Consult [VFX Reference Platform](https://vfxplatform.com/) for compatible library versions
4. Open a new issue with your build log and CMake output

Good luck with your build! 🚀
