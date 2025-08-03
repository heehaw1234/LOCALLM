# Local Ollama Network Setup

This project enables easy network access to your local Ollama server from any device.

## 🚀 Quick Start

### **For Host Machine (Ollama Server):**
```bash
# One command to start everything:
.\quick_start.bat

# This will:
# - Configure Ollama for network access
# - Start the server
# - Show you the connection URLs
# - Start proxy server with web interface
```

### **For Remote Devices (Chat Clients):**
```bash
# Copy the remote_device_files folder to any device
# Then simply run:
remote_chat_service.bat

# This will:
# - Auto-discover your Ollama server
# - Start a persistent chat service
# - Open a chat window automatically
```

## 📁 **Project Structure**

### **Main Files:**
- `quick_start.bat` - Complete server setup (host machine)
- `remote_device_files/` - All files for remote devices

### **Remote Device Files:**
- `remote_chat_service.bat` - **Main chat service** (recommended)
- `smart_remote_client.py` - Advanced Python client
- `remote_chat.ps1` - PowerShell client
- `COMPLETE_SETUP_GUIDE.md` - Detailed instructions

## 🎯 **What This Solves**

✅ **Dynamic IP Changes** - Auto-discovers server location  
✅ **Easy Setup** - One-click deployment  
✅ **Multi-Device** - Chat from phones, laptops, tablets  
✅ **Cross-Platform** - Windows, Mac, Linux support  
✅ **Persistent Service** - Chat window stays open  
✅ **No Configuration** - Just copy files and run  

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
