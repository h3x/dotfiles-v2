#!/usr/bin/env bash
notify-send "Codeartifact token exported in new terminal"
alacritty -e bash -lc "export CODEARTIFACT_AUTH_TOKEN=$(aws codeartifact --profile codeartifact get-authorization-token --domain alayacare --domain-owner 406883902139 --query authorizationToken --output text); exec bash" &

