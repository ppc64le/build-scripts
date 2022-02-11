FROM golang:1.17.6-alpine as base
ARG ARCH=amd64
ARG VERSION
ARG COMMIT
ARG DATE
ENV GOOS=linux \
    CGO_ENABLED=0 \
    GOARCH=${ARCH}
RUN apk add --no-cache git
WORKDIR /app

COPY go.mod .
COPY go.sum .
RUN go mod download

COPY . .

## BUILDER STAGE ##
FROM base as builder
RUN go build -o conftest -ldflags="-w -s -X github.com/open-policy-agent/conftest/internal/commands.version=${VERSION}" main.go

## TEST STAGE ##
FROM base as test
RUN go test -v ./...

## ACCEPTANCE STAGE ##
FROM base as acceptance
COPY --from=builder /app/conftest /app/conftest

RUN apk add --no-cache npm bash
RUN npm install -g bats

#RUN bats acceptance.bats

## EXAMPLES STAGE ##
FROM base as examples
ARG ARCH
ENV TERRAFORM_VERSION=1.1.5 \
    KUSTOMIZE_VERSION=v4.5.2

COPY --from=builder /app/conftest /usr/local/bin
COPY examples /examples

WORKDIR /tmp
RUN apk add --no-cache npm make git jq ca-certificates openssl unzip wget bash curl && \
     if [ "$ARCH" = "ppc64le" ] ; then \
        wget -O /usr/local/bin/terraform https://oplab9.parqtec.unicamp.br/pub/ppc64el/terraform/terraform-${TERRAFORM_VERSION} && \
        chmod +x /usr/local/bin/terraform ; \
     else \
        wget "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" && \
        unzip "terraform_${TERRAFORM_VERSION}_linux_amd64.zip" -d /usr/local/bin ; \
    fi

RUN curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh ${KUSTOMIZE_VERSION}"  | bash

RUN go install cuelang.org/go/cmd/cue@latest

WORKDIR /examples

## RELEASE ##
FROM alpine:3.15.0

# Install git for protocols that depend on it when using conftest pull
RUN apk add --no-cache git

COPY --from=builder /app/conftest /
RUN ln -s /conftest /usr/local/bin/conftest
WORKDIR /project

ENTRYPOINT ["/conftest"]
CMD ["--help"]
