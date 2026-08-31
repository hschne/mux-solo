#!/usr/bin/env bash

set -euo pipefail

readonly MARKER="󴀷"

function main() {
  local state="${1:-}"
  local input=""
  local model=""
  local project=""
  local status_icon=""
  local title=""

  [[ -n "${TMUX:-}" && -n "${TMUX_PANE:-}" ]] || return 0
  [[ -t 0 ]] || input="$(cat)"

  case "$state" in
  working | waiting | crashed)
    model="$(hook_model "$input")"
    if [[ -n "$model" ]]; then
      model="$(shorten_model "$model")"
    else
      model="$(tmux show-options -pqv -t "$TMUX_PANE" @claude_model 2>/dev/null || true)"
    fi

    project="$(basename "${CLAUDE_PROJECT_DIR:-$PWD}")"
    status_icon="$MARKER"
    [[ "$state" == "working" ]] && status_icon+="*"
    title="$status_icon $project"
    [[ -n "$model" ]] && title+=" · $model"

    tmux set-option -p -t "$TMUX_PANE" @pi_title "$title" \; \
      set-option -p -t "$TMUX_PANE" @pane_status "$state" \; \
      set-option -p -t "$TMUX_PANE" @pane_label "$MARKER" \; \
      set-option -p -t "$TMUX_PANE" @claude_model "$model" \; \
      refresh-client -S 2>/dev/null || true
    ;;
  clear)
    tmux set-option -pu -t "$TMUX_PANE" @pi_title \; \
      set-option -pu -t "$TMUX_PANE" @pane_status \; \
      set-option -pu -t "$TMUX_PANE" @pane_label \; \
      set-option -pu -t "$TMUX_PANE" @claude_model \; \
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

hook_model() {
  local input="$1"

  sed -n 's/.*"model"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' <<<"$input"
}

shorten_model() {
  local model="$1"

  model="${model#claude-}"
  sed -E 's/-[0-9]{8}$//' <<<"$model"
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
