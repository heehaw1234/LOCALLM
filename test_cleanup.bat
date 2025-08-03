@echo off
echo Testing Ollama server status...
echo.

echo 1. Checking if any Ollama processes are running:
tasklist | findstr ollama
if %errorlevel% neq 0 echo ✅ No Ollama processes found

echo.
echo 2. Checking if port 11434 is in use:
netstat -ano | findstr ":11434" | findstr LISTENING
if %errorlevel% neq 0 echo ✅ Port 11434 is free

echo.
echo 3. Testing API connection:
curl -s http://localhost:11434/api/tags >nul 2>&1
if %errorlevel% neq 0 (
    echo ✅ API is not responding (server is down)
) else (
    echo ❌ API is still responding (server is still running)
)

echo.
echo 4. Testing connect_to_ollama.bat (should fail):
echo This should show connection errors...
pause
