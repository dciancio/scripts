### Retrieve all CRC versions sorted by version number
for i in $(curl -sL "https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/crc/" | grep -o -E 'a href="[^\"]+"' | cut -d'"' -f2 | grep -E '/[0-9]{1}.[0-9]{0,2}')
do
basename $i
done | sort -V | while read ver
do
curl -sL "https://mirror.openshift.com/pub/openshift-v4/clients/crc/$ver/release-info.json" | jq -r '.version | ("crcVersion: "+.crcVersion+"   OpenshiftVersion: "+.openshiftVersion)'
done

