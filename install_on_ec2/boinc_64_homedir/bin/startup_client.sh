#!/bin/bash

set -o nounset

# --------
# This script assumes a compiled boinc >= 7.0.28 in /home/boinc/boinc
# --------


# ----- Test user -----

if [[ `whoami` != 'boinc' ]]; then
   echo "No running as user boinc -- exiting" >&2
   exit 1
fi

# The shell should have the user's home in MYHOME

MYHOME=$HOME

# --- Option processing ---

NO_GPUS=
NO_GUI_RPC=
USE_VERBOSE=
USE_TAIL=
PRINT_LOGFILE=

function processOptions {
   local PARAM=
   local UNKNOWN=
   local USE_HELP=
   for PARAM in "$@"; do

      if [[ $PARAM == '--nogpu' || $PARAM == '--nogpus' ]]; then
         NO_GPUS=1
         continue
      fi

      if [[ $PARAM == '--noguirpc' ]]; then
         NO_GUI_RPC=1
         continue
      fi

      if [[ $PARAM == '--verbose' ]]; then
         USE_VERBOSE=1
         continue
      fi

      if [[ $PARAM == '--tail' ]]; then
         USE_TAIL=1
         continue
      fi

      if [[ $PARAM == '--printlogfile' ]]; then
         PRINT_LOGFILE=1
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
  
   if [[ -n $PRINT_LOGFILE && -n $USE_TAIL ]]; then
      echo "Both --printlogfile and --tail specified; use only one!" >&2
      USE_HELP=1
   fi

   if [[ -n $UNKNOWN ]]; then
      echo "Unknown parameters '$UNKNOWN'" >&2
   fi

   if [[ -n $UNKNOWN || -n $USE_HELP ]]; then
      echo "Allowed are:" >&2
      echo "--nogpu(s) - to disable GPU use" >&2
      echo "--noguirpc - to disable GUI RPC (this will make 'boinccmd' ineffective)" >&2
      echo "--verbose  - for more logging (no effect for now)" >&2
      echo "--tail     - to tail the logfile" >&2
      exit 1
   fi

}

processOptions "$@"

# ----- Set directories and test them -----

BINDIR=$MYHOME/boinc/bin
WORKDIR=$MYHOME/work
LOGDIR=$MYHOME/logs

if [[ ! -d $MYHOME ]]; then
   echo "Directory '$MYHOME' does not exist -- exiting" >&2
   exit 1
fi

if [[ ! -d $BINDIR ]]; then
   echo "Directory '$BINDIR' does not exist (either boinc is not installed or you need to symlink it) -- exiting" >&2
   exit 1
fi

if [[ ! -d $WORKDIR ]]; then
   echo "Directory '$WORKDIR' does not exist -- creating it" >&2
   mkdir $WORKDIR
   if [[ $? != 0 || ! -d $WORKDIR ]]; then
      echo "Could not create directory '$WORKDIR' -- exiting" >&2
      exit 1
   fi
fi

if [[ ! -d $LOGDIR ]]; then
   echo "Directory '$LOGDIR' does not exist -- creating it" >&2
   mkdir $LOGDIR
   if [[ $? != 0 || ! -d $LOGDIR ]]; then
      echo "Could not create directory '$LOGDIR' -- exiting" >&2
      exit 1
   fi
fi

# ---- Does the BOINC client command exist? ------

BOINC_CLIENT=$BINDIR/boinc_client

if [[ ! -x $BOINC_CLIENT ]]; then
   echo "Boinc client '$BOINC_CLIENT' does not exist or is not executable -- exiting" >&2
   exit 1
fi

# ----- Change to "work" directory, which is also the directory containing workfiles -----

pushd $WORKDIR > /dev/null

if [[ $? != 0 ]]; then
   echo "Could not cd to directory '$WORKDIR' -- exiting" >&2
   exit 1
fi

# ----- Determine logfile name ------

WHEN=`date +%Y.%m.%d.%H.%M.%S`
LOGFILE="$LOGDIR/out.$WHEN.txt"

# ----- If "cc_config.xml" exists, move it to the work directory

CC_CONFIG=$MYHOME/cc_config.xml

if [[ -f $CC_CONFIG ]]; then
   /bin/mv "$CC_CONFIG" "$WORKDIR"
fi

# ----- Start client -----

# DO NOT use "--daemon" as this will cause NO OUTPUT to be written (it seems to go to syslog though...?)
# DO NOT use "--fetch_minimal_work" as will cause a single workunit to be downloaded PER PROJECT, leaving most CPUs idle

# ~/work/cc_config.xml contains the debugging flags

# "nohup the process" and put it in the background; it then detaches from the shell when the shell exits (see also "disown", which is basically the same)
# Do NOT put the arguments into quotes so that they "disappear" if empty

#RUNCPUB=--run_cpu_benchmarks
RUNCPUB=

nohup "$BOINC_CLIENT" $NO_GPUS $NO_GUI_RPC $RUNCPUB > "$LOGFILE" 2>&1 &

BOINC_PID=$!
RETVAL=$?

if [[ $RETVAL != 0 ]]; then
   echo "Problem starting BOINC - returnvalue was $RETVAL" >&2
   exit 1
else
   echo "Boinc started; PID $BOINC_PID" >&2
fi

# ----- Print out name of logfile to stdout and exit with 0 if so demanded ----

if [[ -n $PRINT_LOGFILE ]]; then
   echo $LOGFILE
   exit 0
fi

# ----- If tail demanded, replace this process by a tail -----

if [[ -n $USE_TAIL ]]; then
   exec tail -f "$LOGFILE"
fi


