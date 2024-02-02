// Code generated by mdatagen. DO NOT EDIT.

package metadata

import "go.opentelemetry.io/collector/confmap"

// MetricConfig provides common config for a particular metric.
type MetricConfig struct {
	Enabled bool `mapstructure:"enabled"`

	enabledSetByUser bool
}

func (ms *MetricConfig) Unmarshal(parser *confmap.Conf) error {
	if parser == nil {
		return nil
	}
	err := parser.Unmarshal(ms)
	if err != nil {
		return err
	}
	ms.enabledSetByUser = parser.IsSet("enabled")
	return nil
}

// MetricsConfig provides config for httpmetrics metrics.
type MetricsConfig struct {
	HttpmetricContentCount MetricConfig `mapstructure:"httpmetric.content_count"`
	HttpmetricDuration     MetricConfig `mapstructure:"httpmetric.duration"`
	HttpmetricError        MetricConfig `mapstructure:"httpmetric.error"`
	HttpmetricStatus       MetricConfig `mapstructure:"httpmetric.status"`
	HttpmetricTLS          MetricConfig `mapstructure:"httpmetric.tls"`
}

func DefaultMetricsConfig() MetricsConfig {
	return MetricsConfig{
		HttpmetricContentCount: MetricConfig{
			Enabled: true,
		},
		HttpmetricDuration: MetricConfig{
			Enabled: true,
		},
		HttpmetricError: MetricConfig{
			Enabled: true,
		},
		HttpmetricStatus: MetricConfig{
			Enabled: true,
		},
		HttpmetricTLS: MetricConfig{
			Enabled: true,
		},
	}
}

// ResourceAttributeConfig provides common config for a particular resource attribute.
type ResourceAttributeConfig struct {
	Enabled bool `mapstructure:"enabled"`

	enabledSetByUser bool
}

func (rac *ResourceAttributeConfig) Unmarshal(parser *confmap.Conf) error {
	if parser == nil {
		return nil
	}
	err := parser.Unmarshal(rac)
	if err != nil {
		return err
	}
	rac.enabledSetByUser = parser.IsSet("enabled")
	return nil
}

// ResourceAttributesConfig provides config for httpmetrics resource attributes.
type ResourceAttributesConfig struct {
	Tags ResourceAttributeConfig `mapstructure:"tags"`
}

func DefaultResourceAttributesConfig() ResourceAttributesConfig {
	return ResourceAttributesConfig{
		Tags: ResourceAttributeConfig{
			Enabled: false,
		},
	}
}

// MetricsBuilderConfig is a configuration for httpmetrics metrics builder.
type MetricsBuilderConfig struct {
	Metrics            MetricsConfig            `mapstructure:"metrics"`
	ResourceAttributes ResourceAttributesConfig `mapstructure:"resource_attributes"`
}

func DefaultMetricsBuilderConfig() MetricsBuilderConfig {
	return MetricsBuilderConfig{
		Metrics:            DefaultMetricsConfig(),
		ResourceAttributes: DefaultResourceAttributesConfig(),
	}
}
