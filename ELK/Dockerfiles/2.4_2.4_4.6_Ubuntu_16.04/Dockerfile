FROM ubuntu_ppc64le:16.04
MAINTAINER Meghali Dhoble

ENV KIBANA 4.6
ENV ELASTIC 2.x
ENV LOGSTASH 2.4

ENV GOSU_VERSION 1.7
ENV GOSU_URL https://github.com/tianon/gosu/releases/download

RUN echo "deb http://ports.ubuntu.com/ubuntu-ports xenial restricted multiverse universe"  >> /etc/apt/sources.list
RUN apt-get update -y
RUN apt-get install -y openjdk-8-jdk openjdk-8-jre 
ENV JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-ppc64el
ENV PATH=$JAVA_HOME/bin:$PATH
RUN apt-get install -y wget
RUN set -x \
	&& echo "Grab gosu for easy step-down from root..." \
	&& wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" \
	&& wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture).asc" \
	&& export GNUPGHOME="$(mktemp -d)" \
	&& gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
	&& gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
	&& rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
	&& chmod +x /usr/local/bin/gosu \
	&& gosu nobody true 

# Install ELK Required Dependancies
RUN set -x \
	&& apt-get -qq update \
	&& apt-get install -yq wget ca-certificates \
	&& echo "NOTE: the 'ffi-rzmq-core' gem is very picky about where it looks for libzmq.so" \
	&& mkdir -p /usr/local/lib && ln -s /usr/lib/*/libzmq.so.3 /usr/local/lib/libzmq.so \
	&& groupadd -r kibana && useradd -r -m -g kibana kibana \
	&& groupadd -r logstash && useradd -r -m -g logstash logstash \
	&& apt-get -qq update && apt-get -yq install apache2-utils \
                                               supervisor \
                                               libzmq3-dev \
						#elasticsearch \
                                               nginx --no-install-recommends \
  && apt-get purge -y --auto-remove wget \
  && apt-get clean \
  && apt-get autoclean \
  && apt-get autoremove \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
	&& echo "Creating Elasticsearch Paths..." \
	&& for path in \
		/opt/elasticsearch-2.4.1/data \
		/opt/elasticsearch-2.4.1/logs \
		/opt/elasticsearch-2.4.1/config \
		/opt/elasticsearch-2.4.1/config/scripts \
	; do \
	mkdir -p "$path"; \
	done

## Install elastic-search using tarball as the apt-get version fails not compatible with Kibana 
# source build failing on Ubuntu 
WORKDIR /opt
RUN apt-get -qq update && apt-get install -yq git wget
RUN wget https://download.elastic.co/elasticsearch/release/org/elasticsearch/distribution/tar/elasticsearch/2.4.1/elasticsearch-2.4.1.tar.gz
RUN tar -xvzf elasticsearch-2.4.1.tar.gz

# Install kibana
RUN apt-get -qq update && apt-get install -yq git wget
WORKDIR /opt
#RUN git clone https://github.com/elastic/kibana.git && cd kibana && git tag && git checkout v5.0.0-alpha1
RUN git clone https://github.com/elastic/kibana.git && cd kibana 
WORKDIR /opt/kibana
RUN git checkout 4.6
RUN apt-get -qq update && apt-get install -yq bcrypt make python g++ 
RUN wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.31.1/install.sh | sh
RUN bash -l -c 'nvm install "$(cat .node-version)"'
RUN bash -l -c "npm install"

# Configure Nginx
ADD config/nginx/kibana.conf /etc/nginx/sites-available/
RUN cd /opt \
	&& echo "Configuring Nginx..." \
	&& mkdir -p /var/www \
	&& ln -sf /dev/stdout /var/log/nginx/access.log \
	&& ln -sf /dev/stderr /var/log/nginx/error.log \
	&& echo "\ndaemon off;" >> /etc/nginx/nginx.conf \
	&& rm /etc/nginx/sites-enabled/default \
	&& ln -s /etc/nginx/sites-available/kibana.conf /etc/nginx/sites-enabled/kibana.conf

# install logstash 
RUN apt-get -qq update && apt-get install -yq git curl
WORKDIR /opt
RUN git clone https://github.com/elastic/logstash.git && cd logstash && git checkout 2.4
WORKDIR /opt/logstash
RUN curl -sSL https://rvm.io/mpapis.asc | gpg --import -
RUN curl -sSL https://get.rvm.io | bash -s --
RUN bash -l -c "rvm install jruby 1.7.25 && rvm use jruby-1.7.25"

ENV RUBY_PLATFORM=java
RUN wget http://archive.apache.org/dist/ant/binaries/apache-ant-1.9.4-bin.tar.gz && tar -xvzf apache-ant-1.9.4-bin.tar.gz
ENV ANT_HOME=/opt/logstash/apache-ant-1.9.4
ENV PATH=$ANT_HOME/bin:$PATH
RUN apt-get -qq update && apt-get install -yq unzip
RUN wget https://github.com/jnr/jffi/archive/master.zip && unzip master.zip && cd jffi-master #&& ant
RUN bash -l -c "rake bootstrap" # && rake test:install-core"


# Install Timelion Kibana Plugin
#RUN /opt/kibana/bin/kibana plugin -i kibana/timelion

# Add ELK PATHs
ENV PATH /opt/elasticsearch-2.4.1/bin:$PATH
ENV PATH /opt/logstash/bin:$PATH
ENV PATH /opt/kibana/bin:$PATH

# Add elastic config
COPY config/elastic /usr/share/elasticsearch/config
# Add admin/admin web user account
COPY config/nginx/htpasswd /etc/nginx/.htpasswd
# Add configs
COPY config/supervisord/supervisord.conf /etc/supervisor/conf.d/

# Add entrypoints
COPY entrypoints/logstash-entrypoint.sh /
COPY entrypoints/kibana-entrypoint.sh /
RUN chmod +x /*.sh

VOLUME ["/usr/share/elasticsearch/data"]
VOLUME ["/etc/logstash/conf.d"]
VOLUME ["/etc/nginx"]

EXPOSE 80 443 9200 9300
CMD [bash -l -c "/logstash-entrypoint.sh kibana -e 'input { stdin { } } output { stdout { } }'" && nohup elasticsearch && bash -l -c "kibana"] 
CMD ["/usr/bin/supervisord"]

