#!/bin/bash

OPTION1=$1
OPTION2=$2

## Report based on a must-gather or live cluster

if [[ "$OPTION1" != "--live" ]] && [[ "$OPTION1" != "--must-gather" ]] && [[ "$OPTION2" != "--log" ]]; then
  printf "usage: $0 [--live | --must-gather] [--log]\n" >&2 && exit 1
fi

if [[ "$OPTION1" = "--live" ]]; then
  OCWHOAMI=$(oc whoami 2>/dev/null)
  if [[ -z "$OCWHOAMI" ]]; then
    printf "Live option requires that OC login user context to be set. Ensure the user has cluster-admin permissions.\n" >&2 && exit 1
  fi
  CMD="oc"
  printf "Using this oc login user context:\n" 
  printf "API URL: %s   USER: %s\n" $(oc whoami --show-server) $(oc whoami)
fi

if [[ "$OPTION1" = "--must-gather" ]]; then
  omc use | grep 'must-gather: ""' && printf "Must-gather option requires configuring a must-gather to use with omc (https://github.com/gmeghnag/omc).\n" >&2 && exit 1
  CMD="omc"
  printf "Using this omc must-gather report:\n" 
  $CMD use
fi

echo ""
read -p "Would you like to continue (Y/y) or set another user context for oc or omc (N/n)? " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  exit 0
fi

if [[ "$OPTION2" = "--log" ]]; then
  exec &>ocp4clusterinfo.log
fi

# OCP cluster info
OCPVER=$($CMD get clusterversion -o=jsonpath={.items[*].status.desired.version})
OCPCLUSTERID=$($CMD get clusterversion -o=jsonpath={.items[*].spec.clusterID})
printf "\nCluster info:\n"
printf "OCP version   :  ${OCPVER}\n"
printf "OCP cluster ID:  ${OCPCLUSTERID}\n"

# OCP node info
printf "\nNode details:\n"
printf "\nMaster nodes:\n"
(echo "NAME|CPU|MEMORY|ROLES"; $CMD get nodes | grep master | awk '{print $1" "$3}' | while read node role;  do echo "$($CMD get node $node -o json | jq -r '(.metadata.name+"|"+.status.capacity.cpu+"|"+.status.capacity.memory)')|$role" ; done ) | column -s"|" -t 
printf "\nWorker nodes:\n"
(echo "NAME|CPU|MEMORY|ROLES"; $CMD get nodes | grep worker | grep -v infra | awk '{print $1" "$3}' | while read node role;  do echo "$($CMD get node $node -o json | jq -r '(.metadata.name+"|"+.status.capacity.cpu+"|"+.status.capacity.memory)')|$role"; done ) | column -s"|" -t
printf "\nInfra nodes:\n"
(echo "NAME|CPU|MEMORY|ROLES"; $CMD get nodes | grep infra | awk '{print $1" "$3}' | while read node role;  do echo "$($CMD get node $node -o json | jq -r '(.metadata.name+"|"+.status.capacity.cpu+"|"+.status.capacity.memory)')|$role"; done ) | column -s"|" -t

 
