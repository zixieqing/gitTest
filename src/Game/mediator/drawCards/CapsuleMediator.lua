--[[
扭蛋系统mediator
--]]
local Mediator = mvc.Mediator
local CapsuleMediator = class("CapsuleMediator", Mediator)
local NAME = "CapsuleMediator"
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")

function CapsuleMediator:ctor( viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.extractData = {}
	self.rewards = {} -- 卡牌奖励
	self.limitCount = -1
	self.cardId = nil -- 当前抽取的卡牌id
	self.cardPoolDatas = {} -- 卡池信息
	self.cardPoolIndex = nil -- 卡池序号
	self.showCardIndex = 0 -- 当前显示卡牌序号
end

function CapsuleMediator:InterestSignals()
	local signals = {
		POST.GAMBLING_LUCKY.sglName,
		POST.ACTIVITY_GAMBLING_LUCKY.sglName,
		SIGNALNAMES.CACHE_MONEY_UPDATE_UI,
		CAPSULE_CHOOSE_CARDPOOL,
		CAPSULE_SHOW_CAPSULE_UI,
		"Capsule_Multipe_Draw",
		'SHARE_BUTTON_BACK_EVENT'
	}
	return signals
end

function CapsuleMediator:ProcessSignal( signal )
	local name = signal:GetName()
	-- 常规抽卡 / 活动抽卡
	if name == POST.GAMBLING_LUCKY.sglName or name == POST.ACTIVITY_GAMBLING_LUCKY.sglName then
		local body = checktable(signal:GetBody())
		if name == POST.GAMBLING_LUCKY.sglName then
			AppFacade.GetInstance():DispatchObservers("DOT_LOG_EVENT_SEND" , {eventId = "1003-01"})
		end
		-- 处理活动道具
		if body.activityRewards and next(body.activityRewards) ~= nil then
			CommonUtils.DrawRewards(body.activityRewards)
		end
		if not body.errcode then
			self.showCardIndex = 1
			-- 屏蔽返回按钮
			local scene = uiMgr:GetCurrentScene()
			scene:AddViewForNoTouch()
			self.viewComponent.viewData_.extractBtn:setEnabled(false)
			self.viewComponent.viewData_.multipleBtn:setEnabled(false)
			self.rewards = {}
			self.extractData = body
			self.rewards = checktable(body.rewards)
			CommonUtils.DrawRewards(self.rewards)
            GuideUtils.DispatchStepEvent()
			------------------------------------------
			local singleCard = self.rewards[self.showCardIndex]
			local goodsId = checkint(singleCard.goodsId)
		 	local gtype = CommonUtils.GetGoodTypeById(goodsId)
		 	-- 预加载资源
			if tostring(gtype) == GoodsType.TYPE_CARD_FRAGMENT then
				local fragmentData = CommonUtils.GetConfig('goods', 'goods', goodsId)
				display.loadImage(AssetsUtils.GetCardDrawPath(fragmentData.cardId))
				self.cardId = fragmentData.cardId
			elseif tostring(gtype) == GoodsType.TYPE_CARD then
				display.loadImage(AssetsUtils.GetCardDrawPath(goodsId))
				self.cardId = goodsId
			end
			display.loadImage(_res('ui/home/capsule/draw_card_bg.png'))
			display.loadImage(_res('effects/capsule/popup.png'))
			display.loadImage(_res('ui/home/capsule/draw_card_bg_name.png'))
			display.loadImage(_res('ui/home/capsule/draw_card_ico_new.png'))
			display.loadImage(_res('ui/home/capsule/draw_card_bg_text_tips.png'))
			display.loadImage(_res('ui/home/capsule/draw_card_bg_text.png'))
			display.loadImage(_res('ui/home/capsule/card_btn_share.png'))
			display.loadImage(_res('ui/home/capsule/draw_card_btn_ok.png'))
			-- 隐藏火焰图标
    		self.viewComponent.viewData_.fireAnimation:setVisible(false)
    		self:HideActivityImg(true)
			self.viewComponent.canRotate = false
			self.viewComponent.canClick = false
			if self.viewComponent.viewData_.view:getChildByTag(505) then
				self.viewComponent.viewData_.view:getChildByTag(505):removeFromParent()
				self.viewComponent.viewData_.extractBtn:setVisible(true)
				self.viewComponent.viewData_.extractBtnAct:setVisible(true)
				self.viewComponent.viewData_.extractRichLabel:setVisible(true)
				self.viewComponent.viewData_.diamondIcon:setVisible(true)
				self.viewComponent.viewData_.priceLabel:setVisible(true)
			end
			-- 判断抽卡类型
			local consumeDatas = self:GetCapsuleConsume()
			if body.requestData.type == 1 then
				if consumeDatas.one.gold then
					gameMgr:GetUserInfo().diamond = signal:GetBody().diamond
					if body.gold and body.diamond then
						self:GetFacade():DispatchObservers(SIGNALNAMES.CACHE_MONEY_UPDATE_UI,{gold = signal:GetBody().gold,diamond = signal:GetBody().diamond})
						table.remove(self.rewards)
					end
				else
					CommonUtils.DrawRewards( {rewards = {goodsId = consumeDatas.one.goodsId, num = -consumeDatas.one.num}})
					self:GetFacade():DispatchObservers(SIGNALNAMES.CACHE_MONEY_UPDATE_UI)
				end
			elseif body.requestData.type == 2 then
				if consumeDatas.six.gold then
					gameMgr:GetUserInfo().diamond = signal:GetBody().diamond
					if body.gold and body.diamond then
						self:GetFacade():DispatchObservers(SIGNALNAMES.CACHE_MONEY_UPDATE_UI,{gold = signal:GetBody().gold,diamond = signal:GetBody().diamond})
						table.remove(self.rewards)
					end
				else
					CommonUtils.DrawRewards( {rewards = {goodsId = consumeDatas.six.goodsId, num = -consumeDatas.six.num}})
					self:GetFacade():DispatchObservers(SIGNALNAMES.CACHE_MONEY_UPDATE_UI)
				end
			end
			self:checkPreloadRes_()
		end
	elseif name == CAPSULE_CHOOSE_CARDPOOL then -- 选择卡池
		local datas = checktable(signal:GetBody())
		self:ChooseCardPool(datas.index)
	elseif name == SIGNALNAMES.CACHE_MONEY_UPDATE_UI then -- 刷新顶部状态栏
		self:UpdateCountUI()
	elseif name == CAPSULE_SHOW_CAPSULE_UI then 
		self:ShowCapsuleUI()
	elseif name == "Capsule_Multipe_Draw" then
		self:ShowCardAction()
	elseif name == 'SHARE_BUTTON_BACK_EVENT' then
		-- 关闭分享界面
		uiMgr:GetCurrentScene():RemoveDialogByTag(5361)
	end
end

function CapsuleMediator:checkPreloadRes_()
	local resDatas = {}
	for i, rewardData in ipairs(self.rewards or {}) do
		local cardId    = 0
		local goodsId   = checkint(rewardData.goodsId)
		local goodsType = CommonUtils.GetGoodTypeById(goodsId)
		if goodsType == GoodsType.TYPE_CARD_FRAGMENT then
			local fragmentData = CommonUtils.GetConfig('goods', 'goods', goodsId) or {}
			cardId = checkint(fragmentData.cardId)
		else
			cardId = goodsId
		end
		local drawName = CardUtils.GetCardDrawNameByCardId(cardId)
		local drawPath = AssetsUtils.GetCardDrawPath(drawName)
		table.insert(resDatas, drawPath)
	end

	local finishCB = function()
		self.viewComponent.viewData_.capsuleAnimation:setAnimation(0, 'play', false)
		-- 更新剩余抽卡次数
		if self.limitCount ~= -1 then
			self.limitCount = self.limitCount - 1
			if self.limitCount < 0 then
				self.limitCount = 0
			end
			self.viewComponent.viewData_.numLabel:setString(self.limitCount ..'/20')
		end
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

function CapsuleMediator:Initial( key )
	self.super:Initial(key)
	local scene = uiMgr:GetCurrentScene()
	local viewComponent = require( 'Game.views.drawCards.CapsuleView' ).new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	scene:AddGameLayer(viewComponent)
	self:UpdateCountUI()
	-- 绑定按钮回调
	self.viewComponent.viewData_.extractBtn:setOnClickScriptHandler(handler(self, self.ExtractButtonCallback))
	-- self.viewComponent.viewData_.shakeBtn:setOnClickScriptHandler(handler(self, self.ExtractButtonCallback))
	self.viewComponent.viewData_.multipleBtn:setOnClickScriptHandler(handler(self, self.ExtractButtonCallback))
	self.viewComponent.viewData_.cardPoolTitleBtn:setOnClickScriptHandler(handler(self, self.cardPoolTitleBtnCallback))
	self.viewComponent.viewData_.chooseBtn:setOnClickScriptHandler(handler(self, self.chooseButtonCallback))
	-- 绑定spine事件
	self.viewComponent.viewData_.capsuleAnimation:registerSpineEventHandler(handler(self, self.spineEventHandler), sp.EventType.ANIMATION_EVENT)
	self.viewComponent.viewData_.capsuleAnimation:registerSpineEventHandler(handler(self, self.spineEndHandler), sp.EventType.ANIMATION_END)
	if self.payload then
		-- 转换卡池数据
		if checkint(self.payload.coverBase) ~= 1 then -- 是否显示基础卡池	
			for i,v in ipairs(checktable(self.payload.base)) do
				table.insert(self.cardPoolDatas, v)
			end
		end
		for i,v in ipairs(checktable(self.payload.activity)) do
			table.insert(self.cardPoolDatas, v)
		end
	end
	-- fixed guide
	local drawCardStepId = checkint(GuideUtils.GetModuleData(GUIDE_MODULES.MODULE_DRAWCARD))
	if not GuideUtils.IsGuiding() and drawCardStepId == 0 and not GuideUtils.CheckIsHaveSixCards({dontShowTips = true}) then
		GuideUtils.GetDirector():FinishLocalModule(GUIDE_MODULES.MODULE_LOBBY)
		GuideUtils.SwitchModule(GUIDE_MODULES.MODULE_DRAWCARD, 57)
		self.isFixedGuide_ = true
	end
	-- 判断是处于引导
	if GuideUtils.IsGuiding() then
		self.cardPoolIndex = 1
		self:HideCardPoolUI()
		self:UpdateView()
	else
		-- 判断是否显示卡池选择页面
		if #self.cardPoolDatas > 1 then
			self:AddCapusleChooseView()
		else
			self:HideCardPoolChooseBtn()
			self.cardPoolIndex = 1
			self:EnterAction()
		end
	end
	
end
function CapsuleMediator:ExtractButtonCallback( sender )
	local tag = sender:getTag()
	local capsuleDatas = self.cardPoolDatas[self.cardPoolIndex]
	local consumeDatas = self:GetCapsuleConsume()
	local activityId = capsuleDatas.activityId
	if tag == 101 then -- 抽卡
		if gameMgr:GetAmountByGoodId(consumeDatas.one.goodsId) >= checkint(consumeDatas.one.num) then
			PlayAudioClip(AUDIOS.UI.ui_card_movie.id)
			if activityId then
				self:SendSignal(POST.ACTIVITY_GAMBLING_LUCKY.cmdName, {activityId = activityId, type = 1, click = self.viewComponent.clickStr, rotate = self.viewComponent.rotate})
			else
				self:SendSignal(POST.GAMBLING_LUCKY.cmdName, {type = 1, click = self.viewComponent.clickStr, rotate = self.viewComponent.rotate})
			end
		else
			if checkint(consumeDatas.one.goodsId) == DIAMOND_ID then
				if GAME_MODULE_OPEN.NEW_STORE then
					app.uiMgr:showDiamonTips()
				else
					local CommonTip  = require( 'common.NewCommonTip' ).new({text = __('幻晶石不足是否去商城购买？'),
						isOnlyOK = false, callback = function ()
							app.router:Dispatch({name = "HomeMediator"}, {name = "ShopMediator"})
						end})
					CommonTip:setPosition(display.center)
					app.uiMgr:GetCurrentScene():AddDialog(CommonTip)
				end
			else
				uiMgr:AddDialog("common.GainPopup", {goodId = consumeDatas.one.goodsId})
			end
		end
	elseif tag == 102 then -- 摇一摇(弃用)
		if gameMgr:GetAmountByGoodId(CAPSULE_VOUCHER_ID) >= self.voucherCost or gameMgr:GetUserInfo().diamond >= self.BuyDiamond then
			if self.viewComponent.viewData_.view:getChildByTag(505) then
				self.viewComponent.viewData_.view:getChildByTag(505):removeFromParent()
				self.viewComponent.canShake = false
				self.viewComponent.viewData_.extractBtn:setVisible(true)
				self.viewComponent.viewData_.extractBtnAct:setVisible(true)
				self.viewComponent.viewData_.diamondIcon:setVisible(true)
				self.viewComponent.viewData_.priceLabel:setVisible(true)
				self.viewComponent.viewData_.extractTextBg:setVisible(true)
				self.viewComponent.viewData_.extractRichLabel:setVisible(true)
			else
				self.viewComponent.canShake = true
				self.viewComponent.viewData_.extractBtn:setVisible(false)
				self.viewComponent.viewData_.extractBtnAct:setVisible(false)
				self.viewComponent.viewData_.diamondIcon:setVisible(false)
				self.viewComponent.viewData_.priceLabel:setVisible(false)
				self.viewComponent.viewData_.extractTextBg:setVisible(false)
				self.viewComponent.viewData_.extractRichLabel:setVisible(false)
				local shakeAct = sp.SkeletonAnimation:create(
    			  'effects/capsule/shake.json',
    			  'effects/capsule/shake.atlas',
    			  1)
    			shakeAct:update(0)
    			shakeAct:setToSetupPose()
    			shakeAct:setAnimation(0, 'idle', true)
    			self.viewComponent.viewData_.view:addChild(shakeAct)
    			shakeAct:setPosition(cc.p(display.cx - 490, display.cy - 258))
    			shakeAct:runAction(cc.Spawn:create(
    				cc.ScaleTo:create(1, 2),
    				cc.MoveTo:create(1, cc.p(display.cx, display.cy))
    			))
    			shakeAct:setTag(505)
    		end
  		end
	elseif tag == 103 then -- 连抽
		if gameMgr:GetAmountByGoodId(consumeDatas.six.goodsId) >= checkint(consumeDatas.six.num) then
			PlayAudioClip(AUDIOS.UI.ui_card_movie.id)
			if activityId then
				self:SendSignal(POST.ACTIVITY_GAMBLING_LUCKY.cmdName, {activityId = activityId, type = 2, click = self.viewComponent.clickStr, rotate = self.viewComponent.rotate})
			else
				self:SendSignal(POST.GAMBLING_LUCKY.cmdName, {type = 2, click = self.viewComponent.clickStr, rotate = self.viewComponent.rotate})
			end
		else
			if checkint(consumeDatas.six.goodsId) == DIAMOND_ID then
				if GAME_MODULE_OPEN.NEW_STORE then
					app.uiMgr:showDiamonTips()
				else
					local CommonTip  = require( 'common.NewCommonTip' ).new({text = __('幻晶石不足是否去商城购买？'),
						isOnlyOK = false, callback = function ()
							app.router:Dispatch({name = "HomeMediator"}, {name = "ShopMediator"})
						end})
					CommonTip:setPosition(display.center)
					app.uiMgr:GetCurrentScene():AddDialog(CommonTip)
				end
			else
				uiMgr:AddDialog("common.GainPopup", {goodId = consumeDatas.six.goodsId})
			end
		end
	end
end
--[[
卡池标题按钮回调
--]]
function CapsuleMediator:cardPoolTitleBtnCallback( sender )
	PlayAudioByClickNormal()
	self:HideCapsuleUI()
    local capsulePrizeView = require( 'Game.views.drawCards.CapsulePrizeView' ).new({cardPoolDatas = self.cardPoolDatas[checkint(self.cardPoolIndex)], closeAction = true})
    local scene = uiMgr:GetCurrentScene()
    scene:AddDialog(capsulePrizeView)
end
--[[
切换卡池按钮回调
--]]
function CapsuleMediator:chooseButtonCallback( sender )
	PlayAudioByClickNormal()
	self:AddCapusleChooseView()
end
-- spine 自定义回调
function CapsuleMediator:spineEventHandler(event)
	if not event then return end
	if not event.eventData then return end
	if 'play' == event.eventData.name then
		self:ShowCardAction()
		-- 移除屏蔽层
		local scene = uiMgr:GetCurrentScene()
		scene:RemoveViewForNoTouch()
	end
end
-- 抽卡展示
function CapsuleMediator:ShowCardAction()
	if self.showCardIndex > #self.rewards then
		self.viewComponent:runAction(
			cc.Sequence:create(
				cc.DelayTime:create(0.5),
				cc.CallFunc:create(function()
	           		self.viewComponent.canRotate = true
	            	self.viewComponent.canClick = true
	            	self.viewComponent:ResetLeftBtn()
	           		self.viewComponent.viewData_.fireAnimation:setVisible(true)
				end)
			)
		)
		self:ShowActivityImg()
		self.viewComponent.viewData_.extractBtn:setEnabled(true)
		self.viewComponent.viewData_.multipleBtn:setEnabled(true)
	else
		local singleCard = self.rewards[self.showCardIndex]
		local goodsId = checkint(singleCard.goodsId)
		local gtype = CommonUtils.GetGoodTypeById(goodsId)
		local scene = uiMgr:GetCurrentScene()
		local CapsuleCardView  = require( 'Game.views.drawCards.CapsuleCardView' ).new({data = self.rewards[self.showCardIndex]})
		CapsuleCardView:setPosition(display.center)
		CapsuleCardView:setTag(9999)
		-- CapsuleCardView:setLocalZOrder(602)
		scene:AddDialog(CapsuleCardView)
		-- 增加抽卡延时
		local canSkip = false
		self:GetViewComponent():runAction(
			cc.Sequence:create(
				cc.DelayTime:create(0.5),
				cc.CallFunc:create(function()
					canSkip = true
				end)
			)
		)
		-- 抽卡按钮回调
		CapsuleCardView.viewData_.share:setOnClickScriptHandler(handler(self, self.ShareButtonCallback))
		CapsuleCardView.viewData_.okBtn:setOnClickScriptHandler(function (sender)
			if canSkip then
				sender:setEnabled(false)

				PlayAudioByClickNormal()
				-- 更新抽卡界面
				self:UpdateView()
				-- 停止角色语音
				CapsuleCardView:StopCardVoice()
				GuideUtils.DispatchStepEvent()
				local preViewNode = scene:GetDialogByTag(9999)
				local function deleteView()
					self.showCardIndex = self.showCardIndex + 1
					if preViewNode then
						local view = scene:GetDialogByTag(9999)
						view:setVisible(false)
						view:setLocalZOrder(-9999)
						view:setTag(-1)
						view:runAction(
							cc.Sequence:create(
								cc.DelayTime:create(1),
								cc.RemoveSelf:create()
							)
						)
						-- scene:RemoveDialogByTag(9999)
					end
					AppFacade.GetInstance():DispatchObservers("Capsule_Multipe_Draw")
				end
				local action = cc.Sequence:create(cc.FadeOut:create(0.3), cc.CallFunc:create(deleteView))
				preViewNode.viewData_.view:runAction( action )
			end
		end)
	end

end
--[[
分享按钮回调
--]]
function CapsuleMediator:ShareButtonCallback( sender )
	PlayAudioByClickNormal()
	local viewComponent = self:GetViewComponent()
	local shareLayer = require('Game.views.share.CapsuleShareLayer').new({
		cardId = self.rewards[self.showCardIndex].goodsId, clickStr = viewComponent.clickStr, rotate = viewComponent.rotate
	})
	shareLayer:setAnchorPoint(cc.p(0.5, 0.5))
	shareLayer:setTag(5361)
	shareLayer:setPosition(cc.p(display.cx, display.cy))
	uiMgr:GetCurrentScene():AddDialog(shareLayer)
end
-- 动画结束画面回调
function CapsuleMediator:spineEndHandler(event)
	if event.animation == 'play' then
    	self.viewComponent:performWithDelay(
            function ()
            	self.viewComponent.viewData_.capsuleAnimation:update(0)
             	self.viewComponent.viewData_.capsuleAnimation:setToSetupPose()
    			self.viewComponent.viewData_.capsuleAnimation:addAnimation(0, 'idle', true)

            end,
            (1 * cc.Director:getInstance():getAnimationInterval())
        )
	end
end
--[[
更新抽卡页面
--]]
function CapsuleMediator:UpdateView()
	local viewData = self:GetViewComponent().viewData_
	local capsuleDatas = self.cardPoolDatas[self.cardPoolIndex]
	-- 刷新抽卡消耗
	local consumeDatas = self:GetCapsuleConsume()
	viewData.diamondIcon:setTexture(CommonUtils.GetGoodsIconPathById(checkint(consumeDatas.one.goodsId)))
	viewData.priceLabel:setString(tostring(consumeDatas.one.num))
	viewData.multipleIcon:setTexture(CommonUtils.GetGoodsIconPathById(checkint(consumeDatas.six.goodsId)))
	viewData.multiplePriceLabel:setString(tostring(consumeDatas.six.num))
	-- 判断是否为活动卡池
	if capsuleDatas.activityId then
		--viewData.cardPoolTitleBtn:getLabel():setString(capsuleDatas.poolName[i18n.getLang()])
		display.commonLabelParams(viewData.cardPoolTitleBtn:getLabel() , { text = capsuleDatas.poolName[i18n.getLang()] , reqW = 270 } )
		viewData.activityImg:setTexture(_res('ui/home/capsule/activityCapsule/' .. tostring(capsuleDatas.masterView[i18n.getLang()]) .. '.png'))
		viewData.activityImg:setVisible(true)
	else
		--viewData.cardPoolTitleBtn:getLabel():setString(__('普通卡池'))
		display.commonLabelParams(viewData.cardPoolTitleBtn:getLabel() , { text =__('普通卡池') , reqW = 270  } )
		viewData.activityImg:setVisible(false)
		-- 判断是否有抽卡次数限制
		if capsuleDatas.one.leftTimes then
			self.limitCount = checkint(capsuleDatas.one.leftTimes)
		end
		if self.limitCount == -1 then
			self.viewComponent.viewData_.numLabel:setString(' ')
		else
			self.viewComponent.viewData_.numLabel:setString(self.limitCount ..'/20')
		end
	end
end
--[[
选择卡池
@params index int 卡池序号
--]]
function CapsuleMediator:ChooseCardPool( index )
	if not index then return end
	self.cardPoolIndex = checkint(index)
	-- 移除选择页面
	local capsuleChooseView = self.viewComponent.viewData_.view:getChildByName('CapsuleChooseView')
	if capsuleChooseView then
		capsuleChooseView.eaterLayer:setVisible(false)
		capsuleChooseView:runAction(
			cc.Sequence:create(
				cc.Spawn:create(
					cc.FadeTo:create(0.25, 100),
					cc.ScaleTo:create(0.25, 0.2),
					cc.MoveTo:create(0.25, cc.p(display.width - 95 - display.SAFE_L, display.height - 190))
				),
				cc.CallFunc:create(function () 
					self.viewComponent:ResetLeftBtn()
					self:ShowCapsuleUI()
					self:ShowCardPoolUI()
					self:EnterAction()
				end),
				cc.RemoveSelf:create()
			)
		)
	end
end
--[[
显示卡池选择页面
--]]
function CapsuleMediator:AddCapusleChooseView()
	self:HideCardPoolUI()
	self:HideCapsuleUI()
	self:HideActivityImg()
	if not self.viewComponent.viewData_.view:getChildByName('CapsuleChooseView') then
		local capsuleChooseView = require( 'Game.views.drawCards.CapsuleChooseView' ).new({cardPoolDatas = self.cardPoolDatas})
		capsuleChooseView:setName('CapsuleChooseView')
		capsuleChooseView:setOpacity(0)
		self.viewComponent.viewData_.view:addChild(capsuleChooseView, 20)
		capsuleChooseView:setPosition(display.center)
		capsuleChooseView:runAction(cc.FadeIn:create(0.3))
	end
end
--[[
显示抽卡UI
--]]
function CapsuleMediator:ShowCapsuleUI()
	self.viewComponent.canRotate = true
	self.viewComponent.canClick = true
	self.viewComponent.viewData_.multipleLayout:setVisible(true)
	self.viewComponent.viewData_.extractLayout:setVisible(true)
end
--[[
隐藏抽卡UI
--]]
function CapsuleMediator:HideCapsuleUI()
	self.viewComponent.canRotate = false
	self.viewComponent.canClick = false
	self.viewComponent.viewData_.multipleLayout:setVisible(false)
	self.viewComponent.viewData_.extractLayout:setVisible(false)
end
--[[
显示切换卡池相关UI
--]]
function CapsuleMediator:ShowCardPoolUI()
	self.viewComponent.viewData_.chooseLayout:setVisible(true)
end
--[[
隐藏切换卡池相关UI
--]]
function CapsuleMediator:HideCardPoolUI()
	self.viewComponent.viewData_.chooseLayout:setVisible(false)
end
--[[
隐藏卡池切换按钮
--]]
function CapsuleMediator:HideCardPoolChooseBtn()
	self.viewComponent.viewData_.chooseBtn:setVisible(false)
end
--更新顶部货币数量
function CapsuleMediator:UpdateCountUI()
	local viewData = self:GetViewComponent().viewData_
	if viewData.moneyNods then
		for id,v in pairs(viewData.moneyNods) do
			v:updataUi(checkint(id)) --刷新每一个货币数量
		end
	end
end
--[[
进入动画
--]]
function CapsuleMediator:EnterAction()
	self:UpdateView()
	self:ShowActivityImg()
	local viewData = self:GetViewComponent().viewData_
	viewData.multipleBtn:setEnabled(false)
	viewData.extractBtn:setEnabled(false)
	viewData.cardPoolTitleBtn:setEnabled(false)
	viewData.chooseBtn:setEnabled(false)
	viewData.extractLayout:setPositionY(viewData.extractLayout:getPositionY() - 200)
	viewData.multipleLayout:setPositionY(viewData.multipleLayout:getPositionY() - 200)
	viewData.extractLayout:setOpacity(0)
	viewData.multipleLayout:setOpacity(0)
	viewData.chooseLayout:setOpacity(0)
	local btnAction = cc.Spawn:create(
		cc.FadeIn:create(1),
		cc.MoveBy:create(1, cc.p(0, 200))
	)
	self:GetViewComponent():runAction(
		cc.Sequence:create(
			cc.Spawn:create(
				cc.TargetedAction:create(viewData.extractLayout, cc.Spawn:create(
					cc.EaseBackOut:create(cc.MoveBy:create(0.5, cc.p(0, 200))),
					cc.FadeIn:create(0.5)
				)),
				cc.TargetedAction:create(viewData.multipleLayout, cc.Spawn:create(
					cc.EaseBackOut:create(cc.MoveBy:create(0.5, cc.p(0, 200))),
					cc.FadeIn:create(0.5)
				)),
				cc.TargetedAction:create(viewData.chooseLayout, 
					cc.FadeIn:create(0.5)
				)
			),
			cc.CallFunc:create(function()
				viewData.multipleBtn:setEnabled(true)
				viewData.extractBtn:setEnabled(true)
				viewData.cardPoolTitleBtn:setEnabled(true)
				viewData.chooseBtn:setEnabled(true)
			end)
		)
	)
end
--[[
显示活动图
--]]
function CapsuleMediator:ShowActivityImg()
	-- 活动图
	local viewData = self.viewComponent.viewData_
	viewData.activityImg:setOpacity(0)
	viewData.activityImg:runAction(cc.FadeIn:create(0.3))
end
--[[
隐藏活动图
@params isDelay bool 是否延时
--]]
function CapsuleMediator:HideActivityImg( isDelay )
	local action = nil
	if isDelay then
		action = cc.Sequence:create(
    		cc.DelayTime:create(3),
    		cc.FadeOut:create(0.3)
    	)
	else
		action = cc.FadeOut:create(0.3)
	end
    self.viewComponent.viewData_.activityImg:runAction(action)
end
--[[
获取抽卡消耗
--]]
function CapsuleMediator:GetCapsuleConsume()
	local cardPoolDatas = self.cardPoolDatas[self.cardPoolIndex] or {}
	local type = {
		'one',
		'six'
	}
	local datas = {}
	for i,v in ipairs(type) do
		local cardPoolData = cardPoolDatas[v] or {}
		datas[v] = {}
		if cardPoolDatas.activityId then
			-- 活动卡池
			for index, consumeData in ipairs(checktable(cardPoolData)) do
				if index == #cardPoolData then
					datas[v].goodsId = consumeData.goodsId
					datas[v].num = consumeData.num
					break
				end
				if gameMgr:GetAmountByGoodId(consumeData.goodsId) >= checkint(consumeData.num) then
					datas[v].goodsId = consumeData.goodsId
					datas[v].num = consumeData.num
					break
				end
			end
		else
			-- 基础卡池
			if Platform.id > 4000 and Platform.id < 5000 then
				if gameMgr:GetAmountByGoodId(cardPoolData.goodsId) >= cardPoolData.num then
					datas[v].goodsId = cardPoolData.goodsId
					datas[v].num = cardPoolData.num
				else
					datas[v].goodsId = DIAMOND_ID
					datas[v].num = cardPoolData.diamond
					if cardPoolData.gold then
						datas[v].gold = cardPoolData.gold
					end
				end
			else
				datas[v].goodsId = cardPoolData.goodsId
				datas[v].num = cardPoolData.num
			end
		end
	end
	return datas
end
function CapsuleMediator:OnRegist()
	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightHide")
	regPost(POST.GAMBLING_LUCKY)
	regPost(POST.ACTIVITY_GAMBLING_LUCKY)
	if not self.isFixedGuide_ then
		GuideUtils.DispatchStepEvent()
	end
    self.bgm = PlayAudioClip(AUDIOS.UI.ui_await.id, true)
end
function CapsuleMediator:OnUnRegist()
	local scene = uiMgr:GetCurrentScene()
	scene:RemoveGameLayer(self.viewComponent)
	-- self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "hide")
	unregPost(POST.GAMBLING_LUCKY)
	unregPost(POST.ACTIVITY_GAMBLING_LUCKY)
	AppFacade.GetInstance():DispatchObservers(HomeScene_ChangeCenterContainer, "hide")
	-- 关闭背景音乐
	if self.bgm then
		self.bgm:Stop(true)
		self.bgm = nil
	end
	AppFacade.GetInstance():DispatchObservers(SGL.BREAK_TO_HOME_MEDIATOR)
end

return CapsuleMediator
