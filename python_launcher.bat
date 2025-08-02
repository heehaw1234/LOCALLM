@echo off
setlocal enabledelayedexpansion

REM ==================================================
REM Python Environment Detection and Launcher
REM Automatically finds and uses the best Python setup
REM ==================================================

set "PYTHON_CMD="

REM Function to test Python and run command
:find_python
echo 🔍 Finding Python environment...

REM Try virtual environment first
if exist "venv\Scripts\python.exe" (
    echo ✅ Found virtual environment
    set "PYTHON_CMD=venv\Scripts\python.exe"
    goto :run_python
)

REM Try portable Python
if exist "portable_python\python.exe" (
    echo ✅ Found portable Python
    set "PYTHON_CMD=portable_python\python.exe"
    goto :run_python
)

REM Try system Python
python --version >nul 2>&1
if !errorlevel! equ 0 (
    echo ✅ Found system Python
    set "PYTHON_CMD=python"
    goto :run_python
)

REM Try py launcher
py --version >nul 2>&1
if !errorlevel! equ 0 (
    echo ✅ Found Python via py launcher
    set "PYTHON_CMD=py"
    goto :run_python
)

REM No Python found
echo ❌ No Python found
echo 💡 Run python_setup.bat to install Python
echo 💡 Or use remote_chat_service.bat (no Python needed)
pause
exit /b 1

:run_python
echo 🐍 Using: !PYTHON_CMD!

REM Check if requests is available
echo 🔍 Checking Python packages...
!PYTHON_CMD! -c "import requests" >nul 2>&1
if !errorlevel! neq 0 (
    echo ⚠️  Missing 'requests' package
    echo 📦 Installing requests...
    !PYTHON_CMD! -m pip install requests --user --quiet
    if !errorlevel! neq 0 (
        echo ❌ Failed to install requests
        echo 💡 Try running python_setup.bat
        pause
        exit /b 1
    )
    echo ✅ Requests installed
)

REM Run the smart client with all arguments
echo 🚀 Starting smart remote client...
echo.
!PYTHON_CMD! smart_remote_client.py %*

exit /b 0
