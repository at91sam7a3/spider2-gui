# Spider2 Robot Communication Protocol

**Document Version:** 1.0  
**Date:** May 2026  
**Target:** Client implementation (Python, C++, Node.js, etc.)

---

## Table of Contents

1. [Overview](#overview)
2. [ZMQ Architecture](#zmq-architecture)
3. [Message Frame Structure](#message-frame-structure)
4. [Message Types](#message-types)
5. [Protocol Buffers Definitions](#protocol-buffers-definitions)
6. [Request/Response Patterns](#requestresponse-patterns)
7. [Connection Lifecycle](#connection-lifecycle)
8. [Error Handling](#error-handling)
9. [Client Implementation Guide](#client-implementation-guide)

---

## Overview

Spider2 uses **ZeroMQ (ZMQ)** for asynchronous message-based communication and **Protocol Buffers (protobuf)** for message serialization. The system follows a **ROUTER/DEALER pattern** where:

- **Server:** Listens on a ROUTER socket (receives from multiple clients)
- **Client:** Connects with a DEALER socket (sends to server, receives asynchronously)

### Key Characteristics

| Property | Value |
|----------|-------|
| **Network Protocol** | TCP |
| **Default Port** | `5555` |
| **Message Serialization** | Protocol Buffers (proto2) |
| **ZMQ Pattern** | ROUTER/DEALER async |
| **Video Compression** | JPEG (standard) |
| **Message Timeout** | 30 seconds (client disconnect after no heartbeat) |
| **Supported Clients** | Multiple simultaneous |

---

## ZMQ Architecture

### Socket Configuration

#### Server Side (Robot)

```cpp
zmq::context_t context(1);
zmq::socket_t socket(context, zmq::socket_type::router);
socket.bind("tcp://*:5555");
```

**Properties:**
- **Type:** `ROUTER` socket
- **Address:** `tcp://*:5555` (bind on all interfaces, port 5555)
- **Behavior:** Automatically prepends client identity to all received messages
- **Async:** Non-blocking receive with 100ms timeout

#### Client Side (Your Implementation)

```cpp
// C++ example
zmq::socket_t socket(context, zmq::socket_type::dealer);
socket.connect("tcp://192.168.18.90:5555");
```

**Properties:**
- **Type:** `DEALER` socket
- **Address:** `tcp://[ROBOT_IP]:5555`
- **Behavior:** Automatically adds empty delimiter frame
- **Default Timeout:** Should implement 30s inactivity timeout

### Message Flow Pattern

```
CLIENT (DEALER)                      SERVER (ROUTER)
    |                                    |
    |--- send 3 frames ----------------->|
    |                                    |
    |<-- receive async telemetry --------|
    |<-- receive async sensor data ------|
```

---

## Message Frame Structure

### Outgoing Message (Client → Server)

All client messages are sent as **3-frame ZMQ messages**:

```
Frame 0: [Empty Frame - Added by DEALER automatically]
Frame 1: [Message Type - 1 byte uint8]
Frame 2: [Protobuf Serialized Data - variable length]
```

### Incoming Message (Server → Client)

Server sends **2-frame messages** (no client identity needed):

```
Frame 0: [Message Type - 1 byte uint8]
Frame 1: [Protobuf Serialized Data - variable length]
```

### Frame Details

#### Frame 0 (Client only): Empty Frame
- **Type:** Delimiter
- **Length:** 0 bytes
- **Purpose:** Added automatically by DEALER socket, indicates client identity boundary
- **Action:** Ignore on client side (ZMQ handles this)

#### Frame 1: Message Type
- **Type:** Unsigned 8-bit integer (uint8)
- **Byte Order:** Network byte order (big-endian)
- **Valid Values:** See [Message Types](#message-types)
- **Example:** `0x01` = MOVE_COMMAND

#### Frame 2: Protobuf Data
- **Type:** Binary protobuf serialized message
- **Length:** Variable (0-16MB typical)
- **Encoding:** Protobuf binary format (not JSON or text)
- **Empty Payload:** Valid for some message types (e.g., HEARTBEAT has empty data)

---

## Message Types

### Message Type Enum

```cpp
enum MessageType : uint8_t {
    HEARTBEAT          = 0x00,  // Client → Server (1Hz) + Server → Client (every 5s)
    MOVE_COMMAND       = 0x01,  // Client → Server: Movement velocity
    TELEMETRY_UPDATE   = 0x02,  // Server → Client: System metrics
    GYRO_DATA          = 0x03,  // Server → Client: Gyroscope readings
    LIDAR_DATA         = 0x04,  // Server → Client: LIDAR scan
    VIDEO_FRAME        = 0x05,  // Server → Client: Camera frame (JPEG encoded)
    HEIGHT_COMMAND     = 0x06,  // Client → Server: Body height adjustment
    WALKING_STYLE_CMD  = 0x07,  // Client → Server: Walking gait selection
};
```

### Message Direction Reference

| Type | Direction | Frequency | Response | Timeout |
|------|-----------|-----------|----------|---------|
| HEARTBEAT | Bidirectional | 1Hz (client) | HEARTBEAT ack | 30s |
| MOVE_COMMAND | → Server | On-demand | None (async) | - |
| HEIGHT_COMMAND | → Server | On-demand | None (async) | - |
| WALKING_STYLE_CMD | → Server | On-demand | None (async) | - |
| TELEMETRY_UPDATE | → Client | ~1Hz | None | - |
| GYRO_DATA | → Client | ~10Hz | None | - |
| LIDAR_DATA | → Client | ~10Hz | None | - |
| VIDEO_FRAME | → Client | ~30fps | None | - |

---

## Protocol Buffers Definitions

### Raw .proto File Location

**File:** `command.proto` (in robot root directory)

### Message Definitions

#### 1. Heartbeat

```protobuf
message Heartbeat{
    required int64 timestamp = 1;
    optional string client_id = 2;
}
```

**Usage:** 
- Client sends every 1 second to keep connection alive
- Server responds with HEARTBEAT to acknowledge
- If no heartbeat received for 30s, connection is considered dead
- Timestamp: Unix epoch milliseconds

#### 2. MoveCommand

```protobuf
message MoveCommand{
    required float forwardSpeed = 1;   // m/s, range: -2.0 to 2.0
    required float strafeSpeed = 2;    // m/s, range: -2.0 to 2.0
    required float rotationSpeed = 3;  // rad/s, range: -1.0 to 1.0
}
```

**Usage:**
- Client sends movement commands (asynchronous, no response expected)
- Values are body-relative: forward/strafe/rotation
- Movement thread reads latest command every 10ms
- Sending zeros stops the robot

#### 3. HeightCommand

```protobuf
message HeightCommand{
    required float height = 1;  // meters, range: 0.1 to 0.4
}
```

**Usage:**
- Adjust robot body height
- Typical range: 0.1m (low) to 0.4m (high)

#### 4. WalkingStyleCommand

```protobuf
message WalkingStyleCommand{
    required int32 style = 1;  // 1=TwoLegs, 2=ThreeLegs, 3=Wave
}
```

**Usage:**
- Select hexapod walking gait
- Enum values: 1 (TwoLegs), 2 (ThreeLegs), 3 (Wave)

#### 5. GyroData

```protobuf
message GyroData{
    required int64 timestamp = 1;  // Unix epoch milliseconds
    required float x = 2;          // Angular velocity rad/s
    required float y = 3;          // Angular velocity rad/s
}
```

**Usage:**
- Server sends gyroscope readings (~10Hz from BNO055 IMU)
- From I2C device at address 0x29
- Raw 16-bit readings converted to rad/s

#### 6. LidarData

```protobuf
message LidarData{
    required int64 timestamp = 1;
    repeated float angles = 2 [packed=true];      // 16 angle readings (radians)
    repeated float distances = 3 [packed=true];   // 16 distance readings (meters)
}
```

**Usage:**
- Server sends LIDAR scans (~10Hz)
- Exactly 16 samples per message
- Packed format (optimized binary encoding)
- Distance range: 0.1m to 10m

#### 7. VideoFrame

```protobuf
message VideoFrame{
    required int64 timestamp = 1;  // Unix epoch milliseconds
    required bytes data = 2;       // JPEG-encoded frame
    required int32 width = 3;      // 640 (default)
    required int32 height = 4;     // 480 (default)
}
```

**Usage:**
- Server sends camera frames (~30fps)
- Data is JPEG-encoded binary (not raw RGB)
- Clients must decode JPEG data (SOI/EOI markers present)
- Typical frame size: 15-50 KB per frame

#### 8. TelemetryUpdate

```protobuf
message TelemetryUpdate{
    required string name = 1;  // Metric name: "battery_voltage", "cpu_temp", "status"
    oneof value {
        float fvalue = 2;      // For numeric metrics
        string svalue = 3;     // For string metrics
        bool bvalue = 4;       // For boolean metrics
        int32 ivalue = 5;      // For integer metrics
    }
}
```

**Purpose:** System health monitoring (NOT sensor data)

**Sent Automatically:** Yes, ~1Hz

**Usage:**
- Server sends system metrics (~1Hz) independent of sensor data
- Used for monitoring robot health, not sensor readings
- Common metrics:
  - `battery_voltage` (float): e.g., 12.5V — Battery charge level
  - `cpu_temperature` (float): e.g., 45.2°C — Raspberry Pi CPU temp
  - `status` (string): e.g., "running", "error", "idle" — Robot operational status
  - Any custom metric as name/value pair

**Distinction from Sensor Data:**
- **GYRO_DATA** = Motion sensor (angular velocity)
- **LIDAR_DATA** = Distance sensor (range readings)
- **VIDEO_FRAME** = Vision sensor (camera image)
- **TELEMETRY_UPDATE** = System health (battery, CPU, status) — NOT a sensor, monitors robot itself

---

## Request/Response Patterns

### Key Distinction: Hybrid Async (NOT Pure Request-Response)

This protocol is **NOT request-response**. It's **hybrid async**:

| Initiator | What | Response | Notes |
|-----------|------|----------|-------|
| **Client → Server** | Commands (MOVE, HEIGHT, etc.) | None | Async, fire-and-forget |
| **Client → Server** | HEARTBEAT (keep-alive) | Server responds with HEARTBEAT | Required for connection |
| **Server → Client** | Telemetry (GYRO, LIDAR, VIDEO) | None | **Server initiates unsolicited** |
| **Server → Client** | TELEMETRY_UPDATE (health) | None | **Server initiates unsolicited** |

**Important:** The server **DOES initiate** telemetry sends. Clients must have a receiver thread listening for unsolicited data from server.

### Pattern 1: Command (Fire and Forget)

**Flow:**
```
Client                          Server
  |                               |
  | MOVE_COMMAND (3 frames) ------>|
  |                               |
  | (no response expected)        |
  |                               |
```

**Message Types:** MOVE_COMMAND, HEIGHT_COMMAND, WALKING_STYLE_COMMAND

### Pattern 2: Telemetry Push (Server → Client)

**Flow:**
```
Client                          Server
  |                               |
  |                          (sensor reads every N ms)
  |                               |
  | <----- GYRO_DATA (2 frames) --|
  | <----- LIDAR_DATA (2 frames) |
  | <----- VIDEO_FRAME (2 frames)|
  |                               |
```

**Message Types:** TELEMETRY_UPDATE, GYRO_DATA, LIDAR_DATA, VIDEO_FRAME

### Pattern 3: Heartbeat (Keep-Alive)

**Flow:**
```
Client                          Server
  |                               |
  | HEARTBEAT (3 frames) -------->|
  | (every 1 second)              |
  |                               |
  | <---- HEARTBEAT (2 frames) ---|
  | (periodic acknowledgment)     |
  |                               |
```

**Message Type:** HEARTBEAT (bidirectional)

**Timeout Behavior:**
- Server keeps per-client timestamp
- If no message received for 30 seconds → connection considered dead
- Client should send heartbeat every 1 second
- Server sends heartbeat every 5 seconds (for acknowledgment)

---

## Connection Lifecycle

### 1. Connection Establishment

```
CLIENT                                  SERVER
  |                                        |
  | socket = DEALER                       |
  | socket.connect("tcp://192.168.18.90:5555")
  |                                        |
  |--- HEARTBEAT (first) ----------------->|
  |                                        |
  |<---- HEARTBEAT (ack) ------------------|
  |                                        |
  | (ready for commands/telemetry)        |
```

### 2. Active Connection

```
CLIENT                                  SERVER
  |                                        |
  |--- HEARTBEAT (every 1s) --------->    |
  |--- MOVE_COMMAND (on demand) ------>   |
  |                                        |
  |<---- GYRO_DATA (every 100ms) ------   |
  |<---- LIDAR_DATA (every 100ms) -----   |
  |<---- VIDEO_FRAME (every 33ms) -----   |
  |<---- TELEMETRY_UPDATE (every 1s) --   |
  |<---- HEARTBEAT (every 5s) ----------  |
  |                                        |
```

### 3. Connection Timeout

```
CLIENT                                  SERVER
  |                                        |
  | (30+ seconds without message)         |
  |                                        |
  | <---- NO DATA (connection dead) ---    | (client entry deleted)
  |                                        |
  | (client will reconnect on next attempt)
  |                                        |
```

### 4. Clean Disconnect

```
CLIENT                                  SERVER
  |                                        |
  | socket.close()                        |
  | context.term()                        |
  |                                        |
  | (TCP connection drops)                |
  |                                        |
  |<---- NO DATA ----------------------   | (client auto-removed after 30s timeout)
  |                                        |
```

---

## Error Handling

### ZMQ Connection Errors

| Error | Cause | Recovery |
|-------|-------|----------|
| Connection refused | Server not running | Retry with exponential backoff |
| Host unreachable | Network issue | Check IP/firewall |
| Timeout | Network latency | Increase ZMQ timeout |
| Broken pipe | Server crashed | Reconnect |

### Message Parsing Errors

| Error | Cause | Recovery |
|-------|-------|----------|
| Invalid message type | Corrupt byte or version mismatch | Skip message, log warning |
| Protobuf parse fail | Truncated data | Skip message, reconnect if persistent |
| Empty payload on required field | Malformed message | Skip message, log warning |

### Connection Lifecycle Errors

| Error | Cause | Recovery |
|-------|-------|----------|
| No heartbeat for 30s | Network or server issue | Reconnect |
| Multiple simultaneous connects | Client didn't disconnect | Use unique client_id per connection |

---

## Client Implementation Guide

### Minimal C++ Client

```cpp
#include <zmq.hpp>
#include "command.pb.h"
#include <thread>
#include <chrono>

class RobotClient {
private:
    zmq::context_t context;
    zmq::socket_t socket;
    bool running;

public:
    RobotClient(const std::string& robot_ip, int port = 5555)
        : context(1), socket(context, zmq::socket_type::dealer), running(true) {
        std::string endpoint = "tcp://" + robot_ip + ":" + std::to_string(port);
        socket.connect(endpoint);
        
        std::thread hb(&RobotClient::heartbeat_loop, this);
        hb.detach();
    }

    void heartbeat_loop() {
        while (running) {
            Command::Heartbeat hb;
            hb.set_timestamp(std::chrono::duration_cast<std::chrono::milliseconds>(
                std::chrono::system_clock::now().time_since_epoch()).count());
            hb.set_client_id("cpp_client");
            
            std::string data = hb.SerializeAsString();
            socket.send(zmq::const_buffer("\x00", 1), zmq::send_flags::none);
            socket.send(zmq::const_buffer(data.data(), data.size()), zmq::send_flags::none);
            
            std::this_thread::sleep_for(std::chrono::seconds(1));
        }
    }

    void move(float forward, float strafe, float rotation) {
        Command::MoveCommand move;
        move.set_forwardspeed(forward);
        move.set_strafespeed(strafe);
        move.set_rotationspeed(rotation);
        
        std::string data = move.SerializeAsString();
        socket.send(zmq::const_buffer("\x01", 1), zmq::send_flags::none);
        socket.send(zmq::const_buffer(data.data(), data.size()), zmq::send_flags::none);
    }

    ~RobotClient() {
        running = false;
    }
};
```

---

## Quick Reference: Message Type Map

```
0x00 = HEARTBEAT         (bi-directional, keep-alive)
0x01 = MOVE_COMMAND      (client→server, movement)
0x02 = TELEMETRY_UPDATE  (server→client, metrics)
0x03 = GYRO_DATA         (server→client, gyroscope)
0x04 = LIDAR_DATA        (server→client, LIDAR scan)
0x05 = VIDEO_FRAME       (server→client, camera)
0x06 = HEIGHT_COMMAND    (client→server, body height)
0x07 = WALKING_STYLE_CMD (client→server, gait)
```

---

## Troubleshooting

### "Connection refused"
- Ensure robot is running: `./build-arm64/spider2`
- Check robot IP address: `ip addr` on robot
- Check firewall: `sudo ufw status`

### "Invalid message type"
- Verify message type byte is in range 0x00-0x07
- Check protobuf compilation: `protoc --version`

### "No telemetry received"
- Ensure receiver thread is running
- Check ZMQ socket timeout settings
- Verify heartbeat is being sent (1Hz)

### "Latency issues"
- Reduce LIDAR/video frame rates by modifying robot code
- Use `--bwlimit` in rsync to avoid WiFi saturation

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | May 2026 | Initial protocol documentation |
