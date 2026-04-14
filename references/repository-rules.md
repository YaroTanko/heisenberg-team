# Repository Rules

## Canonical Apply Rule

After every feature change, re-run:

```bash
bash scripts/apply.sh
```

This repository treats `Apply` as a fresh installation of the current repo state into the live OpenClaw runtime and agent workspaces.

`Apply` updates:
- `~/.openclaw/agents/<openclaw-agent>/agent/`
- `~/.openclaw/agents/producer/agent/skills/`
- `~/openclaw-agents/<character>/`

## Source of Truth

Edit files in this repository, not the installed runtime copies.

Do not treat files under `~/.openclaw/agents/...` or `~/openclaw-agents/...` as the primary source. Those directories are deployment targets refreshed by `Apply`.

## Stateful Files

`Apply` refreshes repo-owned files, but it does not overwrite an existing workspace `references/team-board.md`. The board is runtime state, not source.

## Initial Setup vs Re-Apply

- First-time setup: `bash scripts/setup-wizard.sh`
- Non-interactive install: `bash scripts/apply.sh`
- After any feature/change to agents, skills, scripts, configs, or docs that affect installation: `bash scripts/apply.sh`

## Verification

`scripts/apply.sh` runs post-apply verification by default. Use `--skip-verify` only for controlled automation or tests.
