#!/usr/bin/env bash
# Install Jarvis Codex rules into ~/.codex/rules
# Usage: scripts/codex-install-rules.sh [--force]

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
RULES_SOURCE="$ROOT_DIR/templates/codex/jarvis.rules"
CODEX_RULES_DIR="$HOME/.codex/rules"
FORCE=0

usage() {
  cat <<'USAGE'
Usage: scripts/codex-install-rules.sh [options]

Options:
  --force   Overwrite existing ~/.codex/rules/jarvis.rules
  -h, --help  Show this help
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force)
      FORCE=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
 done

if [[ ! -f "$RULES_SOURCE" ]]; then
  echo "Rules template not found: $RULES_SOURCE" >&2
  exit 1
fi

mkdir -p "$CODEX_RULES_DIR"
TARGET="$CODEX_RULES_DIR/jarvis.rules"

if [[ -f "$TARGET" && $FORCE -ne 1 ]]; then
  echo "Rules already exist at $TARGET. Use --force to overwrite."
  exit 0
fi

cp "$RULES_SOURCE" "$TARGET"

echo "Installed Codex rules to $TARGET"
