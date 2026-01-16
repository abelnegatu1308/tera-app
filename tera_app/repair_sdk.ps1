# Helper script to repair corrupted Flutter SDK core file
Write-Host "Repairing Flutter SDK: scaffold.dart..." -ForegroundColor Cyan

$sdkPath = "C:\src\flutter\flutter"
$scaffoldFile = "packages/flutter/lib/src/material/scaffold.dart"

if (Test-Path $sdkPath) {
    Set-Location $sdkPath
    git checkout $scaffoldFile
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Successfully restored scaffold.dart!" -ForegroundColor Green
    } else {
        Write-Host "Failed to restore using git. Attempting flutter doctor..." -ForegroundColor Yellow
        flutter doctor
    }
} else {
    Write-Host "Error: Could not find Flutter SDK at $sdkPath" -ForegroundColor Red
}

Write-Host "Done. Please try building your project again." -ForegroundColor Cyan
