local skynet = require("skynet")

function class(classname, super)
    local superType = type(super)
    local cls

    if superType ~= "function" and superType ~= "table" then
        superType = nil
        super     = nil
    end

    if superType == "function" or (super and super.__ctype == 1) then
        -- inherited from native C++ Object
        cls = {}

        if superType == "table" then
            -- copy fields from super
            for k, v in pairs(super) do cls[k] = v end
            cls.__create = super.__create
            cls.super    = super
        else
            cls.__create = super
            cls.ctor = function() end
        end

        cls.__cname = classname
        cls.__ctype = 1

        function cls.new(...)
            local instance = cls.__create(...)
            -- copy fields from class to native object
            for k, v in pairs(cls) do instance[k] = v end
            instance.class = cls
            instance:ctor(...)
            return instance
        end

    else
        -- inherited from Lua Object
        if super then
            cls = {}
            setmetatable(cls, {__index = super})
            cls.super = super
        else
            cls = {ctor = function() end}
        end

        cls.__cname = classname
        cls.__ctype = 2 -- lua
        cls.__index = cls

        function cls.new(...)
            local instance = setmetatable({}, cls)
            instance.class = cls
            instance:ctor(...)
            return instance
        end
    end

    return cls
end

function clone(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local newObject      = {}
        lookup_table[object] = newObject
        for key, value in pairs(object) do
            newObject[_copy(key)] = _copy(value)
        end
        return setmetatable(newObject, getmetatable(object))
    end
    return _copy(object)
end

function string.split(str, delimiter)
    if str == nil or str == "" or delimiter == nil then
        return nil
    end

    local result = {}
    for match in (str .. delimiter):gmatch("(.-)" .. delimiter) do
        table.insert(result, match)
    end
    return result
end

function table.unique(t, bArray)
    local check = {}
    local n     = {}
    local idx   = 1
    for k, v in pairs(t) do
        if not check[v] then
            if bArray then
                n[idx] = v
                idx    = idx + 1
            else
                n[k] = v
            end
            check[v] = true
        end
    end
    return n
end

function table.merge(dest, src)
    for k, v in pairs(src) do
        dest[k] = v
    end
end

-- 复制数组
function table.copyArray(array)
    local copy = {}
    for i, v in ipairs(array or {}) do
        copy[i] = v
    end
    return copy
end

-- 复制table
function table.copyTable(tbl)
    local copy = {}
    for k, v in pairs(tbl or {}) do
        copy[k] = v
    end
    return copy
end

function table.removebyvalue(array, value, removeall)
    local c, i, max = 0, 1, #array
    while i <= max do
        if array[i] == value then
            table.remove(array, i)
            c   = c + 1
            i   = i - 1
            max = max - 1
            if not removeall then break end
        end
        i = i + 1
    end
    return c
end

function table.shuffle(array)
    math.randomseed(getmicrosecond())
    local len = #array
    for i = 1, len do
        local ri = math.random(1, len)
        array[ri], array[i] = array[i], array[ri]
    end
end

-- 四舍五入取n位数字
function math.getPreciseDecimal(nNum, n)
    if type(nNum) ~= "number" then
        return nNum
    end

    local fNNum = math.floor(nNum)
    if fNNum == nNum then
        return fNNum
    end

    n = n or 0
    n = math.floor(n)
    if n < 0 then
        n = 0
    end

    local nDecimal = 10 ^ n
    local nTemp    = math.floor(nNum * nDecimal + 0.5)
    local nRet     = nTemp / nDecimal

    return nRet
end

local EARTH_RADIUS = 6378.137
local function rad(d)
    return d * math.pi / 180.0
end

-- 根据两点间的经纬度计算距离,单位米
-- @param lat 纬度值
-- @param lng 经度值
function getDistance(lat1, lon1, lat2, lon2)
    local radLat1 = rad(lat1)
    local radLat2 = rad(lat2)
    local a       = radLat1 - radLat2
    local b       = rad(lon1) - rad(lon2)
    local s       = 2 * math.asin(math.sqrt(math.sin(a / 2) ^ 2 +
        math.cos(radLat1) * math.cos(radLat2) * (math.sin(b / 2) ^ 2), 2))
    s = s * EARTH_RADIUS
    return s * 1000
end

--------------------------------------------------------
-- skynet timer interface
--------------------------------------------------------
local max_id    = 0
local timer_ids = {}

-- 指定时间后运行一次
function add_skynet_timer(sec, func)
    max_id        = max_id + 1
    local id      = max_id
    timer_ids[id] = true
    local wrapper = function()
        if not timer_ids[id] then
            return
        end
        timer_ids[id] = nil
        func()
    end
    skynet.timeout(sec * 100, wrapper)
    return id
end

-- 指定时间不断运行
function add_skynet_timer2(sec, func)
    max_id        = max_id + 1
    local id      = max_id
    timer_ids[id] = true
    local function wrapper()
        skynet.timeout(sec * 100, function()
            if not timer_ids[id] then
                return
            end
            -- timer_ids[id] = nil
            func()
            wrapper()
        end)
    end
    wrapper()
    return id
end

-- 指定时间运行指定次数
function add_skynet_timer3(sec, func, times)
    max_id           = max_id + 1
    local id         = max_id
    timer_ids[id]    = true
    local exec_times = times
    local cur_times  = 1
    local function wrapper()
        skynet.timeout(sec * 100, function()
            if not timer_ids[id] then
                return
            end
            func()
            cur_times = cur_times + 1
            if cur_times >= exec_times then
                timer_ids[id] = nil
            end
            wrapper()
        end)
    end
    func()
    wrapper()
    return id
end

function del_skynet_timer(id)
    timer_ids[id] = nil
end

local rawSkynetExit = skynet.exit
skynet.exit = function(...)
    skynet.error("skynet exit", SERVICE_NAME, ...)
    rawSkynetExit()
end