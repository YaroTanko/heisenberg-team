# Durable Memory Protocol

> How the team stores long-lived knowledge without polluting raw chat history.

## 1. Memory layers

### Raw layer
- `sessions` / transcripts
- useful for recent context and recovery
- not the main source of truth

### Working layer
- `memory/YYYY-MM-DD*.md`
- handoff, daily notes, intermediate conclusions

### Durable layer
- `memory/core/` for stable facts and preferences
- `memory/decisions/` for rules and architectural decisions
- `memory/projects/` for project knowledge worth keeping

## 2. What belongs in durable memory

Promote:
- stable user facts
- confirmed preferences
- system changes that matter for more than 30 days
- important project decisions
- repeated lessons and patterns

Do not promote:
- tool traces
- temporary TODOs
- one-off debug noise
- unverified guesses
- secrets, tokens, passwords

## 3. Suggested files

- `memory/core/facts_user.md`
- `memory/core/preferences_user.md`
- `memory/core/changes_system.md`
- `memory/decisions/*.md`

## 4. Writing style

- short title
- precise summary
- 1-3 lines of details if needed
- source and date
- no transcript dumps

## 5. Team rule

If an agent confirms a fact, preference, or long-lived change that will likely matter again, it should not wait for a reminder. It should record it in durable memory as part of finishing the task.
