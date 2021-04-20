#!/bin/bash
#
# When committing this file to git, but sure to execute this command to make it executable
# git update-index --chmod=+x ./runRaft.sh
#

mode=$1
arguments=$2
raftDefaults=$3
secret=$4
actionPath=$5

if [ "${mode,,}" == "azure" ];
then
  if [ -z "$raftDefaults" ];
  then
    echo "The raftDefaults input must be provided to run against a RAFT Azure deployment"
    exit 1
  fi

  if [ -z "$secret" ];
  then
    echo "The secret input must be provided to run against a RAFT Azure deployment"
    exit 1
  fi

  echo "Starting RAFT job on Azure deployment"
  python "$actionPath"/raft.py  --defaults-context-json "$raftDefaults" --secret "$secret" $arguments
else
  echo "Running RAFT locally"
  export RAFT_LOCAL="raft-action"
  python "$actionPath"/raft_local.py $arguments   
fi
