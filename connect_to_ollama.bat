@echo off
setlocal enabledelayedexpansion
title Ollama Remote Connection - One-Click Setup

:: =============================================================================
:: OLLAMA REMOTE CONNECTION - MASTER SETUP FILE
:: =============================================================================
:: This is the ONLY file you need to run on a remote device
:: It handles: Python setup, server discovery, connection, and chat
:: =============================================================================

color 0A
echo.
echo ================================================================
echo 🚀 OLLAMA REMOTE CONNECTION - ONE-CLICK SETUP
echo ================================================================
echo.
echo This will automatically:
echo   ✅ Check for Python environment
echo   ✅ Setup Python if needed (no admin rights required)
echo   ✅ Discover your Ollama server
echo   ✅ Connect and start chatting
echo.
echo Press any key to start, or Ctrl+C to cancel...
pause >nul

:: =============================================================================
:: STEP 1: PYTHON ENVIRONMENT CHECK AND SETUP
:: =============================================================================
echo.
echo ================================================================
echo 🐍 STEP 1: PYTHON ENVIRONMENT SETUP
echo ================================================================

set "PYTHON_CMD="
set "SETUP_NEEDED=0"

:: Check for virtual environment first
if exist "venv\Scripts\python.exe" (
    set "PYTHON_CMD=venv\Scripts\python.exe"
    echo ✅ Found virtual environment: venv\Scripts\python.exe
    goto :check_packages
)

:: Check for portable Python
if exist "portable_python\python.exe" (
    set "PYTHON_CMD=portable_python\python.exe"
    echo ✅ Found portable Python: portable_python\python.exe
    goto :check_packages
)

:: Check system Python installations
for %%P in (python py) do (
    %%P --version >nul 2>&1
    if !errorlevel! equ 0 (
        set "PYTHON_CMD=%%P"
        echo ✅ Found system Python: %%P
        goto :check_packages
    )
)

:: Check common Python install locations
for %%D in ("C:\Python*" "%LOCALAPPDATA%\Programs\Python\Python*" "%APPDATA%\Python\Python*") do (
    if exist "%%D\python.exe" (
        set "PYTHON_CMD=%%D\python.exe"
        echo ✅ Found Python at: %%D\python.exe
        goto :check_packages
    )
)

:: No Python found - need to install
echo ❌ No Python installation found
set "SETUP_NEEDED=1"
goto :python_setup

:check_packages
:: Test if required packages are available
echo 📦 Checking for required packages...
%PYTHON_CMD% -c "import requests" >nul 2>&1
if errorlevel 1 (
    echo ❌ Required packages missing (requests)
    set "SETUP_NEEDED=1"
    goto :install_packages
) else (
    echo ✅ All required packages found
    goto :server_discovery
)

:python_setup
if %SETUP_NEEDED% equ 1 (
    echo.
    echo ================================================================
    echo 🔧 PYTHON SETUP REQUIRED
    echo ================================================================
    echo.
    echo Choose setup option:
    echo   1. Auto-download portable Python ^(RECOMMENDED^)
    echo   2. Use existing Python and install packages
    echo   3. Continue without Python ^(basic features only^)
    echo.
    set /p "choice=Enter choice (1-3): "
    
    if "!choice!"=="1" goto :download_python
    if "!choice!"=="2" goto :install_packages
    if "!choice!"=="3" goto :batch_mode
    
    echo Invalid choice, using portable Python...
    goto :download_python
)

:download_python
echo.
echo 📥 Downloading portable Python 3.11.8...
echo This may take 5-10 minutes depending on your internet speed.
echo.

:: Create portable_python directory
if not exist "portable_python" mkdir portable_python

:: Download Python embeddable
echo Downloading Python embeddable package...
powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://www.python.org/ftp/python/3.11.8/python-3.11.8-embed-amd64.zip' -OutFile 'python-embed.zip'}" 2>nul

if not exist "python-embed.zip" (
    echo ❌ Failed to download Python. Trying alternative method...
    curl -L -o python-embed.zip "https://www.python.org/ftp/python/3.11.8/python-3.11.8-embed-amd64.zip" 2>nul
)

if not exist "python-embed.zip" (
    echo ❌ Download failed. Please check your internet connection.
    echo Falling back to batch mode...
    goto :batch_mode
)

:: Extract Python
echo Extracting Python...
powershell -Command "Expand-Archive -Path 'python-embed.zip' -DestinationPath 'portable_python' -Force" 2>nul
del python-embed.zip 2>nul

:: Enable pip by uncommenting import site
if exist "portable_python\python311._pth" (
    powershell -Command "(Get-Content 'portable_python\python311._pth') -replace '^#import site', 'import site' | Set-Content 'portable_python\python311._pth'"
)

:: Download and install pip
echo Setting up pip...
if not exist "portable_python\get-pip.py" (
    powershell -Command "Invoke-WebRequest -Uri 'https://bootstrap.pypa.io/get-pip.py' -OutFile 'portable_python\get-pip.py'" 2>nul
)

if exist "portable_python\get-pip.py" (
    portable_python\python.exe portable_python\get-pip.py --quiet 2>nul
)

:: Create virtual environment
echo Creating virtual environment...
portable_python\python.exe -m venv venv 2>nul

if exist "venv\Scripts\python.exe" (
    set "PYTHON_CMD=venv\Scripts\python.exe"
    echo ✅ Virtual environment created successfully
) else (
    set "PYTHON_CMD=portable_python\python.exe"
    echo ✅ Using portable Python directly
)

goto :install_packages

:install_packages
echo.
echo 📦 Installing required packages...

:: Try pip install with current Python command
echo Trying: %PYTHON_CMD% -m pip install requests
%PYTHON_CMD% -m pip install requests --quiet --disable-pip-version-check 2>nul
if not errorlevel 1 (
    echo ✅ Packages installed successfully
    goto :server_discovery
)

:: Try pip3 if pip failed
echo Trying: %PYTHON_CMD% -m pip3 install requests
%PYTHON_CMD% -m pip3 install requests --quiet --disable-pip-version-check 2>nul
if not errorlevel 1 (
    echo ✅ Packages installed successfully
    goto :server_discovery
)

:: Try direct pip command
echo Trying: pip install requests
pip install requests --quiet --disable-pip-version-check 2>nul
if not errorlevel 1 (
    echo ✅ Packages installed successfully
    goto :server_discovery
)

:: Try pip3 command
echo Trying: pip3 install requests
pip3 install requests --quiet --disable-pip-version-check 2>nul
if not errorlevel 1 (
    echo ✅ Packages installed successfully
    goto :server_discovery
)

:: All pip methods failed
echo ❌ Failed to install packages with all methods
echo ⚠️  Python found but package installation failed
echo 💡 You may need to install packages manually: pip install requests
echo 💡 Or run: python -m pip install requests
echo Falling back to batch mode...
goto :batch_mode

:batch_mode
echo.
echo ================================================================
echo 📄 BATCH MODE - BASIC FUNCTIONALITY
echo ================================================================
set "PYTHON_CMD="
goto :server_discovery

:: =============================================================================
:: STEP 2: SERVER DISCOVERY
:: =============================================================================
:server_discovery
echo.
echo ================================================================
echo 🔍 STEP 2: OLLAMA SERVER DISCOVERY
echo ================================================================

set "SERVER_IP="
set "SERVER_PORT=11434"

:: Check last known connection
if exist "remote_connection.txt" (
    set /p LAST_IP=<remote_connection.txt
    echo 📁 Trying last known server: !LAST_IP!
    call :test_connection "!LAST_IP!" && (
        set "SERVER_IP=!LAST_IP!"
        echo ✅ Connected to last known server: !LAST_IP!
        goto :start_chat
    )
)

:: Try localhost first
echo 🏠 Testing localhost...
for %%H in (127.0.0.1 localhost) do (
    call :test_connection "%%H" && (
        set "SERVER_IP=%%H"
        echo ✅ Found server at localhost: %%H
        goto :start_chat
    )
)

:: Get current machine's IP for reference
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4 Address"') do (
    set "CURRENT_IP=%%a"
    set "CURRENT_IP=!CURRENT_IP: =!"
    echo 💻 Current machine IP: !CURRENT_IP!
    break
)

:: Network scan - try common IP ranges
echo 🌐 Scanning network for Ollama servers...
echo This may take 1-2 minutes...

:: Try current subnet first (most likely)
if defined CURRENT_IP (
    for /f "tokens=1,2,3 delims=." %%a in ("!CURRENT_IP!") do (
        set "SUBNET=%%a.%%b.%%c"
        echo Scanning subnet: !SUBNET!.x
        for /l %%i in (1,1,254) do (
            if not defined SERVER_IP (
                call :test_connection "!SUBNET!.%%i" && (
                    set "SERVER_IP=!SUBNET!.%%i"
                    echo ✅ Found server at: !SUBNET!.%%i
                    goto :start_chat
                )
            )
        )
    )
)

:: Try common private network ranges
for %%R in (192.168.1 192.168.0 10.0.0 172.16.0) do (
    if not defined SERVER_IP (
        echo Scanning: %%R.x
        for /l %%i in (1,1,254) do (
            if not defined SERVER_IP (
                call :test_connection "%%R.%%i" && (
                    set "SERVER_IP=%%R.%%i"
                    echo ✅ Found server at: %%R.%%i
                    goto :start_chat
                )
            )
        )
    )
)

:: Manual IP entry if auto-discovery fails
echo.
echo ❌ Auto-discovery failed to find Ollama server
echo.
echo Please make sure:
echo   1. Ollama server is running with network access (quick_start.bat)
echo   2. Both devices are on the same network
echo   3. Windows Firewall allows Ollama (port 11434)
echo.
set /p "MANUAL_IP=Enter Ollama server IP manually (or press Enter to exit): "
if "!MANUAL_IP!"=="" goto :error_exit

call :test_connection "!MANUAL_IP!" && (
    set "SERVER_IP=!MANUAL_IP!"
    echo ✅ Connected to manually entered server: !MANUAL_IP!
    goto :start_chat
) || (
    echo ❌ Could not connect to !MANUAL_IP!
    goto :error_exit
)

:: =============================================================================
:: STEP 3: START CHAT
:: =============================================================================
:start_chat
echo.
echo ================================================================
echo 💬 STEP 3: STARTING CHAT SESSION
echo ================================================================

:: Save successful connection for next time
echo !SERVER_IP!>remote_connection.txt
echo ✅ Connection info saved for next time

:: Get available models and detect which one is currently loaded/running
echo 🔍 Detecting active model on server...
set "SELECTED_MODEL="
set "MODEL_STATUS="

:: Try to get running processes/models first
curl -s --connect-timeout 5 "http://!SERVER_IP!:!SERVER_PORT!/api/ps" > temp_running.json 2>nul
if exist temp_running.json (
    echo 📊 Checking for currently loaded models...
    
    :: Parse running models from JSON using PowerShell
    for /f "usebackq delims=" %%i in (`powershell -Command "try { $json = Get-Content 'temp_running.json' | ConvertFrom-Json; if ($json.models -and $json.models.Count -gt 0) { $json.models[0].name } else { '' } } catch { '' }"`) do (
        if not "%%i"=="" (
            set "SELECTED_MODEL=%%i"
            set "MODEL_STATUS=ACTIVE"
            echo ✅ Found active model in memory: %%i
            goto model_detected
        )
    )
    del temp_running.json 2>nul
)

:model_detected
:: If no running model found, get first available model
if not defined SELECTED_MODEL (
    echo 📋 No model currently loaded in memory, checking available models...
    curl -s --connect-timeout 5 "http://!SERVER_IP!:!SERVER_PORT!/api/tags" > temp_models.json 2>nul
    if exist temp_models.json (
        echo 🔍 Getting first available model...
        
        :: Parse models from JSON using PowerShell and get the first one
        for /f "usebackq delims=" %%i in (`powershell -Command "try { $json = Get-Content 'temp_models.json' | ConvertFrom-Json; if ($json.models -and $json.models.Count -gt 0) { $json.models[0].name } else { '' } } catch { '' }"`) do (
            if not "%%i"=="" (
                set "SELECTED_MODEL=%%i"
                set "MODEL_STATUS=AVAILABLE"
                echo ✅ Using first available model: %%i
                goto model_found
            )
        )
        del temp_models.json 2>nul
    )
)

:model_found
:: Ensure we have a valid model name
if "!SELECTED_MODEL!"=="" (
    set "SELECTED_MODEL=tinyllama:latest"
    set "MODEL_STATUS=FALLBACK"
    echo 🔧 No models detected, using fallback: !SELECTED_MODEL!
    goto model_status_done
)

:: Display status based on MODEL_STATUS
if "!MODEL_STATUS!"=="ACTIVE" (
    echo ✅ Auto-selected model: !SELECTED_MODEL! (currently loaded in memory)
    goto model_status_done
)
if "!MODEL_STATUS!"=="AVAILABLE" (
    echo ✅ Auto-selected model: !SELECTED_MODEL! (will be loaded on first use)
    goto model_status_done
)
echo ✅ Auto-selected model: !SELECTED_MODEL!

:model_status_done

echo.
echo 💡 NOTE: The system detected the ACTUAL model currently active on the server.
echo 💡 If this is not the model you expected, check the server's quickstart menu.

echo.

:: Choose chat method based on available Python
if defined PYTHON_CMD (
    echo 🐍 Starting Python chat client...
    goto :python_chat
) else (
    echo 📄 Starting batch chat client...
    goto :batch_chat
)

:python_chat
echo.
echo ================================================================
echo 🤖 PYTHON CHAT MODE - Advanced Features Available
echo ================================================================
echo Connected to: !SERVER_IP!:!SERVER_PORT!

:: Display model status
if "!MODEL_STATUS!"=="ACTIVE" (
    echo Model: !SELECTED_MODEL! (currently loaded in memory)
    goto python_chat_continue
)
if "!MODEL_STATUS!"=="AVAILABLE" (
    echo Model: !SELECTED_MODEL! (will be loaded on first use)
    goto python_chat_continue
)
echo Model: !SELECTED_MODEL!

:python_chat_continue
echo Type 'quit' or 'exit' to end the chat
echo Type 'models' to see all available models
echo ================================================================
echo.

:: Use existing Python client instead of generating temp file
if exist "smart_remote_client.py" (
    echo Starting smart remote client with auto-detected model: !SELECTED_MODEL!...
    %PYTHON_CMD% smart_remote_client.py --host !SERVER_IP! --model !SELECTED_MODEL!
) else if exist "remote_chat_client.py" (
    echo Starting remote chat client with auto-detected model: !SELECTED_MODEL!...
    %PYTHON_CMD% remote_chat_client.py --host !SERVER_IP! --model !SELECTED_MODEL!
) else (
    echo No Python client found, using fallback batch mode...
    goto :batch_chat
)

goto :end_session

:batch_chat
echo.
echo ================================================================
echo 🤖 BATCH CHAT MODE - Basic Chat Available
echo ================================================================
echo Connected to: !SERVER_IP!:!SERVER_PORT!

:: Display model status
if "!MODEL_STATUS!"=="ACTIVE" (
    echo Model: !SELECTED_MODEL! (currently loaded in memory)
    goto batch_chat_continue
)
if "!MODEL_STATUS!"=="AVAILABLE" (
    echo Model: !SELECTED_MODEL! (will be loaded on first use)
    goto batch_chat_continue
)
echo Model: !SELECTED_MODEL!

:batch_chat_continue
echo Type 'quit' to end the chat
echo Type 'models' to see all available models
echo Type 'refresh' to re-detect active model
echo ================================================================
echo.

:batch_chat_loop
set /p "user_input=You: "
if /i "!user_input!"=="quit" goto :end_session
if /i "!user_input!"=="models" goto :show_models_batch
if /i "!user_input!"=="refresh" goto :refresh_model_batch
if "!user_input!"=="" goto :batch_chat_loop

:: Create temporary request file with auto-detected model
echo {"model":"!SELECTED_MODEL!","prompt":"!user_input!","stream":false} > temp_request.json

:: Send request and get response
echo 🤖 AI (!SELECTED_MODEL!): 
curl -s -X POST "http://!SERVER_IP!:!SERVER_PORT!/api/generate" -H "Content-Type: application/json" -d @temp_request.json 2>nul | findstr /C:"response" | for /f "tokens=2 delims=:" %%a in ('more') do (
    set "response=%%a"
    set "response=!response:~1,-1!"
    set "response=!response:\"=!"
    echo !response!
)

del temp_request.json 2>nul
echo.
goto :batch_chat_loop

:show_models_batch
echo.
echo 📋 Available models on server:
curl -s --connect-timeout 5 "http://!SERVER_IP!:!SERVER_PORT!/api/tags" > temp_models.json 2>nul
if exist temp_models.json (
    set "model_count=0"
    for /f "usebackq delims=" %%i in (`powershell -Command "try { $json = Get-Content 'temp_models.json' | ConvertFrom-Json; $json.models | ForEach-Object { $_.name } } catch { }"`) do (
        set /a model_count+=1
        set "model_!model_count!=%%i"
        if "%%i"=="!SELECTED_MODEL!" (
            echo   !model_count!. %%i (CURRENTLY ACTIVE)
        ) else (
            echo   !model_count!. %%i
        )
    )
    
    echo.
    echo ✅ Currently using: !SELECTED_MODEL! (auto-detected)
    echo 💡 The system automatically uses the active model on the server
    echo 💡 Type 'refresh' to re-detect the active model
    
    del temp_models.json 2>nul
) else (
    echo ❌ Could not get models list
)
echo.
goto :batch_chat_loop

:refresh_model_batch
echo.
echo 🔄 Re-detecting active model on server...

:: Re-run the model detection logic
set "OLD_MODEL=!SELECTED_MODEL!"
set "SELECTED_MODEL="

:: Try to get running processes/models first
curl -s --connect-timeout 5 "http://!SERVER_IP!:!SERVER_PORT!/api/ps" > temp_running.json 2>nul
if exist temp_running.json (
    for /f "usebackq delims=" %%i in (`powershell -Command "try { $json = Get-Content 'temp_running.json' | ConvertFrom-Json; if ($json.models -and $json.models.Count -gt 0) { $json.models[0].name } else { '' } } catch { '' }"`) do (
        if not "%%i"=="" (
            set "SELECTED_MODEL=%%i"
            if "!SELECTED_MODEL!"=="!OLD_MODEL!" (
                echo ✅ Model unchanged: !SELECTED_MODEL!
            ) else (
                echo ✅ Model changed from !OLD_MODEL! to !SELECTED_MODEL!
            )
            goto refresh_done
        )
    )
    del temp_running.json 2>nul
)

:: If no running model found, get first available model
if not defined SELECTED_MODEL (
    curl -s --connect-timeout 5 "http://!SERVER_IP!:!SERVER_PORT!/api/tags" > temp_models.json 2>nul
    if exist temp_models.json (
        for /f "usebackq delims=" %%i in (`powershell -Command "try { $json = Get-Content 'temp_models.json' | ConvertFrom-Json; if ($json.models -and $json.models.Count -gt 0) { $json.models[0].name } else { '' } } catch { '' }"`) do (
            if not "%%i"=="" (
                set "SELECTED_MODEL=%%i"
                if "!SELECTED_MODEL!"=="!OLD_MODEL!" (
                    echo ✅ Model unchanged: !SELECTED_MODEL!
                ) else (
                    echo ✅ Model changed from !OLD_MODEL! to !SELECTED_MODEL!
                )
                goto refresh_done
            )
        )
        del temp_models.json 2>nul
    )
)

:refresh_done
if "!SELECTED_MODEL!"=="" (
    set "SELECTED_MODEL=!OLD_MODEL!"
    echo ⚠️  Could not detect model, keeping: !SELECTED_MODEL!
)
echo.
goto :batch_chat_loop

:: =============================================================================
:: HELPER FUNCTIONS
:: =============================================================================
:test_connection
set "test_ip=%~1"
:: Quick connection test using curl (faster than ping for HTTP)
curl -s --connect-timeout 2 "http://%test_ip%:11434/api/tags" >nul 2>&1
exit /b %errorlevel%

:error_exit
echo.
echo ================================================================
echo ❌ CONNECTION FAILED
echo ================================================================
echo.
echo Troubleshooting steps:
echo   1. Make sure Ollama server is running on the host machine
echo   2. Run 'quick_start.bat' on the host machine
echo   3. Check that both devices are on the same network
echo   4. Verify Windows Firewall allows Ollama (port 11434)
echo   5. Try running this script again
echo.
pause
exit /b 1

:end_session
echo.
echo ================================================================
echo 🎯 SESSION COMPLETE
echo ================================================================
echo.
echo ✅ Connection details saved for next time
echo ✅ To chat again, just run this file: connect_to_ollama.bat
echo.
echo Your remote device is now set up! Next time it will connect faster.
echo.
pause
exit /b 0
