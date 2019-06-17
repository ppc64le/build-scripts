#
# Copyright (c) 2012-2019 Red Hat, Inc.
# This program and the accompanying materials are made
# available under the terms of the Eclipse Public License 2.0
# which is available at https://www.eclipse.org/legal/epl-2.0/
#
# SPDX-License-Identifier: EPL-2.0
#
# Contributors:
#   Red Hat, Inc. - initial API and implementation
#

FROM golang:1.10.3-alpine as builder
WORKDIR /go/src/github.com/eclipse/che-machine-exec/
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -a -ldflags '-w -s' -a -installsuffix cgo -o che-machine-exec .
RUN apk add --no-cache ca-certificates

RUN adduser -D -g '' unprivilegeduser

FROM scratch
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /go/src/github.com/eclipse/che-machine-exec/che-machine-exec /go/bin/che-machine-exec

USER unprivilegeduser

ENTRYPOINT ["/go/bin/che-machine-exec"]
