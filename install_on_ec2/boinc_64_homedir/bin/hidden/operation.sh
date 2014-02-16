#!/bin/bash

set -o nounset

# This code assumes a compiled boinc >= 7.0.28 in /home/boinc/boinc

# ----- Test user and his homedir -----

if [[ `whoami` != 'boinc' ]]; then
   echo "No running as user boinc -- exiting" >&2; exit 1
fi

# The shell should have the user's home directory in $HOME

MYHOME=$HOME

if [[ ! -d $MYHOME ]]; then
   echo "Directory '$MYHOME' does not exist -- exiting\n" >&2
   exit 1
fi

# ----- Set directories and test them (no need to create, they are created at boinc client start) -----

BINDIR=$MYHOME/boinc/bin
WORKDIR=$MYHOME/work

if [[ ! -d $MYHOME ]]; then
   echo "Directory '$MYHOME' does not exist -- exiting\n" >&2
   exit 1
fi
 
if [[ ! -d $BINDIR ]]; then
   echo "Directory '$BINDIR' does not exist (either boinc is not installed or you need to symlink it) -- exiting\n" >&2
   exit 1
fi

if [[ ! -d $WORKDIR ]]; then
   echo "Directory '$WORKDIR' does not exist -- exiting\n" >&2
   exit 1
fi

# ----- Go to workdir using "pushd" -----

pushd "$WORKDIR" >/dev/null

if [[ $? != 0 ]]; then
   echo "Could not cd to directory '$WORKDIR' -- exiting\n" >&2
   exit 1
fi

# ----- If this script is called "get_tasks", just run that command ----

OP_NAME=

if [[ $0 == get_tasks ]]; then

   CMD="'$BINDIR/boinccmd' --get_tasks"
   echo "Running command: $CMD" >&2
   # eval "$CMD"
   $CMD
   EXIT_VALUE=$?

else

   # ----- Find out what project to manipulate by verifying name of this script -----
   # This script should have been started via a symlink named after the project, so
   # we check "$0" for the project name!
   # The filename (actually a symlink to this script) should be: 
   # {attach|detach}.{project_name}

   BASENAME=`basename $0`
   PROJECT_NAME=`echo $BASENAME | perl -wlne 'print $1 if /^\S+\.(\S+?)$/'`
   OP_NAME=`echo $BASENAME | perl -wlne 'print $1 if /^(\S+)\.\S+?$/'`

   # If the project name does not match any of the known names, an error will be raised later
   # but do a quick check right here,

   if [[ -z $PROJECT_NAME || $PROJECT_NAME == 'sh' || $PROJECT_NAME == 'pl' ]]; then
      echo "Could not determine project name from basename '$BASENAME' -- exiting" >&2
      exit 1
   fi

   if [[ -z $OP_NAME ]]; then
      echo "Could not determine operation name from basename '$BASENAME' -- exiting" >&2
      exit 1
   fi

   # ----- Set project coordinates; edit this as needed -----
   # The weak account key changes if you change the password!!

   declare -A WEAK_ACCOUNT_KEY
   declare -A PROJECT_URL

   WEAK_ACCOUNT_KEY[setiathome]="SETI@HOME_WEAKPK"
   WEAK_ACCOUNT_KEY[einsteinathome]="EINSTEIN@HOME_WEAKPK"
   WEAK_ACCOUNT_KEY[dockingathome]="DOCKING@HOME_WEAKPK"
   WEAK_ACCOUNT_KEY[climateprediction]="CLIMATEPREDICTION_WEAK_PK"

   PROJECT_URL[setiathome]="http://setiathome.berkeley.edu/"
   PROJECT_URL[einsteinathome]="http://einstein.phys.uwm.edu/"
   PROJECT_URL[dockingathome]="http://docking.cis.udel.edu/"
   PROJECT_URL[climateprediction]="http://climateprediction.net/"

   MY_URL="${PROJECT_URL[$PROJECT_NAME]}"

   if [[ -z "$MY_URL" ]]; then
      echo "Project '$PROJECT_NAME' is unknown -- exiting" >&2
      exit 1
   fi

   # ----- Run operation ------

   case $OP_NAME in
      reset|detach|update|suspend|resume|nomorework|allowmorework)
         CMD="'$BINDIR/boinccmd' --project '${PROJECT_URL[$PROJECT_NAME]}' '$OP_NAME'"
         echo "Running command: $CMD" >&2
         eval "$CMD"
         EXIT_VALUE=$?
      ;;
      attach)
         CMD="'$BINDIR/boinccmd' --project_attach '${PROJECT_URL[$PROJECT_NAME]}' '${WEAK_ACCOUNT_KEY[$PROJECT_NAME]}'"
         echo "Running command: $CMD" >&2
         eval "$CMD"
         EXIT_VALUE=$?
      ;;
      *)
         echo "Operation '$OP_NAME' is unknown -- exiting" >&2
         exit 1
   esac
fi

# The exit value 126 means "already attached" and is not considered an error

if [[ $EXIT_VALUE -eq 126 && $OP_NAME == attach ]]; then
   echo "Exit value '126' (already attached), considered as successful" >&2
   exit 0
elif [[ $EXIT_VALUE -eq 0 ]]; then
   exit 0
else
   echo "Exit value of operation is: $EXIT_VALUE -- considered a failure" >&2
   exit $EXIT_VALUE
fi

