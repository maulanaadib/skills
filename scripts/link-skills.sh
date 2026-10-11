#!/usr/bin/env bash
set -euo pipefail

# NOTE: This is a dev-only script, intended for use by maintainers of this repo.
# It is not a supported installer. The supported installer is `npx skills add`.
#
# Links all skills in the repository into the local skill directories used by
# each agent harness:
#   ~/.agents/skills: opencode, codex, cursor, and other Agent Skills-compatible harnesses
#   ~/.claude/skills: Claude Code
# Each entry is a link into this repo, so a `git pull` is all that's needed
# to keep installed skills up to date.
#
# On Windows this script requires a bash environment (Git Bash, WSL). Windows
# users without bash should run scripts/link-skills.mjs instead, which needs
# only Node.js and no elevation.

REPO="$(cd "$(dirname "$0")/.." && pwd)"
DESTS=("$HOME/.agents/skills" "$HOME/.claude/skills")

# Collect the repo's skills once, link into every destination.
names=()
srcs=()
while IFS= read -r -d '' skill_md; do
  src="$(dirname "$skill_md")"
  names+=("$(basename "$src")")
  srcs+=("$src")
done < <(find "$REPO/skills" -name SKILL.md -not -path '*/node_modules/*' -print0)

if [ "${#names[@]}" -eq 0 ]; then
  echo "error: no SKILL.md found under $REPO/skills. Nothing to link." >&2
  exit 1
fi

# Guard: a destination that is itself a link into this repo would make us write
# the per-skill links back into the working copy. Detect and bail.
for DEST in "${DESTS[@]}"; do
  if [ -L "$DEST" ]; then
    resolved="$(readlink -f "$DEST")"
    case "$resolved" in
      "$REPO"|"$REPO"/*)
        echo "error: $DEST is a symlink into this repo ($resolved)." >&2
        echo "Remove it (rm \"$DEST\") and re-run; the script will recreate it as a real dir." >&2
        exit 1
        ;;
    esac
  fi
done

for DEST in "${DESTS[@]}"; do
  mkdir -p "$DEST"

  for i in "${!names[@]}"; do
    name="${names[$i]}"
    src="${srcs[$i]}"
    target="$DEST/$name"

    if [ -e "$target" ] && [ ! -L "$target" ]; then
      # A real directory already holds this name. Refuse rather than destroy it.
      echo "skipped  $name at $DEST: a real directory already exists there (not a symlink)."
      continue
    fi

    if [ -L "$target" ]; then
      existing="$(readlink -f "$target")"
      if [ "$existing" = "$src" ]; then
        echo "ok       $name (already linked)"
        continue
      fi
      rm -f "$target"
      echo "relink   $name (was -> $existing)"
    fi

    ln -sfn "$src" "$target"
    echo "linked   $name -> $src ($DEST)"
  done
done

echo ""
echo "Done. ${#names[@]} skill(s) linked."
echo "Edits in $REPO are now live in every linked agent."
echo "To revert: node scripts/link-skills.mjs --unlink"
