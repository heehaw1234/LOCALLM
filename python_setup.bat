@echo off
setlocal enabledelayedexpansion

REM ==================================================
REM Python Environment Setup for Remote Ollama Chat
REM Downloads and sets up portable Python if not found
REM ==================================================

title Python Environment Setup

echo.
echo ============================================
echo     🐍 Python Environment Setup
echo ============================================
echo.

REM Check if Python is already available
echo 🔍 Checking for Python installation...

REM Try python command
python --version >nul 2>&1
if !errorlevel! equ 0 (
    echo ✅ Python found in PATH
    python --version
    echo 💡 You can use the Python clients directly
    goto :python_ready
)

REM Try py command (Windows Python Launcher)
py --version >nul 2>&1
if !errorlevel! equ 0 (
    echo ✅ Python found via py launcher
    py --version
    echo 💡 You can use: py smart_remote_client.py
    goto :python_ready
)

REM Try common Python installation paths
set "python_paths="
set "python_paths=!python_paths! C:\Python3\python.exe"
set "python_paths=!python_paths! C:\Python39\python.exe"
set "python_paths=!python_paths! C:\Python310\python.exe"
set "python_paths=!python_paths! C:\Python311\python.exe"
set "python_paths=!python_paths! C:\Python312\python.exe"
set "python_paths=!python_paths! C:\Python313\python.exe"
set "python_paths=!python_paths! %LOCALAPPDATA%\Programs\Python\Python39\python.exe"
set "python_paths=!python_paths! %LOCALAPPDATA%\Programs\Python\Python310\python.exe"
set "python_paths=!python_paths! %LOCALAPPDATA%\Programs\Python\Python311\python.exe"
set "python_paths=!python_paths! %LOCALAPPDATA%\Programs\Python\Python312\python.exe"
set "python_paths=!python_paths! %LOCALAPPDATA%\Programs\Python\Python313\python.exe"

for %%p in (!python_paths!) do (
    if exist "%%p" (
        echo ✅ Python found at: %%p
        "%%p" --version
        set "PYTHON_EXE=%%p"
        goto :python_ready
    )
)

echo ❌ Python not found on this system
echo.
echo 🎯 Options:
echo    1. Download and setup portable Python (recommended)
echo    2. Install Python from python.org
echo    3. Use batch files only (no Python features)
echo    4. Exit
echo.

set /p "choice=Enter your choice (1-4): "

if "!choice!"=="1" goto :setup_portable
if "!choice!"=="2" goto :install_python
if "!choice!"=="3" goto :batch_only
if "!choice!"=="4" goto :end

goto :end

:setup_portable
echo.
echo ============================================
echo     📦 Setting Up Portable Python
echo ============================================
echo.

REM Check if we already have a portable Python setup
if exist "portable_python\python.exe" (
    echo ✅ Portable Python already exists
    echo 🔍 Testing portable Python...
    portable_python\python.exe --version
    if !errorlevel! equ 0 (
        echo ✅ Portable Python is working
        set "PYTHON_EXE=portable_python\python.exe"
        goto :setup_venv
    ) else (
        echo ❌ Portable Python is corrupted, will re-download
        rmdir /s /q portable_python >nul 2>&1
    )
)

echo 📥 Downloading portable Python...
echo 💡 This may take a few minutes depending on your internet speed
echo.

REM Create download directory
if not exist "temp_download" mkdir temp_download

REM Download Python embeddable package (Python 3.11)
set "PYTHON_URL=https://www.python.org/ftp/python/3.11.8/python-3.11.8-embed-amd64.zip"
set "PYTHON_ZIP=temp_download\python-embed.zip"

echo 🌐 Downloading from: %PYTHON_URL%

REM Use PowerShell to download (works on most Windows systems)
powershell -Command "& {try { Invoke-WebRequest -Uri '%PYTHON_URL%' -OutFile '%PYTHON_ZIP%' -UseBasicParsing; Write-Host 'Download completed' } catch { Write-Host 'Download failed:' $_.Exception.Message; exit 1 }}"

if !errorlevel! neq 0 (
    echo ❌ Download failed
    echo 💡 Please check your internet connection and try again
    echo 💡 Or choose option 2 to install Python manually
    pause
    goto :end
)

if not exist "%PYTHON_ZIP%" (
    echo ❌ Download file not found
    echo 💡 Please try again or install Python manually
    pause
    goto :end
)

echo ✅ Download completed
echo 📦 Extracting Python...

REM Extract using PowerShell
powershell -Command "& {Expand-Archive -Path '%PYTHON_ZIP%' -DestinationPath 'portable_python' -Force}"

if !errorlevel! neq 0 (
    echo ❌ Extraction failed
    pause
    goto :end
)

REM Download get-pip.py
echo 📦 Setting up pip...
powershell -Command "& {Invoke-WebRequest -Uri 'https://bootstrap.pypa.io/get-pip.py' -OutFile 'temp_download\get-pip.py' -UseBasicParsing}"

REM Install pip
portable_python\python.exe temp_download\get-pip.py --no-warn-script-location

REM Cleanup
rmdir /s /q temp_download >nul 2>&1

echo ✅ Portable Python setup complete
set "PYTHON_EXE=portable_python\python.exe"

goto :setup_venv

:setup_venv
echo.
echo ============================================
echo     🔧 Setting Up Virtual Environment
echo ============================================
echo.

REM Create virtual environment
if exist "venv" (
    echo 🔄 Virtual environment already exists, recreating...
    rmdir /s /q venv >nul 2>&1
)

echo 📦 Creating virtual environment...
"%PYTHON_EXE%" -m venv venv

if !errorlevel! neq 0 (
    echo ❌ Failed to create virtual environment
    echo 💡 Trying without venv module...
    goto :install_packages_direct
)

echo ✅ Virtual environment created

REM Activate virtual environment and install packages
echo 📦 Installing required packages...
call venv\Scripts\activate.bat

REM Install requests
pip install requests

if !errorlevel! neq 0 (
    echo ❌ Failed to install packages in venv
    echo 💡 Trying direct installation...
    call venv\Scripts\deactivate.bat
    goto :install_packages_direct
)

echo ✅ Virtual environment setup complete
call venv\Scripts\deactivate.bat

REM Create activation script
echo @echo off> activate_python.bat
echo call venv\Scripts\activate.bat>> activate_python.bat
echo echo ✅ Python virtual environment activated>> activate_python.bat
echo echo 💡 You can now run: python smart_remote_client.py>> activate_python.bat

REM Create Python launcher scripts
echo @echo off> python_chat.bat
echo call venv\Scripts\activate.bat>> python_chat.bat
echo python smart_remote_client.py %%*>> python_chat.bat
echo call venv\Scripts\deactivate.bat>> python_chat.bat

echo @echo off> python_scan.bat
echo call venv\Scripts\activate.bat>> python_scan.bat
echo python smart_remote_client.py --scan>> python_scan.bat
echo call venv\Scripts\deactivate.bat>> python_scan.bat
echo pause>> python_scan.bat

goto :python_ready

:install_packages_direct
echo 📦 Installing packages directly...
"%PYTHON_EXE%" -m pip install requests --user

if !errorlevel! neq 0 (
    echo ❌ Failed to install packages
    echo 💡 You can still use batch files for basic functionality
    goto :batch_only
)

echo ✅ Packages installed

REM Create direct Python launcher
echo @echo off> python_chat.bat
echo "%PYTHON_EXE%" smart_remote_client.py %%*>> python_chat.bat

echo @echo off> python_scan.bat
echo "%PYTHON_EXE%" smart_remote_client.py --scan>> python_scan.bat
echo pause>> python_scan.bat

goto :python_ready

:python_ready
echo.
echo ============================================
echo     ✅ Python Environment Ready
echo ============================================
echo.
echo 🐍 Python is now available for Ollama chat clients
echo.
echo 📋 Available commands:
if exist "venv\Scripts\python.exe" (
    echo    💡 python_chat.bat    - Start smart Python chat client
    echo    💡 python_scan.bat    - Scan for Ollama servers
    echo    💡 activate_python.bat - Activate Python environment
) else if defined PYTHON_EXE (
    echo    💡 python_chat.bat    - Start smart Python chat client  
    echo    💡 python_scan.bat    - Scan for Ollama servers
) else (
    echo    💡 python smart_remote_client.py - Direct Python client
)
echo    💡 remote_chat_service.bat - Windows batch service (no Python needed)
echo.
echo 🎯 Recommended: Try python_chat.bat for the best experience
echo.
goto :end

:install_python
echo.
echo ============================================
echo     🌐 Install Python from Official Site
echo ============================================
echo.
echo 📥 Opening Python download page...
echo 💡 Download Python 3.11 or newer from python.org
echo 💡 Make sure to check "Add Python to PATH" during installation
echo.

start https://www.python.org/downloads/

echo ⏳ After installing Python:
echo    1. Restart this script
echo    2. Python will be automatically detected
echo    3. Or run: python_setup.bat again
echo.
pause
goto :end

:batch_only
echo.
echo ============================================
echo     📄 Batch Files Only Mode
echo ============================================
echo.
echo 💡 You can use these Windows batch files without Python:
echo.
echo    ✅ remote_chat_service.bat - Complete chat service
echo    ✅ remote_chat.bat         - Simple chat interface
echo.
echo 🚫 These features require Python (not available):
echo    ❌ smart_remote_client.py  - Advanced Python client
echo    ❌ Network scanning tools
echo    ❌ Advanced configuration
echo.
echo 🎯 Try remote_chat_service.bat - it works great without Python!
echo.
goto :end

:end
echo.
echo 👋 Python setup complete!
echo 💡 You can run this script again anytime to reconfigure Python
echo.
pause
exit /b 0
