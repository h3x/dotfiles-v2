#!/usr/bin/env bash
notify-send "Pulling Latest Changes for AlayaCare Services"
terminal-display 'cd $ALAYACARE_HOME && ac services foreach "git pull && git submodule update"'

