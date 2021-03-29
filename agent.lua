local skynet = require "skynet"
local socket = require "skynet.socket"

local CMD = {}
local srcFds = {}
local dstFds = {}
local srcTodstFds = {}

local ATYP = {
	ipv4 = 1,
	domain = 3,
	ipv6 = 4,
}

local function read(fd, n)
	local data, err = socket.read(fd, n)

	if not data then
		if srcFds[fd] or dstFds[fd] then
			error(err)
		end
		return
	end

	return data
end

local function write(srcFd, pack)
	return socket.write(srcFd, pack)
end

local function handIdentifie(srcFd)
	local data = read(srcFd, 2)
	local ver = string.byte(data, 1)
	local nmethods = string.byte(data, 2)
	data = read(srcFd,nmethods)
	local methods = {}
	for i = 1, nmethods do
		methods[i] = string.byte(data, i)
	end

	write(srcFd,"\5\0")
end

local function sendResponse(srcFd)
	local response = "\5\0\0\1\127\127\127\1\0\0"
		-- buf[8] = 8555 >> 8;
		-- buf[9] = 8555 % 256;
	write(srcFd,response)
end

local function handleRequest(srcFd)
	local data = read(srcFd,4)
	local ver = string.byte(data, 1)
	local cmd = string.byte(data, 2)
	local rsv = string.byte(data, 3)
	local atyp = string.byte(data, 4)
	log(ver, cmd, rsv, atyp)

	local dstFd
	local err
	local dstAddr
	local dstPort

	if atyp == ATYP.domain then
		local data = read(srcFd,1)
		local addrLen = string.byte(data, 1)
		dstAddr = read(srcFd,addrLen)
		data = read(srcFd,2)
		dstPort = (string.byte(data, 1) << 8) + string.byte(data, 2)
		INFO("handle request. dst domain", dstAddr, dstPort)

		dstFd, err = socket.open(dstAddr, dstPort)
		if not dstFd then
			ERROR("connect to dst addr failed.", dstAddr, dstPort, err)
			return
		end
	elseif atyp == ATYP.ipv4 then
		local data = read(srcFd,4)
		dstAddr = string.byte(data, 1) .. "." .. string.byte(data, 2) .. "." .. string.byte(data, 3) .. "." .. string.byte(data, 4)
		data = read(srcFd, 2)
		dstPort = (string.byte(data, 1) << 8) + string.byte(data, 2)
		INFO("handle request. dst ipv4", dstAddr, dstPort)

		dstFd, err = socket.open(dstAddr, dstPort)
		if not dstFd then
			ERROR("connect to dst ipv4 failed.", dstAddr, dstPort, err)
			return
		end
	else
		ERROR("atype not handed", atyp)
		return
	end

	WARN("connected dstFd:", dstFd, dstAddr, dstPort)
	dstFds[dstFd] = true
	srcTodstFds[srcFd] = dstFd
	socket.onclose(dstFd, function()
		INFO("client dstFd close, srcFd-dstFd:", srcFd, dstFd)
		dstFds[dstFd] = nil
	end)

	sendResponse(srcFd)

	skynet.fork(function()
		while srcFds[srcFd] do
			local data = read(srcFd)
			if not data then
				break
			end
			socket.write(dstFd, data)
		end
	end)
	while dstFds[dstFd] do
		local data = read(dstFd)
		if not data then
			break
		end
		write(srcFd, data)
	end
	WARN("agent end<===========", srcFd)
end

function CMD.start(conf)
	local fd = conf.client

	local srcFd = fd
	socket.start(srcFd)

	WARN("agent start===========>", srcFd)

	srcFds[srcFd] = true

	socket.onclose(srcFd, function()
		srcFds[srcFd] = nil
		local dstFd = srcTodstFds[srcFd]
		INFO("client srcFd close. srcFd-dstFd:", srcFd, dstFd)
		socket.close(dstFd)
		srcTodstFds[srcFd] = nil
	end)

	handIdentifie(srcFd)
	handleRequest(srcFd)
end

skynet.info_func(function()
	local info = {
		srcFds = srcFds,
		dstFds = dstFds,
		srcTodstFds = srcTodstFds,
	}
	return info
end)

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command, ...)
		-- skynet.trace()
		local f = CMD[command]
		skynet.retpack(f(...))
		-- local ok, data = xpcall(f, __G__TRACKBACK__, ...)
		-- skynet.retpack(data)
	end)
end)
