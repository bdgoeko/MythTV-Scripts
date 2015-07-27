#!/bin/bash

# Name: conver2mkv.sh
# Description: A script to convert OTA Mpeg recoding to x264 mkv files
#   the grand plan was to build a multi-machine conversion "system"
#   machines to dip into the queue of videos to be converted
#   and grab one work through it and then go on....
#   But this is a start, and converts files.
#
# Note about ffmpeg on ubunutu
#http://askubuntu.com/questions/432542/is-ffmpeg-missing-from-the-official-repositories-in-14-04

# Copyright Brian Dolan-Goecke 2012,2015
# Contact Brian Dolan-Goecke @ http://www.goecke-dolan.com/Brian/sendmeail.php

# 
# need to add machine name

# Old version number... 
VERSION="0.1.7-goeko-20140117111915"

# Global Variables
EXIT_STATUS=0
DELETE_SOURCE_FILE=false

WORKING_DIR=${HOME}/convert2mkv

if test "${1}" = "-d"
then
  DELETE_SOURCE_FILE=true
  echo "Delete source file turned on!"
  shift
fi

# Some files to keeps stats... not really that useful.
STATUS_FILE=${WORKING_DIR}/Stats/convert_status.csv
Q_FILE=${WORKING_DIR}/Stats/q_file.csv
COMPLETED_FILE=${WORKING_DIR}/Stats/completed_file.csv

COMPLETED_DIR=${WORKING_DIR}/Completed

if test $# -ge 1
then
  NOT_DONE=true
else
  NOT_DONE=false
fi

# Okay go do some work.
while test ${#} -gt 0
do

  EXTENSION=mkv
  INFILE=${1}
  INFILESIZE=`ls -lH "${infile}" | cut -d\  -f5`
  OUTFILESIZE=0
  EXITDATETIME=0
  FILE=`basename "${1}"`
  LOGFILE=${file%%.mpg}_${EXTENSION}.log
  #OUTFILE=${file%%.mpg}.mp4
  OUTFILE=${file%%.mpg}.${EXTENSION}

  echo "InFile: \"${INFILE}\"" | tee -a "${LOGFILE}"
  echo "OutFile: \"${OUTFILE}\"" | tee -a "${LOGFILE}"
  echo "LogFile: \"${LOGFILE}\"" | tee -a "${LOGFILE}"
  STARTDATETIME=`date +%Y%m%d%H%M`
  echo "StartTime: ${STARTDATETIME}" | tee -a "${LOGFILE}"
  echo "\"${file}\",${STARTDATETIME}" >> ${Q_FILE}
  echo "\"${file}\",start,0,${STARTDATETIME},\"${INFILE}\",${INFILESIZE},${EXITDATETIME},\"${OUTFILE}\",${OUTFILESIZE}" >> ${STATUS_FILE}

  # VLC
  # /usr/bin/vlc -vvv -I dummy "$infile" --sout "#transcode{vcodec=h264,}:standard{dst=\"$outfile\",access=file}" vlc://quit 2>&1 | tee -a ${LOGFILE}
  
  echo "Converting ${INFILE} to ${OUTFILE}..."
  #ffmpeg -i "${INFILE}" -vf yadif -acodec copy  "${OUTFILE}" -acodec copy -newaudio 2>&1 | tee -a "${LOGFILE}"
  ffmpeg -i "${INFILE}" -vf yadif -acodec copy  "${OUTFILE}" -acodec copy -newaudio > "${LOGFILE}" 2>&1
  CONVERT_STATUS=$?
  EXITDATETIME=`date +%Y%m%d%H%M`
  OUTFILESIZE=`ls -lH "${OUTFILE}" | cut -d\  -f5`
  echo "Exit Status from convert: ${CONVERT_STATUS}" | tee -a "${LOGFILE}"
  echo "\"${FILE}\",exited,${CONVERT_STATUS},${STARTDATETIME},\"${INFILE}\",${INFILESIZE},${EXITDATETIME},\"${OUTFILE}\",${OUTFILESIZE}" >> ${STATUS_FILE}
  echo "\"${FILE}\",exited,${CONVERT_STATUS},${STARTDATETIME},\"${INFILE}\",${INFILESIZE},${EXITDATETIME},\"${OUTFILE}\",${OUTFILESIZE}" >> ${COMPLETED_FILE}
  echo "Completed Time: ${EXITDATETIME}" | tee -a "${logfile}"

  if test ${CONVERT_STATUS} -eq 0
  then
    echo "Moving completed file"
    mv "${OUTFILE}" ${COMPLETED_DIR}/
    mv "${LOGFILE}" ${COMPLETED_DIR}/
    if `$DELETE_SOURCE_FILE`
    then
      echo "Deleting source file \"${INFILE}\"."
      rm "${INFILE}"
    fi
  fi

  #Give someone a chance to break out of this.
  read -t1 ANYTHING

  if test -n "${ANYTHING}"
  then
    case ${ANYTHING} in
      [qQ]|[xX]|[qQ][uU][iI][tT]|[eE][xX][iI][tT] )
        NOT_DONE=false
        echo "Exiting at user request"
      ;;
      *)
        echo "I don't understand \"${ANYTHING}\", continuing..."
        ANYTHING=""
      ;;
    esac
  fi

  if `$NOT_DONE`
  then
    shift
    if test $# -ge 1
    then
      echo "Going to next file \"${1}\""
      NOT_DONE=true
    else
      echo "All Done."
      NOT_DONE=false
    fi
  fi 

done

exit ${EXIT_STATUS}
