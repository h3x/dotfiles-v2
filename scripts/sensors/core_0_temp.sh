
#!/usr/bin/bash

# --------- 
# CPU Core 0 Temperature
# --------- 

sensors | awk '/Core 0:/ {printf "%s", $2'} || echo "N/A"
