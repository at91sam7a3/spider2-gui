echo -------BUILDING DEBUG------------
@echo off
setlocal
echo ------- BUILDING DEBUG ------------
echo ------- BUILDING DEBUG (Conan 2) ------------

:: --- Configuration ---
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

echo Assuming that QT installation path is: %default_qt_install_prefix%
echo [INFO] Using Qt: %qt_install_prefix%

if not exist build mkdir build
cd build 
if not exist debug mkdir debug
cd debug
if not exist deploy mkdir deploy

:: Initialize MSVC environment
if not defined DevEnvDir (
    echo [INFO] Initializing MSVC environment...
    call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat" amd64
)
set "PATH=%NINJA_PATH%;%qt_install_prefix%\bin;%PATH%"

:: Run conan to install dependencies
echo [INFO] Installing dependencies via Conan...
conan2 install ../.. --output-folder=. --build=missing -s build_type=Debug
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Conan installation failed.
    exit /b %ERRORLEVEL%
)

:: Configure and Build
echo [INFO] Configuring CMake...
"%CMAKE_EXE%" -S ../.. -B . -G "Ninja" ^
    -DCMAKE_BUILD_TYPE=Debug ^
    -DCMAKE_PREFIX_PATH="%qt_install_prefix%" ^
    -DCMAKE_TOOLCHAIN_FILE="conan_toolchain.cmake" ^
    -DBUILD_NUMBER="%BUILD_NUMBER%" ^
    -DCMAKE_INSTALL_PREFIX="./deploy"

if %ERRORLEVEL% neq 0 (
    echo [ERROR] CMake configuration failed.
    exit /b %ERRORLEVEL%
)

echo [INFO] Building...
"%CMAKE_EXE%" --build . --parallel
echo [INFO] Installing...
"%CMAKE_EXE%" --install .

:: Optional: Copy demo libs
set "MIRASPEC_DEMO_LIBS=C:\build\DemoLibraries"
if exist "%MIRASPEC_DEMO_LIBS%" (
    echo Copying demo libraries to deploy\demoLibraries ...
    xcopy "%MIRASPEC_DEMO_LIBS%\*" "%CD%\deploy\demoLibraries\" /E /I /Y
) else (
    echo Demo libraries not found at %MIRASPEC_DEMO_LIBS%, skipping.
)

cd ..\..

cd ..
echo -----done-----
endlocal