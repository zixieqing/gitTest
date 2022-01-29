--[[
 * author : kaishiqi
 * descpt : 关于 猫屋数据 的本地模拟
]]
local _r  = virtualData._r
local j2t = virtualData.j2t
local t2t = virtualData.t2t

local AVATAR_SAFE_SIZE = CatHouseUtils.AVATAR_SAFE_SIZE

local avatarTypeMap = {}
for _, avatarConf in pairs(CONF.CAT_HOUSE.AVATAR_INFO:GetAll()) do
    local avatarType = CatHouseUtils.GetAvatarTypeByGoodsId(avatarConf.id)
    avatarTypeMap[tostring(avatarType)] = avatarTypeMap[tostring(avatarType)] or {}
    table.insert(avatarTypeMap[tostring(avatarType)], avatarConf)
end


local bubbleIdList   = {}
local identityIdList = {}
for _, mallConf in pairs(CONF.CAT_HOUSE.MALL_INFO:GetAll()) do
    local goodsType = CatHouseUtils.GetDressTypeByGoodsId(mallConf.id)
    if goodsType == CatHouseUtils.AVATAR_STYLE_TYPE.BUBBLE then
        table.insert(bubbleIdList, checkint(mallConf.id))
    elseif goodsType == CatHouseUtils.AVATAR_STYLE_TYPE.IDENTITY then
        table.insert(identityIdList, checkint(mallConf.id))
    end
end


local DEBUG_DEFINES = {
    HAS_DEFAULT_HEAD       = true, -- 设置初始 形象
    HAS_DEFAULT_BUBBLE     = true, -- 设置初始 气泡
    HAS_DEFAULT_BUSIESS    = true, -- 设置初始 名片
    HAS_DEFAULT_EVENTS     = true, -- 设置初始 事件
    HAS_DEFAULT_SUIT       = true, -- 设置初始 套装
    ROOMER_CHANGE_INTERVAL = 5*10, -- 自动变化 房客间隔
    ROOMER_WALK_INTERVAL   = 3*10, -- 自动移动 房客间隔
    ROOMER_CHAT_INTERVAL   = 4*10, -- 自动聊天 房客间隔
    HAS_INIT_CAT_MODULE    = true, -- 猫咪功能 初始化
}


virtualData.catHouse = {}


virtualData.catHouse.createRandomHeadId = function()
    local cardId  = virtualData._rValue(virtualData.validCardIdList, 1)[1]
    local skinMap = virtualData.validCardIdMap[tostring(cardId)]
    local skinId  = virtualData._rValue(table.keys(skinMap), 1)[1]
    return checkint(skinId)
end


virtualData.catHouse.createRandomBubbleId = function()
    return checkint(virtualData._rValue(bubbleIdList, 1)[1])
end


virtualData.catHouse.createRandomIdentityId = function()
    return checkint(virtualData._rValue(identityIdList, 1)[1])
end


virtualData.catHouse.createAvatarRandomPos = function(avatarId, avatarRect)
    local locaConf   = CONF.CAT_HOUSE.AVATAR_LOCATION:GetValue(avatarId)
    local avatarType = CatHouseUtils.GetAvatarTypeByGoodsId(avatarId)
    local locations  = checktable(locaConf.location)
    local avatarW    = checkint(locaConf.collisionBoxWidth)
    local avatarH    = checkint(locaConf.collisionBoxLength)
    local loopNum    = 50
    local appended   = false
    local randomPos  = cc.p(checkint(locations[1]), checkint(locations[2]))
    local avatarRect = avatarRect
    if avatarRect == nil then
        avatarRect = {}
        for _, avatarData in pairs(virtualData.catHouse_.location) do
            local avatarType = CatHouseUtils.GetAvatarTypeByGoodsId(avatarData.goodsId)
            local locaConf   = CONF.CAT_HOUSE.AVATAR_LOCATION:GetValue(avatarData.goodsId)
            local avatarW    = checkint(locaConf.collisionBoxWidth)
            local avatarH    = checkint(locaConf.collisionBoxLength)
            local avatarPos  = avatarData.location
            if avatarType ~= CatHouseUtils.AVATAR_TYPE.WALL and avatarType ~= CatHouseUtils.AVATAR_TYPE.FLOOR and avatarType ~= CatHouseUtils.AVATAR_TYPE.CELLING then
                table.insert(avatarRect, cc.rect(avatarPos.x, avatarPos.y, avatarW, avatarH))
            end
        end
    end
    if avatarType ~= CatHouseUtils.AVATAR_TYPE.WALL and avatarType ~= CatHouseUtils.AVATAR_TYPE.FLOOR and avatarType ~= CatHouseUtils.AVATAR_TYPE.CELLING then
        while loopNum > 0 and not appended do
            local avatarX = _r(AVATAR_SAFE_SIZE.width - avatarW)
            local avatarY = _r(AVATAR_SAFE_SIZE.height - avatarH)
            local avtRect = cc.rect(avatarX, avatarY, avatarW, avatarH)
            local isCross = false
            for _, rect in ipairs(avatarRect) do
                if cc.rectIntersectsRect(rect, avtRect) then
                    isCross = true
                    break
                end
            end
            if not isCross then
                table.insert(avatarRect, avtRect)
                randomPos.x = avatarX
                randomPos.y = avatarY
                appended = true
            end
            loopNum = loopNum - 1
        end
    end
    return randomPos
end


virtualData.catHouse.createAvatarLocationMap = function(houseLevel)
    local locationMap = {}
    local avatarRect  = {}
    local avatarList  = {}
    local levelConf   = CONF.CAT_HOUSE.LEVEL_INFO:GetValue(houseLevel)
    local catteryNum  = checkint(levelConf.catLimit)
    local buildAvatar = function(type, num)
        local avatarDataList = {}
        local avatarTypeList = avatarTypeMap[tostring(type)] or {}
        local avatarConfList = virtualData._rValue(avatarTypeList, checkint(num))
        for index, avatarConf in ipairs(avatarConfList) do
            local avatarId   = checkint(avatarConf.id)
            local avatarPos  = virtualData.catHouse.createAvatarRandomPos(avatarId, avatarRect)
            local avatarData = {
                goodsId = avatarId,
                damaged = _r(0,checkint(avatarConf.damage)),
                x = avatarPos.x,
                y = avatarPos.y,
            }
            avatarDataList[index] = avatarData
        end
        return avatarDataList
    end
    table.insertto(avatarList, buildAvatar(CatHouseUtils.AVATAR_TYPE.WALL, 1))  -- 墙壁
    table.insertto(avatarList, buildAvatar(CatHouseUtils.AVATAR_TYPE.FLOOR, 1))  -- 地板
    table.insertto(avatarList, buildAvatar(CatHouseUtils.AVATAR_TYPE.CELLING, _r(0,1))) -- 吊顶
    table.insertto(avatarList, buildAvatar(CatHouseUtils.AVATAR_TYPE.DECORATE, _r(0,9))) -- 装饰
    table.insertto(avatarList, buildAvatar(CatHouseUtils.AVATAR_TYPE.CATTERY, _r(0, catteryNum)))  -- 猫窝

    -- location data
    for _, avatarData in pairs(avatarList) do
        local uuid = virtualData.generateUuid()
        locationMap[tostring(uuid)] = {
            goodsUuid = uuid,                         -- 道具唯一id
            goodsId   = checkint(avatarData.goodsId), -- 道具配表id
            damaged   = checkint(avatarData.damaged), -- 是否被损坏
            location  = {                             -- 坐标map（key：x|y）
                x = checkint(avatarData.x),
                y = checkint(avatarData.y),
            },
        }
    end

    return locationMap
end


-------------------------------------------------------------------------------
-- avatar data
-------------------------------------------------------------------------------

virtualData.catHouse.appendAvatar = function(goodsId)
    local cmdData = {
        goodsUuid = virtualData.generateUuid(),
    }
    return cmdData
end


virtualData.catHouse.removeAvatar = function(goodsId, goodsUuid)
    local avatarData = virtualData.catHouse_.location[tostring(goodsUuid)] or {}
    virtualData.catHouse_.location[tostring(goodsUuid)] = nil
end


virtualData.catHouse.movedAvatar = function(goodsId, goodsUuid, x, y)
    if not virtualData.catHouse_.location[tostring(goodsUuid)] then
        local avatarConf = CONF.CAT_HOUSE.AVATAR_INFO:GetValue(goodsId)
        local avatarType = checkint(avatarConf.mainType)
        local avatarData = {
            goodsUuid = checkint(goodsUuid),         -- 道具唯一id
            goodsId   = checkint(goodsId),           -- 道具配表id
            location  = pos or cc.p(0,0),            -- 坐标map（key：x|y）
            damaged   = _r(0,checkint(avatarConf.damage)), -- 是否损坏
        }
        virtualData.catHouse_.location[tostring(goodsUuid)] = avatarData
    end

    -- update loaction
    local avatarData    = virtualData.catHouse_.location[tostring(goodsUuid)]
    avatarData.location = cc.p(x, y)
end


virtualData.catHouse.cleanAllAvatar = function()
    local cmdData = {
        cleanList = {}
    }

    for goodsUuid, avatarData in pairs(virtualData.catHouse_.location or {}) do
        local goodsId    = avatarData.goodsId
        local avatarConf = CONF.CAT_HOUSE.AVATAR_INFO:GetValue(goodsId)
        local canRemoved = true
        local avatarType = checkint(avatarConf.mainType)
        if avatarType == CatHouseUtils.AVATAR_TYPE.WALL or avatarType == CatHouseUtils.AVATAR_TYPE.FLOOR then
            canRemoved = false
        end

        if canRemoved then
            table.insert(cmdData.cleanList, {goodsId = goodsId, goodsUuid = goodsUuid})
        end
    end

    for _, cleanData in ipairs(cmdData.cleanList) do
        virtualData.catHouse.removeAvatar(cleanData.goodsId, cleanData.goodsUuid)
    end
    return cmdData
end


-------------------------------------------------------------------------------
-- room data
-------------------------------------------------------------------------------

local stopRoomerAutoChangeFunc = function()
    if virtualData.roomerAutoChangeHandler_ then
        scheduler.unscheduleGlobal(virtualData.roomerAutoChangeHandler_)
        virtualData.roomerAutoChangeHandler_ = nil
    end
end
local startRoomerAutoChangeFunc = function()
    if virtualData.roomerAutoChangeHandler_ then return end
    virtualData.roomerAutoChangeHandler_ = scheduler.scheduleGlobal(function()
        local memberNum = table.nums(virtualData.catHouseRoom_.memberMap)
        if memberNum < virtualData.catHouseRoom_.roomSize then
            -- append roomer
            local cmdData = virtualData.catHouse.appendRoomMember()
            if next(cmdData) ~= nil then
                gameServer:sendAllClient(NetCmd.HOUSE_MEMBER_VISIT, {data = cmdData})
            end
        else
            -- remove roomer
            local cmdData = virtualData.catHouse.removeRoomMember()
            if next(cmdData) ~= nil then
                gameServer:sendAllClient(NetCmd.HOUSE_MEMBER_LEAVE, {data = cmdData})
            end
        end
    end, DEBUG_DEFINES.ROOMER_CHANGE_INTERVAL)
end


local stopHouseRoomerAutoWalkFunc = function()
    if virtualData.houseRoomerAutoWalkHandler_ then
        scheduler.unscheduleGlobal(virtualData.houseRoomerAutoWalkHandler_)
        virtualData.houseRoomerAutoWalkHandler_ = nil
    end
end
local startHouseRoomerAutoWalkFunc = function()
    if virtualData.houseRoomerAutoWalkHandler_ then return end
    virtualData.houseRoomerAutoWalkHandler_ = scheduler.scheduleGlobal(function()
        local memberIdList = table.keys(virtualData.catHouseRoom_.memberMap)
        local roomMemberId = checkint(virtualData._rValue(memberIdList, 1)[1])
        if roomMemberId ~= virtualData.playerData.playerId then
            -- member walk
            gameServer:sendAllClient(NetCmd.HOUSE_MEMBER_WALK, {data = {
                memberId = roomMemberId,
                pointX   = _r(AVATAR_SAFE_SIZE.width),
                pointY   = _r(AVATAR_SAFE_SIZE.height),
            }})
        end
    end, DEBUG_DEFINES.ROOMER_WALK_INTERVAL)
end


local stopHouseRoomerAutoChatFunc = function()
    if virtualData.houseRoomerAutoChatHandler_ then
        scheduler.unscheduleGlobal(virtualData.houseRoomerAutoChatHandler_)
        virtualData.houseRoomerAutoChatHandler_ = nil
    end
end
local startHouseRoomerAutoChatFunc = function()
    if virtualData.houseRoomerAutoChatHandler_ then return end
    virtualData.houseRoomerAutoChatHandler_ = scheduler.scheduleGlobal(function()
        local memberIdList = table.keys(virtualData.catHouseRoom_.memberMap)
        local roomMemberId = checkint(virtualData._rValue(memberIdList, 1)[1])
        local memberData   = virtualData.catHouseRoom_.memberMap[tostring(roomMemberId)]
        if memberData then
            -- member walk
            chatServer:sendAllClient(NetCmd.RequestChatroomGetMessage, {data = {
                sendTime    = os.time(),
                channel     = CHAT_CHANNELS.CHANNEL_HOUSE,
                messageId   = virtualData.generateUuid(),
                name        = memberData.memberName,
                playerId    = memberData.memberId,
                avatar      = memberData.avatar_,
                avatarFrame = memberData.avatarFrame_,
                message     = string.fmt('<desc>%1</desc><messagetype>1</messagetype>', virtualData.createName(_r(20,200))),
            }})
        end
    end, DEBUG_DEFINES.ROOMER_CHAT_INTERVAL)
end


local stopHouseCatsUpdateLogicFunc = function()
    if virtualData.houseCatsUpdateLogicHandler_ then
        scheduler.unscheduleGlobal(virtualData.houseCatsUpdateLogicHandler_)
        virtualData.houseCatsUpdateLogicHandler_ = nil
    end
end
local startHouseCatsUpdateLogicFunc = function()
    if virtualData.houseCatsUpdateLogicHandler_ then return end
    virtualData.houseCatsUpdateLogicHandler_ = scheduler.scheduleGlobal(function()
        virtualData.catModule.updateCatsLogic()
    end, 1)
end


virtualData.catHouse.initRoomData = function()
    if not virtualData.catHouseRoom_ then
        virtualData.catHouseRoom_ = {
            roomId    = 0,
            roomSize  = 0,
            memberMap = {},
        }

        local levelConf = CONF.CAT_HOUSE.LEVEL_INFO:GetValue(virtualData.playerData.houseLevel)
        virtualData.catHouseRoom_.roomSize = checkint(levelConf.guestLimit)
    end
end


virtualData.catHouse.enterMemberRoom = function(roomOwnerId)
    -- update ownerId
    virtualData.catHouseRoom_.roomOwnerId = checkint(roomOwnerId)

    -- clean room members
    virtualData.catHouseRoom_.memberMap = {}

    -- add myself
    virtualData.catHouse.appendRoomMember(virtualData.playerData.playerId)

    -- add friends
    local memberCount = math.min(#virtualData.playerData.friendList, virtualData.catHouseRoom_.roomSize - 1)  -- myself is -1
    for i = 1, memberCount do
        virtualData.catHouse.appendRoomMember()
    end
end


virtualData.catHouse.appendRoomMember = function(memberId)
    local appendMemberId = checkint(memberId)
    local isRandomMember = appendMemberId == 0
    local roomFriendData = nil
    
    local cmdData = {
    }
    
    -- get random friend
    if isRandomMember then
        local repeatCount = 20
        while repeatCount > 0 and appendMemberId == 0 do
            local friendData = virtualData._rValue(virtualData.playerData.friendList, 1)[1]
            if virtualData.catHouseRoom_.memberMap[tostring(friendData.friendId)] == nil then
                appendMemberId = checkint(friendData.friendId)
                roomFriendData = friendData
            end
            repeatCount = repeatCount - 1
        end
    end

    -- append roomer
    if appendMemberId > 0 then
        if virtualData.playerData.playerId == appendMemberId then
            virtualData.catHouseRoom_.memberMap[tostring(appendMemberId)] = {
                memberId     = virtualData.playerData.playerId,    -- 成员id
                memberName   = virtualData.playerData.playerName,  -- 成员名称
                head         = virtualData.catHouse_.head,         -- 成员形象
                bubble       = virtualData.catHouse_.bubble,       -- 成员气泡
                businessCard = virtualData.catHouse_.busiessCard,  -- 成员名片
                avatar_      = virtualData.playerData.avatar,
                avatarFrame_ = virtualData.playerData.avatarFrame,
            }
        else
            virtualData.catHouseRoom_.memberMap[tostring(appendMemberId)] = {
                memberId     = roomFriendData.friendId,                       -- 成员id
                memberName   = roomFriendData.name,                           -- 成员名称
                head         = virtualData.catHouse.createRandomHeadId(),     -- 成员形象
                bubble       = virtualData.catHouse.createRandomBubbleId(),   -- 成员气泡
                businessCard = virtualData.catHouse.createRandomIdentityId(), -- 成员名片
                avatar_      = roomFriendData.avatar,
                avatarFrame_ = roomFriendData.avatarFrame,
            }
        end

        cmdData = clone(virtualData.catHouseRoom_.memberMap[tostring(appendMemberId)])
    end

    return cmdData
end


virtualData.catHouse.removeRoomMember = function(memberId)
    local removeMemberId = checkint(memberId)
    local isRandomMember = removeMemberId == 0
    local roomFriendData = nil

    local cmdData = {
    }

    -- get random friend
    if isRandomMember then
        local repeatCount  = 20
        local memberIdList = table.keys(virtualData.catHouseRoom_.memberMap)
        while repeatCount > 0 and removeMemberId == 0 do
            local memberId = checkint(virtualData._rValue(memberIdList, 1)[1])
            if virtualData.playerData.playerId ~= memberId then
                removeMemberId = checkint(memberId)
            end
            repeatCount = repeatCount - 1
        end
    end
    
    -- remove roomer
    if removeMemberId > 0 then
        roomFriendData   = virtualData.catHouseRoom_.memberMap[tostring(removeMemberId)]
        cmdData.memberId = roomFriendData and roomFriendData.memberId or 0
        virtualData.catHouseRoom_.memberMap[tostring(removeMemberId)] = nil
    end

    return cmdData
end


virtualData.catHouse.getRoomMembers = function(ownerId)
    local cmdData = {
        members = {}
    }
    if virtualData.catHouseRoom_ and virtualData.catHouseRoom_.roomOwnerId == ownerId then
        for index, memberData in pairs(virtualData.catHouseRoom_.memberMap or {}) do
            table.insert(cmdData.members, memberData)
        end
    end
    return cmdData
end


-------------------------------------------------------------------------------
-- cat data
-------------------------------------------------------------------------------

virtualData.catHouse.createCatTriggerEventData = function()
    local triggerEventList = CONF.CAT_HOUSE.CAT_TRIGGER_EVENT:GetIdList()
    local triggerEventId   = virtualData._rValue(triggerEventList, 1)[1]
    local triggerEventConf = CONF.CAT_HOUSE.CAT_TRIGGER_EVENT:GetValue(triggerEventId)
    local triggerPosXInfo  = triggerEventConf.location.x
    local triggerPosYInfo  = triggerEventConf.location.y
    return {
        eventUuid = virtualData.generateUuid(),
        eventId   = triggerEventConf.id,
        location  = {
            x = checkint(triggerPosXInfo[1]) + _r(checkint(triggerPosXInfo[2])),
            y = checkint(triggerPosYInfo[1]) + _r(checkint(triggerPosYInfo[2])),
        }
    }
end


virtualData.catHouse.checkInitCatModule = function()
    if virtualData.catHouse_.initCat == 1 then return end
    -- mark initCat
    virtualData.catHouse_.initCat = 1

    -- init each friendData
    for _, friendData in ipairs(virtualData.playerData.friendList) do
        virtualData['House/friend']({friendId = friendData.friendId})
    end

    -- star cats update
    startHouseCatsUpdateLogicFunc()
end


-------------------------------------------------------------------------------
-- 小屋
-------------------------------------------------------------------------------

-- 猫屋 小屋进入
virtualData['House/home'] = function(args)
    -- init room data
    virtualData.catHouse.initRoomData()

    if not virtualData.catHouse_ then
        virtualData.catHouse_ = {
            head                 = nil, -- 头像
            bubble               = nil, -- 气泡
            busiessCard          = nil, -- 名片
            location             = {},  -- 装扮（key：家具uuid）
            customSuits          = {},  -- 套装（key：套装id，data：部件列表）
            events               = {},  -- 事件列表
            cats                 = {},  -- 展示猫咪 列表
            initCat              = 0,   -- 猫咪功能 是否初始化
            catWarehouseCapacity = 0,   -- 猫咪仓库 容量
            catTriggerEvent      = {},  -- 猫咪触发 事件
            friendCats           = {},  -- 好友猫咪
        }

        if DEBUG_DEFINES.HAS_DEFAULT_HEAD then
            virtualData.catHouse_.head = virtualData.catHouse.createRandomHeadId()
        end
        if DEBUG_DEFINES.HAS_DEFAULT_BUBBLE then
            virtualData.catHouse_.bubble = virtualData.catHouse.createRandomBubbleId()
        end
        if DEBUG_DEFINES.HAS_DEFAULT_BUSIESS then
            virtualData.catHouse_.busiessCard = virtualData.catHouse.createRandomIdentityId()
        end
        
        -- location data
        for _, avatarConf in pairs(CONF.CAT_HOUSE.AVATAR_INIT:GetAll()) do
            local avatarData = virtualData.catHouse.appendAvatar(avatarConf.goodsId)
            virtualData.catHouse.movedAvatar(avatarConf.goodsId, avatarData.goodsUuid, checkint(avatarConf.x), checkint(avatarConf.y))
        end
        local damageNum = _r(1,5)
        for _, avatarConf in pairs(CONF.CAT_HOUSE.AVATAR_INFO:GetAll()) do
            if checkint(avatarConf.damage) == 1 and damageNum > 0 then
                local avatarData = virtualData.catHouse.appendAvatar(avatarConf.id)
                local avatarPos  = virtualData.catHouse.createAvatarRandomPos(avatarConf.id)
                virtualData.catHouse.movedAvatar(avatarConf.id, avatarData.goodsUuid, avatarPos.x, avatarPos.y)
                damageNum = damageNum - 1
            end
        end
        
        -- events data
        if DEBUG_DEFINES.HAS_DEFAULT_EVENTS then
            local eventIdNum  = CONF.CAT_HOUSE.EVENT_TYPE:GetLength()
            local eventIdList = CONF.CAT_HOUSE.EVENT_TYPE:GetIdListUp()
            local friendList  = virtualData._rValue(virtualData.playerData.friendList, CatHouseUtils.HOUSE_PARAM_FUNCS.EVENT_VISIT_MAX())
            for count = 1, CatHouseUtils.HOUSE_PARAM_FUNCS.EVENT_VISIT_MAX() do
                local typeIndex  = (count - 1) % eventIdNum + 1
                local eventId    = checkint(eventIdList[typeIndex])
                local eventConf  = CONF.CAT_HOUSE.EVENT_TYPE:GetValue(eventId)
                local friendData = friendList[count]
                if friendData then
                    table.insert(virtualData.catHouse_.events, {
                        eventId   = virtualData.generateUuid(),    -- 事件id
                        eventType = checkint(eventConf.id),        -- 事件类型
                        refId     = checkint(friendData.friendId), -- 引用id（邀请任务就是好友id）
                    })
                end
            end
        end

        -- custom suit
        if DEBUG_DEFINES.HAS_DEFAULT_SUIT then
            for suitId = 1, CatHouseUtils.HOUSE_PARAM_FUNCS.AVATAR_SUIT_MAX() do
                local locationMap = virtualData.catHouse.createAvatarLocationMap(virtualData.playerData.houseLevel)
                virtualData.catHouse_.customSuits[tostring(suitId)] = locationMap
            end
        end

        -- init cats
        if DEBUG_DEFINES.HAS_INIT_CAT_MODULE then
            virtualData.catHouse.checkInitCatModule()
            
            -- init catModule
            virtualData['HouseCat/home']()
            
            -- place cats
            local levelConf = CONF.CAT_HOUSE.LEVEL_INFO:GetValue(virtualData.playerData.houseLevel)
            local placeCats = virtualData._rValue(virtualData.catModule_.cats, checkint(levelConf.catLimit))
            virtualData.catHouse_.cats = table.valuesAt(placeCats, 'playerCatId')
            
            -- init catWarehouseCapacity
            virtualData.catHouse_.catWarehouseCapacity = table.nums(virtualData.catHouse_.cats)

            -- trigger event
            for triggerEventIndex = 1, _r(4,10) do
                virtualData.catHouse_.catTriggerEvent[triggerEventIndex] = virtualData.catHouse.createCatTriggerEventData()
            end

            -- friend cats
            local friendIdList = virtualData._rValue(virtualData.playerData.friendList, 2)
            for _, friendData in ipairs(friendIdList) do
                -- get friendData
                local friendHouseData = virtualData.friendCatHouse_[tostring(friendData.friendId)]
                local friendCatsData  = virtualData._rValue(friendHouseData.cats, _r(1,2))
                for _, friendCatData in ipairs(friendCatsData) do
                    table.insert(virtualData.catHouse_.friendCats, {
                        friendId      = friendData.friendId,       -- 好友id
                        friendCatId   = friendCatData.playerCatId, -- 唯一id
                        catId         = friendCatData.catId,       -- 种族id
                        name          = friendCatData.name,        -- 名字
                        gene          = friendCatData.gene,        -- 基因id列表
                        generation    = friendCatData.generation,  -- 代数
                        age           = friendCatData.age,         -- 年龄
                        sex           = friendCatData.sex,         -- 性别
                        attr          = friendCatData.attr,        -- 属性map
                        ability       = friendCatData.ability,     -- 能力map
                        rebirth       = friendCatData.rebirth,     -- 是否回归
                        leftPlayTimes = _r(3),                     -- 剩余喂食次数
                        leftFeedTimes = _r(3),                     -- 剩余喂食次数
                    })
                end
            end

        end
    end

    -- enter self room
    virtualData.catHouse.enterMemberRoom(virtualData.playerData.playerId)

    -- star roomer change
    startRoomerAutoChangeFunc()
    -- star roomer walk
    startHouseRoomerAutoWalkFunc()
    -- star roomer chat
    startHouseRoomerAutoChatFunc()

    return t2t(virtualData.catHouse_)
end


-- 猫屋 小屋离开
virtualData['House/quitHome'] = function(args)
    stopRoomerAutoChangeFunc()
    stopHouseRoomerAutoWalkFunc()
    stopHouseRoomerAutoChatFunc()
    stopHouseCatsUpdateLogicFunc()
    -- virtualData.catHouse_ = nil
    return t2t({})
end


-- 猫屋 小屋升级
virtualData['House/levelUp'] = function(args)
    virtualData.playerData.houseLevel = checkint(virtualData.playerData.houseLevel) + 1

    local levelConf = CONF.CAT_HOUSE.LEVEL_INFO:GetValue(virtualData.playerData.houseLevel)
    virtualData.catHouseRoom_.roomSize = checkint(levelConf.guestLimit)
    
    local data = {
        newLevel = virtualData.playerData.houseLevel
    }
    return t2t(data)
end


-- 猫屋 修理家具
virtualData['House/repair'] = function(args)
    local avatarData   = virtualData.catHouse_.location[tostring(args.goodsUuid)]
    avatarData.damaged = 0
    return t2t({})
end


-------------------------------------------------------------------------------
-- 形象
-------------------------------------------------------------------------------

-- 猫屋 更改头像
virtualData['House/changeHead'] = function(args)
    virtualData.catHouse_.head = checkint(args.cardSkinId)
    return t2t({})
end


-- 猫屋 更改气泡
virtualData['House/changeBubble'] = function(args)
    virtualData.catHouse_.bubble = checkint(args.goodsId)

    local selfRoomData = virtualData.catHouseRoom_.memberMap[tostring(virtualData.playerData.playerId)]
    if selfRoomData then
        selfRoomData.bubble = virtualData.catHouse_.bubble
    end
    return t2t({})
end


-- 猫屋 更改身份
virtualData['House/changeBusinessCard'] = function(args)
    virtualData.catHouse_.busiessCard = checkint(args.goodsId)

    local selfRoomData = virtualData.catHouseRoom_.memberMap[tostring(virtualData.playerData.playerId)]
    if selfRoomData then
        selfRoomData.businessCard = virtualData.catHouse_.businessCard
    end
    return t2t({})
end


-------------------------------------------------------------------------------
-- 奖杯
-------------------------------------------------------------------------------

-- 猫屋 奖杯
virtualData['House/trophy'] = function(args)
    local data = {
        trophy = {}
    }
    -- trophy data
    for _, trophyConf in pairs(CONF.CAT_HOUSE.TROPHY_INFO:GetAll()) do
        if _r(100) > 50 then
            local percent = math.min(_r(200), 100) / 100
            table.insert(data.trophy, {
                trophyId      = checkint(trophyConf.id),                                        -- 奖杯id
                progress      = checkint(checkint(trophyConf.targetNum) * percent),             -- 进度
                hasDrawn      = _r(0,1),                                                        -- 0:未领取 1:已领取
                drawTimestamp = os.time() - virtualData.createSecond('d:100:?,h:24:?,s:60:?'),  -- 获得时间戳
            })
        end
    end
    return t2t(data)
end


-- 猫屋 领取奖杯
virtualData['House/drawTrophy'] = function(args)
    return t2t({})
end


-------------------------------------------------------------------------------
-- 购买
-------------------------------------------------------------------------------

-- 猫屋 购买家具
virtualData['House/buyAvatar'] = function(args)
    virtualData.playerData.backpack[tostring(args.goodsId)] = checkint(virtualData.playerData.backpack[tostring(args.goodsId)]) + checkint(args.num)
    local data = {
        gold    = virtualData.playerData.gold,
        diamond = virtualData.playerData.diamond,
    }
    return t2t(data)
end


-- 猫屋 购买道具
virtualData['House/mallBuy'] = function(args)
    virtualData.playerData.backpack[tostring(args.gooproductIddsId)] = checkint(virtualData.playerData.backpack[tostring(args.productId)]) + 1
    local data = {
        gold    = virtualData.playerData.gold,
        diamond = virtualData.playerData.diamond,
    }
    return t2t(data)
end


-------------------------------------------------------------------------------
-- 套装
-------------------------------------------------------------------------------

-- 猫屋 保存套装
virtualData['House/saveCustomSuit'] = function(args)
    virtualData.catHouse_.customSuits[tostring(args.suidId)] = clone(virtualData.catHouse_.location)
    return t2t({})
end


-- 猫屋 应用套装
virtualData['House/applyCustomSuit'] = function(args)
    virtualData.catHouse_.location = clone(virtualData.catHouse_.customSuits[tostring(args.suidId)])
    return t2t({})
end


-------------------------------------------------------------------------------
-- 好友
-------------------------------------------------------------------------------

-- 猫屋 好友小屋
virtualData['House/friend'] = function(args)
    virtualData.friendCatHouse_ = virtualData.friendCatHouse_ or {}
    
    local friendHouseData = virtualData.friendCatHouse_[tostring(args.friendId)]
    if not friendHouseData then
        friendHouseData = {
            location        = {}, -- 装扮（key：家具uuid）
            trophy          = {}, -- 奖杯列表
            cats            = {}, -- 猫咪
            catTriggerEvent = {}, -- 触发事件
        }
        
        -- location data
        local houseLevel = 0
        for i, friendData in ipairs(virtualData.playerData.friendList) do
            if friendData.friendId == checkint(args.friendId) then
                houseLevel = checkint(friendData.houseLevel)
                break
            end
        end
        friendHouseData.location = virtualData.catHouse.createAvatarLocationMap(houseLevel)

        -- trophy data
        for _, trophyConf in pairs(CONF.CAT_HOUSE.TROPHY_INFO:GetAll()) do
            if _r(100) > 50 then
                local percent = math.min(_r(200), 100) / 100
                table.insert(friendHouseData.trophy, {
                    trophyId      = checkint(trophyConf.id),                                        -- 奖杯id
                    progress      = checkint(checkint(trophyConf.targetNum) * percent),             -- 进度
                    hasDrawn      = _r(0,1),                                                        -- 0:未领取 1:已领取
                    drawTimestamp = os.time() - virtualData.createSecond('d:100:?,h:24:?,s:60:?'),  -- 获得时间
                })
            end
        end

        -- place cats
        for placeCatIndex = 1, _r(4,10) do
            local friendCatsData = virtualData.catModule.createCatData({createType = 1, friendCat = true, emptyState = true})
            friendHouseData.cats[placeCatIndex] = {
                playerCatId   = friendCatsData.playerCatId, -- 唯一id
                catId         = friendCatsData.catId,       -- 种族id
                name          = friendCatsData.name,        -- 名字
                gene          = friendCatsData.gene,        -- 基因id列表
                generation    = friendCatsData.generation,  -- 代数
                age           = friendCatsData.age,         -- 年龄
                sex           = friendCatsData.sex,         -- 性别
                ability       = friendCatsData.ability,     -- 能力map
                attr          = friendCatsData.attr,        -- 属性map
                rebirth       = friendCatsData.rebirth,     -- 是否回归
                alive         = _r(0,1),                    -- 是否活着
            }
        end

        -- trigger event
        for triggerEventIndex = 1, _r(4,10) do
            friendHouseData.catTriggerEvent[triggerEventIndex] = virtualData.catHouse.createCatTriggerEventData()
        end

        virtualData.friendCatHouse_[tostring(args.friendId)] = friendHouseData
    end

    -- enter friend room
    virtualData.catHouse.enterMemberRoom(args.friendId)

    local data = friendHouseData
    return t2t(data)
end


-- 猫屋 好友邀请
virtualData['House/invite'] = function(args)
    return t2t({})
end


-- 猫屋 踢出小屋
virtualData['House/kickOut'] = function(args)
    virtualData.catHouse.removeRoomMember(args.memberId)
    return t2t({})
end


-------------------------------------------------------------------------------
-- 事件
-------------------------------------------------------------------------------

-- 猫屋 完成事件
virtualData['House/finishEvent'] = function(args)
    for eventIndex = #virtualData.catHouse_.events, 1, -1 do
        local eventData = virtualData.catHouse_.events[eventIndex]
        if eventData.eventId == args.eventId then
            table.remove(virtualData.catHouse_.events, eventIndex)
            break
        end
    end
    return t2t({})
end


-------------------------------------------------------------------------------
-- 猫咪
-------------------------------------------------------------------------------

-- 猫屋 放置猫咪
virtualData['House/placeCats'] = function(args)
    virtualData.catHouse_.cats = string.split2(args.cats, ',')
    return t2t({})
end


-- 猫屋 清理触发
virtualData['House/clean'] = function(args)
    local cleanEventMap = {}
    for _, eventUuid in ipairs(string.split2(args.eventUuids)) do
        cleanEventMap[tostring(eventUuid)] = true
    end
    for eventIndex = #virtualData.catHouse_.catTriggerEvent, 1, -1 do
        local eventData = virtualData.catHouse_.catTriggerEvent[eventIndex]
        if cleanEventMap[tostring(eventData.eventUuid)] then
            table.remove(virtualData.catHouse_.catTriggerEvent, eventIndex)
        end
    end
    return t2t({})
end
