--[[
 * author : kaishiqi
 * descpt : 关于 kof竞技场 的本地模拟
]]
virtualData = virtualData or {}

local _r  = virtualData._r
local j2t = virtualData.j2t
local t2t = virtualData.t2t

local DEBUG_DEFINE = {
    STATUS               = 3, --（0-未开始, 1-报名中, 2-备战中, 3-进行中）
    IS_USE_PRESET_ATTACK = true,
    IS_USE_PRESET_DEFINE = true,
}

-- Activity/kofArena 的转义
virtualData['kofArena/_activity_'] = function(args)
    if not virtualData.kofArena_ then
        virtualData.kofArena_ = {
            section      = 0,  -- 当前阶段（0-未开始, 1-报名中, 2-备战中, 3-进行中）
            isApply      = 0,  -- 是否已报名（1-是, 2-否）
            segment      = 0,  -- 等级区间id
            leftSeconds  = 0,  -- 当前阶段剩余秒数
            defendCards  = {}, -- 防守阵容（key为编队id，value为list 卡牌id）
            teamCustomId = 0, -- 防守预设编队id
        }

        local cardUuidList = table.keys(virtualData.playerData.cards)
        local cardTotalNum = table.nums(virtualData.playerData.cards)
        for teamIndex = 1, 3 do
            local teamCards = {}
            for cardIndex = 1, 5 do
                table.insert(teamCards, cardUuidList[_r(cardTotalNum)])
            end
            virtualData.kofArena_.defendCards[tostring(teamIndex)] = teamCards
        end

        -- use teamCustom
        if DEBUG_DEFINE.IS_USE_PRESET_ATTACK then
            local teamCustomList = virtualData['card/getTeamCustomList']().data.info
            for _, teamCustomData in ipairs(teamCustomList) do
                if teamCustomData.type == 3 and teamCustomData.valid == 1 then  -- 3：天城演武

                    local cardCount = 0
                    local teamCards = {}
                    for teamIndex, teamData in ipairs(teamCustomData.cardIds) do
                        teamCards[tostring(teamIndex)] = teamCards[tostring(teamIndex)] or {}
                        for cardIndex, cardUuid in ipairs(teamData) do
                            if checkint(cardUuid) > 0 then
                                table.insert(teamCards[tostring(teamIndex)], cardUuid)
                                cardCount = cardCount + 1
                            end
                        end
                    end

                    if cardCount > 0 then
                        virtualData.kofArena_.defendCards  = teamCards
                        virtualData.kofArena_.teamCustomId = teamCustomData.teamId
                        break
                    end
                end
            end
        end
    end

    local segmentConfs = virtualData.getConf('kofArena', 'levelSegment')
    virtualData.kofArena_.segment     = _r(table.nums(segmentConfs))
    virtualData.kofArena_.section     = DEBUG_DEFINE.STATUS == -1 and _r(0,3) or DEBUG_DEFINE.STATUS
    virtualData.kofArena_.isApply     = virtualData.kofArena_.section > 1 and 1 or 0
    virtualData.kofArena_.leftSeconds = _r(9999)
    return t2t(virtualData.kofArena_)
end


-- 竞技场首页
virtualData['kofArena/home'] = function(args)
    if virtualData.kofArena_.teamInfo == nil then
        virtualData['kofArena/setAttackCards']()
    end

    if virtualData.kofArena_.enemyList == nil then
        virtualData['kofArena/refreshEnemy']()
    end

    local data = {
        leftSeconds      = virtualData.kofArena_.leftSeconds, -- 剩余时间
        leftRefreshTimes = 3,                                 -- 剩余刷新次数
        maxRefreshTimes  = 5,                                 -- 最大刷新次数
        rank             = _r(99),                            -- 当前排行
        winTimes         = _r(9),                             -- 进攻胜场
        swordPoint       = _r(3),                             -- 进攻生命值（3 - swordPoint = 失败次数）
        shieldPoint      = _r(9999),                          -- 防守生命值
        maxShieldPoint   = _r(9999),                          -- 最大防守生命值
        teamInfo         = virtualData.kofArena_.teamInfo,    -- 玩家出战阵容, key为编队id
        enemyList        = virtualData.kofArena_.enemyList,   -- 随机对手
        teamCustomId     = 0,                                 -- 预设编队id
    }

    if DEBUG_DEFINE.IS_USE_PRESET_DEFINE then
        local teamCustomList = virtualData['card/getTeamCustomList']().data.info
            for _, teamCustomData in ipairs(teamCustomList) do
                if teamCustomData.type == 3 and teamCustomData.valid == 1 and teamCustomData.teamId ~= virtualData.kofArena_.teamCustomId then  -- 3：天城演武

                    local cardCount = 0
                    local teamCards = {}
                    for teamIndex, teamData in ipairs(teamCustomData.cardIds) do
                        teamCards[tostring(teamIndex)] = teamCards[tostring(teamIndex)] or {}
                        for cardIndex, cardUuid in ipairs(teamData) do
                            if checkint(cardUuid) > 0 then
                                table.insert(teamCards[tostring(teamIndex)], cardUuid)
                                cardCount = cardCount + 1
                            end
                        end
                    end

                    if cardCount > 0 then
                        virtualData.kofArena_.teamInfo.cards = teamCards
                        data.teamCustomId = teamCustomData.teamId
                        break
                    end
                end
            end
    end
    return t2t(data)
end


-- 竞技场报名
virtualData['kofArena/signUp'] = function(args)
    virtualData.kofArena_.defendCards[tostring(teamIndex)] = json.decode(args.cards)
    virtualData.kofArena_.teamCustomId = args.teamCustomId
    local data = {}
    return t2t(data)
end


-- 刷新对手
virtualData['kofArena/refreshEnemy'] = function(args)
    local data = {
        leftRefreshTimes = _r(1,5), -- 剩余刷新次数
        enemyList        = {},      -- 随机对手
    }

    for i = 1, 4 do
        local playerId    = virtualData.createPlayerId()
        local playerCards = {}
        for teamIndex = 1, 3 do
            playerCards[tostring(teamIndex)] = {cards = {}}
            for cardIndex = 1, 5 do
                table.insert(playerCards[tostring(teamIndex)].cards, virtualData.createCardData(nil, playerId))
            end
        end
        table.insert(data.enemyList, {
            playerId          = playerId,                          -- 玩家id
            playerName        = virtualData.createName(_r(8, 16)), -- 玩家名字
            playerLevel       = _r(100),                           -- 玩家等级
            playerAvatar      = virtualData.createAvatarId(),      -- 玩家头像
            playerAvatarFrame = virtualData.createAvatarFrameId(), -- 玩家头像框
            playerRank        = _r(999),                           -- 玩家排名
            playerCards       = playerCards,                       -- 玩家防守阵容，key为编队id
            skill             = '',                                -- 天赋技能, 逗号分隔
        })
    end

    virtualData.kofArena_.enemyList = data.enemyList
    return t2t(data)
end


-- 设置进攻阵容
virtualData['kofArena/setAttackCards'] = function(args)
    local data = {
        cards = {}
    }

    if args and args.cards then
        for teamIndex, teamData in pairs(json.decode(args.cards)) do
            data.cards[tostring(teamIndex)] = string.split2(teamData, ',')
        end

    else
        local cardUuidList = table.keys(virtualData.playerData.cards)
        local cardTotalNum = table.nums(virtualData.playerData.cards)
        for teamIndex = 1, 3 do
            local teamCards = {}
            for cardIndex = 1, 5 do
                table.insert(teamCards, cardUuidList[_r(cardTotalNum)])
            end
            data.cards[tostring(teamIndex)] = teamCards
        end
    end
    
    virtualData.kofArena_.teamInfo = data
    return t2t(data)
end


-- 战报
virtualData['kofArena/arenaRecord'] = function(args)
    local data = {
        totalTimes = _r(99), -- 当前赛季总场次
        winTimes   = _r(99), -- 当前赛季总胜场
        records    = {},     -- 战斗记录
    }
    for i = 1, 10 do
        local enemyData = {
            playerId    = virtualData.createPlayerId(),      -- 玩家id
            name        = virtualData.createName(_r(8, 16)), -- 玩家名字
            level       = _r(100),                           -- 玩家等级
            avatar      = virtualData.createAvatarId(),      -- 玩家头像
            avatarFrame = virtualData.createAvatarFrameId(), -- 玩家头像框
            teamInfo    = {},
        }
        for teamIndex = 1, 3 do
            enemyData.teamInfo[tostring(teamIndex)] = {cards = {}, battlePoint = _r(99999)}
            for cardIndex = 1, 5 do
                table.insert(enemyData.teamInfo[tostring(teamIndex)].cards, virtualData.createCardData(nil, enemyData.playerId))
            end
        end

        local createTime = os.time() - virtualData.createSecond('d:100:?,h:24:?,s:60:?')
        table.insert(data.records, {
            rank       = _r(99),                                   -- 当场战斗结束后的排名
            type       = _r(1,2),                                  -- 战斗类型,   1-攻击, 2-防御
            isPassed   = _r(0,1),                                  -- 战斗结果,   0-失败, 1-胜利
            opponent   = enemyData,                                -- 对手卡牌阵容
            createTime = virtualData.createFormatTime(createTime),
            integral   = _r(99),
            medal      = _r(99),
        })
    end
    return t2t(data)
end


-- 获取敌人信息
virtualData['kofArena/getEnemyInfo'] = function(args)
    local targetEnemyInfo = {}
    for _, enemyData in ipairs(virtualData.kofArena_.enemyList or {}) do
        if enemyData.playerId == checkint(args.enemyPlayerId) then
            targetEnemyInfo = enemyData
            break
        end
    end

    local data = {
        enemyPlayerId          = targetEnemyInfo.playerId,
        enemyPlayerName        = targetEnemyInfo.playerName,
        enemyPlayerLevel       = targetEnemyInfo.playerLevel,
        enemyPlayerAvatar      = targetEnemyInfo.playerAvatar,
        enemyPlayerAvatarFrame = targetEnemyInfo.playerAvatarFrame,
        enemyPlayerCards       = {},
        enemyPlayerSkill       = {},
    }
    for teamId, teamData in pairs(targetEnemyInfo.playerCards) do
        data.enemyPlayerCards[teamId] = teamData.cards
    end
    return t2t(data)
end


-- 进入战斗
virtualData['kofArena/questAt'] = function(args)
    local data = {
        maxSkillTimes      = 0,
        maxCritDamageTimes = 0,
    }
    return t2t(data)
end


-- 战斗结算
virtualData['kofArena/questGrade'] = function(args)
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
