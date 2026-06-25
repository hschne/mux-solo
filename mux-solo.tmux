#!/usr/bin/env bash
# mux-solo: soloterm-style process/agent status in the tmux window list.
#
# This entry point (run by tpm) sets default colours/glyphs and exposes
# two format options you drop into your own window-status format:
#
#   #{E:@mux_solo_name}        per-window pane status concat, or #W
#   #{E:@mux_solo_attention}   red if a pane crashed, blue if an agent is
#                              waiting, else empty (keep your own accent)
#
# Producers (shell hook, pi extension, ...) set two per-pane user options:
#   @pane_status  one of: running working waiting crashed exited
#   @pane_label   short text shown next to the dot
set -euo pipefail

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

set_default() {
  local opt="$1" val="$2"
  [ -z "$(tmux show-options -gqv "$opt" 2>/dev/null)" ] && tmux set-option -g "$opt" "$val"
  return 0
}

# Defaults. Override any of these in tmux.conf before the plugin run line.
set_default "@mux-solo-color-running"  "green"
set_default "@mux-solo-color-working"  "green"
set_default "@mux-solo-color-waiting"  "blue"
set_default "@mux-solo-color-crashed"  "red"
set_default "@mux-solo-color-exited"   "green"
set_default "@mux-solo-color-label"    "default"
set_default "@mux-solo-glyph-active"   "●"
set_default "@mux-solo-glyph-inactive" "○"
set_default "@mux-solo-separator"      "│"

# The separator is baked into the trim pattern, so read its literal value.
sep="$(tmux show-options -gqv "@mux-solo-separator")"

# Colours/glyphs are referenced live, so changing the colour options takes
# effect without rebuilding. running/working = filled; crashed/exited =
# hollow ("not running"). Colour: waiting=blue, crashed=red, else green.
color='#{?#{==:#{@pane_status},waiting},#[fg=#{@mux-solo-color-waiting}],#{?#{==:#{@pane_status},crashed},#[fg=#{@mux-solo-color-crashed}],#{?#{==:#{@pane_status},exited},#[fg=#{@mux-solo-color-exited}],#[fg=#{@mux-solo-color-running}]}}}'
glyph='#{?#{==:#{@pane_status},crashed},#{@mux-solo-glyph-inactive},#{?#{==:#{@pane_status},exited},#{@mux-solo-glyph-inactive},#{@mux-solo-glyph-active}}}'
seg="#{?#{@pane_status},${color}${glyph} #[fg=#{@mux-solo-color-label}]#{@pane_label} ${sep} ,}"

# Per-window: concat of tracked panes (trailing separator trimmed), or #W.
name="#{?#{P:#{@pane_status}},#{s/ ${sep} \$//:#{P:${seg}}},#W}"

# Per-window attention colour (crashed wins over waiting), else empty.
attention='#{?#{m:*crashed*,#{P:#{@pane_status} }},#{@mux-solo-color-crashed},#{?#{m:*waiting*,#{P:#{@pane_status} }},#{@mux-solo-color-waiting},}}'

tmux set-option -g "@mux_solo_name" "$name"
tmux set-option -g "@mux_solo_attention" "$attention"

# Publish our install dir so the shell hook and pi extension can be sourced
# without hardcoding the tpm plugin path:
#   source "$(tmux show-environment -g MUX_SOLO_DIR | cut -d= -f2)/shell/mux-solo.zsh"
tmux set-environment -g MUX_SOLO_DIR "$CURRENT_DIR"
