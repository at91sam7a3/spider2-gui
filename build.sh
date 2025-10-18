#!/bin/bash

# Spider2 GUI Build Script
# This script sets up the build environment and compiles the Qt QML C++ application

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in the right directory
if [ ! -f "conanfile.txt" ]; then
    print_error "conanfile.txt not found. Please run this script from the project root directory."
    exit 1
fi

# Check for required tools
print_status "Checking for required tools..."

# Check for conan
if ! command -v conan &> /dev/null; then
    print_error "Conan is not installed. Please install Conan first:"
    echo "pip install conan"
    exit 1
fi

# Check for cmake
if ! command -v cmake &> /dev/null; then
    print_error "CMake is not installed. Please install CMake first."
    exit 1
fi

# Check for Qt6
if ! command -v qmake6 &> /dev/null && ! command -v qmake &> /dev/null; then
    print_warning "Qt6 qmake not found in PATH. Make sure Qt6 is installed and properly configured."
fi

print_success "All required tools found."

# Clean previous builds
print_status "Cleaning previous builds..."
rm -rf build/
rm -rf bin/
mkdir -p build
mkdir -p bin

# Configure Conan 2 for x86_64 (override any previous aarch64 configuration)
print_status "Configuring Conan 2 for x86_64..."

# Check if default profile exists, create if it doesn't
if ! conan profile show -pr default > /dev/null 2>&1; then
    print_status "Creating default profile..."
    conan profile detect --name default
else
    print_status "Using existing default profile..."
fi

# Check current profile architecture
CURRENT_PROFILE=$(conan profile show -pr default | grep "arch=" | head -1 | cut -d'=' -f2 || echo "unknown")
print_status "Current Conan profile architecture: $CURRENT_PROFILE"

if [ "$CURRENT_PROFILE" != "x86_64" ]; then
    print_warning "Conan profile is not set to x86_64. Please manually update your profile:"
    echo "conan profile detect --name default"
    echo "Then edit ~/.conan2/profiles/default to ensure arch=x86_64"
    exit 1
else
    print_success "Conan profile is correctly set to x86_64"
fi

# Install Conan dependencies
print_status "Installing Conan dependencies..."
cd build
conan install .. --build=missing --update --output-folder=.

if [ $? -ne 0 ]; then
    print_error "Failed to install Conan dependencies"
    exit 1
fi

print_success "Conan dependencies installed successfully."

# Configure CMake
print_status "Configuring CMake..."
cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_TOOLCHAIN_FILE=conan_toolchain.cmake

if [ $? -ne 0 ]; then
    print_error "CMake configuration failed"
    exit 1
fi

print_success "CMake configuration completed."

# Build the project
print_status "Building the project..."
cmake --build . --config Release --parallel $(nproc)

if [ $? -ne 0 ]; then
    print_error "Build failed"
    exit 1
fi

print_success "Build completed successfully!"

# Copy executable to bin directory
print_status "Copying executable to bin directory..."
cp spider2-gui ../bin/

# Check if executable was created
if [ -f "../bin/spider2-gui" ]; then
    print_success "Executable created: bin/spider2-gui"
    
    # Show file info
    print_status "Executable information:"
    ls -la ../bin/spider2-gui
    file ../bin/spider2-gui
else
    print_error "Executable not found after build"
    exit 1
fi

# Return to project root
cd ..

print_success "Build process completed successfully!"
print_status "You can now run the application with: ./bin/spider2-gui"

# Optional: Run the application
read -p "Do you want to run the application now? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Starting Spider2 GUI..."
    ./bin/spider2-gui
fi
