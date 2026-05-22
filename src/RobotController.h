#pragma once

#include <QObject>
#include <QString>
#include <QVariantMap>
#include <QTimer>
#include <memory>
#include <zmq.hpp>
#include <thread>
#include <atomic>
#include <string>
#include <unordered_map>
#include <vector>
#include <utility>
#include "MessageTypes.hpp"
#include "LidarController.h"
#include "GyroController.h"
#include "SlamController.h"

class VideoProvider;
class MapProvider;

class RobotController : public QObject
{
    Q_OBJECT

    // Properties exposed to QML
    Q_PROPERTY(QString serverIp READ serverIp WRITE setServerIp NOTIFY serverIpChanged)
    Q_PROPERTY(bool connected READ connected NOTIFY connectedChanged)
    Q_PROPERTY(float forwardSpeed READ forwardSpeed WRITE setForwardSpeed NOTIFY forwardSpeedChanged)
    Q_PROPERTY(float strafeSpeed READ strafeSpeed WRITE setStrafeSpeed NOTIFY strafeSpeedChanged)
    Q_PROPERTY(float rotationSpeed READ rotationSpeed WRITE setRotationSpeed NOTIFY rotationSpeedChanged)
    Q_PROPERTY(float height READ height WRITE setHeight NOTIFY heightChanged)
    Q_PROPERTY(int walkingStyle READ walkingStyle WRITE setWalkingStyle NOTIFY walkingStyleChanged)
    Q_PROPERTY(QVariantMap telemetryData READ telemetryData NOTIFY telemetryDataChanged)
    Q_PROPERTY(LidarController* lidarController READ lidarController NOTIFY lidarControllerChanged)
    Q_PROPERTY(GyroController* gyroController READ gyroController NOTIFY gyroControllerChanged)
    Q_PROPERTY(SlamController* slamController READ slamController NOTIFY slamControllerChanged)
    Q_PROPERTY(bool lidarStreamActive READ lidarStreamActive NOTIFY streamHealthChanged)
    Q_PROPERTY(bool gyroStreamActive READ gyroStreamActive NOTIFY streamHealthChanged)
    Q_PROPERTY(bool slamStreamActive READ slamStreamActive NOTIFY streamHealthChanged)
    Q_PROPERTY(bool sensorsStreamActive READ sensorsStreamActive NOTIFY streamHealthChanged)
    Q_PROPERTY(int videoFrameIndex READ videoFrameIndex NOTIFY videoFrameIndexChanged)

public:
    explicit RobotController(QObject *parent = nullptr);
    ~RobotController();

    // Property getters
    QString serverIp() const { return m_serverIp; }
    bool connected() const { return m_connected; }
    float forwardSpeed() const { return m_forwardSpeed; }
    float strafeSpeed() const { return m_strafeSpeed; }
    float rotationSpeed() const { return m_rotationSpeed; }
    float height() const { return m_height; }
    int walkingStyle() const { return m_walkingStyle; }
    QVariantMap telemetryData() const { return m_telemetryData; }
    LidarController* lidarController() const { return m_lidarController; }
    GyroController* gyroController() const { return m_gyroController; }
    SlamController* slamController() const { return m_slamController; }
    bool lidarStreamActive() const { return m_lidarStreamActive; }
    bool gyroStreamActive() const { return m_gyroStreamActive; }
    bool slamStreamActive() const { return m_slamStreamActive; }
    bool sensorsStreamActive() const { return m_sensorsStreamActive; }
    int videoFrameIndex() const { return m_videoFrameIndex.load(std::memory_order_relaxed); }

public slots:
    void setServerIp(const QString &ip);
    void setForwardSpeed(float speed);
    void setStrafeSpeed(float speed);
    void setRotationSpeed(float speed);
    void setHeight(float height);
    void setWalkingStyle(int style);
    void setVideoProvider(VideoProvider *provider);
    void setMapProvider(MapProvider *provider);
    void connectToRobot();
    void disconnectFromRobot();
    /// @brief Broadcast servo torque on/off to all servos (id=254)
    Q_INVOKABLE void setServoTorque(bool enabled);
    /// @brief Send move-to-point command for autonomous navigation
    Q_INVOKABLE void sendMoveToPoint(float target_x_mm, float target_y_mm, float tolerance_mm = 50.0f);
    /// @brief Request robot state transition
    Q_INVOKABLE void sendStateChange(const QString &state);

signals:
    void serverIpChanged();
    void connectedChanged();
    void forwardSpeedChanged();
    void strafeSpeedChanged();
    void rotationSpeedChanged();
    void heightChanged();
    void walkingStyleChanged();
    void telemetryDataChanged();
    void lidarControllerChanged();
    void gyroControllerChanged();
    void slamControllerChanged();
    void streamHealthChanged();
    void videoFrameIndexChanged();
    void connectionError(const QString &error);

private slots:
    void sendHeartbeat();
    void updateStreamHealth();
    void updateDataStatistics();

private:
    void markLidarReceived();
    void markGyroReceived();
    void markSlamReceived();
    void markSensorsReceived();
    void resetStreamHealth();
    static bool isVoltageTelemetry(const QString &name);
    void startCommunicationThread();
    void stopCommunicationThread();
    void communicationLoop();
    void sendMessage(Spider2::MessageType type, const google::protobuf::Message &message);
    void dispatchMessage(uint8_t type, const std::string &data);
    void updateTelemetry(const Command::TelemetryUpdate &telemetry);

    // ZeroMQ components
    std::unique_ptr<zmq::context_t> m_context;
    std::unique_ptr<zmq::socket_t> m_socket;
    std::thread m_communicationThread;
    std::atomic<bool> m_running{false};

    // Connection state
    QString m_serverIp;
    bool m_connected{false};

    // Robot state
    float m_forwardSpeed{0.0f};
    float m_strafeSpeed{0.0f};
    float m_rotationSpeed{0.0f};
    float m_height{50.0f};   // robot default body height in mm
    int m_walkingStyle{1};

    // Telemetry data
    QVariantMap m_telemetryData;

    // Lidar controller
    LidarController *m_lidarController;

    // Gyro controller
    GyroController *m_gyroController;

    // Slam controller
    SlamController *m_slamController;

    // Video provider
    VideoProvider *m_videoProvider{nullptr};

    // Map provider
    MapProvider *m_mapProvider{nullptr};

    // Heartbeat timer
    QTimer *m_heartbeatTimer;

    // Stream health (green if data received within last 1s)
    static constexpr int STREAM_TIMEOUT_MS = 1000;
    QTimer *m_streamHealthTimer{nullptr};
    std::atomic<qint64> m_lastLidarMs{0};
    std::atomic<qint64> m_lastGyroMs{0};
    std::atomic<qint64> m_lastSlamMs{0};
    std::atomic<qint64> m_lastSensorsMs{0};
    bool m_lidarStreamActive{false};
    bool m_gyroStreamActive{false};
    bool m_slamStreamActive{false};
    bool m_sensorsStreamActive{false};
    std::atomic<int> m_videoFrameIndex{0};
    
    // Data statistics (bytes/messages per second)
    QTimer *m_statisticsTimer{nullptr};
    std::atomic<uint64_t> m_bytesReceivedCounter{0};
    std::atomic<uint64_t> m_messagesReceivedCounter{0};
};
