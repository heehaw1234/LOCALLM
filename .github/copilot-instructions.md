<!-- Use this file to provide workspace-specific custom instructions to Copilot. For more details, visit https://code.visualstudio.com/docs/copilot/copilot-customization#_use-a-githubcopilotinstructionsmd-file -->

# Ollama Network Access Project

This is a Python project for creating network interfaces to access Ollama (local LLM server) from various devices and applications.

## Project Context
- **Purpose**: Enable network access to local Ollama LLM server
- **Language**: Python 3.8+
- **Framework**: FastAPI for web APIs, requests/httpx for HTTP clients
- **Target**: Cross-platform network interfaces (web, CLI, API)

## Code Style Guidelines
- Use type hints for all function parameters and return values
- Follow PEP 8 style guidelines
- Add docstrings for all functions and classes
- Use async/await for network operations where possible
- Handle exceptions gracefully with informative error messages

## Key Components
- **Ollama API**: REST API interface to Ollama server
- **Network Configuration**: Cross-platform network setup
- **Multiple Interfaces**: Web UI, CLI, API clients, proxy server
- **Error Handling**: Robust connection and timeout handling

## Dependencies
- `requests`: HTTP client for synchronous operations
- `httpx`: Async HTTP client
- `fastapi`: Web framework for proxy server
- `uvicorn`: ASGI server
- `click`: CLI framework

## Common Patterns
- Always check server connectivity before API calls
- Use timeouts for all network requests
- Provide both sync and async client options
- Include streaming response support
- Log requests for debugging and monitoring

## Security Considerations
- This is for local/trusted network use
- Network access exposes Ollama to other devices
- Consider firewall implications
- Authentication not implemented (add if needed)
