#!/usr/bin/env bash
# mux-solo demo: spin up a throwaway tmux session with mock pane statuses
# so you can see/screenshot every state without wiring up shells.
#
#   ./demo/seed.sh           # build it
#   tmux -L mux-solo-demo attach -t demo
#   tmux -L mux-solo-demo kill-server   # clean up
set -euo pipefail

SOCK=mux-solo-demo
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Panes run a bare `sh` (no shell rc), so a real mux-solo shell hook can't
# clear the mock statuses we set below.
HOLD="sh"

tmux -L "$SOCK" kill-server 2>/dev/null || true
sleep 0.3
tmux -L "$SOCK" new-session -d -s demo -x 200 -y 50 "$HOLD"
tmux -L "$SOCK" set -g base-index 1
tmux -L "$SOCK" set -g pane-base-index 1
tmux -L "$SOCK" set -ga terminal-overrides ",*:Tc"
tmux -L "$SOCK" run-shell "$ROOT/mux-solo.tmux"

# A minimal window-status format using the exposed fragments.
tmux -L "$SOCK" set -g window-status-format \
  "#[fg=#{?#{E:@mux_solo_attention},#{E:@mux_solo_attention},white}] #I #[fg=default]#{E:@mux_solo_name} "
tmux -L "$SOCK" set -g window-status-current-format \
  "#[fg=magenta,bold] #I #[fg=default,nobold]#{E:@mux_solo_name} "
tmux -L "$SOCK" set -g window-status-separator ""

mock() { tmux -L "$SOCK" set-option -p -t "$1" @pane_status "$2"; tmux -L "$SOCK" set-option -p -t "$1" @pane_label "$3"; }

tmux -L "$SOCK" rename-window -t demo:1 web
tmux -L "$SOCK" split-window -t demo:1 -h "$HOLD"
mapfile -t w < <(tmux -L "$SOCK" list-panes -t demo:1 -F '#{pane_id}')
mock "${w[0]}" running "rails server"; mock "${w[1]}" crashed "sidekiq"

tmux -L "$SOCK" new-window -t demo:2 -n test "$HOLD"
mock "$(tmux -L "$SOCK" list-panes -t demo:2 -F '#{pane_id}')" exited "rspec"

tmux -L "$SOCK" new-window -t demo:3 -n agents "$HOLD"
tmux -L "$SOCK" split-window -t demo:3 -h "$HOLD"
mapfile -t a < <(tmux -L "$SOCK" list-panes -t demo:3 -F '#{pane_id}')
mock "${a[0]}" waiting "󴄾"; mock "${a[1]}" working "󴀷"

tmux -L "$SOCK" new-window -t demo:4 -n plain "$HOLD"

tmux -L "$SOCK" select-window -t demo:1
echo "Attach:   tmux -L $SOCK attach -t demo"
echo "Clean up: tmux -L $SOCK kill-server"
