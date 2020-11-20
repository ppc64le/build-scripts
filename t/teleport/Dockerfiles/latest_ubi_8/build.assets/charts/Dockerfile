FROM registry.access.redhat.com/ubi8/ubi:8.2

# Install dumb-init and ca-certificate. The dumb-init package is to ensure
# signals and orphaned processes are are handled correctly. The ca-certificate
# package is installed because the base Ubuntu image does not come with any
# certificate authorities.
#
# Note that /var/lib/apt/lists/* is cleaned up in the same RUN command as
# "apt-get update" to reduce the size of the image.
RUN yum update -y && \
    yum install -y wget

RUN wget https://github.com/Yelp/dumb-init/releases/download/v1.2.2/dumb-init_1.2.2_ppc64le && \
    chmod a+x dumb-init_1.2.2_ppc64le && mv ./dumb-init_1.2.2_ppc64le ./dumb-init && cp ./dumb-init /usr/bin

# Bundle "teleport", "tctl", and "tsh" binaries into image.
ADD teleport /usr/local/bin/teleport
ADD tctl /usr/local/bin/tctl
ADD tsh /usr/local/bin/tsh

# By setting this entry point, we expose make target as command.
ENTRYPOINT ["/usr/bin/dumb-init", "teleport", "start", "-c", "/etc/teleport/teleport.yaml"]
