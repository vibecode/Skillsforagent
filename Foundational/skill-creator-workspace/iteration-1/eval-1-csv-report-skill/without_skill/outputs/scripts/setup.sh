#!/usr/bin/env bash
# Setup script for csv-report skill — idempotent
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Installing Python dependencies for csv-report skill..."
pip3 install --quiet -r "$SCRIPT_DIR/requirements.txt"
echo "csv-report skill setup complete."
