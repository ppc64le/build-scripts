FROM registry.access.redhat.com/ubi9/ubi:latest

# `tini` is a tiny but valid init for containers. This is used to cleanly
# control how ES and any child processes are shut down.
#
# The tini GitHub page gives instructions for verifying the binary using
# gpg, but the keyservers are slow to return the key and this can fail the
# build. Instead, we check the binary against the published checksum.
RUN set -eux ; \
    tini_bin="" ; \
    case "$(arch)" in \
        aarch64) tini_bin='tini-arm64' ;; \
        x86_64)  tini_bin='tini-amd64' ;; \
        ppc64le) tini_bin='tini-ppc64le' ;; \
        *) echo >&2 ; echo >&2 "Unsupported architecture $(arch)" ; echo >&2 ; exit 1 ;; \
    esac ; \
    curl --retry 10 -S -L -O https://github.com/krallin/tini/releases/download/v0.19.0/${tini_bin} ; \
    curl --retry 10 -S -L -O https://github.com/krallin/tini/releases/download/v0.19.0/${tini_bin}.sha256sum ; \
    sha256sum -c ${tini_bin}.sha256sum ; \
    rm ${tini_bin}.sha256sum ; \
    mv ${tini_bin} /bin/tini ; \
    chmod +x /bin/tini

RUN yum install -y gcc make redhat-rpm-config ca-certificates ruby ruby-irb ruby-devel gnupg \
    && echo 'gem: --no-document' >> /etc/gemrc \
    && gem install rexml -v 3.2.6 \
    && gem install oj -v 3.16.1 \
    && gem install json -v 2.6.3 \
    && gem install async-http -v 0.60.2 \
    && gem install async -v 1.31.0 \
    && gem install fluentd -v 1.17.0 \
    && gem install bigdecimal -v 1.4.4 \
    && yum remove -y gcc make redhat-rpm-config ruby-devel \
    && rm -rf /tmp/* /var/tmp/* /usr/lib/ruby/gems/*/cache/*.gem /usr/lib/ruby/gems/2.*/gems/fluentd-*/test

RUN groupadd -r fluent && useradd -r -g fluent fluent \
    # for log storage (maybe shared with host)
    && mkdir -p /fluentd/log \
    # configuration/plugins path (default: copied from .)
    && mkdir -p /fluentd/etc /fluentd/plugins \
    && chown -R fluent /fluentd && chgrp -R fluent /fluentd

COPY fluent.conf /fluentd/etc/
COPY entrypoint.sh /bin/

RUN chmod +x /bin/entrypoint.sh
ENV FLUENTD_CONF="fluent.conf"

ENV LD_PRELOAD=""
EXPOSE 24224 5140

RUN ["gem", "install", "fluent-plugin-elasticsearch", "--no-document", "--version", "5.2.1"]

USER fluent
ENTRYPOINT ["tini",  "--", "/bin/entrypoint.sh"]
CMD ["fluentd"]
