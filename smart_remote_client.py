#!/usr/bin/env python3
"""
Smart Remote Ollama Client - Handles Dynamic IPs
Usage: python smart_remote_client.py
       python smart_remote_client.py --scan
       python smart_remote_client.py --host 192.168.1.100
"""

import argparse
import requests
import json
import sys
import socket
import os
import configparser
from typing import Optional, List, Dict

class SmartOllamaClient:
    def __init__(self, config_file: str = "ollama_connection.conf"):
        self.config_file = config_file
        self.config = self.load_config()
        self.port = int(self.config.get('PORT', 11434))
        self.host = None
        self.base_url = None
        
    def load_config(self) -> Dict[str, str]:
        """Load configuration from file"""
        config = {
            'LAST_IP': '',
            'FORCE_IP': '',
            'COMMON_IPS': 'localhost 127.0.0.1',
            'PORT': '11434'
        }
        
        if os.path.exists(self.config_file):
            try:
                with open(self.config_file, 'r') as f:
                    for line in f:
                        line = line.strip()
                        if line and not line.startswith('#') and '=' in line:
                            key, value = line.split('=', 1)
                            config[key.strip()] = value.strip()
            except Exception as e:
                print(f"⚠️  Could not read config file: {e}")
        
        return config
    
    def save_config(self):
        """Save current configuration"""
        try:
            lines = []
            lines.append("# Ollama Remote Connection Configuration")
            lines.append("# This file stores the last known working IP address")
            lines.append("# Edit this file to manually set a preferred IP address")
            lines.append("")
            lines.append("# Last successful connection (auto-updated)")
            lines.append(f"LAST_IP={self.config.get('LAST_IP', '')}")
            lines.append("")
            lines.append("# Manual override (uncomment and set to force a specific IP)")
            force_ip = self.config.get('FORCE_IP', '')
            if force_ip:
                lines.append(f"FORCE_IP={force_ip}")
            else:
                lines.append("# FORCE_IP=192.168.1.100")
            lines.append("")
            lines.append("# Common IPs to try (space-separated)")
            lines.append(f"COMMON_IPS={self.config.get('COMMON_IPS', 'localhost 127.0.0.1')}")
            lines.append("")
            lines.append("# Port (default: 11434)")
            lines.append(f"PORT={self.config.get('PORT', '11434')}")
            
            with open(self.config_file, 'w') as f:
                f.write('\n'.join(lines))
        except Exception as e:
            print(f"⚠️  Could not save config: {e}")
    
    def discover_server(self, force_host: Optional[str] = None) -> bool:
        """Discover Ollama server and set connection details"""
        if force_host:
            if self.test_connection(force_host):
                self.host = force_host
                self.base_url = f"http://{self.host}:{self.port}"
                self.config['LAST_IP'] = self.host
                self.save_config()
                return True
            else:
                print(f"❌ Could not connect to forced host: {force_host}")
                return False
        
        print("🔍 Discovering Ollama server...")
        
        # 1. Try forced IP from config
        force_ip = self.config.get('FORCE_IP', '').strip()
        if force_ip:
            print(f"🎯 Trying forced IP from config: {force_ip}")
            if self.test_connection(force_ip):
                self.host = force_ip
                self.base_url = f"http://{self.host}:{self.port}"
                return True
        
        # 2. Try last known working IP
        last_ip = self.config.get('LAST_IP', '').strip()
        if last_ip:
            print(f"📁 Trying last known IP: {last_ip}")
            if self.test_connection(last_ip):
                self.host = last_ip
                self.base_url = f"http://{self.host}:{self.port}"
                return True
        
        # 3. Try common IPs from config
        common_ips = self.config.get('COMMON_IPS', '').split()
        if common_ips:
            print("🌐 Trying common IPs...")
            for ip in common_ips:
                print(f"   Testing {ip}...")
                if self.test_connection(ip):
                    self.host = ip
                    self.base_url = f"http://{self.host}:{self.port}"
                    self.config['LAST_IP'] = self.host
                    self.save_config()
                    print(f"✅ Found server at: {ip}")
                    return True
        
        # 4. Network scan
        print("🔍 Scanning local network...")
        network_ips = self.get_network_range()
        for ip in network_ips:
            if ip not in common_ips:  # Don't retest
                print(f"   Testing {ip}...")
                if self.test_connection(ip):
                    self.host = ip
                    self.base_url = f"http://{self.host}:{self.port}"
                    self.config['LAST_IP'] = self.host
                    self.save_config()
                    print(f"✅ Found server at: {ip}")
                    return True
        
        return False
    
    def get_network_range(self) -> List[str]:
        """Get potential IP addresses in local network"""
        potential_ips = []
        
        try:
            # Get local IP
            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            s.connect(("8.8.8.8", 80))
            local_ip = s.getsockname()[0]
            s.close()
            
            # Generate network range
            ip_parts = local_ip.split('.')
            network_base = '.'.join(ip_parts[:3])
            
            # Common server IPs
            for ending in [1, 2, 5, 10, 11, 50, 100, 101, 110, 111, 115, 150, 200]:
                ip = f"{network_base}.{ending}"
                if ip != local_ip:
                    potential_ips.append(ip)
            
            # Add local IP
            potential_ips.append(local_ip)
            
        except Exception:
            pass
        
        return potential_ips
    
    def test_connection(self, host: str) -> bool:
        """Test connection to a specific host"""
        try:
            response = requests.get(f"http://{host}:{self.port}/api/tags", timeout=2)
            return response.status_code == 200
        except:
            return False
    
    def list_models(self) -> List[str]:
        """Get available models"""
        try:
            response = requests.get(f"{self.base_url}/api/tags", timeout=10)
            response.raise_for_status()
            models = response.json().get("models", [])
            return [model["name"] for model in models]
        except Exception as e:
            print(f"❌ Error getting models: {e}")
            return []
    
    def generate(self, model: str, prompt: str, stream: bool = True) -> Optional[str]:
        """Generate response"""
        try:
            payload = {
                "model": model,
                "prompt": prompt,
                "stream": stream
            }
            
            response = requests.post(
                f"{self.base_url}/api/generate",
                json=payload,
                timeout=300,
                stream=stream
            )
            response.raise_for_status()
            
            if stream:
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
                print()
                return full_response
            else:
                data = response.json()
                return data.get("response", "No response")
                
        except Exception as e:
            print(f"❌ Error: {e}")
            return None
    
    def interactive_chat(self, model: str):
        """Interactive chat session"""
        print(f"\n🤖 Chat with {model} at {self.base_url}")
        print("💬 Type 'quit' to exit, 'models' to list models, 'reconnect' to find server again")
        print("=" * 60)
        
        while True:
            try:
                user_input = input(f"\n💭 You: ").strip()
                
                if user_input.lower() in ['quit', 'exit', 'bye']:
                    print("👋 Goodbye!")
                    break
                    
                if user_input.lower() == 'models':
                    models = self.list_models()
                    print("📋 Available models:")
                    for i, model_name in enumerate(models, 1):
                        print(f"  {i}. {model_name}")
                    continue
                
                if user_input.lower() == 'reconnect':
                    print("🔄 Reconnecting...")
                    if self.discover_server():
                        print(f"✅ Reconnected to {self.base_url}")
                    else:
                        print("❌ Could not reconnect")
                    continue
                
                if not user_input:
                    continue
                
                print(f"🤖 {model}: ", end="", flush=True)
                self.generate(model, user_input, stream=True)
                
            except KeyboardInterrupt:
                print("\n\n👋 Chat ended")
                break
            except Exception as e:
                print(f"❌ Error: {e}")

def main():
    parser = argparse.ArgumentParser(description="Smart Remote Ollama Client")
    parser.add_argument("--host", help="Force specific host IP")
    parser.add_argument("--model", default="tinyllama:latest", help="Model to use")
    parser.add_argument("--scan", action="store_true", help="Scan for servers and exit")
    parser.add_argument("--list-models", action="store_true", help="List models and exit")
    parser.add_argument("--prompt", help="Single prompt mode")
    parser.add_argument("--config", default="ollama_connection.conf", help="Config file path")
    
    args = parser.parse_args()
    
    client = SmartOllamaClient(args.config)
    
    # Scan mode
    if args.scan:
        print("🔍 Scanning for Ollama servers...")
        found = []
        
        # Test common IPs
        common_ips = client.config.get('COMMON_IPS', '').split()
        network_ips = client.get_network_range()
        all_ips = list(set(common_ips + network_ips))
        
        for ip in all_ips:
            if client.test_connection(ip):
                found.append(ip)
                print(f"✅ Found server at: {ip}")
        
        if not found:
            print("❌ No servers found")
        else:
            print(f"\n📋 Found {len(found)} server(s)")
            print("💡 Use --host <IP> to connect to a specific server")
        return
    
    # Discover server
    if not client.discover_server(args.host):
        print("❌ Could not find any Ollama servers")
        print("💡 Tips:")
        print("   - Make sure Ollama is running with network access")
        print("   - Check the server's quick_start.bat output for the correct IP")
        print("   - Use --scan to search for servers")
        print("   - Edit ollama_connection.conf to set a specific IP")
        sys.exit(1)
    
    print(f"✅ Connected to {client.base_url}")
    
    # List models mode
    if args.list_models:
        models = client.list_models()
        print(f"\n📋 Available models ({len(models)}):")
        for i, model in enumerate(models, 1):
            print(f"  {i}. {model}")
        return
    
    # Check model exists
    models = client.list_models()
    if args.model not in models and models:
        print(f"⚠️  Model '{args.model}' not found")
        print("📋 Available models:")
        for i, model in enumerate(models, 1):
            print(f"  {i}. {model}")
        if models:
            args.model = models[0]
            print(f"🔄 Using: {args.model}")
    
    # Single prompt or interactive
    if args.prompt:
        print(f"💭 Prompt: {args.prompt}")
        print(f"🤖 {args.model}: ", end="", flush=True)
        client.generate(args.model, args.prompt, stream=True)
    else:
        client.interactive_chat(args.model)

if __name__ == "__main__":
    main()
