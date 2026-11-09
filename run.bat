@echo off
chcp 65001 > nul
echo Pattern English 앱을 시작합니다...
powershell -ExecutionPolicy Bypass -File "%~dp0server.ps1"
pause
