-- Copyright (C) 2017 yushi studio <ywb94@qq.com> github.com/ywb94
-- Licensed to the public under the GNU General Public License v3.

local m, s, o
local dnslist = "dnslist"
local uci = luci.model.uci.cursor()
local fs = require "nixio.fs"
local sys = require "luci.sys"
local sid = arg[1]

local yesno = {
	"yes",
	"no",
}

m = Map(dnslist, translate("DNSCrypt Servers Manage"))
m.redirect = luci.dispatcher.build_url("admin/services/shadowsocksr/dnscrypt-servers")
if m.uci:get(dnslist, sid) ~= "server" then
	luci.http.redirect(m.redirect) 
	return
end

-- [[ Servers Setting ]]--
s = m:section(NamedSection, sid, "server")
s.anonymous = true
s.addremove   = false

o = s:option(Value, "name", translate("Resolver(name)"))
o.default = "opendns"
o.rmempty = false

o = s:option(Value, "full_name", translate("Full Name"))

o = s:option(Value, "description", translate("Description"))

o = s:option(Value, "location", translate("Server Location"))
o.placeholder = "eg: Amsterdam, The Netherlands"

o = s:option(Value, "coordinates", translate("Geography Coordinates"))
o.placeholder = "eg: 33.032501, 83.895699"

o = s:option(Value, "url", translate("URL"))
o.placeholder = "eg: https://a.b.com/abc.html"

o = s:option(Value, "version", translate("DNSCrypt Version"))
o.default = "1"
o.rmempty = false

o = s:option(ListValue, "dnssec_validation", translate("DNSSec Validation"))
for _, v in ipairs(yesno) do o:value(v) end
o.default = "no"
o.rmempty = false

o = s:option(ListValue, "no_logs", translate("No Logs"))
for _, v in ipairs(yesno) do o:value(v) end
o.default = "yes"
o.rmempty = false

o = s:option(ListValue, "namecoin", translate("NameCoin"))
for _, v in ipairs(yesno) do o:value(v) end
o.default = "no"
o.rmempty = false

o = s:option(Value, "resolver_address", translate("Resolver Address"))
o.placeholder = "eg: 8.8.8.8:53"
o.rmempty = false

o = s:option(Value, "provider_name", translate("Provider Name"))

o = s:option(Value, "provider_public_key", translate("Provider Public Key"))
o.placeholder = "eg: B831:5DD7:B14B:6EE3:20A4:70DC:2ED6:B1AA:398C:C9E5:86F8:5D45:45D6:B8C9:B500:5ABA"
o.rmempty = false

o = s:option(Value, "provider_public_key_txt_record", translate("Provider Public_Key TXT Record"))
o.placeholder = "pk.family.ns1.adguard.com"

return m
