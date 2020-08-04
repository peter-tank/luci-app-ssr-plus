-- Copyright (C) 2017 yushi studio <ywb94@qq.com> github.com/ywb94
-- Copyright (C) 2018 lean <coolsnowwolf@gmail.com> github.com/coolsnowwolf
-- Licensed to the public under the GNU General Public License v3.

local m, s, sec, o, kcp_enable
local shadowsocksr = "shadowsocksr"
local uci = luci.model.uci.cursor()

local sys = require "luci.sys"

m = Map(shadowsocksr, translate("ShadowSocksR Plus+ Settings"))

m:section(SimpleSection).template  = "shadowsocksr/status"

local server_table = {}
uci:foreach(shadowsocksr, "servers", function(s)
	if s.alias then
		server_table[s[".name"]] = "[%s]:%s" %{string.upper(s.type), s.alias}
	elseif s.server and s.server_port then
		server_table[s[".name"]] = "[%s]:%s:%s" %{string.upper(s.type), s.server, s.server_port}
	end
end)

local key_table = {}   
for key,_ in pairs(server_table) do  
    table.insert(key_table,key)  
end 

table.sort(key_table)  

-- [[ Global Setting ]]--
s = m:section(TypedSection, "global")
s.anonymous = true

s:tab("Main", translate("Main"))

o = s:taboption("Main", ListValue, "global_server", translate("TCP Proxy Node"))
o:value("nil", translate("Disable"))
for _,key in pairs(key_table) do o:value(key,server_table[key]) end
o.default = "nil"
o.rmempty = false

o = s:taboption("Main", ListValue, "udp_relay_server", translate("UDP Proxy Node"))
o:value("nil", translate("Disable"))
o:value("same", translate("Same as Global Server"))
for _,key in pairs(key_table) do o:value(key,server_table[key]) end

o = s:taboption("Main", Value, "threads", translate("Multi Threads Option"))
o:value("0", translate("Auto Threads"))
o:value("1", translate("1 Thread"))
o:value("2", translate("2 Threads"))
o.default = "0"
o.rmempty = false

o = s:taboption("Main", ListValue, "run_mode", translate("Running Mode"))
o:value("gfw", translate("GFW List Mode"))
o:value("router", translate("China List Mode"))
o:value("all", translate("Global Mode"))
o:value("oversea", translate("Proxy China Mode"))
o.default = "gfw"

o = s:taboption("Main", Value, "dports", translate("Proxy Ports"), translate("All Ports") .. ": 1:65535" .. "，" .. translate("Only Common Ports") .. ": 22,53,587,465,995,993,143,80,443,8443,5353")
o:value("1:65535", translate("All Ports"))
o:value("22,53,587,465,995,993,143,80,443,8443,5353", translate("Only Common Ports"))
o.default = "1:65535"
o.rmempty = false

s:tab("DNS", translate("DNS"))

o = s:taboption("DNS", ListValue, "dns_mode", translate("DNS Hijack"),
	translate("Pdnsd: listening on local 5335, perform TCP DNS query only.<br />Pdnsd+Node: DNS requests encrypt and routed by 'UDP Proxy Node' then forward to ") .. translate("Anti-pollution DNS Server"))
o.widget  = "radio"
o.orientation = "horizontal"
o:value("pdnsd", translate("Pdnsd"))
o:value("pdnsd+node", translate("Pdnsd+Node"))
o:value("local", translate("Local 5335"))
o.default = "pdnsd"
o.rmempty = false

o = s:taboption("DNS", Value, "tunnel_forward", translate("Anti-pollution DNS Server"),
	[[<font color='red'>]] .. luci.util.pcdata(translate("DNS Forward works with type of V2Ray & Trojan UDP proxy nodes only, and listening to local port 5353, local addresses fallback to '8.8.4.4:53' when at 'Pdnsd+Node' mode and only the first valid is used.")) .. [[</font>]])
o:value("127.0.0.1:5353", translate("Local (127.0.0.1:5353)"))
o:value("8.8.4.4:53", translate("Google Public DNS (8.8.4.4)"))
o:value("8.8.8.8:53", translate("Google Public DNS (8.8.8.8)"))
o:value("208.67.222.222:53", translate("OpenDNS (208.67.222.222)"))
o:value("208.67.220.220:53", translate("OpenDNS (208.67.220.220)"))
o:value("209.244.0.3:53", translate("Level 3 Public DNS (209.244.0.3)"))
o:value("209.244.0.4:53", translate("Level 3 Public DNS (209.244.0.4)"))
o:value("4.2.2.1:53", translate("Level 3 Public DNS (4.2.2.1)"))
o:value("4.2.2.2:53", translate("Level 3 Public DNS (4.2.2.2)"))
o:value("4.2.2.3:53", translate("Level 3 Public DNS (4.2.2.3)"))
o:value("4.2.2.4:53", translate("Level 3 Public DNS (4.2.2.4)"))
o:value("1.1.1.1:53", translate("Cloudflare DNS (1.1.1.1)"))
o:value("114.114.114.114:53", translate("Oversea Mode DNS-1 (114.114.114.114)"))
o:value("114.114.115.115:53", translate("Oversea Mode DNS-2 (114.114.115.115)"))
o:depends("dns_mode", "pdnsd")
o:depends("dns_mode", "pdnsd+node")

o = s:taboption("DNS", Value, "fallback_dns", translate("Fallback DNS"), [[<font color='red'>]] .. translate("Should support TCP query when at 'Pdnsd' mode.") .. [[</font>]])
o.default = "208.67.222.222, 208.67.220.220"
o.rmempty = false

o = s:taboption("DNS", Value, "fallback_dns_port", translate("Fallback DNS Port"))
o.datatype = "port"
o.default = 5353
o.rmempty = false

-- [[ Socks5 Proxy ]]--
s = m:section(TypedSection, "socks5_proxy", translate("Socks5 Proxy"))
s.anonymous = true

o = s:option(ListValue, "server", translate("Select Node"))
o:value("nil", translate("Disable"))
o:value("same", translate("Same as UDP Server"))
for _,key in pairs(key_table) do o:value(key,server_table[key]) end
o:value("same", translate("Same as UDP Server"))
o.default = "nil"
o.rmempty = false

o = s:option(Value, "local_address", translate("Server Address"))
o.datatype = "host"
o.default = "0.0.0.0"
o.rmempty = false

o = s:option(Value, "local_port", translate("Local Port"))
o.datatype = "port"
o.default = 1080
o.rmempty = false

return m

