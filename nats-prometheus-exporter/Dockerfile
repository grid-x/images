FROM golang:1.9.2
RUN go get -v github.com/nats-io/prometheus-nats-exporter
WORKDIR /go/src/github.com/nats-io/prometheus-nats-exporter
RUN CGO_ENABLED=0 GOOS=linux go build .

FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=0 /go/src/github.com/nats-io/prometheus-nats-exporter/prometheus-nats-exporter .
ENTRYPOINT ["./prometheus-nats-exporter"]
