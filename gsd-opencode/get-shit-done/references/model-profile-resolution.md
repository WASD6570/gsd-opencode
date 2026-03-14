# Model Profile Resolution

Resolve model profile once at the start of orchestration, then use it for all task spawns.

## Resolution Pattern

```bash
MODEL_PROFILE=$(cat .planning/config.json 2>/dev/null | grep -o '"model_profile"[[:space:]]*:[[:space:]]*"[^"]*"' | grep -o '"[^"]*"$' | tr -d '"' || echo "balanced")
```

Default: `simple` if not set or config missing.

## Lookup Table

@$HOME/.config/opencode/get-shit-done/references/model-profiles.md

Look up the agent in the table for the resolved profile. Pass the model parameter to task calls:

```
task(
  prompt="...",
  subagent_type="gsd-planner",
  model="{resolved_model}"  # e.g. "openai/gpt-5.4" or "openai/gpt-5.3-codex-spark"
)
```

**Note:** This fork resolves profiles to explicit OpenCode model IDs instead of provider aliases.

## Usage

1. Resolve once at orchestration start
2. Store the profile value
3. Look up each agent's model from the table when spawning
4. Pass model parameter to each task call as a full model ID
