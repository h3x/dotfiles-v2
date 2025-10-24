#!/bin/bash

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Header in green
echo -e "${GREEN}Name\t\t\t\t\t\tService\t\t\t\t\t\tStatus${NC}"
echo -e "${GREEN}========================================================================================================================${NC}"
echo -e ""

# Execute docker ps and extract the desired information
docker compose ps --all --format "{{.Name}}\t{{.Service}}\t{{.Status}}" | while IFS=$'\t' read -r name service status; do
  # Calculate the width of the IMAGE column to create proper spacing for each item
  padding_width=40
  name_padded=$(printf "%-${padding_width}.${padding_width}s" "$name")
  service_padded=$(printf "%-${padding_width}.${padding_width}s" "$service")
  status_padded=$(printf "%-${padding_width}.${padding_width}s" "$status" | awk '{print $1}')
  
  # Make pretty
  color=$(echo $status | awk '{if ($1 == "Up") print "\033[1;32m"; else if ($1 == "Exited") print "\033[1;31m"; else if ($1 == "Created") print "\033[0;34m"; else print "\033[0m]"}')

  echo -e "${MAGENTA}${name_padded}\t${CYAN}${service_padded}\t${color}${status_padded}${NC}"


done
# Optional. I dont like the line at the bottom. Uncomment if you want it
# echo -e "${YELLOW}--------------------------------------------------------------------------------------------------------------------${NC}"
