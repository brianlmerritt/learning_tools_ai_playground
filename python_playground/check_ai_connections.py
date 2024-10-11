import os
import requests
from requests.exceptions import RequestException
import socket

def check_env_var(var_name):
    return os.environ.get(var_name) is not None

def check_connection(url):
    try:
        response = requests.get(url, timeout=5)
        return response.status_code == 200
    except RequestException:
        return False

def check_port(host, port):
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(5)
    result = sock.connect_ex((host, port))
    sock.close()
    return result == 0

# Check AI services
print("Checking AI services:")

# OpenAI
openai_api_key = check_env_var('OPENAI_API_KEY')
print(f"OpenAI API Key: {'Present' if openai_api_key else 'Missing'}")
if openai_api_key:
    openai_connection = check_connection('https://api.openai.com/v1')
    print(f"OpenAI Connection: {'Successful' if openai_connection else 'Failed'}")

# Anthropic AI
anthropic_api_key = check_env_var('ANTHROPIC_API_KEY')
print(f"Anthropic API Key: {'Present' if anthropic_api_key else 'Missing'}")
if anthropic_api_key:
    anthropic_connection = check_connection('https://api.anthropic.com')
    print(f"Anthropic Connection: {'Successful' if anthropic_connection else 'Failed'}")

# Hugging Face
huggingface_api_key = check_env_var('HUGGINGFACE_API_KEY')
print(f"Hugging Face API Key: {'Present' if huggingface_api_key else 'Missing'}")
if huggingface_api_key:
    huggingface_connection = check_connection('https://huggingface.co/api')
    print(f"Hugging Face Connection: {'Successful' if huggingface_connection else 'Failed'}")

print("\nChecking database services:")

# Weaviate
weaviate_available = check_port('localhost', 8080)
print(f"Weaviate: {'Available' if weaviate_available else 'Not available'}")

# Elasticsearch
elasticsearch_available = check_port('localhost', 9200)
print(f"Elasticsearch: {'Available' if elasticsearch_available else 'Not available'}")

# Ollama
ollama_available = check_port('localhost', 11434)
print(f"Ollama: {'Available' if ollama_available else 'Not available'}")

print("\nCheck complete.")
