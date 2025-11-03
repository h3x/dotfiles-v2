#!/usr/bin/env bash
# source ~/.zshrc
notify-send "Starting AlayaCare Services Stack"
alacritty -e zsh -lc "source ~/.zshrc && cd $ALAYACARE_SERVICES/webapp && docker compose up -d && npm run start:webapp:federated; exec zsh" &
