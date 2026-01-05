FROM registry.access.redhat.com/ubi9/ubi:9.3

ARG PACKAGE_VERSION=zed-eom

RUN yum install openssl openssl-devel -y && \
    yum install -y git wget gcc gcc-c++ python3 python3-pip python3-devel python3-psycopg2 libxslt libxslt-devel make libpq libpq-devel cmake xz libaio     ninja-build glib2 glib2-devel bzip2 pkgconfig diffutils && \
    wget https://rpmfind.net/linux/centos-stream/9-stream/AppStream/ppc64le/os/Packages/pixman-0.40.0-5.el9.ppc64le.rpm && \
    rpm -i pixman-0.40.0-5.el9.ppc64le.rpm && \
    wget https://rpmfind.net/linux/centos-stream/9-stream/AppStream/ppc64le/os/Packages/pixman-devel-0.40.0-5.el9.ppc64le.rpm && \
    rpm -i pixman-devel-0.40.0-5.el9.ppc64le.rpm

RUN wget https://static.rust-lang.org/dist/rust-1.65.0-powerpc64le-unknown-linux-gnu.tar.gz  &&\
    tar -xzf rust-1.65.0-powerpc64le-unknown-linux-gnu.tar.gz  && \
    cd rust-1.65.0-powerpc64le-unknown-linux-gnu  && \
    ./install.sh  && \
    cd ..

RUN git clone https://github.com/openstack/glance && \
    cd glance && \
    git checkout $PACKAGE_VERSION && \
    pip3 install "cython<3.0.0" wheel tox && pip3 install --no-build-isolation pyyaml==6.0 && \
    python3 -m pip install -r requirements.txt

CMD ["/bin/bash"]
