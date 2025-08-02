@echo off
setlocal enabledelayedexpansion

REM ==================================================
REM Remote Ollama Chat Service Launcher
REM Complete setup for remote device chat access
REM ==================================================

title Remote Ollama Chat Service

set "OLLAMA_PORT=11434"
set "DEFAULT_MODEL=tinyllama:latest"
set "OLLAMA_IP="
set "SERVICE_MODE=0"

echo.
echo ============================================
echo     🚀 Remote Ollama Chat Service
echo ============================================
echo.
echo 🎯 Choose your mode:
echo    1. Setup and start chat service (recommended)
echo    2. Direct chat only
echo    3. Server discovery only
echo    4. Exit
echo.

set /p "mode_choice=Enter choice (1-4): "

if "!mode_choice!"=="1" set "SERVICE_MODE=1"
if "!mode_choice!"=="2" set "SERVICE_MODE=0"
if "!mode_choice!"=="3" goto :discovery_only
if "!mode_choice!"=="4" goto :end

echo.
echo ============================================
echo     🔍 Auto-Discovering Ollama Server
echo ============================================
echo.

REM Check if we have a saved IP from last time
if exist remote_connection.txt (
    set /p "saved_ip=" < remote_connection.txt
    if not "!saved_ip!"=="" (
        echo 📁 Trying last known IP: !saved_ip!
        curl -s -m 3 "http://!saved_ip!:%OLLAMA_PORT%/api/tags" >nul 2>&1
        if !errorlevel! equ 0 (
            set "OLLAMA_IP=!saved_ip!"
            echo ✅ Found Ollama server at: !saved_ip! ^(from last session^)
            goto :connection_found
        ) else (
            echo ❌ Last known IP !saved_ip! is no longer working
        )
    )
)

REM Try localhost first
echo 📡 Trying localhost...
curl -s -m 3 "http://localhost:%OLLAMA_PORT%/api/tags" >nul 2>&1
if !errorlevel! equ 0 (
    set "OLLAMA_IP=localhost"
    echo ✅ Found Ollama server at: localhost
    goto :connection_found
)

REM Get local network range and try common IPs
for /f "tokens=2 delims=:" %%i in ('ipconfig ^| findstr "IPv4"') do (
    set "local_ip=%%i"
    set "local_ip=!local_ip: =!"
    if not "!local_ip!"=="" (
        REM Extract network base (e.g., 192.168.1)
        for /f "tokens=1,2,3 delims=." %%a in ("!local_ip!") do (
            set "network_base=%%a.%%b.%%c"
        )
    )
)

REM Try current machine's IP
if not "!local_ip!"=="" (
    echo 📡 Trying local IP: !local_ip!
    curl -s -m 3 "http://!local_ip!:%OLLAMA_PORT%/api/tags" >nul 2>&1
    if !errorlevel! equ 0 (
        set "OLLAMA_IP=!local_ip!"
        echo ✅ Found Ollama server at: !local_ip!
        goto :connection_found
    )
)

REM Try common network IPs
if not "!network_base!"=="" (
    echo 📡 Scanning network: !network_base!.*
    for %%j in (1 2 10 100 101 110 111 115 200) do (
        set "test_ip=!network_base!.%%j"
        if not "!test_ip!"=="!local_ip!" (
            echo    Testing !test_ip!...
            curl -s -m 2 "http://!test_ip!:%OLLAMA_PORT%/api/tags" >nul 2>&1
            if !errorlevel! equ 0 (
                set "OLLAMA_IP=!test_ip!"
                echo ✅ Found Ollama server at: !test_ip!
                goto :connection_found
            )
        )
    )
)

REM If auto-discovery failed, prompt user
:manual_entry
echo.
echo ❌ Could not auto-discover Ollama server
echo.
echo 📝 Please enter the Ollama server IP address:
echo 💡 Tip: Check the server machine's quick_start.bat output for the correct IP
echo 💡 Or run the server's smart_remote_client.py --scan to find it
echo.
set /p "OLLAMA_IP=🌐 Enter server IP: "

if "!OLLAMA_IP!"=="" (
    echo ❌ No IP address entered
    goto :manual_entry
)

REM Test the manually entered IP
echo 🔍 Testing connection to !OLLAMA_IP!...
curl -s -m 5 "http://!OLLAMA_IP!:%OLLAMA_PORT%/api/tags" >nul 2>&1
if !errorlevel! neq 0 (
    echo ❌ Connection failed to !OLLAMA_IP!:%OLLAMA_PORT%
    echo.
    echo 💡 Troubleshooting:
    echo    - Make sure Ollama server is running on !OLLAMA_IP!
    echo    - Verify the IP address is correct
    echo    - Check firewall settings
    echo.
    set /p "retry=🔄 Try a different IP? (y/n): "
    if /i "!retry!"=="y" goto :manual_entry
    echo.
    echo 👋 Exiting...
    pause
    exit /b 1
)

:connection_found
echo.
echo 🔗 Connected to: !OLLAMA_IP!:%OLLAMA_PORT%
echo ✅ Connection successful!
echo.

REM Save connection info for future use
echo !OLLAMA_IP!> remote_connection.txt
echo 💾 Saved connection info for next time

REM Get available models
echo 📋 Getting available models...
curl -s "http://!OLLAMA_IP!:%OLLAMA_PORT%/api/tags" > temp_models.json 2>nul
if exist temp_models.json (
    echo Available models:
    findstr "name" temp_models.json | head -5
    del temp_models.json >nul 2>&1
)
echo.

REM Create connection info file for other scripts
echo [CONNECTION]> connection_info.ini
echo IP=!OLLAMA_IP!>> connection_info.ini
echo PORT=!OLLAMA_PORT!>> connection_info.ini
echo MODEL=!DEFAULT_MODEL!>> connection_info.ini
echo LAST_CONNECTED=%date% %time%>> connection_info.ini

if "!SERVICE_MODE!"=="1" goto :start_service
if "!SERVICE_MODE!"=="0" goto :direct_chat

:start_service
echo ============================================
echo     🚀 Starting Chat Service
echo ============================================
echo.
echo 🔧 Setting up chat service...
echo 📡 Server: !OLLAMA_IP!:%OLLAMA_PORT%
echo 🤖 Model: !DEFAULT_MODEL!
echo.

REM Create a simple chat service script
echo @echo off> chat_service.bat
echo setlocal enabledelayedexpansion>> chat_service.bat
echo.>> chat_service.bat
echo title Ollama Chat Service - !OLLAMA_IP!>> chat_service.bat
echo.>> chat_service.bat
echo echo ============================================>> chat_service.bat
echo echo     🤖 Ollama Chat Service Active>> chat_service.bat
echo echo ============================================>> chat_service.bat
echo echo 📡 Connected to: !OLLAMA_IP!:%OLLAMA_PORT%>> chat_service.bat
echo echo 🤖 Using model: !DEFAULT_MODEL!>> chat_service.bat
echo echo 💬 Type your messages below ^(type 'quit' to exit^)>> chat_service.bat
echo echo ====================================================>> chat_service.bat
echo echo.>> chat_service.bat
echo.>> chat_service.bat
echo :chat_loop>> chat_service.bat
echo set /p "user_input=💭 You: ">> chat_service.bat
echo.>> chat_service.bat
echo if /i "^^!user_input^^!"=="quit" goto end>> chat_service.bat
echo if /i "^^!user_input^^!"=="exit" goto end>> chat_service.bat
echo if /i "^^!user_input^^!"=="bye" goto end>> chat_service.bat
echo if /i "^^!user_input^^!"=="help" goto show_help>> chat_service.bat
echo if /i "^^!user_input^^!"=="status" goto show_status>> chat_service.bat
echo.>> chat_service.bat
echo if "^^!user_input^^!"=="" goto chat_loop>> chat_service.bat
echo.>> chat_service.bat
echo echo.>> chat_service.bat
echo echo 🤖 !DEFAULT_MODEL!: >> chat_service.bat
echo.>> chat_service.bat
echo REM Create JSON request>> chat_service.bat
echo echo {"model": "!DEFAULT_MODEL!", "prompt": "^^!user_input^^!", "stream": false} ^> temp_request.json>> chat_service.bat
echo.>> chat_service.bat
echo REM Make API call>> chat_service.bat
echo curl -s -X POST "http://!OLLAMA_IP!:%OLLAMA_PORT%/api/generate" ^^>> chat_service.bat
echo      -H "Content-Type: application/json" ^^>> chat_service.bat
echo      -d @temp_request.json ^> temp_response.json 2^^>nul>> chat_service.bat
echo.>> chat_service.bat
echo REM Display response>> chat_service.bat
echo if exist temp_response.json ^(>> chat_service.bat
echo     for /f "tokens=2 delims=:" %%%%a in ^('findstr "response" temp_response.json'^) do ^(>> chat_service.bat
echo         set "response=%%%%a">> chat_service.bat
echo         set "response=^^!response:~1,-1^^!">> chat_service.bat
echo         echo ^^!response^^!>> chat_service.bat
echo     ^)>> chat_service.bat
echo     del temp_response.json ^^>nul 2^^>^^&1>> chat_service.bat
echo ^)>> chat_service.bat
echo.>> chat_service.bat
echo if exist temp_request.json del temp_request.json ^^>nul 2^^>^^&1>> chat_service.bat
echo.>> chat_service.bat
echo echo.>> chat_service.bat
echo echo ====================================================>> chat_service.bat
echo goto chat_loop>> chat_service.bat
echo.>> chat_service.bat
echo :show_help>> chat_service.bat
echo echo.>> chat_service.bat
echo echo 💡 Available commands:>> chat_service.bat
echo echo    help    - Show this help>> chat_service.bat
echo echo    status  - Show connection status>> chat_service.bat
echo echo    quit    - Exit chat service>> chat_service.bat
echo echo.>> chat_service.bat
echo goto chat_loop>> chat_service.bat
echo.>> chat_service.bat
echo :show_status>> chat_service.bat
echo echo.>> chat_service.bat
echo echo 📊 Service Status:>> chat_service.bat
echo echo    Server: !OLLAMA_IP!:%OLLAMA_PORT%>> chat_service.bat
echo echo    Model: !DEFAULT_MODEL!>> chat_service.bat
echo echo    Connection: Active>> chat_service.bat
echo echo.>> chat_service.bat
echo goto chat_loop>> chat_service.bat
echo.>> chat_service.bat
echo :end>> chat_service.bat
echo echo.>> chat_service.bat
echo echo 💾 Connection info saved in: remote_connection.txt>> chat_service.bat
echo echo 👋 Chat service ended. Goodbye!>> chat_service.bat
echo pause>> chat_service.bat

echo ✅ Chat service script created: chat_service.bat
echo.
echo 🚀 Starting chat service in new window...
echo 💡 A new command window will open for the chat interface

start "Ollama Chat Service" chat_service.bat

echo.
echo ============================================
echo     ✅ Setup Complete!
echo ============================================
echo.
echo 📁 Files created:
echo    - chat_service.bat (main chat interface)
echo    - connection_info.ini (connection details)
echo    - remote_connection.txt (saved IP)
echo.
echo 🚀 Chat service is now running in a separate window
echo 💬 You can now chat with the AI from this device
echo.
echo 🔄 To restart the service: run chat_service.bat
echo 🔧 To reconfigure: run this file again
echo.
goto :end

:direct_chat
echo ============================================
echo     💬 Starting Direct Chat
echo ============================================
echo.
echo 🤖 Starting chat with !DEFAULT_MODEL!
echo 💬 Type your messages below (type 'quit' to exit)
echo ====================================================
echo.

:chat_loop
set /p "user_input=💭 You: "

if /i "!user_input!"=="quit" goto end
if /i "!user_input!"=="exit" goto end
if /i "!user_input!"=="bye" goto end

if "!user_input!"=="" goto chat_loop

echo.
echo 🤖 !DEFAULT_MODEL!: 

REM Create temporary JSON file for the request
echo {"model": "!DEFAULT_MODEL!", "prompt": "!user_input!", "stream": false} > temp_request.json

REM Make API call and get response
curl -s -X POST "http://!OLLAMA_IP!:%OLLAMA_PORT%/api/generate" ^
     -H "Content-Type: application/json" ^
     -d @temp_request.json > temp_response.json 2>nul

REM Extract and display response
if exist temp_response.json (
    for /f "tokens=2 delims=:" %%a in ('findstr "response" temp_response.json') do (
        set "response=%%a"
        set "response=!response:~1,-1!"
        echo !response!
    )
    del temp_response.json >nul 2>&1
)

if exist temp_request.json del temp_request.json >nul 2>&1

echo.
echo ====================================================
goto chat_loop

:discovery_only
echo.
echo ============================================
echo     🔍 Server Discovery Mode
echo ============================================
echo.
echo 🌐 Scanning for Ollama servers...
echo.

REM Check saved IP first
if exist remote_connection.txt (
    set /p "saved_ip=" < remote_connection.txt
    if not "!saved_ip!"=="" (
        echo 📁 Testing last known IP: !saved_ip!
        curl -s -m 3 "http://!saved_ip!:%OLLAMA_PORT%/api/tags" >nul 2>&1
        if !errorlevel! equ 0 (
            echo ✅ Found server at: !saved_ip! ^(last known^)
        ) else (
            echo ❌ Last known IP !saved_ip! is not responding
        )
    )
)

echo 📡 Testing localhost...
curl -s -m 3 "http://localhost:%OLLAMA_PORT%/api/tags" >nul 2>&1
if !errorlevel! equ 0 (
    echo ✅ Found server at: localhost
)

REM Network scan
for /f "tokens=2 delims=:" %%i in ('ipconfig ^| findstr "IPv4"') do (
    set "local_ip=%%i"
    set "local_ip=!local_ip: =!"
    if not "!local_ip!"=="" (
        for /f "tokens=1,2,3 delims=." %%a in ("!local_ip!") do (
            set "network_base=%%a.%%b.%%c"
        )
    )
)

if not "!network_base!"=="" (
    echo 📡 Scanning network: !network_base!.*
    for %%j in (1 2 10 100 101 110 111 115 200) do (
        set "test_ip=!network_base!.%%j"
        echo    Testing !test_ip!...
        curl -s -m 2 "http://!test_ip!:%OLLAMA_PORT%/api/tags" >nul 2>&1
        if !errorlevel! equ 0 (
            echo ✅ Found server at: !test_ip!
        )
    )
)

echo.
echo 🔍 Discovery complete!
echo 💡 Use the IPs listed above to connect
echo.
goto :end

:end
echo.
echo 👋 Remote chat service setup complete!
echo.
echo 📁 All connection info saved in current directory
echo 🔄 Run this file again to reconnect or reconfigure
echo.
pause
exit /b 0
