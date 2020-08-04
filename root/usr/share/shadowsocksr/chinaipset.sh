#!/bin/sh

mkdir -p /tmp/dnsmasq.ssr
fwd_port=${1}

echo "create china hash:net family inet hashsize 1024 maxelem 65536" > /tmp/china.ipset
awk '!/^$/&&!/^#/{printf("add china %s'" "'\n",$0)}' /etc/ssr/china_ssr.txt >> /tmp/china.list
ipset -! flush china
ipset -! restore < /tmp/china.ipset 2>/dev/null
rm -f /tmp/china.ipset

if [ -z "${fwd_port}" ]; then
awk '!/^$/&&!/^#/{printf("ipset=/.%s/'"china"'\n",$0)}' /etc/ssr/chnlist >> /tmp/dnsmasq.ssr/china.conf
else
awk '!/^$/&&!/^#/{printf("server=/.%s/'"127.0.0.1#${fwd_port}"'\n",$0)}' /etc/ssr/chnlist > /tmp/dnsmasq.oversea/china.conf
awk '!/^$/&&!/^#/{printf("ipset=/.%s/'"china"'\n",$0)}' /etc/ssr/chnlist >> /tmp/dnsmasq.oversea/china.conf
ln -s /tmp/dnsmasq.oversea/china.conf  /tmp/dnsmasq.ssr/china.conf
fi
