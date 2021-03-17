local skynet = require("skynet")

local CONSOLE_PORT = skynet.getenv("CONSOLE_PORT")
local SERVER_PORT  = skynet.getenv("SERVER_PORT")

skynet.start(function()
    WARN("Server start")
    skynet.newservice("debug_console", CONSOLE_PORT)

    -- 基本服务

    -- watchdog服务
    local watchdog = skynet.newservice("watchdog")
    skynet.call(watchdog, "lua", "start", {
        port      = SERVER_PORT,
        maxclient = 60000,
        nodelay   = true,
    })

    skynet.exit()
end)
