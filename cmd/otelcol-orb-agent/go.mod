// Code generated by "go.opentelemetry.io/collector/cmd/builder". DO NOT EDIT.

module go.opentelemetry.io/collector/cmd/builder

go 1.20

require (
	github.com/orb-community/otelcol-orb/receiver/httpmetricsreceiver v0.87.0
	go.opentelemetry.io/collector/receiver/otlpreceiver v0.87.0
	go.opentelemetry.io/collector/exporter/debugexporter v0.87.0
	github.com/open-telemetry/opentelemetry-collector-contrib/exporter/prometheusremotewriteexporter v0.91.0
	go.opentelemetry.io/collector/exporter/otlphttpexporter v0.87.0
	go.opentelemetry.io/collector/processor/batchprocessor v0.87.0
	go.opentelemetry.io/collector/otelcol v0.91.0
)

require (
	github.com/knadh/koanf/maps v0.1.1 // indirect
	github.com/knadh/koanf/providers/confmap v0.1.0 // indirect
)

replace github.com/orb-community/otelcol-orb/receiver/httpmetricsreceiver => ../../../receiver/httpmetricsreceiver
