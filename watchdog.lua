local skynet = require("skynet")
local socket = require("socket")

local CMD = {}
local agents = {}

function CMD.start(conf)
	local listenFd = socket.listen("0.0.0.0", conf.port)
	local agentIndex = 1
	socket.start(listenFd, function(id, addr)
		INFO(string.format("accept client socket_id: %s addr:%s", id, addr))
		-- local agent = skynet.newservice("agent")
		-- skynet.call(agent, "lua", "start", {client = id, watchdog = skynet.self()})
		skynet.send(agents[agentIndex], "lua", "start", {client = id, watchdog = skynet.self()})
		agentIndex = agentIndex + 1
		if agentIndex > 10 then
			agentIndex = 1
		end
	end)
end

skynet.start(function()
	for i = 1, 10 do
		agents[i] = skynet.newservice("agent")
	end
	skynet.dispatch("lua", function(session, source, cmd, subcmd, ...)
		local f = assert(CMD[cmd])
		skynet.retpack(f(subcmd, ...))
	end)
end)
