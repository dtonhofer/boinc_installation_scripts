#!/bin/bash

set -o nounset

# =========
# Create a tarball named TARGET in WEB_DIR, supposed to be web-accessible, so that it can be pulled down easily
# from a remote machine.
# =========

WEB_DIR=/var/www/html

TARGET=boinc_64.tgz

FROM_DIR=$FOODIR/install_on_ec2/boinc_64_homedir

# --- Cd to the WEB_DIR and delete any existing TARGET file ---

if [[ ! -d $WEB_DIR ]]; then
   echo "Directory $WEB_DIR does not exist -- exiting!" >&2
   exit 1
fi

pushd $WEB_DIR >/dev/null 2>&1

if [[ $? != 0 ]]; then
   echo "Could not cd to '$WEB_DIR' -- exiting" >&2
   exit 1
fi

if [[ -f $TARGET ]]; then   
   echo "File '$WEB_DIR/$TARGET' exists -- removing it!" >&2
   md5sum $WEB_DIR/$TARGET
   /bin/rm "$TARGET"
fi

if [[ $? != 0 ]]; then
   echo "Could not remove file '$WEB_DIR/$TARGET' -- exiting" >&2
   exit 1
fi

# --- Tar the FROM_DIR into the TARGET tarball ---

if [[ ! -d $FROM_DIR ]]; then
   echo "Directory '$FROM_DIR' does not exist -- exiting!" >&2
   exit 1
fi

tar --create --gzip --file=$TARGET --directory=$FROM_DIR .

if [[ $? != 0 ]]; then
   echo "Could not properly run 'tar' -- exiting" >&2
   exit 1
fi

md5sum $WEB_DIR/$TARGET

