param(
    [string]$ApiBaseUrl = "http://10.0.2.2:8000/api/v1"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Push-Location "$PSScriptRoot\..\mobile"
try {
    flutter pub get
    flutter run --dart-define="API_BASE_URL=$ApiBaseUrl"
}
finally {
    Pop-Location
}
