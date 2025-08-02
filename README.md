# Local Ollama Network Setup

This project demonstrates how to run Ollama locally and access it through various interfaces using IP addresses.

## Quick Start

### 1. Configure Ollama for Network Access

By default, Ollama only accepts connections from localhost. To allow network access:

```bash
# Set environment variable to allow external connections
$env:OLLAMA_HOST = "0.0.0.0:11434"

# Start Ollama server
ollama serve
```

### 2. Pull a Model

```bash
# Pull a lightweight model for testing
ollama pull llama2:7b-chat
# or a smaller model
ollama pull tinyllama
```

### 3. Test Local Connection

```bash
# Test that Ollama is working locally
ollama run llama2:7b-chat "Hello, how are you?"
```

### 4. Test Network Connection

Find your IP address and test from another device:

```bash
# Get your local IP address
ipconfig | findstr "IPv4"

# Test API endpoint (replace YOUR_IP with actual IP)
curl http://YOUR_IP:11434/api/generate -d '{
  "model": "llama2:7b-chat",
  "prompt": "Hello, how are you?",
  "stream": false
}'
```

## Available Interfaces

- **Web Interface** (`web_interface.html`) - Simple browser-based chat
- **Python CLI Client** (`cli_client.py`) - Command line interface
- **Python API Client** (`api_client.py`) - Programmatic access
- **FastAPI Proxy** (`proxy_server.py`) - Custom API wrapper
- **Jupyter Notebook** (`ollama_examples.ipynb`) - Interactive examples

## Network Configuration

### Windows Firewall
You may need to allow Python/Ollama through Windows Firewall:
1. Go to Windows Security > Firewall & network protection
2. Click "Allow an app through firewall"
3. Add Python and Ollama if not already allowed

### Finding Your IP Address
```powershell
# PowerShell command to get local IP
(Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias "Wi-Fi" | Select-Object IPAddress).IPAddress
```

## Usage Examples

### From Another Computer
```python
import requests

# Replace with your computer's IP address
OLLAMA_URL = "http://192.168.1.100:11434"

response = requests.post(f"{OLLAMA_URL}/api/generate", json={
    "model": "llama2:7b-chat",
    "prompt": "What is the capital of France?",
    "stream": False
})

print(response.json()["response"])
```

### From Mobile Device
Open the web interface in your mobile browser:
`http://YOUR_IP_ADDRESS:8000`

## Troubleshooting

- **Connection refused**: Make sure `OLLAMA_HOST=0.0.0.0:11434` is set
- **Firewall issues**: Allow Python and Ollama through Windows Firewall
- **Model not found**: Run `ollama pull model_name` first
- **Slow responses**: Use smaller models like `tinyllama` for faster inference
