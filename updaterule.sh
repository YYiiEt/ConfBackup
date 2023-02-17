#!/bin/bash
FILE_DIR="/etc/smartdns/sub-conf"

[ ! -d ${FILE_DIR} ] && mkdir -p ${FILE_DIR}

function download_rule()
{
    local rule_name=$1
    local rule_url=$2
    curl -SsL --connect-timeout 10 -m 30 --speed-time 15 --speed-limit 1 --retry 2 "$rule_url" -o /tmp/$rule_name 2>&1 | awk -v time="$(date "+%Y-%m-%d %H:%M:%S")" -v file=/tmp/"$rule_name" '{print time "【" file "】Download Failed:【"$0"】"}' >> /tmp/download.log
    if [ "${PIPESTATUS[0]}" -eq 0 ] && [ -z "$(grep "404: Not Found" /tmp/download.log)" ] && [ -z "$(grep "Package size exceeded the configured limit" /tmp/download.log)" ]; then
        echo "Download $rule_name success"
        mv /tmp/$rule_name ${FILE_DIR}/$rule_name >/dev/null 2>&1
        rm -rf /tmp/download.log >/dev/null 2>&1
    else
        echo "Download $rule_name fail"
        rm -rf /tmp/$rule_name >/dev/null 2>&1
        mv /tmp/download.log /tmp/fail.log >/dev/null 2>&1
    fi
}

function purge_rule()
{
    local rule_name=$1
    if [ -f ${FILE_DIR}/$rule_name ]; then
        sed -i "s/^$//g;s/\r//g;/^#/d;/regexp:/d;s/full://g" ${FILE_DIR}/$rule_name >/dev/null 2>&1
    else
        echo "File named $rule_name dosen't exist"
    fi
}

function generate_whitelist()
{
    local rule_name=$1
    if [ -f ${FILE_DIR}/$rule_name ]; then
        sed -i 's/^/whitelist-ip &/g' ${FILE_DIR}/$rule_name >/dev/null 2>&1
    else
        echo "File named $rule_name dosen't exist"
    fi
}

download_rule direct-list.txt https://fastly.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/direct-list.txt
purge_rule direct-list.txt
download_rule proxy-list.txt https://fastly.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/proxy-list.txt
purge_rule proxy-list.txt
download_rule whitelist-ip.conf https://fastly.jsdelivr.net/gh/Loyalsoldier/geoip@release/text/cn.txt
generate_whitelist whitelist-ip.conf
download_rule neodevhost.conf https://neodev.team/lite_smartdns.conf
