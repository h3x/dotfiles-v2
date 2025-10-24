#!/bin/bash


GREEN="\033[0;32m"
BLUE="\033[0;34m"
RED="\033[0;31m"
MAGENTA="\033[0;35m"
NC="\033[0m"

input=$(cat)

[[ -z $input ]] && echo -e "${RED}No input from nabu${NC}" && exit 1

# echo $input

set +e
errors=$(jq -re '""' <<<"${input}" 2>&1)
if [ ! -z "${errors}" ]; then
  echo -e "${RED}Error parsing input: ${errors}${NC}"
  exit 1
fi

# Parse JSON and assign to variables
username=$(echo "${input}" | jq -r '.mysql.username')
password=$(echo "${input}" | jq -r '.mysql.password')
hostname=$(echo "${input}" | jq -r '.mysql.hostname')
port=$(echo "${input}" | jq -r '.mysql.port')
name=$(echo "${input}" | jq -r '.mysql.name')


UUID=$(uuidgen -r)
source="
#DataSourceSettings#
#LocalDataSource: New Connection
#BEGIN#
<data-source source='LOCAL' name='New Connection' uuid='${UUID}'>
        <database-info product='MySQL' version='8.0.32' jdbc-version='4.2' driver-name='MySQL Connector/J' driver-version='mysql-connector-j-8.2.0 (Revision: 06a1f724497fd81c6a659131fda822c9e5085b6c)' dbms='MYSQL_AURORA' exact-version='3.5.2' exact-driver-version='8.2'>
                <extra-name-characters>#@</extra-name-characters>
                <identifier-quote-string>\`</identifier-quote-string>
                <jdbc-catalog-is-schema>true</jdbc-catalog-is-schema>
        </database-info>
        <case-sensitivity plain-identifiers='exact' quoted-identifiers='exact'/>
        <driver-ref>mysql.8</driver-ref>
        <synchronize>true</synchronize>
        <jdbc-driver>com.mysql.cj.jdbc.Driver</jdbc-driver>
        <jdbc-url>jdbc:mysql://${hostname}:${port}</jdbc-url>
        <secret-storage>master_key</secret-storage>
        <user-name>${username}</user-name>
        <schema-mapping>
        <introspection-scope>
        <node kind='schema'>
                <name qname='@'/>
                <name qname='${name}'/>
        </node>
        </introspection-scope>
        </schema-mapping>
</data-source>
#END#"


echo "${source}" | xclip -selection clipboard

echo -e "${GREEN}Data source copied to clipboard${NC}"
echo -e "${MAGENTA}To import the data source in DataGrip, paste the clipboard content in the XML tab of the Data Source Properties dialog${NC}"
echo -e "Password: ${BLUE}${password}${NC}"

