# “Add-on Project Requirements for Learning Tools AI PLayground - SOLR ⇄ RAG Bridge”

> **Context**
> We have a GitHub repository ([https://github.com/brianlmerritt/learning_tools_ai_playground](https://github.com/brianlmerritt/learning_tools_ai_playground)) that already contains Moodle and optional Solr as Git submodules. We now want three *new* sub-repositories—added as submodules—to implement a search/embeddings/RAG bridge.
>
> ### Submodules to create
>
> 1. **`solr-nginx-lua-subsystem`** – reverse proxy in OpenResty/Nginx + Lua that forwards Moodle ⇄ Solr traffic and “tees” each request/response into Redis.
> 2. **`embeddings-workers-subsystem`** – Redis-backed queue (RQ) with workers that call either OpenAI `/v1/embeddings` or local Ollama embeddings and write vectors + metadata to a store-agnostic interface.
> 3. **`rag-retrieval-subsystem`** – REST façade that exposes OpenAI-style `/v1/chat/completions`; retrieval layer must support Solr DenseVectorField and PostgreSQL pgvector first, with plug-ins for Pinecone and Weaviate later.
>
> **Goal**: a plug-and-play bridge that lets Moodle's existing Solr Global Search feed a Retrieval-Augmented-Generation (RAG) workflow without changing Moodle or Solr code.

---

### 1  General design constraints

* All three subsystems **must be Git submodules** checked out under `/plugins/<name>` to keep the main repo clean and enable independent CI; follow best-practice patterns for nested submodules (lock SHA, forbid `--recursive` pushes, document update flow). ([reddit.com][1])
* Each subsystem must provide a Dockerfile and a `docker-compose.yaml` in its root directory.
* The main script for bringing up all AI-related services is `bin/ai_up.sh`. This script reads `configs/plugins.yaml`, ensures all plugins/submodules are present under `/plugins`, attaches them to the correct Docker network, and runs the appropriate `docker-compose` commands for each plugin/submodule.
* Do **not** rely on a top-level `docker-compose.override.yml` for orchestration; instead, all orchestration and network integration is handled by `ai_up.sh`.
* Every service **exposes health-check endpoints** (`/health` or nginx stub_status) for integration with Playground's existing monitoring.
* Unit tests must run via `pytest` (Python) or `busted` (Lua) and be callable from `make test`.
* Configuration exclusively through `.env` or Helm values—no hard-coded keys.
* **Secrets (OpenAI keys, DB passwords) are managed via `/bin/setup_environment.sh` and are never committed to Git.**

---

### 2  Subsystem A – `solr-nginx-lua-subsystem`

| Requirement                                                                                                                                                                                      | Notes & references                      |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | --------------------------------------- |
| Reverse proxy built on **OpenResty (`lua-nginx-module`)** with TLS passthrough. ([github.com][2])                                                                                                | Gives Lua hooks plus Nginx performance. |
| Use `access_by_lua*` to parse inbound request, read body (enable `client_body_buffer_size`), and **LPUSH** a JSON job onto Redis list `solr_jobs`. ([forum.openresty.us][3], [python-rq.org][4]) |                                         |
| Try to add < 1 ms latency at 300 req/s (target drawn from forum benchmarks). ([forum.openresty.us][3])                                                                                             |                                         |
| If Redis is down, log and drop the job without affecting search response.                                                                                                                        |                                         |
| Provide optional Lua switch to down-sample queries (e.g., 1 in N) for load control.                                                                                                              |                                         |
| Include example Moodle Solr endpoint wiring (`proxy_pass http://solr:8983/solr`). ([docs.moodle.org][5])                                                                                         |                                         |

---

### 3  Subsystem B – `embeddings-workers-subsystem`

| Requirement                                                                                                                                       | Notes & references |
| ------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ |
| Queue layer: **Redis + Python RQ** workers. ([python-rq.org][4], [twilio.com][6])                                                                 |                    |
| Workers consume `solr_jobs`, extract `doc_id`, `query`, or snippet, then call an **Embedding Facade**:                                            |                    |
| \* **OpenAI adapter** hitting `/v1/embeddings` (supports models like `text-embedding-3-large`). ([platform.openai.com][7], [docs.pinecone.io][8]) |                    |
| \* **Ollama adapter** calling local `POST /api/embeddings`. ([ollama.com][9])                                                                     |                    |
| Embedding adapters must implement `encode(texts) -> List[float]` and be swappable via `EMBEDDINGS_PROVIDER=openai \| ollama`.                    |                    |
| Store vectors & metadata through a **Vector Store Facade** that the RAG service will read (see §4).                                               |                    |
| Provide integration tests that embed a sample sentence and assert cosine similarity ≈ 1 when re-queried.                                          |                    |

---

### 4  Subsystem C – `rag-retrieval-subsystem`

| Requirement                                                                                                                                                                                                                        | References |
| ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------- |
| Expose **OpenAI-style chat API**: `/v1/chat/completions`. The body contains standard role-based messages; the service performs retrieval-augmented generation. ([platform.openai.com][7])                                          |            |
| **Retrieval adapters (phase 1):**                                                                                                                                                                                                  |            |
| \* **Solr DenseVectorField** using `/query` with `knn=…` param. ([solr.apache.org][10], [stackoverflow.com][11])                                                                                                                   |            |
| \* **PostgreSQL + pgvector**, using `SELECT … ORDER BY embedding <-> $1 LIMIT k`. ([supabase.com][12], [medium.com][13])                                                                                                           |            |
| **Retrieval adapters (phase 2, optional):** Pinecone (`/v1/vectors/upsert`, `/query`) ([docs.pinecone.io][14], [docs.pinecone.io][15]) and Weaviate (`/v1/graphql`) with OpenAI vectorizer. ([weaviate.io][16], [weaviate.io][17]) |            |
| Follow RAG best practices—retrieve k ≈ 8, construct a context window ≤ 8 KiB, then call chosen LLM (OpenAI, Ollama, or user-supplied). ([docs.pinecone.io][18], [wsj.com][19])                                                     |            |
| Provide streaming (`text/event-stream`) and non-streaming modes.                                                                                                                                                                   |            |
| Must fall back gracefully when no relevant vectors are found.                                                                                                                                                                      |            |

---

### 5  Repository & CI structure

```
learning_tools_ai_playground/
│
├─ plugins/
│   ├─ solr-nginx-lua-subsystem/      (Git submodule)
│   ├─ embeddings-workers-subsystem/  (Git submodule)
│   └─ rag-retrieval-subsystem/       (Git submodule)
│
├─ docker-compose.yml      # (legacy, not used for new subsystems)
├─ bin/ai_up.sh            # Main script for bringing up all AI/bridge subsystems
└─ .github/workflows/
    ├─ lua-proxy-ci.yml    # lint + openresty tests
    ├─ python-workers-ci.yml
    └─ rag-service-ci.yml
```

* CI must pin submodule SHAs and fail if `git submodule status` shows dirty. ([reddit.com][1])
* Release tags in each submodule propagate via GitHub Actions using `git submodule update --remote --merge`.
* All new subsystems must be compatible with orchestration via `bin/ai_up.sh`.

---

### 6  Security & Ops

* **Secrets (OpenAI keys, DB passwords) are managed via `/bin/setup_environment.sh` and are never committed to Git.**
* Provide Prometheus exporters: Nginx `stub_status`, RQ `rq_exporter`, and custom metrics for RAG latency.
* Document upgrade path when Solr version bumps (note: DenseVectorField stable since Solr 9). ([solr.apache.org][10])

---

### 7  Deliverables

1. Three GitHub repositories initialised and wired as submodules under `/plugins`.
2. Working `bin/ai_up.sh` demo indexing at least 100 Moodle pages and answering a RAG query.
3. Markdown docs: **setup**, **architecture diagram**, **API examples**, **benchmark notes** (latency & throughput).
4. 50 % test coverage in each submodule (later aim for 80% ).

---

**End of prompt** – proceed to implementation.

[1]: https://www.reddit.com/r/git/comments/flw1dz/best_practise_for_projects_with_multiple_layers/?utm_source=chatgpt.com "Best Practise for Projects with multiple layers of submodules : r/git"
[2]: https://github.com/openresty/lua-nginx-module?utm_source=chatgpt.com "openresty/lua-nginx-module: Embed the Power of Lua into ... - GitHub"
[3]: https://forum.openresty.us/d/4406-28dc54b92f073f970eba15c52688b8a7?utm_source=chatgpt.com "Nginx : Reverse Proxy + Redis - OpenResty Forum"
[4]: https://python-rq.org/?utm_source=chatgpt.com "RQ: Simple job queues for Python"
[5]: https://docs.moodle.org/en/Global_search?utm_source=chatgpt.com "Global search - MoodleDocs"
[6]: https://www.twilio.com/en-us/blog/developers/tutorials/building-blocks/first-task-rq-redis-python?utm_source=chatgpt.com "How to Run Your First Task with RQ, Redis, and Python - Twilio"
[7]: https://platform.openai.com/docs/api-reference/embeddings/create?utm_source=chatgpt.com "API Reference - OpenAI Platform"
[8]: https://docs.pinecone.io/models/text-embedding-3-large?utm_source=chatgpt.com "text-embedding-3-large | OpenAI - Pinecone Docs"
[9]: https://ollama.com/blog/embedding-models?utm_source=chatgpt.com "Embedding models · Ollama Blog"
[10]: https://solr.apache.org/guide/solr/latest/query-guide/dense-vector-search.html?utm_source=chatgpt.com "Dense Vector Search :: Apache Solr Reference Guide"
[11]: https://stackoverflow.com/questions/69626343/vector-based-search-in-solr?utm_source=chatgpt.com "Vector based search in solr - Stack Overflow"
[12]: https://supabase.com/blog/openai-embeddings-postgres-vector?utm_source=chatgpt.com "Storing OpenAI embeddings in Postgres with pgvector - Supabase"
[13]: https://medium.com/%40magda7817/better-together-openai-embeddings-api-with-postgresql-pgvector-extension-7a34645bdac2?utm_source=chatgpt.com "Better Together: OpenAI Embeddings API With PostgreSQL pgvector ..."
[14]: https://docs.pinecone.io/integrations/openai?utm_source=chatgpt.com "OpenAI - Pinecone Docs"
[15]: https://docs.pinecone.io/guides/get-started/overview?utm_source=chatgpt.com "Pinecone Docs: Pinecone Database"
[16]: https://weaviate.io/developers/weaviate/model-providers/openai?utm_source=chatgpt.com "OpenAI + Weaviate"
[17]: https://weaviate.io/developers/weaviate/model-providers/openai/embeddings?utm_source=chatgpt.com "Text Embeddings - Weaviate"
[18]: https://docs.pinecone.io/guides/get-started/build-a-rag-chatbot?utm_source=chatgpt.com "Build a RAG chatbot - Pinecone Docs"
[19]: https://www.wsj.com/articles/how-a-decades-old-technology-and-a-paper-from-meta-created-an-ai-industry-standard-354a810e?utm_source=chatgpt.com "How a Decades-Old Technology and a Paper From Meta Created an AI Industry Standard"
