#!/bin/bash

if [[ $# - eq 1 ]]; then
   selected=$1 
else
    selected=$(find ~/dev ~/dotfiles ~/ ~/alayadev/accloud-lde/ -mindepth 1 -maxdepth 1 -type d | fzf)
fi

if [[ -z $selected ]]; then
    exit 1
fi

selected_name=$(basename "$selected" | tr . _)
tmux_running=$(tmux ls | grep -c $selected_name)

if [[ $tmux_running -eq 0 ]]; then
    tmux new-session -s $selected_name -c $selected
else
    tmux attach-session -t $selected_name
fi
# todo finish this
