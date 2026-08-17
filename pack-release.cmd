@echo off
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0pack-release.ps1"
exit /b %ERRORLEVEL%
