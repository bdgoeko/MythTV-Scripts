#!/bin/bash

# Script to dump info about show
VERSION=""
EXIT_STATUS=0

VERBOSE=/bin/false

# should get this somewhere else ? but where from ? 
#mythdb info
MythDBServer=
MythDBUser="mythtv"
MythDBPass=""
MythDB="mythconverg"

MIM_DUMP_FILECNT=38 # there were 39 lines as of 20110823

if test -z "${MythDBServer}" ; then
  echo "MythDBServer not set."
  exit 132
fi
if test -z "${MythDBUser}" ; then
  echo "MythDBUser not set."
  exit 132
fi
if test -z "${MythDBPass}" ; then
  echo "MythDBPass not set."
  exit 132
fi

# if the values aren't set we should try and dig it out of /etc/mythtv/config.xml
#if it exists

if test $# -lt 1
then
  echo "need to spedify an Program ID or Basename"
  exit 129
fi

SHOW_ID=$1
${VERBOSE} && echo "Working on '${SHOW_ID}'"

if test "${SHOW_ID:0:2}" == "EP"
then 
  ${VERBOSE} && echo "Looking for Program ID \"${SHOW_ID}\""
  SQL_SEARCH="programid = '${SHOW_ID}'"
else 
  # a file name we need to convert to basename ?
  #strip extension.
  TEMP=`echo ${SHOW_ID} | cut -d. -f1`
  #update show_id with new info
  SHOW_ID=${TEMP}
  SQL_SEARCH="basename LIKE '${SHOW_ID}%'"
  ${VERBOSE} && echo "Looking for basename LIKE \"${SHOW_ID}\""
  ## pull apart title to get chanid && starttime ? 
  # 1021_20140902120000.*
  #ie  chanid = '1021' and starttime = '2014-09-02 12:00:00';
  # then could go after either recoreded or oldrecoreded 
fi

#MySQL [mythconverg]> select * from recorded where basename LIKE '1021_201409021%' \G
#mysql --user=mythtv -h 10.1.1.46 --password=yT8Zr2Ow mythconverg

#set the output file name, and make sure we don't clobber a file
DUMP_FILE="${SHOW_ID}.text"
if test -f "${DUMP_FILE}"; then
  echo "error file '${DUMP_FILE}' exists!"
  echo "Exiting."
  exit 131
fi

echo "SELECT * from recorded WHERE ${SQL_SEARCH} \G" | mysql -h $MythDBServer --user=$MythDBUser --password=$MythDBPass ${MythDB} > "${DUMP_FILE}"
FILE_DUMP_STATUS=$? # Not quite sure what that will be, but we will get it anyway

DUMP_FILE_LINECNT=`wc -l "${DUMP_FILE}" | cut -d\  -f1`
${VERBOSE} && echo "Dump Status '${FILE_DUMP_STATUS}'"

# Make sure we have something in the record dump from the database
if test "${DUMP_FILE_LINECNT}" -lt "${MIM_DUMP_FILECNT}"
then
  echo "Error, database info dump file \"${DUMP_FILE}\" less than ${MIM_DUMP_FILECNT}"
  echo "SQL comand retured ${FILE_DUMP_STATUS}"
  exit 130 
fi

${VERBOSE} && echo "Done with ${PROG_ID}"
${VERBOSE} && echo "ALL Done"

exit ${EXIT_STATUS}
