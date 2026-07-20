#!/usr/bin/env bash
# Fetch and cache the free-exercise-db dataset (Unlicense / public domain).
# https://github.com/yuhonas/free-exercise-db — 800+ exercises with equipment,
# level, muscles, and step-by-step instructions. Idempotent: refreshes only if
# the cache is missing or older than 30 days.
set -euo pipefail

CACHE_DIR="${HOME}/.cache/free-exercise-db"
CACHE_FILE="${CACHE_DIR}/exercises.json"
URL="https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/dist/exercises.json"
MAX_AGE_DAYS=30

mkdir -p "$CACHE_DIR"

if [ -f "$CACHE_FILE" ]; then
  if [ -z "$(find "$CACHE_FILE" -mtime +"$MAX_AGE_DAYS" 2>/dev/null)" ]; then
    count=$(jq 'length' "$CACHE_FILE" 2>/dev/null || echo 0)
    if [ "$count" -gt 100 ]; then
      echo "cached: $CACHE_FILE ($count exercises)"
      exit 0
    fi
  fi
fi

tmp=$(mktemp)
curl -fsSL --max-time 60 "$URL" -o "$tmp"
count=$(jq 'length' "$tmp")
if [ "$count" -lt 100 ]; then
  echo "error: fetched dataset looks truncated ($count entries)" >&2
  rm -f "$tmp"
  exit 1
fi
mv "$tmp" "$CACHE_FILE"
echo "fetched: $CACHE_FILE ($count exercises)"
