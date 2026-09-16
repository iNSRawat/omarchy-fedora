#!/usr/bin/env bash
# gsd.sh — "Get Shit Done" agent & developer session launcher
# Launches a floating dedicated terminal for AI agentic coding (e.g. GSD, Claude Code, Aider)
set -euo pipefail

TITLE="GSD — Get Shit Done"

if [[ $# -gt 0 ]]; then
  # Run user's specific command inside a floating GSD terminal
  exec foot --title="$TITLE" "$@"
fi

# Check for agentic tools or launch interactive menu
if command -v npx &>/dev/null; then
  cat <<'EOF' >/tmp/_gsd_menu.sh
#!/usr/bin/env bash
echo -e "\033[1;34m══▶ GSD: Get Shit Done\033[0m"
echo -e "  1) Run GSD (get-shit-done-cc)"
echo -e "  2) Open Project Shell"
echo -e "  3) Git Status & Quick Commit"
echo -e "  4) Exit"
echo ""
read -rp "  Select [1-4]: " choice
case "$choice" in
  1) npx get-shit-done-cc@latest ;;
  2) exec $SHELL ;;
  3) git status && exec $SHELL ;;
  *) exit 0 ;;
esac
EOF
  chmod +x /tmp/_gsd_menu.sh
  exec foot --title="$TITLE" /tmp/_gsd_menu.sh
else
  exec foot --title="$TITLE"
fi
