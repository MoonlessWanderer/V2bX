#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}Error: ${plain} Please run this script as root.\n" && exit 1

# check os
if [[ -f /etc/redhat-release ]]; then
    release="centos"
elif cat /etc/issue | grep -Eqi "alpine"; then
    release="alpine"
elif cat /etc/issue | grep -Eqi "debian"; then
    release="debian"
elif cat /etc/issue | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /etc/issue | grep -Eqi "centos|red hat|redhat|rocky|alma|oracle linux"; then
    release="centos"
elif cat /proc/version | grep -Eqi "debian"; then
    release="debian"
elif cat /proc/version | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /proc/version | grep -Eqi "centos|red hat|redhat|rocky|alma|oracle linux"; then
    release="centos"
elif cat /proc/version | grep -Eqi "arch"; then
    release="arch"
else
    echo -e "${red}We could not detect your system. Please contact the script author.${plain}\n" && exit 1
fi

# os version
if [[ -f /etc/os-release ]]; then
    os_version=$(awk -F'[= ."]' '/VERSION_ID/{print $3}' /etc/os-release)
fi
if [[ -z "$os_version" && -f /etc/lsb-release ]]; then
    os_version=$(awk -F'[= ."]+' '/DISTRIB_RELEASE/{print $2}' /etc/lsb-release)
fi

if [[ x"${release}" == x"centos" ]]; then
    if [[ ${os_version} -le 6 ]]; then
        echo -e "${red}Please use CentOS 7 or a newer release.${plain}\n" && exit 1
    fi
    if [[ ${os_version} -eq 7 ]]; then
        echo -e "${red}Note: CentOS 7 cannot use the Hysteria 1 or 2 protocols.${plain}\n"
    fi
elif [[ x"${release}" == x"ubuntu" ]]; then
    if [[ ${os_version} -lt 16 ]]; then
        echo -e "${red}Please use Ubuntu 16 or a newer release.${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"debian" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red}Please use Debian 8 or a newer release.${plain}\n" && exit 1
    fi
fi

confirm() {
    if [[ $# > 1 ]]; then
        echo && read -rp "$1 [default $2]: " temp
        if [[ x"${temp}" == x"" ]]; then
            temp=$2
        fi
    else
        read -rp "$1 [y/n]: " temp
    fi
    if [[ x"${temp}" == x"y" || x"${temp}" == x"Y" ]]; then
        return 0
    else
        return 1
    fi
}

confirm_restart() {
    confirm "Restart V2bX?" "y"
    if [[ $? == 0 ]]; then
        restart
    else
        show_menu
    fi
}

before_show_menu() {
    echo && echo -n -e "${yellow}Press Enter to return to the main menu: ${plain}" && read temp
    show_menu
}

install() {
    bash <(curl -Ls https://raw.githubusercontent.com/MoonlessWanderer/V2bX/main/script/install.sh)
    if [[ $? == 0 ]]; then
        if [[ $# == 0 ]]; then
            start
        else
            start 0
        fi
    fi
}

update() {
    if [[ $# == 0 ]]; then
        echo && echo -n -e "Enter a version (default: latest): " && read version
    else
        version=$2
    fi
    bash <(curl -Ls https://raw.githubusercontent.com/MoonlessWanderer/V2bX/main/script/install.sh) $version
    if [[ $? == 0 ]]; then
        echo -e "${green}Update complete. V2bX has been restarted. Use V2bX log to view the logs.${plain}"
        exit
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

config() {
    echo "V2bX will try to restart automatically after you save the config."
    if command -v nano >/dev/null 2>&1; then
        nano /etc/V2bX/config.json
    else
        vi /etc/V2bX/config.json
    fi
    sleep 2
    restart
    check_status
    case $? in
        0)
            echo -e "V2bX status: ${green}running${plain}"
            ;;
        1)
            echo -e "V2bX is not running, or the automatic restart failed. Would you like to view the logs? [Y/n]" && echo
            read -e -rp "(default: y):" yn
            [[ -z ${yn} ]] && yn="y"
            if [[ ${yn} == [Yy] ]]; then
               show_log
            fi
            ;;
        2)
            echo -e "V2bX status: ${red}not installed${plain}"
    esac
}

uninstall() {
    confirm "Are you sure you want to uninstall V2bX?" "n"
    if [[ $? != 0 ]]; then
        if [[ $# == 0 ]]; then
            show_menu
        fi
        return 0
    fi
    if [[ x"${release}" == x"alpine" ]]; then
        service V2bX stop
        rc-update del V2bX
        rm /etc/init.d/V2bX -f
    else
        systemctl stop V2bX
        systemctl disable V2bX
        rm /etc/systemd/system/V2bX.service -f
        systemctl daemon-reload
        systemctl reset-failed
    fi
    rm /etc/V2bX/ -rf
    rm /usr/local/V2bX/ -rf

    echo ""
    echo -e "V2bX was uninstalled. To remove this script as well, exit and run ${green}rm /usr/bin/V2bX -f${plain}."
    echo ""

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

start() {
    check_status
    if [[ $? == 0 ]]; then
        echo ""
        echo -e "${green}V2bX is already running. Choose restart if you want to restart it.${plain}"
    else
        if [[ x"${release}" == x"alpine" ]]; then
            service V2bX start
        else
            systemctl start V2bX
        fi
        sleep 2
        check_status
        if [[ $? == 0 ]]; then
            echo -e "${green}V2bX started. Use V2bX log to view the logs.${plain}"
        else
            echo -e "${red}V2bX may have failed to start. Please check the logs with V2bX log.${plain}"
        fi
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

stop() {
    if [[ x"${release}" == x"alpine" ]]; then
        service V2bX stop
    else
        systemctl stop V2bX
    fi
    sleep 2
    check_status
    if [[ $? == 1 ]]; then
        echo -e "${green}V2bX stopped.${plain}"
    else
        echo -e "${red}V2bX did not stop. It may need more than two seconds. Please check the logs shortly.${plain}"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

restart() {
    if [[ x"${release}" == x"alpine" ]]; then
        service V2bX restart
    else
        systemctl restart V2bX
    fi
    sleep 2
    check_status
    if [[ $? == 0 ]]; then
        echo -e "${green}V2bX restarted. Use V2bX log to view the logs.${plain}"
    else
        echo -e "${red}V2bX may have failed to start. Please check the logs with V2bX log.${plain}"
    fi
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

status() {
    if [[ x"${release}" == x"alpine" ]]; then
        service V2bX status
    else
        systemctl status V2bX --no-pager -l
    fi
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

enable() {
    if [[ x"${release}" == x"alpine" ]]; then
        rc-update add V2bX
    else
        systemctl enable V2bX
    fi
    if [[ $? == 0 ]]; then
        echo -e "${green}V2bX will now start on boot.${plain}"
    else
        echo -e "${red}Could not enable start on boot.${plain}"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

disable() {
    if [[ x"${release}" == x"alpine" ]]; then
        rc-update del V2bX
    else
        systemctl disable V2bX
    fi
    if [[ $? == 0 ]]; then
        echo -e "${green}V2bX will no longer start on boot.${plain}"
    else
        echo -e "${red}Could not disable start on boot.${plain}"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

show_log() {
    if [[ x"${release}" == x"alpine" ]]; then
        echo -e "${red}Log viewing is not available on Alpine yet.${plain}\n" && exit 1
    else
        journalctl -u V2bX.service -e --no-pager -f
    fi
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

install_bbr() {
    bash <(curl -L -s https://github.com/ylx2016/Linux-NetSpeed/raw/master/tcpx.sh)
}

update_shell() {
    wget -O /usr/bin/V2bX -N --no-check-certificate https://raw.githubusercontent.com/MoonlessWanderer/V2bX/main/script/V2bX.sh
    if [[ $? != 0 ]]; then
        echo ""
        echo -e "${red}Could not download the script. Please check that this machine can reach GitHub.${plain}"
        before_show_menu
    else
        chmod +x /usr/bin/V2bX
        echo -e "${green}The script was updated. Please run it again.${plain}" && exit 0
    fi
}

# 0: running, 1: not running, 2: not installed
check_status() {
    if [[ ! -f /usr/local/V2bX/V2bX ]]; then
        return 2
    fi
    if [[ x"${release}" == x"alpine" ]]; then
        temp=$(service V2bX status | awk '{print $3}')
        if [[ x"${temp}" == x"started" ]]; then
            return 0
        else
            return 1
        fi
    else
        # The status line is translated, so "Active" is not reliable. The exit code is.
        if systemctl is-active V2bX >/dev/null 2>&1; then
            return 0
        else
            return 1
        fi
    fi
}

check_enabled() {
    if [[ x"${release}" == x"alpine" ]]; then
        temp=$(rc-update show | grep V2bX)
        if [[ x"${temp}" == x"" ]]; then
            return 1
        else
            return 0
        fi
    else
        temp=$(systemctl is-enabled V2bX 2>/dev/null)
        if [[ x"${temp}" == x"enabled" ]]; then
            return 0
        else
            return 1;
        fi
    fi
}

check_uninstall() {
    check_status
    if [[ $? != 2 ]]; then
        echo ""
        echo -e "${red}V2bX is already installed. There is no need to install it again.${plain}"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 1
    else
        return 0
    fi
}

check_install() {
    check_status
    if [[ $? == 2 ]]; then
        echo ""
        echo -e "${red}Please install V2bX first.${plain}"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 1
    else
        return 0
    fi
}

show_status() {
    check_status
    case $? in
        0)
            echo -e "V2bX status: ${green}running${plain}"
            show_enable_status
            ;;
        1)
            echo -e "V2bX status: ${yellow}not running${plain}"
            show_enable_status
            ;;
        2)
            echo -e "V2bX status: ${red}not installed${plain}"
    esac
}

show_enable_status() {
    check_enabled
    if [[ $? == 0 ]]; then
        echo -e "Start on boot: ${green}yes${plain}"
    else
        echo -e "Start on boot: ${red}no${plain}"
    fi
}

generate_x25519_key() {
    echo -n "Generating an x25519 key: "
    /usr/local/V2bX/V2bX x25519
    echo ""
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

show_V2bX_version() {
    echo -n "V2bX version: "
    /usr/local/V2bX/V2bX version
    echo ""
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

add_node_config() {
    core_type="1"
    core="xray"
    core_xray=true
    while true; do
        read -rp "Please enter the node ID: " NodeID
        # Node ID must be a positive integer
        if [[ "$NodeID" =~ ^[0-9]+$ ]]; then
            break  # Valid input, leave the loop
        else
            echo "Please enter a valid number for the node ID."
        fi
    done

    while true; do
        echo -e "${yellow}Please choose a transport protocol:${plain}"
        echo -e "${green}1. Shadowsocks${plain}"
        echo -e "${green}2. Vless${plain}"
        echo -e "${green}3. Vmess${plain}"
        echo -e "${green}4. Trojan${plain}"
        read -rp "Please enter: " NodeType
        case "$NodeType" in
            1 ) NodeType="shadowsocks"; break ;;
            2 ) NodeType="vless"; break ;;
            3 ) NodeType="vmess"; break ;;
            4 ) NodeType="trojan"; break ;;
            * ) echo -e "${red}That choice is not valid. Xray supports Shadowsocks, Vless, Vmess, and Trojan.${plain}" ;;
        esac
    done
    if [ "$NodeType" == "vless" ]; then
        read -rp "Is this a Reality node? (y/n)" isreality
    fi

    if [[ "$isreality" != "y" && "$isreality" != "Y" &&  "$istls" != "y" ]]; then
        read -rp "Configure TLS? (y/n)" istls
    fi

    certmode="none"
    certdomain="example.com"
    if [[ "$isreality" != "y" && "$isreality" != "Y" && ( "$istls" == "y" || "$istls" == "Y" ) ]]; then
        echo -e "${yellow}Please choose a certificate mode:${plain}"
        echo -e "${green}1. http: request a certificate automatically. The node domain must already resolve.${plain}"
        echo -e "${green}2. dns: request a certificate automatically. You will need your DNS provider API credentials.${plain}"
        echo -e "${green}3. self: use a self-signed certificate, or an existing certificate file.${plain}"
        read -rp "Please enter: " certmode
        case "$certmode" in
            1 ) certmode="http" ;;
            2 ) certmode="dns" ;;
            3 ) certmode="self" ;;
        esac
        read -rp "Please enter the certificate domain (example.com): " certdomain
        if [ "$certmode" != "http" ]; then
            echo -e "${red}Please edit the config file yourself, then restart V2bX.${plain}"
        fi
    fi
    node_config=""
    if [ "$core_type" == "1" ]; then 
    node_config=$(cat <<EOF
{
            "Core": "$core",
            "ApiHost": "$ApiHost",
            "ApiKey": "$ApiKey",
            "NodeID": $NodeID,
            "NodeType": "$NodeType",
            "OutboundTag": "",
            "Timeout": 30,
            "ListenIP": "0.0.0.0",
            "SendIP": "0.0.0.0",
            "DeviceOnlineMinTraffic": 200,
            "MinReportTraffic": 0,
            "EnableProxyProtocol": false,
            "EnableUot": true,
            "EnableTFO": true,
            "DNSType": "UseIPv4",
            "CertConfig": {
                "CertMode": "$certmode",
                "RejectUnknownSni": false,
                "CertDomain": "$certdomain",
                "CertFile": "/etc/V2bX/fullchain.cer",
                "KeyFile": "/etc/V2bX/cert.key",
                "Email": "v2bx@github.com",
                "Provider": "cloudflare",
                "DNSEnv": {
                    "EnvName": "env1"
                }
            }
        },
EOF
)
    fi
    nodes_config+=("$node_config")
}

generate_config_file() {
    echo -e "${yellow}V2bX config file wizard${plain}"
    echo -e "${red}Please read the following notes:${plain}"
    echo -e "${red}1. This feature is still in testing.${plain}"
    echo -e "${red}2. The generated file is saved to /etc/V2bX/config.json.${plain}"
    echo -e "${red}3. The previous file is saved to /etc/V2bX/config.json.bak.${plain}"
    echo -e "${red}4. TLS support is only partial for now.${plain}"
    echo -e "${red}5. The generated config includes audit rules.${plain}"
    echo -e "${red}6. Continue? (y/n)${plain}"
    read -rp "Please enter: " continue_prompt
    if [[ "$continue_prompt" =~ ^[Nn][Oo]? ]]; then
        exit 0
    fi
    
    nodes_config=()
    first_node=true
    core_xray=false
    fixed_api_info=false
    check_api=false
    
    while true; do
        if [ "$first_node" = true ]; then
            read -rp "Please enter the panel URL (https://example.com): " ApiHost
            read -rp "Please enter the panel API key: " ApiKey
            read -rp "Use this panel URL and API key for every node? (y/n)" fixed_api
            if [ "$fixed_api" = "y" ] || [ "$fixed_api" = "Y" ]; then
                fixed_api_info=true
                echo -e "${red}The panel address is saved.${plain}"
            fi
            first_node=false
            add_node_config
        else
            read -rp "Add another node? (Press Enter to continue, or type n or no to finish)" continue_adding_node
            if [[ "$continue_adding_node" =~ ^[Nn][Oo]? ]]; then
                break
            elif [ "$fixed_api_info" = false ]; then
                read -rp "Please enter the panel URL: " ApiHost
                read -rp "Please enter the panel API key: " ApiKey
            fi
            add_node_config
        fi
    done

    # Initialize the core config array
    cores_config="["

    # Add the Xray core config when selected
    if [ "$core_xray" = true ]; then
        cores_config+="
    {
        \"Type\": \"xray\",
        \"Log\": {
            \"Level\": \"error\",
            \"ErrorPath\": \"/etc/V2bX/error.log\"
        },
        \"OutboundConfigPath\": \"/etc/V2bX/custom_outbound.json\",
        \"RouteConfigPath\": \"/etc/V2bX/route.json\"
    },"
    fi

    # Drop the trailing comma and close the array
    cores_config+="]"
    cores_config=$(echo "$cores_config" | sed 's/},]$/}]/')

    # Change to the config directory
    cd /etc/V2bX
    
    # Back up the previous config file
    mv config.json config.json.bak
    nodes_config_str="${nodes_config[*]}"
    formatted_nodes_config="${nodes_config_str%,}"

    # Create config.json
    cat <<EOF > /etc/V2bX/config.json
{
    "Log": {
        "Level": "error",
        "Output": ""
    },
    "Cores": $cores_config,
    "Nodes": [$formatted_nodes_config]
}
EOF
    
    # Create custom_outbound.json
    cat <<EOF > /etc/V2bX/custom_outbound.json
    [
        {
            "tag": "direct",
            "protocol": "freedom",
            "streamSettings": {
                "sockopt": {
                    "domainStrategy": "ForceIPv4"
                }
            }
        },
        {
            "protocol": "blackhole",
            "tag": "block"
        }
    ]
EOF
    
    # Create route.json
    cat <<EOF > /etc/V2bX/route.json
    {
        "domainStrategy": "AsIs",
        "rules": [
            {
                "type": "field",
                "outboundTag": "block",
                "ip": [
                    "geoip:private"
                ]
            },
            {
                "type": "field",
                "outboundTag": "block",
                "domain": [
                    "regexp:(api|ps|sv|offnavi|newvector|ulog.imap|newloc)(.map|).(baidu|n.shifen).com",
                    "regexp:(.+.|^)(360|so).(cn|com)",
                    "regexp:(Subject|HELO|SMTP)",
                    "regexp:(torrent|.torrent|peer_id=|info_hash|get_peers|find_node|BitTorrent|announce_peer|announce.php?passkey=)",
                    "regexp:(^.@)(guerrillamail|guerrillamailblock|sharklasers|grr|pokemail|spam4|bccto|chacuo|027168).(info|biz|com|de|net|org|me|la)",
                    "regexp:(.?)(xunlei|sandai|Thunder|XLLiveUD)(.)",
                    "regexp:(..||)(dafahao|mingjinglive|botanwang|minghui|dongtaiwang|falunaz|epochtimes|ntdtv|falundafa|falungong|wujieliulan|zhengjian).(org|com|net)",
                    "regexp:(ed2k|.torrent|peer_id=|announce|info_hash|get_peers|find_node|BitTorrent|announce_peer|announce.php?passkey=|magnet:|xunlei|sandai|Thunder|XLLiveUD|bt_key)",
                    "regexp:(.+.|^)(360).(cn|com|net)",
                    "regexp:(.*.||)(guanjia.qq.com|qqpcmgr|QQPCMGR)",
                    "regexp:(.*.||)(rising|kingsoft|duba|xindubawukong|jinshanduba).(com|net|org)",
                    "regexp:(.*.||)(netvigator|torproject).(com|cn|net|org)",
                    "regexp:(..||)(visa|mycard|gash|beanfun|bank).",
                    "regexp:(.*.||)(gov|12377|12315|talk.news.pts.org|creaders|zhuichaguoji|efcc.org|cyberpolice|aboluowang|tuidang|epochtimes|zhengjian|110.qq|mingjingnews|inmediahk|xinsheng|breakgfw|chengmingmag|jinpianwang|qi-gong|mhradio|edoors|renminbao|soundofhope|xizang-zhiye|bannedbook|ntdtv|12321|secretchina|dajiyuan|boxun|chinadigitaltimes|dwnews|huaglad|oneplusnews|epochweekly|cn.rfi).(cn|com|org|net|club|net|fr|tw|hk|eu|info|me)",
                    "regexp:(.*.||)(miaozhen|cnzz|talkingdata|umeng).(cn|com)",
                    "regexp:(.*.||)(mycard).(com|tw)",
                    "regexp:(.*.||)(gash).(com|tw)",
                    "regexp:(.bank.)",
                    "regexp:(.*.||)(pincong).(rocks)",
                    "regexp:(.*.||)(taobao).(com)",
                    "regexp:(.*.||)(laomoe|jiyou|ssss|lolicp|vv1234|0z|4321q|868123|ksweb|mm126).(com|cloud|fun|cn|gs|xyz|cc)",
                    "regexp:(flows|miaoko).(pages).(dev)"
                ]
            },
            {
                "type": "field",
                "outboundTag": "block",
                "ip": [
                    "127.0.0.1/32",
                    "10.0.0.0/8",
                    "fc00::/7",
                    "fe80::/10",
                    "172.16.0.0/12"
                ]
            },
            {
                "type": "field",
                "outboundTag": "block",
                "protocol": [
                    "bittorrent"
                ]
            }
        ]
    }
EOF

    echo -e "${green}The config file is ready. Restarting V2bX.${plain}"
    restart 0
    before_show_menu
}

# Open firewall ports
open_ports() {
    systemctl stop firewalld.service 2>/dev/null
    systemctl disable firewalld.service 2>/dev/null
    setenforce 0 2>/dev/null
    ufw disable 2>/dev/null
    iptables -P INPUT ACCEPT 2>/dev/null
    iptables -P FORWARD ACCEPT 2>/dev/null
    iptables -P OUTPUT ACCEPT 2>/dev/null
    iptables -t nat -F 2>/dev/null
    iptables -t mangle -F 2>/dev/null
    iptables -F 2>/dev/null
    iptables -X 2>/dev/null
    netfilter-persistent save 2>/dev/null
    echo -e "${green}Firewall ports are now open.${plain}"
}

show_usage() {
    echo "How to use the V2bX management script:"
    echo "------------------------------------------"
    echo "V2bX              - Show the management menu"
    echo "V2bX start        - Start V2bX"
    echo "V2bX stop         - Stop V2bX"
    echo "V2bX restart      - Restart V2bX"
    echo "V2bX status       - Show V2bX status"
    echo "V2bX enable       - Enable start on boot"
    echo "V2bX disable      - Disable start on boot"
    echo "V2bX log          - View V2bX logs"
    echo "V2bX x25519       - Generate an x25519 key"
    echo "V2bX generate     - Generate a V2bX config file"
    echo "V2bX update       - Update V2bX"
    echo "V2bX update x.x.x - Install a specific V2bX version"
    echo "V2bX install      - Install V2bX"
    echo "V2bX uninstall    - Uninstall V2bX"
    echo "V2bX version      - Show the V2bX version"
    echo "------------------------------------------"
}

# Prints V2bX and Xray version lines. The ASCII banner from `V2bX version` is ignored.
# An older binary that does not print an Xray line leaves that row out.
format_version_header() {
    local ver_out=$1
    local v2bx_ver xray_ver
    v2bx_ver=$(printf '%s\n' "$ver_out" | awk '/^V2bX / { print $2; exit }')
    xray_ver=$(printf '%s\n' "$ver_out" | awk '/^Xray / { print $2; exit }')
    if [[ -n "$v2bx_ver" ]]; then
        printf 'V2bX %s\n' "$v2bx_ver"
    else
        printf 'V2bX\n'
    fi
    if [[ -n "$xray_ver" ]]; then
        printf 'Xray %s\n' "$xray_ver"
    fi
}

# One "label|action" line per visible row. Numbers are assigned later, in order.
# status: 0 running, 1 stopped, 2 not installed. enabled: 0 boot on, otherwise off.
menu_entries() {
    local status=$1
    local enabled=$2
    if [[ $status -eq 2 ]]; then
        echo "Install|install"
        return
    fi
    echo "Uninstall|uninstall"
    if [[ $status -eq 0 ]]; then
        echo "Restart|restart"
        echo "Stop|stop"
    else
        echo "Start|start"
    fi
    echo "Update|update"
    echo "Generate config|generate_config_file"
    echo "Logs|show_log"
    echo "Edit config|config"
    echo "X25519 key|generate_x25519_key"
    if [[ $enabled -eq 0 ]]; then
        echo "No boot start|disable"
    else
        echo "Start on boot|enable"
    fi
}

show_menu() {
    local status enabled boot_text status_word status_color
    local menu_labels=() menu_actions=()
    local line num choice i

    enabled=1
    check_status
    status=$?

    if [[ $status -eq 2 ]]; then
        echo "V2bX"
        echo -e "${red}not installed${plain}"
    else
        format_version_header "$(/usr/local/V2bX/V2bX version 2>/dev/null)"
        check_enabled
        enabled=$?
        if [[ $status -eq 0 ]]; then
            status_word="running"
            status_color="$green"
        else
            status_word="stopped"
            status_color="$yellow"
        fi
        if [[ $enabled -eq 0 ]]; then
            boot_text="starts on boot"
        else
            boot_text="no boot start"
        fi
        echo -e "${status_color}${status_word}${plain}    ${boot_text}"
    fi
    echo

    while IFS= read -r line; do
        menu_labels+=("${line%%|*}")
        menu_actions+=("${line#*|}")
    done < <(menu_entries "$status" "$enabled")

    i=1
    for line in "${menu_labels[@]}"; do
        printf ' %d  %s\n' "$i" "$line"
        i=$((i + 1))
    done
    echo " 0  Exit"
    echo
    read -r -p "Please choose an option: " num
    num="${num#"${num%%[![:space:]]*}"}"
    num="${num%"${num##*[![:space:]]}"}"

    if [[ "$num" == "0" ]]; then
        exit 0
    fi
    if [[ "$num" =~ ^[0-9]+$ ]]; then
        choice=$((10#$num))
        if [[ $choice -ge 1 && $choice -le ${#menu_actions[@]} ]]; then
            "${menu_actions[$((choice - 1))]}"
            return
        fi
    fi
    echo -e "${red}Please enter a number from the list.${plain}"
    show_menu
}


if [[ $# > 0 ]]; then
    case $1 in
        "start") check_install 0 && start 0 ;;
        "stop") check_install 0 && stop 0 ;;
        "restart") check_install 0 && restart 0 ;;
        "status") check_install 0 && status 0 ;;
        "enable") check_install 0 && enable 0 ;;
        "disable") check_install 0 && disable 0 ;;
        "log") check_install 0 && show_log 0 ;;
        "update") check_install 0 && update 0 $2 ;;
        "config") config $* ;;
        "generate") generate_config_file ;;
        "install") check_uninstall 0 && install 0 ;;
        "uninstall") check_install 0 && uninstall 0 ;;
        "x25519") check_install 0 && generate_x25519_key 0 ;;
        "version") check_install 0 && show_V2bX_version 0 ;;
        "update_shell") update_shell ;;
        *) show_usage
    esac
else
    show_menu
fi
