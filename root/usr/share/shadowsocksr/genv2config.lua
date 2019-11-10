local ucursor = require "luci.model.uci".cursor()
local json = require "luci.jsonc"
local server_section = arg[1]
local proto = arg[2]
local local_addr = arg[3] 
local local_port = arg[4]
local usr_dns = arg[5]
local usr_port = arg[6]
local fdns_port = arg[7]

local server = ucursor:get_all("shadowsocksr", server_section)

local v2ray = {
  log = {
    -- error = "/var/ssrplus.log",
    loglevel = "warning"
  },
    -- 传入连接
    inbounds = {{
        listen = local_addr,
        port = tonumber(local_port),
        protocol = (proto == "socks") and "socks" or "dokodemo-door",
        settings = (proto == "socks") and {
            udp = true,
	    auth = "noauth",
            ip = local_addr
        } or {
            network = (proto == "tcp") and "tcp" or "udp",
            timeout = 30,
            followRedirect = true,
	},
        sniffing = {
            enabled = true,
            destOverride = { "http", "tls" }
        }
        },
        (proto == "fdns") and {
        listen = local_addr,
        port = tonumber(fdns_port),
        protocol = "dokodemo-door",
        settings = {
            network = "tcp,udp",
            address = usr_dns,
            port = tonumber(usr_port),
            followRedirect = false
        },
        } or nil
    },
    -- 传出连接
    outbounds = {{
        protocol = "vmess",
        settings = {
            vnext = {
                {
                    address = server.server,
                    port = tonumber(server.server_port),
                    users = {
                        {
                            id = server.vmess_id,
                            alterId = tonumber(server.alter_id),
                            security = server.security
                        }
                    }
                }
            }
        },
    -- 底层传输配置
        streamSettings = {
            network = server.transport,
            security = (server.tls == '1') and "tls" or "none",
            tlsSettings = {
		serverName = (server.tls_host ~= nil) and server.tls_host or ((server.ws_host ~= nil) and server.ws_host or ""),
		allowInsecure = (server.insecure == "1") and true or false,
		},
            kcpSettings = (server.transport == "kcp") and {
              mtu = tonumber(server.mtu),
              tti = tonumber(server.tti),
              uplinkCapacity = tonumber(server.uplink_capacity),
              downlinkCapacity = tonumber(server.downlink_capacity),
              congestion = (server.congestion == "1") and true or false,
              readBufferSize = tonumber(server.read_buffer_size),
              writeBufferSize = tonumber(server.write_buffer_size),
              header = {
                  type = server.kcp_guise
              }
          } or nil,
             wsSettings = (server.transport == "ws") and (server.ws_path ~= nil or server.ws_host ~= nil) and {
                path = server.ws_path,
                headers = (server.ws_host ~= nil) and {
                    Host = server.ws_host
                } or nil,
            } or nil,
            httpSettings = (server.transport == "h2") and {
                path = server.h2_path,
                host = server.h2_host,
            } or nil,
            quicSettings = (server.transport == "quic") and {
                security = server.quic_security,
                key = server.quic_key,
                header = {
                  type = server.quic_guise
                }
            } or nil
        },
        mux = {
            enabled = (server.mux == "1") and true or false,
            concurrency = tonumber(server.concurrency)
      }
    },

    -- 额外传出连接
--    outboundDetour = {
        {
            protocol = "freedom",
            tag = "direct",
            settings = { keep = "" }
        }
    }
}
print(json.stringify(v2ray, 1))
