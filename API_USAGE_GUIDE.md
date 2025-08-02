# 🔌 Ollama API Usage Guide

## 🔑 Authentication: NONE REQUIRED!

Ollama runs **without authentication** - no API keys needed!
- ✅ Simple HTTP requests
- ❌ No tokens, keys, or auth headers
- 🌐 Network access based on IP/firewall only

## 📡 API Endpoints

### Base URL: `http://YOUR_IP:11434`

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/tags` | GET | List available models |
| `/api/generate` | POST | Generate text |
| `/api/chat` | POST | Chat conversation |
| `/api/pull` | POST | Download model |
| `/api/push` | POST | Upload model |
| `/api/create` | POST | Create custom model |

## 💻 Direct API Examples

### 1. **List Models**
```bash
# cURL
curl http://localhost:11434/api/tags

# PowerShell
Invoke-RestMethod -Uri "http://localhost:11434/api/tags"

# Python
import requests
response = requests.get("http://localhost:11434/api/tags")
print(response.json())
```

### 2. **Generate Text**
```bash
# cURL
curl -X POST "http://localhost:11434/api/generate" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "tinyllama:latest",
    "prompt": "Hello, world!",
    "stream": false
  }'

# PowerShell
$body = @{
    model = "tinyllama:latest"
    prompt = "Hello, world!"
    stream = $false
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:11434/api/generate" -Method POST -Body $body -ContentType "application/json"

# Python
import requests
response = requests.post("http://localhost:11434/api/generate", json={
    "model": "tinyllama:latest",
    "prompt": "Hello, world!",
    "stream": False
})
print(response.json()["response"])
```

### 3. **Chat Mode**
```bash
# Python
import requests
response = requests.post("http://localhost:11434/api/chat", json={
    "model": "tinyllama:latest",
    "messages": [
        {"role": "user", "content": "Hello!"},
        {"role": "assistant", "content": "Hi there!"},
        {"role": "user", "content": "How are you?"}
    ]
})
print(response.json())
```

## 🌍 Third-Party Platform Integration

### ✅ **What Works:**
- **OpenAI-compatible clients** (with adapters)
- **Custom applications** (web apps, mobile apps)
- **Programming languages** (Python, JavaScript, Java, etc.)
- **Automation tools** (scripts, workflows)
- **Local development tools**

### 📱 **Platform Examples:**

#### **1. Python Applications**
```python
import requests

class LocalOllamaClient:
    def __init__(self, base_url="http://192.168.1.115:11434"):
        self.base_url = base_url
    
    def generate(self, model, prompt):
        response = requests.post(f"{self.base_url}/api/generate", json={
            "model": model,
            "prompt": prompt,
            "stream": False
        })
        return response.json()["response"]

# Usage
client = LocalOllamaClient()
result = client.generate("tinyllama:latest", "What is Python?")
print(result)
```

#### **2. JavaScript/Web Apps**
```javascript
class OllamaAPI {
    constructor(baseUrl = 'http://192.168.1.115:11434') {
        this.baseUrl = baseUrl;
    }
    
    async generate(model, prompt) {
        const response = await fetch(`${this.baseUrl}/api/generate`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                model: model,
                prompt: prompt,
                stream: false
            })
        });
        const data = await response.json();
        return data.response;
    }
}

// Usage
const ollama = new OllamaAPI();
const result = await ollama.generate('tinyllama:latest', 'Hello!');
console.log(result);
```

#### **3. Mobile Apps (React Native)**
```javascript
// In a React Native app
const generateText = async (prompt) => {
    try {
        const response = await fetch('http://192.168.1.115:11434/api/generate', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                model: 'tinyllama:latest',
                prompt: prompt,
                stream: false
            })
        });
        const data = await response.json();
        return data.response;
    } catch (error) {
        console.error('Error:', error);
    }
};
```

#### **4. OpenAI API Compatibility**
```python
# Using openai library with local endpoint
import openai

# Point to your local Ollama server
openai.api_base = "http://192.168.1.115:11434/v1"  # Note: needs adapter
openai.api_key = "not-needed"

# This requires an OpenAI-to-Ollama adapter
```

## 🌐 Network Access Scope

### ✅ **WORKS (Same Network):**
- **Local devices**: Same Wi-Fi/LAN
- **Mobile phones**: On same Wi-Fi
- **Other computers**: Same network
- **IoT devices**: Smart home devices
- **Development tools**: Local IDEs, tools

### ❌ **DOESN'T WORK:**
- **Internet access**: Not accessible from outside your network
- **Different networks**: Can't cross network boundaries
- **Cellular data**: Unless connected via VPN
- **Cloud platforms**: Can't connect from cloud services
- **Remote locations**: Not accessible remotely

### 🔒 **Security Implications:**
- **No authentication**: Anyone on network can access
- **Unencrypted**: HTTP traffic (not HTTPS)
- **Trust-based**: Relies on network security
- **Local only**: Can't be accessed from internet

## 🛠️ Third-Party Integration Examples

### **1. Chatbot Applications**
```python
# Discord bot example
import discord
import requests

class OllamaChatBot:
    def __init__(self):
        self.ollama_url = "http://192.168.1.115:11434"
    
    async def respond(self, message):
        response = requests.post(f"{self.ollama_url}/api/generate", json={
            "model": "tinyllama:latest",
            "prompt": message,
            "stream": False
        })
        return response.json()["response"]
```

### **2. Web Applications**
```javascript
// Express.js server
app.post('/chat', async (req, res) => {
    const { message } = req.body;
    
    const response = await fetch('http://192.168.1.115:11434/api/generate', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            model: 'tinyllama:latest',
            prompt: message,
            stream: false
        })
    });
    
    const data = await response.json();
    res.json({ response: data.response });
});
```

### **3. Mobile Apps**
```swift
// iOS Swift example
func generateText(prompt: String, completion: @escaping (String?) -> Void) {
    let url = URL(string: "http://192.168.1.115:11434/api/generate")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let body = [
        "model": "tinyllama:latest",
        "prompt": prompt,
        "stream": false
    ]
    
    request.httpBody = try? JSONSerialization.data(withJSONObject: body)
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        // Handle response...
    }.resume()
}
```

## 🚀 Getting Started with Third-Party Integration

1. **Ensure Ollama is accessible**: Set `OLLAMA_HOST=0.0.0.0:11434`
2. **Find your IP address**: Use `ipconfig` or the batch files
3. **Test connectivity**: Use the provided API examples
4. **Handle CORS**: For web apps, use the proxy server
5. **Error handling**: Always handle network errors gracefully

## 🔧 Troubleshooting Third-Party Access

### **Common Issues:**
- **CORS errors**: Use the FastAPI proxy server
- **Network timeouts**: Check firewall settings
- **Connection refused**: Verify OLLAMA_HOST setting
- **Model not found**: Ensure model is installed

### **Solutions:**
- Use `proxy_server.py` for CORS-enabled access
- Add appropriate firewall rules
- Test with direct IP access first
- Verify model availability via `/api/tags`

## 💡 Best Practices

1. **Always handle errors** in your applications
2. **Use timeouts** for API calls (models can be slow)
3. **Cache responses** when appropriate
4. **Monitor usage** to avoid overwhelming the server
5. **Consider rate limiting** for multi-user applications
6. **Use the proxy server** for web applications (CORS support)

The beauty of Ollama is its simplicity - no API keys, just straightforward HTTP requests! 🎉
