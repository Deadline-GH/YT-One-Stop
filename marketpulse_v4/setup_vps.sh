#!/usr/bin/env bash
# MarketPulse V4 — Phase 1: Vibe-Trading Baseline Setup
# Run this once on world-01 (Ubuntu VPS) as a non-root user with Docker access.
# Usage: bash setup_vps.sh [--ollama-host <tailscale-ip>] [--model <model-name>]
set -euo pipefail

REPO_URL="https://github.com/HKUDS/Vibe-Trading.git"
INSTALL_DIR="${HOME}/vibe-trading"
OLLAMA_HOST="${OLLAMA_HOST:-}"   # override via --ollama-host or env var
MODEL_NAME="${MODEL_NAME:-llama3.2}"

# ── Parse args ──────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case $1 in
    --ollama-host) OLLAMA_HOST="$2"; shift 2 ;;
    --model)       MODEL_NAME="$2";  shift 2 ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done

# ── Preflight checks ─────────────────────────────────────────────────────────
echo "==> Checking prerequisites..."
command -v git    >/dev/null 2>&1 || { echo "ERROR: git not found"; exit 1; }
command -v docker >/dev/null 2>&1 || { echo "ERROR: docker not found"; exit 1; }
docker compose version >/dev/null 2>&1 || { echo "ERROR: docker compose (v2) not found"; exit 1; }

if [[ -z "$OLLAMA_HOST" ]]; then
  echo ""
  echo "WARN: --ollama-host not provided."
  echo "      The .env will use placeholder <OLLAMA_TAILSCALE_IP>."
  echo "      Edit marketpulse_v4/env.template or set OLLAMA_HOST= before re-running."
  echo ""
fi

# ── Clone Vibe-Trading ───────────────────────────────────────────────────────
echo "==> Cloning Vibe-Trading into ${INSTALL_DIR}..."
if [[ -d "${INSTALL_DIR}/.git" ]]; then
  echo "    Repo already present — pulling latest..."
  git -C "${INSTALL_DIR}" pull --ff-only
else
  git clone "${REPO_URL}" "${INSTALL_DIR}"
fi

# ── Inject .env ──────────────────────────────────────────────────────────────
echo "==> Writing agent/.env ..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_TEMPLATE="${SCRIPT_DIR}/env.template"
ENV_DEST="${INSTALL_DIR}/agent/.env"

if [[ ! -f "$ENV_TEMPLATE" ]]; then
  echo "ERROR: env.template not found at ${ENV_TEMPLATE}"
  exit 1
fi

cp "$ENV_TEMPLATE" "$ENV_DEST"

# Substitute OLLAMA_HOST if provided
if [[ -n "$OLLAMA_HOST" ]]; then
  sed -i "s|<OLLAMA_TAILSCALE_IP>|${OLLAMA_HOST}|g" "$ENV_DEST"
fi
sed -i "s|<MODEL_NAME>|${MODEL_NAME}|g" "$ENV_DEST"

echo "    Written to ${ENV_DEST}"

# ── Copy docker-compose override ─────────────────────────────────────────────
echo "==> Copying docker-compose.override.yml ..."
cp "${SCRIPT_DIR}/docker-compose.override.yml" "${INSTALL_DIR}/docker-compose.override.yml"

# ── Build & start ─────────────────────────────────────────────────────────────
echo "==> Building Docker image (this takes a few minutes on first run)..."
docker compose -f "${INSTALL_DIR}/docker-compose.yml" \
               -f "${INSTALL_DIR}/docker-compose.override.yml" \
               build

echo "==> Starting vibe-trading service..."
docker compose -f "${INSTALL_DIR}/docker-compose.yml" \
               -f "${INSTALL_DIR}/docker-compose.override.yml" \
               up -d vibe-trading

# ── Health check ──────────────────────────────────────────────────────────────
echo "==> Waiting for API to become healthy (up to 60s)..."
for i in $(seq 1 12); do
  if curl -sf http://127.0.0.1:8899/health >/dev/null 2>&1; then
    echo "    ✓ API is up!"
    break
  fi
  if [[ $i -eq 12 ]]; then
    echo "ERROR: API did not come up within 60s. Check logs:"
    echo "  docker compose -f ${INSTALL_DIR}/docker-compose.yml logs vibe-trading"
    exit 1
  fi
  echo "    ... waiting (${i}/12)"
  sleep 5
done

echo ""
echo "════════════════════════════════════════════════════════════"
echo " Vibe-Trading baseline is RUNNING on http://127.0.0.1:8899 "
echo " Run verify_baseline.sh to confirm all checks pass.        "
echo "════════════════════════════════════════════════════════════"
