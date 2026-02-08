#!/usr/bin/env bash
# Install recommended Cursor Skills to user-level ~/.cursor/skills/
# Run from project root or any folder. Requires: git

set -e
CURSOR_HOME="${CURSOR_USER_HOME:-$HOME/.cursor}"
SKILLS_DIR="$CURSOR_HOME/skills"
TEMP_DIR="${TMPDIR:-/tmp}/cursor-skills-install-$$"

REPOS="agentworks/secure-skills daniel-scrivner/cursor-skills dadbodgeoff/drift vercel-labs/agent-skills"

echo "Cursor Skills installer (user-level)"
echo "Target: $SKILLS_DIR"
echo ""

if ! command -v git &>/dev/null; then
  echo "ERROR: git is required. Install Git and try again."
  exit 1
fi

mkdir -p "$SKILLS_DIR"
mkdir -p "$TEMP_DIR"
trap 'rm -rf "$TEMP_DIR"' EXIT

for repo in $REPOS; do
  name="${repo##*/}"
  clone_path="$TEMP_DIR/$name"
  echo "Cloning $repo ..."
  if ! git clone --depth 1 --quiet "https://github.com/${repo}.git" "$clone_path" 2>/dev/null; then
    echo "  Skip (clone failed or repo not found)."
    continue
  fi
  count=0
  while IFS= read -r -d '' f; do
    dir=$(dirname "$f")
    skill_name=$(basename "$dir")
    dest="$SKILLS_DIR/$skill_name"
    rm -rf "$dest"
    cp -R "$dir" "$dest"
    echo "  Installed skill: $skill_name"
    count=$((count + 1))
  done < <(find "$clone_path" -name "SKILL.md" -print0 2>/dev/null)
  if [ "$count" -eq 0 ]; then
    if [ -f "$clone_path/SKILL.md" ]; then
      dest="$SKILLS_DIR/$name"
      rm -rf "$dest"
      cp -R "$clone_path" "$dest"
      echo "  Installed as $name"
    else
      echo "  Skip (no SKILL.md found)."
    fi
  fi
done

echo ""
echo "Done. Restart Cursor to see new skills (or use / in Agent chat)."
