@echo off
rem Installs the app on the phone to talk to the PC over Wi-Fi. Bypasses the script execution policy for this script only.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tool\run_on_wifi.ps1" %*
