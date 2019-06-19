FROM openjdk:8u191-jdk-alpine

ENV LANG=C.UTF-8 \
    DOCKER_VERSION=18.09.1-r0 \
    DOCKER_BUCKET=get.docker.com \
    CHE_IN_CONTAINER=true \
    ARCH="`arch`"

RUN echo "http://dl-4.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories && \
    apk add --update curl openssl sudo bash && \
    curl -sSL "https://${DOCKER_BUCKET}/builds/Linux/$ARCH/docker-${DOCKER_VERSION}" -o /usr/bin/docker && \
    chmod +x /usr/bin/docker && \
    echo "%root ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    rm -rf /tmp/* /var/cache/apk/*

EXPOSE 8000 8080
COPY entrypoint.sh /entrypoint.sh
COPY open-jdk-source-file-location /open-jdk-source-file-location
ENTRYPOINT ["/entrypoint.sh"]
RUN mkdir /logs /data && \
    chmod 0777 /logs /data
ADD eclipse-che /home/user/eclipse-che
RUN find /home/user -type d -exec chmod 777 {} \;

