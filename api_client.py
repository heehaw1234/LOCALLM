#!/usr/bin/env python3
"""
API client examples for Ollama server
Demonstrates various ways to interact with Ollama programmatically
"""

import requests
import json
import asyncio
import httpx
from typing import List, Dict, Optional, AsyncGenerator

class OllamaAPI:
    """Synchronous Ollama API client"""
    
    def __init__(self, base_url: str = "http://localhost:11434"):
        self.base_url = base_url.rstrip('/')
    
    def health_check(self) -> bool:
        """Check if Ollama server is running"""
        try:
            response = requests.get(f"{self.base_url}/api/tags", timeout=5)
            return response.status_code == 200
        except:
            return False
    
    def list_models(self) -> List[Dict]:
        """Get list of available models"""
        response = requests.get(f"{self.base_url}/api/tags")
        response.raise_for_status()
        return response.json().get("models", [])
    
    def generate(self, model: str, prompt: str, **kwargs) -> str:
        """Generate text with given model and prompt"""
        payload = {
            "model": model,
            "prompt": prompt,
            "stream": False,
            **kwargs
        }
        
        response = requests.post(f"{self.base_url}/api/generate", json=payload)
        response.raise_for_status()
        return response.json()["response"]
    
    def generate_stream(self, model: str, prompt: str, **kwargs):
        """Generate text with streaming response"""
        payload = {
            "model": model,
            "prompt": prompt,
            "stream": True,
            **kwargs
        }
        
        response = requests.post(f"{self.base_url}/api/generate", json=payload, stream=True)
        response.raise_for_status()
        
        for line in response.iter_lines():
            if line:
                data = json.loads(line)
                if "response" in data:
                    yield data["response"]
                if data.get("done", False):
                    break
    
    def chat(self, model: str, messages: List[Dict], **kwargs) -> str:
        """Chat with model using conversation history"""
        payload = {
            "model": model,
            "messages": messages,
            "stream": False,
            **kwargs
        }
        
        response = requests.post(f"{self.base_url}/api/chat", json=payload)
        response.raise_for_status()
        return response.json()["message"]["content"]

class AsyncOllamaAPI:
    """Asynchronous Ollama API client"""
    
    def __init__(self, base_url: str = "http://localhost:11434"):
        self.base_url = base_url.rstrip('/')
    
    async def health_check(self) -> bool:
        """Check if Ollama server is running"""
        try:
            async with httpx.AsyncClient() as client:
                response = await client.get(f"{self.base_url}/api/tags", timeout=5)
                return response.status_code == 200
        except:
            return False
    
    async def list_models(self) -> List[Dict]:
        """Get list of available models"""
        async with httpx.AsyncClient() as client:
            response = await client.get(f"{self.base_url}/api/tags")
            response.raise_for_status()
            return response.json().get("models", [])
    
    async def generate(self, model: str, prompt: str, **kwargs) -> str:
        """Generate text with given model and prompt"""
        payload = {
            "model": model,
            "prompt": prompt,
            "stream": False,
            **kwargs
        }
        
        async with httpx.AsyncClient(timeout=300) as client:
            response = await client.post(f"{self.base_url}/api/generate", json=payload)
            response.raise_for_status()
            return response.json()["response"]
    
    async def generate_stream(self, model: str, prompt: str, **kwargs) -> AsyncGenerator[str, None]:
        """Generate text with streaming response"""
        payload = {
            "model": model,
            "prompt": prompt,
            "stream": True,
            **kwargs
        }
        
        async with httpx.AsyncClient(timeout=300) as client:
            async with client.stream("POST", f"{self.base_url}/api/generate", json=payload) as response:
                response.raise_for_status()
                async for line in response.aiter_lines():
                    if line:
                        data = json.loads(line)
                        if "response" in data:
                            yield data["response"]
                        if data.get("done", False):
                            break

# Example usage functions
def example_basic_usage():
    """Basic synchronous usage example"""
    print("=== Basic Usage Example ===")
    
    # Initialize client - replace with your server IP
    client = OllamaAPI("http://localhost:11434")
    # client = OllamaAPI("http://192.168.1.100:11434")  # For remote access
    
    # Health check
    if not client.health_check():
        print("❌ Ollama server not accessible")
        return
    
    print("✅ Connected to Ollama")
    
    # List models
    models = client.list_models()
    print(f"📋 Available models: {[m['name'] for m in models]}")
    
    if not models:
        print("No models found. Please pull a model first: ollama pull llama2")
        return
    
    # Use first available model
    model_name = models[0]["name"]
    print(f"🤖 Using model: {model_name}")
    
    # Simple generation
    prompt = "What is the capital of France?"
    response = client.generate(model_name, prompt)
    print(f"📝 Response: {response}")

def example_streaming():
    """Streaming response example"""
    print("\n=== Streaming Example ===")
    
    client = OllamaAPI("http://localhost:11434")
    
    if not client.health_check():
        print("❌ Ollama server not accessible")
        return
    
    models = client.list_models()
    if not models:
        print("No models available")
        return
    
    model_name = models[0]["name"]
    prompt = "Write a short story about a robot learning to paint."
    
    print(f"🎨 Generating story with {model_name}...")
    print("📖 Story: ", end="", flush=True)
    
    for chunk in client.generate_stream(model_name, prompt):
        print(chunk, end="", flush=True)
    print("\n")

async def example_async_usage():
    """Asynchronous usage example"""
    print("\n=== Async Usage Example ===")
    
    client = AsyncOllamaAPI("http://localhost:11434")
    
    # Health check
    if not await client.health_check():
        print("❌ Ollama server not accessible")
        return
    
    print("✅ Connected to Ollama (async)")
    
    # List models
    models = await client.list_models()
    if not models:
        print("No models available")
        return
    
    model_name = models[0]["name"]
    
    # Multiple concurrent requests
    prompts = [
        "What is Python?",
        "Explain machine learning",
        "What is the internet?"
    ]
    
    print(f"🚀 Running {len(prompts)} requests concurrently...")
    
    tasks = [client.generate(model_name, prompt) for prompt in prompts]
    responses = await asyncio.gather(*tasks)
    
    for prompt, response in zip(prompts, responses):
        print(f"\n❓ {prompt}")
        print(f"💬 {response[:100]}...")

def example_chat_conversation():
    """Chat conversation example"""
    print("\n=== Chat Conversation Example ===")
    
    client = OllamaAPI("http://localhost:11434")
    
    if not client.health_check():
        print("❌ Ollama server not accessible")
        return
    
    models = client.list_models()
    if not models:
        print("No models available")
        return
    
    model_name = models[0]["name"]
    
    # Build conversation
    messages = [
        {"role": "user", "content": "Hello! What's your name?"},
    ]
    
    try:
        response = client.chat(model_name, messages)
        print(f"🤖 Assistant: {response}")
        
        # Continue conversation
        messages.append({"role": "assistant", "content": response})
        messages.append({"role": "user", "content": "Can you help me with Python programming?"})
        
        response = client.chat(model_name, messages)
        print(f"🤖 Assistant: {response}")
        
    except Exception as e:
        print(f"Chat not supported on this model: {e}")
        print("Try using the generate method instead")

if __name__ == "__main__":
    print("🦙 Ollama API Client Examples")
    print("=" * 40)
    
    # Run examples
    example_basic_usage()
    example_streaming()
    
    # Run async example
    asyncio.run(example_async_usage())
    
    example_chat_conversation()
    
    print("\n✨ All examples completed!")
    print("\n💡 To connect from another device:")
    print("   1. Set OLLAMA_HOST=0.0.0.0:11434")
    print("   2. Replace 'localhost' with your IP address in the client")
    print("   3. Make sure your firewall allows connections")
