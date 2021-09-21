#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
#set -o posix # this doesn't cause errors when non-posix things are used?
#set -o xtrace # or run bash -x but that ignore the shebang

source ./.secrets

#__constants__#
ENVIRONMENT="FreeNAS"
ORIGIN="FreeNAS"
SERVICE="FreeNAS Alert"
DEBUG=false		# set to true for debug messages. anything else means no debug messages


declare -A LEVEL
LEVEL[INFO]=informational
LEVEL[WARNING]=warning
LEVEL[NOTICE]=minor
LEVEL[ERROR]=major
LEVEL[CRITICAL]=critical
LEVEL[ALERT]=major
LEVEL[EMERGENCY]=critical		



#__helper functions__#
function debugecho {
    if [ "$DEBUG" == "true" ]
    then
        echo "$*"
    fi
}


# get the number of alerts
num=$( midclt call alert.list | jq length )

for (( i=0; i<=$num-1; i++ ))
do
	debugecho Record# ${i}

	alerts=$(midclt call alert.list | jq  ".[$i]")
	debugecho "${alerts}"

	dismissed="Dismissed? $(jq -r '.dismissed' <<< ${alerts})"

	if [[ "${dismissed}" == "true" ]]; then
	    continue
	fi

	uuid="$(jq -r '.uuid' <<< ${alerts})"
	source="$(jq -r '.klass' <<< ${alerts})"
	node="$(jq -r '.node' <<< ${alerts})"
	level=${LEVEL[$(jq -r '.level' <<< ${alerts})]}
	formatted="$(jq -r '.formatted' <<< ${alerts} | jq -sR)"
	

	JSON_TEMPLATE='{
		environment: $env, 
		event: $src, 
		origin: $org, 
		resource: $nd, 
		service: [ 
			$srv 
			], 
		severity: $lvl, 
		value: $dsm, 
		text: $fmt,
		type: "exceptionAlert"}'


	JSON=$( jq -n \
		--arg env "$ENVIRONMENT" \
		--arg src "$source" \
		--arg org "$ORIGIN" \
		--arg nd "$node" \
		--arg srv "$SERVICE" \
		--arg lvl "$level" \
		--arg dsm "$dismissed" \
		--arg fmt "$formatted" \
		"${JSON_TEMPLATE}")

	echo ${JSON}
	

	debugecho ${JSON} |jq -r .
	debugecho calling alerta
	curl -XPOST ${ALERTA_ENDPOINT} \
	-H 'Authorization: Key '${ALERTA_KEY}'' \
	-H 'Content-type: application/json' \
	-d "${JSON}"

	
	debugecho dismissed on freenas: ${dismissed}
	#echo enter to continue ...
	#read input

done






# TODO
# handle "dismissed" (push OK)
# test github.dev vscode
