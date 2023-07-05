#!/bin/bash

###
# Script pre-requisites:
# 1) JQ: https://stedolan.github.io/jq/download/
# 2) OCM cli: https://access.redhat.com/articles/6114701
# 3) OCM support cli plugin: https://source.redhat.com/groups/public/ocm_team/ocm_blog/ocm_support_cli
###

EBSACCTID=$1
STATUS=$2
DT=$(date "+%Y%m%d")
CSVFILE="${DT}_clusters_${EBSACCTID}.csv"

if ! [[ $EBSACCTID =~ ^[[:digit:]]+$ ]]; then
  echo "usage: $0 <ebs_account_id>" >&2
  exit 1
fi
if [[ "$STATUS" != "--all" ]] && [[ "$STATUS" != "" ]]; then
  echo "usage: $0 <ebs_account_id> [blank | --all = all clusters: active,stale,archived...]" >&2
  exit 1
fi

# Validate ebs_account_id entered
ORGID=$(ocm list organizations --parameter search="ebs_account_id=$EBSACCTID" --columns id | tail -n +2)
if [ "$ORGID" = "" ]; then
  echo "Unknown ebs_account_id entered!" >&2
  exit 1
fi

if [[ "$STATUS" = "--all" ]]; then
  CONDITION=""
else
  CONDITION="Status!='Archived'"
fi

rm -f $CSVFILE
IFS=$'\n'
echo "Cluster Display Name|Cluster ID|Status|Created|Plan|Provider|Region|Version|CPU Total|Subscription CPU Total|Compute Nodes|System Units|Usage|Support Level|Last Telemetry Date|Subscription ID" >>$CSVFILE
#for i in $(ocm support get organizations $ORGID --fetch-subscriptions | jq -r '.[]|.subscriptions[]|select(.status != "Archived")|.href'); do
for i in $(ocm support get subs $ORGID ${CONDITION} | jq -r '.[]|.href'); do
  echo "----- $i"
  ocm get $i | jq -r 'if (.status == "Active" and .plan.id=="OCP") then (.display_name+"|"+.external_cluster_id+"|"+.status+"|"+(.created_at[:19]|strptime("%Y-%m-%dT%H:%M:%S")|strftime("%Y-%m-%d"))+"|"+.plan.id+"|"+.cloud_provider_id+"|"+.region_id+"|"+.metrics[].openshift_version+"|"+(.cpu_total|tostring)+"|"+(.metrics[].subscription_cpu_total|tostring)+"|"+(.metrics[].nodes.compute|tostring)+"|"+.system_units+"|"+.usage+"|"+.support_level+"|"+.last_telemetry_date+"|"+.href) elif (.status != "Active") then (.display_name+"|"+.external_cluster_id+"|"+.status+"|"+(.created_at[:19]|strptime("%Y-%m-%dT%H:%M:%S")|strftime("%Y-%m-%d"))+"|"+.plan.id+"|"+.cloud_provider_id+"|"+"|"+"|"+"|"+"|"+"|"+.system_units+"|"+.usage+"|"+.support_level+"|"+.last_telemetry_date+"|"+.href) else empty end' >>$CSVFILE
done

# Calculate cores and subs for active clusters
CORESALL=0
CORESPRM=0
CORESSTD=0
CORESSUP=0
CORESEVA=0
CORESNON=0
TOTALL=0
TOTPRM=0
TOTSTD=0
TOTSUP=0
TOTEVA=0
TOTNON=0
for i in $(cat $CSVFILE | grep "Active"); do
  PLAN=$(echo $i | awk -F"|" '{print $5}')
  SUBCPU=$(echo $i | awk -F"|" '{print $10}')
  SLA=$(echo $i | awk -F"|" '{print $14}')
  [ "$SLA" = "Premium" ] && TOTPRM=$(( $TOTPRM + 1 )) && [[ "$PLAN" == "OCP" ]] && CORESPRM=$(( $CORESPRM + $SUBCPU ))
  [ "$SLA" = "Standard" ] && TOTSTD=$(( $TOTSTD + 1 )) && [[ "$PLAN" == "OCP" ]] && CORESSTD=$(( $CORESSTD + $SUBCPU ))
  [ "$SLA" = "Self-Support" ] && TOTSUP=$(( $TOTSUP + 1 )) && [[ "$PLAN" == "OCP" ]] && CORESSUP=$(( $CORESSUP + $SUBCPU ))
  [ "$SLA" = "Eval" ] && TOTEVA=$(( $TOTEVA + 1 )) && [[ "$PLAN" == "OCP" ]] && CORESEVA=$(( $CORESEVA + $SUBCPU ))
  [ "$SLA" = "None" ] && TOTNON=$(( $TOTNON + 1 )) && [[ "$PLAN" == "OCP" ]] && CORESNON=$(( $CORESNON + $SUBCPU ))
  TOTALL=$(( $TOTALL + 1 )) && [[ "$PLAN" == "OCP" ]] && CORESALL=$(( $CORESALL + $SUBCPU ))
done

printf "\n\n" >> $CSVFILE
printf "=================================\n" >>$CSVFILE
printf "=       ACTIVE CLUSTERS         =\n" >>$CSVFILE
printf "=================================\n" >>$CSVFILE
printf "Type         Clusters       Cores\n" >>$CSVFILE
printf "=================================\n" >>$CSVFILE
printf "Premium:        %5d       %5d\n" $TOTPRM $CORESPRM >>$CSVFILE
printf "Standard:       %5d       %5d\n" $TOTSTD $CORESSTD >>$CSVFILE
printf "Self-Support:   %5d       %5d\n" $TOTSUP $CORESSUP >>$CSVFILE
printf "Evaluation:     %5d       %5d\n" $TOTEVA $CORESEVA >>$CSVFILE
printf "Expired:        %5d       %5d\n" $TOTNON $CORESNON >>$CSVFILE
printf "=================================\n" >>$CSVFILE
printf "Total           %5d       %5d\n" $TOTALL $CORESALL >>$CSVFILE

