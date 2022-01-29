local _disk = {}

--[[
--写入文件的记录方式
--]]
function _disk.new(filename, datePattern, pattern)
    assert(filename ~= nil and type(filename) == 'string', 'Invalid filename ' .. tostring(filename))
    local file = nil
    local curDate = nil
    local fileUtils = cc.FileUtils:getInstance()
    local dirpath = fileUtils:getWritablePath() .. "log/"
    if not fileUtils:isDirectoryExist(dirpath) then
        fileUtils:createDirectory(dirpath)
    end
    filename = dirpath .. filename
    return function (logger, level, message, exception)
        local date = os.date(datePattern)
        if date ~= curDate or file == nil then
            curDate = date
            if file ~= nil then file:close() end
            file = io.open(string.format(filename, curDate), 'a')
            if not file then
                io.stderr:write(string.format('can not open the file %s', filename))
            else
                file:setvbuf('line')
            end
        end
        if file then
            file:write(logger:Format(pattern, level, message, exception))
            file:flush()
        end
    end
end

return _disk
