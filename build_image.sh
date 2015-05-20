#!/bin/bash

# Build image with Packer

echo "-------------------------------"
echo "Kubestack Packer Image builder:"

### Set CoreOS release channel
LOOP=1
while [ $LOOP -gt 0 ]
do
    VALID_MAIN=0
    echo " "
    echo " CoreOS Release Channel:"
    echo " 1)  Alpha "
    echo " 2)  Beta "
    echo " 3)  Stable "
    echo " "
    echo "Select an option:"

    read RESPONSE
    XX=${RESPONSE:=Y}

    if [ $RESPONSE = 1 ]
    then
        VALID_MAIN=1
        channel="alpha"
        LOOP=0
    fi

    if [ $RESPONSE = 2 ]
    then
        VALID_MAIN=1
        channel="beta"
        LOOP=0
    fi

    if [ $RESPONSE = 3 ]
    then
        VALID_MAIN=1
        channel="stable"
        LOOP=0
    fi

    if [ $VALID_MAIN != 1 ]
    then
        continue
    fi
done
### Set CoreOS release channel

# cd to packer folder
cd packer
#

# get GC project id
GC_PROJECT=$(cat settings.json | grep project_id | head -1 | cut -f2 -d":" | sed 's/"//g' | sed 's/ //g' | sed 's/,//g')

# get latest image name
coreos_image=$(gcloud compute images list --project=$GC_PROJECT | grep -v grep | grep coreos-$channel | awk {'print $1'})

# Let's build the image
packer build -var source_image=$coreos_image -var-file=settings.json kubestack.json

# END OF GAME ...
