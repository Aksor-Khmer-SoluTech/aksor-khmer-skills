#!/usr/bin/env bash
# Copy the Aksor skills into Claude Code's skills folder.
#   ./install.sh                       -> ~/.claude/skills (every project)
#   ./install.sh --project <folder>    -> <folder>/.claude/skills (that project only)
# Run it again after `git pull` to update. Only the aksor-* skill folders are replaced; nothing else is touched.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
src="plugins/aksor/skills"

case "${1:-}" in
  "") dest="$HOME/.claude/skills" ;;
  --project)
    [ -n "${2:-}" ] && [ -d "$2" ] || { echo "error: --project needs an existing folder" >&2; exit 1; }
    dest="$(cd "$2" && pwd)/.claude/skills" ;;
  -h|--help) sed -n '2,5p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
  *) echo "error: unknown option '$1' (see ./install.sh --help)" >&2; exit 1 ;;
esac

mkdir -p "$dest"
for skill in "$src"/*/; do
  name="$(basename "$skill")"
  case "$name" in aksor-*) ;; *) continue ;; esac
  [ -e "$dest/$name" ] && rm -r -- "${dest:?}/$name"
  cp -R "$skill" "$dest/$name"
  echo "installed $name -> $dest/$name"
done
echo "done. Restart Claude Code (or start a new session) to pick them up."
