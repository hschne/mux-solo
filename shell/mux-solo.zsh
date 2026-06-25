# mux-solo: zsh integration for tmux window status indicators.
#
# Marks each pane with a status the tmux window tabs render as a colored
# dot + label. Tracks only commands matching a prefix listed in the
# `@mux-solo-processes` tmux option (comma-separated, e.g.
# `set -g @mux-solo-processes 'rails, node, bundle exec rails'`).
# Before matching, a leading shell alias is expanded and leading env
# assignments (FOO=1) are stripped, so `rs` (your alias) and
# `RAILS_ENV=test rails s` resolve. Matching is word-prefix: `rails`
# matches `rails server`, and a multi-word entry like `bundle exec rails`
# matches `bundle exec rails console`. Agent panes are owned by their own
# producer (e.g. the pi extension), which writes the same @pane_status /
# @pane_label options directly.

# Only meaningful inside tmux.
[[ -n "$TMUX" ]] || return 0

typeset -ga _mux_solo_procs

# Read the tracked commands from the `@mux-solo-processes` tmux option:
# a comma-separated list whose entries may themselves contain spaces
# (e.g. `bundle exec rails`). Each entry is whitespace-normalized.
_mux_solo_load() {
  emulate -L zsh
  _mux_solo_procs=()
  local raw
  raw="$(tmux show-option -gqv @mux-solo-processes 2>/dev/null)"
  [[ -n "$raw" ]] || return 0
  local entry
  local -a fields
  for entry in ${(s:,:)raw}; do
    fields=(${=entry})          # whitespace-split (drops blanks, normalizes)
    (( $#fields )) && _mux_solo_procs+="${(j: :)fields}"  # normalized entry
  done
}

mux-solo-reload() { emulate -L zsh; _mux_solo_load; }

# Per-shell memory of what we last pushed to tmux, so we only shell out to
# tmux when the state actually changes (keeps the prompt fast).
typeset -g _mux_solo_state=""
typeset -g _mux_solo_label=""
typeset -g _mux_solo_pending_tracked=0
typeset -g _mux_solo_pending_label=""
typeset -g _mux_solo_cmd=""

# Clear this pane's status with a single tmux invocation. Target
# $TMUX_PANE explicitly: `set-option -p` without -t resolves to the
# client's ACTIVE pane, not the calling shell's pane, so background panes
# (tmuxinator startup) would otherwise write to the wrong window.
_mux_solo_unset_pane() {
  emulate -L zsh
  tmux set-option -pu -t "$TMUX_PANE" @pane_status \; \
       set-option -pu -t "$TMUX_PANE" @pane_label \; \
       refresh-client -S 2>/dev/null
}

_mux_solo_set() {
  emulate -L zsh
  local state="$1" label="$2"
  [[ "$state" == "$_mux_solo_state" && "$label" == "$_mux_solo_label" ]] && return 0
  _mux_solo_state="$state"
  _mux_solo_label="$label"
  local short="$label"
  (( ${#short} > 20 )) && short="${short[1,19]}…"
  tmux set-option -p -t "$TMUX_PANE" @pane_status "$state" \; \
       set-option -p -t "$TMUX_PANE" @pane_label "$short" \; \
       refresh-client -S 2>/dev/null
}

_mux_solo_clear() {
  emulate -L zsh
  [[ -z "$_mux_solo_state" ]] && return 0
  _mux_solo_state=""
  _mux_solo_label=""
  _mux_solo_unset_pane
}

# Normalize a command into $_mux_solo_cmd: expand a leading alias (once
# per name, like zsh itself) and strip leading env assignments. No
# subshell, so it stays cheap to run on every prompt.
_mux_solo_resolve() {
  emulate -L zsh
  local -a words
  words=(${(z)1})
  typeset -A seen
  local i=0
  while (( $#words && i < 20 )); do
    (( i++ ))
    if [[ "$words[1]" == *=* ]]; then
      shift words; continue            # leading env assignment (FOO=1)
    fi
    if (( ${+aliases[$words[1]]} )) && (( ! ${+seen[$words[1]]} )); then
      seen[$words[1]]=1
      words=(${(z)aliases[$words[1]]} ${words[2,-1]})
      continue
    fi
    break
  done
  _mux_solo_cmd="${(j: :)words}"
}

# True if the resolved command equals a config entry or begins with one
# followed by a space (word-prefix match).
_mux_solo_match() {
  emulate -L zsh
  local entry
  for entry in $_mux_solo_procs; do
    [[ "$1" == "$entry" || "$1" == "$entry "* ]] && return 0
  done
  return 1
}

_mux_solo_preexec() {
  emulate -L zsh
  _mux_solo_resolve "$1"
  if [[ -n "$_mux_solo_cmd" ]] && _mux_solo_match "$_mux_solo_cmd"; then
    _mux_solo_pending_tracked=1
    _mux_solo_pending_label="$1"
    _mux_solo_set running "$1"
  else
    _mux_solo_pending_tracked=0
    _mux_solo_clear
  fi
}

_mux_solo_precmd() {
  local ec=$?        # capture before anything else clobbers it
  emulate -L zsh
  if (( _mux_solo_pending_tracked )); then
    if (( ec == 0 )) || (( ec >= 129 && ec <= 158 )); then
      _mux_solo_set exited "$_mux_solo_pending_label"
    else
      _mux_solo_set crashed "$_mux_solo_pending_label"
    fi
    _mux_solo_pending_tracked=0
  fi
}

autoload -Uz add-zsh-hook
add-zsh-hook preexec _mux_solo_preexec
add-zsh-hook precmd _mux_solo_precmd

_mux_solo_load

# A fresh shell owns its pane: clear any status left behind by a previous
# shell instance or an uncleanly-killed process so it can't go stale.
_mux_solo_unset_pane
