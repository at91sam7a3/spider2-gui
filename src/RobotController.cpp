#include "RobotController.h"
#include <QDebug>
#include <QThread>
#include <QCoreApplication>
#include <zmq.hpp>
#include <zmq_addon.hpp>
#include "command.pb.h"
#include "LidarDataModel.h"
#include "GyroDataModel.h"

RobotController::RobotController(QObject *parent)
    : QObject(parent)
    , m_context(std::make_unique<zmq::context_t>(1))
    , m_lidarController(new LidarController(this))
    , m_gyroController(new GyroController(this))
    , m_heartbeatTimer(new QTimer(this))
{
    m_heartbeatTimer->setInterval(1000); // Send heartbeat every second
    connect(m_heartbeatTimer, &QTimer::timeout, this, &RobotController::sendHeartbeat);
}

RobotController::~RobotController()
{
    disconnectFromRobot();
}

void RobotController::setServerIp(const QString &ip)
{
    if (m_serverIp != ip) {
        m_serverIp = ip;
        emit serverIpChanged();
    }
}

void RobotController::setForwardSpeed(float speed)
{
    if (qAbs(m_forwardSpeed - speed) > 0.001f) {
        m_forwardSpeed = qBound(-1.0f, speed, 1.0f);
        emit forwardSpeedChanged();
        
        if (m_connected) {
            auto cmd = Spider2::MessageFactory::createMoveCommand(m_forwardSpeed, m_strafeSpeed, m_rotationSpeed);
            sendMessage(Spider2::MessageType::MOVE_COMMAND, cmd);
        }
    }
}

void RobotController::setStrafeSpeed(float speed)
{
    if (qAbs(m_strafeSpeed - speed) > 0.001f) {
        m_strafeSpeed = qBound(-1.0f, speed, 1.0f);
        emit strafeSpeedChanged();
        
        if (m_connected) {
            auto cmd = Spider2::MessageFactory::createMoveCommand(m_forwardSpeed, m_strafeSpeed, m_rotationSpeed);
            sendMessage(Spider2::MessageType::MOVE_COMMAND, cmd);
        }
    }
}

void RobotController::setRotationSpeed(float speed)
{
    if (qAbs(m_rotationSpeed - speed) > 0.001f) {
        m_rotationSpeed = qBound(-1.0f, speed, 1.0f);
        emit rotationSpeedChanged();
        
        if (m_connected) {
            auto cmd = Spider2::MessageFactory::createMoveCommand(m_forwardSpeed, m_strafeSpeed, m_rotationSpeed);
            sendMessage(Spider2::MessageType::MOVE_COMMAND, cmd);
        }
    }
}

void RobotController::setHeight(float height)
{
    if (qAbs(m_height - height) > 0.001f) {
        m_height = height;
        emit heightChanged();
        
        if (m_connected) {
            Command::HeightCommand cmd;
            cmd.set_height(m_height);
            sendMessage(Spider2::MessageType::HEIGHT_COMMAND, cmd);
        }
    }
}

void RobotController::setWalkingStyle(int style)
{
    if (m_walkingStyle != style && style >= 1 && style <= 3) {
        m_walkingStyle = style;
        emit walkingStyleChanged();
        
        if (m_connected) {
            Command::WalkingStyleCommand cmd;
            cmd.set_style(m_walkingStyle);
            sendMessage(Spider2::MessageType::WALKING_STYLE_COMMAND, cmd);
        }
    }
}

void RobotController::connectToRobot()
{
    if (m_serverIp.isEmpty()) {
        emit connectionError("Server IP address is required");
        return;
    }

    try {
        m_socket = std::make_unique<zmq::socket_t>(*m_context, ZMQ_DEALER);
        m_socket->set(zmq::sockopt::linger, 0);
        
        QString connectionString = QString("tcp://%1:5555").arg(m_serverIp);
        m_socket->connect(connectionString.toStdString());
        
        m_connected = true;
        emit connectedChanged();
        
        startCommunicationThread();
        m_heartbeatTimer->start();
        
        qDebug() << "Connected to robot at" << m_serverIp;
        
    } catch (const zmq::error_t &e) {
        emit connectionError(QString("Failed to connect: %1").arg(e.what()));
        qDebug() << "Connection error:" << e.what();
    }
}

void RobotController::disconnectFromRobot()
{
    if (m_connected) {
        m_heartbeatTimer->stop();
        stopCommunicationThread();
        
        if (m_socket) {
            m_socket->close();
            m_socket.reset();
        }
        
        m_connected = false;
        emit connectedChanged();
        
        qDebug() << "Disconnected from robot";
    }
}

void RobotController::sendHeartbeat()
{
    if (m_connected) {
        auto heartbeat = Spider2::MessageFactory::createHeartbeat("spider2-gui");
        sendMessage(Spider2::MessageType::HEARTBEAT, heartbeat);
    }
}

void RobotController::startCommunicationThread()
{
    m_running = true;
    m_communicationThread = std::thread(&RobotController::communicationLoop, this);
}

void RobotController::stopCommunicationThread()
{
    m_running = false;
    if (m_communicationThread.joinable()) {
        m_communicationThread.join();
    }
}

void RobotController::communicationLoop()
{
    zmq::pollitem_t items[] = {
        { *m_socket, 0, ZMQ_POLLIN, 0 }
    };

    while (m_running) {
        try {
            zmq::poll(items, 1, std::chrono::milliseconds(100));
            
            if (items[0].revents & ZMQ_POLLIN) {
                zmq::message_t message;
                auto result = m_socket->recv(message, zmq::recv_flags::dontwait);
                
                if (result) {
                    processIncomingMessage(message);
                }
            }
        } catch (const zmq::error_t &e) {
            if (e.num() != ETERM) {
                qDebug() << "Communication error:" << e.what();
            }
            break;
        }
    }
}

void RobotController::sendMessage(Spider2::MessageType type, const google::protobuf::Message &message)
{
    if (!m_connected || !m_socket) {
        return;
    }

    try {
        // Serialize protobuf message
        std::string serialized;
        message.SerializeToString(&serialized);
        
        // Create ZeroMQ message with type byte + protobuf data
        zmq::message_t zmqMessage(serialized.size() + 1);
        char *data = static_cast<char*>(zmqMessage.data());
        data[0] = static_cast<uint8_t>(type);
        std::memcpy(data + 1, serialized.data(), serialized.size());
        
        m_socket->send(zmqMessage, zmq::send_flags::dontwait);
        
    } catch (const zmq::error_t &e) {
        qDebug() << "Failed to send message:" << e.what();
    } catch (const std::exception &e) {
        qDebug() << "Failed to serialize message:" << e.what();
    }
}

void RobotController::processIncomingMessage(const zmq::message_t &message)
{
    if (message.size() < 1) {
        return;
    }

    const char *data = static_cast<const char*>(message.data());
    uint8_t messageType = static_cast<uint8_t>(data[0]);
    
    // Handle VIDEO_FRAME specially (no protobuf)
    if (messageType == static_cast<uint8_t>(Spider2::MessageType::VIDEO_FRAME)) {
        // For now, we don't process video frames
        // In the future, this would update the VideoProvider
        return;
    }
    
    // Process protobuf messages
    std::string protobufData(data + 1, message.size() - 1);
    
    switch (static_cast<Spider2::MessageType>(messageType)) {
        case Spider2::MessageType::TELEMETRY_UPDATE: {
            Command::TelemetryUpdate telemetry;
            if (telemetry.ParseFromString(protobufData)) {
                updateTelemetry(telemetry);
            }
            break;
        }
        case Spider2::MessageType::LIDAR_DATA: {
            Command::LidarData lidar;
            if (lidar.ParseFromString(protobufData)) {
                // Convert protobuf data to LidarPoint vector
                QVector<LidarPoint> points;
                int count = std::min(lidar.angles_size(), lidar.distances_size());
                
                for (int i = 0; i < count; i++) {
                    points.append(LidarPoint(lidar.angles(i), lidar.distances(i)));
                }
                
                // Update lidar controller
                m_lidarController->updateLidarData(points);
                
                // Store lidar data in telemetry
                QVariantMap lidarData;
                lidarData["timestamp"] = static_cast<qint64>(lidar.timestamp());
                lidarData["angle_count"] = lidar.angles_size();
                lidarData["distance_count"] = lidar.distances_size();
                m_telemetryData["lidar"] = lidarData;
                emit telemetryDataChanged();
            }
            break;
        }
        case Spider2::MessageType::GYRO_DATA: {
            Command::GyroData gyro;
            if (gyro.ParseFromString(protobufData)) {
                // Update gyro controller
                m_gyroController->updateGyroData(gyro.x(), gyro.y(), 0.0f, gyro.timestamp());
                
                // Store gyro data in telemetry
                QVariantMap gyroData;
                gyroData["timestamp"] = static_cast<qint64>(gyro.timestamp());
                gyroData["x"] = gyro.x();
                gyroData["y"] = gyro.y();
                m_telemetryData["gyro"] = gyroData;
                emit telemetryDataChanged();
            }
            break;
        }
        default:
            qDebug() << "Unknown message type:" << messageType;
            break;
    }
}

void RobotController::updateTelemetry(const Command::TelemetryUpdate &telemetry)
{
    QString name = QString::fromStdString(telemetry.name());
    
    if (telemetry.has_fvalue()) {
        m_telemetryData[name] = telemetry.fvalue();
    } else if (telemetry.has_svalue()) {
        m_telemetryData[name] = QString::fromStdString(telemetry.svalue());
    } else if (telemetry.has_bvalue()) {
        m_telemetryData[name] = telemetry.bvalue();
    } else if (telemetry.has_ivalue()) {
        m_telemetryData[name] = telemetry.ivalue();
    }
    
    emit telemetryDataChanged();
}
