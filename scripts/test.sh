#!/bin/bash

NABU="$ALAYACARE_HOME/services/nabu/web/api/v1/tenant"
LOCAL_TENANT='${NABU}/alayadev.json'
TEMP='${NABU}/alayadev.tmp.json'

input=$(cat)
[[ -z $input ]] && echo "No input from nabu" && exit 1


function connect() {
        if [ -f $TEMP ]; then
                echo "Temporary file already exists. Please reset before connecting"
                exit 1
        fi

        mv $LOCAL_TENANT $TEMP


        # jq --argjson mysql "$(jq '.databases.mysql' test3.json)" '.databases.mysql=$mysql' alayadev.json > al.json
}

function reset() {
        if [ -f $TEMP ]; then
                echo "Temporary file does not exist. Exiting..."
                exit 1
        fi
        mv $TEMP $LOCAL_TENANT 
}


