#Dockerfile for accesss-management component
# ----------------------------------------------------------------------------
#
# Package          : kubeflow
# Version          : latest
# Source repo      : https://github.com/kubeflow/kubeflow
# Tested on        : Fedora Linux release 5.7.16-200.fc32.ppc64le
# Passing Arguments: Configure with command no argument required
# Script License   : Apache License, Version 2 or later
# Maintainer       : Ujjwal Sharma <ujjwal.cpp@gmail.com> / Priya Seth<sethp@us.ibm.com>
#
# Disclaimer       : This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#


ARG GOLANG_VERSION=1.12.4
FROM golang:${GOLANG_VERSION} as builder

WORKDIR /workspace

COPY . .
RUN go mod download
RUN if [ "$(uname -m)" = "aarch64" ]; then \
        CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -gcflags 'all=-N -l' -o access-management main.go; \
    elif [ "$(uname -m)" = "ppc64le" ]; then \
        CGO_ENABLED=0 GOOS=linux GOARCH=ppc64le go build -gcflags 'all=-N -l' -o access-management main.go; \
    else \
        CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -gcflags 'all=-N -l' -o access-management main.go; \
    fi

RUN chmod a+rx access-management

# Use distroless as minimal base image to package the manager binary
# Refer to https://github.com/GoogleContainerTools/distroless for more details
FROM gcr.io/distroless/base:latest as serve
WORKDIR /
COPY third_party third_party
COPY --from=builder /workspace/access-management .
COPY --from=builder /go/pkg/mod/github.com/hashicorp third_party/library/

EXPOSE 8081

CMD ["/access-management"]

