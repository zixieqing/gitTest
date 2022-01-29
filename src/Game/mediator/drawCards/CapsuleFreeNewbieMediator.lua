-------------------------------------------------------------------------------
-- 新抽卡 - 免费新手抽卡 中介者
-- 
-- Author: kaishiqi <zhangkai@funtoygame.com>
-- 
-- Create: 2021-09-22 17:40:06
-------------------------------------------------------------------------------
local RewardsAnimateMediator    = require('Game.mediator.drawCards.CapsuleAnimateMediator')
local CapsuleFreeNewbieView     = require("Game.views.drawCards.CapsuleFreeNewbieView")
---@class CapsuleFreeNewbieMediator : Mediator
local CapsuleFreeNewbieMediator = class('CapsuleFreeNewbieMediator', mvc.Mediator)

local DRAW_ONCE_COUNT = 1
local DRAW_MUCH_COUNT = 10


function CapsuleFreeNewbieMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'CapsuleFreeNewbieMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance method

function CapsuleFreeNewbieMediator:Initial(key)
    self.super.Initial(self, key)

    self.ownerNode_      = self.ctorArgs_.ownerNode
    self.isControllable_ = true

    -- create view
    if self.ownerNode_ then
        self.viewNode_ = CapsuleFreeNewbieView.new(self.ownerNode_:getContentSize())
        self.ownerNode_:addChild(self.viewNode_)
        self:SetViewComponent(self.viewNode_)

        -- add listener
        display.commonUIParams(self:getViewData().drawOnceBtn, {cb = handler(self, self.onClicDrawOnceButtonkHandler_)})
        display.commonUIParams(self:getViewData().drawMuchBtn, {cb = handler(self, self.onClicDrawMuchButtonkHandler_)})
        display.commonUIParams(self:getViewData().finalRewardsBtn, {cb = handler(self, self.onClicFinalRewardsButtonkHandler_)})
        display.commonUIParams(self:getViewData().countRewardsBtn, {cb = handler(self, self.onClicCountRewardsButtonkHandler_)})
    end
end


function CapsuleFreeNewbieMediator:CleanupView()
    if self.ownerNode_ then
        if self.viewNode_ and self.viewNode_:getParent() then
            self.viewNode_:runAction(cc.RemoveSelf:create())
            self.viewNode_ = nil
        end
        self.ownerNode_ = nil
    end
    
    self:closeFinalRewardsView_()
    self:closeCountRewardsView_()
end


function CapsuleFreeNewbieMediator:OnRegist()
    regPost(POST.GAMBLING_FREE_NEWBIE_LUCKY)
    regPost(POST.GAMBLING_FREE_NEWBIE_DRAW_TASK)
    regPost(POST.GAMBLING_FREE_NEWBIE_DRAW_FINAL)
end
function CapsuleFreeNewbieMediator:OnUnRegist()
    unregPost(POST.GAMBLING_FREE_NEWBIE_LUCKY)
    unregPost(POST.GAMBLING_FREE_NEWBIE_DRAW_TASK)
    unregPost(POST.GAMBLING_FREE_NEWBIE_DRAW_FINAL)
end


function CapsuleFreeNewbieMediator:InterestSignals()
    return {
        POST.GAMBLING_FREE_NEWBIE_LUCKY.sglName,
        POST.GAMBLING_FREE_NEWBIE_DRAW_TASK.sglName,
        POST.GAMBLING_FREE_NEWBIE_DRAW_FINAL.sglName,
    }
end
function CapsuleFreeNewbieMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    if name == POST.GAMBLING_FREE_NEWBIE_LUCKY.sglName then
        local cardRewards = {}
        local isOneDraw   = checkint(data.requestData.type) == 1
        local usedTimes   = isOneDraw and DRAW_ONCE_COUNT or DRAW_MUCH_COUNT
        local consumeData = isOneDraw and self:getOnceConsumeData() or self:getMuchConsumeData()

        -- consume draw goods
        CommonUtils.DrawRewards({rewards = {goodsId = consumeData.goodsId, num = -consumeData.num}})  

        -- update userInfo
        -- app.gameMgr:GetUserInfo().gold    = checkint(data.gold)
        -- app.gameMgr:GetUserInfo().diamond = checkint(data.diamond)
        -- self:GetFacade():DispatchObservers(SIGNALNAMES.CACHE_MONEY_UPDATE_UI)

        -- update gamblingTimes
        self:getHomeData().gamblingTimes = self:getHomeData().gamblingTimes + usedTimes

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


    elseif name == POST.GAMBLING_FREE_NEWBIE_DRAW_TASK.sglName then
        -- mark timesRewards.hasDrawn
        local drawIndex    = 0
        local drawRewardId = checkint(data.requestData.rewardId)
        local timesRewards = checktable(self:getHomeData().timesRewards)
        for rewardIndex, rewardData in ipairs(timesRewards) do
            if checkint(rewardData.rewardId) == drawRewardId then
                rewardData.hasDrawn = 1
                drawIndex = rewardIndex
                break
            end
        end

        -- refresh homeNoticeBoards
        app.gameMgr:checkFreeNewbieCapsuleData(self:getHomeData())

        -- update countRewardsCell
        if drawIndex > 0 and self.countRewardsViewData_ then
            ---@param cellViewData CapsuleFreeNewbieView.CountRewardsCellViewData
            for _, cellViewData in pairs(self.countRewardsViewData_.rewardTableView:getCellViewDataDict()) do
                local cellIndex = checkint(cellViewData.view:getTag())
                if cellIndex == drawIndex then
                    self:getViewNode():updateCountRewardsCellState(cellViewData, true)
                    break
                end
            end
        end

        -- popup drawReward
        app.uiMgr:showRewardPopup({rewards = data.rewards})


    elseif name == POST.GAMBLING_FREE_NEWBIE_DRAW_FINAL.sglName then
        self:closeFinalRewardsView_()

        -- mark finalRewardsHasDrawn
        self:getHomeData().finalRewardsHasDrawn = 1
        self:getViewNode():updateFinalRewardsLight(false)
        self:getViewNode():updateFinalRewardsEnable(false)

        -- refresh homeNoticeBoards
        app.gameMgr:checkFreeNewbieCapsuleData(self:getHomeData())

        -- show rewards animate
        local cardRewards = {}
        for i, goodsData in ipairs(data.rewards or {}) do
            local goodsType = CommonUtils.GetGoodTypeById(goodsData.goodsId)
            if goodsType == GoodsType.TYPE_CARD or goodsType == GoodsType.TYPE_CARD_FRAGMENT then
                table.insert(cardRewards, goodsData)
            end
        end
        self:GetFacade():RegistMediator(RewardsAnimateMediator.new({rewards = cardRewards}))

    end
end

-------------------------------------------------
-- get /set

---@return CapsuleFreeNewbieView
function CapsuleFreeNewbieMediator:getViewNode()
    return self.viewNode_
end
---@return CapsuleFreeNewbieView.ViewData
function CapsuleFreeNewbieMediator:getViewData()
    return self:getViewNode() and self:getViewNode():getViewData() or {}
end


function CapsuleFreeNewbieMediator:getHomeData()
    return self.homeData_ or {}
end


function CapsuleFreeNewbieMediator:getOnceConsumeData()
    local onceGamblingTimes   = checkint(self:getHomeData().oneGamblingTimes)           -- 单抽过的次数
    local onceDiscountTimes   = checkint(self:getHomeData().oneDiscountTimes)           -- 单抽可折扣次数（0就是没折扣）
    local normalOnceConsume   = checktable(self:getHomeData().oneConsume)[1] or {}      -- 单抽正常消耗
    local discountOnceConsume = checktable(self:getHomeData().firstOneConsume)[1] or {} -- 单抽折扣消耗
    return (onceDiscountTimes > 0 and onceGamblingTimes < onceDiscountTimes) and discountOnceConsume or normalOnceConsume
end


function CapsuleFreeNewbieMediator:getMuchConsumeData()
    local mushGamblingTimes   = checkint(self:getHomeData().tenGamblingTimes)           -- 多抽过的次数
    local mushDiscountTimes   = checkint(self:getHomeData().tenDiscountTimes)           -- 多抽可折扣次数（0就是没折扣）
    local normalMushConsume   = checktable(self:getHomeData().tenConsume)[1] or {}      -- 多抽正常消耗
    local discountMushConsume = checktable(self:getHomeData().firstTenConsume)[1] or {} -- 多抽折扣消耗
    return (mushDiscountTimes > 0 and mushGamblingTimes < mushDiscountTimes) and discountMushConsume or normalMushConsume
end


-------------------------------------------------
-- public method

function CapsuleFreeNewbieMediator:resetHomeData(homeData)
    self.homeData_ = homeData
    if self.homeData_.timesRewards then
        table.sort(self.homeData_.timesRewards, function(aData, bData)
            local aHasDrawn  = checkint(aData.hasDrawn)
            local bHasDrawn  = checkint(bData.hasDrawn)
            local aTargetNum = checkint(aData.targetNum)
            local bTargetNum = checkint(bData.targetNum)
            if aHasDrawn == 0 and bHasDrawn == 0 then
                return aTargetNum < bTargetNum
            elseif aHasDrawn == 1 and bHasDrawn == 1 then
                return aTargetNum < bTargetNum
            else
                return aHasDrawn < bHasDrawn
            end
        end)
    end
    self:updateDarwInfo_()
end


-------------------------------------------------
-- private method

function CapsuleFreeNewbieMediator:updateDarwInfo_()
    local isDrawnFinal     = checkint(self:getHomeData().finalRewardsHasDrawn) == 1 -- 是否领取最终奖励
    local useGamblingTimes = checkint(self:getHomeData().gamblingTimes)             -- 已抽次数
    local maxGamblingTimes = checkint(self:getHomeData().maxGamblingTimes)          -- 最大次数
    local hasGamblingTimes = maxGamblingTimes - useGamblingTimes                    -- 剩余次数
    local isEnableDrawOnce = hasGamblingTimes >= DRAW_ONCE_COUNT
    local isEnableDrawMuch = hasGamblingTimes >= DRAW_MUCH_COUNT
    local onceConsumeData  = self:getOnceConsumeData()
    local muchConsumeData  = self:getMuchConsumeData()
    
    -- update leftTimes
    self:getViewNode():updateLeftTimesLabel(hasGamblingTimes)

    -- update finalLight
    self:getViewNode():updateFinalRewardsEnable(not isDrawnFinal)
    self:getViewNode():updateFinalRewardsLight(hasGamblingTimes <= 0 and not isDrawnFinal)
    
    -- update drawButton
    self:getViewNode():updateDrawButtonEnabled(true, isEnableDrawOnce)
    self:getViewNode():updateDrawButtonEnabled(false, isEnableDrawMuch)
    
    -- update consume
    self:getViewNode():updateConsumeRLabel(true, onceConsumeData.goodsId, onceConsumeData.num)
    self:getViewNode():updateConsumeRLabel(false, muchConsumeData.goodsId, muchConsumeData.num)
end


function CapsuleFreeNewbieMediator:closeFinalRewardsView_()
    if self.finalRewardsViewData_ then
        if self.finalRewardsViewData_.view and not tolua.isnull(self.finalRewardsViewData_.view) then
            self.finalRewardsViewData_.view:runAction(cc.RemoveSelf:create())
        end
        self.finalRewardsViewData_ = nil
    end
end


function CapsuleFreeNewbieMediator:closeCountRewardsView_()
    if self.countRewardsViewData_ then
        if self.countRewardsViewData_.view and not tolua.isnull(self.countRewardsViewData_.view) then
            self.countRewardsViewData_.view:runAction(cc.RemoveSelf:create())
        end
        self.countRewardsViewData_ = nil
    end
end


-------------------------------------------------
-- handler

function CapsuleFreeNewbieMediator:onClicDrawOnceButtonkHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local consumeData     = self:getOnceConsumeData()
    local consumeGoodsId  = checkint(consumeData.goodsId)
    local consumeGoodsNum = checkint(consumeData.num)
    if app.gameMgr:GetAmountByGoodId(consumeGoodsId) >= consumeGoodsNum then
        self:SendSignal(POST.GAMBLING_FREE_NEWBIE_LUCKY.cmdName, {type = 1})
    else
        app.capsuleMgr:ShowGoodsShortageTips(consumeGoodsId)
    end
end


function CapsuleFreeNewbieMediator:onClicDrawMuchButtonkHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local consumeData     = self:getMuchConsumeData()
    local consumeGoodsId  = checkint(consumeData.goodsId)
    local consumeGoodsNum = checkint(consumeData.num)
    if app.gameMgr:GetAmountByGoodId(consumeGoodsId) >= consumeGoodsNum then
        self:SendSignal(POST.GAMBLING_FREE_NEWBIE_LUCKY.cmdName, {type = 2})
    else
        app.capsuleMgr:ShowGoodsShortageTips(consumeGoodsId)
    end
end


function CapsuleFreeNewbieMediator:onClicFinalRewardsButtonkHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    ---@type CapsuleFreeNewbieView.FinalRewardsViewData
    self.finalRewardsViewData_ = CapsuleFreeNewbieView.CreateFinalRewardsView()
    app.uiMgr:GetCurrentScene():AddDialog(self.finalRewardsViewData_.view)

    -- update views
    local useGamblingTimes = checkint(self:getHomeData().gamblingTimes)             -- 已抽次数
    local maxGamblingTimes = checkint(self:getHomeData().maxGamblingTimes)          -- 最大次数
    local isDrawnRewards   = checkint(self:getHomeData().finalRewardsHasDrawn) == 1 -- 是否领取最终奖励
    local isEnabledDrawn   = useGamblingTimes >= maxGamblingTimes and not isDrawnRewards
    local finalRewards     = checktable(self:getHomeData().finalRewards)
    self.finalRewardsViewData_.drawRewardsBtn:setEnabled(isEnabledDrawn)
    self.finalRewardsViewData_.rewardTableView:resetCellCount(#finalRewards)

    ui.bindClick(self.finalRewardsViewData_.blockLayer, function(sender)
        PlayAudioByClickClose()
        self:closeFinalRewardsView_()
    end, false)

    ui.bindClick(self.finalRewardsViewData_.drawRewardsBtn, function(sender)
        PlayAudioByClickNormal()
        if self.finalRewardsViewData_.selectedIndex > 0 then
            local rewardData = checktable(finalRewards[self.finalRewardsViewData_.selectedIndex])
            self:SendSignal(POST.GAMBLING_FREE_NEWBIE_DRAW_FINAL.cmdName, {rewardId = rewardData.rewardId})
        else
            app.uiMgr:ShowInformationTips(__('请选择奖励'))
        end
    end)

    ---@param cellViewData CapsuleFreeNewbieView.FinalRewardsCellViewData
    self.finalRewardsViewData_.rewardTableView:setCellInitHandler(function(cellViewData)
        ui.bindClick(cellViewData.clickArea, function(sender)
            PlayAudioByClickNormal()
            local cellIndex = checkint(sender:getTag())
            self.finalRewardsViewData_.selectedIndex = cellIndex

            -- update all finalRewardsSelectedIndex
            for _, cellViewData in pairs(self.finalRewardsViewData_.rewardTableView:getCellViewDataDict()) do
                local isSelected = checkint(cellViewData.clickArea:getTag()) == cellIndex
                self:getViewNode():updateFinalRewardsCellSelected(cellViewData, isSelected)
            end
        end)
    end)

    ---@param cellViewData CapsuleFreeNewbieView.FinalRewardsCellViewData
    self.finalRewardsViewData_.rewardTableView:setCellUpdateHandler(function(cellIndex, cellViewData)
        cellViewData.view:setTag(cellIndex)
        cellViewData.clickArea:setTag(cellIndex)
        
        local rewardData = checktable(finalRewards[cellIndex])
        cellViewData.cardHeadNode:RefreshUI({cardData = {cardId = rewardData.goodsId, favorabilityLevel = 0}})

        local isSelected = self.finalRewardsViewData_.selectedIndex == cellIndex
        self:getViewNode():updateFinalRewardsCellSelected(cellViewData, isSelected)
    end)
end


function CapsuleFreeNewbieMediator:onClicCountRewardsButtonkHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    ---@type CapsuleFreeNewbieView.CountRewardsViewData
    self.countRewardsViewData_ = CapsuleFreeNewbieView.CreateCountRewardsView()
    app.uiMgr:GetCurrentScene():AddDialog(self.countRewardsViewData_.view)

    -- update views
    local timesRewards  = checktable(self:getHomeData().timesRewards)
    local gamblingTimes = checkint(self:getHomeData().gamblingTimes)
    self.countRewardsViewData_.rewardTableView:resetCellCount(#timesRewards)

    ui.bindClick(self.countRewardsViewData_.blockLayer, function(sender)
        PlayAudioByClickClose()
        self:closeCountRewardsView_()
    end, false)

    ---@param cellViewData CapsuleFreeNewbieView.CountRewardsCellViewData
    self.countRewardsViewData_.rewardTableView:setCellInitHandler(function(cellViewData)
        ui.bindClick(cellViewData.drawRewardsBtn, function(sender)
            PlayAudioByClickNormal()
            local cellIndex  = checkint(sender:getTag())
            local rewardData = checktable(timesRewards[cellIndex])
            self:SendSignal(POST.GAMBLING_FREE_NEWBIE_DRAW_TASK.cmdName, {rewardId = rewardData.rewardId})
        end)
    end)

    ---@param cellViewData CapsuleFreeNewbieView.CountRewardsCellViewData
    self.countRewardsViewData_.rewardTableView:setCellUpdateHandler(function(cellIndex, cellViewData)
        cellViewData.view:setTag(cellIndex)
        cellViewData.drawRewardsBtn:setTag(cellIndex)
        
        local rewardData = checktable(timesRewards[cellIndex])
        self:getViewNode():updateCountRewardsCellDescr(cellViewData, rewardData.targetNum)
        self:getViewNode():updateCountRewardsCellGoods(cellViewData, rewardData.rewards)
        self:getViewNode():updateCountRewardsCellState(cellViewData, checkint(rewardData.hasDrawn) == 1)
        self:getViewNode():updateCountRewardsCellProgress(cellViewData, gamblingTimes, rewardData.targetNum)
    end)
end


return CapsuleFreeNewbieMediator
