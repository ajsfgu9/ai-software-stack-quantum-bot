# ai-software-stack-quantum-bot

A hardened, two-phase trend-monitoring, LLM-filtering, SQLite-archiving, and Telegram-alerting pipeline modeled directly on the [`jijiji88888/ai-hardware-bot`](https://github.com/jijiji88888/ai-hardware-bot) architecture — strictly scoped to the **8 AI Software Stack Layers + Quantum Computing**.

## Pipeline Architecture

1. **Multi-Source Ingestion (`app.py` + `scrapers.py`)**
   - **arXiv Atom API**: Single combined query across `cs.LG, cs.CL, cs.DC, cs.PL, cs.DB, cs.SE, cs.IR, cs.HC, quant-ph` preserving `<category>` tags for cross-list-aware per-category bucketing.
   - **Hacker News**: Firebase API (`/v0/newstories.json`) backed by a persistent SQLite `hn_high_water_mark` in `bot_state` and a `ThreadPoolExecutor`.
   - **Techmeme**: Standard RSS with conditional GET (`ETag` / `Last-Modified`), per-feed failure cooldowns, and Wayback Machine fallback.
   - **Specialist Engineering & Quantum RSS/Atom (`fetch_standard_rss_2`)**: Enriched parser extracting `<content:encoded>`, tags, author, and OpenGraph fallback snippets across PyTorch Blog, Hugging Face Blog, NVIDIA Developer Blog, DuckDB Blog, LangChain Blog, Qdrant Blog, Quantum Computing Report, The Quantum Insider, and The Register AI.
   - **OSS Ecosystem Release Feeds (`fetch_ecosystem_releases_rss`)**: Direct GitHub Atom release/commit streams for `vLLM`, `vLLM Daily`, `llama.cpp`, `PyTorch`, `Ray`, `Polars`, `LiteLLM`, `Open WebUI`, and `Qiskit`.
   - **403-Resilient HTML Scrapers (`scrapers.py`)**: Dedicated scrapers for `vllm.ai/blog`, `unsloth.ai/blog`, `ollama.com/blog`, `pola.rs/posts/`, and `rocm.blogs.amd.com` plus a universal fallback using `curl_cffi` native browser TLS impersonation (`chrome`/`safari`/`firefox` profile rotation), UTF-8 decoding, JSON-LD + DOM extraction, WP REST API, XML sitemaps, Jina Reader (`r.jina.ai`), and Wayback Machine CDX (7-day window) — with **zero Google News proxy dependencies**.
   - **Optional SEC EDGAR EFTS (`ENABLE_SEC_EDGAR=false`)**: Full-text search across public filings scoped to AI stack and quantum computing keywords.

2. **Two-Phase Decoupled Queue Runtime (`APScheduler`)**
   - **Fetch phase (`fetch_and_enqueue`)**: Runs every `FETCH_MINUTES` (default 10m), tags candidates in memory via `STACK_DOMAIN_TAXONOMY`, balances sources via `fair_cap_items()` (round-robin prioritizing signal matches within each source), strips tracking URL params, hashes SHA-256 title fingerprints, deduplicates against bounded in-memory caches and SQLite (`processed_urls`, `processed_fingerprints`), and pushes new candidates into `CANDIDATE_QUEUE`.
   - **Flush phase (`maybe_flush` -> `drain_queue` -> `flush_queue`)**: Checked every `CHECK_QUEUE_SECONDS` (default 60s). Flushes when queue depth reaches `QUEUE_FLUSH_LIMIT` (default 32) or after `FORCE_FLUSH_MINUTES` (default 30m) of staleness. Failed OpenRouter batches are automatically requeued up to `MAX_ITEM_RETRIES` (default 5).

3. **Strict OpenRouter LLM Classifier & SQLite WAL Store**
   - Evaluates items in batches (`LLM_BATCH_SIZE=8`, `temperature=0.05`, JSON mode) strictly against the 9 target domains, rejecting off-topic hardware-only cooling/packaging news, consumer hype, or generic earnings.
   - Persists accepted signals (`score >= 7.0`) into `ai_stack_quantum_trends.db` (SQLite WAL mode) with structured fields: `stack_layer`, `bottleneck_addressed`, `specific_tech`, `relevance_score`, `why_it_matters`, `ai_stack_thesis`, `telegram_summary`, and `raw_llm_json`.

4. **Telegram Alerting & Digests**
   - Items scoring `>= ALERT_THRESHOLD` (default `8.5`) trigger immediate HTML alerts (`MAX_ALERTS_PER_FLUSH=8`).
   - Remaining accepted items (`>= 7.0`) are delivered in periodic digests every `DIGEST_MINUTES` (default 360m), chunked cleanly under Telegram's message limit.

---

## Strictly Tracked Topics (9 Domains)

| # | Domain / Stack Layer | Key Frameworks, Libraries & Bottlenecks Tracked |
|---|---|---|
| **1** | **Data Engineering & Preprocessing** | Apache Spark, Ray Data, Polars, DuckDB, MinHash LSH, fastText, PII redaction, GPU data starvation; Hugging Face Tokenizers, tiktoken, SentencePiece, BPE/Unigram, vocabulary fertility & compression. |
| **2** | **Deep Learning Frameworks & Distributed Training** | PyTorch (`torch.compile`, TorchDynamo, TorchInductor), JAX, TensorFlow; DeepSpeed, Megatron-LM, FSDP, Ray Train (TP, PP, ZeRO Stages 1–3, pipeline bubbles); TRL, Unsloth, Axolotl, PEFT (LoRA, QLoRA, SFT, RLHF, DPO, KTO). |
| **3** | **Low-Level GPU Acceleration & Acceleration Kernels** | NVIDIA CUDA, AMD ROCm, Intel oneAPI; cuDNN, cuBLAS, CUTLASS (Hopper/Blackwell GEMM); NCCL, RCCL (AllReduce/AllGather/ReduceScatter over NVLink/InfiniBand/RoCE); FlashAttention-2/3, vLLM PagedAttention, Triton (HBM/SRAM IO-aware fusion). |
| **4** | **Model Optimization & Quantization** | AutoGPTQ, AutoAWQ, bitsandbytes, llama.cpp / GGML / GGUF (INT8/INT4/FP8/FP4/k-quants); TensorRT-LLM, ONNX Runtime, Apache TVM, OpenVINO (graph compilation, constant folding, 2x–4x TTFT speedups). |
| **5** | **Serving & Inference Engines** | vLLM, TGI, TensorRT-LLM, Triton Inference Server (continuous batching, prefix caching, PagedAttention KV-cache); Ollama, llama.cpp, ExLlamaV2, MLC-LLM (Metal/Apple Silicon, Vulkan, AVX-512 local inference). |
| **6** | **Application Orchestration, RAG & Middleware** | LangChain, LangGraph, LlamaIndex, CrewAI (tool calling, agent state machines); Milvus, Qdrant, Chroma, Pinecone, pgvector (RAG recall & TTFT); Outlines, Instructor, NeMo Guardrails, Guidance (grammar-constrained decoding, logit masking, prompt-injection defense). |
| **7** | **API Gateway & Model Routing** | LiteLLM, Portkey, OpenResty / Envoy, Kong (failover cascading, rate-limiting, cost tracking); FastAPI, gRPC, Uvicorn (async dispatch, SSE streaming transport). |
| **8** | **End-User Presentation & Interface (UX)** | Open WebUI, LibreChat, Next.js Chat Interfaces, Gradio, Streamlit (token-by-token SSE streaming, Markdown/LaTeX rendering, optimistic UI updates, timeout/context-limit error handling). |
| **9** | **Quantum Computing** | Superconducting, trapped-ion, neutral-atom, photonic, silicon-spin & topological QPUs; fault-tolerant logical qubits, QEC (surface codes, qLDPC), cryo-CMOS control; Qiskit, Cirq, PennyLane, CUDA-Q, Braket, VQE/QAOA. |

---

## Quick Start (Docker Compose)

```bash
git clone https://github.com/ajsfgu9/ai-software-stack-quantum-bot.git
cd ai-software-stack-quantum-bot
cp .env.example .env
# Edit .env and set OPENROUTER_API_KEY, TELEGRAM_BOT_TOKEN, and TELEGRAM_CHAT_ID
docker compose up -d --build
docker compose logs -f
```

The container runs as non-root `botuser` (UID `10001`) with a read-only root filesystem, `cap_drop: [ALL]`, `no-new-privileges:true`, a 512M memory cap, zero exposed ports, and a live `HEALTHCHECK` monitoring `/app/data/heartbeat.txt`.
