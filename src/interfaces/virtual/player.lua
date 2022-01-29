--[[
 * author : kaishiqi
 * descpt : 关于 玩家数据 的本地模拟
]]
virtualData = virtualData or {}

local _r  = virtualData._r
local j2t = virtualData.j2t
local t2t = virtualData.t2t


virtualData['player/name'] = function(args)
    local data = {
        playerName = {}
    }
    for i = 1, 10 do
        table.insert(data.playerName, virtualData.createName(_r(6,12)))
    end
    return t2t(data)
end


virtualData['Player/create'] = function(args)
    virtualData.playerData.avatar     = args.avatar
    virtualData.playerData.birthday   = args.birthday
    virtualData.playerData.playerName = args.playerName

    local data = {
        playerId   = virtualData.playerData.playerId,
        playerName = virtualData.playerData.playerName,
        serverTime = virtualData.playerData.serverTime,
    }
    return t2t(data)
end


-- 玩家角色签到
virtualData['player/checkin'] = function(args)
    local checkinJson  = io.readfile(cc.FileUtils:getInstance():fullPathForFilename("interfaces/"..'checkin2.json'))
	virtualData.playerData = json.decode(checkinJson)
    return t2t(virtualData.playerData)
end

-- 皇家对决
virtualData['offlineArena/home'] = function(args)
    local checkinJson  = io.readfile(cc.FileUtils:getInstance():fullPathForFilename("interfaces/"..'huangjiaduijue.json'))
    return t2t(json.decode(checkinJson))
end


virtualData['Player/guide'] = function(args)
    return t2t({})
end


virtualData['player/unlockArea'] = function(args)
    return t2t({})
end


virtualData['pay/buyGold'] = function(args)
    local data = {
        gold              = virtualData.playerData.gold,
        diamond           = virtualData.playerData.diamond,
        freeGoldLeftTimes = {}
    }
    return t2t(data)
end
virtualData['pay/buyHp'] = function(args)
    virtualData.playerData.hp = virtualData.playerData.hp + 1
    local data = {
        hp = virtualData.playerData.hp,
    }
    return t2t(data)
end


-------------------------------------------------
-- quest 主线相关接口
-------------------------------------------------

-- 玩家进入战斗前
virtualData['quest/at'] = function(args)
    local data = {
        maxCritDamageTimes = 0,
        maxSkillTimes      = 0,
        currentQuestId     = args.questId
    }
    return t2t(data)
end
-- 战斗结算
virtualData['quest/grade'] = function(args)
    local isPassed   = checkint(args.isPassed) == 1
    local questId    = checkint(args.questId)
    local questConfs = virtualData.getConf('quest', 'quest')
    local questConf  = questConfs[tostring(questId)] or {}
    local questLevel = checkint(questConf.difficulty)

    virtualData.playerData.hp = virtualData.playerData.hp - 5

    if isPassed then
        local plotTaskId = checkint(checktable(virtualData.playerData.newestPlotTask).taskId)
        local questConf  = virtualData.getConf('quest', 'questPlot', plotTaskId)
        local addMainExp = plotTaskId > 0 and checkint(questConf.mainExp) or 10
        virtualData.playerData.mainExp       = virtualData.playerData.mainExp + addMainExp
        virtualData.playerData.newestQuestId = virtualData.playerData.newestQuestId + 1

        if virtualData.plot_ and virtualData.plot_.plotTask[tostring(plotTaskId)] then
            local plotTaskData = virtualData.plot_.plotTask[tostring(plotTaskId)]
            plotTaskData.status = 3
        end

        if questLevel == 1 then  -- 普通
            virtualData.playerData.newestQuestId = math.max(virtualData.playerData.newestQuestId, questId)
        elseif questLevel == 2 then  -- 困难
            virtualData.playerData.newestHardQuestId = math.max(virtualData.playerData.newestHardQuestId, questId)
        elseif questLevel == 3 then  -- 史诗
            virtualData.playerData.newestInsaneQuestId = math.max(virtualData.playerData.newestInsaneQuestId, questId)
        end
    end

    local data = {
        hp                  = virtualData.playerData.hp,
        gold                = virtualData.playerData.gold,
        mainExp             = virtualData.playerData.mainExp,
        newestQuestId       = virtualData.playerData.newestQuestId,
        newestHardQuestId   = virtualData.playerData.newestHardQuestId,
        newestInsaneQuestId = virtualData.playerData.newestInsaneQuestId,
        grade               = _r(5),
        reward              = {},
        rewards             = {},
        magicFood           = {},
        monsters            = {},
        cardExp             = {},
        favorabilityCards   = {},
        isFirstPassed       = virtualData.playerData.isFirstPassed
    }
    virtualData.playerData.isFirstPassed = false
    
    local teamData = virtualData.playerData.allTeams[args.teamId] or {}
    for i, teamData in ipairs(teamData.cards or {}) do
        local cardGuid = checkint(teamData.id)
        if cardGuid > 0 then
            local cardData = virtualData.playerData.cards[tostring(cardGuid)]
            data.cardExp[tostring(cardGuid)] = {
                exp   = cardData.exp,
                level = cardData.level,
            }
            data.favorabilityCards[tostring(cardGuid)] = {
                favorability      = cardData.favorability,
                favorabilityLevel = cardData.favorabilityLevel,
            }
        end
    end
    return t2t(data)
end
-- 三星扫荡
virtualData['quest/sweep'] = function(args)
    local addExp   = 10
    local addGold  = _r(100)
    local sweepNum = checkint(args.times)
    virtualData.playerData.gold = virtualData.playerData.gold + addGold
    virtualData.playerData.mainExp = virtualData.playerData.mainExp + addExp
    local data = {
        totalGold     = virtualData.playerData.gold,
        totalMainExp  = virtualData.playerData.mainExp,
        challengeTime = -1,                             -- 剩余挑战次数(-1为无限制)
        sweep         = {}
    }
    for i = 1, sweepNum do
        local sweepData = {
            mainExp = math.floor(addExp / sweepNum),
            gold    = math.floor(addGold / sweepNum),
            rewards = virtualData.createGoodsList(_r(2,6))
        }
        data.sweep[tostring(i)] = sweepData
    end
    return t2t(data)
end
-- 主线剧情领取奖励
virtualData['quest/story'] = function(args)
    local data = {
        rewards = {
            {goodsId = 890002, num = _r(999)}
        }
    }
    return t2t(data)
end


-- 切换玩家主角技
virtualData['quest/switchPlayerSkill'] = function(args)
    local skillList = string.split2(args.skills, ',')
    local data = {
        skill = skillList
    }
    return t2t(data)
end


-------------------------------------------------
-- Prize 领奖中心及邮箱接口
-------------------------------------------------

-- 领奖中心
virtualData['Prize/enter'] = function(args)
    local data = {
        prizes = {}
    }
    if _r(100) > 75 then
        for i = 1, _r(5) do
            table.insert(data.prizes, {
                prizeId        = 1,
                title          = virtualData.createName(12),
                content        = virtualData.createName(1000),
                rewards        = virtualData.createGoodsList(_r(1,5)),
                from           = nil,
                createTime     = os.time(),
                effectTime     = _r(99),
                expirationTime = 60*60*24*30,
            })
        end
    end
    return t2t(data)
end


-------------------------------------------------
-- notice 公告接口
-------------------------------------------------

virtualData['notice/publicNotice'] = function(args)
    local data = {
        notice = {}
    }
    if _r(100) > 75 then
        for i = 1, _r(5) do
            local type = _r(1, 2)

            -- 公告类型
            if type == 1 then
                table.insert(data.notice, {
                    type     = 1,  
                    title    = '公告标题' .. i,
                    subTitle = '公告子标题' .. i,
                    content  = virtualData.createName(_r(50, 150)),
                })

            -- 活动类型
            elseif type == 2 then
                table.insert(data.notice, {
                    type        = 2,  
                    title       = '活动标题' .. i,
                    subTitle    = '活动子标题' .. i,
                    content     = virtualData.createName(_r(50, 150)),
                    contentTime = virtualData.createFormatTime(os.time()),
                })
            end
        end
    end
    return t2t(data)
end


-------------------------------------------------
-- Personal 个人相关接口
-------------------------------------------------

virtualData['Personal/playerPersonal'] = function(args)
    -- TODO
    return t2t({})
end


-------------------------------------------------
-- talent 天赋相关接口
-------------------------------------------------

-- 天赋列表
virtualData['talent/talents'] = function(args)
    local talentDefine = {
        {type = TalentType.DAMAGE, name = 'talentDamage'},  -- 伤害
        {type = TalentType.SUPPORT, name = 'talentAssist'}, -- 辅助
        {type = TalentType.CONTROL, name = 'talentControl'}, -- 控制
    }
    local data = {}
    for _, define in ipairs(talentDefine) do
        data[tostring(define.type)] = {
            talentLevel            = 0,     -- 天赋总等级
            nextTalentCookingPoint = _r(9), -- 下一级消耗的料理点
        }
    end
    return t2t(data)
end

-- 点亮天赋
virtualData['talent/lightTalent'] = function(args)
    local data = {
        talentId               = args.talentId,
        consumeCookingPoint    = _r(9),         -- 消耗的料理点
        nextTalentCookingPoint = _r(9),         -- 下一级消耗的料理点
        skill                  = {},            -- 选中的主角技
        allSkill               = {},            -- 所有的主角技
    }
    return t2t(data)
end


-- 日常
virtualData['dailyTask/home'] = function(args)
    local data = {
        tasks              = {},
        activePoint        = _r(99),
        activePointRewards = {}
    }

    local dailyTaskConfs = virtualData.getConf('task', 'task')
    for _, taskConf in pairs(dailyTaskConfs) do
        if _r(100) > 75 then
            table.insert(data.tasks, {
                id          = checkint(taskConf.id),
                name        = tostring(taskConf.name),
                descr       = tostring(taskConf.descr),
                activePoint = _r(99),
                progress    = _r(0, checkint(taskConf.targetNum)*2),
                targetNum   = checkint(taskConf.targetNum),
                hasDrawn    = _r(0,1),
                rewards     = virtualData.createGoodsList(_r(1,3)),
                mainExp     = checkint(taskConf.mainExp),
                taskType    = checkint(taskConf.taskType),
            })
        end
    end
    

    for i = 1, 5 do
        table.insert(data.activePointRewards, {
            activePoint = i*10,
            hasDrawn    = _r(0,1),
            rewards     = virtualData.createGoodsList(_r(2,4))
        })
    end
    return t2t(data)
end

