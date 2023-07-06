#!/bin/bash

FILE=$1
[ -z $FILE ] && { echo "Can't open file $FILE" >&2; exit 1; }

echo -n -e "\nPHYSICAL_ID| " ;cat $FILE |grep -e 'physical id'| awk '{ printf("%3s|",$4 ); } END { printf( "\n" ); }'
echo -n -e "\nCPU_CORES| ";cat $FILE |grep -e 'cpu cores'| awk '{ printf( "%3s|",  $4 ); } END { printf( "\n" ); }'
echo -n -e "\nSIBLINGS| ";cat $FILE |grep -e 'siblings'| awk '{ printf( "%3s|",  $3 ); } END { printf( "\n" ); }'
echo -n -e "\nPROCESSOR_NO| ";cat $FILE |grep -e 'processor'| awk '{ printf( "%3s|",  $3 ); } END { printf( "\n" ); }'

