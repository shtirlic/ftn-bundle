FROM ubuntu:20.04 as binkd-builder

WORKDIR /binkd
#COPY . /binkd

RUN apt update && apt upgrade -y \
  && apt install -y git gcc make \
  && git clone https://github.com/pgul/binkd.git /binkd \
  && cp mkfls/unix/* . \
  && ./configure \
  && make -j$(getconf _NPROCESSORS_ONLN)

FROM ubuntu:20.04
LABEL maintainer="Serg Podtynnyi <serg@podtynnyi.com>"

RUN apt update && apt upgrade -y 

COPY --from=builder /binkd/binkd /usr/local/bin


VOLUME 	/ftn
EXPOSE 24554
