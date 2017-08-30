FROM ppc64le/openjdk:8-jdk
MAINTAINER Meghali Dhoble

ENV JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-ppc64el
ENV PATH=$JAVA_HOME/bin:$PATH
ENV RUBY_PLATFORM=java
ENV ANT_HOME=/opt/logstash/apache-ant-1.9.4
ENV PATH=$ANT_HOME/bin:$PATH


# Install ELK Required Dependancies
RUN set -x \
	&& apt-get -qq update \
	&& apt-get install -yq  ca-certificates \
	&& echo "NOTE: the 'ffi-rzmq-core' gem is very picky about where it looks for libzmq.so" \
	&& mkdir -p /usr/local/lib && ln -s /usr/lib/*/libzmq.so.3 /usr/local/lib/libzmq.so \
	&& groupadd -r kibana && useradd -r -m -g kibana kibana \
	&& groupadd -r logstash && useradd -r -m -g logstash logstash \
	&& apt-get -qq update && apt-get -yq install apache2-utils \
                                               supervisor \
                                               libzmq3-dev \
                                               nginx --no-install-recommends \
					       git \
					       bcrypt \
					       build-essential \
	#Install Elasticsearch
	&& cd /opt \
	&& wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-5.5.1.tar.gz \
	&& tar -xvzf elasticsearch-5.5.1.tar.gz \
	&& echo "Creating Elasticsearch Paths..." \
	&& for path in \
		/opt/elasticsearch-5.5.1/data \
		/opt/elasticsearch-5.5.1/logs \
		/opt/elasticsearch-5.5.1/config \
		/opt/elasticsearch-5.5.1/config/scripts \
	; do \
	mkdir -p "$path"; \
	done \
	#Install Kibana
	&& cd /opt \
	&& git clone https://github.com/elastic/kibana.git && cd kibana && git checkout v5.5.1 \
	&& wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.31.1/install.sh | sh \
	&& bash -l -c 'nvm install "$(cat .node-version)"' \
	&& bash -l -c "npm install" \
	#Install logstash
	&& cd /opt \
	&& git clone https://github.com/elastic/logstash.git && cd logstash && git checkout v5.5.1 \
	&& curl -sSL https://rvm.io/mpapis.asc | gpg --import - \
	&& curl -sSL https://get.rvm.io | bash -s -- \
	&& bash -l -c "rvm install jruby 1.7.25 && rvm use jruby-1.7.25" \
	&& cd /opt \
	&& wget http://archive.apache.org/dist/ant/binaries/apache-ant-1.9.4-bin.tar.gz && tar -xvzf apache-ant-1.9.4-bin.tar.gz \
	&& wget https://github.com/jnr/jffi/archive/master.zip && unzip master.zip && cd jffi-master \
	&& bash -l -c "rake bootstrap" # && rake test:install-core"

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

# Add ELK PATHs
ENV PATH /opt/elasticsearch-5.5.1/bin:$PATH
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
RUN chmod +x /*.sh

VOLUME ["/usr/share/elasticsearch/data"]
VOLUME ["/etc/logstash/conf.d"]
VOLUME ["/etc/nginx"]

EXPOSE 80 443 9200 9300
CMD [bash -l -c "/logstash-entrypoint.sh kibana -e 'input { stdin { } } output { stdout { } }'" && nohup elasticsearch && bash -l -c "kibana"] 
CMD ["/usr/bin/supervisord"]

