VER=$1

OUTFILE="/tmp/listoperatorversions4ocpbundle"

if [[ -z "$VER" ]] || ! [[ $VER =~ ^[0-9]+\.[0-9]+ ]]; then
   echo "usage: $0 <ocp_version=4.10|4.11|4.12>" >&2
   exit 1
fi

podman login --get-login registry.redhat.io 2>/dev/null 1>&2
if [ $? -ne 0 ]; then
   echo "Please login first to registry.redhat.io using 'podman login'" >&2
   exit 1
fi

REDHAT_OPERATORS=registry.redhat.io/redhat/redhat-operator-index
CERTIFIED_OPERATORS=registry.redhat.io/redhat/certified-operator-index
COMMUNITY_OPERATORS=registry.redhat.io/redhat/community-operator-index
REDHAT_MARKETPLACE_OPERATORS=registry.redhat.io/redhat/redhat-marketplace-index

CATALOGS=($REDHAT_OPERATORS $CERTIFIED_OPERATORS $COMMUNITY_OPERATORS $REDHAT_MARKETPLACE_OPERATORS)

for catalog in ${CATALOGS[@]}; do
  catalog_name=$(basename -- "$catalog")
  podman run -p50051:50051 --name $catalog_name -d $catalog:v${VER}
  [[ $? -ne 0 ]] && rm ${OUTFILE}_${catalog_name}.txt && continue
  echo "----- $catalog_name -----" >${OUTFILE}_${catalog_name}.txt
  grpcurl -plaintext  localhost:50051 api.Registry.ListBundles | jq -r '(.packageName+" "+.csvName+" "+.channelName)'|sort -V >>${OUTFILE}_${catalog_name}.txt
  podman rm -f $catalog_name
done

