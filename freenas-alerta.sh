#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

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

	uuid="$(jq -r '.uuid' <<< ${alerts})"
	source="$(jq -r '.klass' <<< ${alerts})"
	node="$(jq -r '.node' <<< ${alerts})"
	level=${LEVEL[$(jq -r '.level' <<< ${alerts})]}
	formatted="$(jq -r '.formatted' <<< ${alerts} | jq -sR)"
	dismissed="$(jq -r '.dismissed' <<< ${alerts})"

	if [[ ${dismissed} = "true" ]]; then
		status="closed"
		level="cleared"
	else
		echo dis =  "${dismissed}"
	fi

	
	# note that this is a literal template. i.e $ENVIRONMENT is not a bash variable
	# it's a jq template value name
	JSON_TEMPLATE='{
		environment: $ENVIRONMENT, 
		event: $source, 
		origin: $ORIGIN, 
		resource: $node, 
		service: [ 
			$SERVICE
			], 
		severity: $level, 
		status: $status,
		value: $dismissed, 
		text: $formatted,
		type: "exceptionAlert"}'


	JSON=$( jq -n \
		--arg ENVIRONMENT "$ENVIRONMENT" \
		--arg source "$source" \
		--arg ORIGIN "$ORIGIN" \
		--arg node "$node" \
		--arg SERVICE "$SERVICE" \
		--arg level "$level" \
		--arg status "$status" \
		--arg dismissed "$dismissed" \
		--arg formatted "$formatted" \
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
