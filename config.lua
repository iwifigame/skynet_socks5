-- skynet根目录
skynet_root = "/data/skynet_note/"
proj_root   = "./"

CONSOLE_PORT = "$CONSOLE_PORT"
SERVER_PORT  = "$SERVER_PORT"

start      = "main"
thread     = 2
logger     = "log_0.txt"
logservice = "logger"

harbor     = 0
address    = nil
master     = nil
standalone = nil

preload   = proj_root .. "preload.lua"
bootstrap = "snlua bootstrap"
lualoader = skynet_root .. "lualib/loader.lua"
cpath     = skynet_root .. "cservice/?.so;cservice/?.so;"

local function concat(args)
    local r = ""
    for i = 1, #args do
        if args[i]:sub(1, 1) == "/" then
            r = r .. ";" .. proj_root .. args[i]
        else
            r = r .. ";" .. skynet_root .. args[i]
        end
    end
    return r
end

luaservice = concat({
    "service/?.lua",

    "/?.lua",
    "/service/?.lua",
})

lua_path = concat({
    "lualib/?.lua",
    "lualib/compat10/?.lua",

    "/?.lua",
})

lua_cpath = concat({
    "luaclib/?.so",
})
