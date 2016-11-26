#!/bin/bash

if [ $# -ne 4 ]; then
  echo "Usage: $0 <Directory> <File Prefix> <Min expected> <Max expected>"
  exit -1
fi

DIRECTORY=$1
FILEPREFIX=$2
FILEMIN=$3
FILEMAX=$4
DEBUGLVL=0

if [ $DEBUGLVL -gt 0 ];then
        echo "Directory: $DIRECTORY"
        echo "Prefix:    $FILEPREFIX"
        echo "Min Files: $FILEMIN"
        echo "Max Files: $FILEMAX"
        find $DIRECTORY -name "$FILEPREFIX" -type f
fi

MYCOUNT=`find $DIRECTORY -name "$FILEPREFIX*" -type f|wc -l`


if [ "$MYCOUNT" -eq "$FILEMIN" -o "$MYCOUNT" -gt "$FILEMIN" -a "$MYCOUNT" -lt "$FILEMAX" -o "$MYCOUNT" -eq "$FILEMAX" ];then
        echo "OK: Found $MYCOUNT files, expected $FILEMIN to $FILEMAX"
        exit 0
else
        echo "ERROR: Found $MYCOUNT files, expected $FILEMIN to $FILEMAX"
        exit 2
fi
