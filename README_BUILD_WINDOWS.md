# Building OpenDCC on Windows - Documentation Overview

This repository now includes comprehensive Windows build documentation. Choose your starting point based on your experience level:

## 🚀 Quick Start (Recommended)

**New to building C++ projects?** Start here:

### [QUICKSTART_WINDOWS.md](QUICKSTART_WINDOWS.md)
- TL;DR instructions to get building fast
- Prerequisites installation guide
- Automated build scripts
- Expected timelines
- **Start here if this is your first time!**

## 📋 Build Progress Tracking

### [BUILD_CHECKLIST.md](BUILD_CHECKLIST.md)
- Interactive checklist for tracking build progress
- Phase-by-phase completion tracking
- Notes section for issues encountered
- Environment summary for future reference
- **Print this or keep it open while building!**

## 📖 Detailed Guides

### [WINDOWS_BUILD_GUIDE.md](WINDOWS_BUILD_GUIDE.md)
- Complete step-by-step tutorial (5 phases)
- Detailed explanations of each step
- Copy-paste ready commands
- Troubleshooting for common issues
- **Use this for the full walkthrough**

### [BUILDING_WINDOWS.md](BUILDING_WINDOWS.md)
- Technical reference documentation
- All CMake options explained
- Complete dependency list with purpose
- Advanced configuration options
- **Reference this for specific details**

## 🤖 For Claude Code

### [CLAUDE.md](CLAUDE.md)
- High-level architecture overview
- Build system explanation
- Development patterns
- Code structure
- **For AI assistants and new developers**

## 🛠️ Build Scripts

Located in `build_scripts/` directory:

### [build_usd_for_opendcc.bat](build_scripts/build_usd_for_opendcc.bat)
- **Batch script** for building USD automatically
- Use from: "x64 Native Tools Command Prompt for VS 2022"
- Builds USD + ~40-50% of OpenDCC dependencies
- Takes 1-4 hours

### [build_usd_for_opendcc.ps1](build_scripts/build_usd_for_opendcc.ps1)
- **PowerShell script** for building USD automatically
- Use from: "Developer PowerShell for VS 2022"
- Better error handling and progress display
- Same functionality as .bat version

---

## Recommended Build Path

### Phase 0: Prepare (30 mins)
1. Read [QUICKSTART_WINDOWS.md](QUICKSTART_WINDOWS.md) prerequisites section
2. Install Visual Studio 2022, Python 3.10, CMake, NASM
3. Print or open [BUILD_CHECKLIST.md](BUILD_CHECKLIST.md)

### Phase 1: Build USD (1-4 hours, automated)
1. Run `build_scripts\build_usd_for_opendcc.bat`
2. Wait for completion (check off items in checklist)
3. Verify USD works

### Phase 2: Qt & PySide (30-60 mins)
1. Install Qt 5.15.x from official installer
2. Install PySide2: `pip install PySide2`
3. Set environment variables

### Phase 3: Remaining Dependencies (2-4 hours)
1. Use vcpkg (recommended) or manual builds
2. Build: ZMQ, Eigen3, OpenMesh, doctest, sentry, qtadvanceddocking, OSL
3. Follow [WINDOWS_BUILD_GUIDE.md](WINDOWS_BUILD_GUIDE.md) Phase 3

### Phase 4: Build OpenDCC (1-2 hours)
1. Set up environment script
2. Run CMake configure
3. Build with Visual Studio
4. Install

### Phase 5: Run & Test (30 mins)
1. Launch OpenDCC
2. Test functionality
3. Celebrate! 🎉

---

## Time Estimates

| Experience Level | Total Time | Notes |
|-----------------|------------|-------|
| **Beginner** | 2-3 days | First-time builds, learning as you go |
| **Intermediate** | 1-2 days | Some build experience, familiar with CMake |
| **Advanced** | 6-12 hours | Experienced with VFX platform builds |
| **Expert** | 4-8 hours | Everything goes smoothly first try |

**Note:** Most time is waiting for builds - actual hands-on time is much less!

---

## What Gets Built

### Phase 1 (Automated by build_usd.py)
✅ USD Core
✅ Boost + Boost.Python
✅ TBB / OneTBB
✅ OpenEXR + Imath
✅ OpenSubdiv
✅ OpenImageIO
✅ OpenColorIO
✅ GLEW
✅ Embree
✅ Alembic
✅ MaterialX
✅ Image format libraries (JPEG, PNG, TIFF)

**Result:** ~40-50% of OpenDCC dependencies complete!

### Phase 2 (Manual Install)
⚠️ Qt5 5.15.x
⚠️ PySide2 + Shiboken2

### Phase 3 (Manual Build or vcpkg)
⚠️ ZMQ
⚠️ Eigen3
⚠️ OpenMesh
⚠️ doctest
⚠️ sentry
⚠️ qtadvanceddocking
⚠️ OSL (complex, consider skipping if issues)

### Optional (Phase 3)
⭕ IGL (libigl) - for USD 22.05+
⭕ Skia - for canvas features
⭕ Graphviz - for node editor
⭕ Bullet3 - for physics
⭕ Arnold - render delegate
⭕ Cycles - render delegate
⭕ Renderman - render delegate

---

## Troubleshooting

### Quick Fixes

**"Visual Studio environment not found"**
- Use "x64 Native Tools Command Prompt for VS 2022" not regular cmd

**"Python not found"**
- Reinstall with "Add to PATH" checked
- Restart terminal

**"Out of disk space"**
- Need ~30 GB free during build
- Final install is ~10 GB

**"Missing DLLs at runtime"**
- Run environment setup script first
- Add dependency bin/ dirs to PATH

### Detailed Troubleshooting

See each guide for specific troubleshooting:
- [QUICKSTART_WINDOWS.md](QUICKSTART_WINDOWS.md#troubleshooting-phase-1)
- [WINDOWS_BUILD_GUIDE.md](WINDOWS_BUILD_GUIDE.md#troubleshooting)

---

## After Building

Once OpenDCC is built successfully:

1. **Learn the Architecture**
   - Read [CLAUDE.md](CLAUDE.md)
   - Explore `src/packages/` for plugin examples
   - Review `configs/opendcc.usd_editor.toml.in`

2. **Start Developing**
   - Try the Python shell: `dcc_base.exe --shell`
   - Create a simple plugin
   - Experiment with USD stages

3. **Contribute**
   - Report build issues
   - Improve documentation
   - Share your experience

---

## Document Quick Reference

| When you need... | Read this... |
|-----------------|--------------|
| To just get started building | [QUICKSTART_WINDOWS.md](QUICKSTART_WINDOWS.md) |
| To track your progress | [BUILD_CHECKLIST.md](BUILD_CHECKLIST.md) |
| Step-by-step instructions | [WINDOWS_BUILD_GUIDE.md](WINDOWS_BUILD_GUIDE.md) |
| Technical details / CMake options | [BUILDING_WINDOWS.md](BUILDING_WINDOWS.md) |
| Architecture / development info | [CLAUDE.md](CLAUDE.md) |
| Project overview | [README.md](README.md) |

---

## Getting Help

1. Check the troubleshooting sections in the guides
2. Review [USD build documentation](https://github.com/PixarAnimationStudios/OpenUSD/blob/release/BUILDING.md)
3. Search [OpenDCC GitHub issues](https://github.com/OpenDCC/OpenDCC/issues)
4. Open a new issue with:
   - Your build log
   - Which phase you're on
   - Error messages
   - System info (Windows version, VS version, Python version)

---

## Success Stories

**Built OpenDCC successfully on Windows?**

Please consider:
- Opening a PR with any documentation improvements
- Sharing your build time and system specs
- Reporting any issues you encountered and how you fixed them
- Creating pre-built dependency packages for the community

Your contribution helps everyone! 🙏

---

## License

OpenDCC is licensed under Apache 2.0. See [LICENSE.txt](LICENSE.txt).

Build documentation created to help the community build OpenDCC on Windows.

---

**Ready to build?** Start with [QUICKSTART_WINDOWS.md](QUICKSTART_WINDOWS.md)! 🚀
