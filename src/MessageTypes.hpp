#pragma once

#include <cstdint>
#include <string>
#include <vector>
#include <chrono>
#include "command.pb.h"

namespace Spider2 {

/**
 * @brief Message type enumeration for the Spider2 robot communication protocol
 * 
 * This enum defines all the message types that can be sent between the robot
 * and client applications. Each type corresponds to a specific protobuf message.
 */
enum class MessageType : uint8_t {
    MOVE_COMMAND = 1,        ///< Robot movement control command
    TELEMETRY_UPDATE = 2,    ///< Sensor or status data update
    LIDAR_DATA = 3,          ///< LiDAR sensor readings
    GYRO_DATA = 4,           ///< Gyroscope/IMU data
    HEARTBEAT = 5,           ///< Connection keep-alive message
    VIDEO_FRAME = 6,         ///< Video frame data
    HEIGHT_COMMAND = 7,      ///< Robot height control command
    WALKING_STYLE_COMMAND = 8 ///< Robot walking style command
};

/**
 * @brief Message direction enumeration
 * 
 * Indicates whether a message is being sent from client to robot
 * or from robot to client.
 */
enum class MessageDirection : uint8_t {
    CLIENT_TO_ROBOT = 0,     ///< Message sent from client to robot
    ROBOT_TO_CLIENT = 1      ///< Message sent from robot to client
};

/**
 * @brief Telemetry data types enumeration
 * 
 * Defines the different types of telemetry data that can be sent
 * in a TelemetryUpdate message.
 */
enum class TelemetryType : uint8_t {
    FLOAT = 0,               ///< Float value
    STRING = 1,              ///< String value
    BOOLEAN = 2,             ///< Boolean value
    INTEGER = 3              ///< Integer value
};

/**
 * @brief Message type constants and utilities
 */
namespace MessageConstants {
    // Message type names for logging and debugging
    constexpr const char* MOVE_COMMAND_NAME = "MoveCommand";
    constexpr const char* TELEMETRY_UPDATE_NAME = "TelemetryUpdate";
    constexpr const char* LIDAR_DATA_NAME = "LidarData";
    constexpr const char* GYRO_DATA_NAME = "GyroData";
    constexpr const char* HEARTBEAT_NAME = "Heartbeat";
    
    // Default values
    constexpr float DEFAULT_MOVE_SPEED = 0.0f;
    constexpr int64_t DEFAULT_TIMESTAMP = 0;
    constexpr int DEFAULT_LIDAR_READINGS = 16;
    
    // Message size limits
    constexpr size_t MAX_TELEMETRY_NAME_LENGTH = 64;
    constexpr size_t MAX_CLIENT_ID_LENGTH = 32;
    constexpr size_t MAX_LIDAR_READINGS = 32;
}

/**
 * @brief Message creation helper functions
 */
namespace MessageFactory {
    
    /**
     * @brief Create a MoveCommand message
     * @param forward_speed Forward movement speed (-1.0 to 1.0)
     * @param strafe_speed Sideways movement speed (-1.0 to 1.0)
     * @param rotation_speed Rotation speed (-1.0 to 1.0)
     * @return MoveCommand protobuf message
     */
    inline Command::MoveCommand createMoveCommand(float forward_speed, 
                                                  float strafe_speed, 
                                                  float rotation_speed) {
        Command::MoveCommand cmd;
        cmd.set_forwardspeed(forward_speed);
        cmd.set_strafespeed(strafe_speed);
        cmd.set_rotationspeed(rotation_speed);
        return cmd;
    }
    
    /**
     * @brief Create a TelemetryUpdate message with float value
     * @param name Telemetry parameter name
     * @param value Float value
     * @return TelemetryUpdate protobuf message
     */
    inline Command::TelemetryUpdate createTelemetryUpdate(const std::string& name, float value) {
        Command::TelemetryUpdate telemetry;
        telemetry.set_name(name);
        telemetry.set_fvalue(value);
        return telemetry;
    }
    
    /**
     * @brief Create a TelemetryUpdate message with string value
     * @param name Telemetry parameter name
     * @param value String value
     * @return TelemetryUpdate protobuf message
     */
    inline Command::TelemetryUpdate createTelemetryUpdate(const std::string& name, const std::string& value) {
        Command::TelemetryUpdate telemetry;
        telemetry.set_name(name);
        telemetry.set_svalue(value);
        return telemetry;
    }
    
    /**
     * @brief Create a TelemetryUpdate message with boolean value
     * @param name Telemetry parameter name
     * @param value Boolean value
     * @return TelemetryUpdate protobuf message
     */
    inline Command::TelemetryUpdate createTelemetryUpdate(const std::string& name, bool value) {
        Command::TelemetryUpdate telemetry;
        telemetry.set_name(name);
        telemetry.set_bvalue(value);
        return telemetry;
    }
    
    /**
     * @brief Create a TelemetryUpdate message with integer value
     * @param name Telemetry parameter name
     * @param value Integer value
     * @return TelemetryUpdate protobuf message
     */
    inline Command::TelemetryUpdate createTelemetryUpdate(const std::string& name, int32_t value) {
        Command::TelemetryUpdate telemetry;
        telemetry.set_name(name);
        telemetry.set_ivalue(value);
        return telemetry;
    }
    
    /**
     * @brief Create a LidarData message
     * @param angles Vector of angle readings in radians
     * @param distances Vector of distance readings in meters
     * @param timestamp Optional timestamp (defaults to current time)
     * @return LidarData protobuf message
     */
    inline Command::LidarData createLidarData(const std::vector<float>& angles,
                                              const std::vector<float>& distances,
                                              int64_t timestamp = 0) {
        Command::LidarData lidar;
        
        if (timestamp == 0) {
            timestamp = std::chrono::duration_cast<std::chrono::milliseconds>(
                std::chrono::system_clock::now().time_since_epoch()).count();
        }
        
        lidar.set_timestamp(timestamp);
        
        for (float angle : angles) {
            lidar.add_angles(angle);
        }
        
        for (float distance : distances) {
            lidar.add_distances(distance);
        }
        
        return lidar;
    }
    
    /**
     * @brief Create a GyroData message
     * @param x X-axis angular velocity in rad/s
     * @param y Y-axis angular velocity in rad/s
     * @param timestamp Optional timestamp (defaults to current time)
     * @return GyroData protobuf message
     */
    inline Command::GyroData createGyroData(float x, float y, int64_t timestamp = 0) {
        Command::GyroData gyro;
        
        if (timestamp == 0) {
            timestamp = std::chrono::duration_cast<std::chrono::milliseconds>(
                std::chrono::system_clock::now().time_since_epoch()).count();
        }
        
        gyro.set_timestamp(timestamp);
        gyro.set_x(x);
        gyro.set_y(y);
        
        return gyro;
    }
    
    /**
     * @brief Create a Heartbeat message
     * @param client_id Optional client identifier
     * @param timestamp Optional timestamp (defaults to current time)
     * @return Heartbeat protobuf message
     */
    inline Command::Heartbeat createHeartbeat(const std::string& client_id = "", int64_t timestamp = 0) {
        Command::Heartbeat heartbeat;
        
        if (timestamp == 0) {
            timestamp = std::chrono::duration_cast<std::chrono::milliseconds>(
                std::chrono::system_clock::now().time_since_epoch()).count();
        }
        
        heartbeat.set_timestamp(timestamp);
        
        if (!client_id.empty()) {
            heartbeat.set_client_id(client_id);
        }
        
        return heartbeat;
    }
}

/**
 * @brief Message validation helper functions
 */
namespace MessageValidator {
    
    /**
     * @brief Validate a MoveCommand message
     * @param cmd MoveCommand to validate
     * @return true if valid, false otherwise
     */
    inline bool isValidMoveCommand(const Command::MoveCommand& cmd) {
        return cmd.has_forwardspeed() && 
               cmd.has_strafespeed() && 
               cmd.has_rotationspeed() &&
               cmd.forwardspeed() >= -1.0f && cmd.forwardspeed() <= 1.0f &&
               cmd.strafespeed() >= -1.0f && cmd.strafespeed() <= 1.0f &&
               cmd.rotationspeed() >= -1.0f && cmd.rotationspeed() <= 1.0f;
    }
    
    /**
     * @brief Validate a TelemetryUpdate message
     * @param telemetry TelemetryUpdate to validate
     * @return true if valid, false otherwise
     */
    inline bool isValidTelemetryUpdate(const Command::TelemetryUpdate& telemetry) {
        if (!telemetry.has_name() || telemetry.name().empty()) {
            return false;
        }
        
        if (telemetry.name().length() > MessageConstants::MAX_TELEMETRY_NAME_LENGTH) {
            return false;
        }
        
        // Check that exactly one value type is set
        int value_count = 0;
        if (telemetry.has_fvalue()) value_count++;
        if (telemetry.has_svalue()) value_count++;
        if (telemetry.has_bvalue()) value_count++;
        if (telemetry.has_ivalue()) value_count++;
        
        return value_count == 1;
    }
    
    /**
     * @brief Validate a LidarData message
     * @param lidar LidarData to validate
     * @return true if valid, false otherwise
     */
    inline bool isValidLidarData(const Command::LidarData& lidar) {
        if (!lidar.has_timestamp()) {
            return false;
        }
        
        int angle_count = lidar.angles_size();
        int distance_count = lidar.distances_size();
        
        if (angle_count != distance_count) {
            return false;
        }
        
        if (angle_count == 0 || angle_count > MessageConstants::MAX_LIDAR_READINGS) {
            return false;
        }
        
        // Validate angle and distance values
        for (int i = 0; i < angle_count; i++) {
            float angle = lidar.angles(i);
            float distance = lidar.distances(i);
            
            if (angle < -M_PI || angle > M_PI) {
                return false;
            }
            
            if (distance < 0.0f || distance > 100.0f) { // Assuming max range of 100m
                return false;
            }
        }
        
        return true;
    }
    
    /**
     * @brief Validate a GyroData message
     * @param gyro GyroData to validate
     * @return true if valid, false otherwise
     */
    inline bool isValidGyroData(const Command::GyroData& gyro) {
        return gyro.has_timestamp() && 
               gyro.has_x() && 
               gyro.has_y() &&
               gyro.x() >= -1000.0f && gyro.x() <= 1000.0f && // Reasonable gyro range
               gyro.y() >= -1000.0f && gyro.y() <= 1000.0f;
    }
    
    /**
     * @brief Validate a Heartbeat message
     * @param heartbeat Heartbeat to validate
     * @return true if valid, false otherwise
     */
    inline bool isValidHeartbeat(const Command::Heartbeat& heartbeat) {
        if (!heartbeat.has_timestamp()) {
            return false;
        }
        
        if (heartbeat.has_client_id() && 
            heartbeat.client_id().length() > MessageConstants::MAX_CLIENT_ID_LENGTH) {
            return false;
        }
        
        return true;
    }
}

/**
 * @brief Message utility functions
 */
namespace MessageUtils {
    
    /**
     * @brief Get the name of a message type
     * @param type MessageType enum value
     * @return String name of the message type
     */
    inline const char* getMessageTypeName(MessageType type) {
        switch (type) {
            case MessageType::MOVE_COMMAND:
                return MessageConstants::MOVE_COMMAND_NAME;
            case MessageType::TELEMETRY_UPDATE:
                return MessageConstants::TELEMETRY_UPDATE_NAME;
            case MessageType::LIDAR_DATA:
                return MessageConstants::LIDAR_DATA_NAME;
            case MessageType::GYRO_DATA:
                return MessageConstants::GYRO_DATA_NAME;
            case MessageType::HEARTBEAT:
                return MessageConstants::HEARTBEAT_NAME;
            default:
                return "Unknown";
        }
    }
    
    /**
     * @brief Get current timestamp in milliseconds
     * @return Current timestamp as int64_t
     */
    inline int64_t getCurrentTimestamp() {
        return std::chrono::duration_cast<std::chrono::milliseconds>(
            std::chrono::system_clock::now().time_since_epoch()).count();
    }
    
    /**
     * @brief Check if a timestamp is recent (within specified milliseconds)
     * @param timestamp Timestamp to check
     * @param max_age_ms Maximum age in milliseconds
     * @return true if timestamp is recent, false otherwise
     */
    inline bool isTimestampRecent(int64_t timestamp, int64_t max_age_ms = 5000) {
        int64_t current_time = getCurrentTimestamp();
        return (current_time - timestamp) <= max_age_ms;
    }
}

} // namespace Spider2
