# ai-software-stack-quantum-bot (Rebalanced: AI Models & Software Stack)

A hardened, two-phase trend-monitoring, LLM-filtering, SQLite-archiving, and Telegram-alerting pipeline modeled directly on [`jijiji88888/ai-hardware-bot`](https://github.com/jijiji88888/ai-hardware-bot) — cleanly scoped to **10 AI Models & Software Stack Layers** (with Quantum Computing delegated to `ai-hardware-bot` to eliminate cross-bot duplication).

## Pipeline Architecture

1. **Multi-Source Ingestion (`app.py` + `scrapers.py`)**
   - **arXiv Atom API**: Single combined query across `cs.AI, cs.LG, cs.CL, cs.CV, cs.MA, cs.DC, cs.PL, cs.DB, cs.SE, cs.IR, cs.HC` preserving `<category>` tags for cross-list-aware per-category bucketing.
   - **Hacker News (Signal-Filtered)**: Polls `/v0/topstories.json` + `/v0/beststories.json` via `ThreadPoolExecutor` (`HN_STORIES_PER_RUN=80`) and keeps only stories meeting `HN_MIN_SCORE` (default `15`), eliminating 1-point `newstories` spam while allowing rising stories to enter once they gain traction.
   - **Techmeme**: Standard RSS with conditional GET (`ETag` / `Last-Modified`), per-feed failure cooldowns, and raw Wayback Machine (`id_`) fallback.
   - **Specialist Engineering & Frontier Lab RSS/Atom (`fetch_standard_rss_2`)**: Enriched parser extracting `<content:encoded>`, tags, author, and OpenGraph fallback snippets across PyTorch Blog, Hugging Face Blog, NVIDIA Developer Blog, DuckDB Blog, LangChain Blog, Qdrant Blog, OpenAI News, Google DeepMind Blog, Google Research Blog, and The Register AI.
   - **OSS Ecosystem Release Feeds (`fetch_ecosystem_releases_rss`)**: Curated GitHub Atom release streams for `vLLM`, `SGLang`, `llama.cpp`, `PyTorch`, `Transformers`, `Ray`, `Polars`, `LiteLLM`, and `Open WebUI` (noisy raw commit streams removed).
   - **Conditional GET (`HTTP 304 Not Modified`) & Cooldown Hygiene**: All RSS/Atom fetchers track `ETag` / `Last-Modified` validators thread-safely and return explicit fetch statuses (`ok`, `not_modified`, `cooldown`, `empty`, `error`), so unchanged or cooling-down feeds skip redundant HTML homepage fallback scraping.
   - **403-Resilient HTML Scrapers (`scrapers.py`)**: Dedicated scrapers for `vllm.ai/blog`, `unsloth.ai/blog`, `ollama.com/blog`, `pola.rs/posts/`, `rocm.blogs.amd.com`, `anthropic.com/news`, `anthropic.com/research`, and `ai.meta.com/blog/` plus a universal fallback using `curl_cffi` native browser TLS impersonation (`chrome`/`safari`/`firefox` profile rotation), UTF-8 decoding, JSON-LD + DOM extraction, WP REST API, XML sitemaps, Jina Reader (`r.jina.ai`), and Wayback Machine CDX (7-day window) — with **zero Google News proxy dependencies**.
   - **Optional SEC EDGAR EFTS (`ENABLE_SEC_EDGAR=false`)**: Full-text search across public filings scoped to AI models and software stack keywords.

2. **Two-Phase Decoupled Queue Runtime (`APScheduler`)**
   - **Fetch phase (`fetch_and_enqueue`)**: Runs every `FETCH_MINUTES` (default `2m`), balances sources via `fair_cap_items()` (`MAX_CANDIDATES_PER_RUN=1000`, pure round-robin across sources), strips tracking URL params, hashes SHA-256 title fingerprints, deduplicates against bounded in-memory caches and SQLite (`processed_urls`, `processed_fingerprints`), and pushes new candidates into `CANDIDATE_QUEUE` (`CANDIDATE_QUEUE_MAX=480`).
   - **Flush phase (`maybe_flush` -> `drain_queue` -> `flush_queue`)**: Checked every `CHECK_QUEUE_SECONDS` (default `1s`). Flushes immediately when queue depth reaches `QUEUE_FLUSH_LIMIT` (default `1`) or after `FORCE_FLUSH_MINUTES` (default `30m`) of staleness. Failed LLM batches are automatically requeued up to `MAX_ITEM_RETRIES` (default `5`).

3. **Strict Dual-Provider LLM Classifier (OpenRouter + Official Gemini API) & SQLite WAL Store**
   - Supports both **OpenRouter** (`OPENROUTER_API_KEY`, `OPENROUTER_MODEL`) and Google's **Official Gemini API** (`GEMINI_API_KEY`, `GEMINI_MODEL` via `generativelanguage.googleapis.com`). Set `LLM_PROVIDER=openrouter` (default) or `LLM_PROVIDER=gemini`, and optionally set `LLM_FALLBACK_PROVIDER` for automatic failover.
   - Evaluates items in batches (`LLM_BATCH_SIZE=12`, `temperature=0.05`, JSON mode) strictly against the 10 AI Models & Software Stack layers, rejecting physical hardware/cooling/packaging (`ai-hardware-bot`), Quantum QPUs (`ai-hardware-bot`), non-AI hard sciences (`frontier-deeptech-bot`), and generic consumer/marketing fluff.
   - Persists accepted signals (`score >= 7.0`) into `ai_stack_quantum_trends.db` (SQLite WAL mode) with structured fields: `stack_layer`, `bottleneck_addressed`, `specific_tech`, `relevance_score`, `why_it_matters`, `ai_stack_thesis`, `telegram_summary`, and `raw_llm_json`.

4. **Telegram Alerting & Digests**
   - Items scoring `>= ALERT_THRESHOLD` (default `7.5`) trigger immediate HTML alerts (`MAX_ALERTS_PER_FLUSH=8`).
   - Remaining accepted items (`>= 7.0`) are delivered in periodic digests every `DIGEST_MINUTES` (default `60m`, `DIGEST_MAX_ITEMS=5`), chunked cleanly under Telegram's message limit.

---

## Strictly Tracked Topics (10 AI Models & Software Stack Layers)

| # | Domain / Stack Layer | Key Frameworks, Labs & Bottlenecks Tracked |
|---|---|---|
| **1** | **Data Engineering & Preprocessing** | Apache Spark, Ray Data, Polars, DuckDB, MinHash LSH, fastText, PII redaction, GPU data starvation; Hugging Face Tokenizers, tiktoken, SentencePiece, BPE/Unigram, vocabulary fertility & compression. |
| **2** | **Deep Learning Frameworks & Distributed Training** | PyTorch (`torch.compile`, TorchDynamo, TorchInductor), JAX, TensorFlow; DeepSpeed, Megatron-LM, FSDP, Ray Train (TP, PP, ZeRO Stages 1–3, pipeline bubbles); TRL, Unsloth, Axolotl, PEFT (LoRA, QLoRA, SFT, RLHF, DPO, KTO, GRPO). |
| **3** | **Low-Level GPU Acceleration & Acceleration Kernels** | NVIDIA CUDA, AMD ROCm, Intel oneAPI; cuDNN, cuBLAS, CUTLASS (Hopper/Blackwell GEMM); NCCL, RCCL (AllReduce/AllGather/ReduceScatter over NVLink/InfiniBand/RoCE); FlashAttention-2/3/4, vLLM PagedAttention, FlashInfer, Triton (HBM/SRAM IO-aware fusion). |
| **4** | **Model Optimization & Quantization** | AutoGPTQ, AutoAWQ, bitsandbytes, llama.cpp / GGML / GGUF (INT8/INT4/FP8/FP4/NVFP4/k-quants); TensorRT-LLM, ONNX Runtime, Apache TVM, OpenVINO (graph compilation, constant folding, 2x–4x TTFT speedups). |
| **5** | **Serving & Inference Engines** | vLLM, SGLang, TGI, TensorRT-LLM, Triton Inference Server (continuous batching, prefix caching, PagedAttention KV-cache, disaggregated prefill); Ollama, llama.cpp, ExLlamaV2/V3, MLC-LLM (Metal/Apple Silicon, Vulkan, AVX-512 local inference). |
| **6** | **Application Orchestration, RAG & Middleware** | LangChain, LangGraph, LlamaIndex, CrewAI, MCP (tool calling, agent state machines); Milvus, Qdrant, Chroma, Pinecone, pgvector (RAG recall & TTFT); Outlines, Instructor, NeMo Guardrails, Guidance (grammar-constrained decoding, logit masking, prompt-injection defense). |
| **7** | **API Gateway & Model Routing** | LiteLLM, Portkey, OpenResty / Envoy, Kong (failover cascading, rate-limiting, cost tracking); FastAPI, gRPC, Uvicorn (async dispatch, SSE streaming transport). |
| **8** | **End-User Presentation & Interface (UX)** | Open WebUI, LibreChat, Next.js Chat Interfaces, Gradio, Streamlit (token-by-token SSE streaming, Markdown/LaTeX rendering, optimistic UI updates, timeout/context-limit error handling). |
| **9** | **Frontier Foundation Models, Multimodal & Test-Time Compute** | OpenAI, Anthropic, Google DeepMind, Meta AI, DeepSeek, Qwen, Mistral, xAI releases; MoE & long-context architectures; test-time compute scaling, PRMs, MCTS search, RL for reasoning, formal verification (AlphaProof); native multimodal, video/audio/speech-to-speech, and 3D/world simulation models. |
| **10** | **Autonomous Agent Swarms, AI Safety, Interpretability & Evals** | Self-directing multi-agent swarms, coding/computer-use agents, recursive workflow optimization; mechanistic interpretability (SAEs/circuits), scalable oversight, alignment faking/control research, red-teaming, and frontier capability/safety benchmarks. |

---

## Quick Start (Docker Compose)

```bash
git clone https://github.com/ajsfgu9/ai-software-stack-quantum-bot.git
cd ai-software-stack-quantum-bot
cp .env.example .env
# Edit .env and set LLM_PROVIDER (openrouter or gemini), OPENROUTER_API_KEY / GEMINI_API_KEY, TELEGRAM_BOT_TOKEN, and TELEGRAM_CHAT_ID
docker compose up -d --build
docker compose logs -f
```

The container runs as non-root `botuser` (UID `10001`) with a read-only root filesystem, `cap_drop: [ALL]`, `no-new-privileges:true`, a 512M memory cap, zero exposed ports, and a live `HEALTHCHECK` monitoring `/app/data/heartbeat.txt`.