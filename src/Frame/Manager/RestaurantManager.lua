--[[
 * author : kaishiqi
 * descpt : 餐厅 管理器
]]
local BaseManager       = require('Frame.Manager.ManagerBase')
---@class RestaurantManager
local RestaurantManager = class('RestaurantManager', BaseManager)


-------------------------------------------------
-- manager method

RestaurantManager.DEFAULT_NAME = 'RestaurantManager'
RestaurantManager.instances_   = {}


function RestaurantManager.GetInstance(instancesKey)
    instancesKey = instancesKey or RestaurantManager.DEFAULT_NAME

    if not RestaurantManager.instances_[instancesKey] then
        RestaurantManager.instances_[instancesKey] = RestaurantManager.new(instancesKey)
    end
    return RestaurantManager.instances_[instancesKey]
end


function RestaurantManager.Destroy(instancesKey)
    instancesKey = instancesKey or RestaurantManager.DEFAULT_NAME

    if RestaurantManager.instances_[instancesKey] then
        RestaurantManager.instances_[instancesKey]:release()
        RestaurantManager.instances_[instancesKey] = nil
    end
end


-------------------------------------------------
-- life cycle

function RestaurantManager:ctor(instancesKey)
    self.super.ctor(self)

    if RestaurantManager.instances_[instancesKey] then
        funLog(Logger.INFO, "注册相关的facade类型")
    else
        self:initial()
    end
end


function RestaurantManager:initial()
end


function RestaurantManager:release()
end


-------------------------------------------------
-- public method


--判断该卡牌是否在某个职位。主管。厨师，服务员
function RestaurantManager:CheckCardAssistantIndex(id, employe)
    local bool = false
    for k, v in pairs(app.gameMgr:GetUserInfo().employee) do
        local typee = CommonUtils.GetConfigNoParser('restaurant', 'employee', k).type
        if checkint(typee) == checkint(employe) then
            if checkint(v) == checkint(id) then
                bool = true
                break
            end
        end
    end
    return bool
end


--[[
--判断餐厅avatar某个物品是否解锁
--]]
function RestaurantManager:IsAvatarLock(goodsId)
    local isLocked    = true
    local cacheLocked = checktable(app.gameMgr:GetUserInfo().avatarCacheData.unlockAvatars)
    for idx, val in ipairs(cacheLocked) do
        if checkint(goodsId) == checkint(val) then
            isLocked = false
            break
        end
    end
    --[[
    local avatarInfo = CommonUtils.GetConfigNoParser('restaurant', 'avatar', checkint(goodsId))
    if avatarInfo then
        local unlockTypeInfo = avatarInfo.unlockType
        local unlockNum = checkint(unlockTypeInfo[tostring(UnlockTypes.AS_LEVEL)].targetNum)
        if checkint(app.gameMgr:GetUserInfo().restaurantLevel) >= unlockNum then
            isLocked = false --已解锁的物品
        end
        -- local unlockTypes = CommonUtils.GetConfigAllMess('unlockType')
    end
    --]]
    return isLocked
end


--获取餐厅当前客流量
function RestaurantManager:GetTraffic()
    local traffic  = 0
    local userInfo = app.gameMgr:GetUserInfo()
    -- 雇员效果
    for k, v in pairs(app.gameMgr:GetUserInfo().supervisor) do
        local x = self:GetCardBusinessBuff(v, LOBBY_SUPERVISOR, 2)
        if next(x) ~= nil then
            for _, skill in ipairs(x) do
                if skill.allEffectNum.targetType == '41' then
                    traffic = traffic + checkint(skill.allEffectNum.effectNum[1])
                end
            end
        end
    end

    for k, v in pairs(app.gameMgr:GetUserInfo().chef) do
        local x = self:GetCardBusinessBuff(v, LOBBY_CHEF, 2)
        if next(x) ~= nil then
            for _, skill in ipairs(x) do
                if skill.allEffectNum.targetType == '41' then
                    traffic = traffic + checkint(skill.allEffectNum.effectNum[1])
                end
            end
        end
    end
    for k, v in pairs(app.gameMgr:GetUserInfo().waiter) do
        local x = self:GetCardBusinessBuff(v, LOBBY_WAITER, 2)
        if next(x) ~= nil then
            for _, skill in ipairs(x) do
                if skill.allEffectNum.targetType == '41' then
                    traffic = traffic + checkint(skill.allEffectNum.effectNum[1])
                end
            end
        end
    end
    -- 香味
    local fragrance = 0
    for recipeId, _ in pairs(userInfo.avatarCacheData.recipe) do
        local recipeDatas = CommonUtils.GetConfigNoParser('cooking', 'recipe', recipeId)
        if recipeDatas and userInfo.cookingStyles[recipeDatas.cookingStyleId] then
            for _, recipe in ipairs(userInfo.cookingStyles[recipeDatas.cookingStyleId]) do
                if checkint(recipe.recipeId) == checkint(recipeId) then
                    fragrance = fragrance + checkint(recipe.fragrance)
                    break
                end
            end
        end
    end
    local addCustomerNum = checkint(fragrance / 20) * math.sqrt(table.nums(userInfo.avatarCacheData.recipe))
    traffic              = traffic + checkint(addCustomerNum)
    -- avatarbuff
    for _, v in pairs(userInfo.avatarCacheData.location) do
        local avatarDatas = CommonUtils.GetConfigNoParser('restaurant', 'avatar', v.goodsId)
        if table.nums(checktable(avatarDatas.buffType)) > 0 then
            for _, buff in ipairs(avatarDatas.buffType) do
                if buff.targetNum and next(buff.targetNum) ~= nil then
                    traffic = traffic + checkint(buff.targetNum)
                end
            end
        end
    end
    -- 餐厅等级
    local restaurantDatas = CommonUtils.GetConfigNoParser('restaurant', 'levelUp', userInfo.restaurantLevel)
    traffic               = traffic + checkint(restaurantDatas.traffic)
    return traffic
end



function RestaurantManager:GetAvatarAmoutById(avatarId)
    local locations = checktable(app.gameMgr:GetUserInfo().avatarCacheData.location)
    local no        = 0
    local minus     = 0
    for _, val in pairs(locations) do
        if checkint(val.goodsId) == checkint(avatarId) then
            minus = minus + 1
        end
    end
    local backNumber = app.gameMgr:GetAmountByGoodId(avatarId)
    local avatarInfo = CommonUtils.GetConfigNoParser('restaurant', 'avatar', avatarId)
    local nType      = RestaurantUtils.GetAvatarSubType(avatarInfo.mainType, avatarInfo.subType)
    if (nType == RESTAURANT_AVATAR_TYPE.WALL or nType == RESTAURANT_AVATAR_TYPE.CEILING or 
        nType == RESTAURANT_AVATAR_TYPE.FLOOR or nType == RESTAURANT_AVATAR_TYPE.DECORATION_PET) then
        no = backNumber
    else
        no = backNumber - minus
    end
    return no
end


--[[
根据seatId得到物品的配表avatarId
--]]
function RestaurantManager:GetSeatConfigBySeatId(seatId, locations)
    local ids = string.split(seatId, '_')
    local location = locations and locations[tostring(ids[1])] or app.gameMgr:GetUserInfo().avatarCacheData.location[tostring(ids[1])]
    local t = {}
    if location then
        local locationConfig = CONF.AVATAR.LOCATION:GetValue(location.goodsId)
        local aId = string.format('%d_%d', checkint(location.goodsId),checkint(ids[2]))
        for name, val in pairs(locationConfig.additions) do
            if val.additionId == aId then
                t = val
                break
            end
        end
    else
        funLog(Logger.INFO, "位置缓存中查找不到对应的位置信息>>>>>>" .. seatId)
    end
    return t
end


--==============================--
--desc: 该函数是获取该卡牌已经解锁。且对应模块。且对应生效位置。且上阵该生效位置
--time:2017-06-27 11:38:51
--@employe:卡牌的所处位置 1：主管。2：厨师。3：服务员。
--@cardId: 卡牌的cardId
--@module: 对应作用的模块 0任何模块 1烹饪,2大堂,3外卖,4料理副本
--@IsNeedInJob :bool 是否不需要上阵到具体职位  默认false
--@extraData   :获取技能的位置
--@return
--==============================---
function RestaurantManager:GetCardBusinessBuff(Id, employe, module, IsNotNeedInJob,extraData)
    local cardData  = app.gameMgr:GetCardDataById(Id)
    local tempSkill = CommonUtils.GetBusinessSkillByCardId(cardData.cardId,extraData) --获取到技能id
    local t         = {}
    -- dump(tempSkill)
    -- dump(IsNotNeedInJob)†

    if IsNotNeedInJob then
        for k, v in ipairs(tempSkill) do
            if checkint(v.module) == checkint(module) then
                --判断为模块相同技能
                if v.unlock == 1 then
                    --该技能是否解锁
                    v.chenkEmploye = employe
                    v.cardId       = cardData.cardId
                    table.insert(t, v)
                end
            end
        end
    else
        if self:CheckCardAssistantIndex(Id, employe) then
            for k, v in ipairs(tempSkill) do
                if checkint(v.module) == checkint(module) then
                    --判断为模块相同技能
                    if v.unlock == 1 then
                        --该技能是否解锁
                        local bool = false
                        for i, v in ipairs(v.employee) do
                            if checkint(v) == checkint(employe) then
                                bool = true
                                break
                            end
                        end
                        if bool == true then
                            --判断该技能在卡牌的所处位置是否生效
                            v.chenkEmploye = employe
                            v.cardId       = cardData.cardId
                            table.insert(t, v)
                            -- break
                        end
                    end
                end
            end
        end
    end

    return t
end


--@module: 对应作用的模块 1烹饪,2大堂,3外卖,4料理副本
function RestaurantManager:GetAllAssistantBuff(module)
    -- 	 supervisor  = {},   --主管
    --   chef        = {},   --厨师
    --   waiter      = {},   --服务
    local t = {}
    for k, v in pairs(app.gameMgr:GetUserInfo().supervisor) do
        local x = self:GetCardBusinessBuff(v, LOBBY_SUPERVISOR, module)
        if next(x) ~= nil then
            table.insert(t, x)
        end
    end

    for k, v in pairs(app.gameMgr:GetUserInfo().chef) do
        local x = self:GetCardBusinessBuff(v, LOBBY_CHEF, module)
        if next(x) ~= nil then
            table.insert(t, x)
        end
    end

    for k, v in pairs(app.gameMgr:GetUserInfo().waiter) do
        local x = self:GetCardBusinessBuff(v, LOBBY_WAITER, module)
        if next(x) ~= nil then
            table.insert(t, x)
        end
    end
    -- dump(t)
    return t
end


--餐厅的橱窗出售食物数量上限提高_target_num_个
function RestaurantManager:getCookCanScaleFoodsNum( scaleFoodsNum )
    local scaleFoodsNum = scaleFoodsNum or 0
    local t             = self:GetAllAssistantBuff(CARD_BUSINESS_SKILL_MODEL_LOBBY)
    for i, v in ipairs(t) do
        for i, vv in ipairs(v) do
            if checkint(vv.allEffectNum.targetType) == RestaurantSkill.SKILL_TYPE_RESTAURANT_SHOP_WINDOW_MAX_INCREASE then
                local num     = CommonUtils.GetAssistantEffectNum( vv.allEffectNum )
                -- dump(num)
                scaleFoodsNum = scaleFoodsNum + checkint(num)
            end
        end
    end

    --月卡相关增加上限
    scaleFoodsNum = scaleFoodsNum + CommonUtils.getVipTotalLimitByField('shopWindowLimit')
    -- dump(scaleFoodsNum)
    return scaleFoodsNum
end


--[[
--餐厅是否有服务员，厨师 新鲜度不足
--]]
function RestaurantManager:IsShowRedPointForChefOrWaiter()
    local bool     = false
    local tempBool = false
    -- dump(app.gameMgr:GetUserInfo().chef)
    -- dump(app.gameMgr:GetUserInfo().waiter)
    if next(app.gameMgr:GetUserInfo().chef) ~= nil then
        for i, v in pairs(app.gameMgr:GetUserInfo().chef) do
            local cardData = app.gameMgr:GetCardDataById(v)
            if cardData then
                if checkint(cardData.vigour) <= 0 then
                    bool     = true
                    tempBool = true
                    break
                end
            end
        end
    else
        bool     = true
        tempBool = true
    end
    if tempBool == false then
        if next(app.gameMgr:GetUserInfo().waiter) ~= nil then
            for i, v in pairs(app.gameMgr:GetUserInfo().waiter) do
                local cardData = app.gameMgr:GetCardDataById(v)
                if cardData then
                    if checkint(cardData.vigour) <= 0 then
                        bool = true
                        break
                    end
                end
            end
        else
            bool = true
        end
    end
    return bool
end


--飨灵在厨房使用_target_id_菜系中的食谱制作时间降低_target_num_%
--飨灵在厨房中制作食物时,制作时间降低_target_num_%
function RestaurantManager:getReduceMakingTime( reduceMakingTime, playerCardId, recipeId )
    local cookingStyleId = 0
    local recipeData     = CommonUtils.GetConfigNoParser('cooking', 'recipe', recipeId)
    if recipeData then
        cookingStyleId = recipeData.cookingStyleId
    end
    -- dump(reduceMakingTime)
    local reduceMakingTime = reduceMakingTime
    if self:CheckCardAssistantIndex(playerCardId, LOBBY_CHEF) then
        local t = self:GetCardBusinessBuff(playerCardId, LOBBY_CHEF, CARD_BUSINESS_SKILL_MODEL_LOBBY)
        for i, v in ipairs(t) do
            -- dump(v)
            if checkint(v.allEffectNum.targetType) == RestaurantSkill.SKILL_TYPE_RESTAURANT_MAKING_TIME_DECREASE then
                local num        = CommonUtils.GetAssistantEffectNum( v.allEffectNum )
                -- dump(num)
                local x          = reduceMakingTime * tonumber(num)
                reduceMakingTime = reduceMakingTime - x
                -- break
            elseif checkint(v.allEffectNum.targetType) == RestaurantSkill.SKILL_TYPE_RESTAURANT_COOKING_STYLE_MAKING_LIMIT_INCREASE then
                if next(v.allTargetId) ~= nil then
                    if checkint(cookingStyleId) ~= 0 and checkint(v.allTargetId[1]) == checkint(cookingStyleId) then
                        local num        = CommonUtils.GetAssistantEffectNum( v.allEffectNum )
                        local x          = reduceMakingTime * tonumber(num)
                        reduceMakingTime = reduceMakingTime - x
                    end
                end
            end
        end
    end
    -- dump(reduceMakingTime)
    return reduceMakingTime
end


--飨灵在厨房使用_target_id_菜系中的食谱单次制作数量上限提高_target_num_个
--飨灵在厨房中制作食物时,单次制作数量上限提高_target_num_个
function RestaurantManager:getCookMakeFoodNum( makeFoodNum, playerCardId, recipeId)
    local cookingStyleId = 0
    local recipeData     = CommonUtils.GetConfigNoParser('cooking', 'recipe', recipeId)
    if recipeData then
        cookingStyleId = recipeData.cookingStyleId
    end
    local makeFoodNum = makeFoodNum
    if self:CheckCardAssistantIndex(playerCardId, LOBBY_CHEF) then
        local t = self:GetCardBusinessBuff(playerCardId, LOBBY_CHEF, CARD_BUSINESS_SKILL_MODEL_LOBBY)
        for i, v in ipairs(t) do
            if checkint(v.allEffectNum.targetType) == RestaurantSkill.SKILL_TYPE_RESTAURANT_MAKING_LIMIT_INCREASE then
                local num   = CommonUtils.GetAssistantEffectNum( v.allEffectNum )
                -- dump(num)
                makeFoodNum = makeFoodNum + checkint(num)
                -- break
            elseif checkint(v.allEffectNum.targetType) == RestaurantSkill.SKILL_TYPE_RESTAURANT_COOKING_STYLE_MAKING_LIMIT_INCREASE then
                if next(v.allTargetId) ~= nil then
                    if checkint(cookingStyleId) ~= 0 and checkint(v.allTargetId[1]) == checkint(cookingStyleId) then
                        local num   = CommonUtils.GetAssistantEffectNum( v.allEffectNum )
                        -- dump(num)
                        makeFoodNum = makeFoodNum + checkint(num)
                    end
                end
            end
        end
    end
    return makeFoodNum
end


--获取卡牌新鲜度上限值
function RestaurantManager:getCardVigourLimit( playerCardId )
    local vigour   = 0
    local cardData = app.gameMgr:GetCardDataById(playerCardId)
    if cardData and next(cardData) then
        local cardConf = CommonUtils.GetConfig('cards', 'card', cardData.cardId) or {}
        vigour         = checkint(cardConf.vigour)
        -- if self:CheckCardAssistantIndex(playerCardId, LOBBY_WAITER) then--
        local t        = self:GetCardBusinessBuff(playerCardId, LOBBY_WAITER, CARD_BUSINESS_SKILL_MODEL_ALL, true)
        -- dump(t)
        for i, v in ipairs(t) do
            if checkint(v.allEffectNum.targetType) == RestaurantSkill.SKILL_TYPE_RESTAURANT_VIGOUR_MAX_INCREASE then
                local num = CommonUtils.GetAssistantEffectNum( v.allEffectNum )
                -- dump(num)
                vigour    = vigour + checkint(num)
                break
            end
        end
    end
    -- end
    -- dump(vigour)
    return vigour
end


--[[
--得到当前卡牌的最大的新鲜度的值
--@id 卡牌的id
--]]
function RestaurantManager:GetMaxCardVigourById(id)
    local vigour = self:getCardVigourLimit( id )
    return vigour
end


--[[
判断探索队伍新鲜度是否足够
@params teamId int 队伍id
teamVigourCost int 团队新鲜度消耗
--]]
function RestaurantManager:HasEnoughVigourToExplore(teamId, teamVigourCost)
    local teamFormationData = app.gameMgr:GetUserInfo().teamFormation[checkint(teamId)]
    local cardNums          = CommonUtils.GetTeamCardNums(teamId)
    for i, card in ipairs(teamFormationData.cards) do
        if card.id and checkint(card.id) ~= 0 then
            local vigourCostPercent = checkint(teamVigourCost) / cardNums
            local MaxVigour         = self:GetMaxCardVigourById(card.id)
            local cardVigourCost    = math.round(vigourCostPercent * MaxVigour)
            local cardData          = app.gameMgr:GetCardDataById(card.id)
            if checkint(cardData.vigour) < checkint(cardVigourCost) then
                return false
            end
        end
    end
    return true
end


--[[
扣除探索所消耗的新鲜度
@params teamId int 队伍id
teamVigourCost int 团队新鲜度消耗
--]]
function RestaurantManager:DeductExploreVigour(teamId, teamVigourCost)
    local teamFormationData = app.gameMgr:GetUserInfo().teamFormation[checkint(teamId)]
    local cardNums          = CommonUtils.GetTeamCardNums(teamId)

    for i, card in ipairs(teamFormationData.cards) do
        if card.id and checkint(card.id) ~= 0 then
            local vigourCostPercent = checkint(teamVigourCost) / cardNums
            local MaxVigour         = self:GetMaxCardVigourById(card.id)
            local cardVigourCost    = math.round(vigourCostPercent * MaxVigour)
            local cardData          = app.gameMgr:GetCardDataById(card.id)
            app.gameMgr:UpdateCardDataById(tonumber(card.id), { vigour = tonumber(cardData.vigour - cardVigourCost) })
        end
    end
end


--作为服务员的准备时间所需时间
function RestaurantManager:getWaiterSwitchTimeLimit( playerCardId )
    local switchTime = 600
    if self:CheckCardAssistantIndex(playerCardId, LOBBY_WAITER) then
        local t = self:GetCardBusinessBuff(playerCardId, LOBBY_WAITER, CARD_BUSINESS_SKILL_MODEL_LOBBY)
        for i, v in ipairs(t) do
            if checkint(v.allEffectNum.targetType) == RestaurantSkill.SKILL_TYPE_RESTAURANT_WAITER_SWITCH_CD then
                local num  = CommonUtils.GetAssistantEffectNum( v.allEffectNum )
                -- dump(num)
                switchTime = switchTime - checkint(num)
                break
            end
        end
    end
    -- dump(switchTime)
    return switchTime
end

--==============================--
--desc: 是否拥有主题
--@params themeId int 主题id
--@return isHave  bool 是否拥有
--==============================--
function RestaurantManager:IsHaveTheme(themeId)
    local isHave = false
    -- 1.获取该主题的所有散件
    local avatarThemePartsConf = CommonUtils.GetConfigAllMess('avatarThemeParts', 'restaurant') or {}
    local avatarThemeParts = avatarThemePartsConf[tostring(themeId)]
    if avatarThemeParts == nil then return isHave end

    -- 2.获取map格式的背包数据
    local backpackMap = app.gameMgr:GetBackPackArrayToMap()

    -- 3.检查avatar 状态
    for avatarId, num in pairs(avatarThemeParts) do
        local data = backpackMap[tostring(avatarId)] or {}
        -- 3.1 只要是出现不满足的的情况 既 退出循环
        isHave = checkint(data.amount) >= checkint(num)
        if not isHave then
            break
        end
    end

    return isHave
end

-------------------------------------------------
------------------- custom suit
-- house presetSuitId
function RestaurantManager:setHousePresetSuitId(suitId)
    self.housePresetSuitId_ = checkint(suitId)
    app:DispatchObservers(SGL.RESTAURANT_PREVIEW_SUIT)
end

function RestaurantManager:getHousePresetSuitId()
    return checkint(self.housePresetSuitId_)
end

-- house customSuitData
function RestaurantManager:getAllCustomSuitData()
    return checktable(app.gameMgr:GetUserInfo().avatarCacheData.customSuits)
end
function RestaurantManager:getSuitDataBySuitId(suitId)
    return checktable(self:getAllCustomSuitData()[tostring(suitId)])
end
function RestaurantManager:setSuitDataBySuitId(suitId, suitData)
    if not app.gameMgr:GetUserInfo().avatarCacheData.customSuits then
        app.gameMgr:GetUserInfo().avatarCacheData.customSuits = {}
    end
    app.gameMgr:GetUserInfo().avatarCacheData.customSuits[tostring(suitId)] = checktable(suitData)
end

-------------------------------------------------
-- private method


return RestaurantManager
