#!/bin/bash

in=$1
if [ -z "$in" ] then
        read in
fi

bin="/Applications/DBeaver.app/Contents/MacOS/dbeaver"
driver="driver=$(jq -r '.engine' <<<$in| sed 's/mysql/MariaDB/g' | sed 's/postgresql/PostgreSQL/g')"
host="host=$(jq -r '.hostname' <<<$in)"
port="port=$(jq -r '.port' <<<$in)"
user="user=$(jq -r '.username' <<<$in)"
password="password=$(jq -r '.password' <<<$in)"
database="database=$(jq -r '.name' <<<$in)"
name="name=$database"

command="$bin -con \"$driver|$name|$host|$port|$user|$password|$database\""
eval "$command"

# nabu get v1/tenant/rm.dev.alayacare.ca | jq -c '.databases.mysql' | dbeaver-connect
