#!/bin/bash

FILE=$1
[ -z $FILE ] && { echo "Can't open file $FILE" >&2; exit 1; }

exec &>/tmp/cpushow.$$
echo "proc physcpuid siblings coreid corespersocket"
egrep "processor|physical id|siblings|core id|cpu cores" $FILE | awk -F": " '{printf ("%4d", $2)}' | xargs -n5

exec &>$(tty)
column -t /tmp/cpushow.$$ >&1
rm -f /tmp/cpushow.$$
