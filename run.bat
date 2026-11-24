@echo off
title Email Validator
cd /d "%~dp0"

echo =========================================================
echo                 Email Validator - FastAPI
echo =========================================================
echo.

if not exist ".venv\Scripts\python.exe" (
    echo Creating virtual environment...
    python -m venv .venv
    if errorlevel 1 (
        echo Could not create the virtual environment. Is Python 3.10+ installed?
        pause
        exit /b 1
    )
)

call ".venv\Scripts\activate.bat"

python -c "import fastapi, uvicorn, dns, openpyxl, multipart, motor, pymongo, dotenv" >nul 2>&1
if errorlevel 1 (
    echo Installing requirements, please wait...
    python -m pip install --upgrade pip >nul
    python -m pip install -r requirements.txt
    if errorlevel 1 (
        echo Installation failed. See the messages above.
        pause
        exit /b 1
    )
)

set APP_PORT=8000
if exist ".env" (
    for /f "usebackq tokens=1,2 delims==" %%A in (".env") do (
        if /i "%%A"=="PORT" set APP_PORT=%%B
    )
)

echo.
echo Starting server at http://127.0.0.1:%APP_PORT%
echo Keep this window open while you use the app. Press Ctrl+C to stop.
echo.
start "" cmd /c "timeout /t 3 >nul & start http://127.0.0.1:%APP_PORT%"
python -m uvicorn app.main:app --host 127.0.0.1 --port %APP_PORT%
pause
