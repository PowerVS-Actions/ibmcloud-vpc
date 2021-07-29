#!/bin/bash

: '
    Copyright (C) 2021 IBM Corporation
    Rafael Sene <rpsene@br.ibm.com> - Initial implementation.
'

# Trap ctrl-c and call ctrl_c()
trap ctrl_c INT

function ctrl_c() {
    echo "Bye!"
    exit 0
}

function check_dependencies() {

    DEPENDENCIES=(ibmcloud curl sh wget jq)
    check_connectivity
    for i in "${DEPENDENCIES[@]}"
    do
        if ! command -v "$i" &> /dev/null; then
            echo "$i could not be found, exiting!"
            exit
        fi
    done
}

function check_connectivity() {

    if ! curl --output /dev/null --silent --head --fail http://cloud.ibm.com; then
        echo "ERROR: please, check your internet connection."
        exit 1
    fi
}

function authenticate() {

    local APY_KEY="$1"

    if [ -z "$APY_KEY" ]; then
        echo "API KEY was not set."
        exit
    fi
    ibmcloud login --no-region --apikey "$APY_KEY" > /dev/null 2>&1
}

function get_vpc(){

    IBMCLOUD_ID=$1
    IBMCLOUD_NAME=$2

    IBMCLOUD_REGIONS=($(ibmcloud regions --output JSON | jq -r '.[].Name'))

    for icr in "${IBMCLOUD_REGIONS[@]}"; do
        ibmcloud target -r "$icr" > /dev/null 2>&1
	    VPCS=($(ibmcloud is vpcs --all-resource-groups --json | jq -r '.[] | "\(.id),\(.name),\(.created_at)"'))

	    for vpc in "${VPCS[@]}"; do
            if [ ! -z "$vpc" ]; then
                VPC_CREATION_DATE=$(echo $vpc | awk -F ',' '{print $3}')
                Y=$(echo "$VPC_CREATION_DATE" | awk -F 'T' '{print $1}' | awk -F '-' '{print $1}')
                M=$(echo "$VPC_CREATION_DATE" | awk -F 'T' '{print $1}' | awk -F '-' '{print $2}' | sed 's/^0*//')
                D=$(echo "$VPC_CREATION_DATE" | awk -F 'T' '{print $1}' | awk -F '-' '{print $3}' | sed 's/^0*//')
                AGE=$(python3 -c "from datetime import date as d; print(d.today() - d(int($Y),int($M),int($D)))" | awk -F ',' '{print $1}')
                AGE=$(echo "$AGE" | tr -d " days")
	            if [[ "$AGE" == "0:00:00" ]]; then
		            AGE="0"
	            fi
                echo "$IBMCLOUD_ID,$IBMCLOUD_NAME,$icr,$vpc,$AGE" >> "$(pwd)"/vpc.log
            fi
	    done
    done
}

function run (){
	ACCOUNTS=()
	while IFS= read -r line; do
		clean_line=$(echo "$line" | tr -d '\r')
		ACCOUNTS+=("$clean_line")
	done < ./cloud_accounts

    rm -f "$(pwd)"/vpc.log
    rm -f "$(pwd)"/all.csv

	for ac in "${ACCOUNTS[@]}"; do
		IBMCLOUD=$(echo "$ac" | awk -F "," '{print $1}')
		IBMCLOUD_ID=$(echo "$IBMCLOUD" | awk -F ":" '{print $1}')
		IBMCLOUD_NAME=$(echo "$IBMCLOUD" | awk -F ":" '{print $2}')
		API_KEY=$(echo "$ac" | awk -F "," '{print $2}')

		if [ -z "$API_KEY" ]; then
		    echo
			echo "ERROR: please, set your IBM Cloud API Key."
			echo "		 e.g ./vms-age.sh API_KEY"
			echo
			exit 1
		else
			check_dependencies
			check_connectivity
			authenticate "$API_KEY"
            		get_vpc "$IBMCLOUD_ID" "$IBMCLOUD_NAME"
		fi
	done
    mv "$(pwd)"/vpc.log "$(pwd)"/all.csv
    awk 'NF' ./*.csv
}

run "$@"
