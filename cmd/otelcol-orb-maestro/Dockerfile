FROM golang:1.21-alpine as builder

RUN apk --update add ca-certificates git tzdata

WORKDIR /build

RUN go install go.opentelemetry.io/collector/cmd/builder@latest
COPY builder-config.yaml .
RUN builder --config=builder-config.yaml


FROM scratch

ARG USER_UID=10001

USER ${USER_UID}

COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt

COPY --from=builder /tmp/otelcol/otelcol-orb /otelcol-orb
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo
COPY example-config.yaml /config.yaml
EXPOSE 4317 55680 55679 13133
ENTRYPOINT ["/otelcol-orb"]
CMD ["--config", "/etc/otel/config.yaml"]