# Spider2 GUI - Build & Deployment Guide

## Quick Start

### 1. Build the Project
```bash
.\build.bat
```

This script will:
- Install dependencies using Conan
- Configure the project with CMake
- Compile the application using Visual Studio 2022

**Output:** `build\debug\Debug\spider2-gui.exe`

### 2. Create Deployment Package
```bash
.\deploy.bat
```

This script will:
- Copy the executable
- Deploy all Qt runtime libraries
- Create plugin directories
- Generate deployment documentation

**Output:** `deploy\` folder with 1384 files (~200-300 MB depending on compression)

### 3. (Optional) Create Distribution Archive
```bash
.\archive_deployment.bat
```

This will create a ZIP file of the entire deployment package suitable for distribution.

---

## Project Structure

```
spider2-gui/
├── src/                          # Source code
│   ├── main.cpp
│   ├── RobotController.*
│   ├── VideoProvider.*
│   ├── LidarController.*
│   ├── GyroController.*
│   ├── command.proto            # Protocol Buffer definition
│   └── ...
├── res/                         # Resources
│   └── qml/                     # Qt QML files
├── build/                       # Build artifacts (generated)
├── deploy/                      # Deployment package (generated)
├── CMakeLists.txt              # CMake configuration
├── conanfile.txt               # Conan dependencies
├── build.bat                   # Build script (Windows)
├── build.sh                    # Build script (Linux)
├── deploy.bat                  # Deployment script
├── archive_deployment.bat      # Archive creation script
└── pull_deps_debug.bat         # Download dependencies

```

---

## Dependencies

### Tools Required
- **CMake 3.20+**: For building (included with Qt)
- **Conan 2.0+**: For dependency management
- **Visual Studio 2022 Community**: C++ compiler
- **Qt 6.8.0**: GUI framework (MSVC 2022 build)

### Libraries (via Conan)
- **ZeroMQ**: Message passing library
- **Protocol Buffers**: Data serialization
- **libsodium**: Cryptography library
- **cppzmq**: C++ ZeroMQ bindings
- **zlib**: Compression library

---

## Build Customization

### Change Qt Installation Path
Edit `build.bat` line:
```batch
set "default_qt_install_prefix=C:\Qt\6.8.0\msvc2022_64"
```

Or pass as argument:
```batch
build.bat "D:\MyQt\6.8.0\msvc2022_64"
```

### Debug vs Release Build
The current setup builds in **Debug** mode. For Release:
1. Modify `build.bat`:
   - Change `Debug` to `Release` in conan and cmake commands
   - Update `--debug` to `--release` in deploy.bat

---

## Deployment Details

### Deployment Folder Contents

**1384 Total Files:**
- **1 executable**: spider2-gui.exe (6.9 MB)
- **79 DLLs**: Qt runtime libraries and dependencies
- **368 QML files**: User interface components
- **792 PNG images**: UI graphics
- **30 translation files**: Multi-language support
- **Supporting files**: Plugins, configuration, documentation

### Deployment Directories
```
deploy/
├── spider2-gui.exe              # Main executable
├── Qt6*.dll                     # Qt runtime libraries
├── *.dll                        # Supporting libraries
├── platforms/                   # Platform plugins (Windows)
├── imageformats/                # Image format support
├── iconengines/                 # Icon rendering
├── generic/                     # Generic plugins
├── networkinformation/          # Network plugins
├── tls/                         # SSL/TLS support
├── qml/                         # QML modules
├── translations/                # Language files
├── DEPLOYMENT_README.txt        # Deployment instructions
└── README.txt                   # Basic information
```

---

## Qt Creator

Qt Creator’s built-in Conan integration targets **Conan 1** (`conan_cmake_run`). This project uses **Conan 2** (`conan2 install`), the same as `build.bat`. Use the existing `build/debug` tree and skip Creator’s Conan step.

### One-time setup

1. Install dependencies (same as VS Code workflow):
   ```batch
   pull_deps_debug.bat
   ```
   Or run a full `build.bat` once.

2. In **Projects → Build**:
   - **Build directory:** `build/debug` (not `build/Desktop_Qt_…`)
   - **CMake generator:** **Visual Studio 17 2022** with **x64** (not Ninja — Conan’s toolchain sets `CMAKE_GENERATOR_PLATFORM`, which Ninja rejects). After changing the generator, run **Build → Clear CMake Configuration** (or delete `CMakeCache.txt` in the build folder).
   - **Initial CMake parameters** (add if not using preset):
     ```
     -DCMAKE_TOOLCHAIN_FILE=<build-dir>/conan_toolchain.cmake
     ```
   - For a **Release** Qt Creator build folder, run once:
     ```batch
     qtcreator_setup.bat Release build\Desktop_Qt_6_8_0_MSVC2022_64bit-Release
     ```
   - **CMake configuration:** enable preset **`conan-default`** if offered, or set:
     - `CMAKE_TOOLCHAIN_FILE` = `build/debug/conan_toolchain.cmake`
     - `CMAKE_PREFIX_PATH` = `C:/Qt/6.8.0/msvc2022_64` (your Qt path)

3. `QtCreatorPackageManager.cmake` in the repo root sets `QT_CREATOR_SKIP_CONAN_SETUP=ON` so Creator does not run the failing Conan 1 install.

4. **Run** executable: `build/debug/Debug/spider2-gui.exe`  
   **Deploy** (optional): still use `deploy.bat` from a terminal after building.

### If you keep a separate Qt Creator build folder

```batch
conan2 install . -s build_type=Debug --output-folder=build\Desktop_Qt_6_8_0_MSVC2022_64bit-Debug --build=missing
```

Then configure with **Visual Studio 17 2022** (not Ninja), `CMAKE_TOOLCHAIN_FILE` pointing at that folder’s `conan_toolchain.cmake`, and `QT_CREATOR_SKIP_CONAN_SETUP=ON`.

---

## Troubleshooting

### Build Failures

**Error: "Could NOT find Qt6"**
- Ensure Qt 6.8.0 MSVC 2022 is installed
- Verify path in build.bat matches your installation

**Error: "Conan installation failed"**
- Run `pull_deps_debug.bat` first to download dependencies
- Check internet connection
- Verify Conan is installed: `conan2 --version`

**Error: "CMake configuration failed"**
- Delete `build/` folder and try again
- Ensure Visual Studio 2022 is installed
- Run `vcvarsall.bat` manually if needed

### Runtime Issues

**Application won't start from deploy folder**
- Verify all DLL files are present
- Check Windows event viewer for specific errors
- Ensure Visual C++ Runtime is installed

**Missing plugins or QML files**
- Re-run `deploy.bat` after rebuilding
- Check that `res\qml\` folder exists in project root

---

## Development Workflow

### Quick Build & Deploy
```batch
:: Build
build.bat

:: Deploy
deploy.bat

:: Test
cd deploy
spider2-gui.exe
```

### Clean Build
```batch
rmdir /s /q build
build.bat
```

### Update Dependencies
```batch
pull_deps_debug.bat
build.bat
```

---

## Release Distribution

### Single File Distribution
Use the deployment folder as-is. Users can download and run directly.

### Compressed Distribution
```batch
archive_deployment.bat
```
This creates `spider2-gui-deployment.zip` for easy download/sharing.

### Installer (Advanced)
For professional distribution, consider:
- NSIS (free, open-source)
- InstallShield
- WiX Toolset

---

## Build & Test Matrix

| Component | Version | Status |
|-----------|---------|--------|
| Qt | 6.8.0 | ✓ Tested |
| CMake | 3.30+ | ✓ Working |
| Conan | 2.x | ✓ Working |
| MSVC | 2022 (v143) | ✓ Working |
| Windows | 10/11 | ✓ Tested |

---

## Advanced Options

### Parallel Build
`build.bat` automatically uses `%NUMBER_OF_PROCESSORS%` for parallel compilation.

### Debug Symbols
Debug builds include full debugging symbols in:
- `build\debug\Debug\spider2-gui.pdb`

### Static Linking
Most dependencies are statically linked. Runtime requirements are minimal.

---

## Performance Notes

- **Debug build**: Full debugging support, larger executable
- **Deployment size**: ~200-300 MB (uncompressed)
- **Runtime memory**: Typical ~50-100 MB depending on usage
- **Startup time**: ~1-2 seconds (debug build)

---

## Support & Documentation

- **CMake**: https://cmake.org/documentation/
- **Qt 6**: https://doc.qt.io/qt-6/
- **Conan**: https://conan.io/
- **ZeroMQ**: https://zeromq.org/

---

**Last Updated**: 2026-05-19  
**Project**: Spider2 GUI  
**Build System**: CMake + Conan  
**Target Platform**: Windows 10/11 x64
