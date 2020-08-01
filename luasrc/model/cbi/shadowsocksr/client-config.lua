-- Copyright (C) 2017 yushi studio <ywb94@qq.com> github.com/ywb94
-- Licensed to the public under the GNU General Public License v3.

local m, s, o,kcp_enable
local shadowsocksr = "shadowsocksr"
local uci = luci.model.uci.cursor()
local fs = require "nixio.fs"
local sys = require "luci.sys"
local sid = arg[1]
local uuid = luci.sys.exec("cat /proc/sys/kernel/random/uuid")

local function is_finded(e)
    return luci.sys.exec('type -t -p "%s/%s" "%s"' % {/usr/bin/v2ray, e, e}) ~= "" and true or false
end

local server_table = {}
local encrypt_methods = {
	"none",
	"table",
	"rc4",
	"rc4-md5-6",
	"rc4-md5",
	"aes-128-cfb",
	"aes-192-cfb",
	"aes-256-cfb",
	"aes-128-ctr",
	"aes-192-ctr",
	"aes-256-ctr",	
	"bf-cfb",
	"camellia-128-cfb",
	"camellia-192-cfb",
	"camellia-256-cfb",
	"cast5-cfb",
	"des-cfb",
	"idea-cfb",
	"rc2-cfb",
	"seed-cfb",
	"salsa20",
	"chacha20",
	"chacha20-ietf",
}

local encrypt_methods_ss = {
	-- aead
	"aes-128-gcm",
	"aes-192-gcm",
	"aes-256-gcm",
	"chacha20-ietf-poly1305",
	"xchacha20-ietf-poly1305",
	-- stream
	"table",
	"rc4",
	"rc4-md5",
	"aes-128-cfb",
	"aes-192-cfb",
	"aes-256-cfb",
	"aes-128-ctr",
	"aes-192-ctr",
	"aes-256-ctr",
	"bf-cfb",
	"camellia-128-cfb",
	"camellia-192-cfb",
	"camellia-256-cfb",
	"salsa20",
	"chacha20",
	"chacha20-ietf",
}

local protocol = {
	"origin",
	"verify_deflate",
	"auth_sha1_v4",
	"auth_aes128_sha1",
	"auth_aes128_md5",
	"auth_chain_a",
	"auth_chain_b",
	"auth_chain_c",
	"auth_chain_d",
	"auth_chain_e",
	"auth_chain_f",
}

local obfs = {
	"plain",
	"http_simple",
	"http_post",
	"random_head",
	"tls1.2_ticket_auth",
}

local securitys = {
    "auto",
    "none",
    "aes-128-gcm",
    "chacha20-poly1305"
}

local force_fp = {
	"disable",
	"firefox",
	"chrome",
	"ios",
}

local encrypt_methods_ss_aead = {
	"dummy",
	"aead_chacha20_poly1305",
	"aead_aes_128_gcm",
	"aead_aes_256_gcm",
	"chacha20-ietf-poly1305",
	"aes-128-gcm",
	"aes-256-gcm",
}

m = Map(shadowsocksr, translate("Edit ShadowSocksR Server"))
m.redirect = luci.dispatcher.build_url("admin/services/shadowsocksr/servers")
if m.uci:get(shadowsocksr, sid) ~= "servers" then
	luci.http.redirect(m.redirect) 
	return
end

-- [[ Servers Setting ]]--
s = m:section(NamedSection, sid, "servers")
s.anonymous = true
s.addremove   = false

o = s:option(DummyValue, "ssr_url", translate("Share Current"))
o.rawhtml  = true
o.template = "shadowsocksr/ssrurl"
o.value = sid

type = s:option(ListValue, "type", translate("Server Node Type"))
if is_finded("trojan") then
type:value("trojan", translate("Trojan-Plus"))
end
if is_finded("trojan-go") then
type:value("trojan-go", translate("Trojan-Go"))
end
if is_finded("v2ray") then
type:value("v2ray", translate("V2Ray"))
end
type:value("ssr", translate("ShadowsocksR"))
if is_finded("ss-redir") then
type:value("ss", translate("Shadowsocks"))
end
type.description = translate("Using incorrect encryption mothod may causes service fail to start")

o = s:option(Value, "alias", translate("Alias(optional)"))

o = s:option(Value, "server", translate("Server Address"))
o.datatype = "host"
o.rmempty = false

o = s:option(Value, "server_port", translate("Server Port"))
o.datatype = "port"
o.rmempty = false

-- o = s:option(Value, "timeout", translate("Connection Timeout"))
-- o.datatype = "uinteger"
-- o.default = 60
-- o.rmempty = false

o = s:option(Value, "password", translate("Password"))
o.password = true
o.rmempty = true
o:depends("type", "ssr")
o:depends("type", "ss")
o:depends("type", "trojan")
o:depends("type", "trojan-go")

o = s:option(ListValue, "encrypt_method", translate("Encrypt Method"))
for _, v in ipairs(encrypt_methods) do o:value(v) end
o.rmempty = true
o:depends("type", "ssr")

o = s:option(ListValue, "encrypt_method_ss", translate("Encrypt Method"))
for _, v in ipairs(encrypt_methods_ss) do o:value(v) end
o.rmempty = true
o:depends("type", "ss")

o = s:option(ListValue, "protocol", translate("Protocol"))
for _, v in ipairs(protocol) do o:value(v) end
o.rmempty = true
o:depends("type", "ssr")

o = s:option(Value, "protocol_param", translate("Protocol param(optional)"))
o:depends("type", "ssr")

o = s:option(ListValue, "obfs", translate("Obfs"))
for _, v in ipairs(obfs) do o:value(v) end
o.rmempty = true
o:depends("type", "ssr")

o = s:option(Value, "obfs_param", translate("Obfs param(optional)"))
o:depends("type", "ssr")

-- AlterId
o = s:option(Value, "alter_id", translate("AlterId"))
o.datatype = "port"
o.default = 16
o.rmempty = true
o:depends("type", "v2ray")

-- VmessId
o = s:option(Value, "vmess_id", translate("VmessId (UUID)"))
o.rmempty = true
o.default = uuid
o:depends("type", "v2ray")

-- 加密方式
o = s:option(ListValue, "security", translate("Encrypt Method"))
for _, v in ipairs(securitys) do o:value(v, v:upper()) end
o.rmempty = true
o:depends("type", "v2ray")

-- [[ TLS ]]--
o = s:option(ListValue, "stream_security", translate("Transport Layer Encryption"))
o:value("none", "none")
o:value("tls", "tls")
o.default = "tls"
o:depends("type", "v2ray")
o:depends("type", "trojan-go")
o:depends("type", "trojan")
o.validate = function(self, value)
    if value == "none" and type:formvalue(sid) == "trojan" then
        return nil, translate("'none' not supported for original Trojan.")
    end
    return value
end

o = s:option(Flag, "session_ticket", translate("Session Ticket"))
o.default = "0"
o:depends("stream_security", "tls")

o = s:option(Value, "tls_host", translate("TLS Host"))
o:depends("stream_security", "tls")

-- [[ allowInsecure ]]--
o = s:option(Flag, "insecure", translate("allowInsecure"))
o:depends("stream_security", "tls")

-- For Trojan-Go
o = s:option(ListValue, "fingerprint", translate("Finger Print"))
for _, v in ipairs(force_fp) do o:value(v) end
o:depends({ type = "trojan-go", stream_security = "tls" })
o.default = "firefox"

o = s:option(ListValue, "trojan_transport", translate("Transport"))
o:value("original", "Original")
o:value("ws", "WebSocket")
o:value("h2", "HTTP/2")
o:value("h2+ws", "HTTP/2 & WebSocket")
o.default = "ws"
o:depends("type", "trojan-go")

o = s:option(ListValue, "plugin_type", translate("Plugin Type"))
o:value("plaintext", "Plain Text")
o:value("shadowsocks", "ShadowSocks")
o:value("other", "Other")
o.default = "plaintext"
o:depends({ stream_security = "none", trojan_transport = "original" })

o = s:option(Value, "plugin_cmd", translate("Plugin Binary"))
o.placeholder = "eg: /usr/bin/v2ray-plugin"
o:depends({ plugin_type = "shadowsocks" })
o:depends({ plugin_type = "other" })

o = s:option(Value, "plugin_option", translate("Plugin Option"))
o.placeholder = "eg: obfs=http;obfs-host=www.baidu.com"
o:depends({ plugin_type = "shadowsocks" })
o:depends({ plugin_type = "other" })

o = s:option(DynamicList, "plugin_arg", translate("Plugin Option Args"))
o.placeholder = "eg: [\"-config\", \"test.json\"]"
o:depends({ plugin_type = "shadowsocks" })
o:depends({ plugin_type = "other" })

-- 传输协议
o = s:option(ListValue, "transport", translate("Transport"))
o:value("tcp", "TCP")
o:value("kcp", "mKCP")
o:value("ws", "WebSocket")
o:value("h2", "HTTP/2")
o:value("quic", "QUIC")
o.rmempty = true
o:depends("type", "v2ray")

-- [[ TCP部分 ]]--

-- TCP伪装
o = s:option(ListValue, "tcp_guise", translate("Camouflage Type"))
o:depends("transport", "tcp")
o:value("http", "HTTP")
o:value("none", translate("None"))
o.rmempty = true

-- HTTP域名
o = s:option(Value, "http_host", translate("HTTP Host"))
o:depends("tcp_guise", "http")
o.rmempty = true

-- HTTP路径
o = s:option(Value, "http_path", translate("HTTP Path"))
o:depends("tcp_guise", "http")
o.rmempty = true

-- [[ WS部分 ]]--

-- WS域名
o = s:option(Value, "ws_host", translate("WebSocket Host"))
o:depends("transport", "ws")
o:depends("trojan_transport", "h2+ws")
o:depends("trojan_transport", "ws")
o.datatype = "host"
o.rmempty = true

-- WS路径
o = s:option(Value, "ws_path", translate("WebSocket Path"))
o:depends("transport", "ws")
o:depends("trojan_transport", "h2+ws")
o:depends("trojan_transport", "ws")
o.rmempty = true

-- [[ H2部分 ]]--

-- H2域名
o = s:option(Value, "h2_host", translate("HTTP/2 Host"))
o:depends("transport", "h2")
o:depends("trojan_transport", "h2+ws")
o:depends("trojan_transport", "h2")
o.rmempty = true

-- H2路径
o = s:option(Value, "h2_path", translate("HTTP/2 Path"))
o:depends("transport", "h2")
o:depends("trojan_transport", "h2+ws")
o:depends("trojan_transport", "h2")
o.rmempty = true

-- [[ QUIC部分 ]]--

o = s:option(ListValue, "quic_security", translate("QUIC Security"))
o:depends("transport", "quic")
o.rmempty = true
o:value("none", translate("None"))
o:value("aes-128-gcm", translate("aes-128-gcm"))
o:value("chacha20-poly1305", translate("chacha20-poly1305"))

o = s:option(Value, "quic_key", translate("QUIC Key"))
o:depends("transport", "quic")
o.rmempty = true

o = s:option(ListValue, "quic_guise", translate("Header"))
o:depends("transport", "quic")
o.rmempty = true
o:value("none", translate("None"))
o:value("srtp", translate("VideoCall (SRTP)"))
o:value("utp", translate("BitTorrent (uTP)"))
o:value("wechat-video", translate("WechatVideo"))
o:value("dtls", "DTLS 1.2")
o:value("wireguard", "WireGuard")

-- [[ mKCP部分 ]]--

o = s:option(ListValue, "kcp_guise", translate("Camouflage Type"))
o:depends("transport", "kcp")
o:value("none", translate("None"))
o:value("srtp", translate("VideoCall (SRTP)"))
o:value("utp", translate("BitTorrent (uTP)"))
o:value("wechat-video", translate("WechatVideo"))
o:value("dtls", "DTLS 1.2")
o:value("wireguard", "WireGuard")
o.rmempty = true

o = s:option(Value, "mtu", translate("MTU"))
o.datatype = "uinteger"
o:depends("transport", "kcp")
o.default = 1350
o.rmempty = true

o = s:option(Value, "tti", translate("TTI"))
o.datatype = "uinteger"
o:depends("transport", "kcp")
o.default = 50
o.rmempty = true

o = s:option(Value, "uplink_capacity", translate("Uplink Capacity"))
o.datatype = "uinteger"
o:depends("transport", "kcp")
o.default = 5
o.rmempty = true

o = s:option(Value, "downlink_capacity", translate("Downlink Capacity"))
o.datatype = "uinteger"
o:depends("transport", "kcp")
o.default = 20
o.rmempty = true

o = s:option(Value, "read_buffer_size", translate("Read Buffer Size"))
o.datatype = "uinteger"
o:depends("transport", "kcp")
o.default = 2
o.rmempty = true

o = s:option(Value, "write_buffer_size", translate("Write Buffer Size"))
o.datatype = "uinteger"
o:depends("transport", "kcp")
o.default = 2
o.rmempty = true

o = s:option(Flag, "congestion", translate("Congestion"))
o:depends("transport", "kcp")
o.rmempty = true

-- For Trojan-Go only
o = s:option(Flag, "ss_aead", translate("Shadowsocks2"))
o:depends("type", "trojan-go")
o.default = "0"
o.rmempty = false

o = s:option(ListValue, "ss_aead_method", translate("Encrypt Method"))
for _, v in ipairs(encrypt_methods_ss_aead) do o:value(v, v) end
o.default = "aead_aes_128_gcm"
o.rmempty = false
o:depends("ss_aead", "1")

o = s:option(Value, "ss_aead_pwd", translate("Password"))
o.password = true
o.rmempty = true
o:depends("ss_aead", "1")

-- [[ Mux ]]--
o = s:option(Flag, "mux", translate("Mux"))
o.rmempty = true
o.default = "0"
o:depends("type", "v2ray")
o:depends("type", "trojan-go")

o = s:option(Value, "concurrency", translate("Concurrency"))
o.datatype = "uinteger"
o.rmempty = false
o.default = "4"
o:depends("mux", "1")

o = s:option(Flag, "fast_open", translate("TCP Fast Open"))
o.rmempty = true
o.default = "0"
o:depends("type", "ssr")
o:depends("type", "ss")
o:depends("type", "trojan")
o:depends("type", "trojan-go")

o = s:option(Flag, "switch_enable", translate("Enable Auto Switch"))
o.rmempty = false
o.default = "1"

o = s:option(Value, "local_port", translate("Local Port"))
o.datatype = "port"
o.default = 1234
o.rmempty = false

if is_finded("kcptun-client") then

kcp_enable = s:option(Flag, "kcp_enable", translate("KcpTun Enable"))
kcp_enable.rmempty = true
kcp_enable.default = "0"
kcp_enable:depends("type", "ssr")
kcp_enable:depends("type", "ss")

o = s:option(Value, "kcp_port", translate("KcpTun Port"))
o.datatype = "port"
o.default = 4000
o:depends("type", "ssr")
o:depends("type", "ss")

o = s:option(Value, "kcp_password", translate("KcpTun Password"))
o.password = true
o:depends("type", "ssr")
o:depends("type", "ss")

o = s:option(Value, "kcp_param", translate("KcpTun Param"))
o.default = "--nocomp"
o:depends("type", "ssr")
o:depends("type", "ss")

end

return m
