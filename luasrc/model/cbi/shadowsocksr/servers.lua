-- Licensed to the public under the GNU General Public License v3.

local m, s, o
local shadowsocksr = "shadowsocksr"

local uci = luci.model.uci.cursor()
local server_count = 0
uci:foreach("shadowsocksr", "servers", function(s)
  server_count = server_count + 1
end)

local fs  = require "nixio.fs"
local sys = require "luci.sys"

local function is_finded(e)
    return luci.sys.exec('type -t -p "%s/%s" "%s"' % {/usr/bin/v2ray, e, e}) ~= "" and true or false
end

m = Map(shadowsocksr,  translate("Servers subscription and manage"))

-- Server Subscribe

s = m:section(TypedSection, "server_subscribe")
s.anonymous = true

o = s:option(Button,"subscribe", translate("Update All Subscribe Severs"))
o.rawhtml  = true
o.template = "shadowsocksr/subscribe_nodes"

o = s:option(Button,"delete",translate("Delete all severs"))
o.inputstyle = "reset"
o.description = string.format(translate("Server Count") ..  ": %d", server_count)
o.write = function()
  uci:delete_all("shadowsocksr", "servers", function(s) return true end)
  uci:save("shadowsocksr") 
  luci.sys.call("uci commit shadowsocksr && /etc/init.d/shadowsocksr stop") 
  luci.http.redirect(luci.dispatcher.build_url("admin", "services", "shadowsocksr", "servers"))
  return
end

-- [[ Servers Manage ]]--
s = m:section(TypedSection, "servers")
s.anonymous = true
s.addremove = true
s.sortable = false
s.template = "cbi/tblsection"
s.extedit = luci.dispatcher.build_url("admin/services/shadowsocksr/servers/%s")
function s.create(...)
	local sid = TypedSection.create(...)
	if sid then
		luci.http.redirect(s.extedit % sid)
		return
	end
end

o = s:option(DummyValue, "type", translate("Type"))
function o.cfgvalue(...)
	return Value.cfgvalue(...) or translate("")
end

o = s:option(DummyValue, "alias", translate("Alias"))
function o.cfgvalue(...)
	return Value.cfgvalue(...) or translate("None")
end

o = s:option(DummyValue, "server", translate("Server Address"))
function o.cfgvalue(...)
	return Value.cfgvalue(...) or "?"
end

o = s:option(DummyValue, "server_port", translate("Server Port"))
function o.cfgvalue(...)
	return Value.cfgvalue(...) or "?"
end

if is_finded("kcptun-client") then

o = s:option(DummyValue, "kcp_enable", translate("KcpTun"))
function o.cfgvalue(...)
	return Value.cfgvalue(...) or "?"
end

end

o = s:option(DummyValue, "switch_enable", translate("Auto Switch"))
function o.cfgvalue(...)
	return Value.cfgvalue(...) or "0"
end

o = s:option(DummyValue,"server",translate("Ping Latency"))
o.template="shadowsocksr/ping"
o.width="10%"

o = s:option(DummyValue, "server_port", translate("Socket Connected"))
o.template="shadowsocksr/socket"
o.width="10%"

m:append(Template("shadowsocksr/server_list"))

return m
