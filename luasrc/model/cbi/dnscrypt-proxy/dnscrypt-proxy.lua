-- Copyright (C) 2017 yushi studio <ywb94@qq.com> github.com/ywb94
-- Licensed to the public under the GNU General Public License v3.

local m, s, o
local dnscrypt_proxy="dnscrypt-proxy"
local dnslist = "dnslist"
local uci = luci.model.uci.cursor()
local sys = require "luci.sys"
local http = require "luci.http"
local disp = require "luci.dispatcher"

local function has_bin(name)
	return luci.sys.call("command -v %s >/dev/null" %{name}) == 0
end
local has_dnscrypt = has_bin("dnscrypt-proxy")

if not has_dnscrypt then
	return Map(dnscrypt_proxy, "%s - %s" %{translate("DNSCrypt Proxy"),
		translate("Golbal Setting")}, '<b style="color:red">DNSCrypt binary file not found.</b>')
end
m = Map(dnscrypt_proxy, translate("DNSCrypt Proxy"))

local dnslist_table = {}
uci:foreach(dnslist, "server", function(s)
	if s.name then
		dnslist_table[s.name] = "[%s]::%s" %{s.name, s.resolver_address}
	end
end)

-- [[ Servers Setting ]]--
s = m:section(TypedSection, "dnscrypt-proxy", translate("DNSCrypt Proxy"))
s.anonymous = true

o = s:option(Value, "address", translate("Listening address"))
o.default = "127.0.0.1"
o.datatype = "ip4addr"
o.rmempty = false

o = s:option(Value, "port", translate("Local Port"))
o.default = 5300
o.datatype = "port"
o.rmempty = false

o = s:option(ListValue, "resolver", translate("Select Resolver"))
o:value("nil", translate("Disable"))
for k, v in pairs(dnslist_table) do o:value(k, v) end
o.default = "nil"
o.rmempty = false

o = s:option(Value, "resolvers_list", translate("DNSCrypt Resolvers List"))
o:value("/usr/share/dnscrypt-proxy/dnscrypt-resolvers.csv", translate("Official DNSCrypt List"))
o.default = "/usr/share/dnscrypt-proxy/dnscrypt-resolvers.csv"
o.datatype = "or(file, '/dev/null')"
o.rmempty = false

o = s:option(Button, "refresh list")
o.title = translate("Update lists")
o.inputtitle = translate("Update lists")
o.description = translate("reload dns server list from file: ") .. "/usr/share/dnscrypt-proxy/dnscrypt-resolvers.csv"
o.inputstyle = "reload"
o.write = function()
	sys.call("sh /usr/share/dnscrypt-proxy/csv2conf.sh")
	http.redirect(disp.build_url("admin", "services", "shadowsocks", "dnscrypt-proxy"))
end


return m
