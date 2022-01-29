local Logger = {}

Logger.__index = Logger

local console = require("Frame.Log.console")
local disk = require("Frame.Log.disk")


Logger.DEBUG = "DEBUG"
Logger.INFO = "INFO"
Logger.WARN = "WARN"
Logger.ERROR = "ERROR"
Logger.OFF = "OFF"


Logger._VERSION = '0.2.0'


Logger.LEVELS = {
    INFO = 1,
    DEBUG = 2,
    WARN = 3,
    ERROR = 4,
    OFF = 5
}

Logger.DEFAULT_PATTERN = "[#LEVEL] [#DATE] #MESSAGE at #FILE:#LINE(#METHOD) \n"

local _loggers = {}


--[[
    得到所有的适配器
]]
function Logger.GetAdapters()
    return _loggers
end

function Logger.InitialLoggers(initAdapterFunc)
    if type(initAdapterFunc) == 'function' then
        _loggers = initAdapterFunc()
    else
         _loggers['CONSOLE'] = Logger.new(console.new(), "CONSOLE", Logger.OFF)
    end
end

function Logger.GetLogger(category)
    local log = nil
    if (category ~= nil) then
        log = _loggers[category]
        if (log == nil) then
            for loggerCategory, logger in pairs(_loggers) do
                if (string.find(category, loggerCategory, 1, true) == 1) then
                    log = logger
                    break
                end
            end
        end
    end
    if (log == nil) then
        log = _loggers["CONSOLE"]
    end
    assert(log, "Logger cannot be empty. Check your configuration!")
    return log
end

--[[
-- 添加一个记录日志级别
-- config["foo"] = logger.Logger.new(file.new("foo-%s.log", "%Y-%m-%d"), "foo", logger.INFO)
--]]
function Logger.AddAdapter(func, category)
    if _loggers then
        _loggers[tostring(category)] = func
    end
end

function Logger.new(adapters, category, level)
    local self = {}
    setmetatable(self, Logger)
    if type(adapters) == 'function' then
        adapters = {adapters}
    end
    self.category = category
    self.adapters = adapters
    self.level = level
    return self
end

function Logger:SetLevel(level)
    assert(Logger.LEVELS[level] ~= nil, "unkown adapter level '" .. level .. "''")
    self.level = level
end

function Logger:Log(level, message, exception)
    if Logger.LEVELS[level] >= Logger.LEVELS[self.level] and level ~= Logger.LEVELS.OFF then
        for name,val in pairs(self.adapters) do
            val(self, level, message, exception)
        end
        if self.level == Logger.ERROR then
            if app and app.uiMgr and app.uiMgr.showErrorTips then
                app.uiMgr:showErrorTips()
            end
        end
    end
end

function Logger:Info(message, exception)
    self:Log(Logger.INFO, message, exception)
end

function Logger:Debug(message, exception)
    self:Log(Logger.DEBUG, message, exception)
end

function Logger:Warn(message, exception)
    self:Log(Logger.WARN, message, exception)
end

function Logger:Error(message, exception)
    self:Log(Logger.ERROR, message, exception)
end

local function convertTableToString(message, maxDepth, valueDelimiter, lineDelimiter, indent)
    local result = ""
    if (indent == nil) then
        indent = 2
    end
    if (valueDelimiter == nil) then
        valueDelimiter = " = "
    end
    if (lineDelimiter == nil) then
        lineDelimiter = "\n"
    end
    for k, v in pairs(message) do
        if (result ~= "") then
            result = result .. lineDelimiter
        end
        result = result .. string.rep(" ", indent) .. tostring(k) .. valueDelimiter
        if (type(v) == "table") then
            if (maxDepth > 0) then
                result = result .. "{\n" .. convertTableToString(v, maxDepth - 1, valueDelimiter, lineDelimiter, indent + 2) .. "\n"
                result = result .. string.rep(" ", indent) .. "}"
            else
                result = result .. "[... more table data ...]"
            end
        elseif (type(v) == "function") then
            result = result .. "[function]"
        else
            result = result .. tostring(v)
        end
    end
    return result
end
--[[
--格式化输出
--]]
function Logger:Format(pattern, level, message, exception)
    pattern = pattern or Logger.DEFAULT_PATTERN
    if type(message) == 'table' then
        message = convertTableToString(message, 5)
    end
    -- message = string.gsub(tostring(message), "%%", "%%%%")
    local append = message 
    if (
        string.match(pattern, "#PATH")
        or string.match(pattern, "#FILE")
        or string.match(pattern, "#LINE")
        or string.match(pattern, "#METHOD")
        or string.match(pattern, "#STACKTRACE")
        ) then
        local stackTrace = debug.traceback()
        for line in string.gmatch(stackTrace, "[^\n]-.lua[^\n]+") do
        -- for line in string.gmatch(stackTrace, "[^\n]-.lua:%d+: in [^\n]+") do
            -- if not stirng.match( line, ".logger.-.lua:%d+:") then
            if not string.match( line, ".Log.-.lua") then
                local _, _, sourcePath, sourceLine, sourceMethod = string.find(line, "(.-):(%d+): in (.*)")
                local _, _, sourceFile = string.find(sourcePath or "n/a", ".*\\(.*)")

                pattern = string.gsub(pattern, "#PATH", sourcePath or "n/a")
                pattern = string.gsub(pattern, "#FILE", sourceFile or "n/a")
                pattern = string.gsub(pattern, "#LINE", sourceLine or "n/a")
                pattern = string.gsub(pattern, "#METHOD", sourceMethod or "n/a")
                break
            end
        end
        pattern = string.gsub(pattern, "#STACKTRACE", stackTrace)
    end

    pattern = string.gsub(pattern, "#DATE", tostring(os.date("%Y-%m-%d %H-%M-%S")))
    pattern = string.gsub(pattern, "#RDATE", tostring(os.date()))
    pattern = string.gsub(pattern, "#LEVEL", level)
    pattern = string.gsub(pattern, "#MESSAGE", message)
    if exception ~= nil then
        pattern = string.gsub(pattern, "#ERROR", exception)
    end
    if append then
        if DEBUG == 0 then
            -- pattern = pattern .. tostring(append)
        end
    end
    return pattern
end

return Logger
