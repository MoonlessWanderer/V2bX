# V2bX

A V2board node server with more than one core, based on XrayR. It supports VMess, VLESS, Trojan, Shadowsocks, Hysteria, and Hysteria2.

This project is meant to be used with a [modified V2board](https://github.com/wyx2685/v2board).

## Features

* Free and open source.
* VMess, VLESS, Trojan, Shadowsocks, and Hysteria 1/2.
* VLESS, XTLS, and related newer options.
* One process can serve several nodes.
* Limit online IP addresses.
* Limit TCP connections.
* Speed limits per node port and per user.
* A small, readable config file.
* Editing the config restarts the instance automatically.
* Several cores, and room to add more.
* Build only the cores you need.

## What each core supports

| Feature | v2ray | trojan | shadowsocks | hysteria1/2 |
|-----------|-------|--------|-------------|----------|
| Request a TLS certificate | yes | yes | yes | yes |
| Renew a TLS certificate | yes | yes | yes | yes |
| Online user count | yes | yes | yes | yes |
| Audit rules | yes | yes | yes | yes |
| Custom DNS | yes | yes | yes | yes |
| Online IP limit | yes | yes | yes | yes |
| Connection limit | yes | yes | yes | yes |
| IP limit across nodes | yes | yes | yes | yes |
| Per-user speed limit | yes | yes | yes | yes |
| Dynamic speed limit (not fully tested) | yes | yes | yes | yes |

## TODO

- [ ] Rebuild dynamic speed limits
- [ ] Finish the usage docs

## Install

### One-click install

```
wget -N https://raw.githubusercontent.com/MoonlessWanderer/V2bX/main/script/install.sh && bash install.sh
```

### Manual install

See the [manual install guide](https://v2bx.v-50.me/v2bx/v2bx-xia-zai-he-an-zhuang/install/manual).

## Build

```bash
# Choose cores with -tags. Options: xray, sing, hysteria2
GOEXPERIMENT=jsonv2 go build -v -o build_assets/V2bX -tags "sing xray hysteria2 with_quic with_grpc with_utls with_wireguard with_acme with_gvisor" -trimpath -ldflags "-X 'github.com/InazumaV/V2bX/cmd.version=$version' -s -w -buildid="
```

## Config and guide

The [usage guide](https://v2bx.v-50.me/) walks through the config file.

## Disclaimer

* This project is maintained for personal use, so backward compatibility is not guaranteed.
* Not every feature is guaranteed to work. If something breaks, please open an issue.
* You are responsible for how you use this project.
* The layout may change, sometimes in a large way. If that is a problem for you, please do not rely on this repository.

## Thanks

* [Project X](https://github.com/XTLS/)
* [V2Fly](https://github.com/v2fly)
* [VNet-V2ray](https://github.com/ProxyPanel/VNet-V2ray)
* [Air-Universe](https://github.com/crossfw/Air-Universe)
* [XrayR](https://github.com/XrayR/XrayR)
* [sing-box](https://github.com/SagerNet/sing-box)

## Star history

[![Stargazers over time](https://starchart.cc/MoonlessWanderer/V2bX.svg)](https://starchart.cc/MoonlessWanderer/V2bX)
