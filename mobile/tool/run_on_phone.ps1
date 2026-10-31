# Runs the app on the USB-connected phone against the local Laravel server.
# Usage (from the project root): .\mobile\run-on-phone
# Extra arguments are passed to `flutter run`, e.g. .\mobile\run-on-phone --release

$sdk = if ($env:ANDROID_HOME) { $env:ANDROID_HOME } else { "$env:LOCALAPPDATA\Android\Sdk" }
if (-not $env:JAVA_HOME) { $env:JAVA_HOME = 'C:\src\jdk-21' }

# Terminals opened before the SDKs were installed miss them on PATH, so add them explicitly.
$env:Path = @(
    'C:\src\flutter\bin',
    "$sdk\platform-tools",
    [Environment]::GetEnvironmentVariable('Path', 'User'),
    [Environment]::GetEnvironmentVariable('Path', 'Machine')
) -join ';'

try {
    Invoke-WebRequest -UseBasicParsing -TimeoutSec 3 http://127.0.0.1:8000/up | Out-Null
} catch {
    Write-Host 'The Laravel server is not running. In another terminal, run: php artisan serve' -ForegroundColor Yellow
    exit 1
}

$phones = adb devices | Select-String "`tdevice$"
if (-not $phones) {
    Write-Host 'No phone found. Connect it by USB (File transfer mode) and allow USB debugging on its screen.' -ForegroundColor Yellow
    adb devices
    exit 1
}

# The phone reaches the PC's port 8000 through the cable. Unplugging the cable clears this.
adb reverse tcp:8000 tcp:8000 | Out-Null
Write-Host 'Phone linked to http://127.0.0.1:8000. Starting the app...' -ForegroundColor Green

Set-Location (Split-Path $PSScriptRoot)
flutter run @args
