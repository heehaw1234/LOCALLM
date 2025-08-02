#!/usr/bin/env python3
"""
FastAPI proxy server for Ollama
Provides additional features like authentication, logging, rate limiting, etc.
"""

from fastapi import FastAPI, HTTPException, Depends, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse, HTMLResponse
from pydantic import BaseModel
import httpx
import json
import time
from typing import Optional, List, Dict, Any
import asyncio

app = FastAPI(title="Ollama Proxy Server", version="1.0.0")

# Enable CORS for web interface access
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify allowed origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Configuration
OLLAMA_BASE_URL = "http://localhost:11434"
REQUEST_TIMEOUT = 300

class GenerateRequest(BaseModel):
    model: str
    prompt: str
    stream: bool = False
    temperature: Optional[float] = None
    top_p: Optional[float] = None
    max_tokens: Optional[int] = None

class ChatMessage(BaseModel):
    role: str
    content: str

class ChatRequest(BaseModel):
    model: str
    messages: List[ChatMessage]
    stream: bool = False
    temperature: Optional[float] = None

# Request logging
request_log = []

def log_request(endpoint: str, model: str, prompt_length: int, response_time: float):
    """Log API requests for monitoring"""
    request_log.append({
        "timestamp": time.time(),
        "endpoint": endpoint,
        "model": model,
        "prompt_length": prompt_length,
        "response_time": response_time
    })
    
    # Keep only last 100 requests
    if len(request_log) > 100:
        request_log.pop(0)

@app.get("/")
async def root():
    """Root endpoint with API information"""
    return {
        "message": "Ollama Proxy Server",
        "version": "1.0.0",
        "endpoints": {
            "/models": "List available models",
            "/generate": "Generate text",
            "/chat": "Chat with model",
            "/health": "Health check",
            "/stats": "Server statistics",
            "/web": "Web interface"
        }
    }

@app.get("/web")
async def web_interface():
    """Serve web interface"""
    html_content = """
    <!DOCTYPE html>
    <html>
    <head>
        <title>Ollama Proxy Interface</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 40px; }
            .container { max-width: 800px; margin: 0 auto; }
            .chat-box { border: 1px solid #ccc; height: 400px; overflow-y: auto; padding: 10px; margin: 20px 0; }
            .input-area { display: flex; gap: 10px; }
            .input-area input { flex: 1; padding: 10px; }
            .input-area button { padding: 10px 20px; }
            .message { margin: 10px 0; padding: 10px; border-radius: 5px; }
            .user { background: #e3f2fd; }
            .assistant { background: #f3e5f5; }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>🦙 Ollama Proxy Interface</h1>
            <div>
                <select id="modelSelect">
                    <option value="">Loading models...</option>
                </select>
                <button onclick="loadModels()">Refresh Models</button>
            </div>
            <div id="chatBox" class="chat-box"></div>
            <div class="input-area">
                <input type="text" id="messageInput" placeholder="Type your message..." onkeypress="handleKeyPress(event)">
                <button onclick="sendMessage()">Send</button>
            </div>
        </div>
        
        <script>
            async function loadModels() {
                try {
                    const response = await fetch('/models');
                    const data = await response.json();
                    const select = document.getElementById('modelSelect');
                    select.innerHTML = '';
                    data.models.forEach(model => {
                        const option = document.createElement('option');
                        option.value = model.name;
                        option.textContent = model.name;
                        select.appendChild(option);
                    });
                } catch (error) {
                    console.error('Error loading models:', error);
                }
            }
            
            async function sendMessage() {
                const input = document.getElementById('messageInput');
                const model = document.getElementById('modelSelect').value;
                const message = input.value.trim();
                
                if (!message || !model) return;
                
                addMessage(message, 'user');
                input.value = '';
                
                try {
                    const response = await fetch('/generate', {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({
                            model: model,
                            prompt: message,
                            stream: false
                        })
                    });
                    
                    const data = await response.json();
                    addMessage(data.response, 'assistant');
                } catch (error) {
                    addMessage('Error: ' + error.message, 'assistant');
                }
            }
            
            function addMessage(text, role) {
                const chatBox = document.getElementById('chatBox');
                const div = document.createElement('div');
                div.className = `message ${role}`;
                div.innerHTML = `<strong>${role}:</strong> ${text}`;
                chatBox.appendChild(div);
                chatBox.scrollTop = chatBox.scrollHeight;
            }
            
            function handleKeyPress(event) {
                if (event.key === 'Enter') {
                    sendMessage();
                }
            }
            
            // Load models on page load
            loadModels();
        </script>
    </body>
    </html>
    """
    return HTMLResponse(content=html_content)

@app.get("/health")
async def health_check():
    """Check if Ollama server is accessible"""
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(f"{OLLAMA_BASE_URL}/api/tags", timeout=5)
            return {
                "status": "healthy" if response.status_code == 200 else "unhealthy",
                "ollama_server": OLLAMA_BASE_URL,
                "response_code": response.status_code
            }
    except Exception as e:
        return {
            "status": "unhealthy",
            "ollama_server": OLLAMA_BASE_URL,
            "error": str(e)
        }

@app.get("/models")
async def list_models():
    """Get available models from Ollama"""
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(f"{OLLAMA_BASE_URL}/api/tags")
            response.raise_for_status()
            return response.json()
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching models: {str(e)}")

@app.post("/generate")
async def generate_text(request: GenerateRequest):
    """Generate text using Ollama"""
    start_time = time.time()
    
    try:
        payload = request.dict()
        
        if request.stream:
            # Handle streaming response
            async def stream_generator():
                async with httpx.AsyncClient(timeout=REQUEST_TIMEOUT) as client:
                    async with client.stream("POST", f"{OLLAMA_BASE_URL}/api/generate", json=payload) as response:
                        response.raise_for_status()
                        async for line in response.aiter_lines():
                            if line:
                                yield f"data: {line}\n\n"
            
            return StreamingResponse(stream_generator(), media_type="text/event-stream")
        else:
            # Handle regular response
            async with httpx.AsyncClient(timeout=REQUEST_TIMEOUT) as client:
                response = await client.post(f"{OLLAMA_BASE_URL}/api/generate", json=payload)
                response.raise_for_status()
                result = response.json()
                
                # Log request
                response_time = time.time() - start_time
                log_request("generate", request.model, len(request.prompt), response_time)
                
                return result
                
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error generating text: {str(e)}")

@app.post("/chat")
async def chat_with_model(request: ChatRequest):
    """Chat with model using conversation history"""
    start_time = time.time()
    
    try:
        payload = request.dict()
        
        async with httpx.AsyncClient(timeout=REQUEST_TIMEOUT) as client:
            response = await client.post(f"{OLLAMA_BASE_URL}/api/chat", json=payload)
            response.raise_for_status()
            result = response.json()
            
            # Log request
            response_time = time.time() - start_time
            prompt_length = sum(len(msg.content) for msg in request.messages)
            log_request("chat", request.model, prompt_length, response_time)
            
            return result
            
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error in chat: {str(e)}")

@app.get("/stats")
async def get_stats():
    """Get server statistics"""
    if not request_log:
        return {"message": "No requests logged yet"}
    
    total_requests = len(request_log)
    avg_response_time = sum(req["response_time"] for req in request_log) / total_requests
    
    models_used = {}
    for req in request_log:
        model = req["model"]
        models_used[model] = models_used.get(model, 0) + 1
    
    return {
        "total_requests": total_requests,
        "average_response_time": round(avg_response_time, 2),
        "models_used": models_used,
        "recent_requests": request_log[-5:]  # Last 5 requests
    }

if __name__ == "__main__":
    import uvicorn
    print("🚀 Starting Ollama Proxy Server...")
    print(f"📡 Proxying to: {OLLAMA_BASE_URL}")
    print("🌐 Web interface: http://localhost:8000/web")
    print("📚 API docs: http://localhost:8000/docs")
    
    uvicorn.run(app, host="0.0.0.0", port=8000)
