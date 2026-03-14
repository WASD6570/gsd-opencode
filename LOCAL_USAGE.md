# Local Usage

Use this when you want OpenCode to load the cloned repo directly instead of the npm-installed package.

## Quick Start

```bash
cd /path/to/gsd-opencode
bash setup-local.sh
```

That links the repo into `~/.config/opencode` and applies the `local/gsd-opencode` overlay on top of the package sources.

## What It Uses

- Base package files from `gsd-opencode/`
- Local override files from `local/gsd-opencode/`
- Default OpenCode config via `gsd-opencode/bin/setup-opencode.js`

## Notes

- Most files are live through symlinks
- The `local/gsd-opencode` overlay is rendered into a local runtime folder before linking, so re-run `bash setup-local.sh` after editing overlay files
- `opencode.json` is preserved on uninstall

## Uninstall

```bash
bash setup-local.sh --uninstall
```

## Custom Config Dir

```bash
bash setup-local.sh --config-dir /path/to/opencode-config
```
