package xray

import (
	"strings"

	conf2 "github.com/InazumaV/V2bX/conf"
	"github.com/xtls/xray-core/core"
	"github.com/xtls/xray-core/infra/conf"
)

// BuildOutbound build freedom outbund config for addoutbound
func buildOutbound(config *conf2.Options, tag string) (*core.OutboundHandlerConfig, error) {
	outboundDetourConfig := &conf.OutboundDetourConfig{}
	outboundDetourConfig.Protocol = "freedom"
	outboundDetourConfig.Tag = tag

	// Build Send IP address
	if config.SendIP != "" {
		outboundDetourConfig.SendThrough = &config.SendIP
	}

	// Freedom's own domainStrategy is deprecated. The same value now belongs on sockopt.
	var domainStrategy = "AsIs"
	if config.XrayOptions.EnableDNS {
		if config.XrayOptions.DNSType != "" {
			domainStrategy = config.XrayOptions.DNSType
		} else {
			domainStrategy = "UseIP"
		}
	}
	if !strings.EqualFold(domainStrategy, "AsIs") {
		outboundDetourConfig.StreamSetting = &conf.StreamConfig{
			SocketSettings: &conf.SocketConfig{
				DomainStrategy: domainStrategy,
			},
		}
	}
	return outboundDetourConfig.Build()
}
