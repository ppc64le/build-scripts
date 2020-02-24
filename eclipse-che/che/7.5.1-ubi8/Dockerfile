FROM registry.access.redhat.com/ubi8/ubi

ENV JAVA_MAJOR_VERSION=8 \
    JAVA_HOME=/usr/lib/jvm/jre-1.8.0 \
    LANG=C.UTF-8 \
    DOCKER_VERSION=18.09.1-r0 \
    DOCKER_BUCKET=get.docker.com \
    CHE_IN_CONTAINER=true \
    ARCH="`arch`"

RUN yum -y update && \
    yum -y install openssl java-1.8.0-openjdk-headless sudo && \
    curl -sSL "https://${DOCKER_BUCKET}/builds/Linux/$ARCH/docker-${DOCKER_VERSION}" -o /usr/bin/docker && \
    chmod +x /usr/bin/docker && \
    yum -y remove openssl && \
    yum clean all && \
    echo "%root ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    sed -i 's/Defaults    requiretty/#Defaults    requiretty/g' /etc/sudoers && \
    rm -rf /tmp/* /var/cache/yum

EXPOSE 8000 8080
COPY entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
RUN mkdir /logs /data && \
    chmod 0777 /logs /data
RUN mkdir -p /home/user
RUN groupadd -r che -g 1000 && useradd -u 1000 -r -g che -m -d /home/user/che -s /sbin/nologin -c "Che user" che
ADD eclipse-che /home/user/eclipse-che
RUN find /home/user -type d -exec chmod 777 {} \;
USER 1000:1000
