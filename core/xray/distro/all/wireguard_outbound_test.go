package all

import (
	"encoding/json"
	"testing"

	coreConf "github.com/xtls/xray-core/infra/conf"
)

func TestCustomOutboundProtocolsBuild(t *testing.T) {
	cases := map[string]string{
		"freedom": `{
			"tag": "direct",
			"protocol": "freedom",
			"streamSettings": {"sockopt": {"domainStrategy": "ForceIPv4"}}
		}`,
		"wireguard": `{
			"tag": "wireguard",
			"protocol": "wireguard",
			"settings": {
				"secretKey": "YWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWFhYWE=",
				"address": ["10.0.0.2/32"],
				"peers": [{
					"publicKey": "YmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmJiYmI=",
					"endpoint": "127.0.0.1:51820"
				}]
			}
		}`,
		"blackhole": `{
			"protocol": "blackhole",
			"tag": "block"
		}`,
	}
	for name, raw := range cases {
		t.Run(name, func(t *testing.T) {
			var cfg coreConf.OutboundDetourConfig
			if err := json.Unmarshal([]byte(raw), &cfg); err != nil {
				t.Fatal(err)
			}
			if _, err := cfg.Build(); err != nil {
				t.Fatal(err)
			}
		})
	}
}
