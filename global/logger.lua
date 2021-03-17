--------------------------------------------------------------------------------
-- @Desc: 日志级别说明如下：
-- TRACE: 程序执行过程追踪，每执行一下，都可以用trace输出一下进行执行跟踪.
-- DEBUG: 指出细粒度信息事件对调试应用程序是非常有帮助的,就是输出debug的信息.
-- INFO : 表明消息在粗粒度级别上突出强调应用程序的运行过程,就是输出提示信息.
-- WARN : 表明会出现潜在错误的情形,就是显示警告信息.
-- ERROR: 指出虽然发生错误事件,但仍然不影响系统的继续运行.就是显示错误信息.
-- FATAL: 指出每个严重的错误事件将会导致应用程序的退出.
-- ALL  : 是最低等级的,用于打开所有日志记录.
-- OFF  : 是最高等级的,用于关闭所有日志记录.
--------------------------------------------------------------------------------
local skynet = require("skynet")
require("global.inspect_utils")

LOG_LEVEL = {
    ALL   = 0,
    TRACE = 1,
    DEBUG = 2,
    INFO  = 3,
    WARN  = 4,
    ERROR = 5,
    FATAL = 6,
    OFF   = 7
}

local logLevel = LOG_LEVEL.ALL -- 日志级别
SET_LOG_LEVEL = function(level)
    logLevel = level
end

local funLevelMap = {
    TRACE = LOG_LEVEL.TRACE,
    LOG   = LOG_LEVEL.DEBUG,
    LOGUP = LOG_LEVEL.TRACE, -- 追踪程序执行
    LGUP2 = LOG_LEVEL.DEBUG,
    DEBUG = LOG_LEVEL.DEBUG,
    INFO  = LOG_LEVEL.INFO,
    WARN  = LOG_LEVEL.WARN,
    ERROR = LOG_LEVEL.ERROR,
    FATAL = LOG_LEVEL.FATAL,
}

local COLOR_RED    = "\x1b[31;1m"
local COLOR_GREEN  = "\x1b[32;1m"
local COLOR_YELLOW = "\x1b[33;1m"
local COLOR_BLUE   = "\x1b[34;1m"
local COLOR_PURPLE = "\x1b[35;1m"
local COLOR_CYAN   = "\x1b[36;1m"
local COLOR_RESET  = "\x1b[0m"

local COLOR_RED_2 = "\x1b[41;37;31;1m"

local funColorMap = {
    TRACE = COLOR_GREEN,
    LOGUP = COLOR_GREEN,
    LGUP2 = COLOR_BLUE,
    LOG   = COLOR_CYAN,
    DEBUG = COLOR_BLUE,
    INFO  = COLOR_PURPLE,
    WARN  = COLOR_YELLOW,
    ERROR = COLOR_RED,
    FATAL = COLOR_RED_2,
}

local function logMsg(funName, msg)
    local color = funColorMap[funName]
    if IS_WINDOWS then
        msg = string.format("[%s] %s", funName, msg)
    else
        msg = string.format("%s[%s] %s %s", color, funName, msg, COLOR_RESET)
    end
    -- skynet.send(".loggerservice", "lua", "log", msg)
    skynet.error(msg)
end

local _tostring = tostring
local function tostring(...)
    local t = {}
    for i = 1, select('#', ...) do
        local x = select(i, ...)
        if type(x) == "table" then
            t[#t + 1] = inspect(x)
        else
            t[#t + 1] = _tostring(x)
        end
    end
    return table.concat(t, " ")
end

-- 添加行信息输出
local function getLogFun(funName)
    return function(...)
        local level = funLevelMap[funName]
        if level < logLevel then
            return
        end

        local debugInfo = debug.getinfo(2, "Sl")
        local lineInfo  = debugInfo.short_src .. ":" .. debugInfo.currentline
        local msg       = string.format("%s: %s", lineInfo, tostring(...))
        logMsg(funName, msg)
    end
end

-- 输出原始错误信息
function logRawErrMsg(...)
    local level = funLevelMap["ERROR"]
    if level < logLevel then
        return
    end

    local msg = string.format("%s", tostring(...))
    logMsg("ERROR", msg)
end

-- 输出上一层调用者信息
function logUp(...)
    local level = funLevelMap["LOGUP"]
    if level < logLevel then
        return
    end
    local debugInfo = debug.getinfo(3, "Sl")
    local lineInfo  = ""
    if debugInfo then
        lineInfo = debugInfo.short_src .. ":" .. debugInfo.currentline
    end
    local msg = string.format("%s: %s", lineInfo, tostring(...))
    logMsg("LOGUP", msg)
end

function logUp2(...)
    local level = funLevelMap["LGUP2"]
    if level < logLevel then
        return
    end
    local debugInfo = debug.getinfo(3, "Sl")
    local lineInfo  = ""
    if debugInfo then
        lineInfo = debugInfo.short_src .. ":" .. debugInfo.currentline
    end
    local msg = string.format("%s: %s", lineInfo, tostring(...))
    logMsg("LGUP2", msg)
end

function logBuff(buff)
    local len  = string.len(buff)
    local info = "buff length: " .. len .. ", buff contents:\n"
    -- 32, 126
    for i = 0, len - 1 do
        local bytes = string.byte(buff, i + 1)
        local chars = string.char(bytes)
        if bytes < 32 or bytes > 126 then
            chars = " "
        end
        info = info .. string.format("%3d-%3d(%s)\t", i, bytes, chars)
        if (i + 1) % 7 == 0 then
            info = info .. "\n"
        end
    end
    logUp(info)
end

-- 生成 log, TRACE, DEBUG ... FATAL等全局方法
log   = getLogFun("LOG")
TRACE = getLogFun("TRACE")
DEBUG = getLogFun("DEBUG")
INFO  = getLogFun("INFO")
WARN  = getLogFun("WARN")
ERROR = getLogFun("ERROR")
FATAL = getLogFun("FATAL")