# Open a client to a tenant's mysql database
nabu-mysql ()
{
  PARAMS=""
  for PARAM in "${@:3}"
  do
    if [[ $PARAM = -* ]]
    then
      PARAMS="${PARAMS} ${PARAM}"
    else
      PARAMS="${PARAMS} \"${PARAM}\""
    fi
  done

  if [[ "$2" == 'local' ]]; then
    mycli --host db --user root --password root --database alayadev
    return 1;
  fi

  if [[ "$2" == 'prod' ]]; then
   if zenity --question --text "Are you sure you want to connect to prod db?"; then
     echo "Connecting to prod db"
   else
     return 1;
   fi
  fi

  URI=$(nabu get "v1/tenant/$1?environment=$2" | jq '.databases.mysql | ("--user " + .username + " --password " + .password + " --host " + .hostname + " --database " + .name)')
  URI=$(echo "mycli $URI" | tr -d '"')
  eval "$URI $PARAMS"
}

# connect directly to a tenant's mysql database
# requires mycli
# params:
#   $1: tenant name
#   $2: enviroment
nabu-jobs ()
{
  PARAMS=""
  for PARAM in "${@:3}"
  do
    if [[ $PARAM = -* ]]
    then
      PARAMS="${PARAMS} ${PARAM}"
    else
      PARAMS="${PARAMS} \"${PARAM}\""
    fi
  done

  if [[ "$2" == 'local' ]]; then
    export PGPASSWORD='dev_alayadev_jobs'
    pgcli --host pg --user dev_alayadev_jobs --no-password root --dbname dev_jobs
    return 1;
  fi

  if [[ "$2" == 'prod' ]]; then
   if zenity --question --text "Are you sure you want to connect to prod db?"; then
     echo "Connecting to prod db"
   else
     return 1;
   fi
  fi

  export PGPASSWORD=$(nabu get "v1/tenant/$1?environment=$2" | jq '.databases.jobs | (.password)' | cut -d "\"" -f 2)
  URI=$(nabu get "v1/tenant/$1?environment=$2" | jq '.databases.jobs | ("--user " + .username + " --no-password " + .password + " --host " + .hostname + " --dbname " + .name)')
  URI=$(echo "pgcli $URI" | tr -d '"')
  eval "$URI $PARAMS"
}

# nabu-mysql tenant environment
# nabu-jobs tenant environment

