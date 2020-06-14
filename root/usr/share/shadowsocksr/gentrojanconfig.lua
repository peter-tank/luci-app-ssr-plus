local ucursor = require "luci.model.uci".cursor()
local json = require "luci.jsonc"
local server_section = arg[1]
local proto = arg[2]
local threads = tonumber(arg[3])
local local_addr = arg[4]
local local_port = arg[5]
local usr_dns = arg[6]
local usr_port = arg[7]

local server = ucursor:get_all("shadowsocksr", server_section)

local trojan = {
    -- error = "/var/ssrplus.log",
    log_level = 3,
    run_type = proto,
    local_addr = local_addr,
    local_port = tonumber(local_port),
    remote_addr = server.server,
    remote_port = tonumber(server.server_port),
    target_addr = (proto == "forward") and usr_dns or nil,
    target_port = (proto == "forward") and tonumber(usr_port) or nil,
    udp_timeout = 30,
    -- 传入连接
    password = {server.password},
    -- 传出连接
    ssl = (server.tls == "1") and {
        verify = (server.insecure == nil or server.insecure == "0") and true or false,
        verify_hostname = (server.insecure == nil or server.insecure == "0") and true or false,
        cert = "",
        cipher = "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES128-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA:AES128-SHA:AES256-SHA:DES-CBC3-SHA",
        cipher_tls13 = "TLS_AES_128_GCM_SHA256:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_256_GCM_SHA384",
        sni = (server.tls_host ~= nil) and server.tls_host or (server.ws_host ~= nil and server.ws_host or server.server),
        alpn = (server.trojan_ws == "1") and {} or {"h2", "http/1.1"},
        fingerprint = (server.fingerprint ~= nil and server.fingerprint ~= "disable" ) and server.fingerprint or "",
        curve = "",
        reuse_session = true,
        session_ticket = true,
        } or nil,
    buffer_size = 32,
    mux = (server.mux == "1") and {
        enabled = true,
        concurrency = tonumber(server.concurrency),
        idle_timeout = 60,
        } or nil,
    websocket = (server.trojan_ws == "1") and {
        enabled = true,
        path = (server.ws_path ~= nil) and server.ws_path or "/",
        hostname = (server.ws_host ~= nil) and server.ws_host or (server.tls_host ~= nil and server.tls_host or server.server)
        } or nil,
    shadowsocks = (server.ss_aead == "1") and {
        enabled = true,
        method = (server.ss_aead_method ~= nil) and server.ss_aead_method or "AEAD_AES_128_GCM",
        password = (server.ss_aead_pwd ~= nil) and server.ss_aead_pwd or ""
        } or nil,
        tcp = {
            no_delay = true,
            keep_alive = true,
            reuse_port = (threads > 1) and true or false,
            fast_open = (server.fast_open == "1") and true or false,
            fast_open_qlen = 20
        }
}
print(json.stringify(trojan, 1))
