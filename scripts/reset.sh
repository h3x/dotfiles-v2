#!/bin/bash

# reset.sh

GREEN="\033[0;32m"
BLUE="\033[0;34m"
RED="\033[0;31m"
MAGENTA="\033[0;35m"
NC="\033[0m"

NABU="$ALAYACARE_HOME/services/nabu/web/api/v1/tenant"
LOCAL_FILE="alayadev.json"
TEMP_FILE="alayadev.tmp.json"

LOCAL_TENANT="${NABU}/${LOCAL_FILE}"
TEMP="${NABU}/${TEMP_FILE}"


if [ ! -f $TEMP ]; then
        echo -e "${RED}Temporary file does not exist. Exiting...${NC}"
        exit 1
fi
mv $TEMP $LOCAL_TENANT 

echo -e "${GREEN}${LOCAL_FILE} Reset Successful!${NC}"
echo ""
