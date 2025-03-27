FROM registry.access.redhat.com/ubi8/ubi:8.7

RUN yum install java-17-openjdk-devel openssl-devel git wget tar python39-devel.ppc64le gcc rust cargo man gcc-c++ cmake.ppc64le -y && \
    export JDK_HOME=/usr/lib/jvm/java-17-openjdk && \
    export JAVA_HOME=/usr/lib/jvm/java-17-openjdk

RUN wget https://archive.apache.org/dist/maven/maven-3/3.8.7/binaries/apache-maven-3.8.7-bin.tar.gz && \
    tar -zxf apache-maven-3.8.7-bin.tar.gz && \
    cp -R apache-maven-3.8.7 /usr/local && \
    ln -s /usr/local/apache-maven-3.8.7/bin/mvn /usr/bin/mvn

RUN git clone https://github.com/ansible/ansible && \
    cd ansible/ && \
    source ./hacking/env-setup && \
    python3 -m pip install --user -r ./requirements.txt && \
    export ANSIBLE_HOME="/usr/local/bin" && \
    export PATH=$PATH:$ANSIBLE_HOME && \
    python3 -m build

EXPOSE 8080
CMD ["/bin/bash"]
