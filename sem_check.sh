#!/bin/bash

HPT=hpt -c ${HPT_CONFIG}
BINKD=binkd -n -q ${BINKD_UPLINKS} ${BINKD_CONFIG} 
RNTRACK=rntrack -c ${RNTRACK_CONFIG}

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
