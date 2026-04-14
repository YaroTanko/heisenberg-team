#!/bin/bash
# apply.sh — Canonical re-install/apply entrypoint for repo changes
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
OPENCLAW_DIR="$HOME/.openclaw/agents"
BASE_DIR="${OPENCLAW_AGENTS_DIR:-$HOME/openclaw-agents}"

VERIFY=true
CHECK_PREREQS=true
RUNTIME_ONLY=false
WORKSPACES_ONLY=false
INSTALL_HOOKS=false

AGENTS=("heisenberg" "saul" "walter" "jesse" "skyler" "hank" "gus" "twins")
SHARED_SCRIPTS=("self-heal.sh" "trash-agent-session.sh" "agent-health-check.sh")

usage() {
  cat <<'EOF'
Usage: bash scripts/apply.sh [options]

Re-installs the current repository state into OpenClaw runtime and workspaces.

Options:
  --skip-verify        Skip post-apply verification
  --skip-prereq-check  Skip openclaw/node prerequisite checks
  --runtime-only       Apply only ~/.openclaw/agents runtime files
  --workspaces-only    Apply only ~/openclaw-agents workspaces
  --install-hooks      Install git hooks (auto-apply after git pull)
  --help, -h           Show this help
EOF
}

log_section() {
  echo ""
  echo "$1"
}

require_cmd() {
  local cmd="$1"
  local hint="$2"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "❌ $cmd not found. $hint" >&2
    exit 1
  fi
}

openclaw_name_for() {
  case "$1" in
    heisenberg) echo "main" ;;
    saul) echo "producer" ;;
    walter) echo "teamlead" ;;
    jesse) echo "marketing-funnel" ;;
    skyler) echo "skyler" ;;
    hank) echo "hank" ;;
    gus) echo "kaizen" ;;
    twins) echo "researcher" ;;
    *)
      echo "Unknown agent: $1" >&2
      exit 1
      ;;
  esac
}

sync_markdown_dir() {
  local src="$1"
  local dest="$2"
  local files=()

  mkdir -p "$dest"
  find "$dest" -maxdepth 1 -type f -name '*.md' -delete

  shopt -s nullglob
  files=("$src"/*.md)
  if [ "${#files[@]}" -gt 0 ]; then
    cp "${files[@]}" "$dest/"
  fi
  shopt -u nullglob
}

sync_skill_dirs() {
  local src_root="$1"
  local dest_root="$2"
  local src_dir
  local existing
  local name

  mkdir -p "$dest_root"

  shopt -s nullglob
  for existing in "$dest_root"/*; do
    [ -e "$existing" ] || continue
    name="$(basename "$existing")"
    if [ ! -d "$src_root/$name" ]; then
      rm -rf "$existing"
    fi
  done

  for src_dir in "$src_root"/*; do
    [ -d "$src_dir" ] || continue
    name="$(basename "$src_dir")"
    rm -rf "$dest_root/$name"
    cp -R "$src_dir" "$dest_root/$name"
  done
  shopt -u nullglob
}

copy_if_present() {
  local src="$1"
  local dest="$2"
  if [ -f "$src" ]; then
    cp "$src" "$dest"
  fi
}

apply_runtime() {
  local char_name
  local agent_name
  local src
  local dest

  log_section "📦 Applying runtime files to $OPENCLAW_DIR"
  for char_name in "${AGENTS[@]}"; do
    agent_name="$(openclaw_name_for "$char_name")"
    src="$REPO_DIR/agents/$char_name"
    dest="$OPENCLAW_DIR/$agent_name/agent"

    if [ ! -d "$src" ]; then
      echo "  ⚠ Missing source agent directory: $src"
      continue
    fi

    sync_markdown_dir "$src" "$dest"
    echo "  ✓ $char_name → $agent_name"
  done

  sync_skill_dirs "$REPO_DIR/skills" "$OPENCLAW_DIR/producer/agent/skills"
  echo "  ✓ skills → producer"
}

apply_workspaces() {
  local agent
  local agent_dir
  local src
  local script
  local config_example

  log_section "🗂 Applying workspace files to $BASE_DIR"
  for agent in "${AGENTS[@]}"; do
    src="$REPO_DIR/agents/$agent"
    agent_dir="$BASE_DIR/$agent"
    mkdir -p "$agent_dir/memory/core" \
      "$agent_dir/memory/decisions" \
      "$agent_dir/memory/archive" \
      "$agent_dir/references" \
      "$agent_dir/scripts"

    if [ -d "$src" ]; then
      sync_markdown_dir "$src" "$agent_dir"
      echo "  ✓ workspace files: $agent"
    else
      echo "  ⚠ Missing source workspace files for $agent"
    fi

    copy_if_present "$REPO_DIR/references/team-constitution.md" "$agent_dir/references/team-constitution.md"
    if [ ! -f "$agent_dir/references/team-board.md" ]; then
      if [ -f "$REPO_DIR/references/team-board.md.example" ]; then
        cp "$REPO_DIR/references/team-board.md.example" "$agent_dir/references/team-board.md"
      elif [ -f "$REPO_DIR/references/team-board.md" ]; then
        cp "$REPO_DIR/references/team-board.md" "$agent_dir/references/team-board.md"
      fi
    fi

    for script in "${SHARED_SCRIPTS[@]}"; do
      if [ -f "$REPO_DIR/scripts/$script" ]; then
        cp "$REPO_DIR/scripts/$script" "$agent_dir/scripts/$script"
        chmod +x "$agent_dir/scripts/$script"
      fi
    done

    config_example="$REPO_DIR/configs/$agent.openclaw.json.example"
    if [ -f "$config_example" ]; then
      cp "$config_example" "$agent_dir/openclaw.json.example"
    fi
  done
}

verify_apply() {
  log_section "🔍 Verifying apply result"

  if [ "$WORKSPACES_ONLY" = false ]; then
    test -f "$OPENCLAW_DIR/main/agent/AGENTS.md"
    test -f "$OPENCLAW_DIR/producer/agent/skills/brainstorming/SKILL.md"
  fi

  if [ "$RUNTIME_ONLY" = false ]; then
    test -f "$BASE_DIR/heisenberg/AGENTS.md"
    test -f "$BASE_DIR/heisenberg/openclaw.json.example"
    test -d "$BASE_DIR/heisenberg/memory/core"
  fi

  bash "$SCRIPT_DIR/smoke-test.sh"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --skip-verify)
      VERIFY=false
      ;;
    --skip-prereq-check)
      CHECK_PREREQS=false
      ;;
    --runtime-only)
      RUNTIME_ONLY=true
      ;;
    --workspaces-only)
      WORKSPACES_ONLY=true
      ;;
    --install-hooks)
      INSTALL_HOOKS=true
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
  shift
done

if [ "$RUNTIME_ONLY" = true ] && [ "$WORKSPACES_ONLY" = true ]; then
  echo "❌ --runtime-only and --workspaces-only are mutually exclusive." >&2
  exit 1
fi

if [ "$CHECK_PREREQS" = true ]; then
  require_cmd openclaw "Install it with: npm install -g openclaw"
  require_cmd node "Install Node.js 20+"
fi

echo "🧪 Heisenberg Team Apply"
echo "========================"
echo "Repo:           $REPO_DIR"
echo "OpenClaw dir:   $OPENCLAW_DIR"
echo "Workspace dir:  $BASE_DIR"
echo "Verify:         $VERIFY"

if [ "$WORKSPACES_ONLY" = false ]; then
  apply_runtime
fi

if [ "$RUNTIME_ONLY" = false ]; then
  apply_workspaces
fi

if [ "$VERIFY" = true ]; then
  verify_apply
fi

if [ "$INSTALL_HOOKS" = true ]; then
  log_section "🪝 Installing git hooks"
  HOOKS_SRC="$REPO_DIR/scripts/hooks"
  HOOKS_DST="$REPO_DIR/.git/hooks"
  if [ -f "$HOOKS_SRC/post-merge" ]; then
    ln -sf "$HOOKS_SRC/post-merge" "$HOOKS_DST/post-merge"
    echo "  ✓ post-merge → auto-apply after git pull"
  else
    echo "  ⚠ scripts/hooks/post-merge not found" >&2
  fi
fi

log_section "✅ Apply finished"
echo "Use this command after every feature change:"
echo "  bash scripts/apply.sh"
