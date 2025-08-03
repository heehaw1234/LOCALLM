#!/usr/bin/env python3
"""
Remote CLI client for connecting to Ollama server over network
Usage: python remote_chat_client.py --host auto
       python remote_chat_client.py --host 192.168.1.115
       python remote_chat_client.py --discover
"""

import argparse
import requests
import json
import sys
import socket
import subprocess
import re
from typing import Optional, List

class RemoteOllamaClient:
    def __init__(self, host: str = "auto", port: int = 11434):
        if host == "auto":
            host = self.discover_ollama_server()
        
        self.host = host
        self.port = port
        self.base_url = f"http://{host}:{port}"
        print(f"🌐 Connecting to Ollama at {self.base_url}")
    def discover_ollama_server(self) -> str:
        """Automatically discover Ollama server on the network"""
        print("🔍 Auto-discovering Ollama server...")
        
        # Method 1: Try common IP ranges
        potential_hosts = self.get_network_range()
        
        for host in potential_hosts:
            if self.test_host_connection(host):
                print(f"✅ Found Ollama server at: {host}")
                return host
        
        # Method 2: Try localhost as fallback
        if self.test_host_connection("localhost"):
            print("✅ Using localhost connection")
            return "localhost"
        
        # Method 3: Ask user for IP
        print("❌ Could not auto-discover Ollama server")
        return self.prompt_for_ip()
    
    def get_network_range(self) -> List[str]:
        """Get likely IP addresses in the local network"""
        potential_hosts = ["localhost", "127.0.0.1"]
        
        try:
            # Get local IP to determine network range
            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            s.connect(("8.8.8.8", 80))
            local_ip = s.getsockname()[0]
            s.close()
            
            # Extract network base (e.g., 192.168.1.x)
            ip_parts = local_ip.split('.')
            network_base = '.'.join(ip_parts[:3])
            
            # Add current machine's IP first
            potential_hosts.append(local_ip)
            
            # Common router/server IPs in the network
            common_endings = [1, 2, 10, 100, 101, 110, 111, 115, 200]
            for ending in common_endings:
                ip = f"{network_base}.{ending}"
                if ip != local_ip and ip not in potential_hosts:
                    potential_hosts.append(ip)
                    
        except Exception as e:
            print(f"⚠️  Could not detect network range: {e}")
        
        return potential_hosts
    
    def test_host_connection(self, host: str) -> bool:
        """Test if a host has Ollama running"""
        try:
            response = requests.get(f"http://{host}:{self.port}/api/tags", timeout=2)
            return response.status_code == 200
        except:
            return False
    
    def prompt_for_ip(self) -> str:
        """Prompt user to enter the Ollama server IP"""
        print("\n📝 Please enter the Ollama server details:")
        print("💡 Tip: Check the server machine's quick_start.bat output for the correct IP")
        
        while True:
            host = input("🌐 Enter server IP (or 'scan' to try discovery again): ").strip()
            
            if host.lower() == 'scan':
                return self.discover_ollama_server()
            
            if not host:
                print("❌ Please enter a valid IP address")
                continue
            
            if self.test_host_connection(host):
                print(f"✅ Connection successful to {host}")
                return host
            else:
                print(f"❌ Could not connect to {host}:{self.port}")
                print("💡 Make sure Ollama is running with network access on that machine")
                retry = input("🔄 Try again? (y/n): ").strip().lower()
                if retry != 'y':
                    sys.exit(1)
        
    def test_connection(self) -> bool:
        """Test if we can connect to the remote Ollama server"""
        try:
            response = requests.get(f"{self.base_url}/api/tags", timeout=5)
            return response.status_code == 200
        except requests.exceptions.RequestException as e:
            print(f"❌ Connection failed: {e}")
            return False
    
    def list_models(self) -> list:
        """Get list of available models"""
        try:
            response = requests.get(f"{self.base_url}/api/tags", timeout=10)
            response.raise_for_status()
            models = response.json().get("models", [])
            return [model["name"] for model in models]
        except requests.exceptions.RequestException as e:
            print(f"Error getting models: {e}")
            return []
    
    def generate(self, model: str, prompt: str, stream: bool = True) -> Optional[str]:
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
                timeout=300,  # 5 minute timeout
                stream=stream
            )
            response.raise_for_status()
            
            if stream:
                # Handle streaming response for real-time output
                full_response = ""
                for line in response.iter_lines():
                    if line:
                        try:
                            data = json.loads(line.decode('utf-8'))
                            if "response" in data:
                                print(data["response"], end="", flush=True)
                                full_response += data["response"]
                            if data.get("done", False):
                                break
                        except json.JSONDecodeError:
                            continue
                print()  # New line after streaming
                return full_response
            else:
                # Handle non-streaming response
                data = response.json()
                return data.get("response", "No response received")
                
        except requests.exceptions.RequestException as e:
            print(f"❌ Error generating response: {e}")
            return None
    
    def interactive_chat(self, model: str):
        """Interactive chat mode with the remote AI"""
        print(f"\n🤖 Starting chat with {model}")
        print("💬 Type your messages (type 'quit', 'exit', or 'bye' to end)")
        print("🔄 Type 'models' to see available models")
        print("=" * 50)
        
        while True:
            try:
                user_input = input("\n💭 You: ").strip()
                
                if user_input.lower() in ['quit', 'exit', 'bye']:
                    print("👋 Goodbye!")
                    break
                    
                if user_input.lower() == 'models':
                    models = self.list_models()
                    print("📋 Available models:")
                    for i, model_name in enumerate(models, 1):
                        print(f"  {i}. {model_name}")
                    continue
                
                if not user_input:
                    continue
                
                print(f"🤖 {model}: ", end="", flush=True)
                response = self.generate(model, user_input, stream=True)
                
            except KeyboardInterrupt:
                print("\n\n👋 Chat ended by user")
                break
            except Exception as e:
                print(f"❌ Error: {e}")

def main():
    parser = argparse.ArgumentParser(description="Remote CLI client for Ollama server")
    parser.add_argument("--host", default="auto", 
                       help="Ollama server IP address ('auto' for discovery, default: auto)")
    parser.add_argument("--port", type=int, default=11434, 
                       help="Ollama server port (default: 11434)")
    parser.add_argument("--model", default="tinyllama:latest", 
                       help="Model to use (default: tinyllama:latest)")
    parser.add_argument("--list-models", action="store_true", 
                       help="List available models and exit")
    parser.add_argument("--prompt", 
                       help="Single prompt mode (non-interactive)")
    parser.add_argument("--discover", action="store_true",
                       help="Scan network for Ollama servers and exit")
    
    args = parser.parse_args()
    
    # Network discovery mode
    if args.discover:
        print("🔍 Scanning network for Ollama servers...")
        client = RemoteOllamaClient("localhost", args.port)  # Dummy client for methods
        potential_hosts = client.get_network_range()
        
        found_servers = []
        for host in potential_hosts:
            if client.test_host_connection(host):
                found_servers.append(host)
                print(f"✅ Found Ollama server at: {host}")
        
        if not found_servers:
            print("❌ No Ollama servers found on the network")
        else:
            print(f"\n📋 Found {len(found_servers)} server(s). Use --host <IP> to connect.")
        return
    
    # Create client
    client = RemoteOllamaClient(args.host, args.port)
    
    # Test connection first
    print("🔍 Testing connection...")
    if not client.test_connection():
        print("❌ Could not connect to Ollama server!")
        print(f"💡 Make sure Ollama is running at {args.host}:{args.port}")
        print("💡 Check your network connection and firewall settings")
        sys.exit(1)
    
    print("✅ Connection successful!")
    
    # List models if requested
    if args.list_models:
        models = client.list_models()
        print("\n📋 Available models:")
        for i, model in enumerate(models, 1):
            print(f"  {i}. {model}")
        return
    
    # Check if model exists
    available_models = client.list_models()
    if args.model not in available_models:
        print(f"⚠️  Model '{args.model}' not found!")
        print("📋 Available models:")
        for i, model in enumerate(available_models, 1):
            print(f"  {i}. {model}")
        if available_models:
            args.model = available_models[0]
            print(f"🔄 Using first available model: {args.model}")
        else:
            print("❌ No models available!")
            sys.exit(1)
    
    # Single prompt mode or interactive chat
    if args.prompt:
        print(f"💭 Prompt: {args.prompt}")
        print(f"🤖 {args.model}: ", end="", flush=True)
        response = client.generate(args.model, args.prompt, stream=True)
    else:
        client.interactive_chat(args.model)

if __name__ == "__main__":
    main()
