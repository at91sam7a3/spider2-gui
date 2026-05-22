@echo off
setlocal enabledelayedexpansion

REM Spider2 GUI Build Script for Windows with Qt 6.8.0
REM This script builds the project with Conan2, CMake, and Ninja

echo.
echo ===============================================
echo      BUILDING DEBUG WITH CONAN 2 AND CMAKE
echo ===============================================
echo.

REM --- Configuration ---
set "QT_VERSION=6.8.0"
set "CMAKE_EXE=C:\Qt\Tools\CMake_64\bin\cmake.exe"
set "NINJA_PATH=C:\Qt\Tools\Ninja"
set "default_qt_install_prefix=C:\Qt\%QT_VERSION%\msvc2022_64"

REM Check if a parameter was provided
if "%~1"=="" (
    set "qt_install_prefix=%default_qt_install_prefix%"
) else (
    set "qt_install_prefix=%~1"
)

echo [INFO] Qt installation path: %qt_install_prefix%

REM Check if Qt installation exists
if not exist "%qt_install_prefix%" (
    echo [ERROR] Qt installation not found at: %qt_install_prefix%
    exit /b 1
)

REM Create build directory structure
if not exist build (
    mkdir build
    echo [INFO] Created build directory
)
cd build
if not exist debug (
    mkdir debug
    echo [INFO] Created debug directory
)
cd debug

REM Initialize MSVC environment if needed
if not defined DevEnvDir (
    echo [INFO] Initializing MSVC environment...
    call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat" amd64
    if !ERRORLEVEL! neq 0 (
        echo [ERROR] Failed to initialize MSVC environment
        exit /b 1
    )
)

REM Add tools to PATH
set "PATH=%NINJA_PATH%;%qt_install_prefix%\bin;%PATH%"

REM Step 1: Install dependencies via Conan
echo.
echo [INFO] ===== STEP 1: Installing dependencies via Conan =====
echo [INFO] Running: conan2 install ../.. -s build_type=Debug --output-folder=. --build=missing
conan2 install ../.. -s build_type=Debug --output-folder=. --build=missing
if !ERRORLEVEL! neq 0 (
    echo [ERROR] Conan installation failed with error code !ERRORLEVEL!
    exit /b !ERRORLEVEL!
)
echo [SUCCESS] Dependencies installed

REM Step 2: Configure CMake
echo.
echo [INFO] ===== STEP 2: Configuring CMake =====
echo [INFO] Running CMake configuration...
"%CMAKE_EXE%" -S ../.. -B . -G "Visual Studio 17 2022" -A x64 ^
    -DCMAKE_PREFIX_PATH="%qt_install_prefix%" ^
    -DCMAKE_TOOLCHAIN_FILE="conan_toolchain.cmake" ^
    -DCMAKE_FIND_DEBUG_MODE=OFF
if !ERRORLEVEL! neq 0 (
    echo [ERROR] CMake configuration failed with error code !ERRORLEVEL!
    exit /b !ERRORLEVEL!
)
echo [SUCCESS] CMake configuration completed

REM Step 3: Build the project
echo.
echo [INFO] ===== STEP 3: Building the project =====
echo [INFO] Running: cmake --build . --config Debug
cmake --build . --config Debug --parallel %NUMBER_OF_PROCESSORS%
if !ERRORLEVEL! neq 0 (
    echo [ERROR] Build failed with error code !ERRORLEVEL!
    exit /b !ERRORLEVEL!
)
echo [SUCCESS] Build completed successfully

echo.
echo ===============================================
echo      BUILD COMPLETED SUCCESSFULLY
echo ===============================================
echo.
echo Output executable should be available in: build\debug\
echo.

cd ../..
endlocal
