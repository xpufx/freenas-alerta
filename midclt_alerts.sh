#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
#set -o posix # this doesn't cause errors when non-posix things are used?
#set -o xtrace # or run bash -x but that ignore the shebang

source ./.secrets

#constants#
ENVIRONMENT="FreeNAS"
ORIGIN="FreeNAS"
SERVICE="FreeNAS Alert"
DEBUG=true


declare -A LEVEL
LEVEL[INFO]=informational
LEVEL[WARNING]=warning
LEVEL[NOTICE]=minor
LEVEL[ERROR]=major
LEVEL[CRITICAL]=critical
LEVEL[ALERT]=major
LEVEL[EMERGENCY]=critical		





function debug {
    if [ ! -z "$DEBUG" ]
    then
        echo "$*"
    fi
}
# get the number of alerts
num=$( midclt call alert.list | jq length )

for (( i=0; i<=$num-1; i++ ))
do
	debug Record# ${i}

	alerts=$(midclt call alert.list | jq  ".[$i]")
	debug ${alerts}

	uuid="$(jq -r '.uuid' <<< ${alerts})"
	source="$(jq -r '.klass' <<< ${alerts})"
	node="$(jq -r '.node' <<< ${alerts})"
	dismissed="$(jq -r '.dismissed' <<< ${alerts})"
	level=${LEVEL[$(jq -r '.level' <<< ${alerts})]}
	formatted="$(jq -r '.formatted' <<< ${alerts} | jq -sR)"
	

	JSON='{ "environment": "'$ENVIRONMENT'", "event": "'$source'", "origin": "'$ORIGIN'", "resource": "'$node'", "service": [ "'$SERVICE'" ], "severity": "'$level'", "text": '$formatted', "type": "exceptionAlert" }'
	debug ${JSON} |jq -r .

	debug calling alerta
	curl -XPOST ${ALERTA_ENDPOINT} \
	-H 'Authorization: Key '${ALERTA_KEY}'' \
	-H 'Content-type: application/json' \
	-d "${JSON}"


	echo dismissed on freenas: ${dismissed}
	echo enter to continue ...
	read input

done






# TODO
# handle "dismissed" (push OK)
