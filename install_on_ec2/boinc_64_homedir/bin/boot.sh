#!/bin/bash

# ---
# Do not start the client if "SKIP_INIT" (one assume it is already running in that case)
# ---

SKIP_INIT=
ATTACH_ALL=

function processOptions {
   local PARAM=
   local UNKNOWN=
   local USE_HELP=
   for PARAM in "$@"; do

      if [[ $PARAM == '--skipinit' ]]; then
         SKIP_INIT=1
         continue
      fi

      if [[ $PARAM == '--attachall' ]]; then
         ATTACH_ALL=1
         continue
      fi

      if [[ $PARAM == '--help' ]]; then
         USE_HELP=1
         continue
      fi

      # Otherwise an unknown parameter

      if [[ -n $UNKNOWN ]]; then
         # Add a separator to the non-empty UNKNOWN...
         UNKNOWN="$UNKNOWN,"
      fi
      # Now add the unknown parameter
      UNKNOWN="${UNKNOWN}${PARAM}"

   done

   if [[ -n $UNKNOWN ]]; then
      echo "Unknown parameters '$UNKNOWN'" >&2
   fi

   if [[ -n $UNKNOWN || -n $USE_HELP ]]; then
      echo "Allowed are:" >&2
      echo "--skipinit  - to skip BOINC client startup (assume BOINC already running)" >&2
      echo "--attachall - to attach to all projects for which a bin/attach* file can be found w/o user interaction" >&2
      exit 1
   fi

}

processOptions "$@"

# ---
# Start the BOINC client
# ---

if [[ -z $SKIP_INIT ]]; then

   echo "Starting client..."

   STARTUP_CMD="$HOME/bin/startup_client.sh"

   if [[ ! -x $STARTUP_CMD ]]; then
      echo "The command '$STARTUP_COMMAND' does not exist -- exiting" >&2
      exit 1
   fi

   # STARTUP_COMMAND is supposed to print the logfile name on STDOUT

   LOGFILE=`$STARTUP_CMD --printlogfile`
   EXITVAL=$?

   if [[ $EXITVAL != 0 ]]; then
      echo "'$STARTUP_CMD' returned with exit value $EXITVAL -- exiting" >&2
      exit 1
   fi

   if [[ ! -f $LOGFILE ]]; then
      echo "Logfile '$LOGFILE' given by '$STARTUP_CMD' does not exist -- exiting" >&2
      exit 1
   fi

   echo "Waiting for 'Initialization completed' to show up in '$LOGFILE' ..."

   I=0
   # This can take a minute or so... 60 x 1s
   while [[ $I -lt 60 ]]; do
      echo -n "."
      sleep 1
      RESULT=`tail --lines=10 "$LOGFILE" | grep "Initialization completed"`
      if [[ -n $RESULT ]]; then
         I=1000
      else
         I=$(($I + 1))
      fi
      RUNNING=`tail --lines=10 "$LOGFILE" | grep "Another instance of BOINC is running"`
      if [[ -n $RUNNING ]]; then
         echo "Another instance of BOINC seems to be running, run this script again with '--skipinit' -- exiting" >&2
         exit 1
      fi
   done

   echo

   if [[ $I -lt 1000 ]]; then
      echo "String 'Initialization completed' does not show up in logfile '$LOGFILE' -- exiting" >&2
      exit 1
   fi

   echo "Found 'Initialization completed' in logfile!"

fi

# Attach projects by running the symlinks named after the operation

ATTACHLIST=`ls $HOME/bin/attach.*`

if [[ -z $ATTACHLIST ]]; then
   echo "No attach commands found at all -- exiting" >&2
   exit 1
fi

for CMD in $ATTACHLIST; do

   ATTACH=
   BASECMD=`basename "$CMD"`

   if [[ -z $ATTACH_ALL ]]; then
      # Do not timeout using option "-t 10" when asking user...
      read -p "Attach using '$BASECMD' [Y/N] ? (default Y) : " ATTACH >&2
      ATTACH=`echo "$ATTACH" | tr '[:upper:]' '[:lower:]'`
   else
      ATTACH=yes
   fi

   if [[ "${ATTACH}" == 'yes' || "${ATTACH}" == 'y' || -z ${ATTACH} ]]; then
      echo "Attaching using '$BASECMD' ..." >&2
      $CMD
      EXITVAL=$?
      if [[ $EXITVAL != 0 ]]; then
         echo "'$CMD' returned with exit value $EXITVAL -- exiting" >&2
         exit 1
      fi
   fi

done

echo "Done"

