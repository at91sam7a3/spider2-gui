#pragma once

#include <QObject>
#include <QString>
#include <QVariantMap>
#include <QTimer>
#include <memory>
#include <zmq.hpp>
#include <thread>
#include <atomic>
#include "MessageTypes.hpp"

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

public slots:
    void setServerIp(const QString &ip);
    void setForwardSpeed(float speed);
    void setStrafeSpeed(float speed);
    void setRotationSpeed(float speed);
    void setHeight(float height);
    void setWalkingStyle(int style);
    void connectToRobot();
    void disconnectFromRobot();

signals:
    void serverIpChanged();
    void connectedChanged();
    void forwardSpeedChanged();
    void strafeSpeedChanged();
    void rotationSpeedChanged();
    void heightChanged();
    void walkingStyleChanged();
    void telemetryDataChanged();
    void connectionError(const QString &error);

private slots:
    void sendHeartbeat();

private:
    void startCommunicationThread();
    void stopCommunicationThread();
    void communicationLoop();
    void sendMessage(Spider2::MessageType type, const google::protobuf::Message &message);
    void processIncomingMessage(const zmq::message_t &message);
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
    float m_height{50.0f};
    int m_walkingStyle{1};

    // Telemetry data
    QVariantMap m_telemetryData;

    // Heartbeat timer
    QTimer *m_heartbeatTimer;
};
