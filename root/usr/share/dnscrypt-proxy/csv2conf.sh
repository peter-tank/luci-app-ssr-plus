#!/bin/sh -e

gen_dnscrypt_config()
{
input=$1
read first_line < $input
first_line=$(echo "${first_line}" | awk '{print tolower($x)}' | sed -e 's/"//g' -e 's/ /_/g')
attributes=$(echo "${first_line}" | awk -F, {'print NF'})
lines=$(cat $input | wc -l)

ix=0
while [ $ix -lt $lines ]
do
	read each_line
	#fix ,'" delmi
	each_line=$(echo "${each_line}" | sed -e 's/, /-/g' -e 's/'"'"'/#/g' | sed -e 's/"//g')
	if [ $ix -ne 0 ]; then
		d=0
		echo "config server"
		while [ $d -lt $attributes ]
		do
			d=$(($d+1))
			op=$(echo "${first_line}" | awk -v x=$d -F',' '{print "option",$x}')
			val=$(echo "${each_line}" | awk -v y=$d -F',' '{print $y}')
			[ -n "$val" ] && echo "	"$op" '"$val"'"
			[ $d -eq $attributes ] && echo ""
		done
	fi
	ix=$(($ix+1))
done < $input
}

if [ -f "/usr/share/dnscrypt-proxy/dnscrypt-resolvers.csv" ]; then
gen_dnscrypt_config /usr/share/dnscrypt-proxy/dnscrypt-resolvers.csv > /tmp/dns.txt
datestr=`date`
echo -e "# dnscrypt server list for dnscrypt-proxy\n# updated on $datestr\n#">/etc/config/dnslist
cat /tmp/dns.txt >>/etc/config/dnslist
rm -f /tmp/dns.txt
fi
