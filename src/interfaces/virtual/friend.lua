--[[
 * author : kaishiqi
 * descpt : 关于 好友数据 的本地模拟
]]
virtualData = virtualData or {}

local _r  = virtualData._r
local j2t = virtualData.j2t
local t2t = virtualData.t2t


-- 餐厅好友
virtualData['friend/friendList'] = function(args)
    local data = {
        friendList = virtualData.playerData.friendList
    }
    return t2t(data)
end


-- 好友列表
virtualData['friend/home'] = function(args)
    local data = {
        friendList         = virtualData.playerData.friendList,
        enemyList          = {},  -- 捣乱者列表
        assistanceList     = {},  -- 捐助列表
        assistanceDoneList = {},  -- 协助列表（只显示已协助和未完成的）
        assistanceLimit    = 0,
        assistanceNum      = 0,
        -- restaurantCleaningLeftTimes      = _r(5),                  -- 餐厅帮好友打扫虫子剩余次数
        -- restaurantEventHelpLeftTimes     = _r(5),                  -- 餐厅帮好友打霸王餐剩余次数
        -- restaurantEventNeedHelpLeftTimes = _r(5),                  -- 餐厅需要好友打霸王餐剩余次数
    }
    return t2t(data)
end


-- 玩家信息
virtualData['friend/playerInfo'] = function(args)
    local playerId   = checkint(args.playerIdList)  -- 玩家ID，逗号分隔（基本都是查询单个玩家）
    local playerData = nil

    if virtualData.union_ and virtualData.union_.member then
        for i, unionMemberData in ipairs(virtualData.union_.member) do
            if checkint(unionMemberData.playerId) == playerId then
                local loginTime  = os.time() - virtualData.createSecond('d:100:?,h:24:?,s:60:?')
                playerData = {
                    friendId        = unionMemberData.playerId,
                    name            = unionMemberData.playerName,
                    level           = unionMemberData.playerLevel,
                    avatar          = unionMemberData.playerAvatar,
                    avatarFrame     = unionMemberData.playerAvatarFrame,
                    playerSign      = '',
                    isOnline        = _r(0,1),
                    lastLoginTime   = virtualData.createFormatTime(loginTime),
                    restaurantLevel = _r(20),
                }
                break
            end
        end
    end

    if not playerData then
        for _, friendData in ipairs(virtualData.playerData.friendList) do
            if checkint(friendData.friendId) == playerId then
                playerData = {
                    friendId        = friendData.playerId,
                    name            = friendData.name,
                    level           = friendData.level,
                    avatar          = friendData.avatar,
                    avatarFrame     = friendData.avatarFrame,
                    playerSign      = friendData.playerSign,
                    isOnline        = friendData.isOnline,
                    lastLoginTime   = friendData.lastLoginTime,
                    restaurantLevel = friendData.restaurantLevel,
                }
                break
            end
        end
    end

    if not playerData then
        local loginTime  = os.time() - virtualData.createSecond('d:100:?,h:24:?,s:60:?')
        playerData = {
            friendId        = virtualData.createPlayerId(),
            name            = virtualData.createName(_r(8, 16)),
            level           = _r(100),
            avatar          = virtualData.createAvatarId(),
            avatarFrame     = virtualData.createAvatarFrameId(),
            playerSign      = virtualData.createName(_r(0, 100)),
            isOnline        = _r(0,1),
            lastLoginTime   = virtualData.createFormatTime(loginTime),
            restaurantLevel = _r(20),
        }
    end

    local data = {
        playerList = {}
    }
    if playerData then
        table.insert(data.playerList, playerData)
    end
    return t2t(data)
end


-- 好友切磋
virtualData['friend/studyTeam'] = function(args)
    local data = {}
    if args.friendId == virtualData.playerData.playerId then
        data.name        = virtualData.playerData.playerName
        data.level       = virtualData.playerData.level
        data.avatar      = virtualData.playerData.avatar
        data.avatarFrame = virtualData.playerData.avatarFrame
        data.team        = {}

        local cardUuidList = table.keys(virtualData.playerData.cards)
        for index, value in ipairs(virtualData._rValue(cardUuidList, 5)) do
            table.insert(data.team, {id = value})
        end

    else
        data.name        = virtualData.createName(_r(8, 16))
        data.level       = _r(100)
        data.avatar      = virtualData.createAvatarId()
        data.avatarFrame = virtualData.createAvatarFrameId()
        data.team        = {}
        for i = 1, 5 do
            table.insert(data.team, virtualData.createCardData(nil, args.friendId))
        end
    end
    return t2t(data)
end


-- 好友切磋列表
virtualData['friend/studyList'] = function(args)
    local data = {
        friendList = {},
        pageNum    = 2,
    }
    for i = 1, 3 do
        local friendData = {
            friendId    = virtualData.createPlayerId(),
            name        = virtualData.createName(_r(8, 16)),
            level       = _r(100),
            avatar      = virtualData.createAvatarId(),
            avatarFrame = virtualData.createAvatarFrameId(),
            team        = {}
        }
        for i = 1, 5 do
            table.insert(friendData.team, virtualData.createCardData(nil, friendData.friendId))
        end
        table.insert(data.friendList, friendData)
    end
    return t2t(data)
end


-- 好友切磋 战斗进入
virtualData['friend/studyQuestAt'] = function(args)
    local data = {
        maxSkillTimes      = 0,
        maxCritDamageTimes = 0,
    }
    return t2t(data)
end
-- 好友切磋 战斗结算
virtualData['friend/studyQuestGrade'] = function(args)
    local data = {
        hp                = virtualData.playerData.hp,
        gold              = virtualData.playerData.gold,
        mainExp           = virtualData.playerData.mainExp,
        reward            = {},
        cardExp           = {},
        favorabilityCards = {},
    }
    return t2t(data)
end
