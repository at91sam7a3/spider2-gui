#include "VideoProvider.h"
#include <QMutexLocker>
#include <QPainter>
#include <QDebug>
#include <QColor>

VideoProvider::VideoProvider(QObject *parent)
    : QQuickImageProvider(QQuickImageProvider::Image)
{
    // Create initial green rectangle stub
    m_currentFrame = QImage(640, 480, QImage::Format_RGB32);
    m_currentFrame.fill(QColor(0, 128, 0)); // Green background
    
    // Add some text to indicate it's a stub
    QPainter painter(&m_currentFrame);
    painter.setPen(Qt::white);
    painter.setFont(QFont("Arial", 24, QFont::Bold));
    painter.drawText(m_currentFrame.rect(), Qt::AlignCenter, "VIDEO STUB\nGreen Rectangle");
}

QImage VideoProvider::requestImage(const QString &id, QSize *size, const QSize &requestedSize)
{
    Q_UNUSED(id)
    
    QMutexLocker locker(&m_frameMutex);
    
    QImage frame = m_currentFrame;
    
    if (size) {
        *size = frame.size();
    }
    
    // Scale if requested size is different
    if (requestedSize.isValid() && requestedSize != frame.size()) {
        frame = frame.scaled(requestedSize, Qt::KeepAspectRatio, Qt::SmoothTransformation);
    }
    
    return frame;
}

void VideoProvider::updateVideoFrame(const QImage &frame)
{
    QMutexLocker locker(&m_frameMutex);
    m_currentFrame = frame;
    emit frameUpdated();
}

QColor VideoProvider::pixelAt(int x, int y)
{
    QMutexLocker locker(&m_frameMutex);
    if (x < 0 || x >= m_currentFrame.width() || y < 0 || y >= m_currentFrame.height())
        return QColor();
    QRgb rgb = m_currentFrame.pixel(x, y);
    return QColor(rgb);
}
