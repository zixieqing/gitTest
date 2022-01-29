--[[
 * author : kaishiqi
 * descpt : 聊天工具类
]]
ChatUtils = {}


CHAT_CHANNELS = {
    CHANNEL_WORLD   = 1,  -- 世界
    CHANNEL_UNION   = 2,  -- 工会
    CHANNEL_SYSTEM  = 3,  -- 系统
    CHANNEL_TEAM    = 4,  -- 组队
    CHANNEL_PRIVATE = 5,  -- 私聊
    CHANNEL_HELP    = 6,  -- 捐助（好友发出的求助）
    CHANNEL_HOUSE   = 7,  -- 御屋
}

CHAT_CHANNEL_TYPE_NAME_FUNCTION_MAP = {
    [CHAT_CHANNELS.CHANNEL_WORLD]   = function() return __('世界') end,
	[CHAT_CHANNELS.CHANNEL_UNION]   = function() return __('工会') end,
	[CHAT_CHANNELS.CHANNEL_PRIVATE] = function() return __('私聊') end,
	[CHAT_CHANNELS.CHANNEL_SYSTEM]  = function() return __('系统') end,
	[CHAT_CHANNELS.CHANNEL_TEAM]    = function() return __('组队') end,
    [CHAT_CHANNELS.CHANNEL_HELP]    = function() return __('捐助') end,
    [CHAT_CHANNELS.CHANNEL_HOUSE]   = function() return __('御屋') end,
}

MSG_TYPES = {
    MSG_TYPE_SELF  = 0, -- 发消息的自己
    MSG_TYPE_OTHER = 1, --发消息的其他人
}

CHAT_MSG_TYPE = {
    TEXT  = 1, -- 文本消息
    SOUND = 2, -- 语音消息
}

HELP_TYPES = {
    RESTAURANT_LUBY   = 1, -- 餐厅露比
    RESTAURANT_BATTLE = 2, -- 餐厅霸王餐
    FRIEND_DONATION   = 3, -- 好友捐助
}

FILTER_LABELS = {
    LOOK     = 'look',        --点击查看
    JOINNOW  = 'joinNow',     --点击加入
    PLAYNAME = 'playName',    --玩家详情
    PARTY    = 'guild',       --公会详情
    STAGE    = 'stage',       --副本详情
    ACTIVITY = 'activity',    --活动详情
    TEXT     = 'desc',        --正常文本
    AUDIO    = 'fileid',      --语音消息id
    TYPE     = 'messagetype', --消息语音类型1广西2语音
}

FILTER_COLORS = {
    look     = '#ee88ff', --点击查看
    joinNow  = '#ee88ff', --点击加入
    playname = '#ee88ff', --玩家详情
    guild    = '#ee88ff', --公会详情
    stage    = '#ee88ff', --副本详情
    activity = '#ee88ff', --活动详情
}

FILTERS = {
    look        = 'look',        --点击查看
    joinNow     = 'joinNow',     --点击加入
    playname    = 'playName',    --玩家详情
    guild       = 'guild',       --公会详情
    stage       = 'stage',       --副本详情
    activity    = 'activity',    --活动详情
    desc        = 'desc',        --正常文本
    fileid      = 'fileid',      --语音消息id
    messagetype = 'messagetype', --消息语音类型1广西2语音
}

MAX_SHOW_MSG = 40


--[[
    根据 频道类型 获取 频道类型名称
    @params channelType : int    频道类型 @see CHAT_CHANNELS
    @return channelName : string 类型名称
--]]
function ChatUtils.GetChannelTypeName(channelType)
	local nameFunc = CHAT_CHANNEL_TYPE_NAME_FUNCTION_MAP[checkint(channelType)]
    return nameFunc and nameFunc() or __('其他')
end


function ChatUtils.InitDatabase()
    -- 清空出错聊天的db
    local shareFileUtils = cc.FileUtils:getInstance()
    local fsize = io.filesize(CHAT_DB_PATH)
    if fsize and fsize == 0 then
        shareFileUtils:removeFile(CHAT_DB_PATH)
    end

    -- 拷贝聊天的db文件到项目的可写目录
    local originalDbPath = RES_PATH.. CHAT_DB_NAME
    if not shareFileUtils:isFileExist(AUDIO_ABSOLUTE_PATH) then
        shareFileUtils:createDirectory(AUDIO_ABSOLUTE_PATH)
    end
    if not shareFileUtils:isFileExist(CHAT_DB_PATH) and shareFileUtils:isFileExist(originalDbPath) then
        io.writefile(CHAT_DB_PATH, FTUtils:getFileData(originalDbPath))
    end

    --[[
    -- 由于一个数据表message_remind的结构有问题会导致红点插入不进去
    --]]
    local dbPath   = CHAT_DB_PATH
    local insertId = 0
    if utils.isExistent(dbPath) then
        local sqlite3 = require('lsqlite3')
        local db      = sqlite3.open(dbPath)
        if db and db:isopen() then
            --先判断新的数据是否存在
            for row in db:nrows("SELECT count(*) size FROM sqlite_master WHERE type='table' AND name='message_remind2'") do
                if row.size <= 0 then
                    --不存在建立
                    db:exec([[
CREATE TABLE `message_remind2` (
    `id`              INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    `playerId`	      INTEGER NOT NULL,
    `newMessage`	  TEXT,
    `lastReceiveTime` INTEGER,
    `lastReadTime`	  INTEGER,
    `hasNewMessage`   INTEGER,
    `myPlayerId`	  INTEGER,
    `ext1` TEXT
);
                        ]])
                end
            end
            db:close()
        end
    end
end


function ChatUtils.IsModuleAvailable()
    return CommonUtils.GetModuleAvailable(MODULE_SWITCH.CHAT) and CommonUtils.GetControlGameProterty(CONTROL_GAME.CHAT_PUSH)
end


-------------------------------------------------------------------------------
-- 世界信息
-------------------------------------------------------------------------------

--[[
--添加世界消息进数据库的逻辑
--@params
--]]
function ChatUtils.UpdateWorldMsg(params)
    if type(params) ~= 'table' then
        return
    end
    local dbPath   = CHAT_DB_PATH
    local insertId = 0
    if utils.isExistent(dbPath) then
        local sqlite3 = require('lsqlite3')
        local db      = sqlite3.open(dbPath)
        if db and db:isopen() then
            --数据库打开后进行数据读取
            local fileid = (params.fileid or '')
            local sql    = string.format([[
                insert into worldmsg (playerId, playerName,message,sendTime,messagetype,fileid,sender,channel
                ) values (%d, '%s', '%s', %d, %d, '%s',%d,%d);
            ]], checkint(params.sendPlayerId),
                string.gsub(params.sendPlayerName, '\'', '\'\''),
                string.gsub(params.message, '\'', '\'\''),
                params.sendTime,
                params.messagetype,
                fileid,
                checkint(params.sender),
                checkint(params.channel))

            -- print(sql)
            -- db:exec('begin;')
            -- pstmt:bind(1, checkint(params.sendPlayerId))
            -- pstmt:bind(2, params.sendPlayerName)
            -- pstmt:bind(3, checkint(params.receivePlayerId))
            -- pstmt:bind(4, params.receivePlayerName)
            -- pstmt:bind(5, params.content)
            -- pstmt:bind(6, params.sendTime)
            -- pstmt:bind(7, params.msgType)
            -- pstmt:bind(8, (params.voiceId or ''))
            -- pstmt:step()
            -- pstmt:reset() --执行了更新
            db:exec(sql)
            -- local t = db:exec('commit;')
            -- pstmt:finalize()
            insertId = db:last_insert_rowid()
            -- print('-----------', insertId)
            db:close()
        end
    end
    return insertId
end

--[[
--获取到所有世界聊天记录的消息集合信息取最新的50条
--]]
function ChatUtils.RetriveWorldMsg()
    local dbPath = CHAT_DB_PATH
    local datas  = {}
    if utils.isExistent(dbPath) then
        local sqlite3 = require('lsqlite3')
        local db      = sqlite3.open(dbPath)
        if db and db:isopen() then
            local sql = string.format('select * from worldmsg order by sendTime desc limit 50;')
            for row in db:nrows(sql) do
                table.insert(datas, row)
            end
            db:close()
        end
    end
    return datas
end


-------------------------------------------------------------------------------
-- 帮助信息
-------------------------------------------------------------------------------

--[[
向数据库插入聊天系统帮助信息
@params 写入数据库的数据
--]]
function ChatUtils.InsertChatHelpMessage(params)
    if type(params) ~= 'table' then
        return
    end
    ChatUtils.DeleteChatHelpMessage(params)
    local dbPath   = CHAT_DB_PATH
    local insertId = 0
    if utils.isExistent(dbPath) then
        local sqlite3 = require('lsqlite3')
        local db      = sqlite3.open(dbPath)
        if db and db:isopen() then
            --数据库打开后进行数据读取
            local sql = string.format([[
                insert into helps(playerId, helpTime, helpType, goodsId, ext1, ext2
                ) values (%d, %d, %d, %d, %s, %s);
            ]],
                checkint(params.playerId),
                checkint(params.helpTime),
                checkint(params.helpType),
                checkint(params.goodsId),
                tostring(params.expirationTime or '0'),
                tostring(params.assistanceId or '0'))
            db:exec('begin;')
            db:exec(sql)
            local t  = db:exec('commit;')
            -- pstmt:finalize()
            insertId = db:last_insert_rowid()
            -- print('-----------', insertId)
            db:close()
        end
    end
    return insertId
end


--[[
删除数据库中的帮助信息
--]]
function ChatUtils.DeleteChatHelpMessage(params)
    if type(params) ~= 'table' then
        return
    end
    local dbPath = CHAT_DB_PATH
    local isOk   = false
    if utils.isExistent(dbPath) then
        local sqlite3 = require('lsqlite3')
        local db      = sqlite3.open(dbPath)
        if db and db:isopen() then
            --数据库打开后进行数据读取
            local sql = string.format([[
                delete from helps where helpType = %d and playerId = %d;
            ]],
                checkint(params.helpType),
                checkint(params.playerId))
            db:exec('begin;')
            db:exec(sql)
            if db:exec(sql) == sqlite3.OK then
                --删除成功了
                isOk = true
            end
            local t = db:exec('commit;')
            db:close()
        end
    end
    return isOk
end


--[[
获取聊天系统帮助信息
--]]
function ChatUtils.GetChatHelpDatas()
    local dbPath  = CHAT_DB_PATH
    local datas   = {}
    local idTable = {}
    local idStr   = nil
    if utils.isExistent(dbPath) then
        local sqlite3 = require('lsqlite3')
        local db      = sqlite3.open(dbPath)
        if db and db:isopen() then
            local sql = string.format('select playerId, helpTime, helpType, goodsId, ext1 as expirationTime, ext2 as assistanceId from helps where helpTime > %d and helpTime < %d', os.time() - 43200, os.time())
            for row in db:nrows(sql) do
                table.insert(datas, row)
            end
            local t = db:exec('commit;')
            db:close()
        end
    end
    table.sort(datas, function(a, b)
        return a.helpTime < b.helpTime
    end)
    return datas
end


--[[
获取帮助列表玩家Id
--]]
function ChatUtils.GetHelpListPlayerId()
    local datas   = ChatUtils.GetChatHelpDatas()
    local idTable = {}
    local idStr   = nil
    for i, data in ipairs(datas) do
        if next(idTable) ~= nil then
            for i, v in ipairs(idTable) do
                if checkint(v) == checkint(data.playerId) then
                    break
                end
                if i == #idTable then
                    table.insert(idTable, data.playerId)
                end
            end
        else
            table.insert(idTable, data.playerId)
        end
    end
    for i, v in ipairs(idTable) do
        if idStr == nil then
            idStr = tostring(v)
        else
            idStr = idStr .. ',' .. tostring(v)
        end
    end
    return idStr
end


-------------------------------------------------------------------------------
-- 私信信息
-------------------------------------------------------------------------------

--[[
--查找与某个玩家的所有聊天记录
--@fromId 发送者id
--@toId  接收者id
--]]
function ChatUtils.GetChatMessages(fromId, toId)
    local dbPath = CHAT_DB_PATH
    local datas  = {}
    if utils.isExistent(dbPath) then
        local sqlite3 = require('lsqlite3')
        local db      = sqlite3.open(dbPath)
        if db and db:isopen() then
            --数据库打开后进行数据读取
            -- -select * from Qmsg t where ((t.sendPlayerId = %d and t.receivePlayerId = %d) or (t.sendPlayerId = %d and t.receivePlayerId = %d)) --desc
            local sql = string.format('select * from Qmsg t where ((t.sendPlayerId = %d and t.receivePlayerId = %d) or (t.sendPlayerId = %d and t.receivePlayerId = %d)) order by sendTime ;', 
                checkint(fromId), 
                checkint(toId), 
                checkint(toId), 
                checkint(fromId)
            )
            for row in db:nrows(sql) do
                table.insert(datas, row)
            end
            db:close()
        end
    end
    -- 排序
    table.sort(datas, function(a, b)
        return checkint(a.sendTime) < checkint(b.sendTime)
    end)
    return datas
end
--[[
--删除某条聊天记录
--@params id --聊天记录的数据库id
--]]
function ChatUtils.DeleteChateMessage(id)
    local dbPath = CHAT_DB_PATH
    local isOk   = false
    if utils.isExistent(dbPath) then
        local sqlite3 = require('lsqlite3')
        local db      = sqlite3.open(dbPath)
        if db and db:isopen() then
            --数据库打开后进行数据读取
            local sql = string.format('delete from Qmsg where id = %d;', checkint(id))
            if db:exec(sql) == sqlite3.OK then
                --删除成功了
                isOk = true
            end
            db:close()
        end
    end
    return isOk, id
end

function ChatUtils.GetChatGroups()
    local dbPath = CHAT_DB_PATH
    local datas  = {}
    if utils.isExistent(dbPath) then
        local sqlite3 = require('lsqlite3')
        local db      = sqlite3.open(dbPath)
        if db and db:isopen() then
            local sql = string.format('select * from (select receivePlayerId as id ,sendPlayerId, sendPlayerName,receivePlayerId,receivePlayerName,content, sendTime, msgType,voiceId, Field10 as time from Qmsg where (sendPlayerId = %d and receivePlayerId <> %d) union select sendPlayerId as id ,sendPlayerId, sendPlayerName,receivePlayerId,receivePlayerName,content, sendTime, msgType,voiceId, Field10 as time from Qmsg where (sendPlayerId <> %d and receivePlayerId = %d)) group by id order by max(sendTime) desc', 
                app.gameMgr:GetUserInfo().playerId, 
                app.gameMgr:GetUserInfo().playerId, 
                app.gameMgr:GetUserInfo().playerId, 
                app.gameMgr:GetUserInfo().playerId
            )
            -- local sql = string.format('select * from (select receivePlayerId as id ,sendPlayerId, sendPlayerName,receivePlayerId,receivePlayerName,content, sendTime, msgType,voiceId from Qmsg where (sendPlayerId = %d and receivePlayerId <> %d) union select sendPlayerId as id ,sendPlayerId, sendPlayerName,receivePlayerId,receivePlayerName,content, sendTime, msgType,voiceId from Qmsg where (sendPlayerId <> %d and receivePlayerId = %d)) group by id order by max(sendTime) desc', app.gameMgr:GetUserInfo().playerId, app.gameMgr:GetUserInfo().playerId, app.gameMgr:GetUserInfo().playerId, app.gameMgr:GetUserInfo().playerId)
            for row in db:nrows(sql) do
                table.insert(datas, row)
            end
            db:close()
        end
    end
    return datas
end
--[[
获取最近联系人id
--]]
function ChatUtils.GetRecentContactsId()
    local dbPath  = CHAT_DB_PATH
    local datas   = {}
    local idTable = {}
    local idStr   = nil
    if utils.isExistent(dbPath) then
        local sqlite3 = require('lsqlite3')
        xTry(function()
            local db = sqlite3.open(dbPath)
            if db and db:isopen() then
                local sql = string.format('select * from (select receivePlayerId as id ,sendPlayerId,sendPlayerName,receivePlayerId,receivePlayerName,content, sendTime, msgType,voiceId, Field10 as time from Qmsg where (sendPlayerId = %d and receivePlayerId <> %d) union select sendPlayerId as id ,sendPlayerId, sendPlayerName,receivePlayerId,receivePlayerName,content,sendTime, msgType,voiceId, Field10 as time from Qmsg where (sendPlayerId <> %d and receivePlayerId = %d)) where (sendTime > %d and sendTime <%d)', 
                    app.gameMgr:GetUserInfo().playerId, 
                    app.gameMgr:GetUserInfo().playerId, 
                    app.gameMgr:GetUserInfo().playerId, 
                    app.gameMgr:GetUserInfo().playerId, 
                    os.time() - 86400, os.time()
                )
                -- local sql = string.format('select * from (select receivePlayerId as id ,sendPlayerId,sendPlayerName,receivePlayerId,receivePlayerName,content, sendTime, msgType,voiceId from Qmsg where (sendPlayerId = %d and receivePlayerId <> %d) union select sendPlayerId as id ,sendPlayerId, sendPlayerName,receivePlayerId,receivePlayerName,content,sendTime, msgType,voiceId from Qmsg where (sendPlayerId <> %d and receivePlayerId = %d)) where (sendTime > %d and sendTime <%d)', app.gameMgr:GetUserInfo().playerId, app.gameMgr:GetUserInfo().playerId, app.gameMgr:GetUserInfo().playerId, app.gameMgr:GetUserInfo().playerId, os.time() - 86400, os.time())
                for row in db:nrows(sql) do
                    table.insert(datas, row)
                end
                db:close()
            end
        end, function()
            app.fileUtils:removeFile(dbPath)

            local originalDbPath = RES_PATH .. CHAT_DB_NAME
            if not app.fileUtils:isFileExist(AUDIO_ABSOLUTE_PATH) then
                app.fileUtils:createDirectory(AUDIO_ABSOLUTE_PATH)
            end
            if not app.fileUtils:isFileExist(CHAT_DB_PATH) and app.fileUtils:isFileExist(originalDbPath) then
                io.writefile(CHAT_DB_PATH, FTUtils:getFileData(originalDbPath))
            end
        end)
    end
    for i, v in ipairs(datas) do
        local myId    = app.gameMgr:GetUserInfo().playerId
        local otherId = nil
        if checkint(v.receivePlayerId) == checkint(myId) then
            otherId = v.sendPlayerId
        elseif checkint(v.sendPlayerId) == checkint(myId) then
            otherId = v.receivePlayerId
        end
        if next(idTable) ~= nil then
            for i, v in ipairs(idTable) do
                if checkint(v) == checkint(otherId) then
                    break
                end
                if i == #idTable then
                    table.insert(idTable, otherId)
                end
            end
        else
            table.insert(idTable, otherId)
        end
    end
    -- 屏蔽黑名单
    local blacklist = app.gameMgr:GetUserInfo().blacklist
    for i, v in ipairs(idTable) do
        local isBlacklist = CommonUtils.IsInBlacklist(v)
        if checkint(v) > 0 and not isBlacklist then
            if idStr == nil then
                idStr = tostring(v)
            else
                idStr = idStr .. ',' .. tostring(v)
            end
        end
    end
    return idStr
end


--[[
-- 向数据库写入数据
--@params 写入数据库的数据
--]]
function ChatUtils.InertChatMessage(params)
    if type(params) ~= 'table' then
        return
    end
    local dbPath   = CHAT_DB_PATH
    local insertId = 0
    if utils.isExistent(dbPath) then
        local sqlite3 = require('lsqlite3')
        local db      = sqlite3.open(dbPath)
        if db and db:isopen() then
            --数据库打开后进行数据读取
            local voiceId = (params.voiceId or '')
            local sql     = string.format([[
                insert into Qmsg(sendPlayerId, sendPlayerName,receivePlayerId,receivePlayerName,
                content, sendTime, msgType,voiceId,Field10
                ) values (%d, '%s', %d, '%s', '%s', %d, %d, '%s',%d);
            ]], checkint(params.sendPlayerId),
                string.gsub(params.sendPlayerName, '\'', '\'\'') or '',
                checkint(params.receivePlayerId),
                string.gsub(params.receivePlayerName, '\'', '\'\'') or '',
                string.gsub(params.content, '\'', '\'\'') or '',
                checkint(params.sendTime),
                params.msgType or '',
                voiceId, checkint(params.time))
            -- local pstmt = db:prepare(sql)
            db:exec('begin;')
            -- pstmt:bind(1, checkint(params.sendPlayerId))
            -- pstmt:bind(2, params.sendPlayerName)
            -- pstmt:bind(3, checkint(params.receivePlayerId))
            -- pstmt:bind(4, params.receivePlayerName)
            -- pstmt:bind(5, params.content)
            -- pstmt:bind(6, params.sendTime)
            -- pstmt:bind(7, params.msgType)
            -- pstmt:bind(8, (params.voiceId or ''))
            -- pstmt:step()
            -- pstmt:reset() --执行了更新
            db:exec(sql)
            local t  = db:exec('commit;')
            -- pstmt:finalize()
            insertId = db:last_insert_rowid()
            -- print('-----------', insertId)
            db:close()
        end
    end
    return insertId
end


--[[
玩家新消息信息存入数据库
@params table {
    playerId int 玩家Id
    newMessage string 最新信息
    lastReciveTime int 接受最新信息时间
    lastReadTime int 查看最新信息时间
    hasNewMessage bool 是否有最新信息
}
--]]
function ChatUtils.UpdatePlayerNewMessage( params )
    if type(params) ~= 'table' then
        return
    end
    local dbPath   = CHAT_DB_PATH
    local insertId = 0
    if utils.isExistent(dbPath) then
        local sqlite3 = require('lsqlite3')
        local db      = sqlite3.open(dbPath)
        if db and db:isopen() then
            -- 判断此玩家有没有消息数据
            local sql = nil
            local temp = ChatUtils.GetNewMessageByPlayerId(params.playerId)
            if temp and next(temp) ~= nil then
                sql = string.format([[
                    update message_remind2 set newMessage = '%s', lastReceiveTime = %d, hasNewMessage = %d where playerId = %d and myPlayerId = %d;
                ]],
                    tostring(params.newMessage),
                    checkint(params.lastReceiveTime),
                    checkint(params.hasNewMessage),
                    checkint(params.playerId),
                    checkint(app.gameMgr:GetUserInfo().playerId)
                )
            else
                sql = string.format([[
                    insert into message_remind2 (playerId, newMessage, lastReceiveTime, lastReadTime, hasNewMessage, myPlayerId) values (%d, '%s', %d, 0, %d, %d);
                ]],
                    checkint(params.playerId),
                    tostring(params.newMessage),
                    checkint(params.lastReceiveTime),
                    checkint(params.hasNewMessage),
                    checkint(app.gameMgr:GetUserInfo().playerId)
                )
            end
            --数据库打开后进行数据读取
            db:exec('begin;')
            db:exec(sql)
            db:exec('commit;')
            db:exec('end;')
            -- pstmt:finalize()
            insertId = db:last_insert_rowid()
            -- print('-----------', insertId)
            db:close()
        end

    end
    return insertId
end
--[[
浏览最新消息
--]]
function ChatUtils.ReadNewMessage( playerId )
    local dbPath   = CHAT_DB_PATH
    local insertId = 0
    if utils.isExistent(dbPath) then
        local newMsg = ChatUtils.GetNewMessageByPlayerId(playerId)
        if newMsg and next(newMsg) ~= nil then
            local sqlite3 = require('lsqlite3')
            local db      = sqlite3.open(dbPath)
            if db and db:isopen() then
                -- 判断此玩家有没有消息数据
                local sql = nil
                sql = string.format([[
                    update message_remind2 set lastReadTime = %d, hasNewMessage = %d where playerId = %d and myPlayerId = %d;
                ]],
                    checkint(os.time()),
                    0,
                    checkint(playerId),
                    checkint(app.gameMgr:GetUserInfo().playerId)
                )
                --数据库打开后进行数据读取
                db:exec('begin;')
                db:exec(sql)
                db:exec('commit;')
                db:exec('end;')
                -- pstmt:finalize()
                insertId = db:last_insert_rowid()
                -- print('-----------', insertId)
                db:close()
            end
        end
    end
    return insertId
end
--[[
查询和某一玩家的最新聊天记录
@params playerId int 对方的玩家id
--]]
function ChatUtils.GetNewMessageByPlayerId( playerId )
    local dbPath = CHAT_DB_PATH
    local datas  = {}
    if utils.isExistent(dbPath) then
        local sqlite3 = require('lsqlite3')
        local db      = sqlite3.open(dbPath)
        if db and db:isopen() then
            local sql = string.format('select playerId, newMessage, lastReceiveTime, hasNewMessage, lastReadTime from message_remind2 where playerId = %d and myPlayerId = %d', 
                checkint(playerId), 
                app.gameMgr:GetUserInfo().playerId
            )
            for row in db:nrows(sql) do
                datas = row
            end
            -- datas = db:nrows(sql)
            db:close()
        end
    end
    return checktable(datas)
end
--[[
判断是否有未读信息
--]]
function ChatUtils.HasUnreadMessage()
    local dbPath = CHAT_DB_PATH
    local datas  = {}
    if utils.isExistent(dbPath) then
        local sqlite3 = require('lsqlite3')
        local db      = sqlite3.open(dbPath)
        if db and db:isopen() then
            local sql = string.format('select playerId, newMessage, lastReceiveTime, hasNewMessage, lastReadTime from message_remind2 where myPlayerId = %d', 
                app.gameMgr:GetUserInfo().playerId
            )
            for row in db:nrows(sql) do
                table.insert(datas, row)
            end
            db:close()
        end
    end
    local hasUnreadMsg = false
    for i,v in ipairs(datas) do
        if CommonUtils.GetIsFriendById(checkint(datas.playerId)) then
            if checkint(v.hasNewMessage) == 1 then
                hasUnreadMsg = true
                break
            end
        else
            if (os.time() - checkint(v.lastReceiveTime)) <= 86400 and checkint(v.hasNewMessage) == 1 then -- 只显示一天内消息
                if not CommonUtils.IsInBlacklist(v.playerId) then -- 排除黑名单
                    hasUnreadMsg = true
                    break
                end
            end
        end
    end
    return hasUnreadMsg
end
