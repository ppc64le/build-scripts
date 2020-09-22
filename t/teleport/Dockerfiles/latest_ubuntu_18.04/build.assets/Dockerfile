# This Dockerfile makes the "build box": the container used to build official
# releases of Teleport and its documentation.

# Use Ubuntu 18.04 as base to get an older glibc version.
# Using a newer base image will build against a newer glibc, which creates a
# runtime requirement for the host to have newer glibc too. For example,
# teleport built on any newer Ubuntu version will not run on Centos 7 because
# of this.
FROM registry.access.redhat.com/ubi8/ubi:8.2

COPY locale.gen /etc/locale.gen
COPY profile /etc/profile

ARG ARCH=ppc64le

RUN yum update -y && \
    yum -y --disableplugin=subscription-manager install http://mirror.centos.org/centos/8.2.2004/BaseOS/${ARCH}/os/Packages/centos-repos-8.2-2.2004.0.1.el8.${ARCH}.rpm \
                                                        http://mirror.centos.org/centos/8.2.2004/BaseOS/${ARCH}/os/Packages/centos-gpg-keys-8.2-2.2004.0.1.el8.noarch.rpm \
                                                        https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm && yum update -y
RUN yum install -y gcc pam-devel glibc-devel net-tools tree git zip  make

ARG UID
ARG GID
RUN (groupadd ci --gid=$GID -o && useradd ci --uid=$UID --gid=$GID --create-home --shell=/bin/sh ;\
     mkdir -p -m0700 /var/lib/teleport && chown -R ci /var/lib/teleport)

# Install etcd.
RUN (curl -L https://github.com/coreos/etcd/releases/download/v3.3.9/etcd-v3.3.9-linux-ppc64le.tar.gz | tar -xz ;\
     cp etcd-v3.3.9-linux-ppc64le/etcd* /bin/)

# Install Go.
ARG RUNTIME
RUN mkdir -p /opt && cd /opt && curl https://storage.googleapis.com/golang/$RUNTIME.linux-ppc64le.tar.gz | tar xz;\
    mkdir -p /go/src/github.com/gravitational/teleport;\
    chmod a+w /go;\
    chmod a+w /var/lib;\
    chmod a-w /

ENV GOPATH="/go" \
    GOROOT="/opt/go" \
    PATH="$PATH:/opt/go/bin:/go/bin:/go/src/github.com/gravitational/teleport/build"

# Install meta-linter.
RUN (curl -L https://github.com/golangci/golangci-lint/releases/download/v1.24.0/golangci-lint-1.24.0-$(go env GOOS)-$(go env GOARCH).tar.gz | tar -xz ;\
     cp golangci-lint-1.24.0-$(go env GOOS)-$(go env GOARCH)/golangci-lint /bin/ ;\
     rm -r golangci-lint*)

COPY pam/pam_teleport.so /lib/ppc64le-linux-gnu/security
COPY pam/teleport-* /etc/pam.d/
RUN mkdir -p /lib/powerpc64le-linux-gnu && ln -s /usr/lib64/libc.so.6 /lib/powerpc64le-linux-gnu/libc.so.6

VOLUME ["/go/src/github.com/gravitational/teleport"]
EXPOSE 6600 2379 2380
