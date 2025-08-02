# Remote Ollama API Client
# Copy this file to any device and run with: powershell -ExecutionPolicy Bypass -File remote_ollama.ps1

param(
    [string]$ServerIP = "",
    [string]$Model = "tinyllama"
)

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "    📡 Remote Ollama API Client" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Get server IP if not provided
if (-not $ServerIP) {
    $ServerIP = Read-Host "Enter Ollama server IP address"
}

if (-not $ServerIP) {
    Write-Host "❌ No IP address provided" -ForegroundColor Red
    exit 1
}

$ServerUrl = "http://${ServerIP}:11434"

Write-Host "🔍 Testing connection to $ServerUrl..." -ForegroundColor Yellow

# Test connectivity
try {
    $response = Invoke-RestMethod -Uri "$ServerUrl/api/tags" -Method Get -TimeoutSec 5
    Write-Host "✅ Connected successfully!" -ForegroundColor Green
} catch {
    Write-Host "❌ Cannot connect to Ollama server at $ServerIP" -ForegroundColor Red
    Write-Host "`n💡 Troubleshooting:" -ForegroundColor Yellow
    Write-Host "   1. Make sure the server is running" -ForegroundColor White
    Write-Host "   2. Check if you're on the same network" -ForegroundColor White
    Write-Host "   3. Verify the IP address is correct" -ForegroundColor White
    Write-Host "   4. Check firewall settings" -ForegroundColor White
    exit 1
}

# Show available models
Write-Host "`n📋 Available models:" -ForegroundColor Green
$models = $response.models | ForEach-Object { $_.name }
$models | ForEach-Object { Write-Host "   - $_" -ForegroundColor White }

function Send-SimplePrompt {
    param($Model, $Prompt)
    
    $body = @{
        model = $Model
        prompt = $Prompt
        stream = $false
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri "$ServerUrl/api/generate" -Method Post -Body $body -ContentType "application/json"
        return $response.response
    } catch {
        Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

function Start-InteractiveChat {
    param($Model)
    
    Write-Host "`n💬 Interactive Chat Mode with $Model (type 'quit' to exit)" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    
    while ($true) {
        $userInput = Read-Host "You"
        if ($userInput -eq "quit" -or $userInput -eq "") { break }
        
        $body = @{
            model = $Model
            messages = @(
                @{
                    role = "user"
                    content = $userInput
                }
            )
            stream = $false
        } | ConvertTo-Json -Depth 3
        
        try {
            Write-Host "Bot: " -NoNewline -ForegroundColor Green
            $response = Invoke-RestMethod -Uri "$ServerUrl/api/chat" -Method Post -Body $body -ContentType "application/json"
            Write-Host $response.message.content -ForegroundColor White
        } catch {
            Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
        }
        Write-Host ""
    }
}

# Main menu
while ($true) {
    Write-Host "`n🎯 What would you like to do?" -ForegroundColor Yellow
    Write-Host "1. Send a simple prompt" -ForegroundColor White
    Write-Host "2. Interactive chat session" -ForegroundColor White
    Write-Host "3. List models" -ForegroundColor White
    Write-Host "4. Change model" -ForegroundColor White
    Write-Host "5. Exit" -ForegroundColor White
    
    $choice = Read-Host "`nChoose option (1-5)"
    
    switch ($choice) {
        "1" {
            $prompt = Read-Host "`nEnter your prompt"
            Write-Host "`n🤖 Response from $Model :" -ForegroundColor Green
            Write-Host "========================================" -ForegroundColor Cyan
            $response = Send-SimplePrompt -Model $Model -Prompt $prompt
            if ($response) {
                Write-Host $response -ForegroundColor White
            }
            Write-Host "========================================" -ForegroundColor Cyan
        }
        "2" {
            Start-InteractiveChat -Model $Model
        }
        "3" {
            Write-Host "`n📋 Available models:" -ForegroundColor Green
            $models | ForEach-Object { Write-Host "   - $_" -ForegroundColor White }
        }
        "4" {
            Write-Host "`nAvailable models:"
            for ($i = 0; $i -lt $models.Count; $i++) {
                Write-Host "$($i + 1). $($models[$i])" -ForegroundColor White
            }
            $modelChoice = Read-Host "Choose model number"
            if ($modelChoice -match '^\d+$' -and [int]$modelChoice -ge 1 -and [int]$modelChoice -le $models.Count) {
                $Model = $models[[int]$modelChoice - 1]
                Write-Host "✅ Selected model: $Model" -ForegroundColor Green
            } else {
                Write-Host "❌ Invalid choice" -ForegroundColor Red
            }
        }
        "5" {
            Write-Host "`n👋 Goodbye!" -ForegroundColor Yellow
            exit 0
        }
        default {
            Write-Host "❌ Invalid choice, please try again." -ForegroundColor Red
        }
    }
}
