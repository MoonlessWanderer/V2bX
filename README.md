# V2bX

A V2board node server based on Xray. It supports VMess, VLESS, Trojan, and Shadowsocks.

This project is meant to be used with a [modified V2board](https://github.com/wyx2685/v2board).

## Features

* Free and open source.
* VMess, VLESS, Trojan, and Shadowsocks on the Xray core.
* VLESS, XTLS, and related newer options.
* One process can serve several nodes.
* Limit online IP addresses.
* Limit TCP connections.
* Speed limits per node port and per user.
* A small, readable config file.
* Editing the config restarts the instance automatically.

## What Xray supports

| Feature | vmess | vless | trojan | shadowsocks |
|-----------|-------|-------|--------|-------------|
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

V2bX runs on Linux: Ubuntu, Debian, CentOS and the RHEL family (Rocky, Alma, Oracle Linux), Alpine, and Arch. Builds are published for x86_64 and arm64.

### One-click install

```
wget -N https://raw.githubusercontent.com/MoonlessWanderer/V2bX/main/script/install.sh && bash install.sh
```

### Manual install

See the [manual install guide](https://v2bx.v-50.me/v2bx/v2bx-xia-zai-he-an-zhuang/install/manual).

## Build

```bash
# This build uses Go 1.27 and the Xray core.
GOEXPERIMENT=jsonv2 go build -v -o build_assets/V2bX -tags "xray" -trimpath -ldflags "-X 'github.com/InazumaV/V2bX/cmd.version=$version' -s -w -buildid="
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

## Star history

[![Stargazers over time](https://starchart.cc/MoonlessWanderer/V2bX.svg)](https://starchart.cc/MoonlessWanderer/V2bX)
