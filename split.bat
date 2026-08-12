@echo off
REM Double-click this. It runs split.ps1 without you having to fight ExecutionPolicy.
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0split.ps1"
echo.
pause
