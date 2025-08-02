@echo off
setlocalREM Auto-discover Ollama server
echo 🔍 Auto-discovering Ollama server...
echo.

REM Check if we have a saved IP from last time
if exist last_ollama_ip.txt (
    set /p "saved_ip=" < last_ollama_ip.txt
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
)edexpansion

REM ==================================================
REM Remote Ollama Chat Client for Windows CMD
REM Connect to Ollama server from another device
REM Auto-discovers server IP or prompts for manual entry
REM ==================================================

set "OLLAMA_PORT=11434"
set "DEFAULT_MODEL=tinyllama:latest"
set "OLLAMA_IP="

echo.
echo ============================================
echo     🌐 Remote Ollama Chat Client
echo ============================================
echo.

REM Auto-discover Ollama server
echo � Auto-discovering Ollama server...
echo.

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

REM Get available models
echo 📋 Getting available models...
curl -s "http://!OLLAMA_IP!:%OLLAMA_PORT%/api/tags" > temp_models.json 2>nul
if exist temp_models.json (
    echo Available models:
    findstr "name" temp_models.json
    del temp_models.json >nul 2>&1
)
echo.

REM Save connection info for future use
echo !OLLAMA_IP!> last_ollama_ip.txt
echo 💾 Saved connection info for next time

REM Interactive chat loop
echo 🤖 Starting chat with %DEFAULT_MODEL%
echo 💬 Type your messages below ^(type 'quit' to exit^)
echo ====================================================
echo.

:chat_loop
set /p "user_input=💭 You: "

if /i "!user_input!"=="quit" goto end
if /i "!user_input!"=="exit" goto end
if /i "!user_input!"=="bye" goto end

if "!user_input!"=="" goto chat_loop

echo.
echo 🤖 %DEFAULT_MODEL%: 

REM Create temporary JSON file for the request
echo {"model": "%DEFAULT_MODEL%", "prompt": "!user_input!", "stream": false} > temp_request.json

REM Make API call and get response
curl -s -X POST "http://!OLLAMA_IP!:%OLLAMA_PORT%/api/generate" ^
     -H "Content-Type: application/json" ^
     -d @temp_request.json > temp_response.json 2>nul

REM Extract and display response
if exist temp_response.json (
    for /f "tokens=2 delims=:" %%a in ('findstr "response" temp_response.json') do (
        set "response=%%a"
        set "response=!response:~1,-1!"
        set "response=!response:\n=!"
        echo !response!
    )
    del temp_response.json >nul 2>&1
)

if exist temp_request.json del temp_request.json >nul 2>&1

echo.
echo ====================================================
goto chat_loop

:end
echo.
echo 💾 Connection info saved in: last_ollama_ip.txt
echo    Next time, the script will try this IP first: !OLLAMA_IP!
echo.
echo 👋 Chat ended. Goodbye!
pause
