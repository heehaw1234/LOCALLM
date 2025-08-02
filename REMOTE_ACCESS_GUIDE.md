# 🌐 Remote API Access Guide

This guide shows you exactly how to make API calls and access your local Ollama from other devices.

## 🚀 Quick Setup

### **1. Start Your Ollama Server**
```bash
# Option A: Quick start everything
quick_start.bat

# Option B: Full launcher with model selection  
ollama_launcher_v2.bat
# Choose option 3: "Keep server running for network access"

# Option C: Just check your current IP
network_detector.bat
```

### **2. Get Your IP Address**
Your current IP is: **192.168.1.115**

## 📱 From Another Device's Command Line

### **Method 1: Use the Remote Scripts (Easiest)**

Copy one of these files to your other device:

**For Windows CMD:**
```bash
# Copy remote_api_test.bat to the other device, then run:
remote_api_test.bat
# Enter IP: 192.168.1.115
```

**For PowerShell (Windows/Mac/Linux):**
```bash
# Copy remote_ollama.ps1 to the other device, then run:
powershell -ExecutionPolicy Bypass -File remote_ollama.ps1
# Enter IP: 192.168.1.115
```

### **Method 2: Direct curl Commands**

**Test Connection:**
```bash
curl http://192.168.1.115:11434/api/tags
```

**List Available Models:**
```bash
curl http://192.168.1.115:11434/api/tags
```

**Send a Simple Question:**
```bash
curl -X POST http://192.168.1.115:11434/api/generate \
  -H "Content-Type: application/json" \
  -d "{\"model\":\"tinyllama\",\"prompt\":\"What is 2+2?\",\"stream\":false}"
```

**Interactive Chat Format:**
```bash
curl -X POST http://192.168.1.115:11434/api/chat \
  -H "Content-Type: application/json" \
  -d "{\"model\":\"tinyllama\",\"messages\":[{\"role\":\"user\",\"content\":\"Hello! How are you?\"}],\"stream\":false}"
```

### **Method 3: Python API Client**

If you have Python on the remote device, copy `cli_client.py` and run:
```bash
python cli_client.py --host 192.168.1.115 --model tinyllama
```

## 🔗 Available Models

Based on your setup, you have these models available:
- `tinyllama:latest` - Small and fast (1.1GB)
- `qwen2.5-coder:7b` - Advanced coding model (4.4GB)  
- `llama3.2:latest` - General purpose model

## 🌐 Web Interface Access

### **Direct Browser Access:**
```
http://192.168.1.115:11434/api/tags
```

### **Web Chat Interface:**
1. Copy `web_interface.html` to the other device
2. Open it in a browser
3. Change the server URL to: `http://192.168.1.115:11434`

### **Proxy Server (Enhanced Features):**
If you start the proxy server:
```
http://192.168.1.115:8000/web
```

## 📋 API Examples

### **1. Simple Text Generation**
```bash
curl -X POST http://192.168.1.115:11434/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "model": "tinyllama",
    "prompt": "Write a short poem about AI",
    "stream": false
  }'
```

### **2. Chat Conversation**
```bash
curl -X POST http://192.168.1.115:11434/api/chat \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen2.5-coder:7b",
    "messages": [
      {"role": "user", "content": "Write a Python function to calculate fibonacci numbers"}
    ],
    "stream": false
  }'
```

### **3. Streaming Response**
```bash
curl -X POST http://192.168.1.115:11434/api/generate \
  -H "Content-Type: application/json" \
  -d '{
    "model": "tinyllama",
    "prompt": "Explain machine learning in simple terms",
    "stream": true
  }'
```

### **4. Code Generation**
```bash
curl -X POST http://192.168.1.115:11434/api/chat \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen2.5-coder:7b",
    "messages": [
      {"role": "user", "content": "Create a REST API in Python using FastAPI"}
    ],
    "stream": false
  }'
```

## 🔧 Troubleshooting

### **Can't Connect?**
1. **Check if Ollama is running:**
   ```bash
   curl http://192.168.1.115:11434/api/tags
   ```

2. **Verify IP address:**
   ```bash
   # On main computer:
   network_detector.bat
   ```

3. **Check Windows Firewall:**
   - Windows may block the connection
   - Allow when prompted, or manually add exception

4. **Verify network:**
   - Both devices must be on same Wi-Fi/network
   - Test with: `ping 192.168.1.115`

### **IP Address Changed?**
When you connect to a different network:
```bash
# Check new IP:
network_detector.bat

# Update your API calls with the new IP
```

## 🎯 Complete Workflow Example

### **On Main Computer:**
```bash
# 1. Start everything
quick_start.bat
# Output shows: Network IP: 192.168.1.115

# 2. Keep running for network access
# (Server runs in background)
```

### **On Another Device (Windows):**
```bash
# Test connection
curl http://192.168.1.115:11434/api/tags

# Send a question
curl -X POST http://192.168.1.115:11434/api/generate ^
  -H "Content-Type: application/json" ^
  -d "{\"model\":\"tinyllama\",\"prompt\":\"Hello world!\",\"stream\":false}"
```

### **On Another Device (Mac/Linux):**
```bash
# Test connection  
curl http://192.168.1.115:11434/api/tags

# Send a question
curl -X POST http://192.168.1.115:11434/api/generate \
  -H "Content-Type: application/json" \
  -d '{"model":"tinyllama","prompt":"Hello world!","stream":false}'
```

## 🔐 Security Notes

- **No API key required** - Ollama runs locally without authentication
- **Local network only** - Only devices on your Wi-Fi can access
- **Firewall consideration** - Windows Firewall may need to allow access
- **Trusted networks** - Only use on networks you trust

## 💡 Pro Tips

1. **Bookmark URLs**: Save `http://192.168.1.115:11434` for quick access
2. **Copy IP easily**: Use `network_detector.bat` → option 4 to copy IP
3. **Test first**: Always test with `/api/tags` before sending prompts
4. **Use streaming**: Add `"stream":true` for real-time responses
5. **Model selection**: Use `qwen2.5-coder:7b` for coding tasks, `tinyllama` for quick responses

Your Ollama setup is now fully accessible across your network! 🚀
