@echo off
setlocal enabledelayedexpansion

REM Install Conan deps for a Qt Creator build directory.
REM Usage:
REM   qtcreator_setup.bat Release "D:\petprojects\spider2-gui\build\Desktop_Qt_6_8_0_MSVC2022_64bit-Release"
REM   qtcreator_setup.bat Debug   "D:\petprojects\spider2-gui\build\Desktop_Qt_6_8_0_MSVC2022_64bit-Debug"

set "BUILD_TYPE=%~1"
set "OUTPUT_DIR=%~2"

if "%BUILD_TYPE%"=="" set "BUILD_TYPE=Debug"
if "%OUTPUT_DIR%"=="" (
    echo Usage: qtcreator_setup.bat [Debug^|Release] [output-folder]
    echo Example: qtcreator_setup.bat Release build\Desktop_Qt_6_8_0_MSVC2022_64bit-Release
    exit /b 1
)

if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

echo [INFO] Conan install: build_type=%BUILD_TYPE% output=%OUTPUT_DIR%
conan2 install "%~dp0" -s build_type=%BUILD_TYPE% --output-folder="%OUTPUT_DIR%" --build=missing
if errorlevel 1 exit /b 1

echo.
echo [SUCCESS] conan_toolchain.cmake is in: %OUTPUT_DIR%
echo.
echo In Qt Creator - Projects - Build - CMake:
echo   Generator: Visual Studio 17 2022  (not Ninja)
echo   Add to Initial Parameters:
echo     -DCMAKE_TOOLCHAIN_FILE=%OUTPUT_DIR%\conan_toolchain.cmake
echo.
echo Re-run CMake configure after changing the generator.

endlocal
