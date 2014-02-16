#!/bin/bash

DIR=/home/boinc

# Ask whether to actually wind down

STOPNOW=

read -p "Wind down ....? [Y/N] (default N) : " -t 10 STOPNOW >&2

STOPNOW=`echo "${STOPNOW}" | tr '[:upper:]' '[:lower:]'`

if [[ "${STOPNOW}" == 'yes' || "${STOPNOW}" == 'y' ]]; then
   echo "Continuing...." >&2
else 
   echo "Exiting..." >&2 
   exit 0
fi

NOMOREWORKLIST=`ls $DIR/bin/nomorework*`

if [[ -z $NOMOREWORKLIST ]]; then
   echo "No 'nomorework' commands found at all -- exiting" >&2
   exit 1
fi

for CMD in $NOMOREWORKLIST; do 
   # echo "Running '$CMD'"
   $CMD
   EXITVAL=$?
   if [[ $EXITVAL != 0 ]]; then
      echo "'$CMD' returned with exit value $EXITVAL -- exiting" >&2
      exit 1
   fi
done

echo "Done"



