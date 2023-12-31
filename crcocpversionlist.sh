#!/bin/bash

### Retrieve all CRC versions sorted by version number
curl -sL "https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/crc/" | grep href | sed 's/.*href="//' | sed 's/".*//' | egrep '/[0-9].*' | cut -d"/" -f8 | sort -V | while read ver
do
curl -sL "https://mirror.openshift.com/pub/openshift-v4/clients/crc/$ver/release-info.json" | jq -r '.version | ("crcVersion: "+.crcVersion+"   openshiftVersion: "+.openshiftVersion)'
done

