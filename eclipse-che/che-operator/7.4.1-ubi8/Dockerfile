# Copyright (c) 2018-2019 Red Hat, Inc.
# This program and the accompanying materials are made
# available under the terms of the Eclipse Public License 2.0
# which is available at https://www.eclipse.org/legal/epl-2.0/
#
# SPDX-License-Identifier: EPL-2.0
#
# Contributors:
#   Red Hat, Inc. - initial API and implementation
#

# NOTE: using registry.access.redhat.com/rhel8/go-toolset does not work (user is requested to use registry.redhat.io)
# NOTE: using registry.redhat.io/rhel8/go-toolset requires login, which complicates automation
# NOTE: since updateBaseImages.sh does not support other registries than RHCC, update to RHEL8
# https://access.redhat.com/containers/?tab=tags#/registry.access.redhat.com/devtools/go-toolset-rhel7
FROM registry.access.redhat.com/devtools/go-toolset-rhel7:1.11.13-11.1571302666 as builder
ENV PATH=/opt/rh/go-toolset-1.11/root/usr/bin:$PATH \
    GOPATH=/go/

USER root
ADD . /go/src/github.com/eclipse/che-operator

# do no break RUN lines when building with UBI base images. https://projects.engineering.redhat.com/browse/OSBS-7398 & OSBS-7399
RUN cd /go/src/github.com/eclipse/che-operator && export MOCK_API=true && go test -v ./... && OOS=linux GOARCH=ppc64le CGO_ENABLED=0 go build -o /tmp/che-operator/che-operator /go/src/github.com/eclipse/che-operator/cmd/manager/main.go && cd ..

# https://access.redhat.com/containers/?tab=tags#/registry.access.redhat.com/ubi8-minimal
FROM registry.access.redhat.com/ubi8-minimal:8.0-213

ENV SUMMARY="Red Hat CodeReady Workspaces Operator container" \
    DESCRIPTION="Red Hat CodeReady Workspaces Operator container" \
    PRODNAME="codeready-workspaces" \
    COMPNAME="operator-rhel8"

LABEL summary="$SUMMARY" \
      description="$DESCRIPTION" \
      io.k8s.description="$DESCRIPTION" \
      io.k8s.display-name="$DESCRIPTION" \
      io.openshift.tags="$PRODNAME,$COMPNAME" \
      com.redhat.component="$PRODNAME-$COMPNAME-container" \
      name="$PRODNAME/$COMPNAME" \
      version="2.0" \
      license="EPLv2" \
      maintainer="Nick Boldt <nboldt@redhat.com>" \
      io.openshift.expose-services="" \
      com.redhat.delivery.appregistry="true" \
      usage=""

# not applicable to Che, only needed for CRW
# ADD controller-manifests /manifests

COPY --from=builder /tmp/che-operator/che-operator /usr/local/bin/che-operator
COPY --from=builder /go/src/github.com/eclipse/che-operator/deploy/keycloak_provision /tmp/keycloak_provision
COPY --from=builder /go/src/github.com/eclipse/che-operator/deploy/oauth_provision /tmp/oauth_provision
# apply CVE fixes, if required
RUN microdnf update -y libnghttp2 && microdnf clean all && rm -rf /var/cache/yum && echo "Installed Packages" && rpm -qa | sort -V && echo "End Of Installed Packages"
CMD ["che-operator"]
