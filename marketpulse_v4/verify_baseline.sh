#!/usr/bin/env bash
# MarketPulse V4 — Baseline Verification
# Run after setup_vps.sh to confirm Vibe-Trading is healthy and reachable.
set -euo pipefail

INSTALL_DIR="${HOME}/vibe-trading"
API_URL="http://127.0.0.1:8899"
PASS=0
FAIL=0

ok()   { echo "  [PASS] $1"; ((PASS++)); }
fail() { echo "  [FAIL] $1"; ((FAIL++)); }
sep()  { echo "──────────────────────────────────────────────"; }

echo ""
echo "MarketPulse V4 — Baseline Verification"
sep

# 1. Repo present
echo "1. Vibe-Trading repo"
if [[ -d "${INSTALL_DIR}/.git" ]]; then
  COMMIT=$(git -C "${INSTALL_DIR}" rev-parse --short HEAD)
  ok "Repo present at ${INSTALL_DIR} (commit: ${COMMIT})"
else
  fail "Repo not found at ${INSTALL_DIR} — run setup_vps.sh first"
fi

# 2. .env exists and has OLLAMA_BASE_URL set
echo "2. .env configuration"
ENV_FILE="${INSTALL_DIR}/agent/.env"
if [[ -f "$ENV_FILE" ]]; then
  if grep -q "<OLLAMA_TAILSCALE_IP>" "$ENV_FILE"; then
    fail ".env still has placeholder <OLLAMA_TAILSCALE_IP> — edit it or re-run setup_vps.sh --ollama-host <IP>"
  elif grep -q "^OLLAMA_BASE_URL=" "$ENV_FILE"; then
    OLLAMA_URL=$(grep "^OLLAMA_BASE_URL=" "$ENV_FILE" | cut -d= -f2-)
    ok "OLLAMA_BASE_URL = ${OLLAMA_URL}"
  else
    fail "OLLAMA_BASE_URL not set in .env"
  fi
else
  fail ".env not found at ${ENV_FILE}"
fi

# 3. Docker container running
echo "3. Docker container status"
if docker ps --format '{{.Names}}' | grep -q "vibe-trading"; then
  STATUS=$(docker ps --filter "name=vibe-trading" --format '{{.Status}}')
  ok "Container running: ${STATUS}"
else
  fail "vibe-trading container is not running"
  echo "     Hint: docker compose -f ${INSTALL_DIR}/docker-compose.yml up -d vibe-trading"
fi

# 4. API health endpoint
echo "4. API health check"
HTTP_CODE=$(curl -so /dev/null -w "%{http_code}" "${API_URL}/health" 2>/dev/null || echo "000")
if [[ "$HTTP_CODE" == "200" ]]; then
  ok "GET /health → 200 OK"
else
  fail "GET /health → ${HTTP_CODE} (expected 200)"
fi

# 5. Ollama reachability from VPS
echo "5. Ollama reachability"
if [[ -f "$ENV_FILE" ]] && ! grep -q "<OLLAMA_TAILSCALE_IP>" "$ENV_FILE"; then
  OLLAMA_BASE=$(grep "^OLLAMA_BASE_URL=" "$ENV_FILE" | cut -d= -f2-)
  HTTP_OLLAMA=$(curl -so /dev/null -w "%{http_code}" "${OLLAMA_BASE}/api/tags" \
                --connect-timeout 5 2>/dev/null || echo "000")
  if [[ "$HTTP_OLLAMA" == "200" ]]; then
    ok "Ollama API reachable at ${OLLAMA_BASE}"
  else
    fail "Ollama API not reachable at ${OLLAMA_BASE} (HTTP ${HTTP_OLLAMA}) — check Tailscale and that Ollama is running on the Windows host"
  fi
else
  echo "  [SKIP] Ollama check skipped (placeholder IP still in .env)"
fi

# 6. Quick smoke-test: agent run via API
echo "6. Agent smoke test"
if [[ "$HTTP_CODE" == "200" ]]; then
  AUTH_KEY=$(grep "^API_AUTH_KEY=" "$ENV_FILE" 2>/dev/null | cut -d= -f2- || echo "")
  AUTH_HEADER=""
  [[ -n "$AUTH_KEY" && "$AUTH_KEY" != "CHANGE_ME_BEFORE_DEPLOY" ]] && AUTH_HEADER="-H \"Authorization: Bearer ${AUTH_KEY}\""
  SMOKE=$(curl -sf -X POST "${API_URL}/api/chat" \
    -H "Content-Type: application/json" \
    ${AUTH_HEADER} \
    -d '{"message":"What is the current price of AAPL?","stream":false}' \
    --connect-timeout 10 --max-time 60 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('content','')[:80])" 2>/dev/null || echo "")
  if [[ -n "$SMOKE" ]]; then
    ok "Agent responded: ${SMOKE}..."
  else
    fail "Agent did not return a response — check container logs: docker logs \$(docker ps -qf name=vibe-trading)"
  fi
else
  echo "  [SKIP] Smoke test skipped (API not up)"
fi

sep
echo ""
if [[ $FAIL -eq 0 ]]; then
  echo "  ALL ${PASS} CHECKS PASSED — baseline is healthy."
  echo "  You can now proceed to Phase 2 (GPU Bridge via Tailscale)."
else
  echo "  ${PASS} passed, ${FAIL} failed."
  echo "  Fix the failures above before proceeding to the next phase."
fi
echo ""
