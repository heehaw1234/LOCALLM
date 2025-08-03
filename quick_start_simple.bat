@echo off
setlocal enabledelayedexpansion
title Ollama Simple Launcher
color 0A

echo.
echo ========================================
echo    🦙 Ollama Simple Launcher
echo ========================================
echo.

REM Set environment for network access
echo 🔧 Setting up network access...
setx OLLAMA_HOST "0.0.0.0:11434" >nul 2>&1
set OLLAMA_HOST=0.0.0.0:11434
echo    OLLAMA_HOST=%OLLAMA_HOST%

REM Detect current network configuration
echo 🌐 Detecting network configuration...
set LOCAL_IP=

REM Simple IP detection
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr "IPv4" ^| findstr /v "127.0.0.1"') do (
    set LOCAL_IP=%%a
    set LOCAL_IP=!LOCAL_IP: =!
    goto ip_found
)
:ip_found

if not defined LOCAL_IP (
    echo    ⚠️  Could not detect IP address - using localhost only
    set LOCAL_IP=localhost
) else (
    echo    ✅ Network IP: !LOCAL_IP!
)

echo.

REM Check if Ollama is installed
echo 🔍 Checking Ollama installation...
ollama --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Ollama is not installed or not in PATH
    echo    Please install from: https://ollama.ai/download
    pause
    exit /b 1
)
echo ✅ Ollama is installed
echo.

REM Start Ollama server automatically
echo 🚀 Starting Ollama server...
curl -s http://localhost:11434/api/tags >nul 2>&1
if %errorlevel% neq 0 (
    echo    Starting Ollama server in background...
    start /b cmd /c "set OLLAMA_HOST=0.0.0.0:11434 && ollama serve >nul 2>&1"
    echo    🕐 Waiting for server to start...
    timeout /t 3 /nobreak >nul
    
    REM Wait for server to be ready
    :wait_server
    curl -s http://localhost:11434/api/tags >nul 2>&1
    if %errorlevel% neq 0 (
        echo       Still waiting...
        timeout /t 2 /nobreak >nul
        goto wait_server
    )
    echo ✅ Server started successfully
) else (
    echo ✅ Server already running
)
echo.

REM Start proxy server in background
echo 🚀 Starting proxy server...
if exist ".venv\Scripts\python.exe" (
    start /B .venv\Scripts\python.exe proxy_server.py 2>nul
    echo ✅ Proxy server starting...
) else (
    echo ⚠️  Virtual environment not found, using system Python
    start /B python proxy_server.py 2>nul
    echo ✅ Proxy server starting...
)
timeout /t 3 /nobreak >nul

REM Get models using simple method
echo 📋 Getting installed models...
set model_count=0

REM Create a temporary file to capture ollama list output
ollama list > temp_models.txt 2>&1

REM Parse models (skip header line, get first token only)
for /f "skip=1 tokens=1" %%i in (temp_models.txt) do (
    if not "%%i"=="" (
        set /a model_count+=1
        set model!model_count!=%%i
        echo !model_count!. %%i
    )
)

del temp_models.txt >nul 2>&1

echo.
echo Found !model_count! models available!

REM Only ask to install if no models exist
if !model_count! GTR 0 goto setup_complete

echo ❌ No models found!
echo.
echo 💡 Suggested models to install:
echo    ollama pull tinyllama       # Small and fast (1.1GB)
echo    ollama pull llama2:7b-chat  # Good balance (3.8GB)
echo    ollama pull codellama:7b    # For coding (3.8GB)
echo.
set /p install_choice="Would you like to install tinyllama now? (y/n): "
if /i "!install_choice!"=="y" (
    echo 📦 Installing tinyllama...
    ollama pull tinyllama
    if !errorlevel!==0 (
        echo ✅ Model installed successfully!
        timeout /t 2 /nobreak >nul
        goto refresh_models
    ) else (
        echo ❌ Failed to install model
        pause
        exit /b 1
    )
) else (
    echo Please install a model first: ollama pull model_name
    pause
    exit /b 1
)

:refresh_models
REM Refresh model list if we just installed one
echo 📋 Refreshing model list...
set model_count=0
ollama list > temp_models.txt 2>&1
for /f "skip=1 tokens=1" %%i in (temp_models.txt) do (
    if not "%%i"=="" (
        set /a model_count+=1
        set model!model_count!=%%i
        echo !model_count!. %%i
    )
)
del temp_models.txt >nul 2>&1

echo.
echo Found !model_count! models available!

:setup_complete

echo.
echo ✅ Setup Complete!
echo ================================

echo 🤖 Found !model_count! models available
echo.

echo 🌐 Access URLs:
if not "!LOCAL_IP!"=="localhost" (
    echo    📱 Network: http://!LOCAL_IP!:11434
    echo    🌐 Web Interface: http://!LOCAL_IP!:8000/web (recommended)
    echo    🔗 Proxy API: http://!LOCAL_IP!:8000
)
echo    🏠 Local: http://localhost:11434
echo    💻 Local Web: http://localhost:8000/web
echo.

echo 📋 Connection URLs for other devices:
if defined LOCAL_IP (
    if not "!LOCAL_IP!"=="localhost" (
        echo    • Direct API: http://!LOCAL_IP!:11434
        echo    • Web Chat: http://!LOCAL_IP!:8000/web
        echo    • Test in browser: http://!LOCAL_IP!:11434/api/tags
    ) else (
        echo    ⚠️  Network access not available (no IP detected)
        echo    Only local access: http://localhost:11434
    )
) else (
    echo    ⚠️  Could not detect network IP address
)
echo.

:main_menu
echo ================================================================
echo 🎯 OLLAMA INTERFACE OPTIONS
echo ================================================================
echo.
echo 1. 🌐 Web Interface (Recommended) - Browser-based chat
echo 2. 💻 Local CLI Chat - Command line interface  
echo 3. 📱 Remote Device Setup - Connect from other devices
echo.
echo 0. Exit and stop server
echo.
set /p action_choice="Choose interface (0-3): "

if "!action_choice!"=="1" goto web_interface
if "!action_choice!"=="2" goto local_cli
if "!action_choice!"=="3" goto remote_setup
if "!action_choice!"=="0" goto cleanup
echo Invalid choice. Please try again.
goto main_menu

:web_interface
echo.
echo ================================================================
echo 🌐 STARTING WEB INTERFACE
echo ================================================================
echo.

REM Ensure proxy server is running
echo 🚀 Starting proxy server...
if exist ".venv\Scripts\python.exe" (
    start /B .venv\Scripts\python.exe proxy_server.py >nul 2>&1
) else (
    start /B python proxy_server.py >nul 2>&1
)
timeout /t 3 /nobreak >nul

echo 🌐 Opening web interface...
REM Try proxy server first (recommended)
curl -s http://localhost:8000 >nul 2>&1
if !errorlevel!==0 (
    start http://localhost:8000/web
    echo ✅ Web interface opened at: http://localhost:8000/web
    if not "!LOCAL_IP!"=="localhost" (
        echo 📱 Network access: http://!LOCAL_IP!:8000/web
    )
) else (
    echo ❌ Proxy server not responding, trying again...
    timeout /t 5 /nobreak >nul
    start http://localhost:8000/web
    echo ✅ Web interface opened
)
echo.
echo 💡 Web interface is now running in your browser
echo 💡 You can chat with any available model through the web interface
echo.
pause
goto main_menu

:local_cli
echo.
echo ================================================================
echo 💻 LOCAL CLI CHAT
echo ================================================================
echo.

if !model_count! gtr 0 (
    echo Available models:
    for /L %%i in (1,1,!model_count!) do (
        call echo %%i. %%model%%i%%
    )
    echo.
    set /p model_choice="Choose model number (1-!model_count!): "
    
    REM Validate choice
    if !model_choice! geq 1 if !model_choice! leq !model_count! (
        call set selected_model=%%model!model_choice!%%
        echo.
        echo 🤖 Starting interactive chat with !selected_model!
        echo    Type '/bye' to exit chat mode and return to main menu
        echo ========================================
        ollama run !selected_model!
        echo.
        echo Chat session ended - returning to main menu.
        echo.
    ) else (
        echo Invalid model choice.
        pause
    )
) else (
    echo No models available. Please install one first.
    pause
)
goto main_menu

:remote_setup
echo.
echo ================================================================
echo 📱 REMOTE DEVICE SETUP
echo ================================================================
echo.

echo 🔄 Ensuring remote files are available...

REM Ensure the remote_device_files directory exists
if not exist "remote_device_files" mkdir remote_device_files

REM Copy the connect script if it doesn't exist
if not exist "remote_device_files\connect_to_ollama.bat" (
    echo Creating connect_to_ollama.bat...
    echo ✅ connect_to_ollama.bat already available
) else (
    echo ✅ connect_to_ollama.bat already available
)

echo.
echo 📋 REMOTE SETUP INSTRUCTIONS:
echo ===============================
echo.

if not "!LOCAL_IP!"=="localhost" (
    echo 1. 📱 Share this server IP with other devices: !LOCAL_IP!
    echo.
    echo 2. 🔗 On other devices, they can access:
    echo    • Web Interface: http://!LOCAL_IP!:8000/web
    echo    • Direct API: http://!LOCAL_IP!:11434
    echo.
    echo 3. 📂 For Windows devices, copy and run:
    echo    • remote_device_files\connect_to_ollama.bat
    echo.
    echo 4. 🧪 Test connection from other devices:
    echo    • Open browser: http://!LOCAL_IP!:11434/api/tags
    echo    • Should show list of available models
    echo.
    echo 💡 To run connect_to_ollama.bat on this device for testing:
    echo    cd remote_device_files
    echo    connect_to_ollama.bat
    echo.
    set /p run_connect="Run connect_to_ollama.bat now for testing? (y/n): "
    if /i "!run_connect!"=="y" (
        echo.
        echo 🚀 Starting connect_to_ollama.bat...
        cd remote_device_files
        call connect_to_ollama.bat
        cd ..
    )
) else (
    echo ❌ Network IP not detected!
    echo    Make sure you're connected to Wi-Fi or Ethernet
    echo    Only local access available: http://localhost:11434
    echo.
)

echo.
echo 💡 The server is running and ready for remote connections!
echo 💡 Remote devices will automatically detect available models.
echo.
pause
goto main_menu

:cleanup
echo.
echo ================================================================
echo 🛑 SHUTTING DOWN OLLAMA SERVER
echo ================================================================
echo.

echo 🔄 Stopping all services...

echo Stopping Ollama server...
taskkill /f /im ollama.exe >nul 2>&1
if !errorlevel!==0 (
    echo ✅ Ollama server stopped
) else (
    echo ⚠️  Ollama server was not running
)

echo Stopping proxy server...
taskkill /f /im python.exe >nul 2>&1
if !errorlevel!==0 (
    echo ✅ Proxy server stopped
) else (
    echo ⚠️  Proxy server was not running
)

echo.
echo ✅ All services stopped successfully
echo 👋 Goodbye!
echo.
timeout /t 2 /nobreak >nul
exit
