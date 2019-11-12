-- Copyright (C) 2017 yushi studio <ywb94@qq.com> github.com/ywb94
-- Licensed to the public under the GNU General Public License v3.

local m, s,sec, o
local dnslist = "dnslist"
local uci = luci.model.uci.cursor()

m = Map(dnslist, translate("DNSCrypt Servers"))

-- [[ Servers Setting ]]--

sec = m:section(TypedSection, "server", translate("DNSCrypt Servers Manage"))
sec.anonymous = true
sec.addremove = true
sec.sortable = true
sec.template = "cbi/tblsection"
sec.extedit = luci.dispatcher.build_url("admin/services/shadowsocksr/dnscrypt-servers/%s")
function sec.create(...)
	local sid = TypedSection.create(...)
	if sid then
		luci.http.redirect(sec.extedit % sid)
		return
	end
end

o = sec:option(DummyValue, "name", translate("Resolver(name)"))
function o.cfgvalue(...)
	return Value.cfgvalue(...) or translate("None")
end

o = sec:option(DummyValue, "full_name", translate("Full Name"))
function o.cfgvalue(...)
	return Value.cfgvalue(...) or "?"
end

o = sec:option(DummyValue, "description", translate("Description"))
function o.cfgvalue(...)
	return Value.cfgvalue(...) or "?"
end

o = sec:option(DummyValue, "location", translate("Server Location"))
function o.cfgvalue(...)
	return Value.cfgvalue(...) or "?"
end

o = sec:option(DummyValue, "coordinates", translate("Geography Coordinates"))
function o.cfgvalue(...)
	return Value.cfgvalue(...) or "?"
end

o = sec:option(DummyValue, "url", translate("URL"))
function o.cfgvalue(...)
	return Value.cfgvalue(...) or "?"
end

o = sec:option(DummyValue, "version", translate("DNSCrypt Version"))
function o.cfgvalue(...)
	return Value.cfgvalue(...) or "?"
end

o = sec:option(DummyValue, "dnssec_validation", translate("DNSSec Validation"))
function o.cfgvalue(...)
	return Value.cfgvalue(...) or "0"
end

o = sec:option(DummyValue, "no_logs", translate("No Logs"))
function o.cfgvalue(...)
	return Value.cfgvalue(...) or "0"
end

o = sec:option(DummyValue, "namecoin", translate("NameCoin"))
function o.cfgvalue(...)
	return Value.cfgvalue(...) or "0"
end

o = sec:option(DummyValue, "resolver_address", translate("Resolver Address"))
function o.cfgvalue(...)
	return Value.cfgvalue(...) or "0"
end

o = sec:option(DummyValue, "provider_name", translate("Provider Name"))
function o.cfgvalue(...)
	return Value.cfgvalue(...) or "0"
end

o = sec:option(DummyValue, "provider_public_key", translate("Provider Public Key"))
function o.cfgvalue(...)
	return Value.cfgvalue(...) or "0"
end

o = sec:option(DummyValue, "provider_public_key_txt_record", translate("Provider Public_Key TXT Record"))
function o.cfgvalue(...)
	return Value.cfgvalue(...) or "0"
end

return m
