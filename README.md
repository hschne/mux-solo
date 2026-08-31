# mux-solo

Soloterm-style process and agent status in your tmux window list. Each
tracked pane shows a colored dot + label; a window's index is tinted red
if a pane crashed or blue if an agent is waiting. Untracked windows look
normal.

- running / working — filled dot (green / green)
- waiting — filled dot (blue)
- crashed — hollow dot (red)
- exited — hollow dot (green)

Requires tmux >= 3.1. Shell hook is **zsh only**.

## How it works

Producers set two per-pane user options; a tmux format renders them:

```
@pane_status   running | working | waiting | crashed | exited
@pane_label    short text shown next to the dot
```

## Install (tpm)

```tmux
set -g @plugin 'hschne/mux-solo'
run '~/.tmux/plugins/tpm/tpm'
```

Insert the exposed fragments into your `window-status` format(s):

```tmux
set -g window-status-format \
  "#[fg=#{?#{E:@mux_solo_attention},#{E:@mux_solo_attention},white}] #I #[fg=default]#{E:@mux_solo_name} "
set -g window-status-current-format \
  "#[fg=magenta] #I #[fg=default]#{E:@mux_solo_name} "
```

## Shell hook (zsh)

```sh
source "$(tmux show-environment -g MUX_SOLO_DIR | cut -d= -f2)/shell/mux-solo.zsh"
```

(The plugin publishes its install dir as the `MUX_SOLO_DIR` tmux
environment variable, so you don't hardcode the tpm path.)

List the commands to track in the `@mux-solo-processes` tmux option, a
comma-separated list. Aliases are expanded and leading env assignments
stripped, so `rails` matches `rails server`, `bundle exec rails` matches
`bundle exec rails db:migrate`, and your `rs` alias resolves to `rails`:

```tmux
set -g @mux-solo-processes 'rails, bundle exec rails, node, vite, claude'
```

Reload after changing the option with `mux-solo-reload`.

## Agents

Agent labels use glyphs from
[lobe-icons-font](https://github.com/hschne/lobe-icons-font); configure it as
a fallback font for your terminal.

### Pi

Run [pi](https://pi.dev) with the bundled extension so each agent shows
working/waiting:

```sh
pi -e "$(tmux show-environment -g MUX_SOLO_DIR | cut -d= -f2)/integrations/pi/tmux.ts"
```

### Claude Code

Install the bundled plugin permanently for your user:

```sh
claude plugin marketplace add hschne/mux-solo
claude plugin install mux-solo@mux-solo --scope user
```

To install from a local checkout instead:

```sh
claude plugin marketplace add ~/Source/mux-solo
claude plugin install mux-solo@mux-solo --scope user
```

Verify with `claude plugin list`, then restart Claude Code. For a one-off
session without installing:

```sh
claude --plugin-dir "$(tmux show-environment -g MUX_SOLO_DIR | cut -d= -f2)/integrations/claude"
```

The plugin marks submitted turns as working, completed turns as waiting,
failed turns as crashed, and clears the pane when the session ends. Keep
`claude` in `@mux-solo-processes` as shown above to also track the process
lifetime before startup and after shutdown.

## Options

```tmux
set -g @mux-solo-processes ''           # comma-separated commands to track (zsh hook)
set -g @mux-solo-color-running  green   # also -working -waiting -crashed -exited -label
set -g @mux-solo-glyph-active    ●      # running / working
set -g @mux-solo-glyph-inactive  ○      # crashed / exited
set -g @mux-solo-separator       │
```

## Demo

```sh
~/.tmux/plugins/mux-solo/demo/seed.sh
tmux -L mux-solo-demo attach -t demo
```
