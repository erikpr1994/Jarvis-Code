#!/usr/bin/env bash
# Sync Jarvis skills into Codex skill locations.
# Usage: scripts/codex-sync.sh [--scope repo|user] [--mode symlink|copy] [--force]

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
SOURCE_DIR="$ROOT_DIR/global/skills"
DEFAULT_CODEX_HOME="$HOME/.codex"

SCOPE="repo"
MODE="copy"
FORCE=0

usage() {
  cat <<'USAGE'
Usage: scripts/codex-sync.sh [options]

Options:
  --scope repo|user   Target repo-scoped (.codex) or user-scoped (~/.codex) skills (default: repo)
  --mode symlink|copy Create symlinks or copy skill folders (default: copy)
  --force             Overwrite existing targets
  -h, --help          Show this help
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --scope)
      SCOPE="$2"
      shift 2
      ;;
    --mode)
      MODE="$2"
      shift 2
      ;;
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

if [[ "$SCOPE" != "repo" && "$SCOPE" != "user" ]]; then
  echo "Invalid --scope: $SCOPE" >&2
  exit 1
fi

if [[ "$MODE" != "symlink" && "$MODE" != "copy" ]]; then
  echo "Invalid --mode: $MODE" >&2
  exit 1
fi

if [[ ! -d "$SOURCE_DIR" ]]; then
  echo "Source skills directory not found: $SOURCE_DIR" >&2
  exit 1
fi

if [[ "$SCOPE" == "repo" ]]; then
  TARGET_ROOT="$ROOT_DIR/.codex/skills"
else
  TARGET_ROOT="$DEFAULT_CODEX_HOME/skills"
fi

mkdir -p "$TARGET_ROOT"

if [[ "$MODE" == "symlink" ]]; then
  echo "Warning: Codex ignores symlinked directories. Use --mode copy unless you have a specific reason."
fi

SKILL_DIRS=()
while IFS= read -r dir; do
  [[ -z "$dir" ]] && continue
  SKILL_DIRS+=("$dir")
done < <(find "$SOURCE_DIR" -mindepth 2 -maxdepth 2 -type f -name SKILL.md -print0 | xargs -0 -n1 dirname | sort -u)

if [[ ${#SKILL_DIRS[@]} -eq 0 ]]; then
  echo "No skills found under $SOURCE_DIR" >&2
  exit 1
fi

created=0
updated=0
skipped=0

for src in "${SKILL_DIRS[@]}"; do
  name=$(basename "$src")
  dest="$TARGET_ROOT/$name"

  if [[ -e "$dest" || -L "$dest" ]]; then
    if [[ $FORCE -eq 1 ]]; then
      rm -rf "$dest"
    else
      skipped=$((skipped + 1))
      continue
    fi
  fi

  if [[ "$MODE" == "symlink" ]]; then
    ln -s "$src" "$dest"
  else
    cp -R "$src" "$dest"
  fi

  if [[ $FORCE -eq 1 ]]; then
    updated=$((updated + 1))
  else
    created=$((created + 1))
  fi
 done

cat <<EOF_SUMMARY
Codex skill sync complete
- Source: $SOURCE_DIR
- Target: $TARGET_ROOT
- Mode:   $MODE
- Created: $created
- Updated: $updated
- Skipped: $skipped
EOF_SUMMARY
