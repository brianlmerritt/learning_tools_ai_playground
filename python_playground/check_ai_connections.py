import os
import requests
from requests.exceptions import RequestException
import socket

# Define network hosts and ports
weaveate_host = "weaviate"
weaveate_port = 8081
ollama_host = "ollama"
ollama_port = 11434
solr_host = "solr"
solr_port = 8983
elasticsearch_host = "elasticsearch"
elasticsearch_port = 9200
tika_host = "tika"
tika_port = 9998

def check_env_var(var_name):
    return os.environ.get(var_name) is not None

def check_connection(url):
    try:
        response = requests.get(url, timeout=5)
        return response.status_code == 200
    except RequestException:
        return False

def check_port(host, port, name):
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(5)
        result = sock.connect_ex((host, port))
        sock.close()
        if result == 0:
            print(f"{name}: 'Available'")
        else:
            print(f"{name}: 'NOT Available'")
    except:
        print(f"{name} is NOT reachable")

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
check_port(weaveate_host, weaveate_port, "Weaviate")
check_port(elasticsearch_host, elasticsearch_port, "ElasticSearch")
check_port(solr_host, solr_port, "SOLR")
check_port(ollama_host, ollama_port, "OLLAMA")
check_port(tika_host, tika_port, "Tika")

print("\nCheck complete.")
