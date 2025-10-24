#!/bin/bash

# connect.sh

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

input=$(cat)

[[ -z $input ]] && echo -e "${RED}No input from nabu${NC}" && exit 1

set +e
errors=$(jq -re '""' <<<"${input}" 2>&1)
if [ ! -z "${errors}" ]; then
  echo -e "${RED}Error parsing input: ${errors}${NC}"
  exit 1
fi

if [ -f $TEMP ]; then
        echo -e "${MAGENTA}Temporary file already exists. Please reset before connecting${NC}"
        exit 1
fi

set -e

mv $LOCAL_TENANT $TEMP
echo -e "${BLUE}Temporary file ${TEMP_FILE} created successfully!${NC}"

jq --argjson mysql "$(echo $input | jq '.databases.mysql')" '.databases.mysql=$mysql' $TEMP > $LOCAL_TENANT

echo -e "${GREEN}Connected to remote tenant successfully!${NC}"
