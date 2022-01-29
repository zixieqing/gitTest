
local EventLog = {}

EaterGameId = 1
local cjson = require("cjson")
local filepath = 'config.json'
if FTUtils:isPathExistent(filepath) then
    local data = FTUtils:getFileDataWithoutDec(filepath)
    if data then
        local status, result = pcall(cjson.decode, data)
        if result and result.gameId then
            EaterGameId = tonumber(result.gameId)
        end
    end
end


function EventLog.CommonParams()
    local userId, playerId = 0, 0
    if AppFacade then
        local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
        if gameMgr and gameMgr.userInfo then
            userId = checkint(gameMgr.userInfo.userId)
            playerId = checkint(gameMgr.userInfo.playerId)
        end
    end
    local t = {
        udid = CCNative:getOpenUDID(),
        timestamp = os.time(),
        gameId  = EaterGameId,
        channel = FTUtils:getChannelId(),
        playerId = pid,
    }
    return t
end
--[[--
将 table转为urlencode的数据
@param t table
@see string.urlencode
]]
function EventLog.tabletourlencode(t)
    local args = {}
    local i = 1
    local keys = table.keys(t)
    table.sort(keys)
    if next( keys ) ~= nil then
        for k, key in pairs( keys ) do
            args[i] = string.urlencode(key) .. '=' .. string.urlencode(t[key])
            i = i + 1
        end
    end
    return table.concat(args,'&')
end

EventLog.generateSign = function ( t )
    -- body
    local saltkey = function (  )
        -- body
        return 'a491db2060f0b95399fd0c70c10a69ca'
    end
    local keys = table.keys(t)
    table.sort(keys)
    local retstring = "";
    local tempt = {}
    for _,v in ipairs(keys) do
        table.insert(tempt,t[v])
    end
    if table.nums(tempt) > 0 then
        retstring = table.concat(tempt,'')
    end
    retstring = retstring .. saltkey()
    return CCCrypto:MD5Lua(retstring, false)
end


EventLog.EVENTS = {
    launchGame = 'launchGame',
    package = 'package',
    packageSuccessful = 'packageSuccessful',
    packageFailed = 'packageFailed',
    update = 'update',
    updateSuccessful = 'updateSuccessful',
    updateFailed = 'updateFailed',
    login = 'login',
    loginSuccessful = 'loginSuccessful',
    create = 'create',
    createSuccessful = 'createSuccessful',
    checkin = 'checkin',
}

function EventLog.Log(eventName, parameters)
    --local params = {event = eventName}
    --local t = EventLog.CommonParams()
    --table.merge(params,t)
    --if parameters then
    --    table.merge(params, parameters)
    --end
    --local sign = EventLog.generateSign(params)
    --params.event = nil
    --local ret = EventLog.tabletourlencode(params)
    --ret = string.format("%s&sign=%s",ret,sign)
    --if DEBUG and DEBUG > 0 then
    --    -- print('------------>>>', ret)
    --end
    --local url = table.concat({'http://','data-log.dddwan.com','/index.html?event=',eventName, '&', ret},'')
    --local xhr = cc.XMLHttpRequest:new()
    --xhr.responseType = 4
    --xhr.timeout = 30
    --xhr:open("GET", url)
    --xhr:send()
end

return EventLog
