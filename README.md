# mux-solo

Soloterm-style process and agent status in your tmux window list. Each
window shows a colored dot + label per pane:

- **running / working** — filled dot (green / green)
- **waiting** (agent needs you) — filled dot (blue)
- **crashed** — hollow dot (red)
- **exited** — hollow dot (green)

A window's index is tinted red if any pane crashed, blue if an agent is
waiting. Windows with nothing tracked fall back to the normal name.

Requires tmux >= 3.1.

## How it works

One small contract: producers set two per-pane user options, a tmux
format renders them.

```
@pane_status   running | working | waiting | crashed | exited
@pane_label    short text shown next to the dot
```

- **Shell hook** (`shell/mux-solo.zsh`) sets them for tracked commands.
- **Agent extension** (`integrations/pi/`) sets them for a running agent.
- The plugin exposes two format fragments you drop into your theme.

## Install

With [tpm](https://github.com/tmux-plugins/tpm):

```tmux
set -g @plugin 'hschne/mux-solo'
run '~/.tmux/plugins/tpm/tpm'
```

Then put the fragments into your `window-status-format`(s):

```tmux
# index tinted by attention, then the pane status concat (or window name)
set -g window-status-format \
  "#[fg=#{?#{E:@mux_solo_attention},#{E:@mux_solo_attention},white}] #I #[fg=default]#{E:@mux_solo_name} "
set -g window-status-current-format \
  "#[fg=magenta] #I #[fg=default]#{E:@mux_solo_name} "
```

## Shell hook

Source it from your shell rc and list the processes you care about:

```sh
# ~/.zshrc
source ~/.tmux/plugins/mux-solo/shell/mux-solo.zsh
```

```sh
mkdir -p ~/.config/mux-solo
cp ~/.tmux/plugins/mux-solo/processes.example ~/.config/mux-solo/processes
```

Each line is a command prefix. Aliases are expanded and leading env
assignments stripped before matching, so `rails` matches `rails server`,
`bundle exec rails` matches `bundle exec rails db:migrate`, and `rs`
(your alias) resolves to `rails`. Reload with `mux-solo-reload`.

Only zsh is shipped today; bash/fish hooks welcome.

## Options

```tmux
set -g @mux-solo-color-running  green      # also -working -waiting -crashed -exited -label
set -g @mux-solo-glyph-active   ●          # running / working
set -g @mux-solo-glyph-inactive ○          # crashed / exited
set -g @mux-solo-separator      │
```

## Demo

```sh
./demo/seed.sh
tmux -L mux-solo-demo attach -t demo
```
