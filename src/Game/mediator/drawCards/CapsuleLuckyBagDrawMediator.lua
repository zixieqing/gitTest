--[[
福袋抽卡领奖mediator    
--]]
local Mediator = mvc.Mediator
local CapsuleLuckyBagDrawMediator = class("CapsuleLuckyBagDrawMediator", Mediator)
local NAME = "CapsuleLuckyBagDrawMediator"
local NewPlayerRewardCell     = require("Game.views.drawCards.NewPlayerRewardCell")
function CapsuleLuckyBagDrawMediator:ctor( params, viewComponent )
    self.super:ctor(NAME, viewComponent)
    self.rewards = params.rewards or {} 
    self.replaceData = params.replaceData or {}
    self.maxReplaceTimes = checkint(params.maxReplaceTimes)
    self.leftReplaceTimes = checkint(params.leftReplaceTimes)
    self.activityId = checkint(params.activityId)
    self.isReplaceState = false -- 是否为兑换状态
    self.selectedGoodsIndex = nil -- 选中的道具序号
end

function CapsuleLuckyBagDrawMediator:InterestSignals()
	local signals = {
        POST.GAMBLING_LUCKY_BAG_LUCKY.sglName,
        POST.GAMBLING_LUCKY_BAG_REFRESH.sglName,
        POST.GAMBLING_LUCKY_BAG_CHOOSE.sglName,
        CAPSULE_LUCKY_BAG_CARD_CLICK,
        CAPSULE_LUCKY_BAG_SWITCH_END,
        CAPSULE_LUCKY_BAG_REPLACE_END,
	}
	return signals
end

function CapsuleLuckyBagDrawMediator:ProcessSignal( signal )
    local name = signal:GetName()
    local body = signal:GetBody()
    print(name)
    if name == POST.GAMBLING_LUCKY_BAG_LUCKY.sglName then
        self:DrawResult(body)
    elseif name == POST.GAMBLING_LUCKY_BAG_REFRESH.sglName then
        self:RefreshCards(body.replaceCards, body.requestData.positionId)  
    elseif name == POST.GAMBLING_LUCKY_BAG_CHOOSE.sglName then
        self:ReplaceCard(body.requestData)
    elseif name == CAPSULE_LUCKY_BAG_CARD_CLICK then
        self:GoodsNodeCallback(body.tag)
    elseif name == CAPSULE_LUCKY_BAG_SWITCH_END then
        self:SelectGoodsNode(1)
    elseif name == CAPSULE_LUCKY_BAG_REPLACE_END then
        local replaceData = self.replaceData[self.selectedGoodsIndex]
        self:GetViewComponent():UpdateSelectCardView(replaceData.replaceCards)
    end
end

function CapsuleLuckyBagDrawMediator:Initial( key )
    self.super.Initial(self, key)
    local viewComponent = require( 'Game.views.drawCards.CapsuleLuckyBagDrawView' ).new()
    viewComponent:setPosition(cc.p(display.cx, display.cy))
    app.uiMgr:GetCurrentScene():AddDialog(viewComponent)
    self:SetViewComponent(viewComponent)
    local viewData = viewComponent:GetViewData()
    viewData.maskLayer:setOnClickScriptHandler(handler(self, self.MaskLayerCallback))
    viewData.skipBtn:setOnClickScriptHandler(handler(self, self.SkipButtonCallback))
    viewData.refreshBtn:setOnClickScriptHandler(handler(self, self.RefreshButtonCallback))
    viewData.gridView:setDataSourceAdapterScriptHandler(handler(self,self.OnDataSourceAdapter))
    for i, v in ipairs(viewData.replaceBtnList) do
        v:setOnClickScriptHandler(handler(self, self.ReplaceButtonCallback))
    end
    self:UpdateRefreshTimes()
    viewComponent:StartDrawAction(self.rewards, self.maxReplaceTimes)
end

---------------------------------------------
----------------- method --------------------
function CapsuleLuckyBagDrawMediator:OnDataSourceAdapter(p_convertview, idx)
    local pCell = p_convertview
    local index = idx + 1
    local sizee = cc.size(230 , 560)
    if pCell == nil then
        pCell = NewPlayerRewardCell.new(sizee)
        pCell.viewData.entryHeadNode:setPositionY(170)
    end

    xTry(function()
        local data  = self.replaceData[self.selectedGoodsIndex]
        local cardId = data.replaceCards[index]

        local viewComponent = self:GetViewComponent()
        viewComponent:UpdateCell(pCell, cardId)
        pCell:setTag(index)
        -- 初始化动作
        pCell.viewData.eventNode:stopAllActions()
        pCell.viewData.eventNode:setOpacity(0)
        pCell.viewData.eventNode:runAction(
            cc.Sequence:create(
                cc.DelayTime:create(0.5),
                cc.DelayTime:create(0.1 * index),
                cc.FadeIn:create(0.4)
            )
        )
    end,function()
        pCell = CGridViewCell:new()
    end)

    return pCell
end
--[[
选择道具
--]]
function CapsuleLuckyBagDrawMediator:SelectGoodsNode( index )
    if index == self.selectedGoodsIndex then return end
    local viewComponent = self:GetViewComponent()
    local viewData = viewComponent:GetViewData()
    local replaceData = self.replaceData[index]
    if self.selectedGoodsIndex then
        viewComponent:UnselectGoodsNodeAction(self.selectedGoodsIndex)
    end
    self.selectedGoodsIndex = index
    viewComponent:SelectGoodsNodeAction(replaceData.replaceCards, index)
    viewComponent:UpdateSelectCardView(replaceData.replaceCards)
end
--[[
替换卡牌
--]]
function CapsuleLuckyBagDrawMediator:ReplaceCard( requestData )
    local positionId = checkint(requestData.positionId)
    local replaceCardId = checkint(requestData.replaceCardId)
    local viewComponent = self:GetViewComponent()
    local cardIndex = 1
    for i, v in ipairs(self.replaceData[positionId].replaceCards) do
        if checkint(v) == replaceCardId then
            cardIndex = i
            break
        end
    end
    self.replaceData[positionId].replaceCards = {}
    self.rewards[positionId].goodsId = replaceCardId
    viewComponent:ReplaceCardAction(replaceCardId, positionId, cardIndex)
end
--[[
刷新卡牌
--]]
function CapsuleLuckyBagDrawMediator:RefreshCards( replaceCards, positionId )
    self.replaceData[positionId].replaceCards = replaceCards
    self.leftReplaceTimes = self.leftReplaceTimes - 1
    local viewComponent = self:GetViewComponent()
    self:UpdateRefreshTimes()
    viewComponent:UpdateSelectCardView(replaceCards)
end
--[[
更新剩余刷新次数
--]]
function CapsuleLuckyBagDrawMediator:UpdateRefreshTimes()
    local viewComponent = self:GetViewComponent()
    viewComponent:UpdateRefreshTimes(self.leftReplaceTimes, self.maxReplaceTimes)
end
--[[
抽奖结果
@params map {
    rewards         list 奖励
    activityRewards list 活动奖励
    diamond         int  钻石数量
}
--]]
function CapsuleLuckyBagDrawMediator:DrawResult( params )
    local rewardsData = app.capsuleMgr:ConvertRewardsData(params)
    if params.diamond then
        app.gameMgr:GetUserInfo().diamond = params.diamond
        self:GetFacade():DispatchObservers(SIGNALNAMES.CACHE_MONEY_UPDATE_UI,{diamond = params.diamond})
    end
    app.uiMgr:AddDialog('common.RewardPopup', {rewards = checktable(rewardsData), showConfirmBtn = true, capsuleRewards = true})
    AppFacade.GetInstance():DispatchObservers(CAPSULE_LUCKY_BAG_DRAW_END)
    AppFacade.GetInstance():UnRegsitMediator("CapsuleLuckyBagDrawMediator")
end
----------------- method --------------------
---------------------------------------------

---------------------------------------------
---------------- callback -------------------
--[[
背景点击回调
--]]
function CapsuleLuckyBagDrawMediator:MaskLayerCallback( sender )   
    PlayAudioByClickNormal()
    local viewComponent = self:GetViewComponent()
    sender:setTouchEnabled(false)
    viewComponent:ShowReplaceViewAction()
    self.isReplaceState = true
end
--[[
跳过按钮点击回调
--]]
function CapsuleLuckyBagDrawMediator:SkipButtonCallback( sender )
    PlayAudioByClickNormal()
    local tag = sender:getTag()
    local data  = self.replaceData[self.selectedGoodsIndex]
    local replaceCardId = data.replaceCards[tag]
    local commonTip = require('common.CommonTip').new({
        text = __('确定要跳过?'),
        callback = function ()
            self:SendSignal(POST.GAMBLING_LUCKY_BAG_LUCKY.cmdName, {activityId = self.activityId})
        end
    })
    commonTip:setName('CommonTip')
    commonTip:setPosition(display.center)
    app.uiMgr:GetCurrentScene():AddDialog(commonTip)

end
--[[
刷新按钮点击回调
--]]
function CapsuleLuckyBagDrawMediator:RefreshButtonCallback( sender )
    PlayAudioByClickNormal()
    if self.leftReplaceTimes <= 0 then 
        app.uiMgr:ShowInformationTips(__('次数不足'))
        return 
    end
    local tag = sender:getTag()
    local data  = self.replaceData[self.selectedGoodsIndex]
    local replaceCardId = data.replaceCards[tag]
    local commonTip = require('common.CommonTip').new({
        text = __('确定要刷新?'),
        descr = __('每次10连抽卡总共只能刷新2次，请慎重刷新！！！'),
        callback = function ()
            self:SendSignal(POST.GAMBLING_LUCKY_BAG_REFRESH.cmdName, {activityId = self.activityId, positionId = self.selectedGoodsIndex})
        end
    })
    commonTip:setName('CommonTip')
    commonTip:setPosition(display.center)
    app.uiMgr:GetCurrentScene():AddDialog(commonTip)
end
--[[
道具点击回调
--]]
function CapsuleLuckyBagDrawMediator:GoodsNodeCallback( tag )
    if self.isReplaceState then
        PlayAudioByClickNormal()
        self:SelectGoodsNode(tag)
    else
        PlayAudioByClickNormal()
        local data = self.rewards[tag]
        local capsuleCardView  = require( 'Game.views.drawCards.CapsuleCardViewNew' ).new({
            data = {goodsId = checkint(data.goodsId), num = checkint(data.num)}, 
            skipAnimation = true,
        })
        capsuleCardView:setPosition(display.center)
        app.uiMgr:GetCurrentScene():AddDialog(capsuleCardView)
    end
end
--[[
替换按钮点击回调
--]]
function CapsuleLuckyBagDrawMediator:ReplaceButtonCallback( sender )
    PlayAudioByClickNormal()
    local tag = sender:getTag()
    local data  = self.replaceData[self.selectedGoodsIndex]
    local replaceCardId = data.replaceCards[tag]
    local commonTip = require('common.CommonTip').new({
        text = __('确定要替换?'),
        callback = function ()
            self:SendSignal(POST.GAMBLING_LUCKY_BAG_CHOOSE.cmdName, {activityId = self.activityId, positionId = self.selectedGoodsIndex, replaceCardId = replaceCardId})
        end
    })
    commonTip:setName('CommonTip')
    commonTip:setPosition(display.center)
    app.uiMgr:GetCurrentScene():AddDialog(commonTip)
end
---------------- callback -------------------
---------------------------------------------

---------------------------------------------
---------------- get / set ------------------

---------------- get / set ------------------
---------------------------------------------
function CapsuleLuckyBagDrawMediator:OnRegist(  )
    regPost(POST.GAMBLING_LUCKY_BAG_LUCKY)
    regPost(POST.GAMBLING_LUCKY_BAG_REFRESH)
    regPost(POST.GAMBLING_LUCKY_BAG_CHOOSE)
end

function CapsuleLuckyBagDrawMediator:OnUnRegist(  )
    unregPost(POST.GAMBLING_LUCKY_BAG_LUCKY)
    unregPost(POST.GAMBLING_LUCKY_BAG_REFRESH)
    unregPost(POST.GAMBLING_LUCKY_BAG_CHOOSE)
    AppFacade.GetInstance():UnRegsitMediator("CapsuleLuckyBagAnimationMediator")
    app.uiMgr:GetCurrentScene():RemoveDialog(self:GetViewComponent())
end
return CapsuleLuckyBagDrawMediator