--[[
 * author : kaishiqi
 * descpt : 关于 武道会数据 的本地模拟
]]
virtualData = virtualData or {}

local _r  = virtualData._r
local j2t = virtualData.j2t
local t2t = virtualData.t2t

local DEBUG_DEFINE = {
    STATUS         = 1,--+30, --FOOD.CHAMPIONSHIP.STEP.UNKNOWN, -- 指定阶段，nil是随机状态
    COUNTDOWN      = 9876, -- 倒计时时间
    QUALIFIED      = 1,    -- 1：晋级，0：没晋级
    GAME_OVER      = 0,    -- 1：被淘汰，0：没淘汰
    IS_APPLIED     = true, -- 是否报名
    IS_AUTO_NEXT   = true, -- 退出进入，是否自动下个步骤
    IS_REMOVE_HALF = not true,  -- 随机响指掉一批玩家
}


-- 武道会 首页
virtualData['Championship/home'] = function(args)
    if not virtualData.championship_ then
        virtualData.championship_ = {
            seasonId     = 0,                      -- 赛季id
            status       = 0,                      -- 赛季阶段 @see CHAMPIONSHIP.STEP
            leftSec      = 0,                      -- 赛季阶段还剩多少秒
            countDown    = 0,                      -- 赛季开启还剩多少秒（闭馆时使用）
            --           = audition
            myScore      = _r(99999),              -- 海选赛 我的成绩
            myRank       = _r(99),                 -- 海选赛 我的排名
            ticket       = _r(9),                  -- 海选赛 挑战次数
            questId      = 0,                      -- 海选赛 关卡id
            auditionTeam = {},                     -- 海选赛 我的队伍
            --           = promotion
            qualified    = DEBUG_DEFINE.QUALIFIED, -- 晋级赛 是否晋级（1：晋级，0：没晋级）
            over         = DEBUG_DEFINE.GAME_OVER, -- 晋级赛 是否淘汰（1：被淘汰，0：没淘汰）
            rank         = _r(32),                 -- 晋级赛 最终排名
            team1        = {},                     -- 晋级赛 队伍1信息
            team2        = {},                     -- 晋级赛 队伍2信息
            team3        = {},                     -- 晋级赛 队伍3信息
            playerInfo   = {},                     -- 晋级赛 32名玩家信息
            matches      = {},                     -- 晋级赛 赛程进度信息
            myMatchIds   = {},                     -- 晋级赛 参加的场次
            --           = guess
            guess        = {},                     -- 我的竞猜信息
        }
        
        -- 赛季 信息
        virtualData.championship_.seasonId = virtualData._rValue(CONF.CHAMPIONSHIP.SCHEDULE:GetIdList(),1)[1]
        virtualData.championship_.status   = DEBUG_DEFINE.STATUS or virtualData._rValue(table.values(FOOD.CHAMPIONSHIP.STEP),1)[1]
        
        -- 海选赛 信息
        virtualData.championship_.questId      = virtualData._rValue(CONF.CHAMPIONSHIP.AUDITION_QUEST:GetIdList(),1)[1]
        virtualData.championship_.auditionTeam = virtualData._rValue(table.keys(virtualData.playerData.cards), MAX_TEAM_MEMBER_AMOUNT)
        -- virtualData.championship_.auditionTeam = { 
        --     '6951387', -- sp 米饭
        --     '6619366', -- 纳豆
        --     '6702702', -- 拐杖糖
        --     '7652427', -- 武夷大红袍
        --     '7026450', -- 冬虫夏草
        -- }
        
        -- 晋级赛 报名队伍
        if DEBUG_DEFINE.IS_APPLIED then
            local cardList = virtualData._rValue(table.keys(virtualData.playerData.cards), MAX_TEAM_MEMBER_AMOUNT * 3)
            local teamList = {}
            for cardIndex, cardUuid in ipairs(cardList) do
                local teamIndex = math.ceil(cardIndex / MAX_TEAM_MEMBER_AMOUNT)
                teamList[teamIndex] = teamList[teamIndex] or {}
                table.insert(teamList[teamIndex], cardUuid)
            end
            virtualData['Championship/apply']({
                cardIds1 = table.concat(teamList[1], ','),
                cardIds2 = table.concat(teamList[2], ','),
                cardIds3 = table.concat(teamList[3], ','),
            })
        end

        -- 晋级赛 32名玩家
        local playerCount = 32
        for playerIndex = 1, playerCount do
            local isPlayerSelf = playerIndex == 1
            local playerId     = isPlayerSelf and virtualData.playerData.playerId or virtualData.createPlayerId()
            local playerData = {
                level  = isPlayerSelf and virtualData.playerData.level       or _r(99),                            -- 玩家等级
                name   = isPlayerSelf and virtualData.playerData.playerName  or virtualData.createName(_r(6,12)),  -- 玩家名称
                avatar = isPlayerSelf and virtualData.playerData.avatar      or virtualData.createAvatarId(),      -- 玩家头像
                frame  = isPlayerSelf and virtualData.playerData.avatarFrame or virtualData.createAvatarFrameId(), -- 玩家头像框
                union  = isPlayerSelf and virtualData.playerData.union.name  or virtualData.createName(_r(6,12)),  -- 玩家工会
                combatValue1 = _r(999999),  -- 队伍1战力
                combatValue2 = _r(999999),  -- 队伍2战力
                combatValue3 = _r(999999),  -- 队伍3战力
            }
            virtualData.championship_.playerInfo[tostring(playerId)] = playerData
        end

        -- 随机响指掉一批玩家
        local matchPlayerIdList = table.keys(virtualData.championship_.playerInfo)
        if DEBUG_DEFINE.IS_REMOVE_HALF then
            for index, playerId in ipairs(matchPlayerIdList) do
                if checkint(playerId) ~= virtualData.playerData.playerId and _r(100) > 20 then
                    matchPlayerIdList[index] = 0
                    virtualData.championship_.playerInfo[tostring(playerId)] = nil
                end
            end
        end
        
        -- 晋级赛 比赛进度
        local matchWinnerIdList = {}
        for roundNum, matchIdList in ipairs(FOOD.CHAMPIONSHIP.MATCH_ID) do
            local playerIdList = roundNum == 1 and matchPlayerIdList or matchWinnerIdList[roundNum - 1]
            local winnerIdList = {}
            for index, matchId in ipairs(matchIdList) do
                local attackerId = checkint(playerIdList[(index-1)*2+1])
                local defenderId = checkint(playerIdList[(index-1)*2+2])
                local hasEmpty   = (attackerId == 0 or defenderId == 0)
                local winnerId   = hasEmpty and math.max(attackerId, defenderId) or virtualData._rValue({attackerId, defenderId},1)[1]
                virtualData.championship_.matches[tostring(matchId)] = {
                    winnerId     = winnerId,
                    attackerId   = attackerId,
                    defenderId   = defenderId,
                    attackerVote = _r(999),
                    defenderVote = _r(999),
                }
                winnerIdList[index] = winnerId
            end
            matchWinnerIdList[roundNum] = winnerIdList
        end

        -- 晋级赛 参加的场次
        for matchId, matchData in pairs(virtualData.championship_.matches) do
            if (virtualData.playerData.playerId == checkint(matchData.attackerId) or 
                virtualData.playerData.playerId == checkint(matchData.defenderId)) then
                virtualData.championship_.myMatchIds[tostring(matchId)] = matchId
            end
        end

        -- 我的竞猜信息
        if DEBUG_DEFINE.QUALIFIED == 0 then
            for roundNum, matchIdList in ipairs(FOOD.CHAMPIONSHIP.MATCH_ID) do
                for index, matchId in ipairs(matchIdList) do
                    if matchId <= virtualData.championship_.status + 1 then
                        if _r(100) > 80 then
                            local matcheData = virtualData.championship_.matches[tostring(matchId)]
                            virtualData.championship_.guess[tostring(matchId)] = {
                                id  = virtualData._rValue({matcheData.attackerId, matcheData.defenderId},1)[1],
                                num = _r(9999),
                            }
                        end
                    end
                end
            end
        end
    else
        if DEBUG_DEFINE.IS_AUTO_NEXT then
            -- switch status to next
            virtualData.championship_.status = virtualData.championship_.status + 1
            if virtualData.championship_.status > FOOD.CHAMPIONSHIP.STEP.OFF_SEASON then
                virtualData.championship_.status = 0
            end
        end
    end

    virtualData.championship_.leftSec   = DEBUG_DEFINE.COUNTDOWN or 5
    virtualData.championship_.countDown = DEBUG_DEFINE.COUNTDOWN or 5
    return t2t(virtualData.championship_)
end


-------------------------------------------------------------------------------
-- 海选赛
-------------------------------------------------------------------------------

-- 海选赛 购买次数
virtualData['Championship/ticket'] = function(args)
    local seasonId   = virtualData.championship_.seasonId
    local seasonConf = CONF.CHAMPIONSHIP.SCHEDULE:GetValue(seasonId)
    local consumeId  = checkint(seasonConf.consumeId)
    local consumeNum = checkint(seasonConf.consumeNum)
    local buyNumber  = checkint(args.num)
    virtualData.championship_.ticket = virtualData.championship_.ticket + buyNumber
    virtualData.playerData.diamond   = virtualData.playerData.diamond - (buyNumber * consumeNum)

    local data = {
        goodsId = consumeId,
        num     = virtualData.playerData.diamond,
        ticket  = virtualData.championship_.ticket,
    }
    return t2t(data)
end


-- 海选赛 提交队伍
virtualData['Championship/audition'] = function(args)
    local auditionTeam = string.split2(args.cardIds, ',')
    virtualData.championship_.auditionTeam = auditionTeam
    return t2t({})
end


-- 海选赛 前32排行
virtualData['Championship/rank'] = function(args)
    local data = {
        myRank  = _r(99),
        myScore = _r(99999),
        rank    = {},
    }
    for index = 1, _r(32) do
        data.rank[index] = {
            rank              = index,
            score             = _r(99999),
            playerId          = virtualData.createPlayerId(),
            playerName        = virtualData.createName(_r(8,16)),
            playerLevel       = _r(99),
            playerAvatar      = virtualData.createAvatarId(),
            playerAvatarFrame = virtualData.createAvatarFrameId(),
        }
    end
    return t2t(data)
end


-- 海选赛 进入战斗
virtualData['Championship/questAt'] = function(args)
    virtualData.championship_.ticket = virtualData.championship_.ticket - 1

    local data = {
        maxSkillTimes      = 0,
        maxCritDamageTimes = 0,
    }
    return t2t(data)
end


-- 海选赛 战斗结算
virtualData['Championship/questGrade'] = function(args)
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


-------------------------------------------------------------------------------
-- 晋级赛
-------------------------------------------------------------------------------

-- 晋级赛 提交队伍
virtualData['Championship/apply'] = function(args)
    local teamList = {
        string.split2(args.cardIds1, ','),
        string.split2(args.cardIds2, ','),
        string.split2(args.cardIds3, ','),
    }
    for teamIndex, cardList in ipairs(teamList) do
        local teamData = virtualData.championship_['team'..teamIndex]
        for cardIndex, cardUuid in ipairs(cardList) do
            local cardData = virtualData.playerData.cards[cardUuid]
            teamData[cardIndex] = cardData
        end
    end
    return t2t({})
end


-- 晋级赛 选手队伍详情
virtualData['Championship/detail'] = function(args)
    local isPlayerSelf   = virtualData.playerData.playerId == args.targetId
    local playerData     = virtualData.championship_.playerInfo[tostring(args.targetId)]
    local allPetIdList   = table.keys(CommonUtils.GetConfigAllMess('pet', 'pet'))
    local petBreakIdList = table.keys(CommonUtils.GetConfigAllMess('petBreak', 'petBreak'))
    local gemstoneIdList = table.keys(CommonUtils.GetConfigAllMess('gemstone', 'artifact'))
    for teamIndex = 1, 3 do
        if nil == playerData['_team' .. teamIndex] then
            local teamData = {}
            if isPlayerSelf then
                teamData = virtualData.championship_['team' .. teamIndex]
            else
                for cardIndex = 1, MAX_TEAM_MEMBER_AMOUNT do
                    local cardData = virtualData.createCardData(nil, args.targetId)
                    teamData[cardIndex] = cardData

                    local petConf = PetUtils.GetPetConfig(allPetIdList[_r(#allPetIdList)])
                    cardData.pets = {
                        ['1'] = {
                            playerPetId = virtualData.generateUuid(),
                            petId       = petConf.id,
                            level       = _r(30),
                            breakLevel  = _r(table.nums(petBreakIdList)),
                            character   = _r(1, table.nums(petConf.character)),
                            isEvolution = _r(0,1),
                            attr        = {},
                        }
                    }
                    for i = 1, #PetUtils.GetPetPInfo() do
                        cardData.pets['1'].attr[i] = {
                            type    = i,
                            num     = _r(9999),
                            quality = _r(5),
                        }
                    end
                    
                    cardData.artifactTalent = {}
                    local cardTalentConf = ArtifactUtils.GetCardAllTalentConfig(cardData.cardId)
                    for _, talentConf in pairs(cardTalentConf or {}) do
                        local index = #cardData.artifactTalent + 1
                        cardData.artifactTalent[tostring(index)] = {
                            id           = virtualData.generateUuid(),
                            talentId     = talentConf.id,
                            type         = talentConf.artifactAttrType[1],
                            level        = _r(1, talentConf.level),
                            gemstoneId   = gemstoneIdList[_r(#gemstoneIdList)],
                            playerId     = cardData.playerId,
                            playerCardId = cardData.id,
                            fragmentNum  = _r(99),
                        }
                    end
                end
            end
            playerData['_team' .. teamIndex] = teamData
        end
    end
    local data = {
        team1 = playerData._team1,
        team2 = playerData._team2,
        team3 = playerData._team3,
    }
    return t2t(data)
end


virtualData['Championship/replayOverall'] = function(args)
    local matchId    = args.matchId
    local matcheData = virtualData.championship_.matches[tostring(matchId)]
    local attackData = checkint(matcheData.attackerId) > 0 and virtualData['Championship/detail']({targetId = matcheData.attackerId}).data or {}
    local defendData = checkint(matcheData.defenderId) > 0 and virtualData['Championship/detail']({targetId = matcheData.defenderId}).data or {}

    local data = {
        data = {},  -- key 场次
    }
    for sequence = 1, 3 do
        data.data[tostring(sequence)] = {
            friendTeam = attackData['team'..sequence], -- 攻击方队伍
            enemyTeam  = defendData['team'..sequence], -- 防守方队伍
            result     = _r(0,1), -- 战斗结果（1：攻击方火舌，0：防守方获胜）
        }
    end
    return t2t(data)
end


virtualData['Championship/replayDetail'] = function(args)
    local matchId     = args.matchId
    local sequence    = args.sequence
    local matcheData  = virtualData.championship_.matches[tostring(matchId)]
    local attackTeam  = checkint(matcheData.attackerId) > 0 and virtualData['Championship/detail']({targetId = matcheData.attackerId}).data['team'..sequence] or {}
    local defendTeam  = checkint(matcheData.defenderId) > 0 and virtualData['Championship/detail']({targetId = matcheData.defenderId}).data['team'..sequence] or {}

    -- battle constructor
    local battleConstructor = require('battleEntry.BattleConstructorEx').new()
    battleConstructor:InitByCommonData(
        0,                                      -- 关卡 id
        -- QuestBattleType.FRIEND_BATTLE,          -- 战斗类型
        QuestBattleType.CHAMPIONSHIP_PROMOTION, -- 战斗类型
        ConfigBattleResultType.ONLY_RESULT,     -- 结算类型
        ----
        {},                                     -- 友方阵容
        {},                                     -- 敌方阵容
        ----
        nil,                                    -- 友方携带的主角技
        nil,                                    -- 友方所有主角技
        nil,                                    -- 敌方携带的主角技
        nil,                                    -- 敌方所有主角技
        ----
        nil,                                    -- 全局buff
        nil,                                    -- 卡牌能力增强信息
        ----
        nil,                                    -- 已买活次数
        nil,                                    -- 最大买活次数
        false,                                  -- 是否开启买活
        ----
        3319870061,                                    -- 随机种子
        false,                                  -- 是否是战斗回放
        ----
        nil,                                    -- 与服务器交互的命令信息
        nil                                     -- 跳转信息
    )

    -- resources data 
    local attackDefines = {}
    local defendDefines = {}
    for _, cardData in ipairs(attackTeam) do
        table.insert(attackDefines, {skinId = cardData.defaultSkinId})
    end
    for _, cardData in ipairs(attackTeam) do
        table.insert(defendDefines, {skinId = cardData.defaultSkinId})
    end
    local attackLoadedRes = battleConstructor:CalcLoadSpineResOneTeam(
        nil,           -- 关卡id
        nil,           -- 战斗类型
        attackDefines, -- 队伍数据
        true           -- 检查连携
    )
    local defendLoadedRes = battleConstructor:CalcLoadSpineResOneTeam(
        nil,           -- 关卡id
        nil,           -- 战斗类型
        defendDefines, -- 队伍数据
        true           -- 检查连携
    )
    local loadedResArray = {
        string.gsub(attackLoadedRes, '{%[1%]={(.*)}}', '%1'),
        string.gsub(defendLoadedRes, '{%[1%]={(.*)}}', '%1'),
    }
    
    -- operate data
    local operateList = {
        '[0]={[1]={["maxParams"]=0,["managerName"]="G_BattleLogicMgr",["functionName"]="RenderReadyStartNextWaveHandler",["variableParams"]={}}},',
        '[47]={[1]={["maxParams"]=0,["managerName"]="G_BattleLogicMgr",["functionName"]="RenderStartNextWaveHandler",["variableParams"]={}}}',
    }
    
    -- return data
    local data = {
        data = {
            constructor     = battleConstructor:CalcRecordConstructData(),                 -- 构造器json
            loadedResources = string.fmt('{[1]={%1}}', table.concat(loadedResArray, ',')), -- 资源表json
            playerOperate   = string.fmt('{%1}', table.concat(operateList, '')),           -- 操作json
        }
    }
    return t2t(data)
end


-------------------------------------------------------------------------------
-- 竞猜
-------------------------------------------------------------------------------

-- 下注
virtualData['Championship/guess'] = function(args)
    local guessNum = FOOD.CHAMPIONSHIP.calculateVoteNum(virtualData.playerData.championshipPoint)
    virtualData.championship_.guess[tostring(args.matchId)] = {
        id  = args.guessId,
        num = guessNum,
    }

    virtualData.playerData.championshipPoint = virtualData.playerData.championshipPoint - guessNum

    local data = {
        guessNum = guessNum,                                 -- 下注金额
        num      = virtualData.playerData.championshipPoint, -- 剩余金额
    }
    return t2t(data)
end


-------------------------------------------------------------------------------
-- 其他
-------------------------------------------------------------------------------

-- 获取历届冠军
virtualData['Championship/history'] = function(args)
    local pageNum = args.page
    local data = {
        maxpage = 6,  -- 最大页数
        range   = 8,  -- 每页几个
        data    = {}, -- 数据列表
    }
    for index = 1, data.range do
        local team1 = virtualData._rValue(virtualData.validCardIdList, 5)
        local team2 = virtualData._rValue(virtualData.validCardIdList, 5)
        local team3 = virtualData._rValue(virtualData.validCardIdList, 5)
        data.data[index] = {
            seasonId = (pageNum-1) * data.range + index,
            playerId = virtualData.createPlayerId(),
            name     = virtualData.createName(_r(8, 16)),
            level    = _r(100),
            avatar   = virtualData.createAvatarId(),
            frame    = virtualData.createAvatarFrameId(),
            union    = virtualData.createName(_r(0, 20)),
            cards1   = table.concat(team1, ','),
            cards2   = table.concat(team2, ','),
            cards3   = table.concat(team3, ','),
        }
    end
    return t2t(data)
end
