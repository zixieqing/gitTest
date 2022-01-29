--[[
 * author : kaishiqi
 * descpt : 关于 餐厅数据 的本地模拟
]]
virtualData = virtualData or {}

local _r  = virtualData._r
local j2t = virtualData.j2t
local t2t = virtualData.t2t

local avatarConfs          = virtualData.getConf('restaurant', 'avatar')
local avatarLocationConfs  = virtualData.getConf('restaurant', 'avatarLocation')
local employeeConfs        = virtualData.getConf('restaurant', 'employee')
local customerConfs        = virtualData.getConf('restaurant', 'customer')
local sCustomerConfs       = virtualData.getConf('restaurant', 'specialCustomer')
local locationConfs        = virtualData.getConf('restaurant', 'avatarLocation')
local taskConfs            = virtualData.getConf('restaurant', 'task')
local taskTypeConfs        = virtualData.getConf('restaurant', 'taskType')
local questEventConfs      = virtualData.getConf('restaurant', 'questEvent')
local cookingRecipeConfs   = virtualData.getConf('restaurant', 'recipe')
local restaurantLevelConfs = virtualData.getConf('restaurant', 'levelUp')

local AVATAR_SAFE_RECT   = DRAG_AREA_RECT
local WAITER_INDEX_BEGAN = 4
local WAITER_INDEX_ENDED = 7
local BUG_INDEX_BEGAN    = 1
local BUG_INDEX_ENDED    = 6

local avatarIdMap = {}
for _, avatarConf in pairs(avatarConfs) do
    local avatarType = checkint(avatarConf.mainType)
    avatarIdMap[tostring(avatarType)] = avatarIdMap[tostring(avatarType)] or {}
    table.insert(avatarIdMap[tostring(avatarType)], avatarConf.id)
end

virtualData.restaurant = {}


virtualData.restaurant.appendCustomer = function()
    local customerKeys = table.keys(customerConfs)
    local customerConf = customerConfs[tostring(customerKeys[_r(#customerKeys)])]

    local emptySeatList = {}
    for seatKey, customerData in pairs(virtualData.restaurant_.seat) do
        if not customerData.customerUuid then
            table.insert(emptySeatList, seatKey)
        end
    end
    
    local nextCustomer = _r(30)
    local seatKey      = nil
    local customerData     = {
        customerUuid      = virtualData.generateUuid(),
        customerId        = customerConf.id,
        isSpecialCustomer = 0,  -- 1:特殊客人 0:普通客人
        isEating          = 0,  -- 1:正在吃饭 0:等待招待
        leftSeconds       = _r(30),
    }
    if #emptySeatList > 0 then
        -- add customer
        seatKey = emptySeatList[_r(#emptySeatList)]
        virtualData.restaurant_.seat[seatKey] = customerData
    else
        table.insert(virtualData.restaurant_.customerWaitingSeat, customerData)
    end
    virtualData.restaurant_.nextCustomerArrivalLeftSeconds = nextCustomer
    
    -- socket data
    local cmdData = {
        customerId                     = customerData.customerId,        -- 客人类型
        customerUuid                   = customerData.customerUuid,      -- 客人的唯一ID
        isSpecialCustomer              = customerData.isSpecialCustomer, -- 0:普通客人, 1:特殊客人
        leftSeconds                    = customerData.leftSeconds,       -- 离开的剩余秒数
        seatId                         = seatKey,                        -- 座位的唯一ID
        nextCustomerArrivalLeftSeconds = nextCustomer,                   -- 下一个客人到达剩余秒数
    }
    return cmdData
end
virtualData.restaurant.removeCustomer = function(seatId)
    local customerData = virtualData.restaurant_.seat[tostring(seatId)]
    if customerData then
        -- clean old customer
        customerData.customerUuid = nil
        customerData.customerId   = nil
        customerData.questEventId = nil
        customerData.leftSeconds  = -1
        customerData.isEating     = 0

        if #virtualData.restaurant_.customerWaitingSeat > 0 then
            -- popup top customer to seat
            local customerData = table.remove(virtualData.restaurant_.customerWaitingSeat, 1)
            virtualData.restaurant_.seat[seatId] = customerData
        end
    else
        table.remove(virtualData.restaurant_.customerWaitingSeat, 1)
    end
end


virtualData.restaurant.appendAvatar = function(goodsId, pos)
    -- append location
    local avatarData = {
        id       = virtualData.generateUuid(),
        goodsId  = checkint(goodsId),
        location = pos or cc.p(0,0)
    }
    virtualData.restaurant_.location[tostring(avatarData.id)] = avatarData

    -- init seat data
    local avatarConf = avatarConfs[tostring(avatarData.goodsId)] or {}
    local avatarType = checkint(avatarConf.mainType)
    if avatarType == RESTAURANT_AVATAR_TYPE.CHAIR then
        local locationConf = locationConfs[tostring(avatarData.goodsId)] or {}
        for _, additionData in ipairs(locationConf.additions or {}) do
            local additionId   = checkint(string.split(additionData.additionId, '_')[2])
            local seatKey      = string.fmt('%1_%2', avatarData.id, additionId)
            local customerData = {
                customerUuid      = nil, -- 客人的唯一ID, nil 表示没人
                customerId        = nil, -- 客人ID
                isSpecialCustomer = nil, -- 1:特殊客人 0:普通客人
                leftSeconds       = -1,  -- 离开的剩余秒数
                questEventId      = nil, -- 霸王餐ID
                isEating          = nil, -- 1:正在吃饭 0:等待招待
                recipeId          = nil, -- 菜id
                recipeNum         = nil, -- 菜数量
            }
            virtualData.restaurant_.seat[seatKey] = customerData
        end
    end
    local cmdData = {
        goodsUuid = avatarData.id
    }
    return cmdData
end
virtualData.restaurant.removeAvatar = function(goodsId, goodsUuid)
    local avatarData = virtualData.restaurant_.location[tostring(goodsUuid)] or {}
    virtualData.restaurant_.location[tostring(goodsUuid)] = nil

    -- clean seat data
    local avatarConf = avatarConfs[tostring(goodsId)] or {}
    local avatarType = checkint(avatarConf.mainType)
    if avatarType == RESTAURANT_AVATAR_TYPE.CHAIR then
        local locationConf = locationConfs[tostring(avatarData.goodsId)] or {}
        for _, additionData in ipairs(locationConf.additions or {}) do
            local additionId = checkint(string.split(additionData.additionId, '_')[2])
            local seatKey  = string.fmt('%1_%2', avatarData.id, additionId)
            virtualData.restaurant_.seat[seatKey] = nil
        end
    end
end
virtualData.restaurant.movedAvatar = function(goodsId, goodsUuid, x, y)
    local avatarData = virtualData.restaurant_.location[tostring(goodsUuid)]
    if avatarData then
        avatarData.location = cc.p(x, y)
    end
end


virtualData.restaurant.switchEmployee = function(employeeId, playerCardId)
    local cardUuid = playerCardId
    local cardData = virtualData.playerData.cards[tostring(cardUuid)]
    if cardData then
        if employeeId == 1 then
            virtualData.playerData.defaultCardId = cardUuid
        end
        virtualData.playerData.employee[tostring(employeeId)] = cardUuid
        virtualData.restaurant_.waiter[tostring(cardUuid)] = {vigour = _r(100) > 50 and _r(checkint(cardData.vigour)) or 0}
    end
    local cmdData = {
        vigour = checkint(checktable(virtualData.restaurant_.waiter[tostring(cardUuid)]).vigour)
    }
    return cmdData
end
virtualData.restaurant.unlockEmployee = function(employeeId)
    table.insert(virtualData.restaurant_.employee, employeeId)
end


virtualData.restaurant.getSeatInfo = function(seats)
    local seatIdList = string.split(checkstr(seats), ',')
    local cmdData    = {}
    for i, seatId in ipairs(seatIdList) do
        local customerData = virtualData.restaurant_.seat[seatId]
        if customerData then
            table.insert(cmdData, {
                customerUuid = customerData.customerUuid,
                leftSeconds  = customerData.leftSeconds,
                seatId       = seatId,
            })
        end
    end
    return cmdData
end


virtualData.restaurant.createAvatarDress = function(restaurantLevel)
    local avatarList = {}
    local avatarRect = {}
    local avatarData = function(goodsId, x, y)
        return {goodsId = goodsId, x = checkint(x), y = checkint(y)}
    end

    local addAvatar = function(avatarType, num)
        local avatarIdList = avatarIdMap[tostring(avatarType)]
        if #avatarIdList > 0 then
            for i=1, num do
                if avatarType == RESTAURANT_AVATAR_TYPE.CHAIR then
                    local avatarId = avatarIdList[_r(#avatarIdList)]
                    local locaConf = avatarLocationConfs[tostring(avatarId)]
                    local seatCols = math.ceil(math.sqrt(num))
                    local seatRows = math.ceil(num / seatCols)
                    local colSpace = math.floor(AVATAR_SAFE_RECT.width / seatCols)
                    local rowSpace = math.floor(AVATAR_SAFE_RECT.height / seatRows)
                    local seatCol  = (i - 1) % seatCols + 1
                    local seatRow  = math.ceil(i / seatCols)
                    local avatarW  = checkint(locaConf.collisionBoxWidth)
                    local avatarH  = checkint(locaConf.collisionBoxLength)
                    local avatarX  = AVATAR_SAFE_RECT.x + (seatCol - 0.5) * colSpace - avatarW / 2
                    local avatarY  = AVATAR_SAFE_RECT.y + (seatRow - 0.5) * rowSpace - avatarH / 2
                    table.insert(avatarList, avatarData(avatarId, avatarX, avatarY))
                    table.insert(avatarRect, cc.rect(avatarX, avatarY, avatarW, avatarH))

                elseif avatarType == RESTAURANT_AVATAR_TYPE.DECORATION then
                    local avatarId = avatarIdList[_r(#avatarIdList)]
                    local locaConf = avatarLocationConfs[tostring(avatarId)]
                    local avatarW  = checkint(locaConf.collisionBoxWidth)
                    local avatarH  = checkint(locaConf.collisionBoxLength)
                    local loopNum  = 50
                    local appended = false
                    while loopNum > 0 and not appended do
                        local avatarX = AVATAR_SAFE_RECT.x + _r(AVATAR_SAFE_RECT.width - avatarW)
                        local avatarY = AVATAR_SAFE_RECT.y + _r(AVATAR_SAFE_RECT.height - avatarH)
                        local avtRect = cc.rect(avatarX, avatarY, avatarW, avatarH)
                        local isCross = false
                        for _, rect in ipairs(avatarRect) do
                            if cc.rectIntersectsRect(rect, avtRect) then
                                isCross = true
                                break
                            end
                        end
                        if not isCross then
                            table.insert(avatarList, avatarData(avatarId, avatarX, avatarY))
                            table.insert(avatarRect, avtRect)
                            appended = true
                        end
                        loopNum = loopNum - 1
                    end

                else
                    table.insert(avatarList, avatarData(avatarIdList[_r(#avatarIdList)]))
                end
            end
        end
    end

    addAvatar(RESTAURANT_AVATAR_TYPE.WALL, 1)
    addAvatar(RESTAURANT_AVATAR_TYPE.FLOOR, 1)

    local resLevel  = checkint(restaurantLevel) > 0 and restaurantLevel or _r(table.nums(restaurantLevelConfs))
    local levelConf = restaurantLevelConfs[tostring(resLevel)] or {}
    local seatNum   = checkint(levelConf.seatNum)
    addAvatar(RESTAURANT_AVATAR_TYPE.CHAIR, seatNum)

    addAvatar(RESTAURANT_AVATAR_TYPE.DECORATION, 20 - seatNum)

    if _r(100) > 50 then
        addAvatar(RESTAURANT_AVATAR_TYPE.CEILING, 1)
    end

    return avatarList
end


virtualData.restaurant.cleanAllAvatar = function()
    local cmdData = {
        cleanList = {}
    }
    for goodsUuid, avatarData in pairs(virtualData.restaurant_.location or {}) do
        local goodsId    = avatarData.goodsId
        local avatarConf = avatarConfs[tostring(goodsId)] or {}
        local avatarType = checkint(avatarConf.mainType)
        if avatarType ~= RESTAURANT_AVATAR_TYPE.WALL and avatarType ~= RESTAURANT_AVATAR_TYPE.FLOOR then

            if avatarType == RESTAURANT_AVATAR_TYPE.CHAIR then
                local isSpecialSeat = false
                local locationConf  = locationConfs[tostring(goodsId)] or {}
                for _, additionData in ipairs(locationConf.additions or {}) do
                    local additionId = checkint(string.split(additionData.additionId, '_')[2])
                    local seatKey  = string.fmt('%1_%2', avatarData.id, additionId)
                    local seatData = virtualData.restaurant_.seat[seatKey] or {}
                    if checkint(seatData.questEventId) > 0 then
                        isSpecialSeat = true
                        break
                    end
                end
                if not isSpecialSeat then
                    table.insert(cmdData.cleanList, {goodsId = goodsId, goodsUuid = goodsUuid})
                end

            else
                table.insert(cmdData.cleanList, {goodsId = goodsId, goodsUuid = goodsUuid})
                
            end
        end
    end
    for _, cleanData in ipairs(cmdData.cleanList) do
        virtualData.restaurant.removeAvatar(cleanData.goodsId, cleanData.goodsUuid)
    end
    return cmdData
end


-- 餐厅首页
virtualData['Restaurant/home'] = function(args)
    if not virtualData.restaurant_ then
        virtualData.restaurant_ = {
            traffic                        = _r(999), -- 客流量
            bill                           = {},      -- 账目
            todayPopularity                = _r(99),  -- 今日获得的知名度
            lastPopularityRankRewards      = nil,     -- 上周知名度排名奖励
            myLastPopularityRank           = _r(100), -- 上周我的知名度排名
            myLastPopularityScore          = _r(999), -- 上周我的知名度
            events                         = {},      -- 餐厅事件
            seat                           = {},      -- 座位,      key为凳子ID
            location                       = {},      -- 装饰物,     key未道具的唯一ID
            unlockAvatars                  = {},      -- 已经解锁的avatar
            waiter                         = {},      -- key为服务员ID
            employee                       = {},      -- 已解锁的雇员位置,  value为员工ID
            customerWaitingSeat            = {},      -- 等待座位的客人
            nextCustomerArrivalLeftSeconds = 0,       -- 下一个客人到达剩余秒数
            nextRestaurantTaskLeftSeconds  = 3,       -- 下一个餐厅任务剩余秒数
            specialCustomerTask            = 0,       -- 特殊客人任务
            restaurantTasks                = {},      -- 餐厅任务,    返回长度>1表示需要选择，否则表示已经选好了
            offlineRewards                 = {},      -- 离线奖励
            offlineRecipe                  = {},      -- 离线消耗的菜谱, key为菜谱ID，value为数量
            recipe                         = {},      -- key为菜谱ID，value为数量
            recipeCooking                  = {},      -- 厨师做菜数据 （key为卡牌Id）
            bug                            = {},      -- 虫子区域ID
            hasBugHelp                     = 0,       -- 虫子求助 0:未求助 1:已求助
            hasEventHelp                   = 0,       -- 霸王餐求助 1:已求助 0:未求助
        }

        -- update event
        local eventConfs = table.values(virtualData.getConf('restaurant', 'event'))
        for i = 1, 2 do
            local eventConf = table.remove(eventConfs, _r(#eventConfs))
            local eventData = {
                eventId   = eventConf.id,
                startTime = os.time() - _r(300),
                endTime   = os.time() + _r(10),
                status    = 1,
            }
            eventData.leftSeconds = eventData.endTime - os.time()
            table.insert(virtualData.restaurant_.events, eventData)
        end
        
        -- init avatar
        local avatarInitConfs = virtualData.getConf('restaurant', 'avatarInit')
        for i,v in ipairs(avatarInitConfs) do
            virtualData.restaurant.appendAvatar(v.goodsId, cc.p(v.x, v.y))
        end

        -- update unlockAvatars
        for goodsId, goodsNum in pairs(virtualData.playerData.backpack) do
            if avatarConfs[tostring(goodsId)] ~= nil then
                table.insert(virtualData.restaurant_.unlockAvatars, checkint(goodsId))
            end
        end

        -- full customer
        local hasQuestEvent = false
        for seatKey, _ in pairs(virtualData.restaurant_.seat) do
            local customerKeys = table.keys(customerConfs)
            local customerConf = customerConfs[tostring(customerKeys[_r(#customerKeys)])]
            local customerData = {
                customerUuid   = virtualData.generateUuid(),
                customerId     = customerConf.id,
            }
            if hasQuestEvent then
                customerData.isEating     = _r(0,1)  -- 1:正在吃饭 0:等待招待
                customerData.leftSeconds  = _r(30)
                if customerData.isEating == 1 then
                    local recipeIdList    = table.keys(cookingRecipeConfs)
                    customerData.recipeId = recipeIdList[_r(#recipeIdList)]
                end
            else
                local questEventKeys      = table.keys(questEventConfs)
                local questEventConf      = questEventConfs[tostring(questEventKeys[_r(#questEventKeys)])]
                customerData.questEventId = questEventConf.id
                customerData.leftSeconds  = -1
                customerData.isEating     = 0
                hasQuestEvent = true
            end
            virtualData.restaurant_.seat[seatKey] = customerData
        end
        
        -- unlock all employee pos
        for k, employeeConf in pairs(employeeConfs) do
            virtualData.restaurant.unlockEmployee(employeeConf.id)
        end

        -- update waiter info
        for i = WAITER_INDEX_BEGAN, WAITER_INDEX_ENDED do
            local cardUuid = checkint(virtualData.playerData.employee[tostring(i)])
            virtualData.restaurant.switchEmployee(i, cardUuid)
        end

        -- bug list
        for i = BUG_INDEX_BEGAN, BUG_INDEX_ENDED do
            if _r(100) > 30 then
                table.insert(virtualData.restaurant_.bug, i)
            end
        end
    end
    return t2t(virtualData.restaurant_)
end


-- 餐厅升级
virtualData['Restaurant/levelUp'] = function(args)
    virtualData.playerData.restaurantLevel = virtualData.playerData.restaurantLevel + 1
    local data = {
        newLevel      = virtualData.playerData.restaurantLevel,
        newPopularity = 0,
        avatarRewards = {},
    }
    return t2t(data)
end


-- 获取任务
virtualData['Restaurant/restaurantTask'] = function(args)
    local taskDataList = {}
    local taskIdList   = table.keys(taskConfs)
    for i = 1,3 do
        local taskId = checkint(table.remove(taskIdList, _r(#taskIdList)))
        if taskId > 0 then
            local taskConf = taskConfs[tostring(taskId)]
            local taskType = checkint(taskConf.taskType)
            local taskData = {
                taskId    = checkint(taskConf.id),
                targetId  = {},
                targetNum = 0,
                progress  = 0,
            }
            -- 菜品id
            if taskType == 1 or taskType == 3 or taskType == 4 then
                local recipeIdList = table.keys(cookingRecipeConfs)
                local recipeId     = checkint(recipeIdList[_r(#recipeIdList)])
                local recipeConf   = cookingRecipeConfs[tostring(recipeId)] or {}
                taskData.targetId  = { checkint(recipeConf.id) }
                taskData.targetNum = _r(10)

            -- 菜系id
            elseif taskType == 5 or taskType == 6 then
                local recipeIdList = table.keys(cookingRecipeConfs)
                local recipeId     = checkint(recipeIdList[_r(#recipeIdList)])
                local recipeConf   = cookingRecipeConfs[tostring(recipeId)] or {}
                taskData.targetId  = { checkint(recipeConf.cookingStyleId) }
                taskData.targetNum = _r(10)

            -- 顾客type
            elseif taskType == 2 then
                local customerIdList = table.keys(customerConfs)
                local customerId     = checkint(customerIdList[_r(#customerIdList)])
                local customerConf   = customerConfs[tostring(customerId)] or {}
                taskData.targetId    = { checkint(customerConf.id) }
                taskData.targetNum   = 1

            -- 数量
            elseif taskType == 7 or taskType == 8 then
                taskData.targetNum = _r(3)
            end
            table.insert(taskDataList, taskData)
        end
    end
    virtualData.restaurant_.restaurantTasks               = taskDataList
    virtualData.restaurant_.nextRestaurantTaskLeftSeconds = 0
    local data = {
        restaurantTasks = virtualData.restaurant_.restaurantTasks
    }
    return t2t(data)
end
-- 餐厅任务选择
virtualData['Restaurant/chooseRestaurantTask'] = function(args)
    local taskDataList = {}
    for i, taskData in ipairs(virtualData.restaurant_.restaurantTasks or {}) do
        if checkint(taskData.taskId) == checkint(args.taskId) then
            taskDataList = { taskData }
            break
        end
    end
    virtualData.restaurant_.restaurantTasks = taskDataList
    return t2t({})
end
-- 餐厅任务取消
virtualData['Restaurant/cancelRestaurantTask'] = function(args)
    virtualData.restaurant_.nextRestaurantTaskLeftSeconds = 3
    local data = {
        nextRestaurantTaskLeftSeconds = virtualData.restaurant_.nextRestaurantTaskLeftSeconds
    }
    return t2t(data)
end


-- 霸王餐取消
virtualData['Restaurant/cancelQuest'] = function(args)
    return t2t({})
end
-- 霸王餐战斗
virtualData['Restaurant/questAt'] = function(args)
    local data = {
        maxSkillTimes      = 0,
        maxCritDamageTimes = 0
    }
    return t2t(data)
end
-- 霸王餐结算
virtualData['Restaurant/questGrade'] = function(args)
    -- clean quest customer
    for seatKey, customerData in pairs(virtualData.restaurant_.seat) do
        if checkint(customerData.questEventId) > 0 then
            virtualData.restaurant.removeCustomer(seatKey)
            break
        end
    end
    local data = {
        hp                = virtualData.playerData.hp,
        gold              = virtualData.playerData.gold,
        mainExp           = virtualData.playerData.mainExp,
        reward            = {},
        cardExp           = {},
        favorabilityCards = {}
    }
    return t2t(data)
end


-- 装饰解锁
virtualData['Restaurant/unlockAvatar'] = function(args)
    table.insert(virtualData.restaurant_.unlockAvatars, args.goodsId)
    return t2t({})
end
-- 装饰购买
virtualData['Restaurant/buyAvatar'] = function(args)
    virtualData.playerData.backpack[tostring(args.goodsId)] = checkint(virtualData.playerData.backpack[tostring(args.goodsId)]) + checkint(args.num)
    local data = {
        gold    = virtualData.playerData.gold,
        diamond = virtualData.playerData.diamond,
    }
    return t2t(data)
end


-- 好友餐厅
virtualData['Restaurant/friend'] = function(args)
    virtualData.friendRestaurant_ = virtualData.friendRestaurant_ or {}

    local friendRestaurantData = virtualData.friendRestaurant_[tostring(args.friendId)]
    if not friendRestaurantData then
        local customerKeys   = table.keys(customerConfs)
        local cardConfs      = virtualData.getConf('card', 'card')
        local cardKeys       = table.keys(cardConfs)
        friendRestaurantData = {
            seat                = {}, -- 座位数据, key为凳子ID
            location            = {}, -- 装饰物,  key未道具的唯一ID
            customerWaitingSeat = {}, -- 等待座位的客人
            recipe              = {}, -- key为菜谱ID，value为数量
            waiter              = {}, -- key为服务员ID
            bug                 = {}, -- 虫子区域ID
        }

        local restaurantLevel = 0
        for i, friendData in ipairs(virtualData.playerData.friendList) do
            if friendData.friendId == checkint(args.friendId) then
                restaurantLevel = checkint(friendData.restaurantLevel)
                break
            end
        end
        local avatarList    = virtualData.restaurant.createAvatarDress(restaurantLevel)
        local hasQuestEvent = false
        for _, v in ipairs(avatarList) do
            -- append location
            local avatarData = {
                id       = virtualData.generateUuid(),
                goodsId  = checkint(v.goodsId),
                location = cc.p(v.x, v.y)
            }
            friendRestaurantData.location[tostring(avatarData.id)] = avatarData

            -- init seat data
            local avatarConf = avatarConfs[tostring(avatarData.goodsId)] or {}
            local avatarType = checkint(avatarConf.mainType)
            if avatarType == RESTAURANT_AVATAR_TYPE.CHAIR then
                local locationConf = locationConfs[tostring(avatarData.goodsId)] or {}
                for _, additionData in ipairs(locationConf.additions or {}) do
                    local additionId   = checkint(string.split(additionData.additionId, '_')[2])
                    local seatKey      = string.fmt('%1_%2', avatarData.id, additionId)
                    local customerData = {
                        customerUuid      = nil, -- 客人的唯一ID, nil 表示没人
                        customerId        = nil, -- 客人ID
                        isSpecialCustomer = nil, -- 1:特殊客人 0:普通客人
                        leftSeconds       = -1,  -- 离开的剩余秒数
                        questEventId      = nil, -- 霸王餐ID
                        isEating          = nil, -- 1:正在吃饭 0:等待招待
                        recipeId          = nil, -- 菜id
                        recipeNum         = nil, -- 菜数量
                    }
                    friendRestaurantData.seat[seatKey] = customerData

                    if _r(100) > 50 then
                        local customerConf = customerConfs[tostring(customerKeys[_r(#customerKeys)])]
                        customerData.customerUuid = virtualData.generateUuid()
                        customerData.customerId   = customerConf.id

                        if hasQuestEvent then
                            customerData.isEating    = _r(0,1)  -- 1:正在吃饭 0:等待招待
                            customerData.leftSeconds = _r(30)
                            if customerData.isEating == 1 then
                                local recipeIdList    = table.keys(cookingRecipeConfs)
                                customerData.recipeId = recipeIdList[_r(#recipeIdList)]
                            end
                        else
                            local questEventKeys      = table.keys(questEventConfs)
                            local questEventConf      = questEventConfs[tostring(questEventKeys[_r(#questEventKeys)])]
                            customerData.questEventId = questEventConf.id
                            customerData.leftSeconds  = -1
                            customerData.isEating     = 0
                            hasQuestEvent = true
                        end
                    end
                end
            end
        end

        -- customer waiting
        for j = 1, _r(0,10) do
            local customerConf = customerConfs[tostring(customerKeys[_r(#customerKeys)])]
            local customerData = {
                customerUuid      = virtualData.generateUuid(),
                customerId        = customerConf.id,
                isSpecialCustomer = 0,  -- 1:特殊客人 0:普通客人
                isEating          = 0,  -- 1:正在吃饭 0:等待招待
                leftSeconds       = _r(30),
            }
            table.insert(friendRestaurantData.customerWaitingSeat, customerData)
        end

        -- waiter
        for i = WAITER_INDEX_BEGAN, WAITER_INDEX_ENDED do
            if _r(100) > 50 then
                local cardId       = checkint(cardKeys[_r(#cardKeys)])
                local cardConf     = cardConfs[tostring(cardId)] or {}
                local cardSkinList = table.keys(cardConf.skin or {})
                local totalVigour  = checkint(cardConf.vigour)
                friendRestaurantData.waiter[tostring(i)] = {
                    cardId        = cardId,
                    skinId        = table.values(checktable(cardConf.skin)[tostring(cardSkinList[_r(#cardSkinList)])] or {})[1],
                    vigour        = _r(100) > 50 and _r(totalVigour) or 0,
                    maxVigour     = totalVigour + _r(100),
                    breakLevel    = math.max(0, #checktable(cardConf.breakLevel) - 1),
                    businessSkill = {}
                }
            end
        end

        -- bug list
        for j = BUG_INDEX_BEGAN, BUG_INDEX_ENDED do
            if _r(100) > 30 then
                table.insert(friendRestaurantData.bug, j)
            end
        end

        virtualData.friendRestaurant_[tostring(args.friendId)] = friendRestaurantData
    end

    local data = friendRestaurantData
    return t2t(data)
end


-- 求助打虫子
virtualData['Restaurant/bugHelp'] = function(args)
    virtualData.restaurant_.hasBugHelp = 1
    return t2t({})
end
-- 自己打虫子
virtualData['Restaurant/bugClean'] = function(args)
    local restaurantBugConf = virtualData.getConf('friend', 'restaurantBug')
    local killGoodsId       = 890005
    local killGoodsNum      = checkint(virtualData.playerData.backpack[tostring(killGoodsId)])
    virtualData.playerData.backpack[tostring(killGoodsId)] = killGoodsNum - 1
    
    -- friend data
    local friendId             = checkint(args.friendId)
    local friendData           = nil
    local friendRestaurantData = nil
    if friendId > 0 then
        for i, v in ipairs(virtualData.playerData.friendList) do
            if v.friendId == friendId then
                friendData = v
                break
            end
        end
        friendRestaurantData = virtualData.friendRestaurant_[tostring(friendId)]
        virtualData.playerData.restaurantCleaningLeftTimes = virtualData.playerData.restaurantCleaningLeftTimes - 1
    end
    if friendData then
        friendData.closePoint = checkint(friendData.closePoint) + checkint(restaurantBugConf.closePoint)
    end

    -- remove bug
    local bugList   = friendRestaurantData and friendRestaurantData.bug or virtualData.restaurant_.bug
    local bugAreaId = checkint(args.bugId)
    for i = #bugList, 1, -1 do
        if bugList[i] == bugAreaId then
            table.remove(bugList, i)
            break
        end
    end
    
    local data = {
        rewards    = checktable(restaurantBugConf.rewards),
        closePoint = checkint(restaurantBugConf.closePoint)
    }
    return t2t(data)
end


-- 求助打霸王餐
virtualData['Restaurant/eventHelp'] = function(args)
    virtualData.restaurant_.hasEventHelp                    = 1
    virtualData.playerData.restaurantEventNeedHelpLeftTimes = virtualData.playerData.restaurantEventNeedHelpLeftTimes - 1
    return t2t({})
end
-- 好友霸王餐战斗
virtualData['Restaurant/helpQuestAt'] = function(args)
    local data = {
        maxSkillTimes      = 0,
        maxCritDamageTimes = 0
    }
    return t2t(data)
end
-- 好友霸王餐结算
virtualData['Restaurant/helpQuestGrade'] = function(args)
    local restaurantEventConf = virtualData.getConf('friend', 'restaurantEvent')

    -- friend data
    local friendId             = checkint(args.friendId)
    local friendData           = nil
    local friendRestaurantData = nil
    if friendId > 0 then
        for i, v in ipairs(virtualData.playerData.friendList) do
            if v.friendId == friendId then
                friendData = v
                break
            end
        end
        friendRestaurantData = virtualData.friendRestaurant_[tostring(friendId)]
        virtualData.playerData.restaurantEventHelpLeftTimes = virtualData.playerData.restaurantEventHelpLeftTimes - 1
    end

    -- add closePoint
    if friendData then
        friendData.closePoint = checkint(friendData.closePoint) + checkint(restaurantEventConf.closePoint)
    end

    -- clean quest customer
    if friendRestaurantData then
        for seatKey, customerData in pairs(friendRestaurantData.seat) do
            if checkint(customerData.questEventId) > 0 then
                customerData.customerUuid = nil
                customerData.customerId   = nil
                customerData.questEventId = nil
                customerData.leftSeconds  = -1
                customerData.isEating     = 0
                break
            end
        end
    end

    local data = {
        hp                = virtualData.playerData.hp,
        gold              = virtualData.playerData.gold,
        mainExp           = virtualData.playerData.mainExp,
        reward            = restaurantEventConf.rewards,
        cardExp           = {},
        favorabilityCards = {},
        closePoint        = friendData and friendData.closePoint or 0,
    }
    return t2t(data)
end


-- 餐厅访问日志
virtualData['Restaurant/message'] = function(args)
    local restaurantVisitConf = virtualData.getConf('friend', 'restaurantVisit')
    local restaurantVisitKeys = table.keys(restaurantVisitConf)

    local data = {
        todayVisit = _r(99),
        totalVisit = _r(99),
        messages   = {}
    }
    local friendIndexList = {}
    for i=1, #virtualData.playerData.friendList do
        table.insert(friendIndexList, i)
    end
    for i=1,_r(#friendIndexList) do
        local friendIndex = table.remove(friendIndexList, _r(#friendIndexList))
        local friendData  = virtualData.playerData.friendList[friendIndex]
        local visitTime   = os.time() - virtualData.createSecond('d:100:?,h:24:?,s:60:?')
        table.insert(data.messages, {
            friendId    = friendData.friendId,
            createTime  = virtualData.createFormatTime(visitTime), -- 最后一次访问时间
            friendName  = friendData.name,
            friendLevel = friendData.level,
            messageType = restaurantVisitKeys[_r(#restaurantVisitKeys)]
        })
    end
    return t2t(data)
end


-- 餐厅做菜
virtualData['Restaurant/recipeCooking'] = function(args)
    local cardData  = virtualData.playerData.cards[tostring(args.employeeId)] or {}
    cardData.vigour = checkint(cardData.vigour) - 10

    local data = {
        gold        = virtualData.playerData.gold,
        vigour      = cardData.vigour,
        leftSeconds = _r(60)
    }
    return t2t(data)
end
-- 加速做菜
virtualData['Restaurant/accelerateRecipeCooking'] = function(args)
    local data = {
        diamond = virtualData.playerData.diamond
    }
    return t2t(data)
end
-- 取消做菜
virtualData['Restaurant/cancelRecipeCooking'] = function(args)
    return t2t({})
end


virtualData['Restaurant/employeeSwitch'] = function(args)
    virtualData.restaurant.switchEmployee(args.employeeId, args.playerCardId)
    return t2t({})
end
