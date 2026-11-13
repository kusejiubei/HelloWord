@echo off
setlocal
title GitHub520 hosts updater

rem ---- self-elevate to administrator ----
net session >nul 2>&1
if not errorlevel 1 goto run

echo Requesting administrator privileges, please click "Yes" in the UAC dialog...
powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
exit /b

:run
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0update-github-hosts.ps1"
echo.
pause
