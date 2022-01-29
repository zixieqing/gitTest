--[[
 * author : kaishiqi
 * descpt : 新抽卡 - 基础抽卡 中介者
]]
local RewardsAnimateMediator  = require('Game.mediator.drawCards.CapsuleAnimateMediator')
local CapsuleBasicGetMediator = class('CapsuleBasicGetMediator', mvc.Mediator)

local RES_DICT = {
    ORANGE_BTN_N = _res('ui/common/common_btn_big_orange_2.png'),
    ORANGE_BTN_D = _res('ui/common/common_btn_big_orange_disabled_2.png'),
    DRAW_BTN_BAR = _res('ui/home/capsuleNew/basic/summon_basic_bg_1.png'),
}

local DRAW_ONCE_TYPE = 1
local DRAW_MUCH_TYPE = 2

local CreateView = nil


function CapsuleBasicGetMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'CapsuleBasicGetMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance method

function CapsuleBasicGetMediator:Initial(key)
    self.super.Initial(self, key)

    self.ownerNode_      = self.ctorArgs_.ownerNode
    self.isControllable_ = true

    -- create view
    if self.ownerNode_ then
        self.viewData_ = CreateView(self.ownerNode_:getContentSize())
        self.ownerNode_:addChild(self.viewData_.view)

        -- add listener
        display.commonUIParams(self:getViewData().drawOnceBtn, {cb = handler(self, self.onClicDrawOnceButtonkHandler_)})
        display.commonUIParams(self:getViewData().drawMuchBtn, {cb = handler(self, self.onClicDrawMuchButtonkHandler_)})
    end
end


function CapsuleBasicGetMediator:CleanupView()
    if self.ownerNode_ then
        if self.viewData_ and self.viewData_.view:getParent() then
            self.viewData_.view:runAction(cc.RemoveSelf:create())
            self.viewData_ = nil
        end
        self.ownerNode_ = nil
    end
end


function CapsuleBasicGetMediator:OnRegist()
    regPost(POST.GAMBLING_LUCKY)
end
function CapsuleBasicGetMediator:OnUnRegist()
    unregPost(POST.GAMBLING_LUCKY)
end


function CapsuleBasicGetMediator:InterestSignals()
    return {
        POST.GAMBLING_LUCKY.sglName,
    }
end
function CapsuleBasicGetMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    if name == POST.GAMBLING_LUCKY.sglName then
        if not data.errcode then
            AppFacade.GetInstance():DispatchObservers("DOT_LOG_EVENT_SEND" , {eventId = "1003-01"})
            local cardRewards = {}
            local isOneDraw   = checkint(data.requestData.type) == DRAW_ONCE_TYPE
            local drawData    = isOneDraw and self:getOnceData() or self:getMuchData()
            local consumeMap  = self:getDrawConsumeMap_()
            local consumeData = consumeMap[tostring(isOneDraw and DRAW_ONCE_TYPE or DRAW_MUCH_TYPE)] or {}

            -- consume draw goods
            CommonUtils.DrawRewards({rewards = {goodsId = consumeData.consumeId, num = -consumeData.consumeNum}})  

            -- update userInfo
            app.gameMgr:GetUserInfo().gold    = checkint(data.gold)
            app.gameMgr:GetUserInfo().diamond = checkint(data.diamond)
            self:GetFacade():DispatchObservers(SIGNALNAMES.CACHE_MONEY_UPDATE_UI)

            -- update leftTimes
            local leftDrawTimes = checkint(drawData.leftTimes)
            if leftDrawTimes > 0 then
                leftDrawTimes = leftDrawTimes - 1
            end
            drawData.leftTimes = leftDrawTimes

            -- update draw info
            self:updateDarwInfo_()

            -- show rewards animate
            for i, goodsData in ipairs(data.rewards or {}) do
                local goodsType = CommonUtils.GetGoodTypeById(goodsData.goodsId)
                if goodsType == GoodsType.TYPE_CARD or goodsType == GoodsType.TYPE_CARD_FRAGMENT then
                    table.insert(cardRewards, goodsData)
                end
            end
            self:GetFacade():RegistMediator(RewardsAnimateMediator.new({rewards = cardRewards, activityRewards = data.activityRewards}))
        end
    end
end


-------------------------------------------------
-- view defines

CreateView = function(size)
    local view = display.newLayer(0, 0, {size = size})
    
    local baseY = 72
    view:addChild(display.newImageView(RES_DICT.DRAW_BTN_BAR, size.width/2 + 5, baseY, {ap = display.RIGHT_CENTER}))
    view:addChild(display.newImageView(RES_DICT.DRAW_BTN_BAR, size.width/2 - 5, baseY, {ap = display.RIGHT_CENTER, rotation = 180}))

    -------------------------------------------------
    -- once info
    local drawOncePos = cc.p(size.width/2 - 200, baseY + 17)
    local drawOnceBtn = display.newButton(drawOncePos.x, drawOncePos.y, {n = RES_DICT.ORANGE_BTN_N, d = RES_DICT.ORANGE_BTN_D})
    display.commonLabelParams(drawOnceBtn, fontWithColor(14, {fontSize = 26, hAlign = display.TAC, text = string.fmt(__('召唤\n_num_次'), {_num_ = 1})}))
    drawOnceBtn:setEnabled(false)
    view:addChild(drawOnceBtn)
    
    local onceConsumeRLable = display.newRichLabel(drawOncePos.x, drawOncePos.y - 62, {sp = 20})
    view:addChild(onceConsumeRLable)

    local onceConsumeCostLabel
    if isJapanSdk() then
        onceConsumeCostLabel = display.newLabel(drawOncePos.x, onceConsumeRLable:getPositionY(), fontWithColor(7, {fontSize = 26, text = ''}))
        view:addChild(onceConsumeCostLabel)
    end

    local onceLeftLable = display.newLabel(drawOncePos.x, drawOncePos.y + 70, fontWithColor(14))
    view:addChild(onceLeftLable)
    
    -------------------------------------------------
    -- much info
    local drawMuchPos = cc.p(size.width/2 + 200, drawOncePos.y)
    local drawMuchBtn = display.newButton(drawMuchPos.x, drawMuchPos.y, {n = RES_DICT.ORANGE_BTN_N, d = RES_DICT.ORANGE_BTN_D})
    display.commonLabelParams(drawMuchBtn, fontWithColor(14, {fontSize = 26, hAlign = display.TAC, text = string.fmt(__('召唤\n_num_次'), {_num_ = 6})}))
    drawMuchBtn:setEnabled(false)
    view:addChild(drawMuchBtn)
    
    local muchConsumeRLable = display.newRichLabel(drawMuchPos.x, onceConsumeRLable:getPositionY(), {sp = 20})
    view:addChild(muchConsumeRLable)

    local muchConsumeCostLabel
    if isJapanSdk() then
        muchConsumeCostLabel = display.newLabel(drawMuchPos.x, muchConsumeRLable:getPositionY(), fontWithColor(7, {fontSize = 26, text = ''}))
        view:addChild(muchConsumeCostLabel)
    end

    local muchLeftLable = display.newLabel(drawMuchPos.x, onceLeftLable:getPositionY(), fontWithColor(14))
    view:addChild(muchLeftLable)

    return {
        view              = view,
        dataLable         = dataLable,
        drawOnceBtn       = drawOnceBtn,
        drawMuchBtn       = drawMuchBtn,
        onceLeftLable     = onceLeftLable,
        muchLeftLable     = muchLeftLable,
        onceConsumeRLable = onceConsumeRLable,
        muchConsumeRLable = muchConsumeRLable,
        onceConsumeCostLabel = onceConsumeCostLabel,
        muchConsumeCostLabel = muchConsumeCostLabel,
    }
end


-------------------------------------------------
-- get /set

function CapsuleBasicGetMediator:getViewData()
    return self.viewData_
end


function CapsuleBasicGetMediator:getOnceData()
    return self.homeData_ and checktable(self.homeData_.one) or {}
end
function CapsuleBasicGetMediator:getMuchData()
    return self.homeData_ and checktable(self.homeData_.six) or {}
end


-------------------------------------------------
-- public method

function CapsuleBasicGetMediator:resetHomeData(homeData)
    self.homeData_ = homeData
    self:updateDarwInfo_()
end


-------------------------------------------------
-- private method

function CapsuleBasicGetMediator:getDrawConsumeMap_()
    local consumeMap  = {}
    local drawDataMap = {
        [tostring(DRAW_ONCE_TYPE)] = self:getOnceData(),
        [tostring(DRAW_MUCH_TYPE)] = self:getMuchData(),
    }
    for drawType, drawData in pairs(drawDataMap) do
        local drawData   = drawDataMap[tostring(drawType)]
        local consumeId  = checkint(drawData.goodsId)
        local consumeNum = checkint(drawData.num)

        if Platform.id > 4000 and Platform.id < 5000 then
            if app.gameMgr:GetAmountByGoodId(consumeId) < consumeNum then
                consumeId  = DIAMOND_ID
                consumeNum = checkint(drawData.diamond)
            end
        end

        consumeMap[tostring(drawType)] = {consumeId = consumeId, consumeNum = consumeNum}
    end
    return consumeMap
end


function CapsuleBasicGetMediator:updateDarwInfo_()
    if not self:getViewData() then return end
    local drawOnceData = self:getOnceData()
    local drawMuchData = self:getMuchData()
    local consumeMap   = self:getDrawConsumeMap_()
    local onceConsume  = consumeMap[tostring(DRAW_ONCE_TYPE)] or {}
    local muchConsume  = consumeMap[tostring(DRAW_MUCH_TYPE)] or {}
    
    -- update consume
    local oncePropNum = checkint(onceConsume.consumeNum)
    local muchPropNum = checkint(muchConsume.consumeNum)
    display.reloadRichLabel(self:getViewData().onceConsumeRLable, {c = {
        fontWithColor(7, {fontSize = 26, text = __('消耗'), }) ,
        fontWithColor(7, {fontSize = 26, text = string.fmt(' %1 ', oncePropNum)}),
        {img = CommonUtils.GetGoodsIconPathById(onceConsume.consumeId), scale = 0.2},
    }})
    display.reloadRichLabel(self:getViewData().muchConsumeRLable, {c = {
        fontWithColor(7, {fontSize = 26, text = __('消耗'), }) ,
        fontWithColor(7, {fontSize = 26, text = string.fmt(' %1 ', muchPropNum)}),
        {img = CommonUtils.GetGoodsIconPathById(muchConsume.consumeId), scale = 0.2},
    }})
    if isJapanSdk() then
        local viewData = self:getViewData()
        display.reloadRichLabel(viewData.onceConsumeRLable, {c = {
            {img = CommonUtils.GetGoodsIconPathById(onceConsume.consumeId), scale = 0.24}
        }})
        viewData.onceConsumeCostLabel:setString(oncePropNum)
        display.setNodesToNodeOnCenter(viewData.drawOnceBtn, {viewData.onceConsumeRLable, viewData.onceConsumeCostLabel}, {y = -20, spaceW = 10})
        display.reloadRichLabel(viewData.muchConsumeRLable, {c = {
            {img = CommonUtils.GetGoodsIconPathById(muchConsume.consumeId), scale = 0.24}
        }})
        viewData.muchConsumeCostLabel:setString(muchPropNum)
        display.setNodesToNodeOnCenter(viewData.drawMuchBtn, {viewData.muchConsumeRLable, viewData.muchConsumeCostLabel}, {y = -20, spaceW = 10})
    end
    
    -- update leftTimes
    local drawMaxTimes  = 20
    local onceLeftTimes = checkint(drawOnceData.leftTimes)
    local muchLeftTimes = checkint(drawMuchData.leftTimes)
    self:getViewData().onceLeftLable:setVisible(onceLeftTimes >= 0)
    self:getViewData().muchLeftLable:setVisible(muchLeftTimes >= 0)
    display.commonLabelParams(self:getViewData().onceLeftLable, {text = string.fmt(__('剩余次数 _num_ / _max_'), {_num_ = onceLeftTimes, _max_ = drawMaxTimes})})
    display.commonLabelParams(self:getViewData().muchLeftLable, {text = string.fmt(__('剩余次数 _num_ / _max_'), {_num_ = muchLeftTimes, _max_ = drawMaxTimes})})

    -- update drawButton
    local isEnableDrawOnce = onceLeftTimes ~= 0
    local isEnableDrawMuch = muchLeftTimes ~= 0
    self:getViewData().drawOnceBtn:setEnabled(isEnableDrawOnce)
    self:getViewData().drawMuchBtn:setEnabled(isEnableDrawMuch)
end


-------------------------------------------------
-- handler

function CapsuleBasicGetMediator:onClicDrawOnceButtonkHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local consumeData     = self:getDrawConsumeMap_()[tostring(DRAW_ONCE_TYPE)] or {}
    local consumeGoodsId  = checkint(consumeData.consumeId)
    local consumeGoodsNum = checkint(consumeData.consumeNum)
    if app.gameMgr:GetAmountByGoodId(consumeGoodsId) >= consumeGoodsNum then
        self:SendSignal(POST.GAMBLING_LUCKY.cmdName, {type = DRAW_ONCE_TYPE})
    else
        app.capsuleMgr:ShowGoodsShortageTips(consumeGoodsId)
    end
end


function CapsuleBasicGetMediator:onClicDrawMuchButtonkHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local consumeData     = self:getDrawConsumeMap_()[tostring(DRAW_MUCH_TYPE)] or {}
    local consumeGoodsId  = checkint(consumeData.consumeId)
    local consumeGoodsNum = checkint(consumeData.consumeNum)
    if app.gameMgr:GetAmountByGoodId(consumeGoodsId) >= consumeGoodsNum then
        self:SendSignal(POST.GAMBLING_LUCKY.cmdName, {type = DRAW_MUCH_TYPE})
    else
        app.capsuleMgr:ShowGoodsShortageTips(consumeGoodsId)
    end
end


return CapsuleBasicGetMediator
