local skynet = require("skynet")
local socket = require("socket")

local CMD = {}
local SOCKET = {}
local gate
local agent = {}
local agents = {}

function SOCKET.open(fd, addr)
	skynet.error("New client from : " .. addr)
	agent[fd] = skynet.newservice("agent")
	skynet.call(agent[fd], "lua", "start", { gate = gate, client = fd, watchdog = skynet.self() })
end

local function close_agent(fd)
	local a = agent[fd]
	agent[fd] = nil
	if a then
		skynet.call(gate, "lua", "kick", fd)
		-- disconnect never return
		skynet.send(a, "lua", "disconnect")
	end
end

function SOCKET.close(fd)
	skynet.error("socket close",fd)
	close_agent(fd)
end

function SOCKET.error(fd, msg)
	skynet.error("socket error",fd, msg)
	close_agent(fd)
end

function SOCKET.warning(fd, size)
	-- size K bytes havn't send out in fd
	skynet.error("socket warning", fd, size)
end

function SOCKET.data(fd, msg)
	skynet.error("SOCKET data", fd, msg)
end

function CMD.start(conf)
	local listenFd = socket.listen("0.0.0.0", conf.port)
	local agentIndex = 1
	socket.start(listenFd, function(id, addr)
		INFO(string.format("accept client socket_id: %s addr:%s", id, addr))
		skynet.call(agents[agentIndex], "lua", "start", {client = id, watchdog = skynet.self()})
		agentIndex = agentIndex + 1
		if agentIndex > 10 then
			agentIndex = 1
		end
	end)
end

function CMD.close(fd)
	close_agent(fd)
end

skynet.start(function()
	for i = 1, 10 do
		agents[i] = skynet.newservice("agent")
	end
	skynet.dispatch("lua", function(session, source, cmd, subcmd, ...)
		if cmd == "socket" then
			local f = SOCKET[subcmd]
			f(...)
			-- socket api don't need return
		else
			local f = assert(CMD[cmd])
			skynet.ret(skynet.pack(f(subcmd, ...)))
		end
	end)
end)
