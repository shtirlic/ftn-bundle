FROM ubuntu:20.04 as ftn-builder

ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true

RUN apt-get update && apt-get upgrade -y \
    && echo 'tzdata tzdata/Areas select Etc' | debconf-set-selections \
    && echo 'tzdata tzdata/Zones/Etc select UTC' | debconf-set-selections \
    && apt-get install -y git gcc g++ make cmake zlib1g-dev \
    && mkdir /usr/src/packages/ 
    
#binkd build
RUN git clone https://github.com/pgul/binkd.git --depth 1 /usr/src/packages/binkd  \
  && cd /usr/src/packages/binkd \
  && cp mkfls/unix/* . \
  && ./configure \
  && make -j$(getconf _NPROCESSORS_ONLN)

#husky clone
RUN git clone https://github.com/huskyproject/huskybse.git --depth 1 /usr/src/packages/huskybse \
  && git clone https://github.com/huskyproject/huskylib.git --depth 1 /usr/src/packages/huskylib \
  && git clone https://github.com/huskyproject/smapi.git --depth 1 /usr/src/packages/smapi \
  && git clone https://github.com/huskyproject/fidoconf.git --depth 1 /usr/src/packages/fidoconf \
  && git clone https://github.com/huskyproject/hpt.git --depth 1 /usr/src/packages/hpt \
  && git clone https://github.com/huskyproject/htick.git --depth 1 /usr/src/packages/htick \
  && git clone https://github.com/huskyproject/areafix.git --depth 1 /usr/src/packages/areafix \
  && git clone https://github.com/huskyproject/hptzip.git --depth 1 /usr/src/packages/hptzip \
  && git clone https://github.com/huskyproject/hptutil.git --depth 1 /usr/src/packages/hptutil 

#husky build
RUN cd /usr/src/packages/hpt \
    && cd /usr/src/packages/huskylib && cmake -H. -Bbuild -DBUILD_SHARED_LIBS=OFF && cmake --build build --target install \
    && cd /usr/src/packages/smapi && cmake -H. -Bbuild -DBUILD_SHARED_LIBS=OFF && cmake --build build --target install \
    && cd /usr/src/packages/fidoconf && cmake -H. -Bbuild -DBUILD_SHARED_LIBS=OFF && cmake --build build --target install \
    && cd /usr/src/packages/areafix && cmake -H. -Bbuild -DBUILD_SHARED_LIBS=OFF && cmake --build build --target install \
    && cd /usr/src/packages/hptzip && cmake -H. -Bbuild -DBUILD_SHARED_LIBS=OFF && cmake --build build --target install \
    && cd /usr/src/packages/hpt && cmake -H. -Bbuild -DBUILD_SHARED_LIBS=OFF && cmake --build build --target install \
    && cd /usr/src/packages/hptutil && cmake -H. -Bbuild -DBUILD_SHARED_LIBS=OFF && cmake --build build --target install \
    && cd /usr/src/packages/htick && cmake -H. -Bbuild -DBUILD_SHARED_LIBS=OFF && cmake --build build --target install 

RUN git clone https://github.com/shtirlic/rntrack.git --depth 1 /usr/src/packages/rntrack \
    && cd /usr/src/packages/rntrack/MakeFiles/linux  && make install 

FROM ubuntu:20.04
LABEL maintainer="Serg Podtynnyi <serg@podtynnyi.com>"

RUN apt update && apt upgrade -y 

COPY --from=ftn-builder /usr/src/packages/binkd/binkd /usr/local/bin
COPY --from=ftn-builder /usr/local/bin/* /usr/local/bin/
COPY --from=ftn-builder /usr/bin/rntrack /usr/local/bin/

WORKDIR /ftn
VOLUME 	/ftn
EXPOSE 24554
