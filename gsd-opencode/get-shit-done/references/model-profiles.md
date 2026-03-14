# Model Profiles

Model profiles control which OpenCode model each GSD agent uses. This allows balancing quality vs token spend.

## Profile Definitions

| Agent | `quality` | `balanced` | `budget` |
|-------|-----------|------------|----------|
| gsd-planner | openai/gpt-5.4 | openai/gpt-5.3-codex-spark | openai/gpt-5.3-codex-spark |
| gsd-roadmapper | openai/gpt-5.4 | openai/gpt-5.3-codex-spark | openai/gpt-5.3-codex-spark |
| gsd-executor | openai/gpt-5.4 | openai/gpt-5.3-codex-spark | openai/gpt-5.3-codex-spark |
| gsd-phase-researcher | openai/gpt-5.4 | openai/gpt-5.3-codex-spark | openai/gpt-5.3-codex-spark |
| gsd-project-researcher | openai/gpt-5.4 | openai/gpt-5.3-codex-spark | openai/gpt-5.3-codex-spark |
| gsd-research-synthesizer | openai/gpt-5.4 | openai/gpt-5.3-codex-spark | openai/gpt-5.3-codex-spark |
| gsd-debugger | openai/gpt-5.4 | openai/gpt-5.3-codex-spark | openai/gpt-5.3-codex-spark |
| gsd-codebase-mapper | openai/gpt-5.4 | openai/gpt-5.3-codex-spark | openai/gpt-5.3-codex-spark |
| gsd-verifier | openai/gpt-5.4 | openai/gpt-5.3-codex-spark | openai/gpt-5.3-codex-spark |
| gsd-plan-checker | openai/gpt-5.4 | openai/gpt-5.3-codex-spark | openai/gpt-5.3-codex-spark |
| gsd-integration-checker | openai/gpt-5.4 | openai/gpt-5.3-codex-spark | openai/gpt-5.3-codex-spark |
| gsd-nyquist-auditor | openai/gpt-5.4 | openai/gpt-5.3-codex-spark | openai/gpt-5.3-codex-spark |
| gsd-code-reviewer | openai/gpt-5.4 | openai/gpt-5.3-codex-spark | openai/gpt-5.3-codex-spark |
| gsd-database-reviewer | openai/gpt-5.4 | openai/gpt-5.3-codex-spark | openai/gpt-5.3-codex-spark |
| gsd-go-reviewer | openai/gpt-5.4 | openai/gpt-5.3-codex-spark | openai/gpt-5.3-codex-spark |
| gsd-python-reviewer | openai/gpt-5.4 | openai/gpt-5.3-codex-spark | openai/gpt-5.3-codex-spark |
| gsd-security-reviewer | openai/gpt-5.4 | openai/gpt-5.3-codex-spark | openai/gpt-5.3-codex-spark |

## Profile Philosophy

**quality** - Maximum reasoning power
- `openai/gpt-5.4` for all GSD agents
- Use when: quota available, critical architecture work

**balanced** (default) - Smart allocation
- `openai/gpt-5.3-codex-spark` for all GSD agents
- Use when: normal development, good balance of quality and cost

**budget** - Cost-aware, same family, lower tier
- `openai/gpt-5.3-codex-spark` for all GSD agents
- Use when: conserving quota, high-volume work, less critical phases

## Resolution Logic

Orchestrators resolve model before spawning:

```
1. read .planning/config.json
2. Check model_overrides for agent-specific override
3. If no override, look up agent in profile table
4. Pass model parameter to task call
```

## Per-Agent Overrides

Override specific agents without changing the entire profile:

```json
{
  "model_profile": "balanced",
  "model_overrides": {
    "gsd-executor": "openai/gpt-5.4",
    "gsd-planner": "openai/gpt-5.3-codex-spark"
  }
}
```

Overrides take precedence over the profile. Values should be full OpenCode model IDs.

## Switching Profiles

Runtime: `/gsd-set-profile <profile>`

Per-project default: Set in `.planning/config.json`:
```json
{
  "model_profile": "balanced"
}
```

## Design Rationale

**Why `openai/gpt-5.4` for quality?**
When you want maximum reasoning quality, use the strongest configured OpenAI model across the full workflow.

**Why `openai/gpt-5.3-codex-spark` for balanced and budget?**
Execution-heavy GSD work benefits from a fast code-focused model. In this fork, balanced and budget intentionally share the same OpenAI model because the team prefers consistency over tier mixing.

**Why use explicit model IDs instead of aliases?**
This fork is OpenAI-only by default. Explicit model IDs make installer output, profile resolution, and reviewer behavior predictable across machines.
