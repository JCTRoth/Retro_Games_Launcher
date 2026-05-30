@echo off
setlocal EnableExtensions DisableDelayedExpansion

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0create_launchers.ps1" %*
set "EXIT_CODE=%ERRORLEVEL%"

if not "%EXIT_CODE%"=="0" (
    echo Launcher generation failed with exit code %EXIT_CODE%.
)

exit /b %EXIT_CODE%

