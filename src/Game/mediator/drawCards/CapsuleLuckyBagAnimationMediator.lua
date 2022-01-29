--[[
福袋抽卡动画mediator    
--]]
local Mediator = mvc.Mediator
local CapsuleLuckyBagAnimationMediator = class("CapsuleLuckyBagAnimationMediator", Mediator)
local NAME = "CapsuleLuckyBagAnimationMediator"
--[[
@params map {
    rewards         list 抽卡奖励
}
--]]
function CapsuleLuckyBagAnimationMediator:ctor( params, viewComponent )
    self.super:ctor(NAME, viewComponent)
    self.data = checktable(params)
    self.activityId = checkint(self.data.activityId)
    self.maxReplaceTimes = checkint(self.data.maxReplaceTimes)
    self.leftReplaceTimes = checkint(self.data.leftReplaceTimes or self.data.maxReplaceTimes)
    self.rewards = {}
    for i, goodsData in ipairs(self.data.rewards) do
        local goodsType = CommonUtils.GetGoodTypeById(goodsData.goodsId)
        if goodsType == GoodsType.TYPE_CARD or goodsType == GoodsType.TYPE_CARD_FRAGMENT then
            table.insert(self.rewards, goodsData)
        end
    end
    self.convertRewards = self:ConvertRewardsData(self.rewards)
    self.showCardIndex = 1

end

function CapsuleLuckyBagAnimationMediator:InterestSignals()
	local signals = {
        'SHARE_BUTTON_BACK_EVENT', 
        CAPSULE_CARDVIEW_BACK,
        CAPSULE_ANIMATION_SKIP,
	}
	return signals
end

function CapsuleLuckyBagAnimationMediator:ProcessSignal( signal )
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

function CapsuleLuckyBagAnimationMediator:Initial( key )
    self.super.Initial(self, key)
    local viewComponent = require( 'Game.views.drawCards.CapsuleLuckyBagAnimationView' ).new({rewards = self.rewards})
    viewComponent:setPosition(cc.p(display.cx, display.cy))
    app.uiMgr:GetCurrentScene():AddDialog(viewComponent)
    self:SetViewComponent(viewComponent)
	-- 绑定spine事件
	viewComponent.viewData.capsuleAnimation:registerSpineEventHandler(handler(self, self.SpineEventHandler), sp.EventType.ANIMATION_EVENT)
	viewComponent.viewData.capsuleAnimation:registerSpineEventHandler(handler(self, self.SpineEndHandler), sp.EventType.ANIMATION_END)
end
--[[
转换奖励数据结构
--]]
function CapsuleLuckyBagAnimationMediator:ConvertRewardsData( rewards )
    if not rewards then return end
    local rewardsData = clone(rewards)
    for i, v in ipairs(checktable(rewardsData)) do
        -- 碎片转换
        local id = v.goodsId
        local cardConf = CommonUtils.GetConfig('cards', 'card', id)
        if app.gameMgr:GetCardDataByCardId(id) then
            --说明已经拥有该卡牌
            local qualityId            = cardConf.qualityId or 1
            local cardConversionConfig = CommonUtils.GetConfig('cards', 'cardConversion', qualityId) or { decomposition = 10 }
            v.goodsId = cardConf.fragmentId
            v.num = cardConversionConfig.decomposition
        end
    end
    return rewardsData
end
--[[
检查资源
--]]
function CapsuleLuckyBagAnimationMediator:CheckPreloadRes_()
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
function CapsuleLuckyBagAnimationMediator:ShowCardAction()
	if self.showCardIndex > #self.rewards then
        -- 抽卡结束
        self:CreateRewardPopup()
	else
		local singleCard = self.rewards[self.showCardIndex]
		local goodsId = checkint(singleCard.goodsId)
		local gtype = CommonUtils.GetGoodTypeById(goodsId)
		local scene = app.uiMgr:GetCurrentScene()
		local capsuleCardView  = require( 'Game.views.drawCards.CapsuleCardViewNew' ).new({data = clone(self.convertRewards[self.showCardIndex])})
		capsuleCardView:setPosition(display.center)
		scene:AddDialog(capsuleCardView)
	end
end
--[[
创建奖励弹窗
--]]
function CapsuleLuckyBagAnimationMediator:CreateRewardPopup()
    local mediator = require("Game.mediator.drawCards.CapsuleLuckyBagDrawMediator").new({rewards = self.rewards, replaceData = self.data.cards, activityId = self.activityId, maxReplaceTimes = self.maxReplaceTimes, leftReplaceTimes = self.leftReplaceTimes})
    AppFacade.GetInstance():RegistMediator(mediator)
end
---------------------------------------------
-------------- spine事件绑定 -----------------
--[[
spine自定义事件回调
--]]
function CapsuleLuckyBagAnimationMediator:SpineEventHandler(event)
    if not event or not event.eventData then return end
	if 'play' == event.eventData.name then
		self:ShowCardAction()
	end
end
--[[
spine动画播放结束回调
--]]
function CapsuleLuckyBagAnimationMediator:SpineEndHandler(event)
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
function CapsuleLuckyBagAnimationMediator:EnterLayer()
    self:CheckPreloadRes_()
end
function CapsuleLuckyBagAnimationMediator:OnRegist(  )
    -- 开启背景音乐
    self.bgm = PlayAudioClip(AUDIOS.UI.ui_await.id, true)
    self:EnterLayer()
end

function CapsuleLuckyBagAnimationMediator:OnUnRegist(  )
	-- 关闭背景音乐
	if self.bgm then
		self.bgm:Stop(true)
        self.bgm = nil
    end   
    app.uiMgr:GetCurrentScene():RemoveDialog(self:GetViewComponent())
end
return CapsuleLuckyBagAnimationMediator