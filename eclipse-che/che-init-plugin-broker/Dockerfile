FROM golang:1.12-alpine3.9 as builder
RUN apk add --no-cache ca-certificates
RUN adduser -D -g '' appuser
WORKDIR /go/src/github.com/eclipse/che-plugin-broker/brokers/init/cmd/
COPY . /go/src/github.com/eclipse/che-plugin-broker/
RUN CGO_ENABLED=0 GOOS=linux go build -a -ldflags '-w -s' -installsuffix cgo -o init-plugin-broker main.go


FROM scratch
USER appuser
COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /go/src/github.com/eclipse/che-plugin-broker/brokers/init/cmd/init-plugin-broker /
ENTRYPOINT ["/init-plugin-broker"]
