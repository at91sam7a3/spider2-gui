# Spider2 Robot Control GUI

A Qt6/QML-based GUI application for controlling a Spider2 robot via ZeroMQ communication protocol.

## Features

- **ZeroMQ Communication**: Bidirectional communication with robot server
- **Video Display**: Full-window video background (currently stubbed as green rectangle)
- **Telemetry OSD**: On-screen display of all robot telemetry data
- **Dual Controls**: Both keyboard and on-screen controls for robot movement
- **Connection Dialog**: IP address input dialog on startup
- **Real-time Updates**: Live telemetry display and robot state monitoring

## Requirements

### System Dependencies

- **Qt6** (6.4 or later) with Quick module
- **CMake** (3.16 or later)
- **Conan** (package manager)

### Conan Dependencies

The following dependencies are automatically managed by Conan:

- `zeromq/4.3.5` - ZeroMQ messaging library
- `cppzmq/4.11.0` - C++ ZeroMQ bindings
- `protobuf/3.21.12` - Protocol Buffers library

## Installation

### Install System Dependencies

#### Ubuntu/Debian
```bash
sudo apt update
sudo apt install qt6-base-dev qt6-declarative-dev cmake protobuf-compiler libprotobuf-dev
pip install conan
```

#### macOS
```bash
brew install qt6 cmake protobuf
pip install conan
```

#### Windows
- Install Qt6 from [qt.io](https://www.qt.io/download)
- Install CMake from [cmake.org](https://cmake.org/download/)
- Install Protocol Buffers from [github.com/protocolbuffers/protobuf](https://github.com/protocolbuffers/protobuf/releases)
- Install Conan: `pip install conan`

## Building

### Option 1: Build Script (Recommended)

#### Linux/macOS
```bash
# Build release version
./build.sh

# Build debug version
./build.sh --debug

# Clean build
./build.sh --clean

# Custom build directory
./build.sh --build-dir my_build
```

#### Windows
```cmd
REM Build release version
build.bat

REM Build debug version
build.bat --debug

REM Clean build
build.bat --clean
```

### Option 2: Makefile
```bash
# Build release version (default)
make

# Build debug version
make debug

# Clean build directories
make clean

# Check dependencies
make check-deps

# Run the application
make run
```

### Option 3: Manual Build
```bash
# Create build directory
mkdir build && cd build

# Install Conan dependencies
conan install .. --build=missing

# Generate protobuf files
protoc --cpp_out=. --proto_path=.. ../command.proto

# Configure CMake
cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_TOOLCHAIN_FILE=conan_toolchain.cmake

# Build
cmake --build . --config Release --parallel
```

## Running

After building, run the application:

```bash
cd build
./appspider2-gui
```

## Usage

1. **Startup**: The application shows a connection dialog asking for the robot server IP address
2. **Connection**: Enter the robot's IP address and click "Connect"
3. **Controls**: Use either keyboard or on-screen controls to move the robot:
   - **Keyboard**: WASD (movement), Q/E (rotation), R/F (height), 1/2/3 (walking style)
   - **On-screen**: Click the directional buttons and controls in the bottom-right panel
4. **Telemetry**: View real-time robot data in the top-left OSD overlay
5. **Video**: The green rectangle represents the video feed (stubbed for now)

## Protocol

The application communicates with the robot using ZeroMQ with the following message format:

- **Message Structure**: `[MessageType byte][Protobuf binary data]`
- **Exception**: `VIDEO_FRAME` messages contain raw video data without protobuf
- **Connection**: DEALER socket connecting to robot server on port 5555

### Message Types

- `MOVE_COMMAND` - Robot movement control
- `TELEMETRY_UPDATE` - Sensor/status data
- `LIDAR_DATA` - LiDAR sensor readings
- `GYRO_DATA` - Gyroscope/IMU data
- `HEARTBEAT` - Connection keep-alive
- `VIDEO_FRAME` - Video frame data
- `HEIGHT_COMMAND` - Robot height control
- `WALKING_STYLE_COMMAND` - Walking style selection

## Project Structure

```
spider2-gui/
├── build.sh              # Linux/macOS build script
├── build.bat             # Windows build script
├── Makefile              # Alternative build system
├── CMakeLists.txt        # CMake build configuration
├── conanfile.txt         # Conan dependencies
├── command.proto         # Protocol Buffers definitions
├── MessageTypes.hpp      # Message type definitions
├── RobotController.h/cpp # ZeroMQ communication and robot control
├── VideoProvider.h/cpp   # Video display provider
├── main.cpp              # Application entry point
├── Main.qml              # Main application UI
├── ConnectionDialog.qml  # Connection dialog
└── TelemetryDisplay.qml  # Telemetry display component
```

## Development

### Adding New Message Types

1. Add message definition to `command.proto`
2. Add message type to `MessageType` enum in `MessageTypes.hpp`
3. Update `RobotController.cpp` to handle the new message type
4. Regenerate protobuf files: `protoc --cpp_out=. command.proto`

### Extending the UI

- Modify QML files in the project root
- Add new Q_PROPERTY bindings in `RobotController.h` for new data
- Update the build system if new C++ files are added

## Troubleshooting

### Common Issues

1. **Qt6 not found**: Ensure Qt6 is installed and `PKG_CONFIG_PATH` is set correctly
2. **Protobuf errors**: Make sure `protoc` is in your PATH
3. **Conan errors**: Run `conan profile detect` to set up Conan profiles
4. **Build failures**: Try cleaning the build directory and rebuilding

### Debug Mode

Build in debug mode for development:

```bash
./build.sh --debug
```

This enables debug symbols and disables optimizations for easier debugging.

## License

This project is part of the Spider2 robot control system.
