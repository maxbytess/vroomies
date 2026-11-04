#!/usr/bin/env bash
# usage: ai.sh <request.json> [ollama-host]
req="$1"
host="${2:-http://localhost:11434}"
curl -sS --max-time 300 "$host/api/chat" \
  -H "content-type: application/json" \
  -d @"$req" || echo '{"error":"Could not reach Ollama. Is it running? (ollama serve)"}'
rm -f "$req"
