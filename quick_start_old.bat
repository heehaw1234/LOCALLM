@echo off
setlocal enabledelayedexpansion
title Ollama Complete Network Launcher
color 0A

echo.
echo ========================================
echo    🦙 Ollama Complete Network Launcher
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

REM Check if server is already running
echo 🔍 Checking server status...
curl -s http://localhost:11434/api/tags >nul 2>&1
if %errorlevel% neq 0 (
    echo 🚀 Starting Ollama server in background...
    start /b cmd /c "set OLLAMA_HOST=0.0.0.0:11434 && ollama serve >nul 2>&1"
    echo 🕐 Waiting for server to start...
    timeout /t 3 /nobreak >nul
    
    REM Wait for server to be ready
    :wait_server
    curl -s http://localhost:11434/api/tags >nul 2>&1
    if %errorlevel% neq 0 (
        echo    Still waiting...
        timeout /t 2 /nobreak >nul
        goto wait_server
    )
    echo ✅ Background server started successfully
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

echo 🔄 Copying remote files to remote_device_files folder...

REM Ensure the remote_device_files directory exists
if not exist "remote_device_files" mkdir remote_device_files

REM Copy the connect script if it doesn't exist
if not exist "remote_device_files\connect_to_ollama.bat" (
    echo Creating connect_to_ollama.bat...
    REM This would copy from the main directory, but since it already exists, just notify
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
    echo 3. 📂 For Windows devices, copy these files:
    echo    • remote_device_files\connect_to_ollama.bat
    echo    • Run connect_to_ollama.bat on the remote device
    echo.
    echo 4. 🧪 Test connection from other devices:
    echo    • Open browser: http://!LOCAL_IP!:11434/api/tags
    echo    • Should show list of available models
    echo.
) else (
    echo ❌ Network IP not detected!
    echo    Make sure you're connected to Wi-Fi or Ethernet
    echo    Only local access available: http://localhost:11434
    echo.
)

echo 💡 The server is running and ready for remote connections!
echo 💡 Remote devices will automatically detect available models.
echo.
pause
goto main_menu

:server_status_monitor
echo.
echo ================================================================
echo 🟢 OLLAMA SERVER STATUS MONITOR
echo ================================================================

REM Re-detect current IP for the status
set STATUS_IP=
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr "IPv4" ^| findstr /v "127.0.0.1"') do (
    set STATUS_IP=%%a
    set STATUS_IP=!STATUS_IP: =!
    goto status_ip_found
)
:status_ip_found

if not defined STATUS_IP (
    set STATUS_IP=localhost
    echo ⚠️  Network IP not detected - using localhost only
) else (
    echo ✅ Network IP detected: !STATUS_IP!
)

echo.
echo 🤖 Model Status:

REM Check what model is currently loaded in memory
curl -s --connect-timeout 5 "http://localhost:11434/api/ps" > temp_status_active.json 2>nul
set "STATUS_ACTIVE="
if exist temp_status_active.json (
    for /f "usebackq delims=" %%i in (`powershell -Command "try { $json = Get-Content 'temp_status_active.json' | ConvertFrom-Json; if ($json.models -and $json.models.Count -gt 0) { $json.models[0].name } else { '' } } catch { '' }"`) do (
        if not "%%i"=="" (
            set "STATUS_ACTIVE=%%i"
        )
    )
    del temp_status_active.json 2>nul
)

if defined STATUS_ACTIVE (
    echo    🎯 Active Model in Memory: !STATUS_ACTIVE!
    if defined DEFAULT_MODEL (
        if "!STATUS_ACTIVE!"=="!DEFAULT_MODEL!" (
            echo    ✅ This matches the configured default model
        ) else (
            echo    ⚠️  Default model (!DEFAULT_MODEL!) differs from active (!STATUS_ACTIVE!)
        )
    )
) else (
    echo    � No model currently loaded in memory
    if defined DEFAULT_MODEL (
        echo    📌 Default Model: !DEFAULT_MODEL! (not currently loaded)
    )
)

if !model_count! gtr 0 (
    echo    📚 Available Models: !model_count!
    for /L %%i in (1,1,!model_count!) do (
        call set current_model=%%model%%i%%
        if defined STATUS_ACTIVE (
            if "!current_model!"=="!STATUS_ACTIVE!" (
                call echo       - %%model%%i%% ^(ACTIVE IN MEMORY^)
            ) else (
                call echo       - %%model%%i%%
            )
        ) else (
            if defined DEFAULT_MODEL (
                if "!current_model!"=="!DEFAULT_MODEL!" (
                    call echo       - %%model%%i%% ^(DEFAULT^)
                ) else (
                    call echo       - %%model%%i%%
                )
            ) else (
                call echo       - %%model%%i%%
            )
        )
    )
) else (
    echo    ❌ No models installed
)

echo.
echo 🌐 Access Points:
echo    📱 Network API: http://!STATUS_IP!:11434
echo    🌐 Web Interface: http://!STATUS_IP!:8000/web
echo    💻 Local API: http://localhost:11434
echo    🏠 Local Web: http://localhost:8000/web
echo.

echo ================================================================
echo 🔄 LIVE SERVER MONITOR - Press Ctrl+C to return to main menu
echo ================================================================

:live_status_loop
timeout /t 10 /nobreak >nul
set CURRENT_TIME=%time:~0,8%
echo [%CURRENT_TIME%] ✅ Server: RUNNING ^| Network: http://!STATUS_IP!:11434
if defined DEFAULT_MODEL (
    echo [%CURRENT_TIME%] 🤖 Default Model: !DEFAULT_MODEL! ready for requests
)
REM Test server responsiveness
curl -s --connect-timeout 3 "http://localhost:11434/api/tags" >nul 2>&1
if !errorlevel!==0 (
    echo [%CURRENT_TIME%] 🟢 Server responding normally
) else (
    echo [%CURRENT_TIME%] 🔴 Server not responding - check if Ollama is running
)
echo.
goto live_status_loop

:server_with_logs
echo.
echo ================================================================
echo 🔥 OLLAMA SERVER WITH LIVE CHAT LOGS
echo ================================================================

REM Re-detect current IP for the logs
set LOGS_IP=
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr "IPv4" ^| findstr /v "127.0.0.1"') do (
    set LOGS_IP=%%a
    set LOGS_IP=!LOGS_IP: =!
    goto logs_ip_found
)
:logs_ip_found

if not defined LOGS_IP (
    set LOGS_IP=localhost
    echo ⚠️  Network IP not detected - using localhost only
) else (
    echo ✅ Network IP detected: !LOGS_IP!
)

echo.
echo 🤖 Server Configuration:
if defined DEFAULT_MODEL (
    echo    📌 Default Model: !DEFAULT_MODEL! (preloaded and ready)
) else (
    echo    📋 All models available on demand
)

echo.
echo 🌐 Server will be accessible at:
echo    📱 Network: http://!LOGS_IP!:11434
echo    🌐 Web Interface: http://!LOGS_IP!:8000/web
echo    💻 Local: http://localhost:11434
echo    🏠 Local Web: http://localhost:8000/web
echo.

echo ================================================================
echo 🚀 STARTING SERVER WITH VERBOSE LOGGING
echo ================================================================
echo 💡 Server will show all chat interactions and API calls
echo 💡 Press Ctrl+C to stop the server and return to main menu
echo ================================================================
echo.

REM Stop any existing Ollama processes first
echo 🔄 Stopping any existing Ollama processes...
taskkill /f /im ollama.exe >nul 2>&1

REM Start proxy server in background first
echo 🚀 Starting proxy server in background...
if exist ".venv\Scripts\python.exe" (
    start /B .venv\Scripts\python.exe proxy_server.py >nul 2>&1
) else (
    start /B python proxy_server.py >nul 2>&1
)

echo 🔥 Starting Ollama server with full logging...
echo.

REM Set environment and start server in foreground with full output
set OLLAMA_HOST=0.0.0.0:11434
set OLLAMA_DEBUG=1

REM Start server in foreground so we can see logs and use Ctrl+C
echo ================================================================
echo 📊 LIVE SERVER LOGS - Press Ctrl+C to stop
echo ================================================================
echo Starting Ollama server at %date% %time%
echo Network address: http://!LOGS_IP!:11434
echo Web interface: http://!LOGS_IP!:8000/web
if defined DEFAULT_MODEL (
    echo Default model: !DEFAULT_MODEL!
)
echo ================================================================
echo.

REM Run server in foreground - this will show all logs
ollama serve

REM This runs when Ctrl+C is pressed or server stops
echo.
echo ================================================================
echo 🛑 SERVER STOPPED
echo ================================================================
echo Server stopped at %date% %time%
echo Returning to main menu...
echo.
timeout /t 3 /nobreak >nul
goto main_menu

:single_prompt
echo.
if !model_count! gtr 0 (
    echo Available models:
    for /L %%i in (1,1,!model_count!) do (
        call echo %%i. %%model%%i%%
    )
    echo.
    set /p model_choice="Choose model number (1-!model_count!): "
    
    if !model_choice! geq 1 if !model_choice! leq !model_count! (
        call set selected_model=%%model!model_choice!%%
        echo.
        set /p user_prompt="Enter your prompt: "
        echo.
        echo 🤖 !selected_model! response:
        echo ========================================
        ollama run !selected_model! "!user_prompt!"
        echo ========================================
    ) else (
        echo Invalid model choice.
    )
) else (
    echo No models available. Please install one first.
)
echo.
pause
goto main_menu

:open_web
echo.
echo 🌐 Opening web interface...
REM Try proxy server first (recommended)
curl -s http://localhost:8000 >nul 2>&1
if !errorlevel!==0 (
    start http://localhost:8000/web
    echo ✅ Proxy web interface opened (recommended)
) else (
    echo ❌ Proxy server not available
    echo � Starting proxy server...
    if exist ".venv\Scripts\python.exe" (
        start /B .venv\Scripts\python.exe proxy_server.py 2>nul
    ) else (
        start /B python proxy_server.py 2>nul
    )
    timeout /t 3 /nobreak >nul
    start http://localhost:8000/web
    echo ✅ Proxy web interface opened
)
echo.
goto main_menu

:remote_device_guide
echo.
echo 📱 Connect from Other Device - Setup Guide
echo ==========================================
echo.

REM Re-detect current IP for the guide
set GUIDE_IP=
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr "IPv4" ^| findstr /v "127.0.0.1"') do (
    set GUIDE_IP=%%a
    set GUIDE_IP=!GUIDE_IP: =!
    goto guide_ip_found
)
:guide_ip_found

if not defined GUIDE_IP (
    echo ❌ No network IP detected. Make sure you're connected to Wi-Fi or Ethernet.
    echo.
    pause
    goto main_menu
)

echo 🌐 Your Ollama server is accessible at: http://!GUIDE_IP!:11434
echo.

echo 📋 STEP 1: Connect Device to Same Network
echo ==========================================
echo 1. Connect your other device (phone, laptop, etc.) to the same Wi-Fi network
echo 2. Make sure both devices can see each other on the network
echo.

echo 🧪 STEP 2: Test Connection
echo ===========================
echo On your other device, open a web browser and go to:
echo    http://!GUIDE_IP!:11434/api/tags
echo.
echo If you see a list of models, the connection is working!
echo.

echo 💻 STEP 3: Command Line Usage (Windows CMD)
echo ============================================
echo On another Windows computer, open Command Prompt and use:
echo.
echo 🔍 List available models:
echo    curl http://!GUIDE_IP!:11434/api/tags
echo.
echo 💬 Chat with a model (replace "tinyllama" with your model):
echo    curl -X POST http://!GUIDE_IP!:11434/api/generate -H "Content-Type: application/json" -d "{\"model\":\"tinyllama\",\"prompt\":\"Hello, how are you?\",\"stream\":false}"
echo.
echo 🚀 Generate text (streaming):
echo    curl -X POST http://!GUIDE_IP!:11434/api/generate -H "Content-Type: application/json" -d "{\"model\":\"tinyllama\",\"prompt\":\"Write a short story about a robot\"}"
echo.

echo 📱 STEP 4: Web Interface Access
echo ===============================
echo 🌐 Open web browser on other device and go to:
echo    http://!GUIDE_IP!:8000/web
echo.
echo This provides a chat interface similar to ChatGPT!
echo.

echo 🐍 STEP 5: Python Usage
echo =======================
echo If you have Python on the other device, you can use:
echo.
echo import requests
echo.
echo # List models
echo response = requests.get('http://!GUIDE_IP!:11434/api/tags')
echo print(response.json())
echo.
echo # Generate text
echo data = {"model": "tinyllama", "prompt": "Hello!", "stream": False}
echo response = requests.post('http://!GUIDE_IP!:11434/api/generate', json=data)
echo print(response.json()['response'])
echo.

echo 📋 Available Models on This Server:
if !model_count! gtr 0 (
    for /L %%i in (1,1,!model_count!) do (
        call set current_model=%%model%%i%%
        if defined DEFAULT_MODEL (
            if "!current_model!"=="!DEFAULT_MODEL!" (
                call echo    - %%model%%i%% ^(DEFAULT - PRELOADED^)
            ) else (
                call echo    - %%model%%i%%
            )
        ) else (
            call echo    - %%model%%i%%
        )
    )
) else (
    echo    No models installed - install some first!
)
echo.

echo 🔧 Troubleshooting Tips:
echo ========================
echo • Make sure Windows Firewall allows connections on port 11434
echo • Both devices must be on the same network (same Wi-Fi)
echo • Try pinging the server: ping !GUIDE_IP!
echo • If web interface doesn't work, try: http://!GUIDE_IP!:11434 directly
echo • Some routers block device-to-device communication (AP isolation)
echo.

echo 💡 Quick Test Commands:
echo =======================
echo Test from CMD on other device:
echo    curl http://!GUIDE_IP!:11434/api/version
echo    curl http://!GUIDE_IP!:11434/api/tags
echo.

echo ================================================================
echo 🟢 SERVER STATUS: RUNNING AND READY
echo ================================================================
if defined DEFAULT_MODEL (
    echo 🤖 Serving Model: !DEFAULT_MODEL! (preloaded for fast response)
) else (
    echo 🤖 All models available on demand
)
echo 🌐 Network Address: http://!GUIDE_IP!:11434
echo 🌐 Web Interface: http://!GUIDE_IP!:8000/web
echo 💻 Local Access: http://localhost:11434
echo.
echo 💡 Your Ollama server is now accessible from other devices!
echo 💡 Use the connection information above to access from remote devices.
echo 💡 Press Ctrl+C to return to main menu, or leave running in background.
echo ================================================================

REM Keep running status visible instead of returning to menu immediately
echo.
echo 🔄 Server Status Monitor (Press Ctrl+C to exit to main menu)
echo ================================================================

:status_loop
timeout /t 30 /nobreak >nul
echo [%date% %time%] ✅ Server running - Network: http://!GUIDE_IP!:11434
if defined DEFAULT_MODEL (
    echo [%date% %time%] 🤖 Default model: !DEFAULT_MODEL! ready
)
goto status_loop

:install_models
echo.
echo 📦 Model Installation
echo ====================
echo.
echo 🤖 Available Ollama Models:
echo.
echo 🚀 RECOMMENDED MODELS ^(Fast & Popular^):
echo 1. tinyllama:latest ^(1.1GB^) - Very fast, good for testing
echo 2. llama3.2:1b ^(1.3GB^) - Meta's latest, ultra fast
echo 3. llama3.2:3b ^(2.0GB^) - Meta's latest, balanced
echo 4. qwen2.5:0.5b ^(0.4GB^) - Alibaba's smallest model
echo 5. qwen2.5:1.5b ^(0.9GB^) - Alibaba's fast model
echo.
echo 💻 CODING MODELS:
echo 6. qwen2.5-coder:1.5b ^(0.9GB^) - Code generation, fast
echo 7. qwen2.5-coder:7b ^(4.4GB^) - Advanced coding
echo 8. qwen2.5-coder:14b ^(8.2GB^) - Professional coding
echo 9. qwen2.5-coder:32b ^(18GB^) - Expert coding
echo 10. codellama:7b ^(3.8GB^) - Meta's code model
echo 11. codellama:13b (7.3GB) - Larger code model
echo 12. codellama:34b (19GB) - Largest code model
echo 13. starcoder2:3b (1.7GB) - Efficient coding
echo 14. starcoder2:7b (4.0GB) - Balanced coding
echo 15. starcoder2:15b (8.5GB) - Advanced coding
echo.
echo 🧠 GENERAL PURPOSE MODELS:
echo 16. llama3.1:8b (4.7GB) - Meta's flagship model
echo 17. llama3.1:70b (40GB) - Meta's large model
echo 18. llama3.1:405b (231GB^) - Meta's largest ^(requires 128GB+ RAM^)
echo 19. llama3.2:11b (6.6GB) - Latest balanced model
echo 20. llama3.2:90b (51GB) - Latest large model
echo 21. qwen2.5:3b (2.0GB) - Alibaba's balanced
echo 22. qwen2.5:7b (4.4GB) - Alibaba's standard
echo 23. qwen2.5:14b (8.2GB) - Alibaba's large
echo 24. qwen2.5:32b (18GB) - Alibaba's extra large
echo 25. qwen2.5:72b (41GB) - Alibaba's flagship
echo.
echo 💬 CHAT & INSTRUCT MODELS:
echo 26. llama2:7b-chat (3.8GB) - Classic chat model
echo 27. llama2:13b-chat (7.3GB) - Larger chat model
echo 28. llama2:70b-chat (39GB) - Largest Llama2 chat
echo 29. mistral:7b (4.1GB) - Mistral's flagship
echo 30. mixtral:8x7b (26GB) - Mixture of experts
echo 31. mixtral:8x22b (87GB) - Large mixture model
echo 32. gemma:2b (1.4GB) - Google's small model
echo 33. gemma:7b (4.8GB) - Google's standard model
echo 34. gemma2:2b (1.6GB) - Google's improved small
echo 35. gemma2:9b (5.4GB) - Google's improved standard
echo 36. gemma2:27b (16GB) - Google's large model
echo.
echo 🔬 SPECIALIZED MODELS:
echo 37. phi3:3.8b (2.3GB) - Microsoft's efficient model
echo 38. phi3:14b (7.9GB) - Microsoft's larger model
echo 39. phi3.5:3.8b (2.3GB) - Microsoft's latest
echo 40. solar:10.7b (6.1GB) - Upstage's model
echo 41. deepseek-coder:1.3b (0.7GB) - DeepSeek coding
echo 42. deepseek-coder:6.7b (3.8GB) - DeepSeek coding
echo 43. deepseek-coder:33b (18GB) - DeepSeek large coding
echo 44. wizard-coder:13b (7.3GB) - WizardLM coding
echo 45. wizard-coder:34b (19GB) - WizardLM large coding
echo.
echo 🌍 MULTILINGUAL MODELS:
echo 46. aya:8b (4.8GB) - Multilingual by Cohere
echo 47. aya:35b (20GB) - Large multilingual
echo 48. command-r:35b (20GB) - Cohere's model
echo 49. command-r-plus:104b (59GB) - Cohere's largest
echo.
echo 🎨 VISION MODELS:
echo 50. llava:7b (4.5GB) - Language + Vision
echo 51. llava:13b (8.0GB) - Larger vision model
echo 52. llava:34b (20GB) - Large vision model
echo 53. bakllava:7b (4.5GB) - Vision model variant
echo.
echo 📊 MATH & REASONING:
echo 54. deepseek-math:7b (4.4GB) - Math specialist
echo 55. wizard-math:7b (4.4GB) - Math reasoning
echo 56. wizard-math:13b (7.3GB) - Advanced math
echo.
echo 🔧 TOOL USE MODELS:
echo 57. gorilla-openfunctions-v2:7b (4.4GB) - Function calling
echo 58. nexusraven:13b (7.3GB) - Function calling
echo.
echo 🚫 UNCENSORED MODELS:
echo 59. dolphin-mistral:7b (4.1GB) - Uncensored chat
echo 60. dolphin-mixtral:8x7b (26GB) - Large uncensored
echo 61. neural-chat:7b (4.1GB) - Uncensored variant
echo.
echo 🔬 EXPERIMENTAL:
echo 62. falcon:7b (4.1GB) - Technology Innovation Institute
echo 63. falcon:40b (23GB) - Large falcon model
echo 64. vicuna:7b (4.1GB) - Fine-tuned LLaMA
echo 65. vicuna:13b (7.3GB) - Larger vicuna
echo 66. alpaca:7b (4.1GB) - Stanford's model
echo 67. orca-mini:3b (2.0GB) - Small reasoning model
echo 68. orca-mini:7b (4.1GB) - Standard reasoning
echo 69. orca-mini:13b (7.3GB) - Large reasoning
echo 70. nous-hermes:7b (4.1GB) - NousResearch model
echo 71. nous-hermes:13b (7.3GB) - Larger NousResearch
echo.
echo 📝 CUSTOM MODEL:
echo 99. Enter custom model name
echo.
echo 0. Back to main menu
echo.
set /p install_choice="Choose model number (0-99): "

REM Reset model to install
set model_to_install=

REM Fast & Popular models
if "!install_choice!"=="1" set model_to_install=tinyllama:latest
if "!install_choice!"=="2" set model_to_install=llama3.2:1b
if "!install_choice!"=="3" set model_to_install=llama3.2:3b
if "!install_choice!"=="4" set model_to_install=qwen2.5:0.5b
if "!install_choice!"=="5" set model_to_install=qwen2.5:1.5b

REM Coding models
if "!install_choice!"=="6" set model_to_install=qwen2.5-coder:1.5b
if "!install_choice!"=="7" set model_to_install=qwen2.5-coder:7b
if "!install_choice!"=="8" set model_to_install=qwen2.5-coder:14b
if "!install_choice!"=="9" set model_to_install=qwen2.5-coder:32b
if "!install_choice!"=="10" set model_to_install=codellama:7b
if "!install_choice!"=="11" set model_to_install=codellama:13b
if "!install_choice!"=="12" set model_to_install=codellama:34b
if "!install_choice!"=="13" set model_to_install=starcoder2:3b
if "!install_choice!"=="14" set model_to_install=starcoder2:7b
if "!install_choice!"=="15" set model_to_install=starcoder2:15b

REM General purpose models
if "!install_choice!"=="16" set model_to_install=llama3.1:8b
if "!install_choice!"=="17" set model_to_install=llama3.1:70b
if "!install_choice!"=="18" set model_to_install=llama3.1:405b
if "!install_choice!"=="19" set model_to_install=llama3.2:11b
if "!install_choice!"=="20" set model_to_install=llama3.2:90b
if "!install_choice!"=="21" set model_to_install=qwen2.5:3b
if "!install_choice!"=="22" set model_to_install=qwen2.5:7b
if "!install_choice!"=="23" set model_to_install=qwen2.5:14b
if "!install_choice!"=="24" set model_to_install=qwen2.5:32b
if "!install_choice!"=="25" set model_to_install=qwen2.5:72b

REM Chat & Instruct models
if "!install_choice!"=="26" set model_to_install=llama2:7b-chat
if "!install_choice!"=="27" set model_to_install=llama2:13b-chat
if "!install_choice!"=="28" set model_to_install=llama2:70b-chat
if "!install_choice!"=="29" set model_to_install=mistral:7b
if "!install_choice!"=="30" set model_to_install=mixtral:8x7b
if "!install_choice!"=="31" set model_to_install=mixtral:8x22b
if "!install_choice!"=="32" set model_to_install=gemma:2b
if "!install_choice!"=="33" set model_to_install=gemma:7b
if "!install_choice!"=="34" set model_to_install=gemma2:2b
if "!install_choice!"=="35" set model_to_install=gemma2:9b
if "!install_choice!"=="36" set model_to_install=gemma2:27b

REM Specialized models
if "!install_choice!"=="37" set model_to_install=phi3:3.8b
if "!install_choice!"=="38" set model_to_install=phi3:14b
if "!install_choice!"=="39" set model_to_install=phi3.5:3.8b
if "!install_choice!"=="40" set model_to_install=solar:10.7b
if "!install_choice!"=="41" set model_to_install=deepseek-coder:1.3b
if "!install_choice!"=="42" set model_to_install=deepseek-coder:6.7b
if "!install_choice!"=="43" set model_to_install=deepseek-coder:33b
if "!install_choice!"=="44" set model_to_install=wizard-coder:13b
if "!install_choice!"=="45" set model_to_install=wizard-coder:34b

REM Multilingual models
if "!install_choice!"=="46" set model_to_install=aya:8b
if "!install_choice!"=="47" set model_to_install=aya:35b
if "!install_choice!"=="48" set model_to_install=command-r:35b
if "!install_choice!"=="49" set model_to_install=command-r-plus:104b

REM Vision models
if "!install_choice!"=="50" set model_to_install=llava:7b
if "!install_choice!"=="51" set model_to_install=llava:13b
if "!install_choice!"=="52" set model_to_install=llava:34b
if "!install_choice!"=="53" set model_to_install=bakllava:7b

REM Math & Reasoning
if "!install_choice!"=="54" set model_to_install=deepseek-math:7b
if "!install_choice!"=="55" set model_to_install=wizard-math:7b
if "!install_choice!"=="56" set model_to_install=wizard-math:13b

REM Tool use models
if "!install_choice!"=="57" set model_to_install=gorilla-openfunctions-v2:7b
if "!install_choice!"=="58" set model_to_install=nexusraven:13b

REM Uncensored models
if "!install_choice!"=="59" set model_to_install=dolphin-mistral:7b
if "!install_choice!"=="60" set model_to_install=dolphin-mixtral:8x7b
if "!install_choice!"=="61" set model_to_install=neural-chat:7b

REM Experimental models
if "!install_choice!"=="62" set model_to_install=falcon:7b
if "!install_choice!"=="63" set model_to_install=falcon:40b
if "!install_choice!"=="64" set model_to_install=vicuna:7b
if "!install_choice!"=="65" set model_to_install=vicuna:13b
if "!install_choice!"=="66" set model_to_install=alpaca:7b
if "!install_choice!"=="67" set model_to_install=orca-mini:3b
if "!install_choice!"=="68" set model_to_install=orca-mini:7b
if "!install_choice!"=="69" set model_to_install=orca-mini:13b
if "!install_choice!"=="70" set model_to_install=nous-hermes:7b
if "!install_choice!"=="71" set model_to_install=nous-hermes:13b

REM Custom model
if "!install_choice!"=="99" (
    set /p model_to_install="Enter custom model name (e.g., modelname:tag): "
)

REM Back to main menu
if "!install_choice!"=="0" goto main_menu

if defined model_to_install (
    echo.
    echo 📦 Installing !model_to_install!...
    echo.
    echo ⚠️  IMPORTANT NOTES:
    echo    • Large models ^(70B+^) require significant RAM ^(32GB+ recommended^)
    echo    • Download times vary based on internet speed
    echo    • Models with 32B+ parameters may be slow on consumer hardware
    echo    • Press Ctrl+C to cancel if needed
    echo.
    echo 🚀 Starting download...
    ollama pull !model_to_install!
    if !errorlevel!==0 (
        echo.
        echo ✅ Model !model_to_install! installed successfully!
        echo 💡 You can now use this model for chat and API calls
        goto get_models_again
    ) else (
        echo.
        echo ❌ Failed to install model: !model_to_install!
        echo 💡 Possible reasons:
        echo    • Model name might be incorrect
        echo    • Network connection issues
        echo    • Insufficient disk space
        echo    • Model might not exist
    )
) else (
    echo.
    echo ❌ Invalid choice or no model specified.
)
echo.
pause
goto install_models

:network_status
echo.
echo 🌐 Network Status Report
echo ========================

REM Re-detect IP address in case it changed
echo 🔄 Refreshing network configuration...
set CURRENT_IP=
set CURRENT_WIFI_IP=
set CURRENT_ETHERNET_IP=

REM Get current Wi-Fi IP
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr "IPv4" ^| findstr /v "127.0.0.1"') do (
    set CURRENT_WIFI_IP=%%a
    set CURRENT_WIFI_IP=!CURRENT_WIFI_IP: =!
    goto current_wifi_found
)
:current_wifi_found

REM Get current Ethernet IP (fallback)
if not defined CURRENT_WIFI_IP (
    for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr "IPv4" ^| findstr /v "127.0.0.1"') do (
        set CURRENT_ETHERNET_IP=%%a
        set CURRENT_ETHERNET_IP=!CURRENT_ETHERNET_IP: =!
        goto current_ethernet_found
    )
    :current_ethernet_found
)

REM Use the first available IP
if defined CURRENT_WIFI_IP (
    set CURRENT_IP=!CURRENT_WIFI_IP!
    echo    Active Network: Wi-Fi (!CURRENT_WIFI_IP!)
) else if defined CURRENT_ETHERNET_IP (
    set CURRENT_IP=!CURRENT_ETHERNET_IP!
    echo    Active Network: Ethernet (!CURRENT_ETHERNET_IP!)
) else (
    for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr "IPv4" ^| findstr /v "127.0.0.1"') do (
        set CURRENT_IP=%%a
        set CURRENT_IP=!CURRENT_IP: =!
        goto current_ip_found
    )
    :current_ip_found
    echo    Detected IP: !CURRENT_IP!
)

echo.
echo 🔗 Your Ollama server is accessible at:
if defined CURRENT_IP (
    if not "!CURRENT_IP!"=="localhost" (
        echo    📱 Network: http://!CURRENT_IP!:11434
        echo    🌐 Web Interface: http://!CURRENT_IP!:8000/web
    )
)
echo    🏠 Local: http://localhost:11434
echo.

echo 📋 Connection URLs for other devices:
if defined CURRENT_IP (
    if not "!CURRENT_IP!"=="localhost" (
        echo    • Direct API: http://!CURRENT_IP!:11434
        echo    • Web Chat: http://!CURRENT_IP!:8000/web
        echo    • Test in browser: http://!CURRENT_IP!:11434/api/tags
    ) else (
        echo    ⚠️  Network access not available (no IP detected)
        echo    Only local access: http://localhost:11434
    )
) else (
    echo    ⚠️  Could not detect network IP address
)
echo.

echo 🔄 Network Status:
if defined CURRENT_WIFI_IP echo    Wi-Fi: !CURRENT_WIFI_IP!
if defined CURRENT_ETHERNET_IP echo    Ethernet: !CURRENT_ETHERNET_IP!
echo    Ollama Host: %OLLAMA_HOST%
echo.

echo 🧪 Testing connections...
echo Testing local API...
curl -s http://localhost:11434/api/tags >nul 2>&1
if !errorlevel!==0 (
    echo    ✅ Local API: Working
) else (
    echo    ❌ Local API: Not responding
)

if defined CURRENT_IP (
    if not "!CURRENT_IP!"=="localhost" (
        echo Testing network API...
        curl -s http://!CURRENT_IP!:11434/api/tags >nul 2>&1
        if !errorlevel!==0 (
            echo    ✅ Network API: Working
        ) else (
            echo    ❌ Network API: Not responding
        )
    )
)

echo Testing proxy server...
curl -s http://localhost:8000 >nul 2>&1
if !errorlevel!==0 (
    echo    ✅ Proxy Server: Working
) else (
    echo    ❌ Proxy Server: Not responding
)

echo.
pause
goto main_menu

:diagnostics
echo.
echo 🔧 System Diagnostics
echo ====================
echo.

echo 📊 Environment Information:
echo    Windows Version: 
wmic os get Caption /value | findstr "Caption"
echo    OLLAMA_HOST: %OLLAMA_HOST%
echo    Current Directory: %CD%
echo.

echo 🔍 Ollama Installation:
ollama --version 2>nul
if !errorlevel!==0 (
    echo    ✅ Ollama is installed and accessible
) else (
    echo    ❌ Ollama not found in PATH
)
echo.

echo 🌐 Network Tools:
curl --version >nul 2>&1
if !errorlevel!==0 (
    echo    ✅ curl is available
) else (
    echo    ❌ curl not found
)
echo.

echo 🐍 Python Environment:
if exist ".venv\Scripts\python.exe" (
    echo    ✅ Virtual environment found
    .venv\Scripts\python.exe --version
) else (
    echo    ⚠️  Virtual environment not found
    python --version 2>nul
    if !errorlevel!==0 (
        echo    ✅ System Python available
    ) else (
        echo    ❌ Python not found
    )
)
echo.

echo 📂 Required Files:
if exist "proxy_server.py" (
    echo    ✅ proxy_server.py found
) else (
    echo    ❌ proxy_server.py missing
)

if exist "api_client.py" (
    echo    ✅ api_client.py found
) else (
    echo    ❌ api_client.py missing
)

if exist "cli_client.py" (
    echo    ✅ cli_client.py found
) else (
    echo    ❌ cli_client.py missing
)

if exist "web_interface.html" (
    echo    ✅ web_interface.html found
) else (
    echo    ❌ web_interface.html missing
)
echo.

echo 🔄 Process Status:
tasklist | findstr "ollama.exe" >nul 2>&1
if !errorlevel!==0 (
    echo    ✅ Ollama server is running
) else (
    echo    ❌ Ollama server not running
)

tasklist | findstr "python.exe" >nul 2>&1
if !errorlevel!==0 (
    echo    ✅ Python processes running
) else (
    echo    ⚠️  No Python processes detected
)
echo.

echo 📋 Available Models:
ollama list 2>nul
echo.

echo 🏥 Health Check:
echo Testing Ollama API...
curl -s http://localhost:11434/api/tags >nul 2>&1
if !errorlevel!==0 (
    echo    ✅ Ollama API responding
) else (
    echo    ❌ Ollama API not responding
)

echo Testing proxy server...
curl -s http://localhost:8000 >nul 2>&1
if !errorlevel!==0 (
    echo    ✅ Proxy server responding
) else (
    echo    ❌ Proxy server not responding
)

echo.
pause
goto main_menu

:stop_services
echo.
echo 🛑 Stopping all services...
echo.

echo Stopping Ollama server...
taskkill /f /im ollama.exe >nul 2>&1
if !errorlevel!==0 (
    echo    ✅ Ollama server stopped
) else (
    echo    ⚠️  Ollama server was not running
)

echo Stopping Python processes (proxy server)...
taskkill /f /im python.exe >nul 2>&1
if !errorlevel!==0 (
    echo    ✅ Python processes stopped
) else (
    echo    ⚠️  No Python processes were running
)

echo.
echo ✅ All services stopped
echo.
pause
goto main_menu

:switch_model
echo.
echo ================================================================
echo 🔄 SWITCH/LOAD MODEL INTO MEMORY
echo ================================================================
echo.

if !model_count! gtr 0 (
    echo 🔍 Checking currently active model...
    
    REM Check what model is currently loaded in memory
    curl -s --connect-timeout 5 "http://localhost:11434/api/ps" > temp_active.json 2>nul
    set "CURRENT_ACTIVE="
    if exist temp_active.json (
        for /f "usebackq delims=" %%i in (`powershell -Command "try { $json = Get-Content 'temp_active.json' | ConvertFrom-Json; if ($json.models -and $json.models.Count -gt 0) { $json.models[0].name } else { '' } } catch { '' }"`) do (
            if not "%%i"=="" (
                set "CURRENT_ACTIVE=%%i"
            )
        )
        del temp_active.json 2>nul
    )
    
    if defined CURRENT_ACTIVE (
        echo ✅ Currently active model in memory: !CURRENT_ACTIVE!
    ) else (
        echo 📭 No model currently loaded in memory
    )
    
    echo.
    echo 📋 Available models:
    for /L %%i in (1,1,!model_count!) do (
        call set current_model=%%model%%i%%
        if defined CURRENT_ACTIVE (
            if "!current_model!"=="!CURRENT_ACTIVE!" (
                call echo %%i. %%model%%i%% ^(CURRENTLY ACTIVE^)
            ) else (
                call echo %%i. %%model%%i%%
            )
        ) else (
            call echo %%i. %%model%%i%%
        )
    )
    
    echo.
    echo 🎯 Choose action:
    echo    1-!model_count!. Load specific model into memory
    echo    0. Return to main menu
    echo.
    set /p model_choice="Enter your choice: "
    
    if "!model_choice!"=="0" goto main_menu
    
    REM Validate choice
    if !model_choice! geq 1 if !model_choice! leq !model_count! (
        call set selected_model=%%model!model_choice!%%
        
        REM Check if this model is already loaded
        if defined CURRENT_ACTIVE (
            if "!selected_model!"=="!CURRENT_ACTIVE!" (
                echo.
                echo ✅ Model !selected_model! is already loaded and active!
                echo 💡 Remote devices will automatically use this model.
                echo.
                pause
                goto main_menu
            )
        )
        
        echo.
        echo 🔄 Loading !selected_model! into memory...
        echo    This will make it the active model for remote connections.
        
        REM Send a test request to load the model
        curl -s -X POST "http://localhost:11434/api/generate" -H "Content-Type: application/json" -d "{\"model\":\"!selected_model!\",\"prompt\":\"Hello\",\"stream\":false}" > temp_load_result.json 2>nul
        
        if exist temp_load_result.json (
            REM Check if the response contains an error
            findstr /C:"error" temp_load_result.json >nul 2>&1
            if !errorlevel! equ 0 (
                echo ❌ Failed to load model !selected_model!
                echo    The model might not be properly installed.
                echo.
                type temp_load_result.json
            ) else (
                echo ✅ Model !selected_model! loaded successfully!
                echo 🎯 This model is now active in memory and will be used by remote devices.
                
                REM Update the DEFAULT_MODEL variable
                set "DEFAULT_MODEL=!selected_model!"
                
                echo.
                echo 📊 Model Status:
                echo    🎯 Active Model: !selected_model!
                echo    🌐 Network Access: http://!LOCAL_IP!:11434
                echo    💻 Remote devices will automatically detect and use this model
            )
            del temp_load_result.json 2>nul
        ) else (
            echo ❌ Failed to connect to Ollama server
            echo    Make sure the server is running properly.
        )
        
        echo.
        pause
    ) else (
        echo ❌ Invalid choice. Please try again.
        timeout /t 2 /nobreak >nul
        goto switch_model
    )
) else (
    echo ❌ No models available!
    echo    Please install models first using option 4 in the main menu.
    echo.
    pause
)
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
