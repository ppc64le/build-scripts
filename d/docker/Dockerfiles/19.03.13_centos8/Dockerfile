FROM centos:8

#Note - Files have be adapted from community dockerfiles available @ https://github.com/docker-library/docker/tree/835c371c516ebdf67adc0c76bbfb38bf9d3e586c/19.03
RUN  yum install -y ca-certificates openssh-clients.ppc64le

ENV DOCKER_VERSION 19.03.13

RUN dnf install -y https://dl.fedoraproject.org/pub/epel/7/ppc64le/Packages/c/containerd-1.2.14-1.el7.ppc64le.rpm
RUN dnf install -y https://oplab9.parqtec.unicamp.br/pub/ppc64el/docker/version-19.03.13/centos/docker-ce-cli-19.03.13-3.el7.ppc64le.rpm
RUN dnf install -y https://oplab9.parqtec.unicamp.br/pub/ppc64el/docker/version-19.03.13/centos/docker-ce-19.03.13-3.el7.ppc64le.rpm

COPY modprobe.sh /usr/local/bin/modprobe
COPY docker-entrypoint.sh /usr/local/bin/

#   dockerd-entrypoint.sh uses DOCKER_TLS_CERTDIR for auto-generating TLS certificates
#   docker-entrypoint.sh uses DOCKER_TLS_CERTDIR for auto-setting DOCKER_TLS_VERIFY and DOCKER_CERT_PATH
# (For this to work, at least the "client" subdirectory of this path needs to be shared between the client and server containers via a volume, "docker cp", or other means of data sharing.)
ENV DOCKER_TLS_CERTDIR=/certs
# also, ensure the directory pre-exists and has wide enough permissions for "dockerd-entrypoint.sh" to create subdirectories, even when run in "rootless" mode
RUN mkdir /certs /certs/client && chmod 1777 /certs /certs/client
# (doing both /certs and /certs/client so that if Docker does a "copy-up" into a volume defined on /certs/client, it will "do the right thing" by default in a way that still works for rootless users)

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["sh"]
