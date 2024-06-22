#!/bin/bash

# Main executables with params from ENV
HPT="hpt -c ${FTN_HPT_CONFIG}"
BINKD="binkd -n ${FTN_BINKD_UPLINKS_POLL} ${FTN_BINKD_CONFIG}"
RNTRACK="rntrack -c ${FTN_RNTRACK_CONFIG}"
SQPACK="sqpack -c ${FTN_HPT_CONFIG}"

# Main actions called from docker run/docker compose
if [[ $1 == "cron" ]]
then
  # Save ENV FTN_* vars for cron jobs
  printenv | grep "FTN_" >> /etc/environment
  exec cron -f
  exit
fi

if [[ $1 == "binkd-server" || $1 == "binkd" ]]
then
  exec binkd -C ${FTN_BINKD_CONFIG}
  exit
fi

if [[ $1 == "binkd-client" ]]
then
  exec binkd -c -C ${FTN_BINKD_CONFIG}
  exit
fi


# We need this to get all ENV saved for cron tasks
. /etc/environment


# Actions called by cron

# Toching poll flag
if [[ $1 == "poll" ]]
then
  touch ${FTN_FLAGSDIR}/poll
fi

# Toching housekeep flag
if [[ $1 == "housekeep" ]]
then
  touch ${FTN_FLAGSDIR}/housekeep
fi

if [ -e ${FTN_HPT_ECHOTOSSLOG} ]
then
  ${RNTRACK}
  ${HPT} scan
  rm -f ${FTN_HPT_ECHOTOSSLOG}
fi

# Binkd traffic toss
if [ -e ${FTN_BINKD_TOSS_FLAG} ]
then
  if [ ! -e ${FTN_FLAGSDIR}/tossing ]
  then
    touch ${FTN_FLAGSDIR}/tossing
    rm -f ${FTN_BINKD_TOSS_FLAG}
    ${RNTRACK}
    ${HPT} afix
    ${HPT} toss link
#     ${HTICK} toss
    rm -f ${FTN_FLAGSDIR}/tossing
  fi
fi

# if [ -e ${FTN_FLAGSDIR}/tick ]
# then
#   ${HTICK} toss
#   chown -R ${USER}:${GROUP} ${FILEBASE}/*
#   chmod 770 ${FILEBASE}/*
#   chmod 660 ${FILEBASE}/*/*
#   rm -f ${FTN_FLAGSDIR}/tick
# fi

# Poll action
if [ -e ${FTN_FLAGSDIR}/poll ]
then
  if [ ! -e ${FTN_FLAGSDIR}/polling ]
  then
    touch ${FTN_FLAGSDIR}/polling
    rm -f ${FTN_FLAGSDIR}/poll
    ${BINKD}
    rm -f ${FTN_FLAGSDIR}/polling
  fi
fi

# Housekeep action
if [ -e ${FTN_FLAGSDIR}/housekeep ]
then
  if [ ! -e ${FTN_FLAGSDIR}/housekeeping ]
  then
    touch ${FTN_FLAGSDIR}/housekeeping
    rm -f ${FTN_FLAGSDIR}/housekeep
    ${SQPACK} *
    ${HPT} qupd
    rm -f ${FTN_FLAGSDIR}/housekeeping
  fi
fi
