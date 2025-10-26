#!/usr/bin/bash

# --------- 
# CPU Temperature
# --------- 

sensors | awk '/CPU:/ {printf "%s", $2'} || echo "N/A"
