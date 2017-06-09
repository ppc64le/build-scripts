FROM ppc64le/ubuntu:16.04
# Owner of a docker file
# This docker file is derived from original work for x86 at https://github.com/cpuguy83/docker-jruby/blob/882f6121c19e90e158bc86645335f8762d26ff19/1.7/jdk/Dockerfile.
# Modified for ppc64le support by email : Meghali Dhoble <dhoblem@us.ibm.com>
MAINTAINER Meghali Dhoble

ENV JRUBY_VERSION  9.1.8.0
ENV JRUBY_SHA256 20ac501c99a7cb3cf53ded64ac1b8bb6e0b0f6ba34a41b8bacc9715cd4bb2601
ENV PATH /opt/jruby/bin:$PATH
ENV GEM_HOME /usr/local/bundle
ENV PATH $GEM_HOME/bin:$PATH
RUN apt-get clean\
        && apt-get update --fix-missing \
        && apt-get install -y libc6-dev curl --no-install-recommends openjdk-8-jdk maven-ant-helper libpangocairo-1.0.0 \
        && rm -rf /var/lib/apt/lists/*\
        && mkdir /opt/jruby \
        && curl -fSL https://s3.amazonaws.com/jruby.org/downloads/${JRUBY_VERSION}/jruby-bin-${JRUBY_VERSION}.tar.gz -o /tmp/jruby.tar.gz \
        && echo "$JRUBY_SHA256 /tmp/jruby.tar.gz" | sha256sum -c - \
        && tar -zx --strip-components=1 -f /tmp/jruby.tar.gz -C /opt/jruby \
        && rm /tmp/jruby.tar.gz \
        && update-alternatives --install /usr/local/bin/ruby ruby /opt/jruby/bin/jruby 1\
        && echo 'gem: --no-rdoc --no-ri' >> ~/.gemrc\
        && gem install bundler \
        && bundle config --global path "$GEM_HOME" \
        && bundle config --global bin "$GEM_HOME/bin"\
		&& apt-get purge -y --auto-remove  libc6-dev curl
# don't create ".bundle" in all our apps
ENV BUNDLE_APP_CONFIG $GEM_HOME

CMD [ "irb" ]



