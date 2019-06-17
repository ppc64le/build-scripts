# Copyright (c) 2012-2019 Red Hat, Inc.
# This program and the accompanying materials are made
# available under the terms of the Eclipse Public License 2.0
# which is available at https://www.eclipse.org/legal/epl-2.0/
#
# SPDX-License-Identifier: EPL-2.0
#
# Contributors:
#   Tyler Jewell - Initial Implementation
#

FROM centos:7

# install openssh needed to generate ssh keys
RUN yum update -y && yum install wget openssh -y \
    && wget https://yum.puppet.com/puppet/el/7/ppc64le/puppet-agent-6.0.3-1.el7.ppc64le.rpm \
    && rpm --install puppet-agent-6.0.3-1.el7.ppc64le.rpm \
    && rm -rf puppet-agent-6.0.3-1.el7.ppc64le.rpm \
    && cp ./opt/puppetlabs/bin/puppet /usr/bin/  \
    && mkdir -p /files \
    && mkdir -p /etc/puppet/modules \
    && mkdir -p /etc/puppet/manifests \
    && mkdir -p /files/docs

COPY manifests /etc/puppet/manifests
COPY modules /etc/puppet/modules
COPY entrypoint.sh /
RUN chmod +x entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]


