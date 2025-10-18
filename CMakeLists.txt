cmake_minimum_required(VERSION 3.20)

project(spider2-gui VERSION 1.0.0 LANGUAGES CXX)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find required packages
find_package(Qt6 REQUIRED COMPONENTS Core Quick Gui QuickControls2 QuickTemplates2)
find_package(Protobuf REQUIRED)
find_package(PkgConfig REQUIRED)

# Enable Qt6 automatic MOC, UIC, and RCC
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTORCC ON)

# Include Conan generated files
include(${CMAKE_BINARY_DIR}/conan_toolchain.cmake)

# Find Conan packages
find_package(ZeroMQ REQUIRED)
find_package(cppzmq REQUIRED)
find_package(protobuf REQUIRED)

# Protobuf configuration
set(PROTOBUF_GENERATE_CPP_APPEND_PATH TRUE)

# Generate protobuf files
set(PROTO_SOURCES "")
set(PROTO_HEADERS "")

get_filename_component(PROTO_FILE "${CMAKE_CURRENT_SOURCE_DIR}/src/command.proto" ABSOLUTE)
get_filename_component(PROTO_NAME "${PROTO_FILE}" NAME_WE)
get_filename_component(PROTO_PATH "${PROTO_FILE}" PATH)

set(PROTO_SRCS "${CMAKE_CURRENT_BINARY_DIR}/${PROTO_NAME}.pb.cc")
set(PROTO_HDRS "${CMAKE_CURRENT_BINARY_DIR}/${PROTO_NAME}.pb.h")

add_custom_command(
    OUTPUT "${PROTO_SRCS}" "${PROTO_HDRS}"
    COMMAND protobuf::protoc
    ARGS --cpp_out=${CMAKE_CURRENT_BINARY_DIR}
         --proto_path=${PROTO_PATH}
         ${PROTO_FILE}
    DEPENDS ${PROTO_FILE}
    COMMENT "Generating C++ code from ${PROTO_FILE}"
    VERBATIM
)

# Create protobuf library
add_library(protobuf_generated STATIC ${PROTO_SRCS} ${PROTO_HDRS})
target_link_libraries(protobuf_generated protobuf::libprotobuf)
target_include_directories(protobuf_generated PUBLIC ${CMAKE_CURRENT_BINARY_DIR})

# QML files - we'll handle them differently
set(QML_FILES
    res/qml/MainSimple.qml
    res/qml/LidarDisplay.qml
    res/qml/GyroDisplay.qml
)

# Source files
set(SOURCES
    src/main.cpp
    src/RobotController.cpp
    src/VideoProvider.cpp
    src/LidarController.cpp
    src/LidarDataModel.cpp
    src/GyroController.cpp
    src/GyroDataModel.cpp
)

set(HEADERS
    src/RobotController.h
    src/VideoProvider.h
    src/MessageTypes.hpp
    src/LidarController.h
    src/LidarDataModel.h
    src/GyroController.h
    src/GyroDataModel.h
)

# Create executable
qt6_add_executable(spider2-gui ${SOURCES} ${HEADERS})

# Add QML files as resources
qt6_add_resources(spider2-gui "qml_resources"
    PREFIX "/spider2-gui"
    FILES ${QML_FILES}
)

# Link libraries
target_link_libraries(spider2-gui PRIVATE
    Qt6::Core
    Qt6::Quick
    Qt6::Gui
    Qt6::QuickControls2
    Qt6::QuickTemplates2
    protobuf_generated
    protobuf::libprotobuf
    libzmq-static
    cppzmq
)

# Include directories
target_include_directories(spider2-gui PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_BINARY_DIR}
)

# Set target properties
set_target_properties(spider2-gui PROPERTIES
    WIN32_EXECUTABLE TRUE
    MACOSX_BUNDLE TRUE
)

# Install rules
install(TARGETS spider2-gui
    BUNDLE DESTINATION .
    RUNTIME DESTINATION bin
)

# Print configuration info
message(STATUS "Qt6 version: ${Qt6_VERSION}")
message(STATUS "Protobuf version: ${Protobuf_VERSION}")
message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")
message(STATUS "C++ standard: ${CMAKE_CXX_STANDARD}")
