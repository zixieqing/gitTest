--[[
 * author : kaishiqi
 * descpt : 关于 卡牌数据 的本地模拟
]]
virtualData = virtualData or {}

local _r  = virtualData._r
local j2t = virtualData.j2t
local t2t = virtualData.t2t


-- 保存卡牌队伍
virtualData['card/saveTeam'] = function(args)
    local cardList = string.split(args.cards, ',')
    local teamData = {teamId = checkint(args.teamId), cards = {}}
    virtualData.playerData.allTeams[args.teamId] = teamData

    for i=1, 5 do
        local cardUuid = checkint(cardList[i])
        teamData.cards[i] = cardUuid > 0 and {id = tostring(cardUuid)} or {}
    end
    if #teamData.cards > 0 then
        teamData.captainId = teamData.cards[1].id
    end

    local data = {
        teamId    = teamData.teamId,
        cards     = teamData.cards,
        captainId = teamData.captainId,
    }
    return t2t(data)
end


-- 卡佩升级
virtualData['card/cardLevelUp'] = function(args)
    local data = {
        level    = 0,
        exp      = 0,
        goodsId  = args.goodsId,
        goodsNum = 0,
    }
    local cardUuid = checkint(args.playerCardId)
    local cardConf = virtualData.getConf('goods', 'consumeProp', data.goodsId)
    for uuid, cardData in pairs(virtualData.playerData.cards) do
        if cardUuid == checkint(uuid) then
            local cardConf = virtualData.getConf('cards', 'card', cardData.cardId)
            data.level     = cardData.level
            data.exp       = cardData.exp + checkint(cardConf.effectNum)
            break
        end
    end
    data.goodsNum = virtualData.playerData.backpack[tostring(data.goodsId)] - 1
    virtualData.playerData.backpack[tostring(data.goodsId)] = data.goodsNum
    return t2t(data)
end
-- 卡牌一键升级
virtualData['card/cardUpgradeMaxKey'] = function(args)
    local data = {
        level         = 0,
        exp           = 0,
        consumesGoods = {}
    }

    local cardUuid = checkint(args.playerCardId)
    for uuid, cardData in pairs(virtualData.playerData.cards) do
        if cardUuid == checkint(uuid) then
            local cardConf = virtualData.getConf('cards', 'card', cardData.cardId)
            cardData.level = math.max(cardData.level, cardConf.maxLevel)
            data.level     = cardConf.maxLevel

            cardData.exp = 9999999
            data.exp     = cardData.exp
            break
        end
    end

    return t2t(data)
end
-- 卡牌升星突破
virtualData['card/cardBreakUp'] = function(args)
    local data = {
        breakLevel = 0,
        gold = virtualData.playerData.gold,
    }
    local cardUuid = checkint(args.playerCardId)
    for uuid, cardData in pairs(virtualData.playerData.cards) do
        if cardUuid == checkint(uuid) then
            local cardConf = virtualData.getConf('cards', 'card', cardData.cardId)
            cardData.breakLevel = cardData.breakLevel + 1
            data.level          = cardData.breakLevel
            break
        end
    end
    return t2t(data)
end


-- 设置看板娘
virtualData['card/defaultCard'] = function(args)
    virtualData.playerData.defaultCardId = args.playerCardId
    return t2t({})
end


-- 卡牌合成
virtualData['card/cardCompose'] = function(args)
    local cardData = virtualData.createCardData(args.cardId, virtualData.playerData.playerId)
    virtualData.playerData.cards[tostring(cardData.id)] = cardData

    local data = {
        playerCardId = cardData.id
    }
    return t2t(data)
end


-- 卡牌默认皮肤
virtualData['card/defaultSkin'] = function(args)
    local cardId   = args.playerCardId
    local skinId   = args.skinId
    local cardData = virtualData.playerData.cards[tostring(cardId)]
    if cardData then
        cardData.defaultSkinId = skinId
    end
    return t2t({})
end


-- 解锁编队
virtualData['card/unlockTeam'] = function(args)
    local data = {
        newTeam = {diamond={}, level={}}
    }
    return t2t(data)
end


-------------------------------------------------------------------------------
-- 预设编队
-------------------------------------------------------------------------------

-- 获取自定义编队总信息
local DEBUG_DEFINE = {
    IS_FULL_TEAM_CUSTOM = true,
}
virtualData['card/getTeamCustomList'] = function()
    if virtualData.presetTeam_ == nil then
        virtualData.presetTeam_ = {}

        local cardUuidList = table.keys(virtualData.playerData.cards)

        local createTeamCardDataFunc = function(presetDefine)
            local teamsData = {}
            for teamIndex = 1, presetDefine.maxTeamCount do
                if DEBUG_DEFINE.IS_FULL_TEAM_CUSTOM or _r(100) > 25 then
                    local cardsData = {}
                    local cardCount = DEBUG_DEFINE.IS_FULL_TEAM_CUSTOM and presetDefine.cardCount or _r(presetDefine.minCardCount/presetDefine.maxTeamCount, presetDefine.cardCount)
                    for cardIndex = 1, cardCount do
                        if (DEBUG_DEFINE.IS_FULL_TEAM_CUSTOM or _r(100) > 50) and #cardUuidList > 0 then
                            local cardUuid = table.remove(cardUuidList, _r(#cardUuidList))
                            table.insert(cardsData, cardUuid)
                        end
                    end
                    table.insert(teamsData, cardsData)
                end
            end
            return teamsData
        end

        for defineType, presetDefine in pairs(PRESET_TEAM_DEFINES or {}) do
            for teamIndex = 1, checkint(presetDefine.saveCount) do
                if (DEBUG_DEFINE.IS_FULL_TEAM_CUSTOM or _r(100) > 25) and #cardUuidList > 0 then
                    table.insert(virtualData.presetTeam_, {
                        teamId    = virtualData.generateUuid(),                             -- 编队id
                        cellIndex = teamIndex,                                              -- 编队位置
                        cardIds   = createTeamCardDataFunc(presetDefine),                   -- 站队卡牌id
                        valid     = _r(0,1),                                                -- 是否可用（1：可用；0：不可用）
                        name      = _r(100) > 95 and virtualData.createName(_r(16)) or nil, -- 队伍名字
                        type      = presetDefine.serverType,                                -- 队伍类型（1：世界boss；2：爬塔；3：天城演武）
                        lock      = _r(100) > 75 and 1 or 0,                                -- 是否锁住（0：未锁住； 1：锁住）
                    })
                end
            end
        end
    end

    local data = {
        info = virtualData.presetTeam_
    }
    return t2t(data)
end


-- 设置自定义编队
virtualData['card/setTeamCustom'] = function(args)
    local data = {
        teamId = nil
    }

    local teamsData = {}
    for teamIndex, teamData in ipairs(json.decode(args.cardJson)) do
        local cardsData = {}
        for cardIndex, cardData in ipairs(teamData) do
            table.insert(cardsData, cardData.id)
        end
        table.insert(teamsData, cardsData)
    end

    local presetTeamData = nil
    if args.teamId == nil then
        presetTeamData = { teamId = virtualData.generateUuid() }
        table.insert(virtualData.presetTeam_, presetTeamData)
    else
        for _, presetData in ipairs(virtualData.presetTeam_) do
            if checkint(presetData.teamId) == checkint(args.teamId) then
                presetTeamData = presetData
                break
            end
        end
    end
    
    if presetTeamData then
        presetTeamData.cardIds   = teamsData      -- 站队卡牌id
        presetTeamData.cellIndex = args.cellIndex -- 编队位置
        presetTeamData.name      = args.name      -- 队伍名字
        presetTeamData.type      = args.type      -- 队伍类型（1：世界boss；2：爬塔；3：天城演武）
        presetTeamData.valid     = 1              -- 是否可用（1：可用；0：不可用）
        presetTeamData.lock      = 0              -- 是否锁住（0：未锁住； 1：锁住）
    end
    
    return t2t(data)
end


--  (获取自定义编队某个信息)
virtualData['card/getTeamCustomDetail'] = function(args)
    local data = {
        info  = {},
        valid = 1,--_r(0,1),  --  1：可用；0：不可用
    }

    for _, presetData in ipairs(virtualData.presetTeam_) do
        if checkint(presetData.teamId) == checkint(args.teamId) then
            local teamsInfoData = {}
            for teamIndex, cardsData in ipairs(presetData.cardIds) do
                teamsInfoData[teamIndex] = {}
                for cardIndex, cardUuid in ipairs(cardsData) do
                    local cardData = virtualData.playerData.cards[cardUuid]
                    teamsInfoData[teamIndex][cardIndex] = {
                        id             = cardData.id,
                        cardId         = cardData.cardId,
                        playerId       = cardData.playerId,
                        artifactTalent = {},
                        pets           = {},
                    }
                end
            end
            data.info = teamsInfoData
            break
        end
    end

    return t2t(data)
end
