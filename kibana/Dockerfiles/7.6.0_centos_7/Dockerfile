FROM centos:7 AS prep_files

ENV WORKDIR=/root

RUN yum update -y  && yum install -y shadow-utils curl gnupg ca-certificates python gcc-c++ make git wget \
	&& cd $WORKDIR \
	&& curl -sL https://raw.githubusercontent.com/creationix/nvm/v0.34.0/install.sh -o install_nvm.sh \
	&& sh install_nvm.sh && source /root/.nvm/nvm.sh \
	&& nvm install 10.18.0 && nvm use 10.18.0 && npm install -g yarn \
	&& cd /root && git clone https://github.com/elastic/kibana.git \
	&& cd kibana && git checkout v7.6.0 && nvm use \
	&& sed -i '385d' /root/kibana/package.json \
        && sed -i '40s/git-common-dir/git-dir/' /root/kibana/src/dev/register_git_hook/register_git_hook.js \ 
	&& sed -i '7s/#server.host: "localhost"/server.host: "0.0.0.0"/' /root/kibana/config/kibana.yml \
	&& sed -i '28s/localhost:9200/elasticsearch:9200/' /root/kibana/config/kibana.yml \
	&& groupadd kibana && useradd kibana -g kibana && chown kibana:kibana -R /root \
	&& sed -i 's|NODE="${DIR}/node/bin/node"|NODE=/usr/bin/node|g' bin/kibana \
	&& sed -i 's|--no-warnings|--no-warnings --max_old_space_size=8192|g' bin/kibana \
	&& wget https://patch-diff.githubusercontent.com/raw/elastic/kibana/pull/57133.diff \
	&& git apply 57133.diff \
	&& su kibana -c 'yarn kbn bootstrap' 

RUN mkdir -p /usr/share/kibana/ && mv /root/kibana/* /usr/share/kibana/ 

WORKDIR /usr/share/kibana

RUN chmod -R g=u /usr/share/kibana
	
RUN find /usr/share/kibana -type d -exec chmod g+s {} \;

################################################################################
# Build stage 1
# Copy prepared files from the previous stage and complete the image.
################################################################################
FROM centos:7
EXPOSE 5601

# Add Reporting dependencies.
RUN yum update -y && yum install -y fontconfig freetype shadow-utils && yum clean all

# Add an init process, check the checksum to make sure it's a match
RUN curl -L -o /usr/local/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v1.2.2/dumb-init_1.2.2_ppc64le
#RUN echo "37f2c1f0372a45554f1b89924fbb134fc24c3756efaedf11e07f599494e0eff9  /usr/local/bin/dumb-init" | sha256sum -c -
RUN chmod +x /usr/local/bin/dumb-init


# Bring in Kibana from the initial stage.
COPY --from=prep_files --chown=1000:0 /usr/share/kibana /usr/share/kibana
WORKDIR /usr/share/kibana
RUN ln -s /usr/share/kibana /opt/kibana
COPY --from=prep_files --chown=1000:0 /root/.nvm/versions/node/v10.18.0/bin/* /usr/bin/

ENV ELASTIC_CONTAINER true
ENV PATH=/usr/share/kibana/bin:$PATH

# Set some Kibana configuration defaults.
COPY --chown=1000:0 config/kibana.yml /usr/share/kibana/config/kibana.yml

# Add the launcher/wrapper script. It knows how to interpret environment
# variables and translate them to Kibana CLI options.
COPY --chown=1000:0 bin/kibana-docker /usr/local/bin/

# Ensure gid 0 write permissions for OpenShift.
RUN chmod g+ws /usr/share/kibana && find /usr/share/kibana -gid 0 -and -not -perm /g+w -exec chmod g+w {} \;

# Provide a non-root user to run the process.
RUN groupadd --gid 1000 kibana && useradd --uid 1000 --gid 1000 --home-dir /usr/share/kibana --no-create-home kibana
USER kibana

LABEL org.label-schema.schema-version="1.0" org.label-schema.vendor="Elastic" org.label-schema.name="kibana" org.label-schema.version="7.6.0" org.label-schema.url="https://www.elastic.co/products/kibana" org.label-schema.vcs-url="https://github.com/elastic/kibana" org.label-schema.license="Elastic License" org.label-schema.usage="https://www.elastic.co/guide/en/kibana/index.html" org.label-schema.build-date="2020-02-29T01:05:44.941Z" license="Elastic License"

ENTRYPOINT ["/usr/local/bin/dumb-init", "--"]

CMD ["/usr/local/bin/kibana-docker"]



