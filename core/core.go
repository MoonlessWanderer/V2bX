package core

import (
	"errors"
	"strings"

	"github.com/InazumaV/V2bX/conf"
)

var (
	cores = map[string]func(c *conf.CoreConfig) (Core, error){}
)

func NewCore(c []conf.CoreConfig) (Core, error) {
	if len(c) == 0 {
		return nil, errors.New("no have vail core")
	}
	// multi core
	if len(c) > 1 {
		return NewSelector(c)
	}
	// one core
	if f, ok := cores[c[0].Type]; ok {
		return f(&c[0])
	}
	return nil, unregisteredCore(c[0].Type)
}

func unregisteredCore(coreType string) error {
	switch strings.ToLower(coreType) {
	case "sing", "hysteria2":
		return errors.New(coreType + " is temporarily disabled in this build. Use the xray core")
	default:
		return errors.New("unknown core type: " + coreType)
	}
}

func RegisterCore(t string, f func(c *conf.CoreConfig) (Core, error)) {
	cores[t] = f
}

func RegisteredCore() []string {
	cs := make([]string, 0, len(cores))
	for k := range cores {
		cs = append(cs, k)
	}
	return cs
}
