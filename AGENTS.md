# AGENTS.md

mux-solo shows process/agent status in the tmux window list. One contract:
producers set per-pane `@pane_status` (one of `running working waiting
crashed exited`) and `@pane_label`; a tmux format renders them.

## Layout

- `mux-solo.tmux` — entry point (tpm runs it). Builds the
  `@mux_solo_name` / `@mux_solo_attention` format fragments and sets
  default `@mux-solo-*` colour/glyph options.
- `shell/mux-solo.zsh` — zsh producer (preexec/precmd). zsh only.
- `integrations/pi/tmux.ts` — pi agent producer.
- `demo/seed.sh` — throwaway session with every state for preview/tests.

## Rules

- Keep the format theme-agnostic: expose fragments + options, never own
  the user's `window-status-format`.
- Always target panes explicitly with `-t "$TMUX_PANE"` (or the pane id);
  `set-option -p` without `-t` hits the client's active pane.
- Powerline/glyph chars are invisible in tool output — after editing a
  format line, verify the glyph count survived.
- Verify rendering with `demo/seed.sh` (panes run bare `sh` so a real
  shell hook can't clear the mock statuses).
- No new dependencies. The tmux entry is bash; the hook is zsh.
