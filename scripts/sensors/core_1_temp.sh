
#!/usr/bin/bash

# --------- 
# CPU Core 1 Temperature
# --------- 

sensors | awk '/Core 1:/ {printf "%s", $2'} || echo "N/A"
