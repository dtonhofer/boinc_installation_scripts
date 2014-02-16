#!/bin/bash

MYHOME=/home/boinc
BINDIR=$MYHOME/boinc/bin

# This will try to connect over port 31416 by default
# But we only get error messages....
# $BINDIR/boinccmd --quit

EXECUTABLE=$BINDIR/boinc_client

PID=`pidof "$EXECUTABLE"`

if [[ $? == 0 ]]; then
  kill $PID
  exit $?
else
  echo "No boinc_client '$EXECUTABLE' found" >&2
  exit 1
fi

exit $?


