--[[
 * author : kaishiqi
 * descpt : 关于 水吧数据 的本地模拟
]]
virtualData = virtualData or {}

local _r  = virtualData._r
local j2t = virtualData.j2t
local t2t = virtualData.t2t


local DebugDefines = {
    openStatus   = 2, -- 营业状态（0：随机，1:营业中 2:打烊中）
    showBusiness = 0, -- 营业结算（0：不结算，1：结算）
}

-- 水吧 主页
virtualData['Bar/home'] = function(args)
    if not virtualData.waterBar_ then
        virtualData.waterBar_ = {
            status                   = 0,  -- 状态 1:营业中 2:打烊中
            leftSeconds              = 0,  -- 当前状态剩余秒数
            businessRewards          = {}, -- 昨日收入（有值就弹奖励）
            yesterdayExpire          = {}, -- 昨日过期账目
            yesterdayBill            = {}, -- 昨日营业账目
            drinks                   = {}, -- 拥有的饮品 (key: 道具ID, value:数量
            onShelfDrinks            = {}, -- 上架的饮品 (key: 道具ID, value:数量
            materials                = {}, -- 食材      (key: 道具ID, value:数量
            formulas                 = {}, -- 已开发的配方
            activityFormulas         = {}, -- 活动配方列表
            customers                = {}, -- 客人
            serveCustomers           = {}, -- 当前找到的客人
            currentScheduleCustomers = {}, -- 当前排期的客人
        }

        -------------------------------------------------
        do
            local allDrinkIdList = CONF.BAR.DRINK:GetIdList()
            
            -- yesterdayExpire : list
            for index, drinkId in ipairs(virtualData._rValue(allDrinkIdList, _r(20))) do
                virtualData.waterBar_.yesterdayExpire[index] = {
                    goodsId = drinkId,
                    num = _r(9)
                }
            end

            -- yesterdayBill : list
            local customerIdList = CONF.BAR.CUSTOMER:GetIdList()
            for index = 1, _r(1,10) do
                virtualData.waterBar_.yesterdayBill[index] = {
                    customerId = customerIdList[_r(#customerIdList)],  -- 客人id
                    rewards    = virtualData.createGoodsList(_r(1,3)), -- 奖励物品
                    consume    = {}, -- 消耗物品
                }
                local consumeDrinIdList = virtualData._rValue(allDrinkIdList, _r(1,5))
                for _, drinkId in ipairs(consumeDrinIdList) do
                    table.insert(virtualData.waterBar_.yesterdayBill[index].consume, {goodsId = drinkId, num = _r(9)})
                end
            end
    
            -- businessRewards : map
            if DebugDefines.showBusiness > 0 then
                virtualData.waterBar_.businessRewards = {
                    rewards                = {}, -- map  key:客人ID，value:奖励list
                    customerFrequencyPoint = {}, -- map  客人增加的熟客值, key:客人ID, value:增加的熟客值
                }
                for _, customerConf in pairs(CONF.BAR.CUSTOMER:GetAll()) do
                    if _r(100) > 80 then
                        virtualData.waterBar_.businessRewards.rewards[tostring(customerConf.id)] = virtualData.createGoodsList(_r(1,3))
                    end
                    virtualData.waterBar_.businessRewards.customerFrequencyPoint[tostring(customerConf.id)] = _r(999)
                end
            end
        end
        -------------------------------------------------
        do
            -- material : map
            for _, materialConf in pairs(CONF.BAR.MATERIAL:GetAll()) do
                if _r(100) > 50 then
                    virtualData.waterBar_.materials[tostring(materialConf.id)] = _r(99)
                end
            end
        end
        -------------------------------------------------
        do
            -- drinks : map
            for _, drinkConf in pairs(CONF.BAR.DRINK:GetAll()) do
                local probability = 97
                if WaterBarUtils.GetDrinkType(drinkConf.id) == FOOD.WATER_BAR.DRINK_TYPE.SOFT then
                    probability = 50
                end
                if _r(100) > probability then
                    virtualData.waterBar_.drinks[tostring(drinkConf.id)] = _r(1,20)
                end
            end
    
            -- onShelfDrinks : map
            for drinkId, drinkNum in pairs(virtualData.waterBar_.drinks) do
                if _r(100) > 70 then
                    local shelfDrinkNum = _r(drinkNum)
                    virtualData.waterBar_.onShelfDrinks[tostring(drinkId)] = shelfDrinkNum
                    virtualData.waterBar_.drinks[tostring(drinkId)] = virtualData.waterBar_.drinks[tostring(drinkId)] - shelfDrinkNum
                end
            end
        end
        -------------------------------------------------
        do
            -- formulas : list
            for _, formulaConf in pairs(CONF.BAR.FORMULA:GetAll()) do
                if _r(100) > 50 then
                    table.insert(virtualData.waterBar_.formulas, {
                        formulaId = formulaConf.id,                        -- 配方id
                        like      = _r(0,1),                               -- 喜爱（0：不喜，1：喜爱）
                        madeStars = virtualData._rValue({0,1,2,3}, _r(0,FOOD.WATER_BAR.DEFINE.FORMULA_STAR_MAX)), -- 做过的星级
                    })
                end
            end
    
            -- activityFormulas : list
        end
        -------------------------------------------------
        do
            -- customers : list
            for _, customerConf in pairs(CONF.BAR.CUSTOMER:GetAll()) do
                if _r(100) > 50 then
                    local pointRewards  = {}
                    local frequencyConf = CONF.BAR.CUSTOMER_FREQUENCY_POINT:GetValue(customerConf.id)
                    for pointKey, pointConf in pairs(frequencyConf) do
                        if _r(100) > 50 then
                            table.insert(pointRewards, pointKey)
                        end
                    end
                    table.insert(virtualData.waterBar_.customers, {
                        customerId            = customerConf.id, -- 客人id
                        frequencyPoint        = _r(1000),        -- 熟客值
                        frequencyPointRewards = pointRewards,    -- 已领取的熟客奖励id
                    })
                end
            end
    
            -- serveCustomers : list
            local serveCustomerList = virtualData._rValue(CONF.BAR.CUSTOMER:GetIdList(), _r(0,5))
            for index, customerId in ipairs(serveCustomerList) do
                local customerConf = CONF.BAR.CUSTOMER:GetValue(customerId)
                virtualData.waterBar_.serveCustomers[index] = {
                    customerId = customerId,
                    storyId    = customerConf.story[_r(#customerConf.story)],
                }
            end
    
            -- currentScheduleCustomers : list
            for _, customerConf in pairs(CONF.BAR.CUSTOMER:GetAll()) do
                if _r(100) > 90 then
                    table.insert(virtualData.waterBar_.currentScheduleCustomers, customerConf.id)
                end
            end
        end
        
    end

    virtualData.waterBar_.status      = DebugDefines.openStatus == 0 and _r(1,2) or DebugDefines.openStatus
    virtualData.waterBar_.leftSeconds = _r(999)
    return t2t(virtualData.waterBar_)
end


-------------------------------------------------------------------------------
-- 水吧市场
-------------------------------------------------------------------------------

-- 市场主页
virtualData['Bar/market'] = function(args)
    local data = {
        products               = {},      -- 商品列表
        refreshDiamond         = _r(99),  -- 刷新钻石单价
        refreshLeftTimes       = _r(9),   -- 手动刷新剩余次数
        nextRefreshLeftSeconds = _r(99),  -- 下一次自动刷新剩余秒数
    }
    
    local moneyConfs  = virtualData.getConf('goods', 'money')
    local moneyIdList = table.keys(moneyConfs)
    for _, materialConf in pairs(CONF.BAR.MATERIAL:GetAll()) do
        local priceNum   = _r(99)
        -- local currencyId = FOOD.GOODS.DEFINE.WATER_BAR_CURRENCY_ID -- 货币
        local currencyId = moneyIdList[_r(#moneyIdList)] -- 货币
        table.insert(data.products, {
            productId = virtualData.generateUuid(),          -- 商品id
            currency  = currencyId,                          -- 货币
            goodsId   = materialConf.id,                     -- 道具id
            goodsNum  = _r(99),                              -- 道具数量
            price     = priceNum,                            -- 价格
            purchased = _r(0,1),                             -- 购买状态（0:未购买 1:已购买）
            sale      = {[tostring(currencyId)] = priceNum}, -- 多价格（key为货币, value为价格）
        })
    end
    virtualData.waterBarMarketList_ = data
    return t2t(data)
end


-- 市场刷新
virtualData['Bar/marketRefresh'] = function(args)
    virtualData['Bar/market']()
    local data = {
        gold     = virtualData.playerData.gold,
        diamond  = virtualData.playerData.diamond,
        products = virtualData.waterBarMarketList_.products,
    }
    return t2t(data)
end


-- 市场购买
virtualData['Bar/marketBuy'] = function(args)
    local data = {
        rewards = {}
    }
    for _, buyProductId in ipairs(string.split2(args.productIds, ',')) do
        for _, productData in ipairs(virtualData.waterBarMarketList_.products) do
            if productData.productId == checkint(buyProductId) then
                table.insert(data.rewards, {
                    goodsId = productData.goodsId,
                    num     = productData.goodsNum,
                })
                break
            end
        end
    end
    return t2t(data)
end


-------------------------------------------------------------------------------
-- 水吧商城
-------------------------------------------------------------------------------

-- 商城主页
virtualData['Bar/mall'] = function(args)
    local data = {
        products               = {},      -- 商品列表
        nextRefreshLeftSeconds = _r(99),  -- 下一次自动刷新剩余秒数
    }
    
    local moneyConfs  = virtualData.getConf('goods', 'money')
    local moneyIdList = table.keys(moneyConfs)
    for _, goodsData in ipairs(virtualData.createGoodsList(_r(6,12))) do
        table.insert(data.products, {
            productId        = virtualData.generateUuid(),    -- 商品id
            goodsId          = goodsData.goodsId,             -- 道具id
            goodsNum         = goodsData.num,                 -- 道具数量
            -- currency         = moneyIdList[_r(#moneyIdList)], -- 货币
            currency         = FOOD.GOODS.DEFINE.WATER_BAR_CURRENCY_ID, -- 货币
            price            = _r(99),                        -- 价格
            leftPurchasedNum = _r(0,5),                         -- 剩余可购买次数
            stock            = _r(9),                         -- 可购买次数
            openLevel        = _r(9),                         -- 开启等级
        })
    end
    virtualData.waterBarMallList_ = data
    return t2t(data)
end


-- 商城购买
virtualData['Bar/mallBuy'] = function(args)
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


-- 商城购买
virtualData['Bar/mallBuyMulti'] = function(args)
    local data = {
        rewards = {}
    }
    for _, productId in ipairs(string.split2(args.products, ',')) do
        local mallBuyData = virtualData['Bar/mallBuy']({productId = productId})
        for _, rewardData in ipairs(mallBuyData.data.rewards) do
            table.insert(data.rewards, rewardData)
        end
    end
    return t2t(data)
end


-------------------------------------------------------------------------------
-- 饮品上/下架
-------------------------------------------------------------------------------

virtualData['Bar/onShelfDrink'] = function(args)
    local onDrinkMap = json.decode(args.drinks)
    for drinkId, drinkNum in pairs(onDrinkMap) do
        virtualData.waterBar_.drinks[drinkId] = virtualData.waterBar_.drinks[drinkId] - drinkNum
        if virtualData.waterBar_.drinks[drinkId] <= 0 then
            virtualData.waterBar_.drinks[drinkId] = nil
        end
        virtualData.waterBar_.onShelfDrinks[drinkId] = checkint(virtualData.waterBar_.onShelfDrinks[drinkId]) + drinkNum
    end
    return t2t({})
end


virtualData['Bar/offShelfDrink'] = function(args)
    local offDrinkMap = json.decode(args.drinks)
    for drinkId, drinkNum in pairs(offDrinkMap) do
        virtualData.waterBar_.onShelfDrinks[drinkId] = virtualData.waterBar_.onShelfDrinks[drinkId] - drinkNum
        if virtualData.waterBar_.onShelfDrinks[drinkId] <= 0 then
            virtualData.waterBar_.onShelfDrinks[drinkId] = nil
        end
        virtualData.waterBar_.drinks[drinkId] = checkint(virtualData.waterBar_.drinks[drinkId]) + drinkNum
    end
    return t2t({})
end


-------------------------------------------------------------------------------
-- 调酒相关
-------------------------------------------------------------------------------

-- （调酒）
virtualData['Bar/bartend'] = function(args)
    for _, materialList in pairs(json.decode(checkstr(args.material)) or {}) do
        for materialId, materialNum in ipairs(materialList) do
            virtualData.waterBar_.materials[materialId] = virtualData.waterBar_.materials[materialId] - materialNum
        end
    end

    local drinkId  = nil
    local drinkNum = 1
    if args.formulaId then
        local formulaConf = CONF.BAR.FORMULA:GetValue(args.formulaId)
        drinkId = formulaConf.drinks[args.method]
    end
    if not drinkId then
        drinkId = virtualData._rValue(CONF.BAR.DRINK:GetIdList(), 1)[1]
    end
    virtualData.waterBar_.drinks[tostring(drinkId)] = checkint(virtualData.waterBar_.drinks[tostring(drinkId)]) + drinkNum

    local data = {
        rewards = {
            {goodsId = drinkId, num = drinkNum}
        }
    }
    return t2t(data)
end


-- （制作）
virtualData['Bar/make'] = function(args)
    -- appedn drink
    virtualData.waterBar_.drinks[tostring(args.drinkId)] = checkint(virtualData.waterBar_.drinks[tostring(args.drinkId)]) + checkint(args.num)

    -- consume material 
    for materialId, materialNum in pairs(json.decode(checkstr(args.material)) or {}) do
        virtualData.waterBar_.materials[materialId] = virtualData.waterBar_.materials[materialId] - materialNum
    end

    local data = {
        rewards = {
            {goodsId = args.drinkId, num = args.num}
        }
    }
    return t2t(data)
end


-- （配方）
virtualData['Bar/formula'] = function(args)
    local formulaConf = CONF.BAR.FORMULA:GetValue(args.formulaId)
    local data = {
        formula = {}
    }
    for index, drinkId in ipairs(formulaConf.drinks or {}) do
        if _r(100) > 75 then
            local materialDatas = {}
            for _, materialId in ipairs(formulaConf.materials or {}) do
                table.insert(materialDatas, {goodsid = materialId, num = _r(9)})
            end 
            table.insert(data.formula, {
                star     = index - 1,     -- 星级
                drinkId  = drinkId,       -- 饮品id
                material = materialDatas, -- 食材消耗
            })
        end
    end
    return t2t(data)
end


-------------------------------------------------------------------------------
-- 水吧其他
-------------------------------------------------------------------------------

-- 水吧升级
virtualData['Bar/levelUp'] = function(args)
    local currentLevel = virtualData.playerData.barLevel
    local maxBarLevel  = CONF.BAR.LEVEL_UP:GetLength()
    local nextBarLevel = math.min(currentLevel + 1, maxBarLevel)
    local nextBarConf  = CONF.BAR.LEVEL_UP:GetValue(nextBarLevel)
    if currentLevel < maxBarLevel then
        local costPopularity = checkint(nextBarConf.barPopularity)
        virtualData.playerData.barLevel      = nextBarLevel
        virtualData.playerData.barPopularity = virtualData.playerData.barPopularity - costPopularity
    end

    local data = {
        newLevel         = virtualData.playerData.barLevel,
        newBarPopularity = virtualData.playerData.barPopularity,
    }
    return t2t(data)
end


-- 配方 喜爱/不喜爱
virtualData['Bar/formulaLike'] = function(args)
    for _, formulaId in ipairs(string.split2(args.formulaIds, ',')) do
        for _, formulaData in ipairs(virtualData.waterBar_.formulas) do
            if checkint(formulaData.formulaId) == checkint(formulaId) then
                formulaData.like = (formulaData.like == 0) and 1 or 0
                break
            end
        end
    end
    return t2t({})
end


-- 熟客奖励领取
virtualData['Bar/drawCustomerFrequencyPoint'] = function(args)
    for index, customerData in ipairs(virtualData.waterBar_.customers) do
        if checkint(customerData.customerId) == checkint(args.customerId) then
            table.insert(customerData.frequencyPointRewards, tostring(args.rewardId))
            break
        end
    end
    local customerPointConf = CONF.BAR.CUSTOMER_FREQUENCY_POINT:GetValue(args.customerId)
    local data = {
        rewards = customerPointConf[tostring(args.rewardId)].rewards
    }
    return t2t(data)
end


-- 客人解锁剧情列表
virtualData['Bar/customerUnlockStoryList'] = function(args)
    local data = {
        customerMap = {}
    }
    for _, customerConf in pairs(CONF.BAR.CUSTOMER:GetAll()) do
        local unlockStoryList = {}
        for index, storyId in ipairs(customerConf.story) do
            if _r(100) > 50 then
                table.insert(unlockStoryList, storyId)
            end
        end
        data.customerMap[tostring(customerConf.id)] = unlockStoryList
    end
    return t2t(data)
end
