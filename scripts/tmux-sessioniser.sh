#!/usr/bin/env bash

if [[ $# -eq 1 ]]; then
    selected=$1
else
    selected=$(find ~/dev ~/alayadev/accloud-lde/ ~/alayadev/accloud-lde/services ~/dotfiles/.config/ ~/dotfiles -mindepth 1 -maxdepth 1 -type d | fzf)
fi

if [[ -z $selected ]]; then
    exit 0
fi

selected_name=$(basename "$selected" | tr . _)
tmux_running=$(pgrep tmux)

if [[ -z $TMUX ]] && [[ -z $tmux_running ]]; then
    tmux new-session -n $selected_name -c $selected
    exit 0
fi

# if ! tmux list-windows | awk {'print $2'} | grep -q $selected_name; then
#     tmux new-window -d -n $selected_name -c $selected
# fi
#
# tmux select-window -t $selected_name


if ! tmux has-session -t=$selected_name 2> /dev/null; then
    tmux new-session -ds $selected_name -c $selected
fi

tmux switch-client -t $selected_name
