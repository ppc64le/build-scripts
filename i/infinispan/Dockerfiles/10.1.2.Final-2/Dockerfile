# Copyright 2019 Red Hat
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# ------------------------------------------------------------------------
#
# This is a Dockerfile for the infinispan/server:10.1.2.Final-2 image.


## START target image infinispan/server:10.1.2.Final-2
## \
    FROM registry.access.redhat.com/ubi8/ubi-minimal:8.0-213

    USER root

###### START module 'org.infinispan.dependencies.common:1.0'
###### \
        # Copy 'org.infinispan.dependencies.common' module content
        COPY modules/org.infinispan.dependencies.common /tmp/scripts/org.infinispan.dependencies.common
        # Switch to 'root' user to install 'org.infinispan.dependencies.common' module defined packages
        USER root
        # Install packages defined in the 'org.infinispan.dependencies.common' module
        RUN microdnf --setopt=tsflags=nodocs install -y bsdtar findutils iproute java-11-openjdk-headless lsof openssl procps-ng vim-minimal \
            && microdnf clean all \
            && rpm -q bsdtar findutils iproute java-11-openjdk-headless lsof openssl procps-ng vim-minimal
        # Custom scripts from 'org.infinispan.dependencies.common' module
        USER root
        RUN [ "sh", "-x", "/tmp/scripts/org.infinispan.dependencies.common/install.sh" ]
###### /
###### END module 'org.infinispan.dependencies.common:1.0'

###### START module 'org.infinispan.dependencies:infinispan'
###### \
        # Copy 'org.infinispan.dependencies' module content
        COPY modules/org.infinispan.dependencies /tmp/scripts/org.infinispan.dependencies
        # Custom scripts from 'org.infinispan.dependencies' module
        USER root
        RUN [ "sh", "-x", "/tmp/scripts/org.infinispan.dependencies/install.sh" ]
###### /
###### END module 'org.infinispan.dependencies:infinispan'

###### START module 'org.infinispan.runtime:1.0'
###### \
        # Copy 'org.infinispan.runtime' module general artifacts
        COPY \
            config-generator.jar \
            server.zip \
            /tmp/artifacts/
        # Copy 'org.infinispan.runtime' module content
        COPY modules/org.infinispan.runtime /tmp/scripts/org.infinispan.runtime
        # Custom scripts from 'org.infinispan.runtime' module
        USER root
        RUN [ "sh", "-x", "/tmp/scripts/org.infinispan.runtime/extract.sh" ]
###### /
###### END module 'org.infinispan.runtime:1.0'

###### START image 'infinispan/server:10.1.2.Final-2'
###### \
        # Copy 'infinispan/server' image general artifacts
        COPY \
            config-generator.jar \
            server.zip \
            /tmp/artifacts/
        # Set 'infinispan/server' image defined environment variables
        ENV \
            ISPN_HOME="/opt/infinispan" \
            JAVA_GC_MAX_METASPACE_SIZE="96m" \
            JAVA_GC_METASPACE_SIZE="32m" \
            JAVA_MAX_MEM_RATIO="50" \
            LAUNCH_ISPN_IN_BACKGROUND="True" 
        # Set 'infinispan/server' image defined labels
        LABEL \
            description="Infinispan Server"  \
            io.cekit.version="3.6.0"  \
            io.k8s.description="Provides a scalable in-memory distributed database designed for fast access to large volumes of data."  \
            io.k8s.display-name="Infinispan Server"  \
            io.openshift.expose-services="8080:http"  \
            io.openshift.s2i.scripts-url="image:///usr/local/s2i"  \
            io.openshift.tags="datagrid,java,jboss,xpaas"  \
            name="Infinispan Server"  \
            release="10.1.2.Final"  \
            summary="Infinispan Server"  \
            version="10.1.2.Final" 
        # Exposed ports in 'infinispan/server' image
        EXPOSE 2157 7800 11221 11222 45700 57600
###### /
###### END image 'infinispan/server:10.1.2.Final-2'


    # Switch to 'root' user and remove artifacts and modules
    USER root
    RUN [ ! -d /tmp/scripts ] || rm -rf /tmp/scripts
    RUN [ ! -d /tmp/artifacts ] || rm -rf /tmp/artifacts

    # Clear package manager metadata
    RUN microdnf clean all && [ ! -d /var/cache/yum ] || rm -rf /var/cache/yum

    # Define the user
    USER 185
    # Define the working directory
    WORKDIR /opt/infinispan
    # Define run cmd
    CMD ["./bin/launch.sh"]
## /
## END target image