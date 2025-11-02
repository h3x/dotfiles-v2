#!/usr/bin/env bash
notify-send "Starting AlayaCare Services Stack"
alacritty -e bash -lc "cd \"$ALAYACARE_SERVICES/webapp\" && dc up -d && npm run start:webapp:federated; exec bash" &

