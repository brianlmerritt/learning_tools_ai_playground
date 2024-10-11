import os
import socket
import openai
from openai import OpenAI
import anthropic
from anthropic import Anthropic, HUMAN_PROMPT, AI_PROMPT
from huggingface_hub import HfApi
from requests.exceptions import HTTPError

# Define network hosts and ports
weaviate_host = "weaviate"
weaviate_port = 8081
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
    except Exception as e:
        print(f"{name} is NOT reachable ({e})")

# Check AI services
print("Checking AI services:")

# OpenAI
openai_api_key = check_env_var('OPENAI_API_KEY')
print(f"OpenAI API Key: {'Present' if openai_api_key else 'Missing'}")
if openai_api_key:
    client = OpenAI(api_key=os.environ['OPENAI_API_KEY'])
    try:
        # Make a simple API call
        response = client.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=[
                {"role": "user", "content": "Hello"}
            ],
            max_tokens=1
        )
        print("OpenAI Connection: Successful")
    except Exception as e:
        print(f"OpenAI Connection: Failed ({e})")

# Anthropic AI
anthropic_api_key = check_env_var('ANTHROPIC_API_KEY')
print(f"Anthropic API Key: {'Present' if anthropic_api_key else 'Missing'}")
if anthropic_api_key:
    client = Anthropic(api_key=os.environ['ANTHROPIC_API_KEY'])
    try:
        # Make a simple API call using the Messages API
        message = client.messages.create(
            model="claude-3-haiku-20240307",
            max_tokens=1,
            messages=[
                {"role": "user", "content": "Hello"}
            ]
        )
        print("Anthropic Connection: Successful")
    except Exception as e:
        print(f"Anthropic Connection: Failed ({e})")

# Hugging Face
huggingface_api_key = check_env_var('HUGGINGFACE_API_KEY')
print(f"Hugging Face API Key: {'Present' if huggingface_api_key else 'Missing'}")
if huggingface_api_key:
    hf_api = HfApi(token=os.environ['HUGGINGFACE_API_KEY'])
    try:
        # Make a simple API call
        user_info = hf_api.whoami()
        print("Hugging Face Connection: Successful")
    except HTTPError as e:
        print(f"Hugging Face Connection: Failed ({e})")
    except Exception as e:
        print(f"Hugging Face Connection: Failed ({e})")

print("\nChecking database services:")

# Weaviate
check_port(weaviate_host, weaviate_port, "Weaviate")
check_port(elasticsearch_host, elasticsearch_port, "ElasticSearch")
check_port(solr_host, solr_port, "SOLR")
check_port(ollama_host, ollama_port, "OLLAMA")
check_port(tika_host, tika_port, "Tika")

print("\nCheck complete.")
