--[[
 * author : kaishiqi
 * descpt : 工会派对 - 回合结算中介者
]]
local UnionPartyRoundResultMediator = class('UnionPartyRoundResultMediator', mvc.Mediator)

local RES_DICT = {
    TOP_ICON_FOOD = 'ui/union/party/party/guild_party_ico_eat_food_default.png',
}

local SHOW_TIME  = 10
local CreateView = nil


function UnionPartyRoundResultMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'UnionPartyRoundResultMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance method

function UnionPartyRoundResultMediator:Initial(key)
    self.super.Initial(self, key)

    -- parse args
    self.partyModel_       = self.ctorArgs_.partyModel
    local roundReadyStepId = checkint(self.ctorArgs_.readyStepId)
    self.dropFood1StepId_  = roundReadyStepId - 6
    self.dropFood2StepId_  = roundReadyStepId - 1
    self.resultShowTime_   = 0

    -- create view
    self.viewData_   = CreateView()
    local uiManager  = self:GetFacade():GetManager('UIManager')
    self.ownerScene_ = uiManager:GetCurrentScene()
    self.ownerScene_:AddDialog(self.viewData_.view)

    -- update views
    self:getViewData().resultSpine:setVisible(false)
    self:getViewData().resultLayer:setVisible(false)
    self:checkFoodGradeSync_()

    local resultRoundNum = 0
    if roundReadyStepId == UNION_PARTY_STEPS.R2_READY_START then
        resultRoundNum = 1
    elseif roundReadyStepId == UNION_PARTY_STEPS.R3_READY_START then
        resultRoundNum = 2
    elseif roundReadyStepId == UNION_PARTY_STEPS.ENDING then
        resultRoundNum = 3
    end
    display.commonLabelParams(self:getViewData().roundResultBrand, {text = string.fmt(__('第_num_回合成绩'), {_num_ = resultRoundNum})})
end


function UnionPartyRoundResultMediator:CleanupView()
    self:stopResultCountdownUpdate_()

    if self.ownerScene_ and self:getViewData().view:getParent() then
        self.ownerScene_:RemoveDialog(self:getViewData().view)
        self.ownerScene_ = nil
    end
end


function UnionPartyRoundResultMediator:OnRegist()
end
function UnionPartyRoundResultMediator:OnUnRegist()
end


function UnionPartyRoundResultMediator:InterestSignals()
    return {
        SGL.UNION_PARTY_MODEL_FOOD_GRADE_SYNC_CHANGE,
    }
end
function UnionPartyRoundResultMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    if SGL.UNION_PARTY_MODEL_FOOD_GRADE_SYNC_CHANGE then
        self:checkFoodGradeSync_()
    end
end


-------------------------------------------------
-- create view

CreateView = function()
    local view = display.newLayer()
    local size = view:getContentSize()

    -- block bg
    local blockBg = display.newLayer(0, 0, {color = cc.c4b(0,0,0,100), enable = true})
    view:addChild(blockBg)

    -- add spine cache
    local resultSpinePath = 'effects/rewardgoods/skeleton'
    if not SpineCache(SpineCacheName.UNION):hasSpineCacheData(resultSpinePath) then
        SpineCache(SpineCacheName.UNION):addCacheData(resultSpinePath, resultSpinePath, 1)
    end

    -- create result spine
    local resultSpine = SpineCache(SpineCacheName.UNION):createWithName(resultSpinePath)
    resultSpine:setPosition(display.center)
    view:addChild(resultSpine)
    
    -- time label
    local timeLabel = display.newLabel(display.cx, display.cy - 175, fontWithColor(14))
    view:addChild(timeLabel)
    
    -------------------------------------------------
    -- result layer
    local resultSize  = size
    local resultLayer = display.newLayer(size.width/2, size.height/2, {size = resultSize, ap = display.CENTER})
    view:addChild(resultLayer)

    local roundResultBrand = display.newLabel(resultSize.width/2, resultSize.height/2 + 80, fontWithColor(20, {fontSize = 40, color1 = '#FF8E1F'}))
    resultLayer:addChild(roundResultBrand)

    local foodResultPoint = cc.p(resultSize.width/2 - 150, resultSize.height/2 - 30)
    local foodResultIcon  = display.newImageView(_res(RES_DICT.TOP_ICON_FOOD), foodResultPoint.x, foodResultPoint.y - 30)
    local foodResultLabel = display.newLabel(foodResultPoint.x, foodResultPoint.y - 30, fontWithColor(19, {fontSize = 50}))
    local foodResultBrand = display.newLabel(foodResultPoint.x, foodResultPoint.y + 30, {fontSize = 32, color = '#FFC350', text = __('吃菜数量')})
    resultLayer:addChild(foodResultBrand)
    resultLayer:addChild(foodResultLabel)
    resultLayer:addChild(foodResultIcon)

    local goldResultPoint = cc.p(foodResultPoint.x + 300, foodResultPoint.y)
    local goldIconPath    = CommonUtils.GetGoodsIconPathById(UNION_POINT_ID)
    local goldResultIcon  = display.newImageView(_res(goldIconPath), goldResultPoint.x, goldResultPoint.y - 30, {scale = 0.32, enable = true})
    local goldResultLabel = display.newLabel(goldResultPoint.x, goldResultPoint.y - 30, fontWithColor(19, {fontSize = 50}))
    local goldResultBrand = display.newLabel(goldResultPoint.x, goldResultPoint.y + 30, {fontSize = 32, color = '#FFC350', text = __('吃菜收益')})
    resultLayer:addChild(goldResultBrand)
    resultLayer:addChild(goldResultLabel)
    resultLayer:addChild(goldResultIcon)

    display.commonUIParams(goldResultIcon, {cb = function(sender)
        app.uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = UNION_POINT_ID, type = 1})
    end, animate = false})

    return {
        view             = view,
        timeLabel        = timeLabel,
        resultSpine      = resultSpine,
        resultLayer      = resultLayer,
        roundResultBrand = roundResultBrand,
        foodResultIcon   = foodResultIcon,
        foodResultLabel  = foodResultLabel,
        foodLabelPoint   = cc.p(foodResultLabel:getPosition()),
        goldResultIcon   = goldResultIcon,
        goldResultLabel  = goldResultLabel,
        goldLabelPoint   = cc.p(goldResultLabel:getPosition()),
    }
end


-------------------------------------------------
-- get / set

function UnionPartyRoundResultMediator:getViewData()
    return self.viewData_
end


function UnionPartyRoundResultMediator:setTimeEndCB(callback)
    self.timeEndCB_ = callback
end


-------------------------------------------------
-- public method

function UnionPartyRoundResultMediator:close()
    self:GetFacade():UnRegsitMediator(self:GetMediatorName())
end


-------------------------------------------------
-- private method

function UnionPartyRoundResultMediator:checkFoodGradeSync_()
    local dropFood1GradeSync = self.partyModel_:isFoodGradeSync(self.dropFood1StepId_)
    local dropFood2GradeSync = self.partyModel_:isFoodGradeSync(self.dropFood2StepId_)
    if dropFood1GradeSync and dropFood2GradeSync then
        local viewData = self:getViewData()
        viewData.resultSpine:setVisible(true)
        viewData.resultLayer:setVisible(true)

        -- update foodScore / goldScore
        local roundFoodScore = self.partyModel_:getFoodScore(self.dropFood1StepId_) + self.partyModel_:getFoodScore(self.dropFood2StepId_)
        local roundGoldScore = self.partyModel_:getGoldScore(self.dropFood1StepId_) + self.partyModel_:getGoldScore(self.dropFood2StepId_)
        display.commonLabelParams(viewData.foodResultLabel, {text = tostring(roundFoodScore)})
        display.commonLabelParams(viewData.goldResultLabel, {text = tostring(roundGoldScore)})

        -- update foodResult info
        local foodLabelSize = display.getLabelContentSize(viewData.foodResultLabel)
        viewData.foodResultIcon:setPositionX(viewData.foodLabelPoint.x + foodLabelSize.width/2)
        viewData.foodResultLabel:setPositionX(viewData.foodLabelPoint.x - 40)

        -- update goldResult info
        local goldLabelSize = display.getLabelContentSize(viewData.goldResultLabel)
        viewData.goldResultIcon:setPositionX(viewData.goldLabelPoint.x + goldLabelSize.width/2)
        viewData.goldResultLabel:setPositionX(viewData.goldLabelPoint.x - 40)

        self:showRoundResult_()
    end
end


function UnionPartyRoundResultMediator:showRoundResult_()
    local viewData = self:getViewData()
    viewData.resultLayer:setScaleY(0)
    viewData.resultSpine:setAnimation(0, 'play', false)
    viewData.view:stopAllActions()
    viewData.view:runAction(cc.Sequence:create({
        cc.DelayTime:create(1),
        cc.TargetedAction:create(viewData.resultLayer, cc.ScaleTo:create(0.2, 1)),
        cc.CallFunc:create(function()
            self:updateResultLeftTime_()
            self:startResultCountdownUpdate_()
        end)
    }))
end
function UnionPartyRoundResultMediator:hideRoundResult_()
    local viewData = self:getViewData()
    viewData.timeLabel:setVisible(false)
    viewData.view:stopAllActions()
    viewData.view:runAction(cc.Sequence:create({
        cc.Spawn:create({
            cc.TargetedAction:create(viewData.resultSpine, cc.ScaleTo:create(0.2, 0)),
            cc.TargetedAction:create(viewData.resultLayer, cc.ScaleTo:create(0.2, 0)),
        }),
        cc.CallFunc:create(function()
            if self.timeEndCB_ then self.timeEndCB_() end
            self:close()
        end)
    }))
end


function UnionPartyRoundResultMediator:startResultCountdownUpdate_()
    if self.resultCountdownUpdateHandler_ then return end
    self.resultCountdownUpdateHandler_ = scheduler.scheduleGlobal(function()
        self.resultShowTime_ = self.resultShowTime_ + 1
        self:updateResultLeftTime_()

        if self.resultShowTime_ >= SHOW_TIME then
            self:stopResultCountdownUpdate_()
            self:hideRoundResult_()
        end
    end, 1)
end
function UnionPartyRoundResultMediator:stopResultCountdownUpdate_()
    if self.resultCountdownUpdateHandler_ then
        scheduler.unscheduleGlobal(self.resultCountdownUpdateHandler_)
        self.resultCountdownUpdateHandler_ = nil
    end
end
function UnionPartyRoundResultMediator:updateResultLeftTime_()
    local resultTimeLeft = SHOW_TIME - self.resultShowTime_
    display.commonLabelParams(self:getViewData().timeLabel, {text = string.fmt(__('_num_秒后自动关闭'), {_num_ = resultTimeLeft})})
end


return UnionPartyRoundResultMediator
