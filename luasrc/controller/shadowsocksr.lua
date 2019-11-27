-- Copyright (C) 2017 yushi studio <ywb94@qq.com>
-- Licensed to the public under the GNU General Public License v3.

module("luci.controller.shadowsocksr", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/shadowsocksr") then
		return
	end

  entry({"admin", "services", "shadowsocksr"},alias("admin", "services", "shadowsocksr", "client"),_("ShadowSocksR Plus+"), 10).dependent = true

  entry({"admin", "services", "shadowsocksr", "client"},cbi("shadowsocksr/client"),_("SSR Client"), 10).leaf = true
 
	entry({"admin", "services", "shadowsocksr", "servers"}, arcombine(cbi("shadowsocksr/servers"), cbi("shadowsocksr/client-config")),_("Severs Nodes"), 20).leaf = true
	
	entry({"admin", "services", "shadowsocksr", "control"},cbi("shadowsocksr/control"),_("Access Control"), 30).leaf = true
	
	entry({"admin", "services", "shadowsocksr", "list"},form("shadowsocksr/list"),_("GFW List"), 40).leaf = true

if nixio.fs.access("/usr/sbin/dnscrypt-proxy") then
	entry({"admin", "services", "shadowsocksr", "dnscrypt-proxy"},cbi("dnscrypt-proxy/dnscrypt-proxy"),_("DNSCrypt Proxy"), 45).leaf = true
	entry({"admin", "services", "shadowsocksr", "dnscrypt-resolvers"},form("dnscrypt-proxy/dnscrypt-resolvers"),_("DNSCrypt Resolvers"), 46).leaf = true
	entry({"admin", "services", "shadowsocksr", "dnscrypt-resolvers"},arcombine(cbi("dnscrypt-proxy/dnscrypt-resolvers"), cbi("dnscrypt-proxy/dnscrypt-resolvers-config")),_("DNSCrypt Servers"), 47).leaf = true
	entry({"admin", "services", "shadowsocksr", "refresh_c"}, call("refresh_cmd"))
	entry({"admin", "services", "shadowsocksr", "resolve_c"}, call("resolve_cmd"))
	entry({"admin", "services", "shadowsocksr", "update_c"}, call("update_cmd"))
end
	
		entry({"admin", "services", "shadowsocksr", "advanced"},cbi("shadowsocksr/advanced"),_("Advanced Settings"), 50).leaf = true
		
		if nixio.fs.access("/usr/bin/ssr-server") then
	      entry({"admin", "services", "shadowsocksr", "server"},arcombine(cbi("shadowsocksr/server"), cbi("shadowsocksr/server-config")),_("SSR Server"), 60).leaf = true
	end
	
	entry({"admin", "services", "shadowsocksr", "status"},form("shadowsocksr/status"),_("Status"), 70).leaf = true
		
	entry({"admin", "services", "shadowsocksr", "check"}, call("check_status"))
	entry({"admin", "services", "shadowsocksr", "refresh"}, call("refresh_data"))
	entry({"admin", "services", "shadowsocksr", "checkport"}, call("check_port"))
	
	entry({"admin", "services", "shadowsocksr","run"},call("act_status")).leaf=true
	
	entry({"admin", "services", "shadowsocksr", "ping"}, call("act_ping")).leaf=true
	
	entry({"admin", "services", "shadowsocksr", "fileread"}, call("act_read"), nil).leaf=true

	entry({"admin", "services", "shadowsocksr", "logview"}, cbi("shadowsocksr/logview", {hideapplybtn=true, hidesavebtn=true, hideresetbtn=true}), _("Log") ,80).leaf=true

end

function act_status()
  local e={}
  e.running=luci.sys.call("busybox ps -w | grep ' /var/etc/shadowsocksr.json' | grep -v grep >/dev/null")==0
  luci.http.prepare_content("application/json")
  luci.http.write_json(e)
end

function act_ping()
	local e={}
	e.index=luci.http.formvalue("index")
	e.ping=luci.sys.exec("ping -c 1 -W 1 %q 2>&1 | grep -o 'time=[0-9]*.[0-9]' | awk -F '=' '{print$2}'"%luci.http.formvalue("domain"))
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end

function check_status()
local set ="/usr/bin/ssr-check www." .. luci.http.formvalue("set") .. ".com 80 3 1"
sret=luci.sys.call(set)
if sret== 0 then
 retstring ="0"
else
 retstring ="1"
end	
luci.http.prepare_content("application/json")
luci.http.write_json({ ret=retstring })
end

function refresh_data()
local set =luci.http.formvalue("set")
local icount =0

if set == "gfw_data" then
 if nixio.fs.access("/usr/bin/wget-ssl") then
  refresh_cmd="wget-ssl --no-check-certificate https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt -O /tmp/gfw.b64"
 else
  refresh_cmd="wget -O /tmp/gfw.b64 http://iytc.net/tools/list.b64"
 end
 sret=luci.sys.call(refresh_cmd .. " 2>/dev/null")
 if sret== 0 then
  luci.sys.call("/usr/bin/ssr-gfw")
  icount = luci.sys.exec("cat /tmp/gfwnew.txt | wc -l")
  if tonumber(icount)>1000 then
   oldcount=luci.sys.exec("cat /etc/dnsmasq.ssr/gfw_list.conf | wc -l")
   if tonumber(icount) ~= tonumber(oldcount) then
    luci.sys.exec("cp -f /tmp/gfwnew.txt /etc/dnsmasq.ssr/gfw_list.conf && cp -f /tmp/gfwnew.txt /tmp/dnsmasq.ssr/gfw_list.conf")
    luci.sys.call("/etc/init.d/dnsmasq restart")
    retstring=tostring(math.ceil(tonumber(icount)/2))
   else
    retstring ="0"
   end
  else
   retstring ="-1"  
  end
  luci.sys.exec("rm -f /tmp/gfwnew.txt ")
 else
  retstring ="-1"
 end
elseif set == "dns_data" then
 if nixio.fs.access("/usr/bin/wget-ssl") then
  refresh_cmd="wget-ssl --no-check-certificate https://raw.githubusercontent.com/dyne/dnscrypt-proxy/master/dnscrypt-resolvers.csv -O /usr/share/dnscrypt-proxy/dnscrypt-resolvers.csv"
 else
  refresh_cmd="wget -O /usr/share/dnscrypt-proxy/dnscrypt-resolvers.csv http://raw.githubusercontent.com/dyne/dnscrypt-proxy/master/dnscrypt-resolvers.csv"
 end
 sret=luci.sys.call(refresh_cmd .. " 2>/dev/null")
 if sret== 0 then
  -- luci.sys.call("/usr/share/dnscrypt-proxy/csv2conf.sh")
  icount = luci.sys.exec("cat /usr/share/dnscrypt-proxy/dnscrypt-resolvers.csv | wc -l")
    retstring=tostring(tonumber(icount))
 else
   retstring ="-1"  
 end

elseif set == "ip_data" then
 refresh_cmd="wget -O- 'http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest'  2>/dev/null| awk -F\\| '/CN\\|ipv4/ { printf(\"%s/%d\\n\", $4, 32-log($5)/log(2)) }' > /tmp/china_ssr.txt"
 sret=luci.sys.call(refresh_cmd)
 icount = luci.sys.exec("cat /tmp/china_ssr.txt | wc -l")
 if  sret== 0 and tonumber(icount)>1000 then
  oldcount=luci.sys.exec("cat /etc/china_ssr.txt | wc -l")
  if tonumber(icount) ~= tonumber(oldcount) then
   luci.sys.exec("cp -f /tmp/china_ssr.txt /etc/china_ssr.txt")
   luci.sys.call("/usr/share/shadowsocksr/chinaipset.sh")
   retstring=tostring(tonumber(icount))
  else
   retstring ="0"
  end

 else
  retstring ="-1"
 end
 luci.sys.exec("rm -f /tmp/china_ssr.txt ")
elseif set == "ads_data" then
  local need_process = 0
  if nixio.fs.access("/usr/bin/wget-ssl") then
  refresh_cmd="wget-ssl --no-check-certificate -O - https://easylist-downloads.adblockplus.org/easylistchina+easylist.txt > /tmp/adnew.conf"
  need_process = 1
 else
  refresh_cmd="wget -O /tmp/ad.conf http://iytc.net/tools/ad.conf"
 end
 sret=luci.sys.call(refresh_cmd .. " 2>/dev/null")
 if sret== 0 then
  if need_process == 1 then
    luci.sys.call("/usr/bin/ssr-ad")
  end
  icount = luci.sys.exec("cat /tmp/ad.conf | wc -l")
  if tonumber(icount)>1000 then
   if nixio.fs.access("/etc/dnsmasq.ssr/ad.conf") then
    oldcount=luci.sys.exec("cat /etc/dnsmasq.ssr/ad.conf | wc -l")
    
   else
    oldcount=0
   end
   
   if tonumber(icount) ~= tonumber(oldcount) then
    luci.sys.exec("cp -f /tmp/ad.conf /etc/dnsmasq.ssr/ad.conf && cp -f /tmp/ad.conf /tmp/dnsmasq.ssr/ad.conf")
    retstring=tostring(math.ceil(tonumber(icount)))
    luci.sys.call("/etc/init.d/dnsmasq restart")
   else
    retstring ="0"
   end
  else
   retstring ="-1"  
  end
  luci.sys.exec("rm -f /tmp/ad.conf ")
 else
  retstring ="-1"
 end
else
 retstring ="-1"
end	
luci.http.prepare_content("application/json")
luci.http.write_json({ ret=retstring ,retcount=icount})
end


function check_port()
local set = luci.http.formvalue("set")
local retstring="<br /><br />"
local s
local server_name = ""
local shadowsocksr = "shadowsocksr"
local uci = luci.model.uci.cursor()
local iret=1

if set == "nslook" then
retstring = luci.sys.exec("/usr/bin/nslookup www.google.com 127.0.0.1#5353")
-- domains = {}
-- domains.push("www.google.com")
-- retjson = luci.util.ubus("network.rrdns", "lookup", {addrs={domains}, timerout=3000})
else
uci:foreach(shadowsocksr, "servers", function(s)

	if s.alias then
		server_name=s.alias
	elseif s.server and s.server_port then
		server_name= "%s:%s" %{s.server, s.server_port}
	end
	iret=luci.sys.call(" ipset add ss_spec_wan_ac " .. s.server .. " 2>/dev/null")
	socket = nixio.socket("inet", "stream")
	socket:setopt("socket", "rcvtimeo", 3)
	socket:setopt("socket", "sndtimeo", 3)
	ret=socket:connect(s.server,s.server_port)
	if  tostring(ret) == "true" then
	socket:close()
	retstring =retstring .. "<font color='green'>[" .. server_name .. "] OK.</font><br />"
	else
	retstring =retstring .. "<font color='red'>[" .. server_name .. "] Error.</font><br />"
	end	
	if  iret== 0 then
	luci.sys.call(" ipset del ss_spec_wan_ac " .. s.server)
	end
end)
end

luci.http.prepare_content("application/json")
luci.http.write_json({ ret=retstring })
end

function update_cmd()
local dc = require "luci.model.dnscrypt".init()
local set = luci.http.formvalue("set")
local surl = luci.http.formvalue("url")
local ecount, retstring = 0, "-1"

if set == "dnscrypt_bin" then
	local bin_file = "/usr/sbin/dnscrypt-proxy"
	local ret = action_update(surl)
	retstring = type(ret) == "table" and table.concat(ret,", ") or ret
 	ecount = nixio.fs.chmod(bin_file, 755)
else
	ecount = -1
	retstring = "Unkown CMD: " .. set
end

luci.http.prepare_content("application/json")
luci.http.write_json({ err=ecount, status=retstring})
end

function refresh_cmd()
local set = luci.http.formvalue("set")
local icount, retstring = 0, "-1"

if set == "dnslist_up" then
	retstring = "1"
	icount = 1
elseif set == "resolvers_up" then
	local bin_file = "/usr/sbin/dnscrypt-proxy"
	retstring = "2"
	icount = 2
else
	ecount = -1
	retstring = "Unkown CMD: " .. set
end

luci.http.prepare_content("application/json")
luci.http.write_json({ ret=retstring ,retcount=icount})
end

function resolve_cmd()
local set = luci.http.formvalue("set")
local retstring="<br /><br />"

retstring = luci.sys.exec("/usr/sbin/dnscrypt-proxy -resolve www.google.com")
luci.http.prepare_content("application/json")
luci.http.write_json({ ret=retstring })
end

-- called by XHR.get from logview.htm
function act_read(lfile)
	local fs = require "nixio.fs"
	local http = require "luci.http"
	local lfile = http.formvalue("lfile")
	local ldata={}
	ldata[#ldata+1] = fs.readfile(lfile) or "_nofile_"
	if ldata[1] == "" then
		ldata[1] = "_nodata_"
	end
	http.prepare_content("application/json")
	http.write_json(ldata)
end

function action_data()
	local http = require "luci.http"

	local types = {
		csv = "text/csv",
		json = "application/json"
	}

	local args = { }
	local mtype = http.formvalue("type") or "json"

	http.prepare_content(types[mtype])
	exec("/usr/sbin/dnscrypt-proxy", args, http.write)
end

function action_list()
	local http = require "luci.http"

	local fd = io.popen("/usr/sbin/dnscrypt-proxy -c list")
	local periods = { }

	if fd then
		while true do
			local period = fd:read("*l")

			if not period then
				break
			end

			periods[#periods+1] = period
		end

		fd:close()
	end

	http.prepare_content("application/json")
	http.write_json(periods)
end

function action_download()
	local nixio = require "nixio"
	local http = require "luci.http"
	local sys = require "luci.sys"
	local uci = require "luci.model.uci".cursor()

	local dir = uci:get_first("dnscrypt-proxy", "dnscrypt-proxy", "directory")
		or "/usr/sbin"

	if dir and nixio.fs.stat(dir, "type") == "dir" then
		local n = "nlbwmon-backup-%s-%s.tar.gz"
			%{ sys.hostname(), os.date("%Y-%m-%d") }

		http.prepare_content("application/octet-stream")
		http.header("Content-Disposition", "attachment; filename=\"%s\"" % n)
		exec("/bin/tar", { "-C", dir, "-c", "-z", ".", "-f", "-" }, http.write)
	else
		http.status(500, "Unable to find database directory")
	end
end

function action_update(surl)
	local tmp = "/tmp/dnscrypt-proxy_bin.tar.gz"
	local dir = "/tmp"
	local stype = luci.util.exec("uname"):lower()
	local sarch = luci.util.exec("uname -m")

	exec("/bin/wget", {"--no-check-certificate", "-O", tmp, surl})

	exec("/usr/sbin/dnscrypt-proxy", {"-service", "stop" })
	local files = { }
	local tar = io.popen("/bin/tar -tzf %s" % tmp, "r")
	if tar then
		while true do
			local file = tar:read("*l")
			if not file then
				break
			elseif file:match("^(.*\/dnscrypt.proxy)$") then
				files[#files+1] = file
			end
		end
		tar:close()
	end

	if #files == 0 then
		return {500, "Internal Server Error", stype, sarch}
	end


	local output = { }

	exec("/usr/sbin/dnscrypt-proxy", {"-service", "stop" })
	exec("/bin/mkdir", { "-p", dir })

	exec("/bin/tar", { "-C", dir, "-vxzf", tmp, unpack(files) },
		function(chunk) output[#output+1] = chunk:match("%S+") end)

	exec("/bin/cp", { "-f", dir .. "/" .. files[1], "/usr/sbin/dnscrypt-proxy"})
	exec("/bin/rm", { "-f", "%s/%s-%s/dnscrypt-proxy" % {dir, stype, sarch}})
	exec("/bin/rm", { "-f", tmp })
	exec("/usr/sbin/dnscrypt-proxy", {"-service", "start" })
	return out
end

function action_upload()
	local nixio = require "nixio"
	local http = require "luci.http"
	local i18n = require "luci.i18n"

	local tmp = "/tmp/dnscrypt-upload.tar.gz"
	local dir = "/usr/share/dnscrypt-proxy"
	local stype = luci.util.exec("uname"):lower()
	local sarch = luci.util.exec("uname -a")

	local fp
	http.setfilehandler(
		function(meta, chunk, eof)
			if not fp and meta and meta.name == "archive" then
				fp = io.open(tmp, "w")
			end
			if fp and chunk then
				fp:write(chunk)
			end
			if fp and eof then
				fp:close()
			end
		end)

	local files = { }
	local tar = io.popen("/bin/tar -tzf %s" % tmp, "r")
	if tar then
		while true do
			local file = tar:read("*l")
			if not file then
				break
			elseif file:match("^%.*%.md$") or
			       file:match("^%.*%.%.json$") then
				files[#files+1] = file
			end
		end
		tar:close()
	end

	if #files == 0 then
		http.status(500, "Internal Server Error")
		tpl.render("dnscrypt-proxy/dnscrypt-resolver", {
			message = i18n.translate("Invalid or empty backup archive")
		})
		return
	end


	local output = { }

	exec("/usr/sbin/dnscrypt-proxy", {"-service", "stop" })
	exec("/bin/mkdir", { "-p", dir })

	exec("/bin/tar", { "-C", dir, "-vxzf", tmp, unpack(files) },
		function(chunk) output[#output+1] = chunk:match("%S+") end)

	exec("/bin/rm", { "-f", tmp })
	exec("/usr/sbin/dnscrypt-proxy", {"-service", "start" })

	tpl.render("dnscrypt-proxy/dnscrypt-resolver", {
		message = i18n.translatef(
			"The following database files have been restored: %s",
			table.concat(output, ", "))
	})
end

function action_commit()
	local http = require "luci.http"
	local disp = require "luci.dispatcher"

	http.redirect(disp.build_url("admin/services/shadowsocksr/dnscrypt-proxy"))
	exec("/usr/sbin/dnscrypt-proxy", { "-service", "restart" })
end

function exec(cmd, args, writer)
	local os = require "os"
	local nixio = require "nixio"

	local fdi, fdo = nixio.pipe()
	local pid = nixio.fork()

	if pid > 0 then
		fdo:close()

		while true do
			local buffer = fdi:read(2048)

			if not buffer or #buffer == 0 then
				break
			end

			if writer then
				writer(buffer)
			end
		end

		nixio.waitpid(pid)
	elseif pid == 0 then
		nixio.dup(fdo, nixio.stdout)
		fdi:close()
		fdo:close()
		nixio.exece(cmd, args, nil)
		nixio.stdout:close()
		os.exit(1)
	end
	luci.util.exec("echo %s, %s>>/tmp/test;" % {cmd, table.concat(args,", ")})
end
