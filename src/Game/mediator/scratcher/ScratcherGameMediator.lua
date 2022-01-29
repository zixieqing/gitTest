---@class ScratcherGameMediator : Mediator
---@field viewComponent ScratcherGameView
local ScratcherGameMediator = class('ScratcherGameMediator', mvc.Mediator)

local NAME = "ScratcherGameMediator"

function ScratcherGameMediator:ctor(params, viewComponent)
	self.super.ctor(self, NAME, viewComponent)
	self.data = checktable(params.status) or {}
	self.poolId = params.tasks.poolId

	local parameter = CONF.FOOD_VOTE.PARMS:GetValue(params.tasks.groupId)
	self.ticketGoodsId = parameter.ticketGoodsId
	self.tasks = params.tasks

	self:CheckRare()
end

function ScratcherGameMediator:Initial(key)
	self.super.Initial(self, key)
	local scene = app.uiMgr:GetCurrentScene()
	local viewComponent = require('Game.views.scratcher.ScratcherGameView').new(self.ticketGoodsId)
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	scene:AddDialog(viewComponent)
	local viewData = viewComponent.viewData
	viewData.backBtn:setOnClickScriptHandler(handler(self, self.OnBackBtnClickHandler))
	viewData.resetBtn:setOnClickScriptHandler(handler(self, self.OnResetBtnClickHandler))
	viewData.detailBtn:setOnClickScriptHandler(handler(self, self.OnDetailBtnClickHandler))
	viewData.souvenirBtn:setOnClickScriptHandler(handler(self, self.OnSourvenirBtnClickHandler))
	viewData.onceBtn:setOnClickScriptHandler(handler(self, self.OnScrapeBtnClickHandler))
	viewData.fiveBtn:setOnClickScriptHandler(handler(self, self.OnScrapeBtnClickHandler))

	local poolConf = CONF.FOOD_VOTE.LOTTERY_POOL:GetValue(self.poolId)
	self.viewComponent:updatePoolCardImg(poolConf.card)
    
	for i = 1, 28 do
		local collection = checktable(self.data.collected)[tostring(i)]
		local cellPoint = self:getCellPos(i)
		if collection then
			local goodsIcon = require('common.GoodNode').new({id = collection.goodsId, amount = collection.num, showAmount = true})
			goodsIcon:setScale(0.9)
			goodsIcon:setPosition(cellPoint)
			goodsIcon:setOnClickScriptHandler(handler(self, self.OnCellRewardBtnClickHandler))
			viewData.view:addChild(goodsIcon, 10)
			viewData.goodsIcons[tostring(i)] = goodsIcon
		end
		self.viewComponent:updateGoodsFrame(i, viewData.goodsIcons[tostring(i)] ~= nil, cellPoint.x, cellPoint.y)
	end

    local key = string.format('%s_ScrapeCollectSourvenir', tostring(app.gameMgr:GetUserInfo().playerId))
	local needOpen = cc.UserDefault:getInstance():getBoolForKey(key, false)
	if needOpen then
		viewData.redPointImage:setVisible(true)
	end
	
	self:CheckLeft()
end

function ScratcherGameMediator:getCellPos(i)
	return cc.p(
		(i-1)%7*114 + display.cx - 558-5,
		display.cy + 197 - math.floor( (i-1)/7 )*114
	)
end

function ScratcherGameMediator:OnRegist()
	regPost(POST.FOOD_COMPARE_RESET_POOL)
	regPost(POST.FOOD_COMPARE_LOTTERY)
	regPost(POST.FOOD_COMPARE_HAS_RARE_ACK)
	regPost(POST.FOOD_COMPARE_STAMP_HOME)
end

function ScratcherGameMediator:OnUnRegist()
    unregPost(POST.FOOD_COMPARE_RESET_POOL)
    unregPost(POST.FOOD_COMPARE_LOTTERY)
    unregPost(POST.FOOD_COMPARE_HAS_RARE_ACK)
    unregPost(POST.FOOD_COMPARE_STAMP_HOME)
	local scene = app.uiMgr:GetCurrentScene()
	scene:RemoveGameLayer(self.viewComponent)
end

function ScratcherGameMediator:InterestSignals()
    local signals = {
        POST.FOOD_COMPARE_RESET_POOL.sglName,
        POST.FOOD_COMPARE_LOTTERY.sglName,
		POST.FOOD_COMPARE_STAMP_HOME.sglName,
		POST.FOOD_COMPARE_HAS_RARE_ACK.sglName,
		SGL.REFRESH_NOT_CLOSE_GOODS_EVENT,
		SGL.CACHE_MONEY_UPDATE_UI
	}
	return signals
end

function ScratcherGameMediator:ProcessSignal(signal)
    local name = signal:GetName()
	local body = signal:GetBody()
	-- dump(body, name)
	if POST.FOOD_COMPARE_RESET_POOL.sglName == name then
		self.tasks.poolId = 0
		self.data.hasRare = 1

		local mediator = require('Game.mediator.scratcher.ScratcherSelectMediator').new(self.tasks)
		AppFacade.GetInstance():RegistMediator(mediator)
		
	elseif POST.FOOD_COMPARE_LOTTERY.sglName == name then
		CommonUtils.DrawRewards({ { goodsId = self.ticketGoodsId, num = -1 * body.requestData.times}})
		-- app.uiMgr:AddDialog('common.RewardPopup', body)
		if not self.data.collected then
			self.data.collected = {}
		end
		table.merge(self.data.collected, body.rewardsPos)
		
		local before = #self.rareRewards
		for _, v in pairs(body.rewardsPos) do
			for k, v2 in pairs(self.rareRewards) do
				if v.goodsId == v2.rewards.goodsId and v.num == v2.rewards.num then
					v2.left = v2.left - 1
					if 0 == v2.left then
						table.remove(self.rareRewards, k)
					end
					break
				end
			end
		end
		local after = #self.rareRewards
		if 0 == after and after < before then
			self.data.hasRare = 0
		end

		self.viewComponent.blockLayer:setVisible(true)
		local lotterySpineCallback = function()
			self.viewComponent.blockLayer:setVisible(false)
			app.uiMgr:AddDialog('common.RewardPopup', body)
		end

		local hasAddSpineCallback = false
		local viewData = self.viewComponent.viewData
		for i = 1, 28 do
			local collection = body.rewardsPos[tostring(i)]
			local cellPoint = self:getCellPos(i)
			if collection then
				self.viewComponent:addLotterySpine(cellPoint.x, cellPoint.y, hasAddSpineCallback == false and lotterySpineCallback or nil)
				hasAddSpineCallback = true
				local goodsIcon = viewData.goodsIcons[tostring(i)]
				if goodsIcon then
					goodsIcon:RefreshSelf({goodsId = collection.goodsId, amount = collection.num, showAmount = true})
				else
					goodsIcon = require('common.GoodNode').new({id = collection.goodsId, amount = collection.num, showAmount = true})
					goodsIcon:setScale(0.9)
					goodsIcon:setPosition(cellPoint)
					goodsIcon:setOnClickScriptHandler(handler(self, self.OnCellRewardBtnClickHandler))
					viewData.view:addChild(goodsIcon, 10)
					viewData.goodsIcons[tostring(i)] = goodsIcon
				end
			end
			self.viewComponent:updateGoodsFrame(i, viewData.goodsIcons[tostring(i)] ~= nil, cellPoint.x, cellPoint.y)
		end
		
		if 0 < checkint(body.stamp) then
			local key = string.format('%s_ScrapeCollectSourvenir', tostring(app.gameMgr:GetUserInfo().playerId))
			cc.UserDefault:getInstance():setBoolForKey(key, true)
			cc.UserDefault:getInstance():flush()

			viewData.redPointImage:setVisible(true)
		end

		self:CheckLeft()
		if 28 == table.nums(self.data.collected or {}) then
			self.tasks.poolId = 0
		end

	elseif POST.FOOD_COMPARE_HAS_RARE_ACK.sglName == name then
		self.data.hasRare = 1

	elseif POST.FOOD_COMPARE_STAMP_HOME.sglName == name then
		local key = string.format('%s_ScrapeCollectSourvenir', tostring(app.gameMgr:GetUserInfo().playerId))
		cc.UserDefault:getInstance():setBoolForKey(key, false)
		cc.UserDefault:getInstance():flush()

		local viewData = self.viewComponent.viewData
		viewData.redPointImage:setVisible(false)

		local mediator = require('Game.mediator.scratcher.ScratcherSouvenirMediator').new({activityHomeData = self.tasks, stampHomeData = body})
		AppFacade.GetInstance():RegistMediator(mediator)

	elseif name == SGL.REFRESH_NOT_CLOSE_GOODS_EVENT then
		local viewData = self.viewComponent.viewData
		for k,v in pairs(viewData.moneyNodes) do
			v:updataUi(checkint( k ))
		end
		self:CheckLeft()
	elseif name == SGL.CACHE_MONEY_UPDATE_UI then
		local viewData = self.viewComponent.viewData
		for k,v in pairs(viewData.moneyNodes) do
			v:updataUi(checkint( k ))
		end
		self:CheckLeft()
	end
end

function ScratcherGameMediator:OnBackBtnClickHandler( sender )
	PlayAudioByClickNormal()
	
    app:UnRegsitMediator(NAME)
end

function ScratcherGameMediator:OnResetBtnClickHandler( sender )
	PlayAudioByClickNormal()
	
	if 0 == self.tasks.poolId then
		local mediator = require('Game.mediator.scratcher.ScratcherSelectMediator').new(self.tasks)
		AppFacade.GetInstance():RegistMediator(mediator)
	else
		local scene = app.uiMgr:GetCurrentScene()
		local CommonTip  = require( 'common.NewCommonTip' ).new({text = __('确定要手动重置卡池内容吗？'), extra = __('（确定后将重置抽卡进度）'),
			btnTextL = __('放弃'), callback = handler(self, self.OnResetConfirmCallBack)})
		CommonTip:setPosition(display.center)
		scene:AddDialog(CommonTip)
	end
end

function ScratcherGameMediator:OnDetailBtnClickHandler( sender )
	PlayAudioByClickNormal()
	
	local mediator = require('Game.mediator.scratcher.ScratcherPreviewMediator').new(self.data)
	AppFacade.GetInstance():RegistMediator(mediator)
end

function ScratcherGameMediator:OnSourvenirBtnClickHandler( sender )
	PlayAudioByClickNormal()

	self:SendSignal(POST.FOOD_COMPARE_STAMP_HOME.cmdName, {activityId = self.data.requestData.activityId})
end

function ScratcherGameMediator:OnScrapeBtnClickHandler( sender )
	PlayAudioByClickNormal()

	if 0 == self.tasks.poolId then
		local mediator = require('Game.mediator.scratcher.ScratcherSelectMediator').new(self.tasks)
		AppFacade.GetInstance():RegistMediator(mediator)
		return
	end

	self.times = sender:getTag()
	
	if 0 == self.data.hasRare then
		self:ScrapeNeedsConfirm()
	else
		self:OnScrapeConfirmCallBack()
	end

end

function ScratcherGameMediator:OnResetConfirmCallBack()
	self:SendSignal(POST.FOOD_COMPARE_RESET_POOL.cmdName, {activityId = self.data.requestData.activityId})
end

function ScratcherGameMediator:ScrapeNeedsConfirm()
    local scene = app.uiMgr:GetCurrentScene()
    local CommonTip  = require( 'common.NewCommonTip' ).new({text = __('点击确定坚持继续抽取'),
		extra = __('（已抽走稀有奖励，建议重置卡池内容再抽取卡池）'), btnTextL = __('放弃'),
		cancelBack = handler(self, self.OnScrapeCancelCallBack),
		closeBgCB = handler(self, self.OnScrapeCancelCallBack),
        callback = handler(self, self.OnScrapeConfirmCallBack)})
    CommonTip:setPosition(display.center)
    CommonTip.extra:setHorizontalAlignment(cc.TEXT_ALIGNMENT_CENTER)
    scene:AddDialog(CommonTip)
end

function ScratcherGameMediator:OnScrapeCancelCallBack()
	self:SendSignal(POST.FOOD_COMPARE_HAS_RARE_ACK.cmdName, {activityId = self.data.requestData.activityId})
end

function ScratcherGameMediator:OnScrapeConfirmCallBack()
	self.data.hasRare = 1

	local times = self.times

	local ownNum = CommonUtils.GetCacheProductNum(self.ticketGoodsId)
	if ownNum < times then
		local goodsConfig = CommonUtils.GetConfig('goods', 'goods', self.ticketGoodsId) or {}
		app.uiMgr:ShowInformationTips(string.fmt(__('_des_不足'), {_des_=tostring(goodsConfig.name)}))
		return
	end

	self:SendSignal(POST.FOOD_COMPARE_LOTTERY.cmdName, {activityId = self.data.requestData.activityId, times = times})
end

function ScratcherGameMediator:OnCellRewardBtnClickHandler( sender )
	app.uiMgr:ShowInformationTipsBoard({
		targetNode = sender, iconId = checkint(sender.goodId), type = 1
	})
end

function ScratcherGameMediator:CheckLeft()
	local viewData = self.viewComponent.viewData
	local ownNum = CommonUtils.GetCacheProductNum(self.ticketGoodsId)
	local collectedCount = table.nums(self.data.collected or {})
	local multi = math.min(5, 28 - collectedCount, ownNum)
	if 0 < multi then
		viewData.fiveBtn:getLabel():setString(string.fmt( __("刮_num_次"), {_num_=multi} ) )
		viewData.fiveBtn:setTag(multi)
	else
		viewData.fiveBtn:getLabel():setString(string.fmt( __("刮_num_次"), {_num_=5} ) )
		viewData.fiveBtn:setTag(5)
	end
end

function ScratcherGameMediator:CheckRare()
	local rareRewards = {}
    for k, v in orderedPairs(self.data.lotteryPool) do
        if type(v) == "table" then
            if "1" == v.rare then
				-- 稀有
				local reward = clone(v)
				reward.left = tonumber(reward.appear)
				rareRewards[#rareRewards+1] = reward
            end
        end
	end
	
	for _, v in pairs(self.data.collected) do
		for k, v2 in pairs(rareRewards) do
			if v.goodsId == v2.rewards.goodsId and v.num == v2.rewards.num then
				v2.left = v2.left - 1
				if 0 == v2.left then
					table.remove(rareRewards, k)
				end
				break
			end
		end
	end
	self.rareRewards = rareRewards
end

function ScratcherGameMediator:ResetView(data, poolId)
	self.data = data
	self.poolId = poolId

	local poolConf = CONF.FOOD_VOTE.LOTTERY_POOL:GetValue(self.poolId)
	self.viewComponent:updatePoolCardImg(poolConf.card)

	local viewData = self.viewComponent.viewData
	for i = 1, 28 do
		local collection = self.data.collected[tostring(i)]
		local cellPoint = self:getCellPos(i)
		if collection then
			local goodsIcon = viewData.goodsIcons[tostring(i)]
			if goodsIcon then
				goodsIcon:RefreshSelf({goodsId = collection.goodsId, amount = collection.num, showAmount = true})
			else
				goodsIcon = require('common.GoodNode').new({id = collection.goodsId, amount = collection.num, showAmount = true})
				goodsIcon:setScale(0.9)
				goodsIcon:setPosition(cellPoint)
				goodsIcon:setOnClickScriptHandler(handler(self, self.OnCellRewardBtnClickHandler))
				viewData.view:addChild(goodsIcon, 10)
				viewData.goodsIcons[tostring(i)] = goodsIcon
			end
		else
			local goodsIcon = viewData.goodsIcons[tostring(i)]
			if goodsIcon then
				goodsIcon:removeFromParent()
				viewData.goodsIcons[tostring(i)] = nil
			end
		end
		self.viewComponent:updateGoodsFrame(i, viewData.goodsIcons[tostring(i)] ~= nil, cellPoint.x, cellPoint.y)
	end
	self:CheckLeft()

    local key = string.format('%s_ScrapeCollectSourvenir', tostring(app.gameMgr:GetUserInfo().playerId))
	local needOpen = cc.UserDefault:getInstance():getBoolForKey(key, false)
	if needOpen then
		viewData.redPointImage:setVisible(true)
	else
		viewData.redPointImage:setVisible(false)
	end
	self:CheckRare()
end

return ScratcherGameMediator
