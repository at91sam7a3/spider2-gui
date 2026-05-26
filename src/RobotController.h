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
    Q_PROPERTY(int trajectoryType READ trajectoryType WRITE setTrajectoryType NOTIFY trajectoryTypeChanged)
    Q_PROPERTY(QVariantMap telemetryData READ telemetryData NOTIFY telemetryDataChanged)
    Q_PROPERTY(LidarController* lidarController READ lidarController NOTIFY lidarControllerChanged)
    Q_PROPERTY(GyroController* gyroController READ gyroController NOTIFY gyroControllerChanged)
    Q_PROPERTY(SlamController* slamController READ slamController NOTIFY slamControllerChanged)
    Q_PROPERTY(bool lidarStreamActive READ lidarStreamActive NOTIFY streamHealthChanged)
    Q_PROPERTY(bool gyroStreamActive READ gyroStreamActive NOTIFY streamHealthChanged)
    Q_PROPERTY(bool slamStreamActive READ slamStreamActive NOTIFY streamHealthChanged)
    Q_PROPERTY(bool sensorsStreamActive READ sensorsStreamActive NOTIFY streamHealthChanged)
    Q_PROPERTY(int videoFrameIndex READ videoFrameIndex NOTIFY videoFrameIndexChanged)
    Q_PROPERTY(bool objectTracking READ objectTracking WRITE setObjectTracking NOTIFY objectTrackingChanged)
    Q_PROPERTY(bool hasBlob READ hasBlob NOTIFY blobDataChanged)
    Q_PROPERTY(float blobX READ blobX NOTIFY blobDataChanged)
    Q_PROPERTY(float blobY READ blobY NOTIFY blobDataChanged)
    Q_PROPERTY(float blobSize READ blobSize NOTIFY blobDataChanged)
    Q_PROPERTY(int blobFrameWidth READ blobFrameWidth NOTIFY blobDataChanged)
    Q_PROPERTY(int blobFrameHeight READ blobFrameHeight NOTIFY blobDataChanged)

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
    int trajectoryType() const { return m_trajectoryType; }
    QVariantMap telemetryData() const { return m_telemetryData; }
    LidarController* lidarController() const { return m_lidarController; }
    GyroController* gyroController() const { return m_gyroController; }
    SlamController* slamController() const { return m_slamController; }
    bool lidarStreamActive() const { return m_lidarStreamActive; }
    bool gyroStreamActive() const { return m_gyroStreamActive; }
    bool slamStreamActive() const { return m_slamStreamActive; }
    bool sensorsStreamActive() const { return m_sensorsStreamActive; }
    int videoFrameIndex() const { return m_videoFrameIndex.load(std::memory_order_relaxed); }
    bool objectTracking() const { return m_objectTracking; }
    bool hasBlob() const { return m_hasBlob; }
    float blobX() const { return m_blobX; }
    float blobY() const { return m_blobY; }
    float blobSize() const { return m_blobSize; }
    int blobFrameWidth() const { return m_blobFrameWidth; }
    int blobFrameHeight() const { return m_blobFrameHeight; }

public slots:
    void setServerIp(const QString &ip);
    void setForwardSpeed(float speed);
    void setStrafeSpeed(float speed);
    void setRotationSpeed(float speed);
    void setHeight(float height);
    void setWalkingStyle(int style);
    void setTrajectoryType(int type);
    void setVideoProvider(VideoProvider *provider);
    void setMapProvider(MapProvider *provider);
    void connectToRobot();
    void disconnectFromRobot();
    /// @brief Broadcast servo torque on/off to all servos (id=254)
    Q_INVOKABLE void setServoTorque(bool enabled);
    /// @brief Send move-to-point command for autonomous navigation
    Q_INVOKABLE void sendMoveToPoint(float target_x_mm, float target_y_mm, float tolerance_mm = 50.0f);
    /// @brief Enable/disable object tracking
    Q_INVOKABLE void setObjectTracking(bool enabled);
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
    void trajectoryTypeChanged();
    void telemetryDataChanged();
    void lidarControllerChanged();
    void gyroControllerChanged();
    void slamControllerChanged();
    void streamHealthChanged();
    void videoFrameIndexChanged();
    void objectTrackingChanged();
    void blobDataChanged();
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
    int m_trajectoryType{0};  // 0 = LinearSine (default), 1 = Cycloid

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

    // Object tracking
    bool m_objectTracking{false};
    bool m_hasBlob{false};
    float m_blobX{0.0f};
    float m_blobY{0.0f};
    float m_blobSize{0.0f};
    int m_blobFrameWidth{0};
    int m_blobFrameHeight{0};
    
    // Data statistics (bytes/messages per second)
    QTimer *m_statisticsTimer{nullptr};
    std::atomic<uint64_t> m_bytesReceivedCounter{0};
    std::atomic<uint64_t> m_messagesReceivedCounter{0};
};
