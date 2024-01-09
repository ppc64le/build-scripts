FROM registry.access.redhat.com/ubi8/ubi:8.7 as builder

RUN yum install -y git go make gcc wget patch

RUN git clone https://github.com/filebrowser/filebrowser.git /filebrowser-src && \
    cd filebrowser-src && \
    git checkout v2.27.0

WORKDIR /filebrowser-src

RUN go build -o /filebrowser-src/build/linux-ppc64le/filebrowser

RUN cp /filebrowser-src/build/linux-ppc64le/filebrowser /filebrowser && \
    chmod +x /filebrowser

FROM registry.access.redhat.com/ubi8/ubi-minimal:8.7

COPY docker_config.json /.filebrowser.json

COPY --from=builder /filebrowser /filebrowser

VOLUME /srv

EXPOSE 80

ENTRYPOINT ["/filebrowser"]
