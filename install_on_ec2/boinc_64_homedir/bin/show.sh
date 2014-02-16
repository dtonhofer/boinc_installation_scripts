#!/bin/bash

MYHOME=/home/boinc
BINDIR=$MYHOME/boinc/bin

WHAT=${1:-''}

WHAT=`echo "${WHAT}" | tr '[:upper:]' '[:lower:]'`

case "$WHAT" in
   state)
      $BINDIR/boinccmd --get_state
      exit $?
      ;;
   info)
      $BINDIR/boinccmd --get_simple_gui_info
      exit $?
      ;;
   status)
      $BINDIR/boinccmd --get_project_status
      exit $?
      ;;
   *)
      echo "Pass one of: state, info, status" >&2
      exit 1
esac


