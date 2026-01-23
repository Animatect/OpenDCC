# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**OpenDCC** is an Apache 2.0 licensed, open-source Digital Content Creation (DCC) application framework for building modular, production-grade 3D tools. It combines a plugin-driven architecture with an industry-standard Qt-based interface, embedded Python scripting, OpenUSD, and Hydra integration.

**Core Philosophy:**
- Provide an artist-friendly, industry-standard frontend (familiar UI/UX)
- Give developers full control over the backend (scene systems, computation, rendering)
- Minimize patches to OpenUSD itself to allow studios to easily swap in their own USD forks
- Conform to the VFX Reference Platform for industry compatibility

**Current Version:** 0.4.0.0

## Build System

### Building the Project

OpenDCC uses CMake (minimum version 3.18) with extensive modularization.

**Windows Build Options:**
1. **Build with Houdini** (Recommended - fastest): Use `build_scripts/build_opendcc_houdini.bat`
2. **Build USD from source**: Use `build_scripts/build_usd_for_opendcc.bat` first
3. See [WINDOWS_BUILD_GUIDE.md](WINDOWS_BUILD_GUIDE.md) for detailed instructions

```bash
# Standard CMake build
mkdir build
cd build
cmake ..
cmake --build .

# Windows (Visual Studio)
cmake -G "Visual Studio 17 2022" ..
cmake --build . --config Release

# With specific options
cmake -DDCC_BUILD_TESTS=ON -DDCC_BUILD_ARNOLD_SUPPORT=OFF ..

# Windows with Houdini USD (fastest approach)
cmake -G "Visual Studio 17 2022" -DDCC_HOUDINI_SUPPORT=ON -DHOUDINI_ROOT="C:\Program Files\Side Effects Software\Houdini 20.5.xxx" ..
```

### Important Build Options

Located in [cmake/defaults/Options.cmake](cmake/defaults/Options.cmake):

- `DCC_BUILD_TESTS` - Enable testing framework (default: OFF)
- `DCC_BUILD_ANIM_ENGINE` - Build animation engine (default: ON)
- `DCC_BUILD_RENDER_VIEW` - Build standalone render viewer (default: ON)
- `DCC_BUILD_ARNOLD_SUPPORT` - Enable Arnold render delegate (default: ON)
- `DCC_BUILD_CYCLES_SUPPORT` - Enable Cycles render delegate (default: OFF)
- `DCC_BUILD_RENDERMAN_SUPPORT` - Enable Renderman support (default: OFF)
- `DCC_BUILD_BULLET_PHYSICS` - Enable Bullet physics (default: ON)
- `DCC_NODE_EDITOR` - Build node editor framework (default: ON)
- `DCC_BUILD_HYDRA_OP` - Build HydraOps system (default: OFF)
- `DCC_HOUDINI_SUPPORT` - Houdini integration (default: OFF)
- `DCC_KATANA_SUPPORT` - Katana integration (default: OFF)

### Build Configurations

- **Release** - Optimized production build
- **Debug** - Debug symbols, no optimization
- **RelWithDebInfo** - Optimized with debug info
- **Hybrid** - Special configuration with RelWithDebInfo symbols but no optimization (`/Od /Ob0`)

### Running the Application

```bash
# Run main application (from build directory)
bin/dcc_base

# Run with Python shell
bin/dcc_base --shell

# Run Python script
bin/dcc_base --script path/to/script.py

# Run tests
bin/dcc_base --with-tests
```

### Testing

Tests use the doctest framework. Enable with `-DDCC_BUILD_TESTS=ON`.

```bash
# Run all tests
bin/dcc_base --with-tests

# Example test location
src/packages/opendcc.anim_engine.core/lib/opendcc/anim_engine/core/anim_engine_tests.cpp
```

Test macros:
- `DOCTEST_TEST_SUITE("SuiteName")` - Define test suite
- `DOCTEST_TEST_CASE("test_name")` - Define test case
- `DOCTEST_REQUIRE(expression)` - Assert requirement

## Architecture

### High-Level Structure

```
src/
├── bin/                    # Executable applications
│   ├── dcc_base/          # Main application (GUI/shell/script modes)
│   ├── crash_reporter/    # Crash reporting tool
│   ├── render_view/       # Standalone render viewer
│   ├── usd_ipc_broker/    # USD IPC synchronization
│   └── usd_render/        # CLI rendering tool
├── lib/                   # Core libraries
│   ├── opendcc/           # Main OpenDCC libraries
│   └── usd/               # USD-specific extensions
├── packages/              # Plugin packages (33+ packages)
└── python/                # Python bindings and utilities
```

### Core Application Flow

1. **Entry Point:** [src/bin/dcc_base/main.cpp](src/bin/dcc_base/main.cpp)
2. **Configuration:** Loads TOML config from `configs/opendcc.usd_editor.toml.in`
3. **Python Initialization:** Calls `opendcc.startup.init()` and `opendcc.startup.init_ui()`
4. **Session Management:** `Application` singleton manages sessions, undo/redo, selection
5. **Plugin Loading:** Packages are loaded based on `package.toml` manifests

### Plugin Package System

All plugins use TOML manifest files (`package.toml`) with this structure:

```toml
[base]
name = 'package.name'

[[environment.PYTHONPATH]]
value = 'python'

[[python.entry_point]]
module = 'package.name'

[[native.entry_point]]
path='lib/${LIB_PREFIX}package.name${LIB_EXT}'
```

**Available Packages:**
- Animation: `opendcc.anim_engine`, `opendcc.anim_engine.curve`, `opendcc.anim_engine.ui.graph_editor`
- USD Editors: `opendcc.usd_editor.bezier_tool`, `opendcc.usd_editor.sculpt_tool`, `opendcc.usd_editor.uv_editor`, `opendcc.usd_editor.material_editor`
- HydraOps: `opendcc.hydra_op`, `opendcc.hydra_op.ui.node_editor`, `opendcc.hydra_op.ui.scene_graph`
- UI: `opendcc.ui.node_editor`, `opendcc.ui.script_editor`, `opendcc.ui.code_editor`

### Command System Architecture

OpenDCC uses a command pattern for undo/redo and Python recording.

**Base Classes** ([src/lib/opendcc/base/commands_api/core/command.h](src/lib/opendcc/base/commands_api/core/command.h)):

```cpp
class Command {
    virtual CommandResult execute(const CommandArgs& args) = 0;
};

class UndoCommand : virtual public Command {
    virtual void undo();
    virtual void redo();
    virtual bool merge_with(UndoCommand* command);
};

class ToolCommand : virtual public Command {
    virtual CommandArgs make_args() const = 0;
};
```

**CommandResult Status:**
- `SUCCESS` - Command executed successfully
- `FAIL` - Command failed
- `INVALID_SYNTAX` - Syntax error in arguments
- `INVALID_ARG` - Invalid argument value
- `CMD_NOT_REGISTERED` - Command not found in registry

**Implementation Pattern:**
1. Inherit from `Command` or `UndoCommand`
2. Implement `execute()` method
3. For undo support, implement `undo()` and `redo()`
4. Register command with `CommandRegistry`
5. Commands are automatically available in Python

### USD Integration

OpenDCC is tightly integrated with OpenUSD and Hydra:

- **Scene Description:** Uses USD stages, layers, and composition
- **Rendering:** Hydra-based viewport with multiple render delegate support (Arnold, Cycles, Renderman, Storm)
- **Selection:** Hydra-based selection for points, edges, faces, instances
- **IPC:** USD Delta IPC syncing for live collaboration ([src/lib/opendcc/usd/usd_ipc_serialization](src/lib/opendcc/usd/usd_ipc_serialization))
- **Watchers:** `stage_watcher.h` and `layer_tree_watcher` monitor USD changes

**Key USD Components:**
- [src/lib/opendcc/app/core/session.h](src/lib/opendcc/app/core/session.h) - USD stage management
- [src/lib/opendcc/usd/compositing](src/lib/opendcc/usd/compositing) - USD composition utilities
- [src/lib/opendcc/usd/hydra_render_session_api](src/lib/opendcc/usd/hydra_render_session_api) - Hydra rendering sessions

### Python Integration

**Dual Binding System:**
- **Pybind11:** C++ to Python bindings
- **Shiboken:** Qt/PySide integration

**Python Startup** ([src/python/opendcc/startup.py](src/python/opendcc/startup.py)):
- `init()` - Core initialization, loads user hooks
- `init_ui()` - UI initialization, creates menus, panels, actions

**Key Python Modules:**
- `opendcc.core` - Core application API
- `opendcc.actions` - UI actions
- `opendcc.plugin_manager` - Plugin management
- `opendcc.stage_utils` - USD stage utilities

### Viewport System

Located in [src/lib/opendcc/app/viewport](src/lib/opendcc/app/viewport):

- OpenGL-based viewport widget
- Hydra integration for rendering
- Camera controls and manipulation
- Extensible viewport tools system
- Industry-standard manipulators using `pxr.Gf` mathematics

### Configuration System

TOML-based configuration in [configs/opendcc.usd_editor.toml.in](configs/opendcc.usd_editor.toml.in):

```toml
[settings.app]
type = "usd_editor"
version = "@OPENDCC_VERSION_STRING@"

[settings.ui]
color_theme = "dark"  # or "light"
language = "en"

[python]
init = "import opendcc.startup;opendcc.startup.init()"
init_ui = "import opendcc.startup;opendcc.startup.init_ui()"

[render]
active_control = "usd"

[ipc.command_server]
port = 8000
server_timeout = 1000  # ms
```

## Key Libraries and Dependencies

**Major Dependencies:**
- **USD (Pixar)** - Scene description and Hydra rendering (core, non-optional)
- **Qt5** - GUI framework
- **PySide2/Shiboken2** - Python-Qt bindings
- **OpenGL/GLEW** - Graphics
- **TBB** - Threading
- **Python 3** - Scripting
- **pybind11** - C++ Python bindings
- **OpenColorIO (OCIO)** - Color management
- **OpenImageIO (OIIO)** - Image I/O
- **OpenEXR/Imath** - Image format and math
- **OpenSubdiv** - Subdivision surfaces
- **ZMQ** - Messaging for IPC
- **doctest** - Testing framework
- **sentry** - Crash reporting
- **qtadvanceddocking** - Advanced docking system

**Render Delegates (optional):**
- Arnold USD
- Cycles
- Renderman
- Moonray

## Development Patterns

### Creating a New Command

```cpp
// In your package's C++ code
class MyCommand : public UndoCommand {
public:
    CommandResult execute(const CommandArgs& args) override {
        // Execute logic
        return CommandResult(CommandResult::Status::SUCCESS);
    }

    void undo() override {
        // Undo logic
    }

    void redo() override {
        // Redo logic
    }
};

// Register in your plugin initialization
CommandRegistry::instance().register_command<MyCommand>("myCommand");
```

### Creating a New Package

1. Create directory in `src/packages/your.package.name/`
2. Add `package.toml` manifest
3. Create CMakeLists.txt
4. Implement C++ code in `lib/` subdirectory
5. Add Python bindings in `python/` subdirectory
6. Optional: Add UI in separate UI package

### Working with USD Stages

```python
import opendcc.core as dcc_core

app = dcc_core.Application.instance()
session = app.get_session()
stage = session.get_stage()

# Work with stage
prim = stage.GetPrimAtPath('/path/to/prim')
```

### Adding UI Panels

Panels are registered via `PanelFactory`:

```cpp
// C++ side
PanelFactory::instance().register_panel("MyPanel", create_panel_function);
```

```python
# Python side
registry = dcc_core.PanelFactory.instance()
registry.register_panel("MyPanel", create_panel_callback)
```

## Important Notes

### Code Modernization

Recent commits show active modernization:
- Moving away from `boost::noncopyable` to deleted copy operations
- Updating to modern CMake targets (e.g., `Imath::Imath` instead of old ILMBASE)
- Supporting newer library versions (OCIO 2.x, PyOpenVDB)

When contributing, prefer modern C++ patterns over legacy Boost dependencies.

### VFX Reference Platform Compliance

OpenDCC conforms to the VFX Reference Platform. When updating dependencies, verify compatibility with the target VFX Platform year.

### USD Philosophy

**Minimize USD patches.** The architecture intentionally avoids modifying OpenUSD core to allow studios to swap in their own forks easily. Work with USD through composition, scene indices, and Hydra rather than patching USD itself.

### Logging

Use spdlog-based logging framework:

```cpp
#include "opendcc/base/vendor/spdlog/spdlog.h"
spdlog::info("Message");
spdlog::warn("Warning");
spdlog::error("Error");
```

### Crash Reporting

Sentry-based crash reporting is integrated. Crash handler configuration in [src/bin/dcc_base/main.cpp](src/bin/dcc_base/main.cpp) captures user context, project names, and server information from environment variables.

## File References

When referencing code locations, use this format:
- Files: `src/lib/opendcc/base/commands_api/core/command.h`
- Specific lines: `src/lib/opendcc/base/commands_api/core/command.h:58`
- Line ranges: `src/lib/opendcc/base/commands_api/core/command.h:58-92`
