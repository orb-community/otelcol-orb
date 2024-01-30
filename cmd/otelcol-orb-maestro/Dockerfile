FROM golang:1.21.6-alpine as builder

RUN apk --update add ca-certificates git tzdata
RUN go install go.opentelemetry.io/collector/cmd/builder@latest

WORKDIR /go/src/github.com/orbcommunity/otelcol-orb

COPY go.mod .

RUN go mod tidy

COPY . .

COPY cmd/otelcol-orb-maestro/builder-config.yaml .
COPY cmd/otelcol-orb-maestro/example-config.yaml .

RUN builder --config=builder-config.yaml


FROM scratch

ARG USER_UID=10001

USER ${USER_UID}

COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt

COPY --from=builder /tmp/otelcol/otelcol-orb /otelcol-orb
COPY --from=builder /tmp/otelcol/example-config.yaml /etc/otel/config.yaml
EXPOSE 4317 55680 55679 13133
ENTRYPOINT ["/otelcol-orb"]
CMD ["--config", "/etc/otel/config.yaml"]