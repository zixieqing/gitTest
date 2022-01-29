--[[
周年庆套圈mediator
--]]
local Mediator = mvc.Mediator
---@class AnniversaryCapsuleMediator :Mediator  
local AnniversaryCapsuleMediator = class("AnniversaryCapsuleMediator", Mediator)
local NAME = "anniversary.AnniversaryCapsuleMediator"

local uiMgr              = app.uiMgr
local gameMgr            = app.gameMgr
local timerMgr           = app.timerMgr
local anniversaryManager = app.anniversaryMgr
local BUTTON_TAG = {
    BACK             = 100,
    RULE             = 101,
    NINE_DRAW        = 102,
    ONT_DRAW         = 103,
    EXTRA_REWARD_TIP = 104,
    REWARD_PREVIEW   = 105,
}

local UI_STATE = {
    BELOW_SHOW = 1,
    BELOW_HIDE = 2,
}

local DRAW_TYPE = {
    ONE  = 1,
    NINE = 2
}

local ONE_DRAW_STAGE_TYPE = {
    STOP    = 0,
    RUN_1   = 1,   -- 
    WAIT    = 2,
    RUN_2   = 3,
    END     = 4,
}

local _max = math.max
local _r   = math.random

function AnniversaryCapsuleMediator:ctor(param ,  viewComponent )
    self.super:ctor(NAME,viewComponent)

    self.gambling = {}
    self.trickLock = false
    self.ninePlayAniTimes = 0
    self.isControllable_ = true
    -- local leftTime = 10000
    -- timerMgr:AddTimer({name = NAME, countdown = 86400})
end

function AnniversaryCapsuleMediator:InterestSignals()
    local signals = {
        COUNT_DOWN_ACTION,
        SGL.CACHE_MONEY_UPDATE_UI,

        POST.ANNIVERSARY_MYSTERIOUS_CIRCLE.sglName,
        POST.ANNIVERSARY_MYSTERIOUS_SUPER_REWARDS.sglName,
    }
    return signals
end

function AnniversaryCapsuleMediator:ProcessSignal( signal )
    local name = signal:GetName()
    local body = signal:GetBody() or {}

    if name == SGL.CACHE_MONEY_UPDATE_UI then
        self:GetViewComponent():UpdateCountUI()
    elseif name == COUNT_DOWN_ACTION then
        local timerName = body.timerName
		if timerName == 'COUNT_DOWN_TAG_ANNIVERSARY' then
            local countdown = body.countdown
            if self.trickStartTime == countdown then
                self:showRingTrickAniByIndex(_r(1, 9))
            end
			if self.trickStartTime == nil or self.trickStartTime == countdown then
                self.trickStartTime = _max(countdown - _r(3, 6), 0)
            end
		end
    elseif name == POST.ANNIVERSARY_MYSTERIOUS_CIRCLE.sglName then
        local rewardLists = body.rewards or {}
        local requestData = body.requestData or {}
        local times = checkint(requestData.times)
        local index = requestData.index
        -- CommonUtils.DrawRewards(rewards)
        -- 代币的消耗
        CommonUtils.DrawRewards({{goodsId = app.anniversaryMgr:GetRingGameID(), num = -1 * self.lotteryConsumeNum * times}})
        
        self.capsuleRewards = {}
        for i, rewardList in pairs(rewardLists) do
            for i, reward in ipairs(rewardList) do
                table.insert(self.capsuleRewards, reward)
            end
        end
        self.gambling = body.gambling or {}

        local homeData              = anniversaryManager:GetHomeData()
        homeData.mysteriousCircleNum = checkint(homeData.mysteriousCircleNum) + times

        self.trickLock = true
        if times == 9 then
            self.curDrawIndex = 0
            self.ninePlayAniTimes = 0
            self:GetViewComponent():drawNineAni()
        elseif times == 1 then
            self.curDrawIndex = index
            self.curOneDrawAniState = ONE_DRAW_STAGE_TYPE.RUN_2
            self:GetViewComponent():drawOneAni(self.curOneDrawAniState)
        end
        self.isControllable_ = true
        self:GetViewComponent():updateExtraRewardTipState(self.superRewardTimes)

        app.badgeMgr:CheckAnniversaryExtraRewardTipRed()
    elseif name == POST.ANNIVERSARY_MYSTERIOUS_SUPER_REWARDS.sglName then
        local rewards = body.rewards or {}
        if next(rewards) ~= nil then
            uiMgr:AddDialog('common.RewardPopup', {rewards = rewards})
        end
        anniversaryManager:SetHomeDataByKeyalue('supperRewardsHasDrawn', 1)

        app.badgeMgr:CheckAnniversaryExtraRewardTipRed()
        self:GetViewComponent():updateExtraRewardTipState(self.superRewardTimes)
    end
end

function AnniversaryCapsuleMediator:Initial( key )
    self.super.Initial(self, key)
    
    self.datas = {}
    self.isControllable_ = true
    self.curOneDrawAniState = ONE_DRAW_STAGE_TYPE.STOP

    ---@type AnniversaryCapsuleView
    local viewComponent  = require('Game.views.anniversary.AnniversaryCapsuleView').new()
    self.viewData_      = viewComponent:getViewData()
    self:SetViewComponent(viewComponent)
    display.commonUIParams(viewComponent, {ap = display.CENTER, po = display.center})

    self.ownerScene_ = uiMgr:GetCurrentScene()
    self:getOwnerScene():AddDialog(viewComponent)

    self:initData_()
    self:initView_()

    app.badgeMgr:CheckAnniversaryExtraRewardTipRed()
end

-------------------------------------------------
-- private method

function AnniversaryCapsuleMediator:initData_()
    local homeData = anniversaryManager:GetHomeData() or {}
    local luckyRewards = homeData.luckyRewards or {}    

    local rewardPreviewDatas = {}
    local rateList = {}
    local totalRate = 0
    for _, d in pairs(luckyRewards) do
        local rewards = d.rewards or {}
        local rareGoods = checkint(d.rareGoods)
        if rewardPreviewDatas[rareGoods] == nil then
            rewardPreviewDatas[rareGoods] = {title = self:initRewardPoolTitleByRareGood(rareGoods), list = {}}
        end
        local baseData = {
            goodsSort = d.goodsSort,
            id = d.id,
        }
        local baseRateData = {
            goodsSort = d.goodsSort,
            descr     = '',
            rate  = checkint(d.rate) --d.rate
        }
        totalRate = totalRate + checkint(d.rate)
        for i, v in ipairs(rewards) do
            baseData.reward = v
            baseRateData.descr = string.format( "%sx%s", tostring(checktable(CommonUtils.GetConfig('goods', 'goods', v.goodsId)).name), tostring(v.num))
            table.insert(rateList, baseRateData)
            table.insert(rewardPreviewDatas[rareGoods].list, baseData)
        end
    end

    local listSortFunc = function (a, b)
        return checkint(a.goodsSort) > checkint(b.goodsSort)
    end

    for i, v in pairs(rewardPreviewDatas) do
        table.sort(v.list or {}, listSortFunc)
    end

    for i, v in ipairs(rateList) do
        v.rateText = math.ceil(checkint(v.rate)/totalRate * 10000) / 100  .. "%"
    end
    table.sort(rateList, listSortFunc)
    
    self.rewardPreviewDatas = rewardPreviewDatas
    self.rateList = rateList

    local parserConfig = anniversaryManager:GetConfigParse()
    local paramConfig = checktable(anniversaryManager:GetConfigDataByName(parserConfig.TYPE.PARAMETER))["1"] or {}
    self.lotteryConsumeNum = checkint(paramConfig.lotteryCost)       -- 抽一次消耗的数量
    self.superRewardTimes = checkint(paramConfig.superRewardTimes)

    local superRewards = paramConfig.superRewards or {}
    self.superRewardsGoodsId = checktable(superRewards[1]).goodsId
end

function AnniversaryCapsuleMediator:initRewardPoolTitleByRareGood(rareGoods)
    return rareGoods == 1 and app.anniversaryMgr:GetPoText(__('稀有')) or app.anniversaryMgr:GetPoText(__('普通'))
end

function AnniversaryCapsuleMediator:initView_()
    local viewData     = self:getViewData()
    local actionBtns   = viewData.actionBtns

    for tag, btn in pairs(actionBtns) do
        display.commonUIParams(btn, {cb = handler(self, self.onButtonAction)})
        if checkint(tag) == BUTTON_TAG.NINE_DRAW then
            self:GetViewComponent():updateConsumeNumLabel(btn, self.lotteryConsumeNum * 9)
        elseif checkint(tag) == BUTTON_TAG.ONT_DRAW then
            self:GetViewComponent():updateConsumeNumLabel(btn, self.lotteryConsumeNum)
        end
        btn:setTag(checkint(tag))
    end

    local potCells     = viewData.potCells
    for i, potCell in ipairs(potCells) do
        display.commonUIParams(potCell, {cb = handler(self, self.onClickPotCellAction)})
        if potCell:getChildByName('potSpine') then
            potCell:getChildByName('potSpine'):registerSpineEventHandler(handler(self, self.potSpineAniCompleteAction), sp.EventType.ANIMATION_COMPLETE)
            -- potCell:getChildByName('potSpine'):registerSpineEventHandler(handler(self, 
        end
        potCell:setTag(i)
    end

    local qAvatar = viewData.qAvatar
    qAvatar:registerSpineEventHandler(handler(self, self.qAvatarAniEndAction), sp.EventType.ANIMATION_EVENT)

    local ringSpine = viewData.ringSpine
    ringSpine:registerSpineEventHandler(handler(self, self.ringSpineAniEndAction), sp.EventType.ANIMATION_END)

    local cutinSpine = viewData.cutinSpine
    cutinSpine:registerSpineEventHandler(handler(self, self.cutinSpineAniEndAction), sp.EventType.ANIMATION_END)

    local viewComponent = self:GetViewComponent()
    viewComponent:UpdateCountUI()
    viewComponent:updateExtraRewardTipState(self.superRewardTimes)


    self:showRingTrickAniByIndex(_r(1, 9))
end

--==============================--
--desc: 罐子按钮点击事件
--params sender userdata 按钮
--@return
--==============================--
function AnniversaryCapsuleMediator:onClickPotCellAction(sender)
    local index = sender:getTag()
    if  self.curOneDrawAniState == ONE_DRAW_STAGE_TYPE.RUN_1 
        or self.curOneDrawAniState == ONE_DRAW_STAGE_TYPE.WAIT then
        
        local potSpine = sender:getChildByName('potSpine')
        if potSpine then
            potSpine:setAnimation(0, 'anni_draw_can_touch', false)
        end
        -- todo 发送抽请求
        self:SendSignal(POST.ANNIVERSARY_MYSTERIOUS_CIRCLE.cmdName, {times = 1, index = index})
    elseif self.curOneDrawAniState == ONE_DRAW_STAGE_TYPE.STOP then
        
        local potSpine = sender:getChildByName('potSpine')
        if potSpine then
            potSpine:setAnimation(0, 'anni_draw_can_touch', false)
        end
    end

end

--==============================--
--desc: 按钮点击事件
--params sender userdata 按钮
--@return
--==============================--
function AnniversaryCapsuleMediator:onButtonAction(sender)
    local tag = sender:getTag()
    
    if tag == BUTTON_TAG.BACK then
        PlayAudioByClickClose()
        
        self:handlerBack()
    else
        PlayAudioByClickNormal()
        if tag == BUTTON_TAG.RULE then
            uiMgr:ShowIntroPopup({moduleId = '-12'})
        elseif tag == BUTTON_TAG.NINE_DRAW then
            self:handlerNineDraw(sender)
        elseif tag == BUTTON_TAG.ONT_DRAW then
            self:handlerOneDraw(sender)
        elseif tag == BUTTON_TAG.EXTRA_REWARD_TIP then
            self:handlerExterRewardTip(sender)
        elseif tag == BUTTON_TAG.REWARD_PREVIEW then
            self:showRewardPreview()
        end
    end
end

--==============================--
--desc: 处理返回键
--@return
--==============================--
function AnniversaryCapsuleMediator:handlerBack()
    if self.curOneDrawAniState ~= ONE_DRAW_STAGE_TYPE.STOP then
        self:resetInitState()
        return
    end
    app:UnRegsitMediator(NAME)
end

--==============================--
--desc: 处理单抽
--@return
--==============================--
function AnniversaryCapsuleMediator:handlerOneDraw()
    if not self.isControllable_ then return end
    local ownNum = CommonUtils.GetCacheProductNum(app.anniversaryMgr:GetRingGameID())
    if ownNum >= self.lotteryConsumeNum then -- 判断货币是否充足
        self.curOneDrawAniState = ONE_DRAW_STAGE_TYPE.RUN_1
        self:GetViewComponent():drawOneAni(self.curOneDrawAniState, function ()
            self.curOneDrawAniState = ONE_DRAW_STAGE_TYPE.WAIT
        end)
    else
        self:showGoodTips(app.anniversaryMgr:GetRingGameID())
    end
end

--==============================--
--desc: 处理九连抽
--@return
--==============================--
function AnniversaryCapsuleMediator:handlerNineDraw()
    if not self.isControllable_ then return end
    local ownNum = CommonUtils.GetCacheProductNum(app.anniversaryMgr:GetRingGameID())
    if ownNum >= 9 * self.lotteryConsumeNum then -- 判断货币是否充足
        self.isControllable_ = false
        self:SendSignal(POST.ANNIVERSARY_MYSTERIOUS_CIRCLE.cmdName, {times = 9})
    else
        self:showGoodTips(app.anniversaryMgr:GetRingGameID())
    end
end

--==============================--
--desc: 处理累计套圈奖励提示
--params sender userdata 套圈奖励提示按钮
--@return
--==============================--
function AnniversaryCapsuleMediator:handlerExterRewardTip(sender)
    local homeData = anniversaryManager:GetHomeData() or {}
    local mysteriousCircleNum = checkint(homeData.mysteriousCircleNum)
    local hasDrawn = checkint(homeData.supperRewardsHasDrawn) > 0
    if not hasDrawn then
        if mysteriousCircleNum >= self.superRewardTimes then
            self:SendSignal(POST.ANNIVERSARY_MYSTERIOUS_SUPER_REWARDS.cmdName)
        else
            uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = self.superRewardsGoodsId, type = 1})
        end
    else
        uiMgr:ShowInformationTips(app.anniversaryMgr:GetPoText(__('奖励已领取')))
    end
end

--==============================--
--desc: 显示奖励预览界面
--@return
--==============================--
function AnniversaryCapsuleMediator:showRewardPreview()
    local capsulePrizeView = require( 'Game.views.anniversary.AnniversaryCapsulePoolView' ).new({confId = self.superRewardsGoodsId, rewardPreviewDatas = self.rewardPreviewDatas, rate = self.rateList})
    display.commonUIParams(capsulePrizeView, {ap = display.CENTER, po = display.center})
    local scene = uiMgr:GetCurrentScene()
    scene:AddDialog(capsulePrizeView)
end

--==============================--
--desc: 显示道具提示
--params goodsId 道具id
--@return
--==============================--
function AnniversaryCapsuleMediator:showGoodTips(goodsId)
    if GAME_MODULE_OPEN.NEW_STORE and checkint(goodsId) == DIAMOND_ID then
        app.uiMgr:showDiamonTips()
    else
        local goodsConf = CommonUtils.GetConfig('goods','goods', goodsId) or {}
        uiMgr:ShowInformationTips(string.fmt(app.anniversaryMgr:GetPoText(__('_name_不足')), {['_name_'] = tostring(goodsConf.name)}))
    end
end

--==============================--
--desc: 根据下标 显示 ring spine trick 动画
--params index 下标
--@return
--==============================--
function AnniversaryCapsuleMediator:showRingTrickAniByIndex(index)
    if self.trickLock then return end
    self:GetViewComponent():showRingTrickAniByIndex(index)
end

--==============================--
--desc: qAvatar spine 动画结束回调
--params event 事件
--@return
--==============================--
function AnniversaryCapsuleMediator:qAvatarAniEndAction(event)
    local animation = event.animation
    
    if animation == 'attack' then
        local viewData = self:getViewData()
        
        -- 如果当前单抽状态 是 静止状态 则显示是9连抽
        if self.curOneDrawAniState == ONE_DRAW_STAGE_TYPE.STOP then
            -- qAvatar:update(0)
            -- qAvatar:setToSetupPose()
            -- qAvatar:addAnimation(0, 'attack', false)
            -- 
            
            local ringSpine = viewData.ringSpine
            ringSpine:setVisible(true)
            ringSpine:setAnimation(0, 'anni_draw_circle_playll', false)
        else
            self:GetViewComponent():setSpineAni(viewData.qAvatar, 'idle', true)
            local ringSpine = viewData.ringSpine
            ringSpine:setVisible(true)
            ringSpine:setAnimation(0, 'anni_draw_circle_play' .. self.curDrawIndex, false)
        end
        
    end
end

--==============================--
--desc: ring spine 动画结束回调
--params event 事件
--@return
--==============================--
function AnniversaryCapsuleMediator:ringSpineAniEndAction(event)
    local animation = event.animation

    if self.curOneDrawAniState == ONE_DRAW_STAGE_TYPE.STOP then
        self:GetViewComponent():setSpineAni(self:getViewData().qAvatar, 'idle', true)
        for i = 1, 9 do
            self:GetViewComponent():showRingAniByIndex(i)    
        end
    else
        self:GetViewComponent():showRingAniByIndex(self.curDrawIndex)
    end
end

--==============================--
--desc: pot spine 动画完成回调
--params event 事件
--@return
--==============================--
function AnniversaryCapsuleMediator:potSpineAniCompleteAction(event)
    
    local animation = event.animation
    -- logInfo.add(5, "potSpineAniCompleteAction = " .. animation)
    if animation == 'anni_draw_can_play' then
        if self.curOneDrawAniState ~= ONE_DRAW_STAGE_TYPE.STOP then
            self:GetViewComponent():showOpenPotAniByIndex(self.curDrawIndex, self.gambling['1'])
        else
            self.curDrawIndex = self.curDrawIndex + 1
            self:GetViewComponent():showOpenPotAniByIndex(self.curDrawIndex, self.gambling[tostring(self.curDrawIndex)])
        end
    elseif animation == 'anni_draw_can_open2' or animation == 'anni_draw_can_open1' then
        if self.curOneDrawAniState == ONE_DRAW_STAGE_TYPE.STOP then
            self.ninePlayAniTimes = self.ninePlayAniTimes + 1
        end

        if self.curOneDrawAniState ~= ONE_DRAW_STAGE_TYPE.STOP or self.ninePlayAniTimes == 9 then
            self:showCapsuleRewards()
        end
    end
    
end

--==============================--
--desc: cutin spine 动画结束回调
--params event 事件
--@return
--==============================--
function AnniversaryCapsuleMediator:cutinSpineAniEndAction(event)
    -- local animation = event.animation
    -- local viewData = self:getViewData()
    -- local cutinSpine = viewData.cutinSpine
    -- cutinSpine:setVisible(false)
    local viewData = self:getViewData()
    local qAvatar  = viewData.qAvatar
    self:GetViewComponent():setSpineAni(qAvatar, 'attack', false)
    -- local ringSpine = viewData.ringSpine
    -- ringSpine:setVisible(true)
    -- ringSpine:setAnimation(0, 'anni_draw_circle_playll', false)
end

--==============================--
--desc: 显示抽卡奖励
--@return
--==============================--
function AnniversaryCapsuleMediator:showCapsuleRewards()
    if self.capsuleRewards and next(self.capsuleRewards) ~= nil then
        local isRate = false
        for i, v in pairs(self.gambling) do
            if checkint(v) > 0 then
                isRate = true
                break
            end
        end
        if isRate then
            self:GetViewComponent():CreateCotAnimation()
        end
        uiMgr:AddDialog('common.RewardPopup', {rewards = self.capsuleRewards, closeCallback = handler(self, self.resetInitState)})
        local scene      = uiMgr:GetCurrentScene()
        scene:RemoveViewForNoTouch()
        self.capsuleRewards = nil
    end
end

--==============================--
--desc: 重置为初始状态
--@return
--==============================--
function AnniversaryCapsuleMediator:resetInitState()
    if self.curOneDrawAniState ~= ONE_DRAW_STAGE_TYPE.STOP then
        self.curOneDrawAniState = ONE_DRAW_STAGE_TYPE.STOP
    end
    self.trickLock = false
    self:GetViewComponent():resetUIInitStae()
    app:DispatchObservers(SGL.CACHE_MONEY_UPDATE_UI)
end

-------------------------------------------------
-- get / set

function AnniversaryCapsuleMediator:getViewData()
    return self.viewData_
end

function AnniversaryCapsuleMediator:getOwnerScene()
    return self.ownerScene_
end

function AnniversaryCapsuleMediator:cleanupView()
    local viewComponent = self:GetViewComponent()
    if self.ownerScene_ and viewComponent and not tolua.isnull(viewComponent) then
        viewComponent:stopAllActions()
        self.ownerScene_:RemoveDialog(viewComponent)
        self.ownerScene_ = nil
    end
end

function AnniversaryCapsuleMediator:OnRegist()
    anniversaryManager:PlayAnniversaryCapsuleBGM()
    regPost(POST.ANNIVERSARY_MYSTERIOUS_SUPER_REWARDS)    
    regPost(POST.ANNIVERSARY_MYSTERIOUS_CIRCLE)

end

function AnniversaryCapsuleMediator:OnUnRegist()
    unregPost(POST.ANNIVERSARY_MYSTERIOUS_SUPER_REWARDS)    
    unregPost(POST.ANNIVERSARY_MYSTERIOUS_CIRCLE)
    anniversaryManager:PlayAnniversaryMainBGM()
    -- 先解除注册 再 移除视图
    self:cleanupView()
end

return AnniversaryCapsuleMediator
