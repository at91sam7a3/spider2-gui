#include "RobotController.h"
#include <QDebug>
#include <QThread>
#include <QCoreApplication>
#include <QDateTime>
#include <QSettings>
#include <zmq.hpp>
#include <zmq_addon.hpp>
#include "command.pb.h"
#include "LidarDataModel.h"
#include "GyroDataModel.h"
#include "SlamController.h"
#include "MapProvider.h"
#include "VideoProvider.h"

RobotController::RobotController(QObject *parent)
    : QObject(parent)
    , m_context(std::make_unique<zmq::context_t>(1))
    , m_lidarController(new LidarController(this))
    , m_gyroController(new GyroController(this))
    , m_slamController(new SlamController(this))
    , m_heartbeatTimer(new QTimer(this))
{
    m_heartbeatTimer->setInterval(1000); // Send heartbeat every second
    connect(m_heartbeatTimer, &QTimer::timeout, this, &RobotController::sendHeartbeat);

    m_streamHealthTimer = new QTimer(this);
    m_streamHealthTimer->setInterval(200);
    connect(m_streamHealthTimer, &QTimer::timeout, this, &RobotController::updateStreamHealth);
    m_streamHealthTimer->start();
    
    // Data statistics timer: update every 1 second
    m_statisticsTimer = new QTimer(this);
    m_statisticsTimer->setInterval(1000);
    connect(m_statisticsTimer, &QTimer::timeout, this, &RobotController::updateDataStatistics);
    m_statisticsTimer->start();

    loadRecentServerIps();
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
        m_forwardSpeed = qBound(-10.0f, speed, 10.0f);  // Range: -10.0 to 10.0 m/s
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
        m_strafeSpeed = qBound(-10.0f, speed, 10.0f);  // Range: -10.0 to 10.0 m/s
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
        m_rotationSpeed = qBound(-3.0f, speed, 3.0f);  // Range: -3.0 to 3.0
        emit rotationSpeedChanged();
        
        if (m_connected) {
            auto cmd = Spider2::MessageFactory::createMoveCommand(m_forwardSpeed, m_strafeSpeed, m_rotationSpeed);
            sendMessage(Spider2::MessageType::MOVE_COMMAND, cmd);
        }
    }
}

void RobotController::setHeight(float height)
{
    if (qAbs(m_height - height) > 0.1f) {
        m_height = qBound(40.0f, height, 150.0f);  // Range: 40..150 mm
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

void RobotController::setTrajectoryType(int type)
{
    if (m_trajectoryType != type && type >= 0 && type <= 1) {
        m_trajectoryType = type;
        emit trajectoryTypeChanged();
        
        if (m_connected) {
            auto cmd = Spider2::MessageFactory::createTrajectoryCommand(type);
            sendMessage(Spider2::MessageType::TRAJECTORY_COMMAND, cmd);
        }
    }
}

void RobotController::setBodyPitch(float angle)
{
    if (qAbs(m_bodyPitch - angle) > 0.01f) {
        m_bodyPitch = qBound(-30.0f, angle, 30.0f);
        emit bodyPitchChanged();
        
        if (m_connected) {
            Command::PitchCommand cmd;
            cmd.set_angle_deg(m_bodyPitch);
            sendMessage(Spider2::MessageType::PITCH_COMMAND, cmd);
        }
    }
}

void RobotController::setBodyRoll(float angle)
{
    if (qAbs(m_bodyRoll - angle) > 0.01f) {
        m_bodyRoll = qBound(-30.0f, angle, 30.0f);
        emit bodyRollChanged();
        
        if (m_connected) {
            Command::RollCommand cmd;
            cmd.set_angle_deg(m_bodyRoll);
            sendMessage(Spider2::MessageType::ROLL_COMMAND, cmd);
        }
    }
}

void RobotController::setVideoProvider(VideoProvider *provider)
{
    m_videoProvider = provider;
}

void RobotController::setMapProvider(MapProvider *provider)
{
    m_mapProvider = provider;
    if (m_slamController)
        m_slamController->setMapProvider(provider);
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
        resetStreamHealth();
        emit connectedChanged();
        
        addToRecentServerIps(m_serverIp);
        startCommunicationThread();
        m_heartbeatTimer->start();
        
        qInfo() << "[ROBOT] Connected to" << m_serverIp;

    } catch (const zmq::error_t &e) {
        emit connectionError(QString("Failed to connect: %1").arg(e.what()));
        qWarning() << "[ROBOT] Connection error:" << e.what();
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
        resetStreamHealth();
        emit connectedChanged();
        
        qInfo() << "[ROBOT] Disconnected";
    }
}

void RobotController::setObjectTracking(bool enabled)
{
    if (!m_connected) return;
    m_objectTracking = enabled;
    emit objectTrackingChanged();

    Command::BlobTrackingCommand cmd;
    cmd.set_enabled(enabled);
    sendMessage(Spider2::MessageType::OBJECT_TRACKING_COMMAND, cmd);
    qInfo() << "[ROBOT] Object tracking" << (enabled ? "ON" : "OFF") << "sent";
}

void RobotController::setServoTorque(bool enabled)
{
    if (!m_connected) return;

    Command::ServoTorqueCommand cmd;
    cmd.set_enabled(enabled);
    sendMessage(Spider2::MessageType::SERVO_TORQUE_COMMAND, cmd);
    qInfo() << "[ROBOT] Servo torque" << (enabled ? "ON" : "OFF") << "sent";
}

void RobotController::sendMoveToPoint(float target_x_mm, float target_y_mm, float tolerance_mm)
{
    if (!m_connected) return;
    auto cmd = Spider2::MessageFactory::createMoveToPointCommand(target_x_mm, target_y_mm, tolerance_mm);
    sendMessage(Spider2::MessageType::MOVE_TO_POINT_COMMAND, cmd);
    qInfo() << "[ROBOT] MoveToPoint sent: (" << target_x_mm << "," << target_y_mm << ")";
}

void RobotController::sendStateChange(const QString &state)
{
    if (!m_connected) return;
    auto cmd = Spider2::MessageFactory::createRobotStateChange(state.toStdString());
    sendMessage(Spider2::MessageType::ROBOT_STATE_CHANGE, cmd);
    qInfo() << "[ROBOT] State change sent:" << state;
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
    // Stream message types: only the LATEST received matters for display.
    // When a backlog builds up, we drain all queued messages and throw away
    // everything except the most recent one of each stream type.
    auto isStream = [](uint8_t t) -> bool {
        return t == static_cast<uint8_t>(Spider2::MessageType::LIDAR_DATA)
            || t == static_cast<uint8_t>(Spider2::MessageType::GYRO_DATA)
            || t == static_cast<uint8_t>(Spider2::MessageType::VIDEO_FRAME)
            || t == static_cast<uint8_t>(Spider2::MessageType::TELEMETRY_UPDATE)
            || t == static_cast<uint8_t>(Spider2::MessageType::SLAM_POSE)
            || t == static_cast<uint8_t>(Spider2::MessageType::SLAM_MAP)
            || t == static_cast<uint8_t>(Spider2::MessageType::OBJECT_TRACKING_DATA);
    };

    zmq::pollitem_t items[] = {{ *m_socket, 0, ZMQ_POLLIN, 0 }};

    while (m_running) {
        try {
            // Block until at least one message arrives (or timeout for heartbeat check)
            zmq::poll(items, 1, std::chrono::milliseconds(100));
            if (!(items[0].revents & ZMQ_POLLIN)) continue;

            // Drain ALL queued messages in one tight non-blocking loop.
            // Stream messages: overwrite with latest (old frames simply discarded).
            // Non-stream messages (heartbeat etc.): keep all in order.
            std::unordered_map<uint8_t, std::string> latest;
            std::vector<std::pair<uint8_t, std::string>> ordered;

            while (true) {
                zmq::message_t type_msg;
                if (!m_socket->recv(type_msg, zmq::recv_flags::dontwait)) break;
                if (type_msg.size() != 1) break;

                zmq::message_t data_msg;
                if (!m_socket->recv(data_msg, zmq::recv_flags::dontwait)) break;

                uint8_t t = *static_cast<const uint8_t*>(type_msg.data());
                std::string d(static_cast<const char*>(data_msg.data()), data_msg.size());
                
                // Track bytes and messages received for statistics
                m_bytesReceivedCounter.fetch_add(d.size(), std::memory_order_relaxed);
                m_messagesReceivedCounter.fetch_add(1, std::memory_order_relaxed);

                if (isStream(t)) {
                    latest[t] = std::move(d);      // overwrite: keep only newest
                } else {
                    ordered.emplace_back(t, std::move(d));
                }
            }

            // Process non-stream messages first (heartbeats, acks …)
            for (auto &[t, d] : ordered)
                dispatchMessage(t, d);

            // Process one (the latest) message per stream type
            for (auto &[t, d] : latest)
                dispatchMessage(t, d);

        } catch (const zmq::error_t &e) {
            if (e.num() != ETERM)
                qWarning() << "[ROBOT] Communication error:" << e.what();
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
        
        // Send message type first (DEALER socket automatically adds identity)
        uint8_t type_byte = static_cast<uint8_t>(type);
        zmq::message_t type_msg(&type_byte, 1);
        m_socket->send(type_msg, zmq::send_flags::sndmore);
        
        // Send message data second
        zmq::message_t data_msg(serialized.data(), serialized.size());
        m_socket->send(data_msg, zmq::send_flags::dontwait);
        
    } catch (const zmq::error_t &e) {
        qWarning() << "[ROBOT] Send error:" << e.what();
    } catch (const std::exception &e) {
        qWarning() << "[ROBOT] Serialize error:" << e.what();
    }
}

void RobotController::dispatchMessage(uint8_t messageType, const std::string &rawData)
{
    // Handle VIDEO_FRAME specially (raw JPEG wrapped in protobuf)
    if (messageType == static_cast<uint8_t>(Spider2::MessageType::VIDEO_FRAME)) {
        try {
            Command::VideoFrame videoFrame;
            const std::string &frameData = rawData;
            
            if (videoFrame.ParseFromString(frameData)) {
                // Create QImage from JPEG data
                QByteArray jpegData(videoFrame.data().data(), videoFrame.data().size());
                QImage image = QImage::fromData(jpegData, "JPEG");
                
                if (!image.isNull()) {
                    // Marshal frame update and counter increment to the GUI thread
                    QMetaObject::invokeMethod(this, [this, image]() {
                        if (m_videoProvider) {
                            m_videoProvider->updateVideoFrame(image);
                        }
                        m_videoFrameIndex.fetch_add(1, std::memory_order_relaxed);
                        emit videoFrameIndexChanged();
                    }, Qt::QueuedConnection);
                } else {
                    qWarning() << "[VIDEO] Failed to decode JPEG data (" << jpegData.size() << "bytes)";
                }
            }
            } catch (const std::exception &e) {
            qWarning() << "[VIDEO] Error processing frame:" << e.what();
        }
        return;
    }
    
    // Process protobuf messages
    const std::string &protobufData = rawData;
    
    switch (static_cast<Spider2::MessageType>(messageType)) {
        case Spider2::MessageType::TELEMETRY_UPDATE: {
            Command::TelemetryUpdate telemetry;
            if (telemetry.ParseFromString(protobufData)) {
                // Copy by value so the lambda captures a self-contained object
                QMetaObject::invokeMethod(this, [this, telemetry]() {
                    updateTelemetry(telemetry);
                }, Qt::QueuedConnection);
            }
            break;
        }
        case Spider2::MessageType::LIDAR_DATA: {
            Command::LidarData lidar;
            if (lidar.ParseFromString(protobufData)) {
                const int nPts = lidar.angles_size();
                if (nPts >= 1 && nPts == lidar.distances_size()) {
                    // Collect valid points; zero/out-of-range distances mean no return
                    QVector<LidarPoint> points;
                    points.reserve(nPts);
                    for (int i = 0; i < nPts; ++i) {
                        float distance = lidar.distances(i);
                        if (distance >= 0.1f && distance <= 10.0f) {
                            points.append(LidarPoint(lidar.angles(i), distance));
                        }
                    }

                    const qint64 ts = static_cast<qint64>(lidar.timestamp());
                    QMetaObject::invokeMethod(this, [this, points, ts, nPts]() {
                        if (!points.isEmpty()) {
                            m_lidarController->updateLidarData(points);
                            markLidarReceived();
                        } else {
                            qWarning() << "[LIDAR] all" << nPts << "points filtered out";
                        }
                        QVariantMap lidarData;
                        lidarData["timestamp"] = ts;
                        lidarData["point_count"] = points.size();
                        m_telemetryData["lidar"] = lidarData;
                        emit telemetryDataChanged();
                    }, Qt::QueuedConnection);
                } else {
                    qWarning() << "LIDAR: malformed message — angles:" << nPts
                               << "distances:" << lidar.distances_size();
                }
            } else {
                qWarning() << "LIDAR: failed to parse protobuf";
            }
            break;
        }
        case Spider2::MessageType::GYRO_DATA: {
            Command::GyroData gyro;
            if (gyro.ParseFromString(protobufData)) {
                const float gx = gyro.x();
                const float gy = gyro.y();
                const qint64 ts = static_cast<qint64>(gyro.timestamp());
                QMetaObject::invokeMethod(this, [this, gx, gy, ts]() {
                    // Z-axis is not in the protocol; use 0.0
                    m_gyroController->updateGyroData(gx, gy, 0.0f, ts);
                    markGyroReceived();
                    QVariantMap gyroData;
                    gyroData["timestamp"] = ts;
                    gyroData["x"] = gx;
                    gyroData["y"] = gy;
                    m_telemetryData["gyro"] = gyroData;
                    emit telemetryDataChanged();
                }, Qt::QueuedConnection);
            }
            break;
        }
        case Spider2::MessageType::HEARTBEAT: {
            break;
        }
        case Spider2::MessageType::SLAM_POSE: {
            Command::SlamPose slamPose;
            if (slamPose.ParseFromString(protobufData)) {
                const double x = slamPose.x_mm();
                const double y = slamPose.y_mm();
                const double theta = slamPose.theta_deg();
                QMetaObject::invokeMethod(this, [this, x, y, theta]() {
                    m_slamController->updatePose(x, y, theta);
                    markSlamReceived();
                }, Qt::QueuedConnection);
            }
            break;
        }
        case Spider2::MessageType::MOVE_TO_POINT_COMMAND: {
            // Acknowledge — handled server-side, no local processing needed
            break;
        }
        case Spider2::MessageType::ROBOT_STATE_CHANGE: {
            // Robot will confirm state change via TELEMETRY_UPDATE robot_state
            break;
        }
        case Spider2::MessageType::SLAM_MAP: {
            Command::SlamMap slamMap;
            if (slamMap.ParseFromString(protobufData)) {
                const int szPx = slamMap.size_pixels();
                const double szM = slamMap.size_meters();
                const std::string &raw = slamMap.data();
                QByteArray data(raw.data(), static_cast<int>(raw.size()));
                QMetaObject::invokeMethod(this, [this, szPx, szM, data]() {
                    m_slamController->updateMap(szPx, szM, data);
                    markSlamReceived();
                }, Qt::QueuedConnection);
            }
            break;
        }
        case Spider2::MessageType::OBJECT_TRACKING_DATA: {
            Command::BlobTrackingData blob;
            if (blob.ParseFromString(protobufData)) {
                QMetaObject::invokeMethod(this, [this, blob]() {
                    m_hasBlob = blob.blob_size() > 0.001f;
                    m_blobX = blob.blob_x();
                    m_blobY = blob.blob_y();
                    m_blobSize = blob.blob_size();
                    m_blobFrameWidth = blob.frame_width();
                    m_blobFrameHeight = blob.frame_height();
                    emit blobDataChanged();
                }, Qt::QueuedConnection);
            }
            break;
        }
        default:
            qWarning() << "[ROBOT] Unknown message type:" << messageType;
            break;
    }
}

bool RobotController::isVoltageTelemetry(const QString &name)
{
    return name.compare(QStringLiteral("battery_voltage"), Qt::CaseInsensitive) == 0
        || name.contains(QStringLiteral("voltage"), Qt::CaseInsensitive);
}

void RobotController::markLidarReceived()
{
    m_lastLidarMs.store(QDateTime::currentMSecsSinceEpoch(), std::memory_order_relaxed);
    QMetaObject::invokeMethod(this, &RobotController::updateStreamHealth, Qt::QueuedConnection);
}

void RobotController::markGyroReceived()
{
    m_lastGyroMs.store(QDateTime::currentMSecsSinceEpoch(), std::memory_order_relaxed);
    QMetaObject::invokeMethod(this, &RobotController::updateStreamHealth, Qt::QueuedConnection);
}

void RobotController::markSlamReceived()
{
    m_lastSlamMs.store(QDateTime::currentMSecsSinceEpoch(), std::memory_order_relaxed);
    QMetaObject::invokeMethod(this, &RobotController::updateStreamHealth, Qt::QueuedConnection);
}

void RobotController::markSensorsReceived()
{
    m_lastSensorsMs.store(QDateTime::currentMSecsSinceEpoch(), std::memory_order_relaxed);
    QMetaObject::invokeMethod(this, &RobotController::updateStreamHealth, Qt::QueuedConnection);
}

void RobotController::resetStreamHealth()
{
    m_lastLidarMs.store(0, std::memory_order_relaxed);
    m_lastGyroMs.store(0, std::memory_order_relaxed);
    m_lastSlamMs.store(0, std::memory_order_relaxed);
    m_lastSensorsMs.store(0, std::memory_order_relaxed);

    const bool changed = m_lidarStreamActive || m_gyroStreamActive
                         || m_slamStreamActive || m_sensorsStreamActive;
    m_lidarStreamActive = false;
    m_gyroStreamActive = false;
    m_slamStreamActive = false;
    m_sensorsStreamActive = false;
    if (changed) {
        emit streamHealthChanged();
    }
}

void RobotController::updateStreamHealth()
{
    const qint64 now = QDateTime::currentMSecsSinceEpoch();
    bool changed = false;

    auto updateOne = [&](std::atomic<qint64> &lastMs, bool &active) {
        const qint64 last = lastMs.load(std::memory_order_relaxed);
        const bool shouldBeActive = last > 0 && (now - last) < STREAM_TIMEOUT_MS;
        if (active != shouldBeActive) {
            active = shouldBeActive;
            changed = true;
        }
    };

    updateOne(m_lastLidarMs, m_lidarStreamActive);
    updateOne(m_lastGyroMs, m_gyroStreamActive);
    updateOne(m_lastSlamMs, m_slamStreamActive);
    updateOne(m_lastSensorsMs, m_sensorsStreamActive);

    if (changed) {
        emit streamHealthChanged();
    }
}

void RobotController::updateDataStatistics()
{
    // Get current counters and reset them for next second
    uint64_t bytesReceived = m_bytesReceivedCounter.exchange(0, std::memory_order_relaxed);
    uint64_t messagesReceived = m_messagesReceivedCounter.exchange(0, std::memory_order_relaxed);
    
    // Update telemetry with current per-second statistics
    QMetaObject::invokeMethod(this, [this, bytesReceived, messagesReceived]() {
        m_telemetryData["bytes_received_per_sec"] = static_cast<qulonglong>(bytesReceived);
        m_telemetryData["messages_received_per_sec"] = static_cast<qulonglong>(messagesReceived);
        emit telemetryDataChanged();
    }, Qt::QueuedConnection);
}

void RobotController::updateTelemetry(const Command::TelemetryUpdate &telemetry)
{
    QString name = QString::fromStdString(telemetry.name());

    if (isVoltageTelemetry(name)) {
        markSensorsReceived();
    }
    
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

void RobotController::loadRecentServerIps()
{
    QSettings settings("Spider2", "spider2-gui");
    m_recentServerIps = settings.value("recentServerIps").toStringList();
    
    if (m_recentServerIps.isEmpty()) {
        m_recentServerIps << "spider.local";
    }
    emit recentServerIpsChanged();
}

void RobotController::saveRecentServerIps()
{
    QSettings settings("Spider2", "spider2-gui");
    settings.setValue("recentServerIps", m_recentServerIps);
}

void RobotController::addToRecentServerIps(const QString &ip)
{
    if (ip.isEmpty()) return;
    
    m_recentServerIps.removeAll(ip);
    m_recentServerIps.prepend(ip);
    
    while (m_recentServerIps.size() > 10) {
        m_recentServerIps.removeLast();
    }
    
    saveRecentServerIps();
    emit recentServerIpsChanged();
}

void RobotController::clearRecentServerIps()
{
    m_recentServerIps.clear();
    m_recentServerIps << "spider.local";
    saveRecentServerIps();
    emit recentServerIpsChanged();
}

void RobotController::resetImu()
{
    if (!m_connected) return;
    Command::ResetImu cmd;
    cmd.set_timestamp(QDateTime::currentMSecsSinceEpoch());
    sendMessage(Spider2::MessageType::RESET_IMU, cmd);
    qInfo() << "[ROBOT] Reset IMU sent";
}
