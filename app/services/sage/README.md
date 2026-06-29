# Sage — the holistic wellness assistant

Sage is the in-app AI companion for the Holistic Chart. It answers members'
questions about nutrition, gut health, fitness, sleep, stress, hydration, habits,
and how their own chart is trending — grounded in their live data.

It is adapted from the modular assistant engine in the companion `Aman_app`
project, re-tailored end-to-end for whole-self wellness and hardened for a health
product (no diagnosis, crisis escalation, and a privacy-first provider chain).

## How it answers: an adaptive provider chain

`Sage::Engine` tries a chain of providers in order and returns the first usable
reply. The chain **always ends in the built-in `grounded` engine**, so a reply is
guaranteed and the call never raises.

| Provider | When it runs | Where data goes |
|---|---|---|
| `local_llm` | `LOCAL_LLM_URL` / `OLLAMA_URL` set | your own server (Ollama, llama.cpp, vLLM…) |
| `groq` | `GROQ_API_KEY` set (opt-in) | Groq (hosted) — minimal derived metrics only |
| `grounded` | always | **in-process — nothing leaves the server** |

**The default is grounded-only.** With no env configured, every word of the
conversation and all chart context stay on your infrastructure. `Sage::Config
.fully_local?` reports whether the active chain is PHI-safe (grounded and/or a
self-hosted local model only).

## The grounded engine

`SageAiService` answers from two things, both local:

1. **Live chart context** — derived metrics for the *current* member (wellness
   score, latest vitals, today's calories vs. target, weekly active minutes,
   streak, BMI, goal). Built in `Api::AiController#build_context`, which
   deliberately excludes direct identifiers (email, member ID, DOB, last name).
2. **A vetted wellness knowledge base** (`Sage::Knowledge`) searched semantically
   by `Sage::Retriever` — accurate guidance for real questions, zero model
   download.

Two parts can be upgraded to **real, local transformer models** (in-process via
the `informers` gem / ONNX Runtime — no Python, no API calls, no keys):

| Capability | Model | Replaces | Files |
|---|---|---|---|
| Semantic retrieval | `sentence-transformers/all-MiniLM-L6-v2` (~80MB) | feature-hashing retriever | `embeddings.rb`, `semantic_retriever.rb` |
| Intent detection | `Xenova/distilbert-base-uncased-mnli` zero-shot (~70MB int8) | regex intents | `intent_classifier.rb` |

Weights download once from Hugging Face on first use and are cached on disk.

## Always-on graceful fallback

Both models are **optional at runtime**. If the `informers` gem isn't bundled,
the weights can't be fetched, the dyno is too small, or the feature is switched
off, the code transparently falls back to the hashing retriever (`retriever.rb`)
and the regex classifier (`classify_by_rules`). Sage never stops answering, and
**urgent/crisis messages ("chest pain", "harm myself", …) are always caught by
deterministic rules *before* any model runs** and routed to 911 / 988.

## Not medical advice

Sage is a wellness companion, not a clinician. It never diagnoses or prescribes,
appends a not-medical-advice note to substantive health guidance, and nudges
members to their care team for anything concerning. See `SYSTEM_PROMPT` in
`AiAssistantService` and `DISCLAIMER` in `Sage::Knowledge`.

## Configuration (env vars)

| Var | Default | Effect |
|---|---|---|
| `SAGE_PROVIDERS` | auto | Explicit chain, e.g. `local_llm,groq,grounded`. |
| `LOCAL_LLM_URL` / `OLLAMA_URL` | — | Point Sage at your own OpenAI-compatible server. |
| `LOCAL_LLM_MODEL` | `llama3.2` | Model name for the local server. |
| `GROQ_API_KEY` | — | Opt in to the hosted Groq fallback. |
| `SAGE_NEURAL` | on | Master switch. `off`/`0`/`false`/`no` disables **all** on-device models. |
| `SAGE_NEURAL_INTENT` | on | Disable just the DistilBERT intent classifier (keep embeddings). |
| `SAGE_EMBED_MODEL` | all-MiniLM-L6-v2 | Override the embedding model id. |
| `SAGE_INTENT_MODEL` | distilbert-…-mnli | Override the zero-shot model id. |
| `SAGE_INTENT_THRESHOLD` | `0.55` | Min entailment confidence before trusting a predicted intent. |
| `SAGE_TIMEOUT` | `20` | Request timeout (s) for a networked provider. |
| `SAGE_WARMUP` | off | Load the models in a background thread at boot. |

## Memory & the free tier

Each model needs roughly its file size again at runtime. One model (embeddings)
fits a 512MB dyno; running both comfortably wants ≥1GB RAM. On a constrained host
leave `SAGE_NEURAL_INTENT=off` (or `SAGE_NEURAL=false`) and Sage runs on the
dependency-free retriever + rules. Tests set `SAGE_NEURAL=off` so no model is ever
downloaded during CI.
