FROM ppc64le/ubuntu:16.04

MAINTAINER "Priya Seth <sethp@us.ibm.com>"

# install dependent packages for Busybox
RUN apt-get update && apt-get install -y make git gcc \
	&& git clone http://git.busybox.net/busybox/ \
	&& cd busybox && git checkout remotes/origin/1_26_stable \
	&& make defconfig && make && make install \
	&& apt-get purge -y make git gcc && apt-get -y autoremove

ENTRYPOINT ["/busybox/busybox"]

CMD ["--list"]
