#!/usr/bin/env python3
"""
CLI client for connecting to Ollama server over network
Usage: python cli_client.py --host 192.168.1.100 --model llama2:7b-chat
"""

import argparse
import requests
import json
import sys
from typing import Optional

class OllamaClient:
    def __init__(self, host: str = "localhost", port: int = 11434):
        self.base_url = f"http://{host}:{port}"
        
    def list_models(self) -> list:
        """Get list of available models"""
        try:
            response = requests.get(f"{self.base_url}/api/tags")
            response.raise_for_status()
            return response.json().get("models", [])
        except requests.exceptions.RequestException as e:
            print(f"Error connecting to Ollama server: {e}")
            return []
    
    def generate(self, model: str, prompt: str, stream: bool = False) -> Optional[str]:
        """Generate response from model"""
        try:
            payload = {
                "model": model,
                "prompt": prompt,
                "stream": stream
            }
            
            response = requests.post(
                f"{self.base_url}/api/generate",
                json=payload,
                timeout=300  # 5 minute timeout
            )
            response.raise_for_status()
            
            if stream:
                # Handle streaming response
                full_response = ""
                for line in response.iter_lines():
                    if line:
                        data = json.loads(line)
                        if "response" in data:
                            print(data["response"], end="", flush=True)
                            full_response += data["response"]
                        if data.get("done", False):
                            break
                print()  # New line after streaming
                return full_response
            else:
                # Handle non-streaming response
                data = response.json()
                return data.get("response", "No response received")
                
        except requests.exceptions.RequestException as e:
            print(f"Error generating response: {e}")
            return None
    
    def chat(self, model: str):
        """Interactive chat mode"""
        print(f"🦙 Connected to Ollama at {self.base_url}")
        print(f"📱 Using model: {model}")
        print("💬 Type 'quit' or 'exit' to end the conversation\n")
        
        while True:
            try:
                user_input = input("You: ").strip()
                
                if user_input.lower() in ['quit', 'exit', 'bye']:
                    print("Goodbye! 👋")
                    break
                
                if not user_input:
                    continue
                
                print("Ollama: ", end="", flush=True)
                response = self.generate(model, user_input, stream=True)
                print()  # Extra newline for readability
                
            except KeyboardInterrupt:
                print("\n\nGoodbye! 👋")
                break
            except Exception as e:
                print(f"Error: {e}")

def main():
    parser = argparse.ArgumentParser(description="CLI client for Ollama server")
    parser.add_argument("--host", default="localhost", help="Ollama server host (default: localhost)")
    parser.add_argument("--port", type=int, default=11434, help="Ollama server port (default: 11434)")
    parser.add_argument("--model", default="llama2:7b-chat", help="Model to use (default: llama2:7b-chat)")
    parser.add_argument("--list-models", action="store_true", help="List available models and exit")
    parser.add_argument("--prompt", help="Single prompt mode (non-interactive)")
    parser.add_argument("--stream", action="store_true", help="Enable streaming output")
    
    args = parser.parse_args()
    
    client = OllamaClient(args.host, args.port)
    
    # Test connection
    print(f"🔌 Connecting to Ollama at {args.host}:{args.port}...")
    models = client.list_models()
    
    if not models:
        print("❌ Could not connect to Ollama server or no models available")
        print("\n💡 Troubleshooting tips:")
        print("1. Make sure Ollama is running: ollama serve")
        print("2. Set environment variable: $env:OLLAMA_HOST = '0.0.0.0:11434'")
        print("3. Check firewall settings")
        print(f"4. Test manually: curl http://{args.host}:{args.port}/api/tags")
        sys.exit(1)
    
    print(f"✅ Connected! Found {len(models)} models:")
    for model in models:
        print(f"  - {model['name']}")
    print()
    
    if args.list_models:
        return
    
    # Check if specified model exists
    model_names = [m['name'] for m in models]
    if args.model not in model_names:
        print(f"❌ Model '{args.model}' not found on server")
        print(f"Available models: {', '.join(model_names)}")
        print(f"\n💡 To pull a model: ollama pull {args.model}")
        sys.exit(1)
    
    if args.prompt:
        # Single prompt mode
        print(f"🤖 Generating response for: {args.prompt}")
        print("Response:", end=" ")
        response = client.generate(args.model, args.prompt, args.stream)
        if not args.stream:
            print(response)
    else:
        # Interactive chat mode
        client.chat(args.model)

if __name__ == "__main__":
    main()
