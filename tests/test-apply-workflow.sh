#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

TEST_HOME="$TMP_DIR/home"
TEST_BIN="$TMP_DIR/bin"
TEST_WORKSPACES="$TMP_DIR/openclaw-agents"

mkdir -p "$TEST_HOME/.openclaw/agents" "$TEST_BIN" "$TEST_WORKSPACES"

cat > "$TEST_BIN/openclaw" <<'EOF'
#!/bin/bash
if [ "${1:-}" = "--version" ]; then
  echo "openclaw-test"
  exit 0
fi
echo "openclaw stub: $*" >&2
exit 0
EOF
chmod +x "$TEST_BIN/openclaw"

export HOME="$TEST_HOME"
export OPENCLAW_AGENTS_DIR="$TEST_WORKSPACES"
export PATH="$TEST_BIN:$PATH"

bash "$REPO_DIR/scripts/apply.sh" --skip-verify

assert_file() {
  local path="$1"
  if [ ! -f "$path" ]; then
    echo "Expected file missing: $path" >&2
    exit 1
  fi
}

assert_dir() {
  local path="$1"
  if [ ! -d "$path" ]; then
    echo "Expected directory missing: $path" >&2
    exit 1
  fi
}

assert_file "$HOME/.openclaw/agents/main/agent/AGENTS.md"
assert_file "$HOME/.openclaw/agents/producer/agent/skills/brainstorming/SKILL.md"
assert_file "$OPENCLAW_AGENTS_DIR/heisenberg/openclaw.json.example"
assert_file "$OPENCLAW_AGENTS_DIR/heisenberg/AGENTS.md"
assert_dir "$OPENCLAW_AGENTS_DIR/heisenberg/memory/core"

echo "apply workflow test passed"
