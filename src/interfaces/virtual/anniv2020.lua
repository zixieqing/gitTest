--[[
 * author : kaishiqi
 * descpt : 关于 武道会数据 的本地模拟
]]
virtualData = virtualData or {}

local _r  = virtualData._r
local j2t = virtualData.j2t
local t2t = virtualData.t2t

local EXPLORE_FLOOR_MAX  = FOOD.ANNIV2020.DEFINE.EXPLORE_FLOOR_MAX
local EXPLORE_MAP_ROWS   = FOOD.ANNIV2020.DEFINE.EXPLORE_MAP_ROWS
local EXPLORE_MAP_COLS   = FOOD.ANNIV2020.DEFINE.EXPLORE_MAP_COLS
local EXPLORE_FLOOR_BOSS = FOOD.ANNIV2020.DEFINE.EXPLORE_FLOOR_BOSS
local EXPLORE_TYPE_CONF  = FOOD.ANNIV2020.EXPLORE_TYPE_CONF
local EXPLORE_TYPE       = FOOD.ANNIV2020.EXPLORE_TYPE

local DEBUG_DEFINE = {
    PRE_UNLOCK_STORY_TYPE    = 1, -- 预先解锁故事（0：不解锁，1：全解锁，2：随机解锁）
    INIT_HANGING_MATERIAL_ID = 3, -- 初始一个挂机
    INIT_EXPLORE_ENTRANCE_ID = 0, -- 初始进入探索（0-3）
    INIT_EXPLORE_FLOOR_NUM   = _r(1, EXPLORE_FLOOR_MAX),
    -- INIT_PUZZLE_PROGRESS     = 98765,
}


-- 周年庆 首页
virtualData['Anniversary2020/home'] = function(args)
    if not virtualData.anniv20_ then
        virtualData.anniv20_ = {
            jumpGridHp              = _r(199,399), -- 探索 当前体力
            jumpGridDrawLeftSeconds = _r(9,19),    -- 探索 领取剩余秒数
            unlockStoryList         = {},          -- 故事 解锁列表
            hangLeftSeconds         = 0,           -- 挂机 剩余秒数
            progress                = DEBUG_DEFINE.INIT_PUZZLE_PROGRESS or 0, -- 拼图 进度
        }

        if DEBUG_DEFINE.PRE_UNLOCK_STORY_TYPE > 0 then
            for _, storyConf in pairs(CONF.ANNIV2020.STORY_COLLECTION:GetAll()) do
                if DEBUG_DEFINE.PRE_UNLOCK_STORY_TYPE == 1 or _r(100) > 50 then
                    table.insert(virtualData.anniv20_.unlockStoryList, storyConf.id)
                end
            end
        end

        if checkint(DEBUG_DEFINE.INIT_HANGING_MATERIAL_ID) > 0 then
            local hangingMaterialConf = CONF.ANNIV2020.HANG_FORMULA:GetValue(DEBUG_DEFINE.INIT_HANGING_MATERIAL_ID)
            local hangingMaterials    = table.concat(table.keys(hangingMaterialConf.material), ',')
            virtualData['Anniversary2020/hangHome']()
            virtualData['Anniversary2020/hang']({materials = hangingMaterials})
            virtualData.anniv20_.hangLeftSeconds = virtualData.anniv20_hangGame.hangLeftSeconds
        end
    end
    return t2t(virtualData.anniv20_)
end


-------------------------------------------------------------------------------
-- 故事
-------------------------------------------------------------------------------

virtualData['Anniversary2020/unlockStory'] = function(args)
    table.insert(virtualData.anniv20_.unlockStoryList, args.storyId)
    return t2t({})
end


-------------------------------------------------------------------------------
-- 商城
-------------------------------------------------------------------------------

-- 商城主页
virtualData['Anniversary2020/mall'] = function(args)
    local data = {
        products  = {},
    }

    local MALL_MAX_LEVEL = CONF.ANNIV2020.MALL_LEVEL:GetLength()
    local moneyConfs  = virtualData.getConf('goods', 'money')
    local moneyIdList = table.keys(moneyConfs)
    local createGoods = function(goodsData)
        return {
            productId        = virtualData.generateUuid(),    -- 商品id
            goodsId          = goodsData.goodsId,             -- 道具id
            goodsNum         = goodsData.num,                 -- 道具数量
            -- currency         = moneyIdList[_r(#moneyIdList)], -- 货币
            currency         = app.anniv2020Mgr:getShopCurrencyId(), -- 货币
            price            = goodsData.price or _r(99),     -- 价格
            leftPurchasedNum = goodsData.left or _r(0,5),     -- 剩余可购买次数
            stock            = _r(9),                         -- 可购买次数
            openLevel        = goodsData.level or _r(MALL_MAX_LEVEL), -- 开启等级
            activity         = checkint(goodsData.activity), -- 是否活动道具（0：否，1：是）
        }
    end
    
    for _, goodsData in ipairs(virtualData.createGoodsList(_r(6,12))) do
        table.insert(data.products, createGoods(goodsData))
    end
    table.insert(data.products, createGoods({
        goodsId  = app.anniv2020Mgr:getShopExpId(),
        num      = 100,
        level    = 1,
        activity = 1,
        left     = 15,
    }))
    table.insert(data.products, createGoods({
        goodsId  = app.anniv2020Mgr:getShopCurrencyId(),
        num      = 98765,
        level    = 1,
        price    = 0,
        left     = 3,
        activity = 1,
    }))
    table.insert(data.products, createGoods({
        goodsId  = 200268,
        num      = 98765,
        level    = 1,
        price    = 0,
        left     = 3,
        activity = 1,
    }))
    table.insert(data.products, createGoods({
        goodsId  = app.anniv2020Mgr:getPuzzleGoodsId(),
        num      = 321,
        level    = 1,
        activity = 1,
        left     = 5,
    }))
    for _, typeConf in pairs(CONF.ANNIV2020.HANG_MATERIAL_TYPE:GetAll()) do
        table.insert(data.products, createGoods({
            goodsId  = typeConf.goodsId,
            num      = _r(9,19),
            activity = 1,
        }))
    end
    virtualData.waterBarMallList_ = data
    return t2t(data)
end


-- 商城购买
virtualData['Anniversary2020/mallBuy'] = function(args)
    local data = {
        rewards = {}
    }
    local buyProductId  = checkint(args.productId)
    local buyProductNum = checkint(args.num)
    for _, productData in ipairs(virtualData.waterBarMallList_.products) do
        if productData.productId == buyProductId then
            local purchasedNum = (args.num == nil and productData.leftPurchasedNum or buyProductNum)
            productData.leftPurchasedNum = productData.leftPurchasedNum - purchasedNum
            
            table.insert(data.rewards, {
                goodsId = productData.goodsId,
                num     = productData.goodsNum * purchasedNum,
            })
            break
        end
    end
    return t2t(data)
end


-------------------------------------------------------------------------------
-- 领体力
-------------------------------------------------------------------------------

virtualData['Anniversary2020/drawJumpGridHp'] = function(args)
    local hpRecoverNum     = checkint(CONF.ANNIV2020.BASE_PARMS:GetValue('hpRecoverNum'))
    local hpRecoverSeconds = checkint(CONF.ANNIV2020.BASE_PARMS:GetValue('hpRecoverSeconds'))
    virtualData.anniv20_.jumpGridHp = virtualData.anniv20_.jumpGridHp + hpRecoverNum
    virtualData.anniv20_.jumpGridDrawLeftSeconds = hpRecoverSeconds
    return t2t({})
end


-------------------------------------------------------------------------------
-- 拼图游戏
-------------------------------------------------------------------------------

-- 拼图首页
virtualData['Anniversary2020/puzzle'] = function(args)
    if not virtualData.anniv20_puzzleGame then
        virtualData.anniv20_puzzleGame = {
            progress = virtualData.anniv20_.progress,  -- 最新拼图进度
        }
    end
    return t2t(virtualData.anniv20_puzzleGame)
end


-- 拼图提交
virtualData['Anniversary2020/puzzleCommit'] = function(args)
    -- consume goods
    local rewards = app.anniv2020Mgr:getPuzzleRewards()
    local goodsId = app.anniv2020Mgr:getPuzzleGoodsId()
    local haveNum = checkint(virtualData.playerData.backpack[tostring(goodsId)])
    virtualData.playerData.backpack[tostring(goodsId)] = haveNum - checkint(args.num)
    
    -- update progress
    local puzzleProgress = virtualData.anniv20_puzzleGame.progress + (args.num * 80)
    virtualData.anniv20_puzzleGame.progress = puzzleProgress
    virtualData.anniv20_.progress           = puzzleProgress

    -- check unlockNum
    local puzzleUnlockNum = 0
    for _, puzzleId in ipairs(CONF.ANNIV2020.PUZZLE_GAME:GetIdListDown()) do
        local puzzleConf = CONF.ANNIV2020.PUZZLE_GAME:GetValue(puzzleId)
        if puzzleProgress >= checkint(puzzleConf.num) then
            puzzleUnlockNum = puzzleId
            break
        end
    end

    local data = {
        progress = puzzleProgress,
        rewards  = {},
    }
    for index, reward in ipairs(rewards) do
        data.rewards[index] = {
            goodsId = reward.goodsId,
            num     = reward.num * checkint(args.num),
        }
    end
    return t2t(data)
end


-------------------------------------------------------------------------------
-- 挂机游戏
-------------------------------------------------------------------------------

-- 挂机首页
virtualData['Anniversary2020/hangHome'] = function(args)
    if not virtualData.anniv20_hangGame then
        virtualData.anniv20_hangGame = {
            hangLeftSeconds  = 0,  -- 挂机剩余秒数
            hangingMaterials = {}, -- 正在挂机的道具
            unlockedFormulas = {}, -- 已经解锁的配方
            drawnHangRewards = {}, -- 已经领取的挂机奖励ID
        }
    end
    return t2t(virtualData.anniv20_hangGame)
end


-- 挂机
virtualData['Anniversary2020/hang'] = function(args)
    virtualData.anniv20_hangGame.hangingMaterials = string.split2(args.materials, ',')
    virtualData.anniv20_hangGame.hangLeftSeconds  = 8--app.anniv2020Mgr:getHangCountdownTime()
    local data = {
        hangLeftSeconds = virtualData.anniv20_hangGame.hangLeftSeconds
    }
    return t2t(data)
end


-- 挂机领取奖励
virtualData['Anniversary2020/hangFinish'] = function(args)
    local unlockFormulaId     = 0
    local hangingMaterialId_1 = checkint(virtualData.anniv20_hangGame.hangingMaterials[1])
    local hangingMaterialId_2 = checkint(virtualData.anniv20_hangGame.hangingMaterials[2])
    local hangingMaterialId_3 = checkint(virtualData.anniv20_hangGame.hangingMaterials[3])
    for _, formulaConf in pairs(CONF.ANNIV2020.HANG_FORMULA:GetAll()) do
        local materialId_1 = checkint(formulaConf.material['1'])
        local materialId_2 = checkint(formulaConf.material['2'])
        local materialId_3 = checkint(formulaConf.material['3'])
        if hangingMaterialId_1 == materialId_1 and hangingMaterialId_2 == materialId_2 and hangingMaterialId_3 == materialId_3 then
            unlockFormulaId = formulaConf.id
            break
        end
    end
    
    -- 清空hong数据
    virtualData.anniv20_hangGame.hangingMaterials = {}
    virtualData.anniv20_hangGame.hangLeftSeconds  = 0
    if unlockFormulaId > 0 then
        table.insert(virtualData.anniv20_hangGame.unlockedFormulas, unlockFormulaId)
    end

    local rewardsConf = CONF.ANNIV2020.HANG_REWARDS:GetValue("1")
    local data = {
        rewards   = rewardsConf.rewards,
        formulaId = unlockFormulaId,
    }
    return t2t(data)
end


-- 挂机领取累计奖励
virtualData['Anniversary2020/hangDrawReward'] = function(args)
    local collectIndex = checkint(args.collectId)
    local rewardsConf  = CONF.ANNIV2020.HANG_REWARDS:GetValue("1")
    local collectsConf = checktable(rewardsConf.collects)

    if collectIndex > 0 then
        table.insert(virtualData.anniv20_hangGame.drawnHangRewards, collectIndex)
    end

    local data = {
        rewards = checktable(collectsConf[collectIndex]).rewards
    }
    return t2t(data)
end


-------------------------------------------------------------------------------
-- 探索游戏
-------------------------------------------------------------------------------

-- 爬塔主页
virtualData['Anniversary2020/explore'] = function(args)
    if not virtualData.anniv20_exploreGame_main then
        virtualData.anniv20_exploreGame_main = {
            explore   = {},
            teamState = {},
        }

        for _, entranceConf in pairs(CONF.ANNIV2020.EXPLORE_ENTRANCE:GetAll()) do
            local isExploring = checkint(entranceConf.id) == checkint(DEBUG_DEFINE.INIT_EXPLORE_ENTRANCE_ID)
            local isExplored  = checkint(entranceConf.id) < checkint(DEBUG_DEFINE.INIT_EXPLORE_ENTRANCE_ID)
            table.insert(virtualData.anniv20_exploreGame_main.explore, {
                exploreModuleId = entranceConf.id,        -- 探索id
                exploring       = isExploring and 1 or 0, -- 是否探索中（1：是，0：否）
                maxFloor        = isExplored and EXPLORE_FLOOR_MAX or (isExploring and _r(DEBUG_DEFINE.INIT_EXPLORE_FLOOR_NUM, EXPLORE_FLOOR_MAX-1) or 0),
                currentFloor    = isExploring and DEBUG_DEFINE.INIT_EXPLORE_FLOOR_NUM or 0,  -- 当前层数
            })
        end

        for cardUuid, cardData in pairs(virtualData.playerData.cards) do
            if _r(100) > 50 then
                virtualData.anniv20_exploreGame_main.teamState[tostring(cardUuid)] = {
                    hp     = _r(100) / 100,  -- 损失血量 百分比
                    energy = _r(100) / 100,  -- 增加能量 百分比
                }
            end
        end
    end
    return t2t(virtualData.anniv20_exploreGame_main)
end


-- 探索扫荡
virtualData['Anniversary2020/exploreSweep'] = function(args)
    local sweepConf = CONF.ANNIV2020.EXPLORE_SWEEP:GetValue(args.sweepId)
    local data = {
        rewards = sweepConf.rewards
    }
    return t2t(data)
end


-- 爬塔进入
virtualData['Anniversary2020/exploreEnter'] = function(args)
    if not virtualData.anniv20_exploreGame_home then

        local currentFloor    = 0
        local exploreModuleId = 0
        for _, exploreMainData in ipairs(virtualData.anniv20_exploreGame_main.explore) do
            if checkint(args.exploreModuleId) == checkint(exploreMainData.exploreModuleId) then
                if exploreMainData.exploring == 0 then
                    exploreMainData.exploring    = 1
                    exploreMainData.currentFloor = 1
                end
                exploreModuleId = checkint(args.exploreModuleId)
                currentFloor    = exploreMainData.currentFloor

            else
                exploreMainData.exploring = 0
            end
        end

        virtualData.anniv20_exploreGame_home = {
            stashRewards = {},               -- 暂存的奖励（n 到 +10 层之间的奖励会一直积累，每10层领一次）
            floor        = currentFloor - 1, -- 当前层（先-1 是因为 [nextFloor] 会+1）
            map          = {},               -- 地图数据（key：格子id）
            buffs        = {},               -- buff（30层内累积）
        }
        virtualData['Anniversary2020/exploreNextFloor']()
    end
    return t2t(virtualData.anniv20_exploreGame_home)
end


-- 探索放弃
virtualData['Anniversary2020/exploreGiveUp'] = function(args)
    -- reset mainData
    for _, exploreMainData in ipairs(virtualData.anniv20_exploreGame_main.explore) do
        if checkint(exploreMainData.exploring) == 1 then
            exploreMainData.exploring    = 0
            exploreMainData.currentFloor = 0
            break
        end
    end

    -- clean homeData
    virtualData.anniv20_exploreGame_home = nil

    return t2t({})
end


-- 探索下一层
virtualData['Anniversary2020/exploreNextFloor'] = function(args)
    -- add floor
    virtualData.anniv20_exploreGame_home.floor = virtualData.anniv20_exploreGame_home.floor + 1

    -- clear map
    virtualData.anniv20_exploreGame_home.map = {}

    -- update mainData.currentFloor
    local currentFloor    = virtualData.anniv20_exploreGame_home.floor
    local exploreModuleId = 0
    for _, exploreMainData in ipairs(virtualData.anniv20_exploreGame_main.explore) do
        if checkint(exploreMainData.exploring) == 1 then
            exploreModuleId = exploreMainData.exploring
            exploreMainData.currentFloor = currentFloor
            break
        end
    end

    local exploreTypeList = {
        EXPLORE_TYPE.MONSTER_NORMAL, -- 1 小怪
        EXPLORE_TYPE.MONSTER_ELITE,  -- 2 精英
        EXPLORE_TYPE.CHEST,          -- 5 宝箱
        EXPLORE_TYPE.OPTION,         -- 4 选项
        EXPLORE_TYPE.BUFF,           -- 6 buff
        EXPLORE_TYPE.EMPTY,          -- 7 空格
    }
    for row = 1, EXPLORE_MAP_ROWS do
        for col = 1, EXPLORE_MAP_COLS do
            local cellIndex   = tostring((row - 1) * EXPLORE_MAP_COLS + col)
            local typeIndex   = (cellIndex - 1) % #exploreTypeList + 1
            local exploreType = exploreTypeList[typeIndex]
            local typeConfs   = EXPLORE_TYPE_CONF[exploreType]
            local exploreConf = nil

            if (exploreType == EXPLORE_TYPE.MONSTER_NORMAL or
                exploreType == EXPLORE_TYPE.MONSTER_ELITE or
                exploreType == EXPLORE_TYPE.CHEST) then
                local confList = {}
                for _, conf in pairs(typeConfs:GetAll()) do
                    if checkint(conf.exploreModuleId) == exploreModuleId then
                        if currentFloor >= checkint(conf.floorMin) and currentFloor <= checkint(conf.floorMax) then
                            table.insert(confList, conf)
                        end
                    end
                end
                exploreConf = virtualData._rValue(confList, 1)[1]
                
            else
                if typeConfs then
                    local confId = virtualData._rValue(typeConfs:GetIdList(), 1)[1]
                    exploreConf  = typeConfs:GetValue(confId)
                end
            end
            
            virtualData.anniv20_exploreGame_home.map[cellIndex] = {
                refId    = exploreConf and exploreConf.id or 0,  -- 根据type到不同表 然后refId就是目标表的id
                type     = exploreType, -- 探索类型
                isPassed = 0,           -- 0 未通关，1 已通关
            }
        end
    end

    if currentFloor > 0 and currentFloor % EXPLORE_FLOOR_BOSS == 0 then
        local cellIndex = tostring(EXPLORE_MAP_COLS * EXPLORE_MAP_COLS)
        local cellData  = virtualData.anniv20_exploreGame_home.map[cellIndex]
        cellData.type   = EXPLORE_TYPE.BOSS
        cellData.refId  = 0
        
        for _, bossConf in pairs(CONF.ANNIV2020.EXPLORE_MONSTER_BOSS:GetAll()) do
            if checkint(bossConf.exploreModuleId) == exploreModuleId and checkint(bossConf.floor) == currentFloor then
                cellData.refId = bossConf.id
                break
            end
        end
    end

    local data = {
        floor = virtualData.anniv20_exploreGame_home.floor,
        map   = virtualData.anniv20_exploreGame_home.map
    }
    return t2t(data)
end


-- 探索最终奖励领取
virtualData['Anniversary2020/exploreDraw'] = function(args)
    local exploreRewards = virtualData.anniv20_exploreGame_home.stashRewards

    -- clear stashRewards
    virtualData.anniv20_exploreGame_home.stashRewards = {}

    local data = {
        rewards = exploreRewards
    }
    return t2t(data)
end


-- 探索 - 宝箱
virtualData['Anniversary2020/exploreChest'] = function(args)
    local mapData    = virtualData.anniv20_exploreGame_home.map[tostring(args.gridId)]
    mapData.isPassed = 1

    local chestConf = CONF.ANNIV2020.EXPLORE_CHEST:GetValue(mapData.refId)
    for _, rewardData in ipairs(chestConf.rewards) do
        table.insert(virtualData.anniv20_exploreGame_home.stashRewards, rewardData)
    end

    return t2t({})
end


-- 探索 - 答题
virtualData['Anniversary2020/exploreOption'] = function(args)
    local mapData    = virtualData.anniv20_exploreGame_home.map[tostring(args.gridId)]
    mapData.isPassed = 1

    local optionConf = CONF.ANNIV2020.EXPLORE_CHEST:GetValue(mapData.refId)
    if checkint(args.optionId) == 1 then
        for _, rewardData in ipairs(optionConf.rewards) do
            table.insert(virtualData.anniv20_exploreGame_home.stashRewards, rewardData)
        end
    end

    return t2t({})
end


-- 探索 - 战斗 开始/结算
virtualData['Anniversary2020/exploreQuestAt'] = function(args)
    return t2t({})
end
virtualData['Anniversary2020/exploreQuestGrade'] = function(args)
    local mapData    = virtualData.anniv20_exploreGame_home.map[tostring(args.gridId)]
    mapData.isPassed = checkint(args.isPassed)

    local questConfs = FOOD.ANNIV2020.EXPLORE_TYPE_CONF[mapData.type]
    local questConf  = questConfs and questConfs:GetValue(mapData.refId) or { rewards = {} }
    if mapData.isPassed == 1 then
        for _, rewardData in ipairs(questConf.rewards) do
            table.insert(virtualData.anniv20_exploreGame_home.stashRewards, rewardData)
        end

        -- update card
        for cardUuid, valueData in pairs(args.fightResult or {}) do
            virtualData.anniv20_exploreGame_main.teamState[tostring(cardUuid)] = {
                hp     = valueData.hp,     -- 血量
                energy = valueData.energy, -- 能量
            }
        end

        -- dead card
        for _, cardUuid in ipairs(string.split2(checkstr(args.deadCards), ',')) do
            virtualData.anniv20_exploreGame_main.teamState[tostring(cardUuid)] = {
                hp     = 1, -- 损失血量 100%
                energy = 0, -- 能量清零 0%
            }
        end
    end

    return t2t({})
end


-- 探索 - 空白
virtualData['Anniversary2020/exploreNone'] = function(args)
    local mapData    = virtualData.anniv20_exploreGame_home.map[tostring(args.gridId)]
    mapData.isPassed = 1

    return t2t({})
end


-- 探索 - BUFF
virtualData['Anniversary2020/exploreBuff'] = function(args)
    local mapData    = virtualData.anniv20_exploreGame_home.map[tostring(args.gridId)]
    mapData.isPassed = 1

    local buffConf    = CONF.ANNIV2020.EXPLORE_BUFF:GetValue(mapData.refId)
    local revivedCard = nil

    -- 战斗类buff
    if checkint(buffConf.type) == 1 then
        virtualData.anniv20_exploreGame_home.buffs = { buffConf.id }  -- 说是替换关系，所以实际只存在一个

    else
        -- 地图全开
        if buffConf.id == 3 then

        -- 复活卡牌
        elseif buffConf.id == 4 then
            for cardUuid, cardData in pairs(virtualData.anniv20_exploreGame_main.teamState) do
                if cardData.hp >= 1 then  -- 损失血量 100%
                    cardData.hp     = 0 -- 损失血量 0%
                    cardData.energy = 0 -- 能量清零 0%
                    revivedCard     = cardUuid
                    break
                end
            end

        -- 通关当前层
        elseif buffConf.id == 5 then

        end
    end

    local data = {
        plAyerCardId = revivedCard,  -- 如果是随机复活，那么返回卡牌自增ID
    }
    return t2t(data)
end
