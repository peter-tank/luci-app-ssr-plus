local ucursor = require "luci.model.uci".cursor()
local json = require "luci.jsonc"
local server_section = arg[1]
local proto = arg[2] 
local local_addr = arg[3]
local local_port = arg[4]
local usr_dns = arg[5]
local usr_port = arg[6]

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
    ssl = (server.tls) and {
        verify = (server.insecure == "1") and false or true,
        verify_hostname = (server.insecure == "1") and false or true,
        cert = "",
        cipher = "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES128-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA:AES128-SHA:AES256-SHA:DES-CBC3-SHA",
        cipher_tls13 = "TLS_AES_128_GCM_SHA256:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_256_GCM_SHA384",
        sni = (server.tls_host ~= nil) and server.tls_host or (server.ws_host ~= nil and server.ws_host or server.server),
        alpn = (server.trojan_ws == "1") and {} or {"h2", "http/1.1"},
        fingerprint = server.fingerprint,
        curve = "",
        reuse_session = true,
        session_ticket = true,
        } or nil,
    mux = (server.mux == "1") and {
        enabled = true,
        concurrency = tonumber(server.concurrency),
        idle_timeout = 60,
        } or nil,
    websocket = (server.trojan_ws == "1") and {
        enabled = true,
        path = (server.ws_path ~= nil) and server.ws_path or "/",
        hostname = (server.ws_host ~= nil) and server.ws_host or (server.tls_host ~= nil and server.tls_host or server.server),
        obfuscation_password = server.obfuscation_password,
        double_tls = (server.double_tls == "1") and true or false,
        double_tls_verify = true,
        } or nil,
        tcp = {
            no_delay = true,
            keep_alive = true,
            reuse_port = false,
            fast_open = (server.fast_open == "1") and true or false,
            fast_open_qlen = 20
        }
}
print(json.stringify(trojan, 1))
