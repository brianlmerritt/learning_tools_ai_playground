# macOS + Docker Desktop Setup

This guide covers running the learning_tools_ai_playground stack locally on macOS with Docker Desktop.

## Prerequisites

Install Docker Desktop for Mac from <https://docs.docker.com/desktop/install/mac-install/>.

Install helper tools via Homebrew:

```bash
brew install jq
brew install yq        # mikefarah/yq — REQUIRED (not the Python pip yq)
```

> **Important:** The shell scripts require `mikefarah/yq` (the Go binary installed by `brew install yq`).
> If you have a Python virtual environment active that contains the `yq` pip package, that version
> will shadow the Homebrew binary and cause errors like `jq: Unknown option -o`.
> Deactivate the venv before running `bin/*.sh` scripts, or ensure `/opt/homebrew/bin` is earlier in
> your `$PATH` than `.venv/bin`.

## Clone and initialise

```bash
git clone https://github.com/brianlmerritt/learning_tools_ai_playground.git
cd learning_tools_ai_playground
git checkout macos
```

Initialise submodules:

```bash
git submodule sync --recursive
git submodule update --init --recursive
```

## Environment variables

Copy the example env file and populate your secrets:

```bash
cp .env.example bin/setup_environment.sh   # or edit bin/setup_environment.sh directly
```

Key macOS defaults (already set in `bin/setup_environment.sh`):

| Variable | macOS value | Notes |
|---|---|---|
| `USE_NVIDIA` | `false` | Docker Desktop for Mac has no NVIDIA GPU passthrough |
| `MOODLE_NETWORK` | `moodle-docker_default` | Compose project default network |
| `MOODLE_DOCKER_WEB_HOST` | `localhost` | Browser access |
| `OLLAMA_BASE_URL` | `http://host.docker.internal:11434` | Native Ollama on Mac (Apple Silicon) |

> **Security:** Do not commit real API keys. Keep them in a local `.env` or `bin/setup_environment.sh`
> which is already gitignored / should remain local.

## GPU / Ollama on Apple Silicon

Docker Desktop for Mac does not support NVIDIA GPU passthrough. Always set `USE_NVIDIA=false`.

For best LLM performance on Apple Silicon, run Ollama natively on macOS:

```bash
brew install ollama
ollama serve
```

Containers reach native Ollama via `http://host.docker.internal:11434`.

## Start Moodle

```bash
./bin/moodle_up.sh
```

Moodle will be available at <http://localhost:8000>.

## Start AI plugins

```bash
./bin/plugin_submodules.sh   # initialise / update plugin submodules
./bin/ai_up.sh               # start plugin Docker stacks
```

## Stop everything

```bash
./bin/ai_down.sh
./bin/moodle_down.sh
```

## Networking model

| Who is calling | Who is being called | Address to use |
|---|---|---|
| Mac browser | Any published container port | `http://localhost:<port>` |
| Container | Another container in same Compose project | `http://<service-name>:<internal-port>` |
| Container | Container in a different Compose project | `http://<service-name>:<internal-port>` (shared network required) |
| Container | Service running natively on the Mac | `http://host.docker.internal:<port>` |

All plugin compose stacks join the Moodle Docker network via:

```yaml
networks:
  default:
    external: true
    name: ${MOODLE_NETWORK:-moodle-docker_default}
```

Avoid `network_mode: host` — it is not supported on Docker Desktop for Mac.
Avoid hardcoded container IPs — they are not stable.

## Validation checklist

```bash
# 1. Confirm branch
git branch --show-current         # should print: macos

# 2. Confirm .gitmodules is fixed
git diff HEAD -- .gitmodules

# 3. Sync and initialise submodules
git submodule sync --recursive
git submodule update --init --recursive

# 4. Check Docker networks after moodle_up.sh
docker network ls | grep moodle

# 5. Validate each compose stack config (run from the plugin directory)
docker compose config --quiet
```
