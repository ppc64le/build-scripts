FROM registry.access.redhat.com/ubi7/ubi:latest

# Required Labels
LABEL name="fluentd" \
      maintainer="redmark@us.ibm.com" \
      vendor="Fluent Organization" \
      version="1.7.4" \
      release="1" \
      summary="Red Hat UBI Fluentd" \
      description="Red Hat UBI Fluentd: Unified Logging Layer"

COPY licenses /licenses

ENV FLUENTD_HOME "/home/fluentd"
ENV FLUENTD_OPT ""
ENV LD_PRELOAD ""
ENV FLUENTD_CONF "fluent.conf"
ENV PATH ${FLUENTD_HOME}/.rvm/gems/ruby-2.6.3/bin/:${FLUENTD_HOME}/.rvm/bin/:$PATH

RUN yum update -y && yum install -y sudo \
  && useradd --create-home --home-dir ${FLUENTD_HOME} --shell /bin/bash --system --user-group fluentd \
  && echo '%fluentd ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER fluentd
WORKDIR ${FLUENTD_HOME}

# Docker creates a layer for every RUN-Statement
RUN sudo yum update -y -q \
  && sudo yum install rh-ruby26.ppc64le git gnupg2 curl which -y -q

SHELL ["/bin/bash", "-c"]

RUN gpg2 --keyserver hkp://keys.gnupg.net/ --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB \
  && curl -L https://get.rvm.io | bash -s stable \
  && rvm install 2.6.3 \
  && source ${FLUENTD_HOME}/.rvm/scripts/rvm \
  && rvm use 2.6.3 --default \
  && gem install bundler \
  && gem install fluentd \
  && fluentd --setup .

COPY --chown=fluentd:fluentd fluent.conf ${FLUENTD_HOME}/${FLUENTD_CONF}
RUN mkdir log

EXPOSE 24224 5140

CMD source ${FLUENTD_HOME}/.rvm/scripts/rvm; fluentd -c ${FLUENTD_HOME}/${FLUENTD_CONF} -p ${FLUENTD_HOME}/plugin $FLUENTD_OPT
