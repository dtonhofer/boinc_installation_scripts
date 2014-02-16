#!/bin/bash

# ----------
# Run 
#
# sudo install --owner boinc --group boinc --mode 775 --directory /var/www/html/boinc
# sudo ln -s /var/www/html/boinc/composite.html /var/www/html/index.html 
#
# to set up web
#
# Run
#
# /home/boinc/webtransfer/copy_html.sh /var/www/html/boinc
#
# every minute from crontab:
#
# */1 * * * * /home/boinc/webtransfer/copy_html.sh /var/www/html/boinc 2>/dev/null 1>/dev/null
#
# Copy logo using
#
# cp /home/boinc/webtransfer/www_logo.gif /var/www/html/boinc/
# ------

set -o nounset

# How many lines to copy into output

LINE_COUNT=150

# The script is passed the "WEBDIR", which is the directory to which files
# shall be written (apache will pick them up from there). It then grabs the
# tail of the boinc output file from the expected place.

USER=boinc

if [[ `whoami` != $USER ]]; then
  echo "Not running as user '$USER' -- exiting" >&2
  exit 1
fi

MYHOME=/home/$USER
LOGDIR=$MYHOME/logs
SCRIPTDIR=$MYHOME/webtransfer

if [[ ! -d $LOGDIR ]]; then
  echo "WEBDIR '$LOGDIR' does not exist -- exiting" >&2
  exit 1
fi

if [[ ! -d $SCRIPTDIR ]]; then
  echo "WEBDIR '$SCRIPTDIR' does not exist -- exiting" >&2
  exit 1
fi

# --- "WEBDIR" is the target webdirectory, passed on the command line ---

WEBDIR=${1:-''}

if [[ -z $WEBDIR ]]; then
  echo "WEBDIR has not been passed -- exiting" >&2
  exit 1
fi

if [[ ! -d $WEBDIR ]]; then
  echo "WEBDIR '$WEBDIR' does not exist -- exiting" >&2
  exit 1
fi

if [[ ! -x $WEBDIR ]]; then
  echo "WEBDIR '$WEBDIR' is not executable -- exiting" >&2
  exit 1
fi

if [[ ! -w $WEBDIR ]]; then
  echo "WEBDIR '$WEBDIR' is not writeable -- exiting" >&2
  exit 1
fi

# --- Template file used to create "composite.html" ---

TEMPLATE_FILE=$SCRIPTDIR/template.html

if [[ ! -f $TEMPLATE_FILE ]]; then
  echo "The template file '$TEMPLATE_FILE does not exist -- exiting" >&2
  exit 1
fi

# If an error occurs, a text will be written to the datafile

ERROR_MSG=

# --- Find a "freshest logfile" ---

FRESHEST_LOGFILE=`ls -t "$LOGDIR"/out.*.txt | head -1`

if [[ -z $FRESHEST_LOGFILE || ! -f $FRESHEST_LOGFILE ]]; then
   echo "No 'freshest logfile' found in directory '$LOGDIR'" >&2
   ERROR_MSG="No data"
fi

# Make sure the file has been modified not too long ago (i.e. boinc isn't down)
# If it's too old, then do not create a file, resp. destroy an existing one.
# For this, add for example -mmin -600 as criterium.

LOGFILE=`basename "$FRESHEST_LOGFILE"`

FRESHEST_LOGFILE=`find "$LOGDIR" -maxdepth 1 -mmin -600 -name "$LOGFILE"`

if [[ -z $FRESHEST_LOGFILE ]]; then
   echo "No 'freshest logfile' file found at all in directory '$LOGDIR' -- '$FRESHEST_LOGFILE' seems too old" >&2
   ERROR_MSG="No data"
fi

if [[ -z $FRESHEST_LOGFILE || ! -f $FRESHEST_LOGFILE ]]; then
   echo "The file '$FRESHEST_LOGFILE' should exist but it doesn't" >&2
   ERROR_MSG="No data"
fi

# Create the "data file" in /tmp

WHEN=`date +%Y.%m.%d.%H.%M.%S`
DATAFILE="/tmp/data.$WHEN.txt"

if [[ -z $ERROR_MSG ]]; then

   # File found; grab a few lines

   echo "Grabbing data from '$FRESHEST_LOGFILE'..." >&2

   # Use "tac" to reverse the file so that freshest lines are at the top

   tail "-${LINE_COUNT}" "$FRESHEST_LOGFILE" | /usr/bin/tac > "$DATAFILE"

else

   echo "$ERROR_MSG" > "$DATAFILE"

fi

# Make sure only user "boinc" (us) can read that file

chmod 600 "$DATAFILE"

# Check the extract, which now must exist and not be too large.
# If there is a problem, then an "empty composite" is created.

DO_NOT_WANT=

if [[ -z $DO_NOT_WANT && ! -f $DATAFILE ]]; then
  DO_NOT_WANT="'$DATAFILE' is not a regular file or does not exist"
  echo $DO_NOT_WANT >&2
fi

#if [[ -z $DO_NOT_WANT && `wc -l "$DATAFILE" | awk '{print $1}'` -gt 100 ]]; then
#  echo "'$DATAFILE' has too many lines" >&2
#  DO_NOT_WANT="Too many lines"
#fi

#if [[ -z $DO_NOT_WANT && `wc -c "$DATAFILE" | awk '{print $1}'` -gt 10000 ]]; then
#  echo "'$DATAFILE' has too many characters" >&2
#  DO_NOT_WANT="Too many characters"
#fi

if [[ -n $DO_NOT_WANT ]]; then
   echo "Error in processing: $DO_NOT_WANT" > "$DATAFILE"
fi

# File to write to (owned by boinc.boinc, world-readable, referenced as index.html through a symlink)

TO_FILE=$WEBDIR/composite.html

# Create the composite by calling a perl program

HEADER="Boinc logfile at `date`"
perl "$MYHOME/webtransfer/inject.pl" "$TEMPLATE_FILE" "$DATAFILE" "$HEADER" > "$TO_FILE.tmp"
sed --in-place "s/%HOSTNAME%/`hostname`/g" "$TO_FILE.tmp"

/bin/mv "$TO_FILE.tmp" "$TO_FILE"

# Make TO_FILE readable by Apache

chmod 664 "$TO_FILE"

# Delete old datafile

/bin/rm "$DATAFILE"
