#!/bin/sh

mkdir -p /tmp/dnsmasq.ssr
fwd_port=${1}
oversea=${2}

[ -n "${gfw_port}" ] && {
awk '!/^$/&&!/^#/{printf("ipset=/.%s/'"gfwlist"'\n",$0)}' /etc/ssr/gfw.list > /tmp/dnsmasq.ssr/gfwlist.conf
[ -z "${fwd_port}" ] || awk '!/^$/&&!/^#/{printf("server=/.%s/'"127.0.0.1#${fwd_port}"'\n",$0)}' /etc/ssr/gfw.list >> /tmp/dnsmasq.ssr/gfwlist.conf
}

fwd_port=${fwd_port:-${oversea}}
awk '!/^$/&&!/^#/{printf("ipset=/.%s/'"blacklist"'\n",$0)}' /etc/ssr/black.list > /tmp/dnsmasq.ssr/blacklist.conf
awk '!/^$/&&!/^#/{printf("server=/.%s/'"127.0.0.1#${fwd_port}"'\n",$0)}' /etc/ssr/black.list >> /tmp/dnsmasq.ssr/blacklist.conf
ln -s /tmp/dnsmasq.ssr/blacklist.conf  /tmp/dnsmasq.oversea/china.conf

awk '!/^$/&&!/^#/{printf("ipset=/.%s/'"whitelist"'\n",$0)}' /etc/ssr/white.list > /tmp/dnsmasq.ssr/whitelist.conf
ln -s /dnsmasq.ssr/whitelist.conf  /tmp/dnsmasq.oversea/whitelist.conf
