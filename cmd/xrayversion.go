//go:build xray

package cmd

import xcore "github.com/xtls/xray-core/core"

func xrayVersion() string {
	return xcore.Version()
}
