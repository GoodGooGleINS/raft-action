#!/bin/bash
#
# When committing this file to git, but sure to execute this command to make it executable
# git update-index --chmod=+x ./copyLogFiles.sh
#

mode=$1
logDirectory=$2
actionPath=$3
workspace=$4

if [ "${mode,,}" == "local" ];
then
  if [ -n "$logDirectory" ];
  then
    echo "Copying log files to $logDirectory"
    cp -r "$actionPath"/local/storage/  "$logDirectory" 
  else
    echo "Copying log files to /.raft"
    cp -r "$actionPath"/local/storage/ "$workspace"/.raft 
  fi
fi