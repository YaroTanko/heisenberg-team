#!/bin/bash
# setup.sh - Compatibility wrapper around the canonical apply workflow
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "⚠️  setup.sh is now a compatibility wrapper."
echo "   Canonical command: bash scripts/apply.sh"

bash "$SCRIPT_DIR/apply.sh" "$@"
