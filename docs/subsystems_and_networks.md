# Subsystems, Docker Configurations, and Network Overview

This document provides an overview of the main subsystems, their docker configurations, network ports, and container names used in the Learning Tools Moodle AI Playground.

---

## 1. Core Subsystems

### Moodle Core

- **Repository:** [moodle/moodle](https://github.com/moodle/moodle.git)
- **Dockerized via:** `core/moodle-docker`
- **Config Files:** `configs/moodle.yaml`, `configs/local_ssl.yaml`, `configs/local_nossl.yaml`
- **Key Containers:**
  - `webserver` (Apache + PHP)
  - `db` (PostgreSQL by default)
- **Ports:**
  - `8000` (HTTP, default, non-SSL)
  - `8443` (HTTPS, with SSL override)
- **Network:** `moodle-docker_default` (or as set by `MOODLE_NETWORK`)

### Moodle Plugins

- Managed via `configs/moodle.yaml` and `bin/moodle_submodules.sh`
- Plugins are added as submodules under `core/moodle/` in their respective directories.

---

## 2. AI and Data Subsystems

Configured via `configs/plugins.yaml` and managed by `bin/ai_up.sh` and `bin/plugin_submodules.sh`.

### Main AI Plugins and Services

| Name            | Path                        | Container Name(s)   | Default Ports | Notes |
|-----------------|----------------------------|---------------------|---------------|-------|
| Weaviate        | plugins/weaviate            | `weaviate`          | 8081, 50051   | Vector DB, REST/gRPC |
| Ollama          | plugins/ollama              | `ollama`            | 11434         | LLM server, GPU/CPU |
| ElasticSearch   | plugins/elasticsearch       | (default)           | 9200, 5601    | Search/Vector store |
| SOLR Search     | plugins/solr                | (default)           | 8983          | Search/Vector store |
| Apache Tika     | plugins/apache_tika         | (default)           | 9998          | Document parsing    |
| Python Playground | plugins/python_ai_playground | `python_ai_dev`   | (internal)    | Dev container       |
| PHP Playground  | plugins/php_ai_playground   | (default)           | (internal)    | Dev container       |
| OpenWebUI       | plugins/openwebui           | `open-webui`        | 3000 (host)   | Web UI for LLMs     |

#### Example Docker Compose Files

- `docker_examples/docker-compose-ollama.yaml`
- `docker_examples/docker-compose-openwebui.yaml`
- `docker_examples/docker-compose-weaviate.yaml`

---

## 3. Network and Environment Configuration

### Environment Variables

Set in `bin/setup_environment.sh` and used throughout the scripts:

- `USE_NVIDIA` — Enables GPU support for Ollama and other AI containers.
- `VOLUMES_HOME` — Host directory for persistent docker volumes.
- `MOODLE_NETWORK` — Docker network name (default: `moodle-docker_default`).
- `MOODLE_DOCKER_WEB_HOST` — Hostname for Moodle webserver.
- `MOODLE_DOCKER_WEB_PORT` — Port for Moodle webserver (8000 or 8443).
- `MOODLE_DOCKER_SSL_OVERRIDE` — Forces SSL and port 8443.
- `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `HUGGINGFACE_API_KEY` — API keys for LLMs.

### Docker Networks

- All AI and Moodle containers are attached to the same docker network (default: `moodle-docker_default`) for inter-container communication.
- The network is created by `bin/moodle_up.sh` and referenced by AI containers in `bin/ai_up.sh`.

---

## 4. Ports Overview

| Service         | Container Name   | Host Port | Container Port | Description                |
|-----------------|------------------|-----------|---------------|----------------------------|
| Moodle (HTTP)   | webserver        | 8000      | 80            | Main Moodle site (non-SSL) |
| Moodle (HTTPS)  | webserver        | 8443      | 443           | Main Moodle site (SSL)     |
| SOLR            | solr             | 8983      | 8983          | Search/Vector store        |
| ElasticSearch   | elasticsearch    | 9200      | 9200          | Search/Vector store        |
| Kibana          | kibana           | 5601      | 5601          | ElasticSearch UI           |
| Ollama          | ollama           | 11434     | 11434         | LLM API                    |
| Weaviate        | weaviate         | 8081      | 8080          | Vector DB API              |
| Weaviate gRPC   | weaviate         | 50051     | 50051         | Vector DB gRPC             |
| Apache Tika     | tika             | 9998      | 9998          | Document parsing           |
| OpenWebUI       | open-webui       | 3000      | 8080          | LLM Web UI                 |

---

## 5. Container Names

- **Moodle:** `webserver`, `db`
- **Ollama:** `ollama`
- **Weaviate:** `weaviate`
- **OpenWebUI:** `open-webui`
- **Python Playground:** `python_ai_dev`
- **Other AI Plugins:** Use default service names as per their docker-compose files.

---

## 6. Example: Bringing Up the System

```bash
# Set up environment variables and keys
./bin/setup_environment.sh

# Start Moodle and its network
./bin/moodle_up.sh

# Start AI plugins and attach to the same network
./bin/ai_up.sh
```

---

## 7. Additional Notes

- All containers share a common docker network for seamless integration.
- SSL configuration is controlled via environment variables and the `local_ssl.yaml`/`local_nossl.yaml` files.
- Persistent data is stored in host directories under `${VOLUMES_HOME}`.
- API keys for LLMs must be set in `setup_environment.sh` before starting containers.

---

For more details, see the main [README.md](../README.md) and the configuration files in the `configs/` directory. 