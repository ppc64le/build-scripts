FROM golang:1.12-alpine3.9 as builder
RUN apk add --no-cache ca-certificates
RUN adduser -D -g '' appuser
WORKDIR /go/src/github.com/eclipse/che-plugin-broker/brokers/unified/cmd/
COPY . /go/src/github.com/eclipse/che-plugin-broker/
RUN CGO_ENABLED=0 GOOS=linux go build -a -ldflags '-w -s' -installsuffix cgo -o unified-broker main.go


FROM alpine:3.9
USER appuser
COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /go/src/github.com/eclipse/che-plugin-broker/brokers/unified/cmd/unified-broker /
ENTRYPOINT ["/unified-broker"]
