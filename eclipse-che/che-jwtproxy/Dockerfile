#
# Copyright (c) 2012-2018 Red Hat, Inc.
# This program and the accompanying materials are made
# available under the terms of the Eclipse Public License 2.0
# which is available at https://www.eclipse.org/legal/epl-2.0/
#
# SPDX-License-Identifier: EPL-2.0
#
# Contributors:
#   Red Hat, Inc. - initial API and implementation
#

FROM golang:1.10.3 as builder
WORKDIR /go/src/github.com/eclipse/che-jwtproxy/
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -a -ldflags '-w -s' -a -installsuffix cgo -o jwtproxy cmd/jwtproxy/main.go


FROM alpine:3.7
ENV XDG_CONFIG_HOME=/config/
VOLUME /config
COPY --from=builder /go/src/github.com/eclipse/che-jwtproxy/jwtproxy /usr/local/bin
ENTRYPOINT ["jwtproxy"]
CMD ["-config", "/config/config.yaml"]
