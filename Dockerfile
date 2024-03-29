FROM ubuntu:22.04 as ftn-builder

ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true

# Install depend
RUN apt-get update && apt-get upgrade -y \
  && echo 'tzdata tzdata/Areas select Etc' | debconf-set-selections \
  && echo 'tzdata tzdata/Zones/Etc select UTC' | debconf-set-selections \
  && apt-get install -y git gcc g++ make cmake zlib1g-dev \
  && mkdir /usr/src/packages/

# Binkd build
RUN git clone https://github.com/pgul/binkd.git --depth 1 /usr/src/packages/binkd  \
  && cd /usr/src/packages/binkd \
  && cp mkfls/unix/* . \
  && ./configure --with-af-force \
  && make install

# Husky clone
RUN git clone https://github.com/huskyproject/huskybse.git --depth 1 /usr/src/packages/huskybse \
  && git clone https://github.com/huskyproject/huskylib.git --depth 1 /usr/src/packages/huskylib \
  && git clone https://github.com/huskyproject/smapi.git --depth 1 /usr/src/packages/smapi \
  && git clone https://github.com/huskyproject/fidoconf.git --depth 1 /usr/src/packages/fidoconf \
  && git clone https://github.com/huskyproject/hpt.git --depth 1 /usr/src/packages/hpt \
  && git clone https://github.com/huskyproject/htick.git --depth 1 /usr/src/packages/htick \
  && git clone https://github.com/huskyproject/areafix.git --depth 1 /usr/src/packages/areafix \
  && git clone https://github.com/huskyproject/hptzip.git --depth 1 /usr/src/packages/hptzip \
  && git clone https://github.com/shtirlic/hptutil.git --depth 1 /usr/src/packages/hptutil \
  && git clone https://github.com/shtirlic/sqpack.git --depth 1 /usr/src/packages/sqpack \
  && git clone https://github.com/shtirlic/nltools.git --depth 1 /usr/src/packages/nltools

# Husky build
RUN cd /usr/src/packages/hpt \
  && cd /usr/src/packages/huskylib  && cmake -H. -Bbuild -DBUILD_SHARED_LIBS=OFF && cmake --build build --target install \
  && cd /usr/src/packages/smapi     && cmake -H. -Bbuild -DBUILD_SHARED_LIBS=OFF && cmake --build build --target install \
  && cd /usr/src/packages/fidoconf  && cmake -H. -Bbuild -DBUILD_SHARED_LIBS=OFF && cmake --build build --target install \
  && cd /usr/src/packages/areafix   && cmake -H. -Bbuild -DBUILD_SHARED_LIBS=OFF && cmake --build build --target install \
  && cd /usr/src/packages/hptzip    && cmake -H. -Bbuild -DBUILD_SHARED_LIBS=OFF && cmake --build build --target install \
  && cd /usr/src/packages/hpt       && cmake -H. -Bbuild -DBUILD_SHARED_LIBS=OFF && cmake --build build --target install \
  && cd /usr/src/packages/htick     && cmake -H. -Bbuild -DBUILD_SHARED_LIBS=OFF && cmake --build build --target install \
  && cd /usr/src/packages/hptutil   && cmake -H. -Bbuild -DBUILD_SHARED_LIBS=OFF && cmake --build build --target install \
  && cd /usr/src/packages/sqpack    && cmake -H. -Bbuild -DBUILD_SHARED_LIBS=OFF && cmake --build build --target install \
  && cd /usr/src/packages/nltools   && cmake -H. -Bbuild -DBUILD_SHARED_LIBS=OFF && cmake --build build --target install

# RNtrack build
RUN git clone https://github.com/vasilyevmax/rntrack.git --depth 1 /usr/src/packages/rntrack \
  && cd /usr/src/packages/rntrack/MakeFiles/linux  && make install

FROM ubuntu:22.04
LABEL maintainer="Serg Podtynnyi <serg@podtynnyi.com>"
LABEL description="Full FTN bundle for FIDOnet and other networks. Inlcudes binkd, most packages of husky(hpt, htick, hptutil etc) and rntrack."

RUN apt update && apt upgrade -y && apt install -y cron sudo

# Copy all binaries from build image
COPY --from=ftn-builder /usr/local/bin/* /usr/local/bin/
COPY --from=ftn-builder /usr/local/sbin/binkd* /usr/local/bin/
COPY --from=ftn-builder /usr/bin/rntrack /usr/local/bin/

# We will use ftn user for all processes
ENV FTNUSER=${FTNUSER:-"ftn"}
RUN adduser --disabled-password --gecos '' ${FTNUSER}

WORKDIR /ftn
VOLUME 	/ftn

ENV FLAGSDIR=${FLAGSDIR:-"/ftn/node/tmp"}

ENV BINKD_CONFIG=${BINKD_CONFIG:-"/ftn/binkd/binkd.conf"}
ENV BINKD_UPLINKS_POLL=${BINKD_UPLINKS_POLL:-"-P 2:5030/3165"}
ENV BINKD_TOSS_FLAG=${BINKD_TOSS_FLAG:-"/ftn/node/tmp/toss"}

ENV HPT_CONFIG=${HPT_CONFIG:-"/ftn/hpt/hpt.conf"}
ENV HPT_ECHOTOSSLOG=${HPT_ECHOTOSSLOG:-"/ftn/log/hpt-toss.log"}

ENV RNTRACK_CONFIG=${RNTRACK_CONFIG:-"/ftn/rntrack/rntrack.cfg"}

# Using cron -f for run crontab, for ex: every minute ftn_check and every hour touch poll
COPY crontab /etc/crontab
COPY ftn_check.sh /usr/local/bin/
RUN chmod 755 /usr/local/bin/ftn_check.sh

USER ${FTNUSER}
EXPOSE 24554
