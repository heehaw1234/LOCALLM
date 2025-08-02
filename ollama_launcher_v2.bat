@echo off
setlocal enabledelayedexpansion
title Ollama Smart Launcher v2
color 0A

echo.
echo ========================================
echo        🦙 Ollama Smart Launcher v2
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
set WIFI_IP=
set ETHERNET_IP=

REM Get Wi-Fi IP address
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr "IPv4" ^| findstr /v "127.0.0.1"') do (
    set WIFI_IP=%%a
    set WIFI_IP=!WIFI_IP: =!
    goto wifi_found
)
:wifi_found

REM Get Ethernet IP address (fallback)
if not defined WIFI_IP (
    for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr "IPv4" ^| findstr /v "127.0.0.1"') do (
        set ETHERNET_IP=%%a
        set ETHERNET_IP=!ETHERNET_IP: =!
        goto ethernet_found
    )
    :ethernet_found
)

REM Use the first available IP (prefer Wi-Fi)
if defined WIFI_IP (
    set LOCAL_IP=!WIFI_IP!
    echo    Wi-Fi IP: !WIFI_IP!
) else if defined ETHERNET_IP (
    set LOCAL_IP=!ETHERNET_IP!
    echo    Ethernet IP: !ETHERNET_IP!
) else (
    REM Fallback method
    for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr "IPv4" ^| findstr /v "127.0.0.1"') do (
        set LOCAL_IP=%%a
        set LOCAL_IP=!LOCAL_IP: =!
        goto ip_found
    )
    :ip_found
    echo    Detected IP: !LOCAL_IP!
)

if not defined LOCAL_IP (
    echo    ⚠️  Could not detect IP address - using localhost only
    set LOCAL_IP=localhost
) else (
    echo    ✅ Network IP: !LOCAL_IP!
)

REM Detect network name if possible
for /f "tokens=1" %%a in ('netsh wlan show profiles ^| findstr "All User Profile"') do (
    echo    Current Network: %%a
    goto network_found
)
:network_found

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
    echo 🚀 Starting Ollama server...
    start /b cmd /c "set OLLAMA_HOST=0.0.0.0:11434 && ollama serve"
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
)
echo ✅ Server is running!
echo.

REM Get models using simple method
echo 📋 Getting installed models...
set model_count=0
set model_list=

REM Create a temporary file to capture ollama list output
ollama list > temp_models.txt 2>&1

REM Parse models (skip header line)
for /f "skip=1 tokens=1 delims= " %%i in (temp_models.txt) do (
    if not "%%i"=="" (
        if not "%%i"=="NAME" (
            set /a model_count+=1
            set model!model_count!=%%i
            echo !model_count!. %%i
        )
    )
)

del temp_models.txt >nul 2>&1

echo.
echo Found !model_count! models available!

if !model_count!==0 (
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
            goto get_models_again
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
)

:get_models_again
REM Refresh model list if we just installed one
if !model_count!==0 (
    echo 📋 Refreshing model list...
    set model_count=0
    ollama list > temp_models.txt 2>&1
    for /f "skip=1 tokens=1 delims= " %%i in (temp_models.txt) do (
        if not "%%i"=="" (
            if not "%%i"=="NAME" (
                set /a model_count+=1
                set model!model_count!=%%i
                echo !model_count!. %%i
            )
        )
    )
    del temp_models.txt >nul 2>&1
)

echo.
echo Found !model_count! models available!
echo.

:main_menu
echo 🎯 What would you like to do?
echo 1. Chat with a model interactively
echo 2. Test a single prompt
echo 3. Keep server running for network access
echo 4. Install more models
echo 5. Exit
echo.
set /p action_choice="Enter your choice (1-5): "

if "!action_choice!"=="1" goto interactive_chat
if "!action_choice!"=="2" goto single_prompt
if "!action_choice!"=="3" goto network_mode
if "!action_choice!"=="4" goto install_models
if "!action_choice!"=="5" goto cleanup
echo Invalid choice. Please try again.
goto main_menu

:interactive_chat
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
        echo    Type '/bye' to exit chat mode
        echo ========================================
        ollama run !selected_model!
        echo.
        echo Chat session ended.
    ) else (
        echo Invalid model choice.
        pause
    )
) else (
    echo No models available. Please install one first.
    pause
)
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

:network_mode
echo.
echo 🌐 Network Mode Active
echo =====================

REM Re-detect IP address in case it changed
echo � Refreshing network configuration...
set LOCAL_IP=
set WIFI_IP=
set ETHERNET_IP=

REM Get current Wi-Fi IP
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr "IPv4" ^| findstr /v "127.0.0.1"') do (
    set WIFI_IP=%%a
    set WIFI_IP=!WIFI_IP: =!
    goto current_wifi_found
)
:current_wifi_found

REM Get current Ethernet IP (fallback)
if not defined WIFI_IP (
    for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr "IPv4" ^| findstr /v "127.0.0.1"') do (
        set ETHERNET_IP=%%a
        set ETHERNET_IP=!ETHERNET_IP: =!
        goto current_ethernet_found
    )
    :current_ethernet_found
)

REM Use the first available IP
if defined WIFI_IP (
    set LOCAL_IP=!WIFI_IP!
    echo    Active Network: Wi-Fi (!WIFI_IP!)
) else if defined ETHERNET_IP (
    set LOCAL_IP=!ETHERNET_IP!
    echo    Active Network: Ethernet (!ETHERNET_IP!)
) else (
    for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr "IPv4" ^| findstr /v "127.0.0.1"') do (
        set LOCAL_IP=%%a
        set LOCAL_IP=!LOCAL_IP: =!
        goto current_ip_found
    )
    :current_ip_found
    echo    Detected IP: !LOCAL_IP!
)

echo.
echo 🔗 Your Ollama server is accessible at:
if defined LOCAL_IP (
    if not "!LOCAL_IP!"=="localhost" (
        echo    📱 Network: http://!LOCAL_IP!:11434
        echo    🌐 Web Interface: http://!LOCAL_IP!:8000/web (if proxy running)
    )
)
echo    🏠 Local: http://localhost:11434
echo.

echo 📋 Connection URLs for other devices:
if defined LOCAL_IP (
    if not "!LOCAL_IP!"=="localhost" (
        echo    • Direct API: http://!LOCAL_IP!:11434
        echo    • Web Chat: Open web_interface.html, use http://!LOCAL_IP!:11434
        echo    • Proxy Server: http://!LOCAL_IP!:8000 (run interface_launcher.bat)
        echo    • CLI from other device: python cli_client.py --host !LOCAL_IP!
    ) else (
        echo    ⚠️  Network access not available (no IP detected)
        echo    Only local access: http://localhost:11434
    )
) else (
    echo    ⚠️  Could not detect network IP address
)
echo.

echo 💡 Quick Setup for Other Devices:
if defined LOCAL_IP (
    if not "!LOCAL_IP!"=="localhost" (
        echo    1. Connect device to same Wi-Fi network
        echo    2. Use this URL: http://!LOCAL_IP!:11434
        echo    3. Test in browser: http://!LOCAL_IP!:11434/api/tags
    )
)
echo.

echo 📱 Available interfaces:
echo    • Web Interface: Double-click web_interface.html
echo    • API Proxy: Run interface_launcher.bat  
echo    • CLI Client: python cli_client.py --host !LOCAL_IP!
echo.
echo 📋 Available models:
if !model_count! gtr 0 (
    for /L %%i in (1,1,!model_count!) do (
        call echo    - %%model%%i%%
    )
) else (
    echo    No models installed
)
echo.

echo 🔄 Network Status:
if defined WIFI_IP echo    Wi-Fi: !WIFI_IP!
if defined ETHERNET_IP echo    Ethernet: !ETHERNET_IP!
echo    Ollama Host: %OLLAMA_HOST%
echo.

echo 💡 To stop the server: Press Ctrl+C or close this window
echo    Server will keep running in background...
echo    IP will be re-detected each time you access this menu
echo.
pause
goto main_menu

:install_models
echo.
echo 📦 Model Installation
echo ====================
echo.
echo 🤖 Available Ollama Models:
echo.
echo 🚀 RECOMMENDED MODELS (Fast & Popular):
echo 1. tinyllama:latest (1.1GB) - Very fast, good for testing
echo 2. llama3.2:1b (1.3GB) - Meta's latest, ultra fast
echo 3. llama3.2:3b (2.0GB) - Meta's latest, balanced
echo 4. qwen2.5:0.5b (0.4GB) - Alibaba's smallest model
echo 5. qwen2.5:1.5b (0.9GB) - Alibaba's fast model
echo.
echo 💻 CODING MODELS:
echo 6. qwen2.5-coder:1.5b (0.9GB) - Code generation, fast
echo 7. qwen2.5-coder:7b (4.4GB) - Advanced coding
echo 8. qwen2.5-coder:14b (8.2GB) - Professional coding
echo 9. qwen2.5-coder:32b (18GB) - Expert coding
echo 10. codellama:7b (3.8GB) - Meta's code model
echo 11. codellama:13b (7.3GB) - Larger code model
echo 12. codellama:34b (19GB) - Largest code model
echo 13. starcoder2:3b (1.7GB) - Efficient coding
echo 14. starcoder2:7b (4.0GB) - Balanced coding
echo 15. starcoder2:15b (8.5GB) - Advanced coding
echo.
echo 🧠 GENERAL PURPOSE MODELS:
echo 16. llama3.1:8b (4.7GB) - Meta's flagship model
echo 17. llama3.1:70b (40GB) - Meta's large model
echo 18. llama3.1:405b (231GB) - Meta's largest (requires 128GB+ RAM)
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
    echo    • Large models (70B+) require significant RAM (32GB+ recommended)
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

:cleanup
echo.
echo 🧹 Do you want to stop the Ollama server?
set /p stop_server="Stop server? (y/n): "
if /i "!stop_server!"=="y" (
    echo Stopping Ollama server...
    taskkill /f /im ollama.exe >nul 2>&1
    echo ✅ Server stopped
)
echo.
echo 👋 Goodbye!
timeout /t 2 /nobreak >nul
exit
