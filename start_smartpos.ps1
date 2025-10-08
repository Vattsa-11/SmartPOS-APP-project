# PowerShell Script to start SmartPOS Application
Write-Host "Starting SmartPOS Application..." -ForegroundColor Cyan
Write-Host ""
Write-Host "This script will start both the FastAPI backend and Flutter frontend." -ForegroundColor Cyan
Write-Host ""

# Define paths
$backendPath = "D:\SRI\Sri works\APP project\smartpos\backend"
$frontendPath = "D:\SRI\Sri works\APP project\smartpos\frontend"

# Check if Python is installed
try {
    python --version | Out-Null
    Write-Host "✓ Python is installed." -ForegroundColor Green
} catch {
    Write-Host "❌ Python is not installed or not in the PATH." -ForegroundColor Red
    Write-Host "Please install Python and try again." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit
}

# Check if Flutter is installed
try {
    flutter --version | Out-Null
    Write-Host "✓ Flutter is installed." -ForegroundColor Green
} catch {
    Write-Host "❌ Flutter is not installed or not in the PATH." -ForegroundColor Red
    Write-Host "Please install Flutter and try again." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit
}

# Check if directories exist
if (-Not (Test-Path $backendPath)) {
    Write-Host "❌ Backend directory not found: $backendPath" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit
}

if (-Not (Test-Path $frontendPath)) {
    Write-Host "❌ Frontend directory not found: $frontendPath" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit
}

# Function to start a process in a new window
function Start-ProcessInNewWindow {
    param (
        [string]$Title,
        [string]$WorkingDirectory,
        [string]$Command,
        [string]$Arguments
    )
    
    Start-Process -FilePath $Command -ArgumentList $Arguments -WorkingDirectory $WorkingDirectory -WindowStyle Normal
}

# Start backend server
Write-Host "[1/2] Starting FastAPI backend server..." -ForegroundColor Yellow
Write-Host "Starting simplified API on port 8001..." -ForegroundColor Cyan
Start-ProcessInNewWindow -Title "SmartPOS Backend" -WorkingDirectory $backendPath -Command "powershell" -Arguments "-Command `"& {cd '$backendPath'; python simple_api.py; Read-Host 'Press Enter to close this window'}`""

# Wait for backend to start
Write-Host "Waiting for backend server to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 8

# Install Flutter dependencies
Write-Host "Installing Flutter dependencies..." -ForegroundColor Yellow
Set-Location $frontendPath
flutter pub get | Out-Null

# Start frontend server
Write-Host "[2/2] Starting Flutter frontend..." -ForegroundColor Yellow
Write-Host "Starting Flutter web application..." -ForegroundColor Cyan
Start-ProcessInNewWindow -Title "SmartPOS Frontend" -WorkingDirectory $frontendPath -Command "powershell" -Arguments "-Command `"& {cd '$frontendPath'; flutter run -d chrome --web-hostname=127.0.0.1 --web-port=5001; Read-Host 'Press Enter to close this window'}`""

Write-Host ""
Write-Host "SmartPOS is now running!" -ForegroundColor Green
Write-Host ""
Write-Host "Backend API: http://127.0.0.1:8001" -ForegroundColor Cyan
Write-Host "API Documentation: http://127.0.0.1:8001/docs" -ForegroundColor Cyan
Write-Host "Frontend App: http://127.0.0.1:5001" -ForegroundColor Cyan
Write-Host ""
Write-Host "Close this window when you're done to stop both servers." -ForegroundColor Yellow
Write-Host ""
