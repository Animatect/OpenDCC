# OpenDCC Windows Quick Start Guide

The fastest way to get started building OpenDCC on Windows.

## TL;DR - Just Want to Build?

1. **Prerequisites** (30 mins)
   - Install Visual Studio 2022, Python 3.10, CMake, NASM

2. **Run Phase 1 Script** (1-4 hours, automated)
   ```cmd
   cd C:\GitHub\OpenDCC\build_scripts
   build_usd_for_opendcc.bat
   ```

3. **Install Qt5** (30 mins)
   - Download and install Qt 5.15.x from https://www.qt.io/

4. **Install PySide2** (5 mins)
   ```cmd
   pip install PySide2
   ```

5. **Build remaining deps** (2-4 hours)
   - See [WINDOWS_BUILD_GUIDE.md](WINDOWS_BUILD_GUIDE.md) Phase 3

6. **Build OpenDCC** (1-2 hours)
   - See [WINDOWS_BUILD_GUIDE.md](WINDOWS_BUILD_GUIDE.md) Phase 4

**Total time:** 1-2 days for first build

---

## Prerequisites Installation

### 1. Visual Studio 2022 Community (Free)

1. Download: https://visualstudio.microsoft.com/downloads/
2. Install with "Desktop development with C++" workload
3. Reboot if prompted

### 2. Python 3.10 (64-bit)

1. Download: https://www.python.org/downloads/release/python-31011/
2. Install "Windows installer (64-bit)"
3. ✅ **Check "Add Python to PATH"** during installation
4. Verify:
   ```cmd
   python --version
   # Should show: Python 3.10.x
   ```

### 3. CMake

```cmd
pip install cmake
```

Or download installer from https://cmake.org/download/

### 4. NASM (Assembler for image libraries)

1. Download: https://www.nasm.us/pub/nasm/releasebuilds/2.16.01/win64/nasm-2.16.01-win64.zip
2. Extract to `C:\nasm`
3. Add to PATH:
   - Search "Environment Variables" in Windows
   - Edit "Path" → Add `C:\nasm`
4. Verify:
   ```cmd
   nasm -v
   # Should show version
   ```

### 5. Git (if not already installed)

Download: https://git-scm.com/download/win

---

## Build Scripts

We've provided automated scripts for Phase 1 (building USD):

### Option A: Batch Script (Recommended for beginners)

```cmd
:: Open "x64 Native Tools Command Prompt for VS 2022"
:: (Search in Start Menu)

cd C:\GitHub\OpenDCC\build_scripts
build_usd_for_opendcc.bat
```

### Option B: PowerShell Script (Better error handling)

```powershell
# Open "Developer PowerShell for VS 2022"
# (Search in Start Menu)

cd C:\GitHub\OpenDCC\build_scripts
.\build_usd_for_opendcc.ps1

# Or from regular PowerShell:
.\build_usd_for_opendcc.ps1 -AutoLoadVS
```

### What These Scripts Do

✅ Check all prerequisites
✅ Clone USD repository to `C:\VFX\OpenUSD`
✅ Build USD with all OpenDCC-required dependencies:
   - USD, Boost, TBB, OpenEXR, Imath, OpenSubdiv
   - OpenImageIO, OpenColorIO, GLEW, Embree, Alembic, MaterialX
✅ Install to `C:\VFX\USD_install`
✅ Verify the build works
✅ Create environment setup scripts

**Time:** 1-4 hours depending on your CPU

---

## After USD Builds Successfully

### Quick Test

```cmd
:: Run the environment setup
C:\VFX\USD_install\usd_env.bat

:: Test USD
python -c "from pxr import Usd; print('USD version:', Usd.GetVersion())"

:: Test usdcat tool
usdcat --version
```

If these work, you're ✅ **40-50% done** with dependencies!

---

## Next Steps

Continue with the detailed guide:

1. **Phase 2:** [Install Qt5 and PySide2](WINDOWS_BUILD_GUIDE.md#phase-2-install-qt5-and-pyside2)
2. **Phase 3:** [Build remaining dependencies](WINDOWS_BUILD_GUIDE.md#phase-3-build-remaining-dependencies)
3. **Phase 4:** [Build OpenDCC](WINDOWS_BUILD_GUIDE.md#phase-4-build-opendcc)
4. **Phase 5:** [Run OpenDCC](WINDOWS_BUILD_GUIDE.md#phase-5-run-opendcc)

---

## Script Customization

### Change Install Location

Edit the script or pass parameter:

**Batch:**
```bat
:: Edit build_usd_for_opendcc.bat line 52:
set "VFX_ROOT=D:\MyVFX"
```

**PowerShell:**
```powershell
.\build_usd_for_opendcc.ps1 -VfxRoot "D:\MyVFX"
```

### Minimal Build (Faster, fewer features)

If you want to build faster by skipping optional components, edit the script and remove these flags:
- `--openimageio`
- `--opencolorio`
- `--alembic`
- `--embree`

⚠️ **Warning:** OpenDCC requires these, so you'll need to build them separately later.

### Debug Build

**Batch:**
```bat
:: Edit line 53:
set "BUILD_TYPE=relwithdebuginfo"
```

**PowerShell:**
```powershell
.\build_usd_for_opendcc.ps1 -BuildType relwithdebuginfo
```

---

## Troubleshooting Phase 1

### "Not running in Visual Studio environment"

**Problem:** Script says Visual Studio tools not found

**Solution:**
1. Don't use regular Command Prompt or PowerShell
2. Use "x64 Native Tools Command Prompt for VS 2022" (for batch script)
3. Or "Developer PowerShell for VS 2022" (for PowerShell script)
4. Find in Start Menu under "Visual Studio 2022"

### "Python not found"

**Problem:** `python --version` doesn't work

**Solution:**
1. Reinstall Python with "Add to PATH" checked
2. Or manually add Python to PATH
3. Restart your terminal after adding to PATH

### "NASM not found"

**Problem:** Warning about NASM missing

**Solution:**
- You can continue without NASM (press Y)
- Some image formats might not build
- Better to install NASM: download from https://www.nasm.us/

### Build fails with "out of space"

**Problem:** Disk full during build

**Solution:**
- USD build needs ~30 GB free space
- After build, only ~10 GB is used
- Choose a drive with more space (edit VFX_ROOT in script)

### Build fails with compilation errors

**Problem:** C++ compilation errors during build

**Solutions:**
1. Ensure you're using Visual Studio 2019 or 2022 (not older)
2. Try building without optional components first
3. Check the error log for specific missing headers
4. Search the error on GitHub: https://github.com/PixarAnimationStudios/OpenUSD/issues

### Python import fails after build

**Problem:** `from pxr import Usd` fails

**Solutions:**
1. Ensure you ran `usd_env.bat` first
2. Check PYTHONPATH is set correctly:
   ```cmd
   echo %PYTHONPATH%
   :: Should include: C:\VFX\USD_install\lib\python
   ```
3. Use the same Python version for testing as you used for building

---

## Need More Details?

- **Full Guide:** [WINDOWS_BUILD_GUIDE.md](WINDOWS_BUILD_GUIDE.md) - Complete step-by-step tutorial
- **Technical Reference:** [BUILDING_WINDOWS.md](BUILDING_WINDOWS.md) - All CMake options and details
- **Architecture:** [CLAUDE.md](CLAUDE.md) - OpenDCC architecture overview

---

## Getting Help

If you're stuck:

1. Check the detailed guides above
2. Review USD build docs: https://github.com/PixarAnimationStudios/OpenUSD/blob/release/BUILDING.md
3. Open an issue with your error log
4. Join the OpenDCC community (when available)

---

## Estimated Timeline

Here's what to expect for a first-time build:

| Phase | Task | Time |
|-------|------|------|
| 0 | Install prerequisites | 30 mins - 1 hour |
| 1 | Build USD (automated) | 1-4 hours |
| 2 | Install Qt5 + PySide2 | 30 mins - 1 hour |
| 3 | Build remaining deps | 2-4 hours |
| 4 | Build OpenDCC | 30 mins - 2 hours |
| 5 | Test and verify | 30 mins |
| **Total** | **First build** | **6-14 hours** |

**Note:** Most of this is automated - you just need to start the scripts and wait!

**Subsequent builds:** Much faster (5-30 mins) since you only rebuild what changed.

---

## Success Criteria

After Phase 1 completes successfully, you should have:

✅ USD installed at `C:\VFX\USD_install`
✅ `usdcat --version` works
✅ `python -c "from pxr import Usd"` works
✅ Environment scripts created
✅ ~40-50% of OpenDCC dependencies satisfied

Ready to continue with Phase 2! 🎉
