# Remote Ollama Chat Client - PowerShell Version
# Usage: .\remote_chat.ps1
# Auto-discovers Ollama server and starts chat

param(
    [string]$Host = "auto",
    [int]$Port = 11434,
    [string]$Model = "tinyllama:latest"
)

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "     🌐 Remote Ollama Chat Client (PS)     " -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$SavedIPFile = "remote_connection.txt"
$OllamaIP = $null

function Test-OllamaConnection {
    param([string]$TestIP)
    try {
        $response = Invoke-RestMethod -Uri "http://${TestIP}:${Port}/api/tags" -TimeoutSec 3 -ErrorAction Stop
        return $true
    }
    catch {
        return $false
    }
}

function Get-NetworkIPs {
    $localIPs = @()
    try {
        $adapters = Get-NetAdapter | Where-Object {$_.Status -eq "Up"}
        foreach ($adapter in $adapters) {
            $ip = Get-NetIPAddress -InterfaceIndex $adapter.InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue
            if ($ip -and $ip.IPAddress -ne "127.0.0.1") {
                $localIPs += $ip.IPAddress
            }
        }
    }
    catch {
        # Fallback method
        $ipConfig = ipconfig | Select-String "IPv4"
        foreach ($line in $ipConfig) {
            if ($line -match "(\d+\.\d+\.\d+\.\d+)") {
                $localIPs += $matches[1]
            }
        }
    }
    return $localIPs
}

if ($Host -eq "auto") {
    Write-Host "🔍 Auto-discovering Ollama server..." -ForegroundColor Yellow
    Write-Host ""
    
    # Try saved IP first
    if (Test-Path $SavedIPFile) {
        $savedIP = Get-Content $SavedIPFile -ErrorAction SilentlyContinue
        if ($savedIP) {
            Write-Host "📁 Trying last known IP: $savedIP" -ForegroundColor Gray
            if (Test-OllamaConnection $savedIP) {
                $OllamaIP = $savedIP
                Write-Host "✅ Found Ollama server at: $savedIP (from last session)" -ForegroundColor Green
            }
            else {
                Write-Host "❌ Last known IP $savedIP is no longer working" -ForegroundColor Red
            }
        }
    }
    
    # Try localhost
    if (-not $OllamaIP) {
        Write-Host "📡 Trying localhost..." -ForegroundColor Gray
        if (Test-OllamaConnection "localhost") {
            $OllamaIP = "localhost"
            Write-Host "✅ Found Ollama server at: localhost" -ForegroundColor Green
        }
    }
    
    # Try network IPs
    if (-not $OllamaIP) {
        Write-Host "🌐 Scanning local network..." -ForegroundColor Gray
        $localIPs = Get-NetworkIPs
        
        foreach ($ip in $localIPs) {
            Write-Host "   Testing $ip..." -ForegroundColor Gray
            if (Test-OllamaConnection $ip) {
                $OllamaIP = $ip
                Write-Host "✅ Found Ollama server at: $ip" -ForegroundColor Green
                break
            }
        }
        
        # Try common network IPs
        if (-not $OllamaIP -and $localIPs.Count -gt 0) {
            $firstIP = $localIPs[0]
            $networkBase = ($firstIP -split '\.')[0..2] -join '.'
            
            $commonEndings = @(1, 2, 10, 100, 101, 110, 111, 115, 200)
            foreach ($ending in $commonEndings) {
                $testIP = "$networkBase.$ending"
                if ($testIP -notin $localIPs) {
                    Write-Host "   Testing $testIP..." -ForegroundColor Gray
                    if (Test-OllamaConnection $testIP) {
                        $OllamaIP = $testIP
                        Write-Host "✅ Found Ollama server at: $testIP" -ForegroundColor Green
                        break
                    }
                }
            }
        }
    }
    
    # Manual entry if auto-discovery failed
    if (-not $OllamaIP) {
        Write-Host ""
        Write-Host "❌ Could not auto-discover Ollama server" -ForegroundColor Red
        Write-Host "📝 Please enter the Ollama server IP address:" -ForegroundColor Yellow
        Write-Host "💡 Tip: Check the server machine's quick_start.bat output" -ForegroundColor Cyan
        
        do {
            $OllamaIP = Read-Host "🌐 Enter server IP"
            if ($OllamaIP) {
                Write-Host "🔍 Testing connection to $OllamaIP..." -ForegroundColor Yellow
                if (-not (Test-OllamaConnection $OllamaIP)) {
                    Write-Host "❌ Connection failed to ${OllamaIP}:${Port}" -ForegroundColor Red
                    $retry = Read-Host "🔄 Try a different IP? (y/n)"
                    if ($retry -ne "y") { exit 1 }
                    $OllamaIP = $null
                }
            }
        } while (-not $OllamaIP)
    }
}
else {
    $OllamaIP = $Host
    Write-Host "🔍 Testing specified host: $OllamaIP" -ForegroundColor Yellow
    if (-not (Test-OllamaConnection $OllamaIP)) {
        Write-Host "❌ Could not connect to $OllamaIP" -ForegroundColor Red
        exit 1
    }
}

# Save successful connection
$OllamaIP | Out-File -FilePath $SavedIPFile -Encoding UTF8

Write-Host ""
Write-Host "🔗 Connected to: ${OllamaIP}:${Port}" -ForegroundColor Green
Write-Host "✅ Connection successful!" -ForegroundColor Green
Write-Host ""

# Get available models
try {
    Write-Host "📋 Getting available models..." -ForegroundColor Yellow
    $models = Invoke-RestMethod -Uri "http://${OllamaIP}:${Port}/api/tags"
    Write-Host "Available models:" -ForegroundColor Cyan
    $models.models | ForEach-Object { Write-Host "  - $($_.name)" -ForegroundColor Gray }
    Write-Host ""
}
catch {
    Write-Host "⚠️  Could not retrieve models list" -ForegroundColor Yellow
}

# Start chat
Write-Host "🤖 Starting chat with $Model" -ForegroundColor Cyan
Write-Host "💬 Type your messages below (type 'quit' to exit)" -ForegroundColor Gray
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host ""

while ($true) {
    $userInput = Read-Host "💭 You"
    
    if ($userInput -in @("quit", "exit", "bye")) {
        Write-Host ""
        Write-Host "👋 Goodbye!" -ForegroundColor Green
        break
    }
    
    if (-not $userInput.Trim()) { continue }
    
    try {
        Write-Host ""
        Write-Host "🤖 $Model`: " -ForegroundColor Cyan -NoNewline
        
        $body = @{
            model = $Model
            prompt = $userInput
            stream = $false
        } | ConvertTo-Json
        
        $response = Invoke-RestMethod -Uri "http://${OllamaIP}:${Port}/api/generate" `
                                    -Method Post `
                                    -Body $body `
                                    -ContentType "application/json" `
                                    -TimeoutSec 300
        
        Write-Host $response.response -ForegroundColor White
        Write-Host ""
        Write-Host "====================================================" -ForegroundColor Cyan
    }
    catch {
        Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host ""
    }
}
