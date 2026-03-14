#!/usr/bin/env bash
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
RESET='\033[0m'

info()  { echo -e "  ${GREEN}✓${RESET} $1"; }
warn()  { echo -e "  ${YELLOW}⚠${RESET} $1"; }
err()   { echo -e "  ${RED}✗${RESET} $1"; exit 1; }

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
PACKAGE_DIR="$REPO_DIR/gsd-opencode"
OVERLAY_DIR="$REPO_DIR/local/gsd-opencode"
BUILD_DIR="$REPO_DIR/.local-runtime/opencode-overlay"

TARGET_DIR="$HOME/.config/opencode"
UNINSTALL=false

usage() {
  cat <<EOF
Usage: bash setup-local.sh [--config-dir PATH] [--uninstall]

Local dev installer for gsd-opencode.

- Symlinks the cloned repo into your OpenCode config
- Uses package sources from ./gsd-opencode/
- Overlays files from ./local/gsd-opencode/
- Seeds opencode.json defaults via the local setup script

Options:
  --config-dir PATH   Target OpenCode config directory (default: ~/.config/opencode)
  --uninstall         Remove locally linked files created by this script
  -h, --help          Show this help text
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --config-dir)
      [[ $# -ge 2 ]] || err "--config-dir requires a path"
      TARGET_DIR="$2"
      shift 2
      ;;
    --uninstall)
      UNINSTALL=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      err "Unknown argument: $1"
      ;;
  esac
done

TARGET_DIR="${TARGET_DIR/#\~/$HOME}"
MANIFEST_PATH="$TARGET_DIR/.gsd-local-manifest"

ensure_parent() {
  mkdir -p "$(dirname "$1")"
}

remove_if_needed() {
  local target="$1"

  if [[ -L "$target" ]]; then
    rm -f "$target"
    return
  fi

  if [[ -e "$target" ]]; then
    warn "$target already exists and will be replaced"
    rm -rf "$target"
  fi
}

cleanup_empty_dirs() {
  local dir="$1"
  while [[ "$dir" != "$TARGET_DIR" && "$dir" != "/" ]]; do
    if [[ -d "$dir" ]] && [[ -z "$(ls -A "$dir" 2>/dev/null)" ]]; then
      rmdir "$dir" 2>/dev/null || true
      dir="$(dirname "$dir")"
    else
      break
    fi
  done
}

render_overlay() {
  local target_posix
  target_posix="$(node -e "console.log(require('path').resolve(process.argv[1]).split(require('path').sep).join('/'))" "$TARGET_DIR")"

  rm -rf "$BUILD_DIR"
  mkdir -p "$BUILD_DIR"

  node - "$OVERLAY_DIR" "$BUILD_DIR" "$target_posix" <<'EOF'
const fs = require('fs');
const path = require('path');

const overlayDir = process.argv[2];
const buildDir = process.argv[3];
const targetDir = process.argv[4];

function walk(dir) {
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  for (const entry of entries) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      walk(full);
      continue;
    }

    let relative = path.relative(overlayDir, full);
    if (relative === path.join('bin', 'gsd-tools.cjs')) {
      relative = path.join('get-shit-done', 'bin', 'gsd-tools.cjs');
    }

    if (relative.startsWith(path.join('commands', 'gsd') + path.sep)) {
      const fileName = path.basename(relative);
      if (!fileName.startsWith('gsd-')) {
        relative = path.join(path.dirname(relative), `gsd-${fileName}`);
      }
    }

    const dest = path.join(buildDir, relative);
    fs.mkdirSync(path.dirname(dest), { recursive: true });

    const original = fs.readFileSync(full, 'utf8');
    const rendered = original
      .replace(/node gsd-opencode\/get-shit-done\/bin\/gsd-tools\.cjs/g, `node ${targetDir}/get-shit-done/bin/gsd-tools.cjs`)
      .replace(/@~\/\.config\/opencode\//g, `@${targetDir}/`)
      .replace(/~\/\.config\/opencode\//g, `${targetDir}/`);

    fs.writeFileSync(dest, rendered, 'utf8');
  }
}

walk(overlayDir);
EOF

  info "Rendered local overlay files"
}

link_tree() {
  local source_dir="$1"
  local dest_prefix="$2"

  while IFS= read -r source_file; do
    local rel target
    rel="${source_file#"$source_dir"/}"
    target="$TARGET_DIR/$dest_prefix/$rel"
    ensure_parent "$target"
    remove_if_needed "$target"
    ln -s "$source_file" "$target"
    printf '%s\n' "$target" >> "$MANIFEST_PATH"
  done < <(find "$source_dir" -type f | sort)
}

write_version() {
  local version_file="$TARGET_DIR/get-shit-done/VERSION"
  local version
  version="$(node -p "require('$PACKAGE_DIR/package.json').version")"
  ensure_parent "$version_file"
  printf '%s' "$version" > "$version_file"
  info "Wrote VERSION ($version)"
}

uninstall() {
  echo ""
  echo -e "  ${CYAN}GSD-OpenCode Local Dev Uninstall${RESET}"
  echo ""

  if [[ ! -f "$MANIFEST_PATH" ]]; then
    err "No local manifest found at $MANIFEST_PATH"
  fi

  while IFS= read -r target; do
    [[ -n "$target" ]] || continue
    if [[ -L "$target" ]]; then
      rm -f "$target"
      cleanup_empty_dirs "$(dirname "$target")"
    fi
  done < "$MANIFEST_PATH"

  rm -f "$TARGET_DIR/get-shit-done/VERSION"
  rm -f "$MANIFEST_PATH"
  cleanup_empty_dirs "$TARGET_DIR/get-shit-done"

  info "Removed local symlinks from $TARGET_DIR"
  warn "opencode.json was left in place"
  echo ""
}

if [[ "$UNINSTALL" == true ]]; then
  uninstall
  exit 0
fi

echo ""
echo -e "  ${CYAN}GSD-OpenCode Local Dev Setup${RESET}"
echo -e "  Repo: ${REPO_DIR}"
echo -e "  Package source: ${PACKAGE_DIR}"
echo -e "  Overlay source: ${OVERLAY_DIR}"
echo -e "  Target: ${TARGET_DIR}"
echo ""

[[ -f "$PACKAGE_DIR/package.json" ]] || err "Package repo not found at $PACKAGE_DIR"
[[ -d "$OVERLAY_DIR" ]] || err "Local overlay not found at $OVERLAY_DIR"

mkdir -p "$TARGET_DIR"
: > "$MANIFEST_PATH"

render_overlay

link_tree "$PACKAGE_DIR/agents" "agents"
link_tree "$PACKAGE_DIR/commands" "commands"
link_tree "$PACKAGE_DIR/get-shit-done" "get-shit-done"
link_tree "$PACKAGE_DIR/rules" "rules"
link_tree "$PACKAGE_DIR/skills" "skills"
link_tree "$BUILD_DIR" ""

write_version

node "$PACKAGE_DIR/bin/setup-opencode.js" --target-dir "$TARGET_DIR" >/dev/null
info "Updated opencode.json defaults"

echo ""
echo -e "  ${GREEN}Done!${RESET} OpenCode now uses your cloned local repo."
echo ""
echo -e "  ${CYAN}How it works:${RESET}"
echo "  - Base files are symlinked from $PACKAGE_DIR"
echo "  - local/gsd-opencode overrides are rendered and linked on top"
echo "  - Re-run this script after editing files in local/gsd-opencode/"
echo ""
echo -e "  ${CYAN}To uninstall:${RESET} bash $REPO_DIR/setup-local.sh --uninstall"
echo ""
