--[[
抽卡动画mediator    
--]]
local Mediator = mvc.Mediator
local CapsuleAnimateMediator = class("CapsuleAnimateMediator", Mediator)
local NAME = "CapsuleAnimateMediator"
--[[
@params map {
    rewards         list 抽卡奖励
    extraRewards    list 额外奖励
    activityRewards list 活动奖励
    stepRewards     list 阶段奖励
}
--]]
function CapsuleAnimateMediator:ctor( params, viewComponent )
    self.super:ctor(NAME, viewComponent)
    self.data = checktable(params)
    self.rewards = {}
    for i, goodsData in ipairs(self.data.rewards) do
        local goodsType = CommonUtils.GetGoodTypeById(goodsData.goodsId)
        if goodsType == GoodsType.TYPE_CARD or goodsType == GoodsType.TYPE_CARD_FRAGMENT then
            table.insert(self.rewards, goodsData)
        end
    end
    self.data.rewards = self.rewards
    self.showCardIndex = 1

end

function CapsuleAnimateMediator:InterestSignals()
	local signals = {
        'SHARE_BUTTON_BACK_EVENT', 
        CAPSULE_CARDVIEW_BACK,
        CAPSULE_ANIMATION_SKIP,
	}
	return signals
end

function CapsuleAnimateMediator:ProcessSignal( signal )
	local name = signal:GetName()
    print(name)
    if name == CAPSULE_CARDVIEW_BACK then
        self.showCardIndex = self.showCardIndex + 1
        self:ShowCardAction()
    elseif name == CAPSULE_ANIMATION_SKIP then
        -- 抽卡动画跳过
        self.showCardIndex = #self.rewards
        self:CreateRewardPopup()
    elseif name == 'SHARE_BUTTON_BACK_EVENT' then
    	-- 关闭分享界面
        app.uiMgr:GetCurrentScene():RemoveDialogByTag(5361)
    end
end

function CapsuleAnimateMediator:Initial( key )
    self.super.Initial(self, key)
    local viewComponent = require( 'Game.views.drawCards.CapsuleAnimateView' ).new()
    viewComponent:setPosition(cc.p(display.cx, display.cy))
    app.uiMgr:GetCurrentScene():AddDialog(viewComponent)
    self:SetViewComponent(viewComponent)
	-- 绑定spine事件
	viewComponent.viewData.capsuleAnimation:registerSpineEventHandler(handler(self, self.SpineEventHandler), sp.EventType.ANIMATION_EVENT)
	viewComponent.viewData.capsuleAnimation:registerSpineEventHandler(handler(self, self.SpineEndHandler), sp.EventType.ANIMATION_END)
end
--[[
检查资源
--]]
function CapsuleAnimateMediator:CheckPreloadRes_()
	local resDatas = {}
	for i, rewardData in ipairs(self.rewards or {}) do
		local cardId    = 0
		local goodsId   = checkint(rewardData.goodsId)
		local goodsType = CommonUtils.GetGoodTypeById(goodsId)
		if goodsType == GoodsType.TYPE_CARD_FRAGMENT then
            cardId = app.capsuleMgr:GetCardIdByFragmentId(goodsId)
		else
			cardId = goodsId
		end
		local drawName = CardUtils.GetCardDrawNameByCardId(cardId)
		local drawPath = AssetsUtils.GetCardDrawPath(drawName)
		table.insert(resDatas, drawPath)
	end

    local finishCB = function()
        -- 开始播放动画
        local isRare = false
        for i, v in ipairs(self.rewards) do
            if CommonUtils.GetGoodsQuality(v.goodsId) == 5 then
                isRare = true
                break
            end
        end
        self:GetViewComponent():StartCapsuleAnimation(isRare)
	end

	if DYNAMIC_LOAD_MODE then
		app.uiMgr:showDownloadResPopup({ 
			isFuzzy  = true,
			resDatas = resDatas,
			finishCB = finishCB,
		})
	else
		finishCB()
	end
end
--[[
展示卡牌
--]]
function CapsuleAnimateMediator:ShowCardAction()
	if self.showCardIndex > #self.rewards then
        -- 抽卡结束
        self:CreateRewardPopup()
	else
		local singleCard = self.rewards[self.showCardIndex]
		local goodsId = checkint(singleCard.goodsId)
		local gtype = CommonUtils.GetGoodTypeById(goodsId)
		local scene = app.uiMgr:GetCurrentScene()
		local capsuleCardView  = require( 'Game.views.drawCards.CapsuleCardViewNew' ).new({data = clone(self.rewards[self.showCardIndex])})
		capsuleCardView:setPosition(display.center)
		scene:AddDialog(capsuleCardView)
	end
end
--[[
创建奖励弹窗
--]]
function CapsuleAnimateMediator:CreateRewardPopup()
    local rewardsData = app.capsuleMgr:ConvertRewardsData(self.data)
    app.uiMgr:AddDialog('common.RewardPopup', {rewards = rewardsData, showConfirmBtn = true, capsuleRewards = true, closeCallback = function ()
        -- 处理阶段奖励
        if self.data.stepRewards and next(self.data.stepRewards) ~= nil then
            app.uiMgr:AddDialog('common.RewardPopup', {rewards = self.data.stepRewards})
        end
        AppFacade.GetInstance():UnRegsitMediator("CapsuleAnimateMediator") 
    end})
end
---------------------------------------------
-------------- spine事件绑定 -----------------
--[[
spine自定义事件回调
--]]
function CapsuleAnimateMediator:SpineEventHandler(event)
    if not event or not event.eventData then return end
	if 'play' == event.eventData.name then
		self:ShowCardAction()
	end
end
--[[
spine动画播放结束回调
--]]
function CapsuleAnimateMediator:SpineEndHandler(event)
	if event.animation == 'play' or event.animation == 'play2' then
    	self.viewComponent:performWithDelay(
            function ()
                -- 将spine恢复至初始状态
                self:GetViewComponent():RecoverCapsuleIdleState()
            end,
            (1 * cc.Director:getInstance():getAnimationInterval())
        )
	end
end
-------------- spine事件绑定 -----------------
---------------------------------------------
function CapsuleAnimateMediator:EnterLayer()
    self:CheckPreloadRes_()
end
function CapsuleAnimateMediator:OnRegist(  )
    -- 开启背景音乐
    self.bgm = PlayAudioClip(AUDIOS.UI.ui_await.id, true)
    self:EnterLayer()
end

function CapsuleAnimateMediator:OnUnRegist(  )
	-- 关闭背景音乐
	if self.bgm then
		self.bgm:Stop(true)
        self.bgm = nil
    end   
    AppFacade.GetInstance():DispatchObservers('EVENT_SUMMON_ANIMATION_MEDIATOR_CLOSE')
    app.uiMgr:GetCurrentScene():RemoveDialog(self:GetViewComponent())
end
return CapsuleAnimateMediator