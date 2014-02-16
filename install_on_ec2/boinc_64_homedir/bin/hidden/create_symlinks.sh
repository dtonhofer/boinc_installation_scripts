#!/bin/bash

# ----- Set directories and test them -----

MYHOME=/home/boinc
BINDIR=$MYHOME/bin

if [[ ! -d $MYHOME ]]; then
   echo "Directory '$MYHOME' does not exist -- exiting\n" >&2
   exit 1
fi
 
if [[ ! -d $BINDIR ]]; then
   echo "Directory '$BINDIR' does not exist (either boinc is not installed or you need to symlink it) -- exiting\n" >&2
   exit 1
fi

# ----- Go to bindir using "pushd" -----

pushd "$BINDIR" >/dev/null

if [[ $? != 0 ]]; then
   echo "Could not cd to directory '$BINDIR' -- exiting\n" >&2
   exit 1
fi

# ----- Run operation! ------

for P in "einsteinathome" "setiathome" "dockingathome"; do 
   for OP in "attach" "detach" "reset" "update" "suspend" "resume" "nomorework" "allowmorework"; do 
      SYMLINK="${OP}.${P}"
      if [[ -L "${SYMLINK}" ]]; then
        /bin/rm "${SYMLINK}"
      fi
      ln -s hidden/operation.sh "${SYMLINK}"
   done
done

# ----- Go back to where you were -----

popd >/dev/null

