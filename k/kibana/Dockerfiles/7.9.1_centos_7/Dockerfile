# NOTE: This is based on the original work at https://github.com/elastic/dockerfiles/

# 
# ** THIS IS AN AUTO-GENERATED FILE **
#

################################################################################
# Build stage 0
# Extract Kibana and make various file manipulations.
################################################################################
FROM centos:7 AS prep_files
# Add tar and gzip
RUN yum update -y && yum install -y tar gzip && yum clean all

WORKDIR /root

RUN yum install -y autoconf automake bzip2 gcc-c++ git gzip libtool make openssl-devel python tar wget zlib-devel patch curl pixman-devel cairo cairo-devel cairomm-devel libjpeg-turbo-devel pango pango-devel pangomm pangomm-devel giflib-develi && \
    mkdir -p /usr/local/lib/nodejs && \
    wget https://nodejs.org/dist/v10.22.0/node-v10.22.0-linux-ppc64le.tar.gz && \
    tar xzvf node-v10.22.0-linux-ppc64le.tar.gz -C /usr/local/lib/nodejs && \
    ln -s /usr/local/lib/nodejs/node-v10.22.0-linux-ppc64le/bin/* /usr/bin/ && \
    curl -o- -L https://yarnpkg.com/install.sh | bash && \
    export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH" && \
    git clone https://github.com/elastic/kibana.git && \
    cd kibana && git checkout v7.9.1 && \
    wget https://raw.githubusercontent.com/linux-on-ibm-z/scripts/master/Kibana/7.9.1/patch/kibana_patch.diff && \
    sed -i s/s390x/ppc64le/g kibana_patch.diff && \
    git apply kibana_patch.diff && \
    wget https://raw.githubusercontent.com/linux-on-ibm-z/scripts/master/Kibana/7.9.1/patch/register_git_hook.diff && \
    git apply register_git_hook.diff && \
    groupadd kibana && useradd kibana -g kibana && chown kibana:kibana -R /root && \
    sed -i 's|await run(Tasks.OptimizeBuild);|//await run(Tasks.OptimizeBuild);|g' src/dev/build/build_distributables.ts && \
    sed -i '/Tasks.InstallChromium/d' src/dev/build/build_distributables.ts && \
    su kibana -c 'yarn kbn bootstrap --no-oss' && \
    su kibana -c 'yarn build --skip-os-packages --no-oss'

RUN mkdir /usr/share/kibana
WORKDIR /usr/share/kibana
RUN tar --strip-components=1 -zxf /root/kibana/target/kibana-7.9.1-SNAPSHOT-linux-ppc64le.tar.gz
# Ensure that group permissions are the same as user permissions.
# This will help when relying on GID-0 to run Kibana, rather than UID-1000.
# OpenShift does this, for example.
# REF: https://docs.openshift.org/latest/creating_images/guidelines.html
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
RUN echo "88b02a3bd014e4c30d8d54389597adc4f5a36d1d6b49200b5a4f6a71026c2246  /usr/local/bin/dumb-init" | sha256sum -c -
RUN chmod +x /usr/local/bin/dumb-init


# Bring in Kibana from the initial stage.
COPY --from=prep_files --chown=1000:0 /usr/share/kibana /usr/share/kibana
WORKDIR /usr/share/kibana
RUN ln -s /usr/share/kibana /opt/kibana
COPY --from=prep_files --chown=1000:0 /usr/local/lib/nodejs/node-v10.22.0-linux-ppc64le/bin/* /usr/bin/

ENV ELASTIC_CONTAINER true
ENV PATH=/usr/share/kibana/bin:$PATH

# Set some Kibana configuration defaults.
COPY --chown=1000:0 config/kibana.yml /usr/share/kibana/config/kibana.yml

# Add the launcher/wrapper script. It knows how to interpret environment
# variables and translate them to Kibana CLI options.
COPY --chown=1000:0 bin/kibana-docker /usr/local/bin/

# Ensure gid 0 write permissions for OpenShift.
RUN chmod g+ws /usr/share/kibana && find /usr/share/kibana -gid 0 -and -not -perm /g+w -exec chmod g+w {} \;

# Remove the suid bit everywhere to mitigate "Stack Clash"
RUN find / -xdev -perm -4000 -exec chmod u-s {} +

# Provide a non-root user to run the process.
RUN groupadd --gid 1000 kibana && useradd --uid 1000 --gid 1000 --home-dir /usr/share/kibana --no-create-home kibana
USER kibana

LABEL org.label-schema.schema-version="1.0" org.label-schema.vendor="Elastic" org.label-schema.name="kibana" org.label-schema.version="7.9.1" org.label-schema.url="https://www.elastic.co/products/kibana" org.label-schema.vcs-url="https://github.com/elastic/kibana" org.label-schema.license="Elastic License" org.label-schema.usage="https://www.elastic.co/guide/en/kibana/index.html" org.label-schema.build-date="2020-09-01T22:38:56.015Z" license="Elastic License"

ENTRYPOINT ["/usr/local/bin/dumb-init", "--"]

CMD ["/usr/local/bin/kibana-docker"]
