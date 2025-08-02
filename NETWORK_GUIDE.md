# Ollama Network Access Scripts

This directory contains various interfaces and tools for accessing Ollama over the network.

## Quick Start Guide

### 1. Install Dependencies
```bash
pip install -r requirements.txt
```

### 2. Configure Ollama for Network Access
```bash
# Set environment variable (Windows PowerShell)
$env:OLLAMA_HOST = "0.0.0.0:11434"

# Start Ollama server
ollama serve
```

### 3. Pull a Model
```bash
ollama pull tinyllama  # Small, fast model for testing
```

### 4. Test Connection
```bash
# Test locally
ollama run tinyllama "Hello, how are you?"

# Test from another device (replace IP)
curl http://192.168.1.100:11434/api/generate -d '{"model":"tinyllama","prompt":"Hello","stream":false}'
```

## Available Interfaces

| File | Description | Usage |
|------|-------------|-------|
| `web_interface.html` | Browser-based chat interface | Open in any web browser |
| `cli_client.py` | Command-line interface | `python cli_client.py --host 192.168.1.100` |
| `api_client.py` | Python API examples | `python api_client.py` |
| `proxy_server.py` | FastAPI proxy with web UI | `python proxy_server.py` |
| `setup.py` | Automated setup script | `python setup.py` |

## Network Configuration

### Find Your IP Address
```powershell
# Windows PowerShell
(Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias "Wi-Fi").IPAddress

# Command Prompt
ipconfig | findstr "IPv4"
```

### Windows Firewall
1. Windows Security → Firewall & network protection
2. "Allow an app through firewall"
3. Add Python and Ollama
4. Check both Private and Public networks

## Usage Examples

### Web Interface
1. Open `web_interface.html` in any browser
2. Update the server URL to your IP address
3. Select a model and start chatting

### CLI Client
```bash
# Connect to remote Ollama server
python cli_client.py --host 192.168.1.100 --model tinyllama

# List available models
python cli_client.py --host 192.168.1.100 --list-models

# Single prompt mode
python cli_client.py --host 192.168.1.100 --prompt "What is Python?"
```

### API Client
```python
from api_client import OllamaAPI

# Connect to remote server
client = OllamaAPI("http://192.168.1.100:11434")

# Generate response
response = client.generate("tinyllama", "Hello, world!")
print(response)
```

### Proxy Server
```bash
# Start the proxy server
python proxy_server.py

# Access web interface
# http://localhost:8000/web

# API documentation
# http://localhost:8000/docs
```

## Mobile Access

### Access from Phone/Tablet
1. Connect to same Wi-Fi network
2. Open browser and go to: `http://YOUR_IP:8000/web`
3. Or use the direct HTML interface

### Create QR Code
Use any QR code generator to create a code for:
`http://YOUR_IP_ADDRESS:11434`

## Troubleshooting

### Connection Issues
- ✅ Ollama running: `ollama serve`
- ✅ Environment set: `OLLAMA_HOST=0.0.0.0:11434`
- ✅ Firewall allows Python/Ollama
- ✅ Using correct IP address
- ✅ Model is pulled: `ollama pull tinyllama`

### Common Errors
| Error | Solution |
|-------|----------|
| "Connection refused" | Set `OLLAMA_HOST=0.0.0.0:11434` |
| "Model not found" | Run `ollama pull model_name` |
| "Timeout" | Check firewall settings |
| "Import error" | Run `pip install -r requirements.txt` |

### Performance Tips
- Use smaller models for faster responses (`tinyllama`)
- Enable streaming for real-time output
- Consider GPU acceleration for better performance

## Security Considerations

⚠️ **Important**: This setup allows network access to your Ollama server.

### Recommendations:
- Only use on trusted networks (home/office Wi-Fi)
- Consider adding authentication for production use
- Monitor network traffic and usage
- Use firewall rules to restrict access if needed

### For Production:
- Add API authentication
- Use HTTPS/SSL certificates
- Implement rate limiting
- Add request logging and monitoring

## Advanced Configuration

### Custom Proxy Features
The `proxy_server.py` includes:
- Request logging
- CORS support
- Statistics endpoint
- Custom web interface
- Streaming support

### Environment Variables
```bash
# Ollama server URL
OLLAMA_HOST=0.0.0.0:11434

# Proxy server settings
PROXY_PORT=8000
PROXY_HOST=0.0.0.0
```

## Contributing

Feel free to extend these scripts with additional features:
- Authentication systems
- Better error handling
- Mobile-optimized interfaces
- Integration with other tools
