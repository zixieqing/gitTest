--[[
 * author : kaishiqi
 * descpt : 水吧 管理器
]]
local BaseManager     = require('Frame.Manager.ManagerBase')
---@class WaterBarManager:WaterBarManager
local WaterBarManager = class('WaterBarManager', BaseManager)

-------------------------------------------------
-- utils method

WaterBarUtils = nil
WaterBarUtils = {

    -- 获取饮品类型
    GetDrinkType = function(drinkId)
        local drinkType = FOOD.WATER_BAR.DRINK_TYPE.ALL
        local drinkConf = CONF.BAR.DRINK:GetValue(drinkId)
        if drinkConf.formulaId then
            local formulaConf = CONF.BAR.FORMULA:GetValue(drinkConf.formulaId)
            if checkint(formulaConf.alcohol) == 1 then
                drinkType = FOOD.WATER_BAR.DRINK_TYPE.ALCOHO
            else
                drinkType = FOOD.WATER_BAR.DRINK_TYPE.SOFT
            end
        end
        return drinkType
    end,

    -- 配方是否喜欢
    IsFormulaLike = function(like)
        return checkint(like) == 1
    end,
}


-------------------------------------------------
-- manager method

WaterBarManager.DEFAULT_NAME = 'WaterBarManager'
WaterBarManager.instances_   = {}


function WaterBarManager.GetInstance(instancesKey)
    instancesKey = instancesKey or WaterBarManager.DEFAULT_NAME

    if not WaterBarManager.instances_[instancesKey] then
        WaterBarManager.instances_[instancesKey] = WaterBarManager.new(instancesKey)
    end
    return WaterBarManager.instances_[instancesKey]
end


function WaterBarManager.Destroy(instancesKey)
    instancesKey = instancesKey or WaterBarManager.DEFAULT_NAME

    if WaterBarManager.instances_[instancesKey] then
        WaterBarManager.instances_[instancesKey]:release()
        WaterBarManager.instances_[instancesKey] = nil
    end
end


-------------------------------------------------
-- life cycle

function WaterBarManager:ctor(instancesKey)
    self.super.ctor(self)

    if WaterBarManager.instances_[instancesKey] then
        funLog(Logger.INFO, "注册相关的facade类型")
    else
        self:initial()
    end
end


function WaterBarManager:initial()
    self.barLevel_   = 0  -- 水吧等级
    self.barPoint_   = 0  -- 水吧货币
    self.popularity_ = 0  -- 水吧知名度
    self.timestamp_  = 0  -- 主页时间戳
    self.homeData_   = {} -- 水吧主页
    self.formulaMap_ = {} -- 材料map
end


function WaterBarManager:release()
end


-- bar level
function WaterBarManager:getBarLevel()
    return checkint(self.barLevel_)
end
function WaterBarManager:setBarLevel(newLevel)
    self.barLevel_ = checkint(newLevel)

    -- 水吧升级时，自动解锁新增的配方（hide = 0：表示不需要研究自动解锁的类型）
    for formulaId, formulaConf in pairs(CONF.BAR.FORMULA:GetAll()) do
        if not self:hasFormula(formulaId) then
            if checkint(formulaConf.openBarLevel) <= self:getBarLevel() and checkint(formulaConf.hide) == 0 then
                self:setFormulaData(formulaId, {formulaId = checkint(formulaId)})
            end
        end
    end
end


-- bar point
function WaterBarManager:getBarPoint()
    return checkint(self.barPoint_)
end
function WaterBarManager:setBarPoint(newPoint)
    self.barPoint_ = checkint(newPoint)
end


-- bar popularity
function WaterBarManager:getBarPopularity()
    return checkint(self.popularity_)
end
function WaterBarManager:setBarPopularity(newPopularity)
    self.popularity_ = checkint(newPopularity)
end


-------------------------------------------------
-- user opening
function WaterBarManager:getUserOpeningKey_()
    return string.format('WATER_BAR_HOME_OPENING_SPINE_%d', checkint(app.gameMgr:GetUserInfo().playerId))
end
function WaterBarManager:isUserOpeningToday()
    local todayValue = os.date("%Y-%m-%d")
    local openingKey = self:getUserOpeningKey_()
    return cc.UserDefault:getInstance():getStringForKey(openingKey, '') == todayValue
end
function WaterBarManager:saveUserOpeningToday()
    local todayValue = os.date("%Y-%m-%d")
    local openingKey = self:getUserOpeningKey_()
    cc.UserDefault:getInstance():setStringForKey(openingKey, todayValue)
    cc.UserDefault:getInstance():flush()
end


-------------------------------------------------
-- user story
function WaterBarManager:getUserStoryKey_(storyId)
    return string.format('WATER_BAR_HOME_STORY_%d_%d', checkint(app.gameMgr:GetUserInfo().playerId), checkint(storyId))
end
function WaterBarManager:isUserStoryTrigger(storyId)
    local storyKey = self:getUserStoryKey_(storyId)
    return cc.UserDefault:getInstance():getBoolForKey(storyKey, false) == true
end
function WaterBarManager:saveUserStoryTrigger(storyId)
    local storyKey = self:getUserStoryKey_(storyId)
    cc.UserDefault:getInstance():setBoolForKey(storyKey, true)
    cc.UserDefault:getInstance():flush()
end


-------------------------------------------------
-- home data

function WaterBarManager:getHomeData()
    return self.homeData_
end
function WaterBarManager:setHomeData(initData)
    self.homeData_   = initData or {}
    self.timestamp_  = os.time() + self:getHomeLeftSeconds()

    -- update formulas
    for _, formulaData in ipairs(self:getHomeData().formulas or {}) do
        self:setFormulaData(formulaData.formulaId, formulaData)
    end
end


-- @see WATER_BAR.STATUS_TYPE
function WaterBarManager:getHomeStatus()
    return checkint(self:getHomeData().status)
end

function WaterBarManager:isHomeOpening()
    return self:getHomeStatus() == FOOD.WATER_BAR.STATUS_TYPE.OPENING
end

function WaterBarManager:isHomeClosing()
    return self:getHomeStatus() == FOOD.WATER_BAR.STATUS_TYPE.CLOSING
end


function WaterBarManager:getHomeLeftSeconds()
    return checkint(self:getHomeData().leftSeconds)
end

function WaterBarManager:getHomeTimestamp()
    return checkint(self.timestamp_)
end


-------------------------------------------------------------------------------
-- business data
-------------------------------------------------------------------------------

-- 昨日过期的账目
function WaterBarManager:getYesterdayExpire()
    return checktable(self:getHomeData().yesterdayExpire)
end

-- 昨日营业的账目
function WaterBarManager:getYesterdayBill()
    return checktable(self:getHomeData().yesterdayBill)
end

-- 营业的收入奖励
function WaterBarManager:setBusinessRewards(data)
    self:getHomeData().businessRewards = checktable(data)
end
function WaterBarManager:getBusinessRewards()
    return checktable(self:getHomeData().businessRewards)
end
function WaterBarManager:hasBusinessRewards()
    return next(checktable(self:getBusinessRewards().rewards)) ~= nil or
        next(checktable(self:getBusinessRewards().customerFrequencyPoint)) ~= nil
end


-------------------------------------------------------------------------------
-- materials data
-------------------------------------------------------------------------------

function WaterBarManager:getAllMaterials()
    self:getHomeData().materials = self:getHomeData().materials or {}
    return self:getHomeData().materials
end
function WaterBarManager:getAllMaterialNum()
    local allMaterialNum = 0
    for _, materialNum in pairs(self:getAllMaterials()) do
        allMaterialNum = allMaterialNum + materialNum
    end
    return allMaterialNum
end


function WaterBarManager:hasMaterial(material)
    return self:getAllMaterials()[tostring(material)] == nil
end


function WaterBarManager:getMaterialNum(material)
    return checkint(self:getAllMaterials()[tostring(material)])
end
function WaterBarManager:setMaterialNum(material, drinkNum)
    self:getAllMaterials()[tostring(material)] = checkint(drinkNum)
end


function WaterBarManager:addMaterialNum(material, drinkNum)
    self:getAllMaterials()[tostring(material)] = checkint(self:getAllMaterials()[tostring(material)]) + checkint(drinkNum)
    if self:getAllMaterials()[tostring(material)] <= 0 then
        self:getAllMaterials()[tostring(material)] = 0
    end
end
function WaterBarManager:subMaterialNum(material, drinkNum)
    self:addMaterialNum(material, -drinkNum)
end


function WaterBarManager:getMaterialList()
    local materialList = table.keys(self:getAllMaterials())
    table.sort(materialList, function(a, b) return checkint(a) < checkint(b) end)
    return materialList
end


-------------------------------------------------------------------------------
-- drinks data
-------------------------------------------------------------------------------

function WaterBarManager:getAllDrinks()
    self:getHomeData().drinks = self:getHomeData().drinks or {}
    return self:getHomeData().drinks
end
function WaterBarManager:getAllDrinkNum()
    local allDrinkNum = 0
    for _, drinkNum in pairs(self:getAllDrinks()) do
        allDrinkNum = allDrinkNum + drinkNum
    end
    return allDrinkNum
end


function WaterBarManager:hasDrink(drinkId)
    return self:getAllDrinks()[tostring(drinkId)] == nil
end


function WaterBarManager:getDrinkNum(drinkId)
    return checkint(self:getAllDrinks()[tostring(drinkId)])
end
function WaterBarManager:setDrinkNum(drinkId, drinkNum)
    self:getAllDrinks()[tostring(drinkId)] = checkint(drinkNum)
end


function WaterBarManager:addDrinkNum(drinkId, drinkNum)
    self:getAllDrinks()[tostring(drinkId)] = checkint(self:getAllDrinks()[tostring(drinkId)]) + checkint(drinkNum)
    if self:getAllDrinks()[tostring(drinkId)] <= 0 then
        self:getAllDrinks()[tostring(drinkId)] = 0
    end
end
function WaterBarManager:subDrinkNum(drinkId, drinkNum)
    self:addDrinkNum(drinkId, -drinkNum)
end


function WaterBarManager:getDrinkList()
    local drinkIdList = table.keys(self:getAllDrinks())
    table.sort(drinkIdList, function(a, b) return checkint(a) < checkint(b) end)
    return drinkIdList
end


-------------------------------------------------------------------------------
-- putaway data
-------------------------------------------------------------------------------

function WaterBarManager:getAllPutaways()
    self:getHomeData().onShelfDrinks = self:getHomeData().onShelfDrinks or {}
    return self:getHomeData().onShelfDrinks
end
function WaterBarManager:getAllPutawayNum(drinkId)
    local allDrinkNum = 0
    for drinkId, drinkNum in pairs(self:getAllPutaways()) do
        allDrinkNum = allDrinkNum + drinkNum
    end
    return allDrinkNum
end


function WaterBarManager:hasPutaway(drinkId)
    return self:getAllPutaways()[tostring(drinkId)] == nil
end


function WaterBarManager:getPutawayNum(drinkId)
    return checkint(self:getAllPutaways()[tostring(drinkId)])
end
function WaterBarManager:setPutawayNum(drinkId, drinkNum)
    self:getAllPutaways()[tostring(drinkId)] = checkint(drinkNum)
end


function WaterBarManager:addPutawayNum(drinkId, drinkNum)
    self:getAllPutaways()[tostring(drinkId)] = checkint(self:getAllPutaways()[tostring(drinkId)]) + checkint(drinkNum)
    if self:getAllPutaways()[tostring(drinkId)] <= 0 then
        self:getAllPutaways()[tostring(drinkId)] = 0
    end
end
function WaterBarManager:subPutawayNum(drinkId, drinkNum)
    self:addPutawayNum(drinkId, -drinkNum)
end


function WaterBarManager:getPutawayList()
    local drinkIdList = table.keys(self:getAllPutaways())
    table.sort(drinkIdList, function(a, b) return checkint(a) < checkint(b) end)
    return drinkIdList
end


-------------------------------------------------------------------------------
-- formula data
-------------------------------------------------------------------------------

function WaterBarManager:getFormulaMap()
    return self.formulaMap_
end


function WaterBarManager:hasFormula(formulaId)
    return self:getFormulaData(formulaId) ~= nil
end


function WaterBarManager:getFormulaData(formulaId)
    return self:getFormulaMap()[tostring(formulaId)]
end


function WaterBarManager:setFormulaData(formulaId, formulaData)
    local findFormulaData = self:getFormulaData(formulaId)
    if findFormulaData == nil then
        self:getFormulaMap()[tostring(formulaId)] = {}
        findFormulaData = self:getFormulaMap()[tostring(formulaId)]
    end

    -- update eache data
    for key, value in pairs(checktable(formulaData)) do
        findFormulaData[key] = value
    end
end


-- formula : like
function WaterBarManager:isFormulaLike(formulaId)
    local findFormulaData = self:getFormulaData(formulaId) or {}
    return WaterBarUtils.IsFormulaLike(findFormulaData.like)
end
function WaterBarManager:setFormulaLike(formulaId, isLike)
    local findFormulaData = self:getFormulaData(formulaId) or {}
    findFormulaData.like = (isLike == true) and 1 or 0
end


-- formula : star
function WaterBarManager:getFormulaStar(formulaId)
    local findFormulaData = self:getFormulaData(formulaId) or {}
    findFormulaData.madeStars = findFormulaData.madeStars or {}
    return checktable(findFormulaData.madeStars)
end
function WaterBarManager:setFormulaStar(formulaId, starList)
    local findFormulaData = self:getFormulaData(formulaId) or {}
    findFormulaData.madeStars = checktable(starList)
end
function WaterBarManager:addFormulaStar(formulaId, starNum)
    local hasFormula = self:hasFormula(formulaId)
    if not hasFormula then
        self:setFormulaData(formulaId , {
            formulaId = formulaId,
            like = 0 ,
            madeStars = {starNum}
        })
        return
    end
    local hasFormulaStar = self:hasFormulaStar(formulaId , starNum)
    if not hasFormulaStar then
        local findFormulaData = self:getFormulaData(formulaId)
        if not findFormulaData.madeStars then
            findFormulaData.madeStars = {}
        end
        table.insert(findFormulaData.madeStars, starNum)
    end
end

function WaterBarManager:hasFormulaStar(formulaId, starNum)
    local hasFormulaStar = false
    for _, star in ipairs(self:getFormulaStar(formulaId)) do
        if checkint(star) == checkint(starNum) then
            hasFormulaStar = true
            break
        end
    end
    return hasFormulaStar
end
function WaterBarManager:getFormulaMaxStar(formulaId)
    local maxFormulaStar = -1
    for _, star in ipairs(self:getFormulaStar(formulaId)) do
        maxFormulaStar = math.max(maxFormulaStar, checkint(star))
    end
    return maxFormulaStar
end


-------------------------------------------------------------------------------
-- customers data
-------------------------------------------------------------------------------

function WaterBarManager:getCurrentScheduleCustomers()
    return checktable(self:getHomeData().currentScheduleCustomers)
end


function WaterBarManager:getAllCustomers()
    self:getHomeData().customers = self:getHomeData().customers or {}
    return self:getHomeData().customers
end


function WaterBarManager:hasCustomer(customerId)
    return self:getCustomerIndex() > 0
end


function WaterBarManager:getCustomerIndex(customerId)
    local findCustomerIndex = 0
    for index, CustomerData in ipairs(self:getAllCustomers()) do
        if checkint(CustomerData.customerId) == checkint(customerId) then
            findCustomerIndex = index
            break
        end
    end
    return findCustomerIndex
end


function WaterBarManager:getCustomerData(customerId)
    return self:getAllCustomers()[self:getCustomerIndex(customerId)]
end


function WaterBarManager:setCustomerData(customerId, CustomerData)
    local findCustomerData  = nil
    local findCustomerIndex = self:getCustomerIndex()
    if findCustomerIndex > 0 then
        findCustomerData = self:getAllCustomers()[findCustomerIndex]
        -- update data
        for key, value in pairs(CustomerData) do
            findCustomerData[key] = CustomerData
        end
    else
        table.insert(self:getAllCustomers(), CustomerData)
    end
end


-- customer : frequencyPoint
function WaterBarManager:getCustomerPoint(customerId)
    local findCustomerData = self:getCustomerData(customerId) or {}
    return checkint(findCustomerData.frequencyPoint)
end
function WaterBarManager:setCustomerPoint(customerId, point)
    local findCustomerData = self:getCustomerData(customerId) or {}
    findCustomerData.frequencyPoint = checkint(point)
end
function WaterBarManager:addCustomerPoint(customerId, point)
    local findCustomerData = self:getCustomerData(customerId) or {}
    findCustomerData.frequencyPoint = checkint(findCustomerData.frequencyPoint) + checkint(point)
end


-- customer : frequencyPointRewards
function WaterBarManager:getCustomerRewardIds(customerId)
    local findCustomerData = self:getCustomerData(customerId) or {}
    return checktable(findCustomerData.frequencyPointRewards)
end
function WaterBarManager:setCustomerRewardIds(customerId, rewardIds)
    local findCustomerData = self:getCustomerData(customerId) or {}
    findCustomerData.frequencyPointRewards = checktable(rewardIds)
end



-- serve getAllServeCustomers
function WaterBarManager:getAllServeCustomers()
    self:getHomeData().serveCustomers = self:getHomeData().serveCustomers or {}
    return self:getHomeData().serveCustomers
end
--[[
    materialList = {
        goodsId  食材ID.
        num  食材数量
    }
    method  手法
]]
function WaterBarManager:GetDrinkIdByMaterials(materialList , method )
    local formulaConf = CONF.BAR.FORMULA:GetAll()
    local method = checkint(method)
    local goodsAllNum = 0
    local methodListTable = {}
    for i = #materialList, 1 do
        if checkint(materialList[i].num) == 0 or checkint(materialList[i].goodsId) == 0    then
            table.remove(materialList , i)
        end
    end
    for i, v in pairs(materialList) do
        goodsAllNum = goodsAllNum + checkint(v.num)
        methodListTable[tostring(v.goodsId)] = v.num
    end
    local starNum = nil
    local formulaId = nil
    for id, formulaOneConf in pairs(formulaConf) do
        local materials = formulaOneConf.materials
        local materialsMap = {}
        for i, materialId in pairs(materials) do
            materialsMap[tostring(materialId)] = materialId
        end
        if checkint(formulaOneConf.method) == method then
            -- 判断是否满足零星
            local isStar = true
            -- 判断种类数量是否相同
            if  #materials == #materialList then
                for index , goodsData in pairs(materialList) do
                    if not materialsMap[tostring(goodsData.goodsId)] then
                        isStar = false
                        break
                    end
                end
            else
                isStar = false
            end
            if not isStar then
                break
            else
                formulaId = id
                starNum = 0
            end

            -- 判断是否满足一星
            local matchingAllNum =  0
            for i = 1, #formulaOneConf.matching do
                matchingAllNum = checkint(formulaOneConf.matching[i])
            end
            if goodsAllNum >= matchingAllNum then
                starNum = 1
            else
                break
            end

            -- 判断是否满足二星
            for i = 1, #materials do
                local materialId = materials[i]
                if materialList[tostring(materialId)] and
                    checkint(materialList[tostring(materialId)]) == checkint(formulaOneConf.matching[i]) then
                else
                    isStar = false
                end
            end

            if not isStar then
                break
            else
                starNum =  2
            end

            -- 判断是否满足三星
            local materialKeyTable = {}
            for i, v in pairs(materialList) do
                materialKeyTable[#materialKeyTable+1] = v.goodsId
            end
            local materialKeyStr =  table.concat(materialKeyTable , ";")
            if materialKeyStr == formulaOneConf.order or
            (materialKeyStr ..";" ==  formulaOneConf.order ) then
                starNum =  3
                break
            else
                break
            end
        end
    end
    if starNum and formulaId then
        local formulaOneConf = formulaConf[tostring(formulaId)]
        local drinkId =  checkint(formulaOneConf.drinks[starNum+1])
        if drinkId > 0  then
            return drinkId
        end
    end
end
----=======================----
--@author : xingweihao
--@date : 2020/4/11 11:22 AM
--@Description 检测制作配方的材料是否充足
--@params
--@return
---=======================----
function WaterBarManager:CheckMaterialEnoughByFormulaId(formulaId)
    local formulaConf = CONF.BAR.FORMULA:GetValue(formulaId)
    local materials = formulaConf.materials or {}
    local isEnough = true
    for index, materialId in pairs(materials) do
        local ownNum = self:getMaterialNum(materialId)
        if ownNum <= 0 then
            isEnough = false
        end
    end
    return isEnough
end
----=======================----
--@author : xingweihao
--@date : 2020/4/11 11:27 AM
--@Description 获取到自由调试是否解锁
--@params
--@return
---=======================----
function WaterBarManager:GetIsUnLockFreeDev()
    return self:getBarLevel() >= FOOD.WATER_BAR.UNLCOK_LEVEL.FREE_DEV
end
----=======================----
--@author : xingweihao
--@date : 2020/3/3 1:44 PM
--@Description  获取到喜欢该配方的顾客
--@params formulaId 配方id
--@return
---=======================----
function WaterBarManager:GetCustomersLikeFormulaByFormulaId(formulaId)
    local customerConf = CONF.BAR.CUSTOMER:GetAll()
    local customerLikeTable = {}
    formulaId = checkint(formulaId)
    for customerId , customerOneConf in pairs(customerConf) do
        for index, id  in pairs(customerOneConf.formula) do
            if formulaId == checkint(id) then
                local cardId = checkint(customerOneConf.cardId)
                if cardId > 0  then
                    customerLikeTable[#customerLikeTable+1] = cardId
                end
                break
            end
        end
    end
    return customerLikeTable
end

function WaterBarManager:UpdateFrequencyPointRewardsByCustomerId(customerId , rewardId)
    customerId = checkint(customerId)
    if customerId == 0 then return end
    rewardId = checkint(rewardId)
    local customers = self:getHomeData().customers
    for index , customerData in pairs(customers) do
        if checkint(customerData.customerId) == customerId then
            local isHaveRewardId = false
            for index, rewardValue in pairs(customerData.frequencyPointRewards) do
                if checkint(rewardValue) == rewardId then
                    isHaveRewardId = true
                end
            end
            if not isHaveRewardId then
                customerData.frequencyPointRewards[#customerData.frequencyPointRewards+1] = rewardId
            end
            break
        end
    end
end
function WaterBarManager:JudgeCustomerDrawRewardsByCustomerId(customerId)
    local customers = self:getCustomerData(customerId) or {}
    local frequencyPointRewards = customers.frequencyPointRewards or {}
    local frequencyPoint = checkint(customers.frequencyPoint)
    local customerId = customers.customerId
    local customerConf = CONF.BAR.CUSTOMER_FREQUENCY_POINT:GetValue(customerId)
    local canRewardsCount = 0
    for point, pointData in pairs(customerConf) do
        if frequencyPoint >= checkint(point) then
            canRewardsCount = canRewardsCount+1
        end
    end
    if canRewardsCount > #frequencyPointRewards then
        return true
    else
        return false
    end
end
function WaterBarManager:GetFormulaIdStatus(formulaId)
    local isHave = self:hasFormula(formulaId)
    if isHave then
        local highStar = self:getFormulaMaxStar(formulaId)
        if highStar >= 0  then
            return FOOD.WATER_BAR.FORMULA_STATUS.UNLOCK_MAKE
        else
            return FOOD.WATER_BAR.FORMULA_STATUS.UNLCOK_NOT_MAKE
        end
    end
    local formulaOneConf = CONF.BAR.FORMULA:GetValue(formulaId)
    if checkint(formulaOneConf.hide) > 1 then
        return FOOD.WATER_BAR.FORMULA_STATUS.HIDE
    end
    return FOOD.WATER_BAR.FORMULA_STATUS.LEVEL_LOCK
end

-------------------------------------------------
-- private method


return WaterBarManager
