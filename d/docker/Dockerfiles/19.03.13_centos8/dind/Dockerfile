
FROM ppc64le/docker:19.03.13

# Build docker:19.03 version from 19.03 folder and use local image to create dind image for v19.03

RUN yum install -y  e2fsprogs iptables openssl xfsprogs shadow-utils e2fsprogs-devel.ppc64le xz pigz wget 

# set up subuid/subgid so that "--userns-remap=default" works out-of-the-box


RUN set -eux; \
	groupadd dockremap; \
	adduser -g dockremap dockremap; \
	echo 'dockremap:165536:65536' >> /etc/subuid; \
	echo 'dockremap:165536:65536' >> /etc/subgid

# https://github.com/docker/docker/tree/master/hack/dind
ENV DIND_COMMIT ed89041433a031cafc0a0f19cfe573c31688d377

RUN set -eux; \
	wget -O /usr/local/bin/dind "https://raw.githubusercontent.com/docker/docker/${DIND_COMMIT}/hack/dind"; \
	chmod +x /usr/local/bin/dind

COPY dockerd-entrypoint.sh /usr/local/bin/

VOLUME /var/lib/docker
EXPOSE 2375 2376

ENTRYPOINT ["dockerd-entrypoint.sh"]
CMD []
