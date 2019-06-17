# Copyright (c) 2018 Red Hat, Inc.
# This program and the accompanying materials are made
# available under the terms of the Eclipse Public License 2.0
# which is available at https://www.eclipse.org/legal/epl-2.0/
#
# SPDX-License-Identifier: EPL-2.0
#
# Contributors:
#   Red Hat, Inc. - initial API and implementation

###
# Builder Image
#

FROM alpine:3.8

RUN mkdir -p /tmp/agent ;\
    mkdir -p /usr/agent/wsagent/webapps/;\
    mkdir -p /usr/agent/traefik ;\
    wget -O /usr/agent/traefik/traefik "https://github.com/containous/traefik/releases/download/v1.7.5/traefik_linux-ppc64le"; \
    chmod +x /usr/agent/traefik/traefik;\
    wget -O /tmp/tomcat8.zip "https://oss.sonatype.org/content/repositories/releases/org/eclipse/che/lib/che-tomcat8-slf4j-logback/6.16.0/che-tomcat8-slf4j-logback-6.16.0.zip" ;\
    unzip /tmp/tomcat8.zip -d /usr/agent/wsagent;

COPY traefik.toml traefik_conf.sh /usr/agent/traefik/
COPY eclipse-che/tomcat/webapps/ROOT.war /usr/agent/wsagent/webapps/ide.war
COPY eclipse-che/lib/ws-agent.tar.gz /tmp/agent
COPY eclipse-che/lib/linux_amd64/exec /tmp/agent
COPY eclipse-che/lib/linux_amd64/terminal /tmp/agent

RUN sed -i -- 's/autoDeploy=\"false\"/autoDeploy=\"true\"/g' /usr/agent/wsagent/conf/server.xml; \
    sed -i 's/<Context>/<Context reloadable=\"true\">/g' /usr/agent/wsagent/conf/context.xml ; \
    cd /tmp/agent && \
    tar -xf ws-agent.tar.gz && \
    tar -xf exec-agent-linux_amd64.tar.gz -C /usr/agent && \
    tar -xf websocket-terminal-linux_amd64.tar.gz -C /usr/agent && \
    cp webapps/ROOT.war /usr/agent/wsagent/webapps/ && cd && \
    rm -rf /tmp/agent 

FROM openjdk:8u181-jdk-alpine3.8

ENV HOME=/home/user
WORKDIR ${HOME}

RUN PACKAGES="ca-certificates supervisor git bash" && \
    apk update upgrade --no-cache && apk add --no-cache ${PACKAGES}


RUN adduser --disabled-password -S -u 1001 -G root -h ${HOME} -s /bin/sh user \
    && echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers \
    # Create /projects for Che
    && mkdir /projects \
    && touch /var/log/supervisord.log \
    && cat /etc/passwd | sed s#root:x.*#root:x:\${USER_ID}:\${GROUP_ID}::\${HOME}:/bin/bash#g > ${HOME}/passwd.template \
    && cat /etc/group | sed s#root:x:0:#root:x:0:0,\${USER_ID}:#g > ${HOME}/group.template \
    # Cleanup tmp folder
    && rm -rf /tmp/* \
    # Change permissions to allow editing of files for openshift user
     && for f in "${HOME}" "/etc/passwd" "/etc/group" "/var/log/" "/projects"; do\
               chgrp -R 0 ${f} && \
               chmod -R g+rwX ${f}; \
           done ;


USER user

ADD entrypoint.sh /entrypoint.sh
ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf


ENTRYPOINT ["/entrypoint.sh"]
CMD /usr/bin/supervisord -n -c /etc/supervisor/conf.d/supervisord.conf

