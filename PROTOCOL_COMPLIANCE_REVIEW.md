# Protocol Compliance Review - Spider2 GUI

## Issues Found

### 1. **Proto File - MISSING VideoFrame Message** ❌
**Current:** `src/command.proto` does not include `VideoFrame` message  
**Required:** Must have VideoFrame with JPEG data support  
**Impact:** Cannot receive video frames from server  
**Fix:** Add VideoFrame message from updated proto file

---

### 2. **Message Type Enum - VALUES MISMATCH** ❌
**Current Implementation:**
```cpp
MOVE_COMMAND = 1
TELEMETRY_UPDATE = 2
LIDAR_DATA = 3
GYRO_DATA = 4
HEARTBEAT = 5
VIDEO_FRAME = 6
HEIGHT_COMMAND = 7
WALKING_STYLE_COMMAND = 8
```

**Protocol Specification:**
```
HEARTBEAT = 0x00
MOVE_COMMAND = 0x01
TELEMETRY_UPDATE = 0x02
GYRO_DATA = 0x03
LIDAR_DATA = 0x04
VIDEO_FRAME = 0x05
HEIGHT_COMMAND = 0x06
WALKING_STYLE_CMD = 0x07
```

**Differences:**
- HEARTBEAT: 5 → 0 ❌
- LIDAR_DATA: 3 → 4 ❌
- GYRO_DATA: 4 → 3 ❌
- VIDEO_FRAME: 6 → 5 ❌
- All others shifted

**Impact:** Communication will fail - message types won't be recognized  
**Fix:** Reorder enum to match protocol specification

---

### 3. **ZMQ Frame Receiving - INCORRECT PATTERN** ❌
**Current Code (RobotController.cpp lines 175-200):**
```cpp
// Receive identity frame first (ROUTER/DEALER pattern)
zmq::message_t identity;
auto result = m_socket->recv(identity, zmq::recv_flags::dontwait);

if (result) {
    // Receive message type second
    zmq::message_t type_msg;
    result = m_socket->recv(type_msg, zmq::recv_flags::dontwait);
    
    if (result && type_msg.size() == 1) {
        // Receive message data third
        zmq::message_t data_msg;
        result = m_socket->recv(data_msg, zmq::recv_flags::dontwait);
```

**Problem:** DEALER socket receiving from ROUTER server  
- Server (ROUTER) automatically prepends identity to SENT messages
- Server does NOT receive client identity when DEALER is the sender
- Client (DEALER) receiving from server gets NO identity frame
- Should be 2 frames: [type][data], NOT 3 frames

**Protocol Specification:**
> Incoming Message (Server → Client)
> ```
> Frame 0: [Message Type - 1 byte uint8]
> Frame 1: [Protobuf Serialized Data - variable length]
> ```

**Current:** Receiving 3 frames (identity, type, data)  
**Required:** Receive 2 frames (type, data)  
**Impact:** Extra frame receive call hangs/blocks, message processing delayed  
**Fix:** Remove identity frame receiving

---

### 4. **Video Frame Handling - NOT IMPLEMENTED** ❌
**Current Code (RobotController.cpp line 245-249):**
```cpp
// Handle VIDEO_FRAME specially (no protobuf)
if (messageType == static_cast<uint8_t>(Spider2::MessageType::VIDEO_FRAME)) {
    // For now, we don't process video frames
    // In the future, this would update the VideoProvider
    return;
}
```

**Required by Protocol:**
- Server sends VIDEO_FRAME messages ~30fps
- Message contains JPEG-encoded frame data
- Must parse VideoFrame protobuf (has timestamp, data, width, height)
- Must decode JPEG and display in VideoProvider

**Impact:** Video stream ignored, no camera feed to UI  
**Fix:** Implement proper VideoFrame parsing and JPEG decoding

---

### 5. **Movement Speed Range - INCORRECT BOUNDS** ❌
**Current Code (RobotController.cpp lines 35-60):**
```cpp
m_forwardSpeed = qBound(-1.0f, speed, 1.0f);  // Wrong range
m_strafeSpeed = qBound(-1.0f, speed, 1.0f);   // Wrong range
m_rotationSpeed = qBound(-1.0f, speed, 1.0f); // Correct range
```

**Protocol Specification:**
```protobuf
message MoveCommand{
    required float forwardSpeed = 1;   // m/s, range: -2.0 to 2.0
    required float strafeSpeed = 2;    // m/s, range: -2.0 to 2.0
    required float rotationSpeed = 3;  // rad/s, range: -1.0 to 1.0
}
```

**Issues:**
- Forward speed: should be ±2.0, not ±1.0 ❌
- Strafe speed: should be ±2.0, not ±1.0 ❌
- Rotation speed: ±1.0 is correct ✓

**Impact:** Limited movement control, cannot reach full speed  
**Fix:** Update bounds to match protocol

---

### 6. **Height Command Range - MISSING VALIDATION** ❌
**Current Code (RobotController.cpp lines 76-84):**
```cpp
m_height = height;  // No bounds checking!
emit heightChanged();
```

**Protocol Specification:**
```protobuf
message HeightCommand{
    required float height = 1;  // meters, range: 0.1 to 0.4
}
```

**Issue:** No validation of height range  
**Impact:** Invalid commands sent to robot (height outside 0.1-0.4m range)  
**Fix:** Add bounds checking

---

### 7. **Walking Style Validation** ⚠️
**Current Code (RobotController.cpp line 91):**
```cpp
if (m_walkingStyle != style && style >= 1 && style <= 3) {
```

**Protocol Specification:**
```protobuf
message WalkingStyleCommand{
    required int32 style = 1;  // 1=TwoLegs, 2=ThreeLegs, 3=Wave
}
```

**Status:** Validation is correct ✓

---

### 8. **Lidar Data Validation - INCOMPLETE** ⚠️
**Protocol Specification:**
- Exactly 16 samples per message
- Packed format (optimized)
- Both angles and distances required

**Current Code (RobotController.cpp line 270):**
```cpp
int count = std::min(lidar.angles_size(), lidar.distances_size());

for (int i = 0; i < count; i++) {
    points.append(LidarPoint(lidar.angles(i), lidar.distances(i)));
}
```

**Issues:**
- Should validate EXACTLY 16 samples, not flexible count ⚠️
- Distance range validation missing (should be 0.1m to 10m)

**Fix:** Add strict validation

---

### 9. **Gyro Data - Z-AXIS MISSING** ⚠️
**Protocol Specification:**
```protobuf
message GyroData{
    required int64 timestamp = 1;
    required float x = 2;          // X-axis angular velocity rad/s
    required float y = 3;          // Y-axis angular velocity rad/s
}
```

**Current Code (RobotController.cpp line 284):**
```cpp
m_gyroController->updateGyroData(gyro.x(), gyro.y(), 0.0f, gyro.timestamp());
```

**Issue:** Protocol only provides X and Y, not Z  
**Status:** Code correctly uses 0.0 for Z ✓

---

### 10. **Telemetry Data - NOT VALIDATED** ⚠️
**Current Code (RobotController.cpp lines 300-310):**
```cpp
case Spider2::MessageType::TELEMETRY_UPDATE: {
    Command::TelemetryUpdate telemetry;
    if (telemetry.ParseFromString(protobufData)) {
        updateTelemetry(telemetry);
    }
    break;
}
```

**Protocol Expected Metrics:**
- `battery_voltage` (float) - Battery charge level (V)
- `cpu_temperature` (float) - CPU temp (°C)
- `status` (string) - Robot state ("running", "error", "idle")

**Issue:** No validation of metric names or ranges  
**Impact:** Potentially crashes with unknown metrics  
**Fix:** Add validation logic

---

## Summary Table

| Issue | Type | Severity | Status |
|-------|------|----------|--------|
| Missing VideoFrame message | Proto | **CRITICAL** | ❌ Not fixed |
| Message type enum mismatch | Protocol | **CRITICAL** | ❌ Not fixed |
| Frame receiving (3 vs 2) | ZMQ | **CRITICAL** | ❌ Not fixed |
| Video frame not processed | Implementation | **HIGH** | ❌ Not implemented |
| Speed bounds wrong | Validation | **HIGH** | ❌ Not fixed |
| Height bounds missing | Validation | **MEDIUM** | ❌ Not fixed |
| Lidar validation loose | Validation | **MEDIUM** | ⚠️ Partial |
| Telemetry validation missing | Validation | **LOW** | ⚠️ Partial |

---

## Files to Update

1. ✅ `src/command.proto` - Add VideoFrame, update proto file
2. ✅ `src/MessageTypes.hpp` - Reorder enum values
3. ✅ `src/RobotController.cpp` - Fix receiving, speed bounds, height validation
4. ✅ `src/RobotController.h` - Add VideoProvider member
5. ✅ `src/VideoProvider.cpp` - Implement JPEG decoding

---

## Next Steps

1. Replace proto file with new version from server
2. Update message type enum values
3. Fix ZMQ frame receiving pattern
4. Implement video frame handling with JPEG decoding
5. Add proper bounds validation
6. Test with running robot server
