# MarketPulse V4 — Project Context

## What this repo is
MarketPulse V4 is an AI-first trading workstation. It uses **HKUDS/Vibe-Trading** as the intelligence engine (agent swarm, sentiment analysis) and will layer **MarketPulse Extras** (safety gates, Moomoo execution, data pipelines) on top once the baseline is stable.

## Infrastructure
| Host | Role |
|---|---|
| Windows 11 (local) | Electron UI shell, Moomoo OpenD, Ollama GPU (20 GB VRAM) |
| Ubuntu VPS (world-01) | Vibe-Trading (Docker), Python Webhook, Rolling Windows |
| Tailscale | Private mesh network between all components |

## Repository layout
```
marketpulse_v4/
  setup_vps.sh               # Phase 1 — clone + configure Vibe-Trading on world-01
  env.template               # .env pre-configured for Ollama via Tailscale
  docker-compose.override.yml # Loopback-only port binding + log rotation
  verify_baseline.sh         # Smoke-test all Phase 1 checks
```

## Phase 1 — Vibe-Trading Baseline (current)
Run on **world-01** as a non-root user with Docker access:

```bash
# Minimal — uses placeholder IP, edit env manually afterward
bash marketpulse_v4/setup_vps.sh

# Full — substitutes Ollama host and model automatically
bash marketpulse_v4/setup_vps.sh --ollama-host 100.x.x.x --model llama3.2

# After setup, confirm everything is healthy
bash marketpulse_v4/verify_baseline.sh
```

**What setup_vps.sh does:**
1. Clones `HKUDS/Vibe-Trading` → `~/vibe-trading`
2. Writes `agent/.env` from `env.template` (substituting Ollama host/model)
3. Copies the docker-compose override
4. Builds the Docker image and starts the `vibe-trading` service
5. Polls `/health` until the API is up (60 s timeout)

## Phases 2-5 (not yet implemented)
- **Phase 2:** Connect VPS → local Ollama GPU via Tailscale
- **Phase 3:** Port `moomooDataClient` + `IndicatorEngine` from MP-V3
- **Phase 4:** Electron "Command Shell" with Autonomous Mode toggle
- **Phase 5:** Python Webhook with 10 s latency gate + rotating logs

## Key design rules
- No MarketPulse Extras code until `verify_baseline.sh` shows all checks passing.
- The broker is only ever called through `TransactionManager` (single point of control).
- API port 8899 is loopback-only on the VPS; Tailscale is the only external path in.
- `API_AUTH_KEY` must be set to a real secret before any non-loopback caller is allowed.
