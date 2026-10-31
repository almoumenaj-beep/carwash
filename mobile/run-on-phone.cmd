@echo off
rem Runs the app on the USB-connected phone. Bypasses the script execution policy for this script only.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tool\run_on_phone.ps1" %*
