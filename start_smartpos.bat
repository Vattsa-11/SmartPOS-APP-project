@echo off
echo Starting SmartPOS Application...
echo.
echo This script will start both the FastAPI backend and Flutter frontend.
echo.

:: Define paths
set BACKEND_PATH=D:\SRI\Sri works\APP project\smartpos\backend
set FRONTEND_PATH=D:\SRI\Sri works\APP project\smartpos\frontend

:: Check if Python is installed
python --version > nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Python is not installed or not in the PATH.
    echo Please install Python and try again.
    goto :error
)

:: Check if Flutter is installed
flutter --version > nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Flutter is not installed or not in the PATH.
    echo Please install Flutter and try again.
    goto :error
)

:: Check if directories exist
if not exist "%BACKEND_PATH%" (
    echo Backend directory not found: %BACKEND_PATH%
    goto :error
)

if not exist "%FRONTEND_PATH%" (
    echo Frontend directory not found: %FRONTEND_PATH%
    goto :error
)

echo [1/2] Starting FastAPI backend server...
echo Starting simplified API on port 8001...
start "SmartPOS Backend" cmd.exe /k "cd /d %BACKEND_PATH% && python simple_api.py"

:: Wait for backend to start
echo Waiting for backend server to start...
timeout /t 8 /nobreak > nul

echo [2/2] Starting Flutter frontend...
echo Installing Flutter dependencies...
cd /d %FRONTEND_PATH%
flutter pub get > nul 2>&1

echo Starting Flutter web application...
start "SmartPOS Frontend" cmd.exe /k "cd /d %FRONTEND_PATH% && flutter run -d chrome --web-hostname=127.0.0.1 --web-port=5001"

echo.
echo SmartPOS is now running!
echo.
echo Backend API: http://127.0.0.1:8001
echo API Documentation: http://127.0.0.1:8001/docs
echo Frontend App: http://127.0.0.1:5001
echo.
echo Close this window when you're done to stop both servers.
echo.
goto :eof

:error
echo.
echo An error occurred while starting the application.
echo Please check the error message above and try again.
pause
