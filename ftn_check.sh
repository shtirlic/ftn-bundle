#!/bin/bash

# We need this to get all ENV set from pid 1 process
. <(xargs -0 bash -c 'printf "export %q\n" "$@"' -- < /proc/1/environ)

SUDO="sudo -u ${FTNUSER}"
HPT="${SUDO} /usr/local/bin/hpt -c ${HPT_CONFIG}"
BINKD="${SUDO} /usr/local/bin/binkd -n ${BINKD_UPLINKS_POLL} ${BINKD_CONFIG}"
RNTRACK="${SUDO} /usr/local/bin/rntrack -c ${RNTRACK_CONFIG}"
SQPACK="${SUDO} /usr/local/bin/sqpack -c ${HPT_CONFIG}"

if [ $1 = "poll" ]
then
  touch ${FLAGSDIR}/poll
fi

if [ $1 = "housekeep" ]
then
  touch ${FLAGSDIR}/housekeep
fi

if [ -e ${HPT_ECHOTOSSLOG} ]
then
  ${RNTRACK}
  ${HPT} scan
  rm -f ${HPT_ECHOTOSSLOG}
fi

if [ -e ${BINKD_TOSS_FLAG} ]
then
  if [ ! -e ${FLAGSDIR}/tossing ]
  then
    touch ${FLAGSDIR}/tossing
    rm -f ${BINKD_TOSS_FLAG}
    ${RNTRACK}
    ${HPT} afix
    ${HPT} toss link
#     ${HTICK} toss
    rm -f ${FLAGSDIR}/tossing
  fi
fi

# if [ -e ${FLAGSDIR}/tick ]
# then
#   ${SUDO} -u ${USER} ${HTICK} toss
#   chown -R ${USER}:${GROUP} ${FILEBASE}/*
#   chmod 770 ${FILEBASE}/*
#   chmod 660 ${FILEBASE}/*/*
#   rm -f ${FLAGSDIR}/tick
# fi

if [ -e ${FLAGSDIR}/poll ]
then
  if [ ! -e ${FLAGSDIR}/polling ]
  then
    touch ${FLAGSDIR}/polling
    rm -f ${FLAGSDIR}/poll
    ${BINKD}
    rm -f ${FLAGSDIR}/polling
  fi
fi

if [ -e ${FLAGSDIR}/housekeep ]
then
  if [ ! -e ${FLAGSDIR}/housekeeping ]
  then
    touch ${FLAGSDIR}/housekeeping
    rm -f ${FLAGSDIR}/housekeep
    ${SQPACK} *
    ${HPT} qupd
    rm -f ${FLAGSDIR}/housekeeping
  fi
fi
