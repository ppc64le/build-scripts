FROM debian:buster-slim

ARG JITSI_RELEASE=stable

ARG ARCH=amd64

ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2

COPY rootfs /

#COPY frep-1.3.11-linux-ppc64le /usr/bin/frep

RUN     set -e; \
	apt-dpkg-wrap apt-get update && \
	apt-dpkg-wrap apt-get install -y apt-transport-https apt-utils ca-certificates gnupg && \
	apt-dpkg-wrap apt-get install -y wget git gcc g++ && \
        wget -qO - https://golang.org/dl/go1.15.2.linux-${ARCH}.tar.gz  | tar xfz - -C /usr && \
        export PATH=/usr/go/bin/:$PATH && \
        git clone https://github.com/subchen/frep.git && cd frep && git checkout v1.3.11 && \
        go build -a -installsuffix cgo -ldflags "-s -w -X 'main.BuildVersion=1.3.11' -X 'main.BuildGitBranch=$(git describe --all)' \
                 -X 'main.BuildGitRev=$(git rev-list --count HEAD)' -X 'main.BuildGitCommit=$(git rev-parse HEAD)' \
                 -X 'main.BuildDate=$(date -u -R)'" -o _releases/frep && \
        cp _releases/frep /usr/bin/frep && chmod +x /usr/bin/frep && \
        cd .. && rm -rf frep && rm -rf /usr/go && \
	wget -qO - https://github.com/just-containers/s6-overlay/releases/download/v1.22.1.0/s6-overlay-${ARCH}.tar.gz | tar xfz - -C / && \
	#wget -qO - https://download.jitsi.org/jitsi-key.gpg.key | apt-key add - && \
	#wget -q https://github.com/subchen/frep/releases/download/v1.3.5/frep-1.3.5-linux-amd64 -O /usr/bin/frep && \
	apt-dpkg-wrap apt-get --purge remove -y wget git gcc g++ && \
	echo "deb http://ftp.debian.org/debian buster-backports main" > /etc/apt/sources.list.d/backports.list && \
	apt-dpkg-wrap apt-get update && \
	apt-dpkg-wrap apt-get dist-upgrade -y && \
	apt-cleanup

RUN \
	[ "$JITSI_RELEASE" = "unstable" ] && \
	apt-dpkg-wrap apt-get update && \
	apt-dpkg-wrap apt-get install -y jq procps curl vim iputils-ping net-tools && \
	apt-cleanup || \
	true

ENTRYPOINT [ "/init" ]
