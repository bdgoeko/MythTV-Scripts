#!/bin/bash

# Name: convert.sh
# Description: A script to convert OTA Mpeg recoding to x264 mkv files
#
# Copyright Brian Dolan-Goecke 2012
# Contact Brian Dolan-Goecke @ http://www.goecke-dolan.com/Brian/sendmeail.php

# need to add machine name

#VERSION="0.1.7-bdg-2012"
VERSION="0.1.7-goeko-20140117111915"

# Global Variables
EXIT_STATUS=0
DELETE_SOURCE_FILE=false

if test "${1}" = "-d"
then
  DELETE_SOURCE_FILE=true
  echo "Delete source file turned on!"
  shift
fi

#STATUS_FILE=${HOME}/convert_status.csv
STATUS_FILE=/network_drive/Temp/Video_Conversion/convert_status.csv
Q_FILE=/network_drive/Temp/Video_Conversion/q_file.csv
COMPLETED_FILE=/network_drive/Temp/Video_Conversion/completed_file.csv

COMPLETED_DIR=${HOME}/Completed

if test $# -ge 1
then
  NOT_DONE=true
else
  NOT_DONE=false
fi

while test ${#} -gt 0
do

  EXTENSION=mkv
  infile=${1}
  infilesize=`ls -lH "${infile}" | cut -d\  -f5`
  outfilesize=0
  exitdatetime=0
  file=`basename "${1}"`
  logfile=${file%%.mpg}_${EXTENSION}.log
  #outfile=${file%%.mpg}.mp4
  outfile=${file%%.mpg}.${EXTENSION}

  echo "InFile: \"${infile}\"" | tee -a "${logfile}"
  echo "OutFile: \"${outfile}\"" | tee -a "${logfile}"
  echo "LogFile: \"${logfile}\"" | tee -a "${logfile}"
  startdatetime=`date +%Y%m%d%H%M`
  echo "StartTime: ${startdatetime}" | tee -a "${logfile}"
  echo "\"${file}\",${startdate}" >> ${Q_FILE}
  echo "\"${file}\",start,0,${startdatetime},\"${infile}\",${infilesize},${exitdatetime},\"${outfile}\",${outfilesize}" >> ${STATUS_FILE}

  # VLC
  # /usr/bin/vlc -vvv -I dummy "$infile" --sout "#transcode{vcodec=h264,}:standard{dst=\"$outfile\",access=file}" vlc://quit 2>&1 | tee -a ${logfile}
  
  echo "Working..."
  #ffmpeg -i "${infile}" -vf yadif -acodec copy  "${outfile}" -acodec copy -newaudio 2>&1 | tee -a "${logfile}"
  ffmpeg -i "${infile}" -vf yadif -acodec copy  "${outfile}" -acodec copy -newaudio > "${logfile}" 2>&1
  CONVERT_STATUS=$?
  exitdatetime=`date +%Y%m%d%H%M`
  outfilesize=`ls -lH "${outfile}" | cut -d\  -f5`
  echo "Exit Status from convert: ${CONVERT_STATUS}" | tee -a "${logfile}"
  echo "\"${file}\",exited,${CONVERT_STATUS},${startdatetime},\"${infile}\",\"${infilesize}\",${exitdatetime},\"${outfile}\",${outfilesize}" >> ${STATUS_FILE}
  echo "\"${file}\",exited,${CONVERT_STATUS},${startdatetime},\"${infile}\",${infilesize},${exitdatetime},\"${outfile}\",${outfilesize}" >> ${COMPLETED_FILE}
  echo "Completed Time: ${exitdatetime}" | tee -a "${logfile}"

  if test ${CONVERT_STATUS} -eq 0
  then
    echo "Moving completed file"
    mv "${outfile}" ${COMPLETED_DIR}/
    mv "${logfile}" ${COMPLETED_DIR}/
    if `$DELETE_SOURCE_FILE`
    then
      echo "Deleting source file \"${infile}\"."
      rm "${infile}"
    fi
  fi

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
