require("global.inspect_utils")
require("global.logger")

local skynet = require("skynet.manager")

local _tostring = tostring
local _inspect  = inspect
function inspect(...)
    local t = {}
    for i = 1, select('#', ...) do
        local x = select(i, ...)
        if type(x) == "table" then
            x = _inspect(x)
        end
        t[#t + 1] = _tostring(x)
    end
    return table.concat(t, " ")
end

-- 输出程序运行异常堆栈
__G__TRACKBACK__ = function(msg)
    logRawErrMsg("---------------- 调用堆栈开始 ----------------")
    logRawErrMsg("LUA ERROR: " .. tostring(msg) .. debug.traceback("", 2))
    logRawErrMsg("---------------- 调用堆栈结束 ----------------")
end

-- export global variable
local __g = _G
GV        = {}
setmetatable(GV, {
    __newindex = function(_, name, value)
        rawset(__g, name, value)
    end,

    __index = function(_, name)
        return rawget(__g, name)
    end
})

-- disable create unexpected global variable
function disable_global()
    setmetatable(__g, {
        __newindex = function(_, name, value)
            error(string.format("USE \" GV.%s = value \" INSTEAD OF SET GLOBAL VARIABLE", name), 2)
        end
    })
end

-- disable_global()

GV.IS_WINDOWS = "\\" == package.config:sub(1, 1)