--[[
奖励mediator
--]]
local Mediator = mvc.Mediator
---@class ActivityChestMediator :Mediator
local ActivityChestMediator = class("ActivityChestMediator", Mediator)
local NAME = "Game.mediator.activity.chest.ActivityChestMediator"
ActivityChestMediator.NAME = NAME
local CHEST_DOUBLE_BUY_SUCCESS_EVENT =  "CHEST_DOUBLE_BUY_SUCCESS_EVENT"
local CHEST_STATUS = {
	NOT_OPEN     = 1,  --未打开
	DO_OPENING   = 2,  --打开中
	ALREADY_OPEN = 3,  --已打开
}
local jumpViewData ={
	[JUMP_MODULE_DATA.TAKEWAY] = {
		['jumpView']    = {
			{mediator = 'HomeMediator' , gameSence = true },
			{mediator = 'order.OrderMediator' , gameSence = false}
		},
		text = __('配送外卖获得伴手礼') ,
		image = "waimai_idle_0",
		imageIsShow = true ,
	}
}

function ActivityChestMediator:ctor(params, viewComponent)
	self.super.ctor(self, NAME, viewComponent)
	params = params or {}
	self.isControllable_ = true
	self.activityId = params.activityId
	self.activityName = params.activityName or  ''
	self.ruleDescr = params.ruleDescr or ""       -- 获得规则
	self.activityCountDownName = app.activityMgr:getActivityCountdownNameByType(ACTIVITY_TYPE.CHEST_ACTIVITY , self.activityId)  -- 活动的名称
	self.openCountDownsChest = {}
	self.activityChestData = nil
end
function ActivityChestMediator:InterestSignals()
	return {
		POST.ACTIVITY2_CR_BOX_DRAW_FINAL_REWARDS.sglName ,
		POST.ACTIVITY2_CR_BOX_DRAW_BOX.sglName ,
		POST.ACTIVITY2_CR_BOX_OPEN_BOX.sglName,
		POST.ACTIVITY2_CR_BOX.sglName ,
		COUNT_DOWN_ACTION
	}
end

function ActivityChestMediator:ProcessSignal(signal)
	local name = signal:GetName()
	if name == COUNT_DOWN_ACTION then
		local body = signal:GetBody()
		self:UpdateTimeLabel(body)
	elseif name == POST.ACTIVITY2_CR_BOX_DRAW_BOX.sglName then
		self:RequestDrawBox(signal)
	elseif name == POST.ACTIVITY2_CR_BOX_OPEN_BOX.sglName then
		self:RequestOpenBox(signal)
	elseif name == POST.ACTIVITY2_CR_BOX_DRAW_FINAL_REWARDS.sglName then
		self:RequestFinalRewards(signal)
	elseif name == CHEST_DOUBLE_BUY_SUCCESS_EVENT then
		self:RequestDoubleEffect(signal)
	elseif name == POST.ACTIVITY2_CR_BOX.sglName then
		self:RequestChestHomeActivity(signal)
	end
end
-- inheritance method
function ActivityChestMediator:Initial(key)
	self.super.Initial(self, key)
	---@type ActivityChestScene
	local viewComponent =  app.uiMgr:SwitchToTargetScene("Game.views.activity.chest.ActivityChestScene")
	self:SetViewComponent(viewComponent)
	local viewData = viewComponent.viewData
	display.commonUIParams(viewData.backBtn , {cb = handler(self, self.BackClick)})
	display.commonUIParams(viewData.tabNameLabel , {cb = handler(self, self.LookRuleClick)})
	for index, cellData in pairs(viewData.cellLayoutDatas) do
		display.commonUIParams(cellData.clickLayer , {cb = handler(self, self.ChestSmallClick) , animate = true })
	end
	display.commonUIParams(viewData.leftBottomLayout , {cb = handler(self, self.ChestBigClick)  })
	display.commonUIParams(viewData.doubleBtn , {cb = handler(self, self.DoubleEffectClick)  })
end
function ActivityChestMediator:DoubleEffectClick(sender)
	local mediator = require("Game.mediator.activity.chest.ActivityChestDoubleEffectMediator").new({
		productId        = self.activityChestData.productId,
		channelProductId = self.activityChestData.channelProductId,
		price            = self.activityChestData.price,
		hasPurchased     = self.activityChestData.hasPurchased,
	})
	app:RegistMediator(mediator)
end
function ActivityChestMediator:ChestBigClick(sender)
	local mediator = require("Game.mediator.activity.chest.ActivityChestBigMediator").new({
		finalRewardsProgress = checkint(self.activityChestData.finalRewardsProgress),
		finalRewardsTarget   = checkint(self.activityChestData.finalRewardsTarget),
		finalRewardsHasDrawn = checkint(self.activityChestData.finalRewardsHasDrawn),
		activityId           = checkint(self.activityId),
		chestName            = self.activityChestData.name,
		finalRewards         = self.activityChestData.finalRewards
	})
	app:RegistMediator(mediator)
end
function ActivityChestMediator:ChestSmallClick(sender)
	if not self.isControllable_ then return end
	self.isControllable_ = false
	self:DelayAction()
	local tag = sender:getTag()
	local boxes = checktable(self.activityChestData).boxes or {}
	local data = boxes[tostring(tag)] or {}
	if checkint(data.goodsId) > 0 then
		-- 宝箱存在的情况下
		if data.status == CHEST_STATUS.NOT_OPEN then
			local canUnlock = self:JudageSmallCanUnLock()
			local mediator = require("Game.mediator.activity.chest.ActivityChestSmallMediator").new({
				chestId         = data.goodsId,
				status          = data.status,
				openLeftSeconds = nil,
				placeId         = tag,
				activityId      = self.activityId,
				refreshSgl      = "CHSET_COUNTDOWN_" .. tag ..  data.goodsId,
				canUnlock       = canUnlock,
			})
			app:RegistMediator(mediator)
		elseif data.status == CHEST_STATUS.DO_OPENING then
			if checkint(self.openCountDownsChest[tostring(tag)]) > 0  then
				local mediator = require("Game.mediator.activity.chest.ActivityChestSmallMediator").new({
					chestId         = data.goodsId,
					status          = data.status,
					openLeftSeconds = self.openCountDownsChest[tostring(tag)],
					placeId         = tag,
					activityId      = self.activityId,
					refreshSgl      = "CHSET_COUNTDOWN_" .. tag ..  data.goodsId,
				})
				app:RegistMediator(mediator)
			else
				self:SendSignal(POST.ACTIVITY2_CR_BOX_DRAW_BOX.cmdName , {
					activityId = self.activityId,
					placeId    = tag,
					type       = 1  -- 正常打开
				})
			end
		elseif data.status == CHEST_STATUS.ALREADY_OPEN then
			self:JumpToMediator(self.activityChestData.moduleId)
		end
	else
		self:JumpToMediator(self.activityChestData.moduleId)
	end
end
function ActivityChestMediator:DelayAction(sender)
	local seq =  cc.Sequence:create(
		cc.DelayTime:create(1),
		cc.CallFunc:create(function()
				self.isControllable_ = true
		end)
	)
	local viewComponent = self:GetViewComponent()
	viewComponent.viewData.rightBottomLayout:runAction(seq)
end
function ActivityChestMediator:GetCurrentUnlockSmallChest()
	local boxes = self.activityChestData.boxes
	local count = 0
	for placeId, boxData in pairs(boxes) do
		if checkint(boxData.status) == CHEST_STATUS.DO_OPENING then
			count = count + 1
		end
	end
	return count 
end
function ActivityChestMediator:JudageSmallCanUnLock()
	local count = self:GetCurrentUnlockSmallChest()
	local maxOpenQueueNum = self.activityChestData.maxOpenQueueNum
	return count < maxOpenQueueNum
end
function ActivityChestMediator:JumpToMediator(moduleId)
	local jumpView = jumpViewData[tostring(moduleId)] and  jumpViewData[tostring(moduleId)].jumpView
	local seq = {}
	if jumpView then
		for i = 1 , #jumpView do
			if jumpView[i].gameSence then
				local mediatorName = jumpView[i].mediator
				seq[#seq+1] = cc.CallFunc:create(function()
					---@type Router
					local router = self:GetFacade():RetrieveMediator("Router")
					router:Dispatch({name = ""}, {name = mediatorName})
				end)
			else
				local mediatorName = "Game.mediator." ..jumpView[i].mediator
				seq[#seq+1] = cc.CallFunc:create(function()
					local mediator = require(mediatorName).new()
					app:RegistMediator(mediator)
				end)

			end
			seq[#seq+1] = cc.DelayTime:create(0.4)
		end
	end
	sceneWorld:runAction(
		cc.Sequence:create(seq)
	)
end

function ActivityChestMediator:BackClick(sender)
	if not self.isControllable_ then return end
	self.isControllable_ = false
	self:DelayAction()
	---@type Router
	local router = self:GetFacade():RetrieveMediator("Router")
	router:Dispatch({name = 'HomeMediator'}, {name = 'ActivityMediator', params = {activityId = self.activityId }})
end

function ActivityChestMediator:LookRuleClick(sender)
	app.uiMgr:ShowIntroPopup({title = self.activityName, descr = self.ruleDescr })
end
function ActivityChestMediator:RequestDoubleEffect(singal)
	local body = singal:GetBody()
	local hasPurchased = body.hasPurchased
	self.activityChestData.hasPurchased = hasPurchased
	self.activityChestData.maxOpenQueueNum = checkint(self.activityChestData.maxOpenQueueNum) * 2
end

function ActivityChestMediator:RequestChestHomeActivity(signal)
	self.activityChestData =signal:GetBody()
	local boxes = self.activityChestData.boxes or {}
	---@type ActivityChestScene
	local viewComponent = self:GetViewComponent()
	for i, v in pairs(boxes) do
		if checkint(v.status) == 2 then
			self.openCountDownsChest[i] = v.openLeftSeconds
		end
	end
	self.preTime = os.time()
	--if table.nums(self.openCountDownsChest) > 0  then
		viewComponent:runAction(cc.RepeatForever:create(
			cc.Sequence:create(
				cc.CallFunc:create(function()
					local currentTime = os.time()
					local reduceTime = currentTime - self.preTime
					for i, v in pairs(self.openCountDownsChest or {}) do
						if checkint(self.openCountDownsChest[i]) > 0 then
							local boxes = self.activityChestData.boxes[tostring(i)] or {}
							self.openCountDownsChest[i] = boxes.openLeftSeconds - reduceTime
							-- 更新宝箱的状态
							if checkint(self.openCountDownsChest[i]) <= 0 then
								viewComponent:ChestUpdateBoxTimeLabel(i , __('已解锁') , "#FFFFFF" , "#734441")
								local data = boxes
								viewComponent:ChestUpdateBoxByIndex(i , {
									goodsId         = data.goodsId,
									status          = checkint(data.status),
									openLeftSeconds = 0,
								} )
							else
								local text = CommonUtils.getTimeFormatByType(self.openCountDownsChest[i])
								viewComponent:ChestUpdateBoxTimeLabel(i , text)
							end
							app:DispatchObservers("CHSET_COUNTDOWN_" .. i .. boxes.goodsId , {countdown = self.openCountDownsChest[i]})
						end
					end
				end),
				cc.DelayTime:create(1)
			)
		))
	--end
	for i =1 , 4 do
		if not boxes[tostring(i)] then
			viewComponent:UpdateTimeLabel(i , "")
		elseif boxes[tostring(i)] then
			if checkint(boxes[tostring(i)].status) == CHEST_STATUS.ALREADY_OPEN then
				viewComponent:UpdateTimeLabel(i , "")
			end
			viewComponent:ChestUpdateBoxByIndex(i ,boxes[tostring(i)] , self:JudageSmallCanUnLock())
		end
	end
	viewComponent:UpdateModuleUI(jumpViewData[tostring(self.activityChestData.moduleId)] , self.activityChestData.productName)
	viewComponent:UpdateTitleName(self.activityName)
	viewComponent:UpdatePrograss(self.activityChestData.finalRewardsProgress ,self.activityChestData.finalRewardsTarget )
	viewComponent:UpateChestName(self.activityChestData.name)
	viewComponent:LoadImage(self.activityChestData.view)
end

function ActivityChestMediator:RequestDrawBox(signal)
	local body = signal:GetBody()
	local requestData = body.requestData
	local placeId = requestData.placeId
	local openType = requestData.type
	local rewards = body.rewards
	local rewardsClone = clone(rewards)
	self.openCountDownsChest[tostring(placeId)] = nil
	local boxes                                 = self.activityChestData.boxes[tostring(placeId)]
	boxes.openLeftSeconds  = 0
	boxes.status = CHEST_STATUS.NOT_OPEN
	local goodsId = boxes.goodsId
	boxes.goodsId = nil
	boxes.openLeftSeconds = nil
	local viewComponent = self:GetViewComponent()
	viewComponent:RunSpineAnimation(
		placeId ,
		function()
			local unlock = self:JudageSmallCanUnLock()
			for index , data in pairs(self.activityChestData.boxes[tostring(placeId)]) do
				viewComponent:ChestUpdateBoxByIndex( placeId ,boxes ,unlock)
			end
			viewComponent:UpdateTimeLabel(placeId , "")
			self.activityChestData.finalRewardsProgress = checkint(self.activityChestData.finalRewardsProgress) + 1
			viewComponent:UpdatePrograss(self.activityChestData.finalRewardsProgress , self.activityChestData.finalRewardsTarget)
			app.uiMgr:AddDialog("common.RewardPopup" , { rewards = rewards , addBackpack = false})

		end
	)
	if openType == 2 then -- 消耗材料打开
		local crBoxConf = CONF.GOODS.CR_BOX:GetValue(goodsId)
		local consumeData = {
			goodsId = crBoxConf.openConsume[1].goodsId,
			num = - requestData.num
		}
		rewardsClone[#rewardsClone+1] = consumeData
	end
	CommonUtils.DrawRewards(rewardsClone)
	self:SetCrBoxTips()
end
function ActivityChestMediator:SetCrBoxTips()
	local boxes = self.activityChestData.boxes
	local tip = 0
	for i, v in pairs(boxes) do
		if v.status == CHEST_STATUS.DO_OPENING then
			if checkint(v.openLeftSeconds) == 0 then
				tip = 1
				break
			else
				if tip > 0  then
					-- 倒计时取当前最短开启时间
					if checkint(v.openLeftSeconds) < tip then
						tip = checkint(v.openLeftSeconds)
					end
				else
					tip = checkint(v.openLeftSeconds)
				end
			end
		end
	end
	if tip ~= 1 then
		local finalRewardsHasDrawn = checkint(self.activityChestData.finalRewardsHasDrawn)
		if finalRewardsHasDrawn == 0 then
			if checkint(self.activityChestData.finalRewardsTarget)  <= checkint(self.activityChestData.finalRewardsProgress) then
				tip = 1
			end
		end
	end
	app.badgeMgr:SetActivityTipByActivitiyId(self.activityId , tip)
	if tip  > 1 then
		app.badgeMgr:AddCrBoxTimerByActivityId(self.activityId , tip)
	else
		app.badgeMgr:RemoveCrBoxTimerByActivityId(self.activityId)
	end
end
function ActivityChestMediator:RequestOpenBox(signal)
	local data                                  = signal:GetBody()
	local requestData                           = data.requestData
	local placeId                               = requestData.placeId
	local currentTime                           = os.time()
	local leftSeconds                           = data.leftSeconds
	self.openCountDownsChest[tostring(placeId)] = leftSeconds
	leftSeconds                                 = leftSeconds + currentTime - self.preTime
	local boxes                                 = self.activityChestData.boxes[tostring(placeId)]
	boxes.openLeftSeconds    = leftSeconds
	boxes.status             = CHEST_STATUS.DO_OPENING
	local viewComponent = self:GetViewComponent()
	for index, data in pairs(self.activityChestData.boxes) do
		viewComponent:ChestUpdateBoxByIndex(index ,{
			openLeftSeconds = self.openCountDownsChest[tostring(index)],
			goodsId         = data.goodsId,
			status          = data.status
		} , self:JudageSmallCanUnLock())
	end
	self:SetCrBoxTips()
end
function ActivityChestMediator:RequestFinalRewards(singal)
	-- 最终奖励已经领取
	self.activityChestData.finalRewardsHasDrawn = 1
	self:SetCrBoxTips()
end
function ActivityChestMediator:UpdateTimeLabel(body)
	local timerName = body.timerName
	if self.activityCountDownName == timerName then
		local viewComponent = self:GetViewComponent()
		local countTime = body.countdown
		local timeFormat = CommonUtils.getTimeFormatByType(countTime)
		viewComponent:UpdateTimeLabel(timeFormat)
		if checkint(countTime) == 0 then
			---@type Router
			local router = self:GetFacade():RetrieveMediator("Router")
			router:Dispatch({name = 'HomeMediator'}, {name = 'ActivityMediator'})
		end
	end
end
function ActivityChestMediator:EnterLayer()
	self:SendSignal(POST.ACTIVITY2_CR_BOX.cmdName , {activityId = self.activityId})
end

function ActivityChestMediator:OnRegist()
	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightHide")
	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "allhide")
	regPost(POST.ACTIVITY2_CR_BOX)
	regPost(POST.ACTIVITY2_CR_BOX_DRAW_BOX)
	self:EnterLayer()
end


function ActivityChestMediator:OnUnRegist()
	unregPost(POST.ACTIVITY2_CR_BOX)
	unregPost(POST.ACTIVITY2_CR_BOX_DRAW_BOX)
	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightShow")
	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "hide")
end

return ActivityChestMediator