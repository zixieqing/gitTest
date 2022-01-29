--[[
 * author : kaishiqi
 * descpt : 工会派对 - 掉菜中介者
]]
local socket                     = require('socket')
local UnionConfigParser          = require('Game.Datas.Parser.UnionConfigParser')
local UnionPartyDropFoodView     = require('Game.views.union.UnionPartyDropFoodView')
local UnionPartyDropFoodMediator = class('UnionPartyDropFoodMediator', mvc.Mediator)

local PRE_DROP_TIME = 1000
local FREEZE_TIME   = 2000
local AREA_COUNT    = 10
local DROP_SPACE    = display.SAFE_RECT.width / AREA_COUNT
local DROP_SPEED    = display.height / 2000

function UnionPartyDropFoodMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'union.UnionPartyDropFoodMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance method

function UnionPartyDropFoodMediator:Initial(key)
    self.super.Initial(self, key)

    -- parse args
    self.partyModel_     = self.ctorArgs_.partyModel
    self.partyStepId_    = checkint(self.ctorArgs_.stepId)
    self.foodAtErrorCB_  = self.ctorArgs_.foodAtErrorCB
    
    -- food gold
    local unionManager  = self:GetFacade():GetManager('UnionManager')
    local foodGoldConfs = CommonUtils.GetConfigAllMess(UnionConfigParser.TYPE.PARTY_FOOD_GOLD, 'union') or {}
    local foodGoldMap   = foodGoldConfs[tostring(self.partyModel_:getUnionLevel())] or {}
    self.baseFoodGold_  = checkint(foodGoldMap[tostring(self.partyModel_:getPartyLevel())])
    self.foodGradeMap_  = self.partyModel_:getFoodGradeMap() or {}
    
    -- drop time
    local partyStepInfo    = unionManager:getPartyStepInfo(self.partyStepId_) or {}
    self.dropStartTime_    = checkint(partyStepInfo.startTime)
    self.serverTimeOffset_ = socket.gettime() - getServerTime()
    
    -- product info
    self.productFoodInfo_   = {data = {}, index = 0, length = 0}
    self.productSpriteInfo_ = {data = {}, index = 0, length = 0}
    
    -- data sets
    self.foodDataList_   = {}
    self.streakViewMap_  = {}
    self.spriteDataList_ = {}

    -- others var
    self.clickFoodList_     = {}
    self.clickSpriteList_   = {}
    self.isDropFoodAtError_ = false
    self.isControllable_    = true
    self.freezeEndedTime_   = 0

    -- create view
    local uiManager    = self:GetFacade():GetManager('UIManager')
    self.ownerScene_   = uiManager:GetCurrentScene()
    self.dropFoodView_ = UnionPartyDropFoodView.new()
    self.ownerScene_:AddDialog(self.dropFoodView_)

    -- save player gold
    local gameManager = self:GetFacade():GetManager('GameManager')
    self.partyModel_:setTempPlayerGold(gameManager:GetAmountByIdForce(UNION_POINT_ID))
end


function UnionPartyDropFoodMediator:CleanupView()
    self:stopDropFoodUpdate_()

    if self.ownerScene_ and self.dropFoodView_ and self.dropFoodView_:getParent() then
        self.ownerScene_:RemoveDialog(self.dropFoodView_)
        self.ownerScene_   = nil
        self.dropFoodView_ = nil
    end
end


function UnionPartyDropFoodMediator:OnRegist()
    regPost(POST.UNION_PARTY_DROP_FOOD_AT, true)

    self:SendSignal(POST.UNION_PARTY_DROP_FOOD_AT.cmdName, {stepId = self.partyStepId_, partyBaseTime = app.unionMgr:getPartyBaseTime()})
end
function UnionPartyDropFoodMediator:OnUnRegist()
    regPost(POST.UNION_PARTY_DROP_FOOD_AT)

    if not self.isDropFoodAtError_ then
        self.partyModel_:setFoodGradeSync(self.partyStepId_, false)
        self:SendSignal(POST.UNION_PARTY_DROP_FOOD_GRADE.cmdName, {
            stepId        = self.partyStepId_,
            clickFoods    = table.concat(self.clickFoodList_, ';'),
            clickRubies   = table.concat(self.clickSpriteList_, ';'),
            foodScore     = self.partyModel_:getFoodScore(self.partyStepId_),
            goldScore     = self.partyModel_:getGoldScore(self.partyStepId_),
            partyBaseTime = app.unionMgr:getPartyBaseTime(),
        })
    end
end


function UnionPartyDropFoodMediator:InterestSignals()
    return {
        POST.UNION_PARTY_DROP_FOOD_AT.sglName,
    }
end
function UnionPartyDropFoodMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    if name == POST.UNION_PARTY_DROP_FOOD_AT.sglName then
        -- check error
        if checkint(data.errcode) ~= 0 then
            self.isDropFoodAtError_ = true

            if self.foodAtErrorCB_ then
                self.foodAtErrorCB_(self.partyStepId_, data.errmsg)
            end
            self:close()

        else
            -- start drop
            self.productFoodInfo_.data     = string.split2(checkstr(data.dropFoods), ';')
            self.productFoodInfo_.length   = table.nums(self.productFoodInfo_.data)
            self.productSpriteInfo_.data   = string.split2(checkstr(data.dropRubies), ';')
            self.productSpriteInfo_.length = table.nums(self.productSpriteInfo_.data)
            self:updateAllDropFood_()
            self:updateAllDropSprite_()
            self:startDropFoodUpdate_()
        end
    end
end


-------------------------------------------------
-- get / set

function UnionPartyDropFoodMediator:getDropFoodView()
    return self.dropFoodView_
end


function UnionPartyDropFoodMediator:getPassTime()
    local passTime = (socket.gettime() - self.serverTimeOffset_ - self.dropStartTime_) * 1000
    return checkint(passTime)
end


-------------------------------------------------
-- public method

function UnionPartyDropFoodMediator:close()
    self:GetFacade():UnRegsitMediator(self:GetMediatorName())
end


-------------------------------------------------
-- private method

function UnionPartyDropFoodMediator:calculateFoodPos_(dropTime, dropSpeed, areaId)
    local foodPosY = display.height - (self:getPassTime() - checkint(dropTime)) * checknumber(dropSpeed)
    local foodPosX = display.SAFE_RECT.x + DROP_SPACE * (checkint(areaId) - 0.5)
    return cc.p(checkint(foodPosX), checkint(foodPosY))
end


function UnionPartyDropFoodMediator:startDropFoodUpdate_()
    if self.dropFoodUpdateHandler_ then return end
    self.dropFoodUpdateHandler_ = scheduler.scheduleUpdateGlobal(function()

        -- update drop
        self:updateAllDropSprite_()
        self:updateAllDropFood_()

        -- check freeze
        if not self.isControllable_ and self:getPassTime() > self.freezeEndedTime_ then
            self.isControllable_ = true
        end
    end)
end
function UnionPartyDropFoodMediator:stopDropFoodUpdate_()
    if self.dropFoodUpdateHandler_ then
        scheduler.unscheduleGlobal(self.dropFoodUpdateHandler_)
        self.dropFoodUpdateHandler_ = nil
    end
end


function UnionPartyDropFoodMediator:updateAllDropFood_()
    local terminalTime   = (getServerTime() - self.dropStartTime_) * 1000 + PRE_DROP_TIME
    local terminalIndex  = self.productFoodInfo_.index
    local terminalLength = self.productFoodInfo_.length

    -- check create food
    for i = terminalIndex, terminalLength do
        local dataStr   = checkstr(self.productFoodInfo_.data[i])
        local dropData  = string.split2(checkstr(dataStr), ',')
        local dropTime  = checkint(dropData[1])
        local foodId    = checkint(dropData[2])
        local areaId    = checkint(dropData[3])
        local foodGrade = checkint(self.foodGradeMap_[tostring(foodId)])
        local isSpecial = foodGrade >= 5
        local foodData  = {
            width     = 0,
            height    = 0,
            foodId    = foodId,
            areaId    = areaId,
            dropTime  = dropTime,
            isSpecial = isSpecial,
            foodGold  = self.baseFoodGold_ * (isSpecial and 2 or 1),
            dropSpeed = DROP_SPEED * (isSpecial and 2 or 1),
        }
        terminalIndex = i

        -- check out of terminalTime
        if dropTime > terminalTime then
            break
            
        else
            -- check outside display
            local foodPos = self:calculateFoodPos_(dropTime, foodData.dropSpeed)
            if foodPos.y >= display.height then
                
                -- create foodView
                foodData.isDead = false
                foodData.view   = self:getDropFoodView():appendFoodView(foodId)
                foodData.width  = foodData.view:getContentSize().width
                foodData.height = foodData.view:getContentSize().height
                table.insert(self.foodDataList_, foodData)

                display.commonUIParams(foodData.view, {cb = handler(self, self.onClickFoodViewHandler_), animate = false})
                foodData.view:setTag(i)

                -- create streakView
                if isSpecial then
                    local streakView = self:getDropFoodView():appendMotionView(foodData.view)
                    self.streakViewMap_[tostring(foodData.view:getTag())] = streakView
                end
            end

            -- check last index
            if terminalIndex == terminalLength then
                terminalIndex = terminalLength + 1
            end
        end
    end
    self.productFoodInfo_.index = terminalIndex

    -------------------------------------------------
    -- update food drop
    for i = #self.foodDataList_, 1, -1 do

        -- update pos
        local foodData = self.foodDataList_[i]
        local foodPos  = self:calculateFoodPos_(foodData.dropTime, foodData.dropSpeed, foodData.areaId)
        foodData.view:setPosition(foodPos)

        -- check destroy
        if foodPos.y + foodData.height < -display.cy or foodData.view:isVisible() == false then
            self:getDropFoodView():removeFoodView(foodData.view)
            table.remove(self.foodDataList_, i)

        -- check dead
        elseif foodData.isDead then
            table.remove(self.foodDataList_, i)
        end
    end

    -------------------------------------------------
    -- update streak drop
    for foodViewTag, streakView in pairs(self.streakViewMap_) do
        local foodView = self:getDropFoodView():getFoodViewByTag(foodViewTag)
        if foodView and foodView:isVisible() and streakView:isVisible() then
            streakView:setPosition(foodView:getPosition())
        else
            self:getDropFoodView():removeMotionView(streakView)
            self.streakViewMap_[foodViewTag] = nil
        end
    end
end
function UnionPartyDropFoodMediator:updateAllDropSprite_()
    local terminalTime   = (getServerTime() - self.dropStartTime_) * 1000 + PRE_DROP_TIME
    local terminalIndex  = self.productSpriteInfo_.index
    local terminalLength = self.productSpriteInfo_.length

    -- check create sprite
    for i = terminalIndex, terminalLength do
        local dataStr    = checkstr(self.productSpriteInfo_.data[i])
        local dropData   = string.split2(checkstr(dataStr), ',')
        local dropTime   = checkint(dropData[1])
        local areaId     = checkint(dropData[2])
        local spriteData = {
            width     = 0,
            height    = 0,
            areaId    = areaId,
            dropTime  = dropTime,
            dropSpeed = DROP_SPEED,
        }
        terminalIndex = i

        -- check out of terminalTime
        if dropTime > terminalTime then
            break
            
        else
            -- check outside display
            local spritePos = self:calculateFoodPos_(dropTime, spriteData.dropSpeed)
            if spritePos.y >= display.height then
                
                -- create spriteView
                spriteData.isDead = false
                spriteData.view   = self:getDropFoodView():appendSpriteView()
                spriteData.width  = spriteData.view:getContentSize().width
                spriteData.height = spriteData.view:getContentSize().height
                table.insert(self.spriteDataList_, spriteData)

                display.commonUIParams(spriteData.view, {cb = handler(self, self.onClickSpriteViewHandler_), animate = false})
                spriteData.view:setTag(i)
            end

            -- check last index
            if terminalIndex == terminalLength then
                terminalIndex = terminalLength + 1
            end
        end
    end
    self.productSpriteInfo_.index = terminalIndex

    -------------------------------------------------
    -- update sprite drop
    for i = #self.spriteDataList_, 1, -1 do
        
        -- update pos
        local spriteData = self.spriteDataList_[i]
        local spritePos  = self:calculateFoodPos_(spriteData.dropTime, spriteData.dropSpeed, spriteData.areaId)
        spriteData.view:setPosition(spritePos)

        -- check destroy
        if spritePos.y + spriteData.height < -display.cy or spriteData.view:isVisible() == false then
            self:getDropFoodView():removeFoodView(spriteData.view)
            table.remove(self.spriteDataList_, i)

        -- check dead
        elseif spriteData.isDead then
            table.remove(self.spriteDataList_, i)
        end
    end
end


-------------------------------------------------
-- handler

function UnionPartyDropFoodMediator:onClickFoodViewHandler_(sender)
    if not self.isControllable_ then return end
    sender:setTouchEnabled(false)
    
    -- record click food
    local foodIndex = sender:getTag()
    local passTime  = self:getPassTime()
    local dropStr   = checkstr(self.productFoodInfo_.data[foodIndex])
    local dropData  = string.split2(checkstr(dropStr), ',')
    local foodId    = checkint(dropData[2])
    table.insert(self.clickFoodList_, table.concat({foodIndex, passTime, foodId}, ','))

    -- check dead food
    for i, foodData in ipairs(self.foodDataList_) do
        if foodData.view and foodData.view:getTag() == foodIndex then
            -- mark food dead
            if self:getDropFoodView() then
                self:getDropFoodView():deadFoodView(foodData.view, foodData.foodGold, foodData.isSpecial)
            end
            foodData.isDead = true

            -- update party score
            local addGoldNum = checkint(foodData.foodGold)
            self.partyModel_:addFoodScore(self.partyStepId_, 1)
            self.partyModel_:addGoldScore(self.partyStepId_, addGoldNum)

            -- update palyer gold
            local gameManager   = self:GetFacade():GetManager('GameManager')
            local newUnionPoint = gameManager:GetAmountByIdForce(UNION_POINT_ID) + addGoldNum
            CommonUtils.DrawRewards({
                {goodsId = UNION_POINT_ID, num = newUnionPoint}
            })
            -- gameManager:GetUserInfo().gold = gameManager:GetUserInfo().gold + addGoldNum
            AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.CACHE_MONEY_UPDATE_UI)
            break
        end
    end

end


function UnionPartyDropFoodMediator:onClickSpriteViewHandler_(sender)
    if not self.isControllable_ then return end
    sender:setTouchEnabled(false)

    -- record click sprite
    local spriteIndex = sender:getTag()
    local passTime    = self:getPassTime()
    local dropStr     = checkstr(self.productSpriteInfo_.data[spriteIndex])
    local dropData    = string.split2(checkstr(dropStr), ',')
    table.insert(self.clickSpriteList_, table.concat({spriteIndex, passTime}, ','))

    -- freeze control
    self.isControllable_  = false
    self.freezeEndedTime_ = passTime + FREEZE_TIME
    
    -- check dead sprite
    for i, spriteData in ipairs(self.spriteDataList_) do
        if spriteData.view and spriteData.view:getTag() == spriteIndex then
            -- mark sprite dead
            self:getDropFoodView():deadSpriteView(spriteData.view, FREEZE_TIME/1000)
            spriteData.isDead = true
            break
        end
    end
end


return UnionPartyDropFoodMediator
