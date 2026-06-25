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
source ~/.tmux/plugins/mux-solo/shell/mux-solo.zsh
```

List the commands to track in `~/.config/mux-solo/processes`, one prefix
per line. Aliases are expanded and leading env assignments stripped, so
`rails` matches `rails server`, `bundle exec rails` matches `bundle exec
rails db:migrate`, and your `rs` alias resolves to `rails`:

```
rails
bundle exec rails
node
vite
```

Reload after edits with `mux-solo-reload`.

## Agents

Run [pi](https://pi.dev) with the bundled extension so each agent shows
working/waiting:

```sh
pi -e ~/.tmux/plugins/mux-solo/integrations/pi/tmux.ts
```

## Options

```tmux
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
