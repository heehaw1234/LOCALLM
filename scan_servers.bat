@echo off
REM Quick server scanner
title Ollama Server Scanner

echo.
echo ============================================
echo     🔍 Ollama Server Scanner  
echo ============================================
echo.

REM Run scan mode
call python_launcher.bat --scan

pause
