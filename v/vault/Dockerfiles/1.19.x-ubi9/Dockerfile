FROM registry.access.redhat.com/ubi9/ubi:9.7 AS builder

ARG VAULT_VERSION=v1.19.5

ARG GO_VERSION=1.24.13

RUN yum install -y gcc-c++ wget tar gzip openssl git make && \
    wget https://go.dev/dl/go${GO_VERSION}.linux-ppc64le.tar.gz && \
    tar -C /usr/local -xf go${GO_VERSION}.linux-ppc64le.tar.gz && \
    export GOROOT=/usr/local/go && \
    export GOPATH=$HOME && \
    export PATH=$GOPATH/bin:$GOROOT/bin:$PATH && \
    git clone https://github.com/hashicorp/vault && cd vault && \
    git checkout $VAULT_VERSION && \
    make bootstrap && \
    make dev
	
FROM registry.access.redhat.com/ubi9/ubi-minimal

# Additional metadata labels used by container registries, platforms
# and certification scanners.
LABEL name="Vault" \
      maintainer="<Pratik.Tonage@ibm.com>" \
      summary="Vault is a tool for securely accessing secrets." \
      description="Vault is a tool for securely accessing secrets. A secret is anything that you want to tightly control access to, such as API keys, passwords, certificates, and more. Vault provides a unified interface to any secret, while providing tight access control and recording a detailed audit log."

RUN microdnf install -y ca-certificates openssl libcap tzdata procps shadow-utils util-linux tar gnupg

# Create a non-root user to run the software.
RUN groupadd --gid 1000 vault && \
    adduser --uid 100 --system -g vault vault && \
    usermod -a -G root vault
	
COPY --from=builder /vault/bin/vault /usr/bin/

ENV HOME=/home/vault

RUN mkdir -p /vault/logs && \
    mkdir -p /vault/file && \
    mkdir -p /vault/config && \
    mkdir -p $HOME && \
    chown -R vault /vault && chown -R vault $HOME && \
    chgrp -R 0 $HOME && chmod -R g+rwX $HOME && \
    chgrp -R 0 /vault && chmod -R g+rwX /vault

# Include EULA and Terms of Eval
RUN mkdir -p /usr/share/doc/vault && \
    curl -o /usr/share/doc/vault/EULA.txt https://eula.hashicorp.com/EULA.txt && \
    curl -o /usr/share/doc/vault/TermsOfEvaluation.txt https://eula.hashicorp.com/TermsOfEvaluation.txt

# Copy the license file as per Legal requirement
COPY --from=builder /vault/LICENSE /usr/share/doc/vault/LICENSE.txt

# Expose the logs directory as a volume since there's potentially long-running
# state in there
VOLUME /vault/logs

# Expose the file directory as a volume since there's potentially long-running
# state in there
VOLUME /vault/file

# 8200/tcp is the primary interface that applications use to interact with
# Vault.
EXPOSE 8200

COPY  --from=builder /vault/.release/docker/ubi-docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

USER vault
ENV SKIP_CHOWN=true
ENV SKIP_SETCAP=true

ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["server", "-dev"]
