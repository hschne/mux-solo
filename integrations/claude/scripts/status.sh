#!/usr/bin/env bash

set -euo pipefail

readonly MARKER="󴀷"

function main() {
  local state="${1:-}"

  [[ -n "${TMUX:-}" && -n "${TMUX_PANE:-}" ]] || return 0

  case "$state" in
  working | waiting | crashed)
    tmux set-option -p -t "$TMUX_PANE" @pane_status "$state" \; \
      set-option -p -t "$TMUX_PANE" @pane_label "$MARKER" \; \
      refresh-client -S 2>/dev/null || true
    ;;
  clear)
    tmux set-option -pu -t "$TMUX_PANE" @pane_status \; \
      set-option -pu -t "$TMUX_PANE" @pane_label \; \
      refresh-client -S 2>/dev/null || true
    ;;
  -h | --help)
    usage
    ;;
  *)
    die "Unknown state: ${state:-<empty>}"
    ;;
  esac
}

usage() {
  cat <<EOF
Usage: $(basename "$0") working|waiting|crashed|clear

Update the current tmux pane with Claude Code's turn state.
EOF
}

die() {
  echo "Error: $1" >&2
  exit "${2:-1}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
