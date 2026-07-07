# Learning Tools AI Playground - WIP!

## Project Description
The Learning Tools AI Playground is a docker environment designed for experimenting with Moodle and various AI systems. It integrates Moodle and Moodle-Docker as submodules, facilitating the automatic loading of other Moodle plugins upon request. The AI aspect of the playground includes a series of plugins supporting vector stores and local or remote Large Language Models (LLMs), offering scalable and customizable AI experimentation within Moodle.

### Helper Scripts
Within the `bin` directory, several helper scripts are available to streamline the setup and management of the Moodle AI Playground:

- `moodle_submodules.sh`: Pulls in necessary Moodle plugins and supporting systems, checking out the relevant branch.  Re-run this script any time you change the moodle.yaml file to bring in the correct repositories and branches.
- `plugin_submodules.sh`: Fetches the required AI plugins, systems, and tools to build the AI playground.
- `moodle_up.sh`: Launches the Moodle docker server and its services.
- `moodle_down.sh`: Stops the Moodle docker server.
- `ai_up.sh`: Activates the AI plugins.
- `ai_down.sh`: Deactivates the AI plugins.

## Installation

### Prerequisites

**Linux:**
```bash
sudo apt-get install jq yq  # JSON and YAML parsers
```

**macOS (recommended):**
```bash
brew install jq yq  # Install via Homebrew — REQUIRED (not Python yq)
docker --version    # Ensure Docker Desktop for Mac is installed
```

**Windows:** Untested. Docker Desktop + WSL2 recommended.

### Clone and initialise

```bash
git clone https://github.com/brianlmerritt/learning_tools_ai_playground
cd learning_tools_ai_playground
git checkout macos  # or main for Linux

# Pull in all submodules (Moodle, plugins, supporting systems)
git submodule sync --recursive
git submodule update --init --recursive
```

### Configure environment

```bash
# Copy the example env file and populate your secrets
cp .env.example .env

# Edit .env with your API keys and preferences:
# - OPENAI_API_KEY, ANTHROPIC_API_KEY, HUGGINGFACE_API_KEY
# - MOODLE_DOCKER_WEB_PORT, MOODLE_DOCKER_SSL (if needed)
# - MOODLE_DOCKER_DB_PORT (if exposing Postgres to localhost)

nano .env  # or your preferred editor
```

### Install Moodle plugins and submodules

```bash
./bin/moodle_submodules.sh  # Fetch Moodle plugins (themes, activities, etc.)
./bin/plugin_submodules.sh  # Fetch AI plugins (optional)
```

For detailed macOS setup and networking model, see [docs/macos-docker.md](docs/macos-docker.md).

## Configuration

### Environment variables (.env)

All configuration is managed via `.env` (which is gitignored). Edit `.env` directly — **do not edit `bin/setup_environment.sh`** (it sources `.env` automatically).

Key variables:

| Variable | Default | Purpose |
|---|---|---|
| `USE_NVIDIA` | `false` | Enable NVIDIA GPU passthrough (Linux only; always `false` on Mac) |
| `MOODLE_NETWORK` | `moodle-docker_default` | Docker network name |
| `MOODLE_DOCKER_WEB_HOST` | `localhost` | Moodle hostname |
| `MOODLE_DOCKER_WEB_PORT` | `8000` | Moodle HTTP port |
| `MOODLE_DOCKER_SSL` | `false` | Enable HTTPS (requires SSL certs in `core/nginx_proxy/`) |
| `MOODLE_DOCKER_BROWSER` | `chrome` | Behat testing browser (Chrome or Firefox) |
| `MOODLE_DOCKER_DB_PORT` | (unset) | Expose Postgres to localhost (e.g. `127.0.0.1:5432`) |
| `OPENAI_API_KEY` | (empty) | OpenAI API key |
| `ANTHROPIC_API_KEY` | (empty) | Anthropic API key |
| `HUGGINGFACE_API_KEY` | (empty) | Hugging Face API key |
| `OLLAMA_BASE_URL` | `http://host.docker.internal:11434` | Native Ollama on Mac |

### Moodle plugins (configs/moodle.yaml)

Selects which Moodle plugins to install (themes, activities, blocks, search engines, etc.). Update this file, then run `./bin/moodle_submodules.sh` to fetch/update plugins.

### AI plugins (configs/plugins.yaml)

Configures which AI subsystems to run (Ollama, Weaviate, Elasticsearch, etc.). Set `use_nvidia: false` on Mac or without NVIDIA GPU; `true` only on Linux with NVIDIA GPU.

### Moodle Docker overrides (configs/local_nossl.yaml / local_ssl.yaml)

Automatically selected based on `MOODLE_DOCKER_SSL`. Overrides services and environment in the main compose stack. On macOS, both use native arm64 `seleniarm/standalone-chromium` Selenium image for Behat tests.

## Operation

### Start Moodle

```bash
./bin/moodle_up.sh
```

This:
1. Sources `.env` and exports all environment variables
2. Initialises Moodle submodules if needed
3. Brings up PostgreSQL, Apache, Selenium, and supporting services
4. Waits for the database to be ready

Moodle is then available at `http://localhost:8000`.

### Complete Moodle installation

1. Visit `http://localhost:8000` in your browser
2. Follow the web installer (database pre-configured)
3. Create admin account and complete setup
4. Database persists across restart cycles

### Access the Moodle database locally

If you set `MOODLE_DOCKER_DB_PORT=127.0.0.1:5432` in `.env`, Postgres is accessible on macOS:

```bash
psql -h localhost -U moodle -d moodle  # From terminal
```

```python
# From Python:
import psycopg2
conn = psycopg2.connect(host="localhost", port=5432,
                        dbname="moodle", user="moodle",
                        password="m@0dl3ing")
```

### Start AI plugins (optional)

```bash
./bin/plugin_submodules.sh  # Fetch/update AI plugins
./bin/ai_up.sh              # Start Docker stacks
```

Default port mappings:

| Service | Port | Notes |
|---|---|---|
| Moodle | 8000 | HTTP on localhost |
| PostgreSQL | 5432 | If `MOODLE_DOCKER_DB_PORT` is set |
| Ollama | 11434 | Native on macOS (not Docker) |
| Elasticsearch | 9200 | If enabled in `plugins.yaml` |
| Weaviate | 8081 | If enabled |
| Solr | 8983 | If enabled |
| Tika | 9998 | If enabled |
| Kibana | 5601 | For Elasticsearch |

### Shut down

```bash
./bin/ai_down.sh      # Stop AI plugins
./bin/moodle_down.sh  # Stop Moodle and database
```

Database persists; use `docker volume rm moodle-docker_moodledb_data` to reset.

## Known issues & notes

### Python yq vs mikefarah yq

All scripts require the Go binary version of yq (`mikefarah/yq`), installed via `brew install yq`. If your venv contains the Python `yq` package, it will shadow the Homebrew version and cause scripts to fail with `jq: Unknown option -o`. Solution: run scripts with venv deactivated, or ensure `/opt/homebrew/bin` comes before `.venv/bin` in `$PATH`.

### macOS Selenium image

On Apple Silicon (M1/M2/M3), the `macos` branch uses `seleniarm/standalone-chromium` (native arm64) instead of amd64-only `selenium/standalone-firefox`. Behat tests will use Chromium instead of Firefox.

### Moodle plugin dependency versions

Some plugins require newer Moodle build versions. If you see "Plugin dependencies check failed" during install, update `configs/moodle.yaml` to a newer tag (e.g. `v4.5.3`) and re-run `./bin/moodle_submodules.sh`.

### Fixed in this release

- ✅ `.gitmodules` updated: 10 plugin submodules now use relative paths (was absolute Linux paths, breaking on macOS)
- ✅ `sed -i` fixed for macOS (added compatibility wrapper)
- ✅ `grep -oP` (Perl regex) replaced with portable `sed` equivalents
- ✅ `.env`-based configuration: secrets no longer in scripts
- ✅ Inline yq flavor detection: scripts work with both mikefarah/yq and Python yq
- ✅ `yq eval -i` replaced with portable grep+cat in compose file updates
- ✅ Nginx proxy now only runs when `MOODLE_DOCKER_SSL=true`
- ✅ PostgreSQL port binding via `MOODLE_DOCKER_DB_PORT` env var
- ✅ All bash scripts are fully macOS-compatible

## License
This project is licensed under the MIT License. For more details, see the LICENSE file in the project repository.

## Contributions
Contributions to the Moodle AI Playground are welcome! If you're interested in contributing, please follow these steps:

1. Fork the repository.
2. Create a new branch for your feature or fix.
3. Commit your changes with clear, descriptive messages.
4. Push your branch and submit a pull request.

For more detailed instructions, please refer to [CONTRIBUTING.md](CONTRIBUTING.md)

## Todo
- [ ] Get minimum AI system of SOLR and ElasticSearch running and integrated with Moodle environment
- [ ] Get working Ollama and/or text generation webui install working
- [ ] Setup Moodle environment to test search (and export to vector stores)
- [ ] Setup Moodle course restore so course backups can be restored in the AI playground and used to test the AI and RAG system
- [ ] Setup RAG system to work with Moodle and SOLR or ElasticSearch vector stores
- [ ] Setup Moodle content export to Weaviate and build Multi-modal RAG system


## Known issues

1. The Moodle part of the AI playground uses GIT submodules.  If you change any code inside of core/moodle you will not be able to push to Moodle core.  By it's nature, git submodules can get confused, and do not understand the moodle.yaml configuration, so any time you run `git submodule update --init --recursive` you should run the `./bin\moodle_submodules.sh` script to get the right branches back.

## Acknowledgements
- Place to acknowledge individuals, organizations, or projects that have contributed to the development of the Moodle AI Playground.

