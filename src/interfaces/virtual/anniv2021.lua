--[[
 * author : panmeng
 * descpt : 关于 周年庆21 的本地模拟
]]
local _r  = virtualData._r
local j2t = virtualData.j2t
local t2t = virtualData.t2t

local EXPLORE_FLOOR_MAX  = FOOD.ANNIV2020.DEFINE.EXPLORE_FLOOR_MAX
local EXPLORE_MAP_ROWS   = FOOD.ANNIV2020.DEFINE.EXPLORE_MAP_ROWS
local EXPLORE_TYPE_CONF  = FOOD.ANNIV2020.EXPLORE_TYPE_CONF
local EXPLORE_TYPE       = FOOD.ANNIV2020.EXPLORE_TYPE

local BOSS_APPEAR_TIME   = CONF.ANNIV2021.BASE_PARMS:GetValue('bossAppearTimes')

local DEBUG_DEFINE = {
    PRE_UNLOCK_STORY_TYPE    = 1, -- 预先解锁故事（0：不解锁，1：全解锁，2：随机解锁)
    INIT_EXPLORE_ENTRANCE_ID = 1, -- 初始进入探索（0-3）
    EXPLORE_MAX_FLOOR        = 12,
    EXPLORE_INIT_LAYER       = _r(1, 12),
    LOTTERY_ROUND            = _r(1, 10),
}

-- 周年庆 首页
virtualData['Anniversary2021/home'] = function(args)
    if not virtualData.anniv21_ then
        virtualData.anniv21_ = {
            hp                     = _r(199,399),                                          -- 当前体力
            drawHpLeftSeconds      = _r(9,19),                                             -- 体力领取剩余秒数
            point                  = _r(199, 399),                                         -- 积分
            unlockStoryList        = {},                                                   -- 解锁故事列表
            isEnd                  = 0,                                                    -- 活动是否结束
            drawnPointRewardIds    = {},                                                   -- 领取的积分奖励列表
            drawnPlotFillRewardIds = {},                                                   -- 领取的填词奖励进度
            plotFillProgress       = 1 or _r(0, CONF.ANNIV2021.PLOT_FILL_QUESTION:GetLength()), -- 填词进度
            currentExploreId       = DEBUG_DEFINE.INIT_EXPLORE_ENTRANCE_ID,                -- 当前迷宫ID
            bossAppearLeftTimes    = _r(0, BOSS_APPEAR_TIME),                                                    -- boss出现剩余次数
            bossHp                 = _r(199, 399),                                         -- boss体力
            isEnd = false,
        }

        if DEBUG_DEFINE.PRE_UNLOCK_STORY_TYPE > 0 then
            for _, storyConf in pairs(CONF.ANNIV2021.STORY_COLLECTION:GetAll()) do
                if DEBUG_DEFINE.PRE_UNLOCK_STORY_TYPE == 1 or _r(100) > 50 then
                    table.insert(virtualData.anniv21_.unlockStoryList, storyConf.id)
                end
            end
        end

    end
    return t2t(virtualData.anniv21_)
end


-------------------------------------------------------------------------------
-- 故事
-------------------------------------------------------------------------------

virtualData['Anniversary2021/unlockStory'] = function(args)
    table.insert(virtualData.anniv21_.unlockStoryList, args.storyId)
    return t2t({})
end


-------------------------------------------------------------------------------
-- 领体力
-------------------------------------------------------------------------------

virtualData['Anniversary2021/drawHp'] = function(args)
    local hpRecoverNum     = checkint(CONF.ANNIV2021.BASE_PARMS:GetValue('hpRecoverNum'))
    local hpRecoverSeconds = checkint(CONF.ANNIV2021.BASE_PARMS:GetValue('hpRecoverSeconds'))
    virtualData.anniv21_.drawHp = virtualData.anniv21_.drawHp + hpRecoverNum
    virtualData.anniv21_.drawHpLeftSeconds = hpRecoverSeconds
    return t2t({})
end


-------------------------------------------------------------------------------
-- 领取剧情奖励
-------------------------------------------------------------------------------

virtualData['Anniversary2021/drawPointRewards'] = function(args)
    local pointRewardConf = CONF.ANNIV2021.AWARDING_INFO:GetValue(args.rewardId)
    local data = {
        rewards = pointRewardConf.rewards
    }
    return t2t(data)
end


-------------------------------------------------------------------------------
-- 抽奖
-------------------------------------------------------------------------------

-- -- 抽奖首页
virtualData['Anniversary2021/lotteryHome'] = function(args)
    if not virtualData.anniv21_lottery_home then
        local BASE_PARMS    = CONF.ANNIV2021.BASE_PARMS
        local groupListData = {
            {
                group = 1,
                loop  = DEBUG_DEFINE.LOTTERY_ROUND,
                totalRewards = {}
            }
        }

        for i = 1, 100 do
            local goodsIndex = _r(1, CONF.ANNIV2021.EXPLORE_MALL:GetLength())
            local goodsData  = CONF.ANNIV2021.EXPLORE_MALL:GetValue(goodsIndex)
            table.insert(groupListData[1].totalRewards, {
                id      = i,
                rewards = {goodsData},
                isRare  = _r(0, 1),
                sort    = i,
                num     = _r(1, 5),
            })
        end

        local lotteryTimes = _r(1, 99)
        local rewards      = {}
        virtualData.anniv21_lottery_other_rewards = {}
        local index = 0
        for _, rewardsData in ipairs(groupListData[1].totalRewards) do
            if table.nums(rewards) >= lotteryTimes then
                index = index + 1
                virtualData.anniv21_lottery_other_rewards[index] = rewardsData.rewards[1]
            else
                rewards[rewardsData.id] = rewards
            end
        end


        virtualData.anniv21_lottery_home = {
            consumeGoodsId  = BASE_PARMS:GetValue('lotteryGoodsId'),
            consumeGoodsNum = BASE_PARMS:GetValue('lotteryGoodsNum'),
            round           = _r(1, DEBUG_DEFINE.LOTTERY_ROUND),
            groupId         = 1,
            lotteryTimes    = lotteryTimes,
            rewards         = rewards,
            groups          = groupListData,
        }
    end
    return t2t(virtualData.anniv21_lottery_home)
end


-- 抽奖
virtualData['Anniversary2021/lottery'] = function(args)
    local rands   = {}
    local rewards = {}
    for i = 1, args.times do
        local freeRewards      = virtualData.anniv21_lottery_other_rewards
        local maxNum = table.nums(freeRewards)
        logt(freeRewards,'111113')
        -- local freeRewardIdList = table.keys(freeRewards)
        local rewardUuid       = freeRewards[math.random(1, maxNum)]
        table.insert(rewards, freeRewards[i])
        -- freeRewards[rewardUuid] = nil
    end

    return t2t({
        rewards = rewards,
    })
end


-------------------------------------------------------------------------------
-- 填词游戏
-------------------------------------------------------------------------------

-- 填词
virtualData['Anniversary2021/plotFill'] = function(args)
    if args.isPass == 1 then
        virtualData.anniv21_.plotFillProgress = virtualData.anniv21_.plotFillProgress + 1 
    end
    return t2t({})
end


-- 领取填词奖励
virtualData['Anniversary2021/drawPlotFillRewards'] = function(args)
    local plotRewardConf = CONF.ANNIV2021.PLOT_FILL_REWARD:GetValue(args.rewardId)
    local data = {
        rewards = plotRewardConf.rewards
    }
    return t2t(data)
end


-------------------------------------------------------------------------------
-- 探索游戏
-------------------------------------------------------------------------------

-- 探索扫荡
virtualData['Anniversary2021/exploreSweep'] = function(args)
    local sweepConf = CONF.ANNIV2021.EXPLORE_SWEEP:GetValue(args.sweepId)
    local data = {
        rewards = sweepConf.rewards
    }
    return t2t(data)
end


-- 爬塔进入
virtualData['Anniversary2021/exploreEnter'] = function(args)
    if not virtualData.anniv21_exploreGame_home then
        local map = {}
        for row = 1, DEBUG_DEFINE.EXPLORE_MAX_FLOOR do
            local curRowNum      = _r(1, EXPLORE_MAP_ROWS)
            local rowIndexRandom = {[1] = true, [2] = true, [3] = true}
            for col = 1, curRowNum do
                -- get random position
                local randomList  = table.keys(rowIndexRandom)
                local cellIndex   = randomList[math.random(1, #randomList)]
                rowIndexRandom[cellIndex] = nil

                -- get random type
                local exploreType = _r(1, #EXPLORE_TYPE)
                local typeConfs   = EXPLORE_TYPE_CONF[exploreType]

                local exploreIndex = _r(1, typeConfs:GetLength())
                local exploreConf  = typeConfs:GetValue(exploreIndex)

                -- get random parent
                local parent = 0
                if map[row - 1] then
                    if not map[row] then
                        parent = 2
                    else
                        local parendIndexList = table.keys(map[row - 1])
                        parent = parendIndexList[math.random(1, #parendIndexList)]
                    end
                end

                if not map[row] then
                    map[row] = {}
                end
                map[row][col] = {
                    refId    = exploreConf.id,                                   -- 根据type到不同表 然后refId就是目标表的id
                    type     = exploreType,                                      -- 探索类型
                    parent   = parent,                                           --
                    isPassed = _r(0, 1),                                         -- 0 未通关，1 已通关
                    finished = row > DEBUG_DEFINE.EXPLORE_INIT_LAYER and 0 or 1, -- 0
                }
            end

        end

        local openCurPos = _r(0, 1)
        local position   = 0
        if openCurPos == 1 then
            position = DEBUG_DEFINE.EXPLORE_INIT_LAYER[math.random(table.keys(map[DEBUG_DEFINE.EXPLORE_INIT_LAYER]))]
        end
        virtualData.anniv21_exploreGame_home = {
            floor     = DEBUG_DEFINE.EXPLORE_INIT_LAYER, -- 当前层（先-1 是因为 [nextFloor] 会+1)
            position  = position,
            map       = map, -- 地图数据（key：格子id)
            mapOpened = _r(0, 1), -- 是否地图全开
        }
    end
    return t2t(virtualData.anniv21_exploreGame_home)
end


-- 探索放弃
virtualData['Anniversary2021/exploreGiveUp'] = function(args)
    -- clean homeData
    virtualData.anniv21_exploreGame_home = nil

    return t2t({})
end


-- 探索下一层
virtualData['Anniversary2021/exploreNextFloor'] = function(args)
    virtualData.anniv21_exploreGame_home.position = args.position
    return t2t({})
end


-- 迷宫地图全开
virtualData['Anniversary2021/exploreOpenMap'] = function(args)
    virtualData.anniv21_exploreGame_home.mapOpened = 1
    return t2t(data)
end


-- 探索 - 宝箱
virtualData['Anniversary2021/exploreChest'] = function(args)
    local exploreData = virtualData.anniv21_exploreGame_home
    local mapData     = exploreData.map[exploreData.floor][exploreData.position]
    mapData.isPassed = 1
    mapData.finished = 1

    local chestData = EXPLORE_TYPE_CONF[EXPLORE_TYPE.CHEST]:GetValue(mapData.refId)
    local data = {
        rewards = chestData.rewards
    }

    return t2t(data)
end


-- 探索 - 剧情
virtualData['Anniversary2021/explorePlot'] = function(args)
    local exploreData = virtualData.anniv21_exploreGame_home
    local mapData     = exploreData.map[exploreData.floor][exploreData.position]
    mapData.isPassed = 1
    mapData.finished = 1

    local plotData = EXPLORE_TYPE_CONF[EXPLORE_TYPE.PLOT]:GetValue(mapData.refId)
    local data = {
        rewards = plotData.rewards
    }

    return t2t(data)
end


-- 探索 - 商店
virtualData['Anniversary2021/exploreMall'] = function(args)
    local exploreData = virtualData.anniv21_exploreGame_home
    local mapData     = exploreData.map[exploreData.floor][exploreData.position]
    mapData.isPassed = 1
    mapData.finished = 1

    local shopData = EXPLORE_TYPE_CONF[EXPLORE_TYPE.MALL]:GetValue(args.productId)
    local data = {
        rewards = shopData
    }

    return t2t(data)
end


-- 探索 - 战斗 开始/结算
virtualData['Anniversary2021/exploreQuestAt'] = function(args)
    virtualData.exporeCards = args.cards

    return t2t({})
end
virtualData['Anniversary2021/exploreQuestGrade'] = function(args)
    local exploreData = virtualData.anniv21_exploreGame_home
    local mapData     = exploreData.map[exploreData.floor][exploreData.position]
    mapData.isPassed  = checkint(args.isPassed)
    mapData.finished  = true

    virtualData.anniv21_.bossAppearLeftTimes = virtualData.anniv21_.bossAppearLeftTimes - 1
    if virtualData.anniv21_.bossAppearLeftTimes <= 0 then
        virtualData.anniv21_.bossAppearLeftTimes = 0
    end

    return t2t({
        cards       = virtualData.anniv21ExporeCards,
        deadCards   = "",
        passTime    = _r(1, 100),
        fightData   = {},
        totalDamage = _r(1, 100),
        isPassed    = virtualData.anniv21_.bossHp <= 0,
    })
end


-- boss - 战斗 开始/结算
virtualData['Anniversary2021/bossQuestAt'] = function(args)
    virtualData.anniv21ExporeCards = args.cards
    return t2t({})
end
virtualData['Anniversary2021/bossQuestGrade'] = function(args)                                         -- boss出现剩余次数
    virtualData.anniv21_.bossHp = virtualData.anniv21_.bossHp - 200
    if virtualData.anniv21_.bossHp <= 0 then
        virtualData.anniv21_.bossAppearLeftTimes    = BOSS_APPEAR_TIME    
    end
    return t2t({
        cards       = virtualData.anniv21ExporeCards,
        deadCards   = "",
        passTime    = _r(1, 100),
        fightData   = {},
        totalDamage = _r(1, 100),
        isPassed    = virtualData.anniv21_.bossHp <= 0,
        bossHp      = virtualData.anniv21_.bossHp,
    })
end
