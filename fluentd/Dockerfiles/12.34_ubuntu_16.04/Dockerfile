FROM ppc64le/ubuntu:16.04
MAINTAINER Snehlata Mohite <smohite@us.ibm.com>

# Do not split this into multiple RUN!
# Docker creates a layer for every RUN-Statement
# therefore an 'apk delete' has no effect
RUN apt-get update -y && apt-get install -y --no-install-recommends\ 
        ca-certificates \
        ruby \
        ruby-dev \
	make gcc\
    &&  echo 'gem: --no-document' >> /etc/gemrc \
    &&  apt-get install  -y libgmp3-dev build-essential zlib1g-dev liblzma-dev libsqlite3-dev  liblzma-dev  \
    &&  gem install oj \
    &&  gem install json \
    &&  gem install fluentd -v 0.12.34 \
    &&  rm -rf /var/cache/apk/* \
    &&  rm -rf /tmp/* /var/tmp/* /usr/lib/ruby/gems/*/cache/*.gem\
    &&  useradd -d /home/fluent -m -s /bin/bash fluent\
    &&  chown -R fluent:fluent /home/fluent\
# for log storage (maybe shared with host)
    &&  mkdir -p /fluentd/log\
# configuration/plugins path (default: copied from .)
    &&  mkdir -p /fluentd/etc /fluentd/plugins\
    &&  chown -R fluent:fluent /fluentd\
    &&  apt-get autoremove -y gcc build-essential && apt-get clean

USER fluent
WORKDIR /home/fluent

# Tell ruby to install packages as user
RUN echo "gem: --user-install --no-document" >> ~/.gemrc
ENV PATH /home/fluent/.gem/ruby/2.3.0/bin:$PATH
ENV GEM_PATH /home/fluent/.gem/ruby/2.3.0:$GEM_PATH

COPY fluent.conf /fluentd/etc/

ENV FLUENTD_OPT=""
ENV FLUENTD_CONF="fluent.conf"

ENV LD_PRELOAD=""

EXPOSE 24224 5140

CMD exec fluentd -c /fluentd/etc/$FLUENTD_CONF -p /fluentd/plugins $FLUENTD_OPT

