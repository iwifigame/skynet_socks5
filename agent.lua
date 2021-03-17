local skynet = require "skynet"
local socket = require "skynet.socket"

local WATCHDOG
local host
local send_request

local CMD = {}
local REQUEST = {}
local client_fd

local function read(n)
	return socket.read(client_fd, n)
end

function REQUEST:get()
end

function REQUEST:set()
end

function REQUEST:handshake()
	return { msg = "Welcome to skynet, I will send heartbeat every 5 sec." }
end

function REQUEST:quit()
	skynet.call(WATCHDOG, "lua", "close", client_fd)
end

local function request(name, args, response)
	local f = assert(REQUEST[name])
	local r = f(args)
	if response then
		return response(r)
	end
end

local function send_package(pack)
	local package = string.pack(">s2", pack)
	socket.write(client_fd, package)
end

local function handIdentifie()
	local data = read(2)
	logBuff(data)
	local ver = string.byte(data, 1)
	local nmethods = string.byte(data, 2)
	data = read(nmethods)
	local methods = {}
	for i = 1, nmethods do
		methods[i] = string.byte(data, i)
	end
	log(methods)

	socket.write(client_fd, "\5\0")
end

local function sendResponse()
	local response = "\5\0\0\1\127\127\127\1\0\0"
		-- buf[8] = 8555 >> 8;
		-- buf[9] = 8555 % 256;
	socket.write(client_fd, response)
end

local function handleRequest()
	local data = read(4)
	logBuff(data)
	local ver = string.byte(data, 1)
	local cmd = string.byte(data, 2)
	local rsv = string.byte(data, 3)
	local atyp = string.byte(data, 4)
	log(ver, cmd, rsv, atyp)

	local dstFd

	if atyp == 3 then
		local addrLen = string.byte(read(1),  1)
		local addr = read(addrLen)
		local data = read(2)
		logBuff(data)
		local port = (string.byte(data, 1) << 8) + string.byte(data, 2)
		INFO("address", addr, port)

		dstFd = socket.open(addr, port)
	end

	sendResponse()

	-- local data = read(32)
	-- logBuff(data)
	skynet.fork(function()
		while true do
			local data = read()
			if not data then
				break
			end
			-- logBuff(data)
			socket.write(dstFd, data)
		end
	end)
	while true do
		local data = socket.read(dstFd)
		if not data then
			break
		end
		-- logBuff(data)
		socket.write(client_fd, data)
	end
end

function CMD.start(conf)
	local fd = conf.client
	WATCHDOG = conf.watchdog

	client_fd = fd
	socket.start(client_fd)

	socket.onclose(client_fd, function()
		ERROR("client fd close")
	end)

	handIdentifie()
	handleRequest()
end

function CMD.disconnect()
	-- todo: do something before exit
	skynet.exit()
end

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command, ...)
		-- skynet.trace()
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
	end)
end)
