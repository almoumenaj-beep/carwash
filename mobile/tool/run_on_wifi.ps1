# Installs the app on the phone so that it talks to the Laravel server over Wi-Fi: once installed, the cable
# can be unplugged and the app keeps working while the phone and the PC are on the same network.
# Usage (from the project root): .\mobile\run-on-wifi
# The server must listen on the network: php artisan serve --host=0.0.0.0 --port=8000
# Extra arguments are passed to `flutter run`.

$sdk = if ($env:ANDROID_HOME) { $env:ANDROID_HOME } else { "$env:LOCALAPPDATA\Android\Sdk" }
if (-not $env:JAVA_HOME) { $env:JAVA_HOME = 'C:\src\jdk-21' }

$env:Path = @(
    'C:\src\flutter\bin',
    "$sdk\platform-tools",
    [Environment]::GetEnvironmentVariable('Path', 'User'),
    [Environment]::GetEnvironmentVariable('Path', 'Machine')
) -join ';'

# The PC's address on the Wi-Fi (virtual adapters such as VMware's are skipped).
$ip = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
    Where-Object { $_.InterfaceAlias -match 'Wi-?Fi|WLAN|Wireless' -and $_.IPAddress -notlike '169.254.*' } |
    Select-Object -First 1 -ExpandProperty IPAddress
if (-not $ip) {
    Write-Host 'The PC is not on a Wi-Fi network.' -ForegroundColor Yellow
    exit 1
}

$apiBaseUrl = "http://${ip}:8000/api/v1"

try {
    Invoke-WebRequest -UseBasicParsing -TimeoutSec 3 "http://${ip}:8000/up" | Out-Null
} catch {
    Write-Host "The Laravel server cannot be reached at http://${ip}:8000." -ForegroundColor Yellow
    Write-Host 'Stop it and start it for the network: php artisan serve --host=0.0.0.0 --port=8000' -ForegroundColor Yellow
    exit 1
}

$phones = adb devices | Select-String "`tdevice$"
if (-not $phones) {
    Write-Host 'No phone found. Connect it by USB once (or pair it for wireless debugging) to install the app.' -ForegroundColor Yellow
    exit 1
}

Write-Host "The app will use $apiBaseUrl. After it starts you can unplug the cable." -ForegroundColor Green
Write-Host "If the phone cannot connect, allow port 8000 in the Windows firewall (see docs/PROJECT_PLAN.md)." -ForegroundColor DarkGray

Set-Location (Split-Path $PSScriptRoot)
flutter run --dart-define=API_BASE_URL=$apiBaseUrl @args
