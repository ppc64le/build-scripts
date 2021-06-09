#Dockerfile
# ----------------------------------------------------------------------------
#
# Package          : kubeflow/admission-webhook
# Version          : latest
# Source repo      : https://github.com/kubeflow/kubeflow
# Tested on        : Fedora Linux release 5.7.16-200.fc32.ppc64le
# Passing Arguments: Configure with command no argument required
# Script License   : Apache License, Version 2 or later
# Maintainer       : Ujjwal Sharma <ujjwal.cpp@gmail.com> / Priya Seth<sethp@us.ibm.com>
#
# Disclaimer       : This Dockerfile has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this Dockerfile.
# Build the manager binary
ARG GOLANG_VERSION=1.12
FROM golang:${GOLANG_VERSION} as builder

# Copy in the go src
WORKDIR /go/src/github.com/kubeflow/kubeflow/components/admission-webhook
COPY pkg/  pkg/
COPY . .

ENV GO111MODULE=on

# Build
RUN if [ "$(uname -m)" = "aarch64" ]; then \
        CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -o webhook -a . ; \
    elif [ "$(uname -m)" = "ppc64le" ]; then \
        CGO_ENABLED=0 GOOS=linux GOARCH=ppc64le go build -o webhook -a . ; \
    else \
        CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o webhook -a . ; \
    fi
# Copy the controller-manager into a distroless image
FROM gcr.io/distroless/static-debian10:fd0d99e8c54d7d7b2f3dd29f5093d030d192cbbc
WORKDIR /
COPY --from=builder /go/src/github.com/kubeflow/kubeflow/components/admission-webhook/webhook .
ENTRYPOINT ["/webhook"]
