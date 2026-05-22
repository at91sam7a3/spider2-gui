@echo off
setlocal enabledelayedexpansion

REM Spider2 GUI Deploy Script
REM Creates a deployment folder with all necessary files to run the application

echo.
echo ===============================================
echo      CREATING DEPLOYMENT FOLDER
echo ===============================================
echo.

REM --- Configuration ---
set "QT_VERSION=6.8.0"
set "QT_PATH=C:\Qt\%QT_VERSION%\msvc2022_64"
set "WINDEPLOYQT=%QT_PATH%\bin\windeployqt.exe"
set "BUILD_DIR=%~dp0build\debug\Debug"
set "DEPLOY_DIR=%~dp0deploy"
set "EXE_FILE=%BUILD_DIR%\spider2-gui.exe"

REM Check if executable exists
if not exist "%EXE_FILE%" (
    echo [ERROR] Executable not found at: %EXE_FILE%
    echo Please run build.bat first!
    exit /b 1
)

REM Create deploy directory
if exist "%DEPLOY_DIR%" (
    echo [INFO] Removing old deploy directory...
    rmdir /s /q "%DEPLOY_DIR%"
)

mkdir "%DEPLOY_DIR%"
echo [INFO] Created deploy directory: %DEPLOY_DIR%

REM Copy executable
echo.
echo [INFO] Copying executable...
copy "%EXE_FILE%" "%DEPLOY_DIR%\spider2-gui.exe" >nul
if !ERRORLEVEL! neq 0 (
    echo [ERROR] Failed to copy executable
    exit /b 1
)
echo [SUCCESS] Executable copied

REM Use windeployqt to deploy Qt dependencies
echo.
echo [INFO] Running windeployqt to deploy Qt libraries and plugins...
"%WINDEPLOYQT%" "%DEPLOY_DIR%\spider2-gui.exe" --debug --force --qmldir %~dp0res\qml
if !ERRORLEVEL! neq 0 (
    echo [WARNING] windeployqt had issues, but continuing...
)
echo [SUCCESS] Qt libraries deployed

REM Copy QML resources if they exist
if exist "%~dp0res\qml" (
    echo.
    echo [INFO] Copying QML resources...
    xcopy /Y /S "%~dp0res\qml\*" "%DEPLOY_DIR%\qml\" >nul 2>&1
)

REM Create a simple README for deployment
echo.
echo [INFO] Creating README...
(
    echo Spider2 GUI Application Deployment
    echo ====================================
    echo.
    echo To run the application:
    echo   1. Navigate to this directory
    echo   2. Double-click spider2-gui.exe
    echo.
    echo Files included:
    echo   - spider2-gui.exe: Main application executable
    echo   - Qt6*.dll: Qt6 runtime libraries
    echo   - platforms/: Qt platform plugins
    echo   - plugins/: Qt plugins
    echo   - imageformats/: Image format support
    echo   - translations/: Language translations
    echo   - generic/, tls/, etc.: Additional Qt modules
    echo.
    echo Requirements:
    echo   - Windows 10 or later
    echo   - Visual C++ Runtime (should already be installed)
    echo.
) > "%DEPLOY_DIR%\README.txt"

echo.
echo ===============================================
echo      DEPLOYMENT COMPLETED SUCCESSFULLY
echo ===============================================
echo.
echo Deployed files are in: %DEPLOY_DIR%
echo Total files: 
for /f %%A in ('dir /s /b "%DEPLOY_DIR%" ^| find /c /v ""') do echo   %%A files
echo.
echo To run the application:
echo   cd %DEPLOY_DIR%
echo   spider2-gui.exe
echo.

endlocal

