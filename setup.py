#!/usr/bin/env python3
"""
Setup script for Ollama network configuration
Automates the process of setting up Ollama for network access
"""

import subprocess
import sys
import os
import socket
import requests
import json
from pathlib import Path

def get_local_ip():
    """Get the local IP address of this machine"""
    try:
        # Create a socket to get local IP
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        local_ip = s.getsockname()[0]
        s.close()
        return local_ip
    except:
        return "Unable to determine"

def check_ollama_installed():
    """Check if Ollama is installed"""
    try:
        result = subprocess.run(["ollama", "--version"], capture_output=True, text=True)
        if result.returncode == 0:
            print(f"✅ Ollama is installed: {result.stdout.strip()}")
            return True
        else:
            print("❌ Ollama is not installed")
            return False
    except FileNotFoundError:
        print("❌ Ollama is not installed or not in PATH")
        return False

def setup_ollama_network():
    """Configure Ollama for network access"""
    print("\n🔧 Setting up Ollama for network access...")
    
    # Set environment variable for current session
    os.environ["OLLAMA_HOST"] = "0.0.0.0:11434"
    print("✅ Set OLLAMA_HOST=0.0.0.0:11434 for current session")
    
    # For Windows, suggest permanent setting
    print("\n💡 To make this permanent on Windows, run this in PowerShell as Administrator:")
    print("[Environment]::SetEnvironmentVariable('OLLAMA_HOST', '0.0.0.0:11434', 'Machine')")
    
    return True

def check_ollama_running():
    """Check if Ollama server is running"""
    try:
        response = requests.get("http://localhost:11434/api/tags", timeout=5)
        if response.status_code == 200:
            print("✅ Ollama server is running")
            models = response.json().get("models", [])
            print(f"📋 Found {len(models)} models:")
            for model in models[:5]:  # Show first 5 models
                print(f"  - {model['name']}")
            return True
        else:
            print("❌ Ollama server responded with error")
            return False
    except requests.exceptions.ConnectionError:
        print("❌ Ollama server is not running")
        return False
    except Exception as e:
        print(f"❌ Error checking Ollama server: {e}")
        return False

def suggest_models():
    """Suggest models to install"""
    print("\n📦 Recommended models to install:")
    models = [
        ("tinyllama", "Small and fast (1.1GB) - Good for testing"),
        ("llama2:7b-chat", "Medium size (3.8GB) - Good balance"),
        ("codellama:7b", "Code generation (3.8GB) - Programming tasks"),
        ("mistral:7b", "High quality (4.1GB) - General use"),
    ]
    
    for name, description in models:
        print(f"  ollama pull {name:<15} # {description}")
    
    print("\n💡 Start with: ollama pull tinyllama")

def check_firewall():
    """Check Windows Firewall settings"""
    print("\n🔥 Firewall Configuration:")
    print("To allow network access, you may need to:")
    print("1. Go to Windows Security > Firewall & network protection")
    print("2. Click 'Allow an app through firewall'")
    print("3. Add 'ollama.exe' if not already listed")
    print("4. Make sure both 'Private' and 'Public' are checked")

def test_network_access(local_ip):
    """Test network access to Ollama"""
    print(f"\n🌐 Testing network access to {local_ip}:11434...")
    
    try:
        response = requests.get(f"http://{local_ip}:11434/api/tags", timeout=10)
        if response.status_code == 200:
            print("✅ Network access is working!")
            print(f"🔗 Other devices can connect to: http://{local_ip}:11434")
            return True
        else:
            print("❌ Network access failed")
            return False
    except Exception as e:
        print(f"❌ Network access failed: {e}")
        return False

def create_start_script():
    """Create a script to start Ollama with network settings"""
    script_content = """@echo off
echo Starting Ollama with network access...
set OLLAMA_HOST=0.0.0.0:11434
echo Set OLLAMA_HOST=%OLLAMA_HOST%
ollama serve
"""
    
    script_path = Path("start_ollama_network.bat")
    script_path.write_text(script_content)
    print(f"📝 Created startup script: {script_path.absolute()}")
    print("   Run this script to start Ollama with network access")

def main():
    """Main setup function"""
    print("🦙 Ollama Network Setup")
    print("=" * 40)
    
    # Get local IP
    local_ip = get_local_ip()
    print(f"🖥️  Your local IP address: {local_ip}")
    
    # Check if Ollama is installed
    if not check_ollama_installed():
        print("\n❌ Please install Ollama first:")
        print("   Visit: https://ollama.ai/download")
        return False
    
    # Setup network configuration
    setup_ollama_network()
    
    # Check if Ollama is running
    if not check_ollama_running():
        print("\n🚀 Starting Ollama server...")
        print("Please run: ollama serve")
        print("(Or use the start_ollama_network.bat script we'll create)")
    
    # Create startup script
    create_start_script()
    
    # Firewall info
    check_firewall()
    
    # Test network access if server is running
    if check_ollama_running():
        test_network_access(local_ip)
    
    # Suggest models
    suggest_models()
    
    # Final instructions
    print("\n🎉 Setup Complete!")
    print("\n📋 Next Steps:")
    print("1. Start Ollama: run 'start_ollama_network.bat' or 'ollama serve'")
    print("2. Pull a model: ollama pull tinyllama")
    print("3. Test locally: ollama run tinyllama 'Hello!'")
    print(f"4. Access from other devices: http://{local_ip}:11434")
    print("5. Use the web interface: open web_interface.html")
    print("6. Or run the proxy server: python proxy_server.py")
    
    return True

if __name__ == "__main__":
    main()
