@echo off
REM Spider2 GUI - Archive Deployment Package
REM Creates a ZIP file of the deployment folder for easy distribution

setlocal enabledelayedexpansion

echo.
echo ===============================================
echo    ARCHIVING DEPLOYMENT PACKAGE
echo ===============================================
echo.

set "DEPLOY_DIR=%~dp0deploy"
set "OUTPUT_ZIP=%~dp0spider2-gui-deployment.zip"

if not exist "%DEPLOY_DIR%" (
    echo [ERROR] Deploy directory not found!
    echo Please run deploy.bat first
    exit /b 1
)

echo [INFO] Creating archive: %OUTPUT_ZIP%

REM Use PowerShell to create ZIP (available on Windows 10+)
powershell -NoProfile -Command "Compress-Archive -Path '%DEPLOY_DIR%' -DestinationPath '%OUTPUT_ZIP%' -Force" 2>nul

if !ERRORLEVEL! equ 0 (
    echo [SUCCESS] Archive created successfully!
    echo.
    echo File: %OUTPUT_ZIP%
    for /f %%A in ('dir /-C "%OUTPUT_ZIP%" ^| find "spider2-gui-deployment.zip"') do (
        echo Size: %%~zA
    )
) else (
    echo [ERROR] Failed to create archive
    echo Make sure PowerShell Compress-Archive is available
    exit /b 1
)

echo.
