# Building OpenDCC on Windows

This guide provides detailed instructions for building OpenDCC on Windows based on the CMake configuration files.

## Prerequisites

### Required Software

1. **Visual Studio 2019 or 2022** with C++ development tools
2. **CMake 3.18 or later**
3. **Git** (for version control)
4. **Python 3.x** (VFX Platform compliant version, typically Python 3.9 or 3.10)

### Required Dependencies

OpenDCC requires numerous VFX industry-standard libraries. You'll need to either:
- Build them from source (time-consuming but gives you control)
- Use pre-built VFX Platform packages (recommended if available)
- Use a package manager like vcpkg (partial support)

#### Core Dependencies (REQUIRED)

These are detected via CMake's `find_package()` and must be available:

| Library | Purpose | CMake Variable |
|---------|---------|----------------|
| **USD (Pixar)** | Scene description, Hydra rendering | `USD_ROOT` or `USD_CONFIG_FILE` |
| **Qt5** | GUI framework (Core, Gui, Widgets, OpenGL, Svg, Multimedia, Network, LinguistTools) | `Qt5_DIR` |
| **PySide2/Shiboken2** | Python-Qt bindings | `SHIBOKEN_CLANG_INSTALL_DIR` (required) |
| **TBB** | Threading Building Blocks | `TBB_ROOT` |
| **Boost** | C++ utilities (including Boost.Python) | `BOOST_ROOT` |
| **OpenGL** | Graphics API | System provided |
| **GLEW** | OpenGL extension wrangler | `GLEW_ROOT` |
| **OpenColorIO (OCIO)** | Color management | `OpenColorIO_ROOT` |
| **OpenImageIO (OIIO)** | Image I/O | `OpenImageIO_ROOT` |
| **OpenEXR** | EXR image format | `OpenEXR_ROOT` |
| **Imath** | Math library | `Imath_ROOT` |
| **OpenSubdiv** | Subdivision surfaces | `OpenSubdiv_ROOT` |
| **OSL** | Open Shading Language | `OSL_ROOT` |
| **ZMQ** | Messaging library for IPC | `ZMQ_ROOT` |
| **Eigen3** | Linear algebra | `Eigen3_ROOT` |
| **Embree 3** | Ray tracing kernels | `embree_ROOT` |
| **doctest** | Testing framework | `doctest_ROOT` |
| **sentry** | Crash reporting | `sentry_ROOT` |
| **qtadvanceddocking** | Advanced docking system | `qtadvanceddocking_ROOT` |
| **OpenMesh** | Mesh processing | `OpenMesh_ROOT` |
| **pybind11** | C++ Python bindings | `pybind11_ROOT` |

#### Optional Dependencies

| Library | Purpose | CMake Option | Default |
|---------|---------|--------------|---------|
| **IGL (libigl)** | Geometry processing (USD >= 22.05) | Auto-detected | Required for USD 22.05+ |
| **Skia** | 2D graphics for canvas | `DCC_PACKAGE_OPENDCC_USD_EDITOR_CANVAS` | OFF |
| **Bullet3** | Physics simulation | `DCC_BUILD_BULLET_PHYSICS` | ON |
| **Arnold USD** | Arnold render delegate | `DCC_BUILD_ARNOLD_SUPPORT` | ON |
| **Cycles** | Cycles render delegate | `DCC_BUILD_CYCLES_SUPPORT` | OFF |
| **Renderman** | Renderman render delegate | `DCC_BUILD_RENDERMAN_SUPPORT` | OFF |
| **Graphviz** | Node graph visualization | `DCC_NODE_EDITOR` | ON |
| **PTex** | Per-face texturing | `DCC_USE_PTEX` | OFF |
| **Alembic** | For usdabc plugin | `DCC_INSTALL_ALEMBIC` | OFF |
| **OpenVDB** | Volume data | `DCC_INSTALL_OPENVDB` | OFF |

## Setting Up Dependencies

### Option 1: Using Pre-built VFX Platform Packages (RECOMMENDED)

The easiest way is to use pre-built packages that conform to the VFX Reference Platform:

1. Download VFX Platform packages for your target year from:
   - [VFX Reference Platform](https://vfxplatform.com/)
   - Your studio's internal build system
   - Community sources (if available)

2. Install all packages to a common root directory, e.g., `C:\VFX\Platform2023`

3. Set environment variables:
   ```cmd
   set USD_ROOT=C:\VFX\Platform2023\USD
   set Qt5_DIR=C:\VFX\Platform2023\Qt5\lib\cmake\Qt5
   set BOOST_ROOT=C:\VFX\Platform2023\boost
   set TBB_ROOT=C:\VFX\Platform2023\tbb
   :: ... and so on for each dependency
   ```

### Option 2: Building USD and Dependencies from Source

If you need to build from source, follow these general steps:

1. **Build Python 3.x** (or use official installer)
2. **Build or install Qt5** (can use official Qt installer)
3. **Build Boost** with Python support
4. **Build USD** with all its dependencies
   - Follow the [USD build documentation](https://github.com/PixarAnimationStudios/OpenUSD)
   - Use `build_scripts/build_usd.py` which builds many dependencies automatically
5. **Build remaining dependencies** (OCIO, OIIO, OSL, etc.)

This process is complex and time-consuming. Consider using a VFX platform distribution if available.

### Finding CMake Modules

OpenDCC includes custom CMake Find modules for all dependencies in `cmake/modules/`:
- `FindUSD.cmake` - Looks for `USD_ROOT` or `USD_CONFIG_FILE`
- `FindOpenColorIO.cmake` - Looks for `OpenColorIO_ROOT`
- `FindOpenImageIO.cmake` - Looks for `OpenImageIO_ROOT`
- And 27 more Find modules...

Each Find module typically checks these locations:
- CMake variable: `-D<PACKAGE>_ROOT=C:\path\to\package`
- Environment variable: `set <PACKAGE>_ROOT=C:\path\to\package`
- `CMAKE_PREFIX_PATH`: `-DCMAKE_PREFIX_PATH=C:\VFX\Platform2023`

## Build Configuration

### Basic Build (Minimal Features)

Create a file `build_windows_minimal.bat`:

```bat
@echo off
:: Set paths to your dependencies
set USD_ROOT=C:\VFX\USD
set Qt5_DIR=C:\VFX\Qt5\lib\cmake\Qt5
set BOOST_ROOT=C:\VFX\boost
set TBB_ROOT=C:\VFX\tbb
set GLEW_ROOT=C:\VFX\glew
set ZMQ_ROOT=C:\VFX\zeromq
set Eigen3_ROOT=C:\VFX\eigen3
set embree_ROOT=C:\VFX\embree3
set OpenColorIO_ROOT=C:\VFX\ocio
set OpenImageIO_ROOT=C:\VFX\oiio
set OpenEXR_ROOT=C:\VFX\openexr
set Imath_ROOT=C:\VFX\imath
set OpenSubdiv_ROOT=C:\VFX\opensubdiv
set OSL_ROOT=C:\VFX\osl
set OpenMesh_ROOT=C:\VFX\openmesh
set doctest_ROOT=C:\VFX\doctest
set sentry_ROOT=C:\VFX\sentry
set qtadvanceddocking_ROOT=C:\VFX\qtadvanceddocking
set pybind11_ROOT=C:\VFX\pybind11
set SHIBOKEN_CLANG_INSTALL_DIR=C:\VFX\shiboken2\clang

:: Create build directory
mkdir build
cd build

:: Configure with minimal features
cmake -G "Visual Studio 17 2022" -A x64 ^
  -DCMAKE_BUILD_TYPE=Release ^
  -DCMAKE_INSTALL_PREFIX=../install ^
  -DDCC_BUILD_ARNOLD_SUPPORT=OFF ^
  -DDCC_BUILD_CYCLES_SUPPORT=OFF ^
  -DDCC_BUILD_RENDERMAN_SUPPORT=OFF ^
  -DDCC_BUILD_BULLET_PHYSICS=OFF ^
  -DDCC_BUILD_TESTS=OFF ^
  -DDCC_BUILD_HYDRA_OP=OFF ^
  ..

:: Build
cmake --build . --config Release --parallel

:: Install
cmake --install . --config Release
```

### Full Build (All Features)

Create a file `build_windows_full.bat`:

```bat
@echo off
:: Set all dependency paths (same as above, plus optional ones)
set Arnold_ROOT=C:\VFX\arnold
set ArnoldUSD_ROOT=C:\VFX\arnold-usd
set Bullet3_ROOT=C:\VFX\bullet3
set Graphviz_ROOT=C:\VFX\graphviz

:: Create build directory
mkdir build
cd build

:: Configure with all features
cmake -G "Visual Studio 17 2022" -A x64 ^
  -DCMAKE_BUILD_TYPE=Release ^
  -DCMAKE_INSTALL_PREFIX=../install ^
  -DDCC_BUILD_ARNOLD_SUPPORT=ON ^
  -DDCC_BUILD_CYCLES_SUPPORT=OFF ^
  -DDCC_BUILD_RENDERMAN_SUPPORT=OFF ^
  -DDCC_BUILD_BULLET_PHYSICS=ON ^
  -DDCC_BUILD_TESTS=ON ^
  -DDCC_BUILD_HYDRA_OP=ON ^
  -DDCC_NODE_EDITOR=ON ^
  ..

:: Build
cmake --build . --config Release --parallel

:: Install
cmake --install . --config Release
```

### Using Ninja for Faster Builds

For faster builds, use Ninja with sccache:

```bat
:: Install Ninja and sccache first
:: pip install ninja
:: Download sccache from https://github.com/mozilla/sccache

cmake -G "Ninja" ^
  -DCMAKE_BUILD_TYPE=Release ^
  -DCMAKE_INSTALL_PREFIX=../install ^
  -DWITH_WINDOWS_SCCACHE=ON ^
  :: ... other options ...
  ..

cmake --build .
cmake --install .
```

## Build Options Reference

### Essential Options

```cmake
-DCMAKE_BUILD_TYPE=<Release|Debug|RelWithDebInfo|Hybrid>  # Build configuration
-DCMAKE_INSTALL_PREFIX=<path>                              # Installation directory
-DCMAKE_PREFIX_PATH=<paths>                                # Semicolon-separated dependency paths
```

### Feature Toggles

```cmake
# Animation
-DDCC_BUILD_ANIM_ENGINE=<ON|OFF>           # Animation engine (default: ON)
-DDCC_BUILD_EXPRESSIONS_ENGINE=<ON|OFF>    # Expression system (default: ON)

# Rendering
-DDCC_BUILD_RENDER_VIEW=<ON|OFF>           # Standalone render viewer (default: ON)
-DDCC_BUILD_ARNOLD_SUPPORT=<ON|OFF>        # Arnold render delegate (default: ON)
-DDCC_BUILD_CYCLES_SUPPORT=<ON|OFF>        # Cycles render delegate (default: OFF)
-DDCC_BUILD_RENDERMAN_SUPPORT=<ON|OFF>     # Renderman support (default: OFF)

# Tools
-DDCC_NODE_EDITOR=<ON|OFF>                 # Node editor framework (default: ON)
-DDCC_BUILD_BULLET_PHYSICS=<ON|OFF>        # Bullet physics (default: ON)
-DDCC_BUILD_HYDRA_OP=<ON|OFF>              # HydraOps system (default: OFF)

# Development
-DDCC_BUILD_TESTS=<ON|OFF>                 # Build tests (default: OFF)
-DDCC_DEBUG_BUILD=<ON|OFF>                 # Debug mode (default: OFF)
-DDCC_VERBOSE_SHIBOKEN_OUTPUT=<ON|OFF>     # Verbose Shiboken output (default: OFF)

# Integration
-DDCC_HOUDINI_SUPPORT=<ON|OFF>             # Houdini integration (default: OFF)
-DDCC_KATANA_SUPPORT=<ON|OFF>              # Katana integration (default: OFF)

# Python
-DDCC_USE_PYTHON_3=<ON|OFF>                # Use Python 3 (default: ON)
-DDCC_EMBEDDED_PYTHON_HOME=<ON|OFF>        # Embed Python home (default: ON)

# Packages (all default: ON unless noted)
-DDCC_PACKAGE_OPENDCC_USD_EDITOR_UV_EDITOR=<ON|OFF>
-DDCC_PACKAGE_OPENDCC_USD_EDITOR_PAINT_PRIMVAR_TOOL=<ON|OFF>
-DDCC_PACKAGE_OPENDCC_USD_EDITOR_SCULPT_TOOL=<ON|OFF>
-DDCC_PACKAGE_OPENDCC_USD_EDITOR_POINT_INSTANCER_TOOL=<ON|OFF>
-DDCC_PACKAGE_OPENDCC_USD_EDITOR_TEXTURE_PAINT_TOOL=<ON|OFF>
-DDCC_PACKAGE_OPENDCC_USD_EDITOR_BEZIER_TOOL=<ON|OFF>
-DDCC_PACKAGE_OPENDCC_USD_EDITOR_LIGHT_OUTLINER=<ON|OFF>
-DDCC_PACKAGE_OPENDCC_USD_EDITOR_LIGHT_LINKING_EDITOR=<ON|OFF>
-DDCC_PACKAGE_OPENDCC_USD_EDITOR_LIVE_SHARE=<ON|OFF>
```

### Dependency Installation Options

These control whether to install dependencies alongside OpenDCC:

```cmake
-DDCC_INSTALL_QT5=<ON|OFF>                 # Install Qt5 (default: OFF)
-DDCC_INSTALL_PYTHON=<ON|OFF>              # Install Python (default: OFF)
-DDCC_INSTALL_PYSIDE2=<ON|OFF>             # Install PySide2 (default: OFF)
-DDCC_INSTALL_USD=<ON|OFF>                 # Install USD (default: OFF)
-DDCC_INSTALL_BOOST=<ON|OFF>               # Install Boost (default: OFF)
-DDCC_INSTALL_TBB=<ON|OFF>                 # Install TBB (default: OFF)
-DDCC_INSTALL_OCIO=<ON|OFF>                # Install OCIO (default: OFF)
-DDCC_INSTALL_OIIO=<ON|OFF>                # Install OIIO (default: OFF)
-DDCC_INSTALL_SENTRY=<ON|OFF>              # Install Sentry (default: ON)
-DDCC_INSTALL_ADS=<ON|OFF>                 # Install Advanced Docking System (default: ON)
```

## Running the Build

### Step 1: Configure

```cmd
cd C:\GitHub\OpenDCC
mkdir build
cd build

:: Run CMake configure (adjust paths and options as needed)
cmake -G "Visual Studio 17 2022" -A x64 -DCMAKE_PREFIX_PATH=C:\VFX\Platform2023 ..
```

CMake will output which dependencies it found and which are missing. Address any `NOT FOUND` errors by setting the appropriate CMake variables or environment variables.

### Step 2: Build

```cmd
:: Build all configurations
cmake --build . --config Release --parallel

:: Or build specific configuration
cmake --build . --config Debug --parallel
cmake --build . --config RelWithDebInfo --parallel
cmake --build . --config Hybrid --parallel
```

The `--parallel` flag enables multi-core compilation for faster builds.

### Step 3: Install

```cmd
cmake --install . --config Release
```

This installs to the prefix specified by `CMAKE_INSTALL_PREFIX` (default: `install/` subdirectory).

## Running OpenDCC

After building and installing:

```cmd
cd C:\GitHub\OpenDCC\install

:: Run main application
bin\dcc_base.exe

:: Run with Python shell
bin\dcc_base.exe --shell

:: Run a Python script
bin\dcc_base.exe --script path\to\script.py

:: Run tests (if built with -DDCC_BUILD_TESTS=ON)
bin\dcc_base.exe --with-tests
```

### Setting Up Runtime Environment

On Windows, the application needs to find all DLLs. Ensure your PATH includes:

```cmd
set PATH=%PATH%;C:\VFX\USD\lib
set PATH=%PATH%;C:\VFX\Qt5\bin
set PATH=%PATH%;C:\VFX\boost\lib
set PATH=%PATH%;C:\VFX\tbb\bin
:: ... all dependency lib/bin directories ...
```

Or install dependencies using the `DCC_INSTALL_*` options to have them copied alongside the application.

## Troubleshooting

### CMake Can't Find Dependencies

**Problem:** `Could not find <Package>`

**Solution:**
1. Set the package root: `-D<Package>_ROOT=C:\path\to\package`
2. Or add to `CMAKE_PREFIX_PATH`: `-DCMAKE_PREFIX_PATH="C:\path1;C:\path2;C:\path3"`
3. Or set environment variable: `set <Package>_ROOT=C:\path\to\package`

### Boost.Python Version Mismatch

**Problem:** CMake can't find `Boost::python39` or similar

**Solution:**
- Ensure Boost was built with Python support for your Python version
- CMake looks for `python${PYTHON_VERSION_MAJOR}${PYTHON_VERSION_MINOR}` component
- For Python 3.9, you need `libboost_python39` or `boost_python39`

### Shiboken CLANG_INSTALL_DIR Not Found

**Problem:** `SHIBOKEN_CLANG_INSTALL_DIR not found`

**Solution:**
- This is REQUIRED for PySide2 bindings
- Usually located in `<PySide2_ROOT>/clang` or similar
- Set explicitly: `-DSHIBOKEN_CLANG_INSTALL_DIR=C:\path\to\shiboken2\clang`

### OpenEXR DLL Issues

**Problem:** OpenEXR linking errors on MSVC

**Solution:**
- The build automatically adds `-DOPENEXR_DLL` definition for MSVC
- Ensure your OpenEXR was built as shared libraries (DLLs)

### USD Version Compatibility

**Problem:** Build errors related to USD version

**Solution:**
- OpenDCC supports USD 21.08 and later
- Some features require USD 22.05+ (texture painting, IGL integration)
- Check USD version compatibility in the error messages
- Option `DCC_USE_HYDRA_FRAMING_API` may need to be OFF for older USD versions

### Missing Python Modules at Runtime

**Problem:** Application starts but crashes with Python import errors

**Solution:**
1. Ensure `PYTHONPATH` includes OpenDCC's Python modules
2. The installed `opendcc_setup.sh` (Linux) sets up environment - Windows needs equivalent
3. Python site-packages should be in `install/python/lib/site-packages` on Windows

### Qt Plugin Errors

**Problem:** Qt platform plugin errors on startup

**Solution:**
- Ensure Qt plugins are in `qt-plugins/` directory relative to executable
- Or set `QT_PLUGIN_PATH` environment variable
- Use `-DDCC_INSTALL_QT5=ON` to install Qt plugins automatically

## Next Steps

After successfully building:

1. Read [CLAUDE.md](CLAUDE.md) for architecture overview
2. Explore the [src/packages](src/packages) directory for available plugins
3. Check [configs/opendcc.usd_editor.toml.in](configs/opendcc.usd_editor.toml.in) for configuration options
4. Run with `--shell` to experiment with the Python API

## Additional Resources

- [OpenUSD Documentation](https://openusd.org/)
- [VFX Reference Platform](https://vfxplatform.com/)
- [Qt Documentation](https://doc.qt.io/)
- [OpenDCC README](README.md)

## Contributing Build Improvements

If you successfully build OpenDCC on Windows, consider contributing:
- Detailed dependency build instructions
- Pre-built dependency packages
- Build automation scripts
- CI/CD configurations
- Updates to this guide

This is a work-in-progress project, and build documentation improvements are highly valued!
