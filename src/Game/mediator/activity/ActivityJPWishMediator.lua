--[[
 * author : liuzhipeng
 * descpt : KFC签到活动 Mediator
--]]
local Mediator = mvc.Mediator
local NAME = "ActivityJPWishMediator"
---@class ActivityJPWishMediator : Mediator
local ActivityJPWishMediator = class(NAME, Mediator)
----@type UIManager
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
--[[
@params table{
}
--]]
function ActivityJPWishMediator:ctor(params, viewComponent )
	self.super:ctor(NAME,viewComponent)
	local data = params or {}
	self.detail = data.activityHomeData.rule[i18n.getLang()] or ""
	self.activityId = checkint(data.activityHomeData.activityId) -- 活动Id

end

function ActivityJPWishMediator:InterestSignals()
	local signals = {
		"PRAY_EVENT",
		SGL.NEXT_TIME_DATE ,
		POST.ACTIVITY_PRAY_FRUIT.sglName,
		POST.ACTIVITY_PRAY.sglName,
		POST.ACTIVITY_PRAY_DRAW.sglName,
	}
	return signals
end

function ActivityJPWishMediator:ProcessSignal(signal)
	local name = signal:GetName()
	local body = signal:GetBody()
	if name == POST.ACTIVITY_PRAY.sglName then
		self.data = body
		self.data.fruits = self.data.fruits or {}
		local fruits = self.data.fruits
		for i, v in pairs(fruits) do
			v.recordTime = os.time()
		end
		self.data.recordTime = os.time()

		---@type ActivityJPWishView
		local viewComponent = self:GetViewComponent()
		viewComponent:UpdateGoods(self.data.prayGoodsId ,self.data.prayGoodsNum)
		viewComponent:UpdateLeftTimes(self.data.leftFreeTimes ,self.data.maxFreeTimes)
		viewComponent:AddFruits(fruits)
		self:UpdateTimeLabel()

		local distanceTime = self.data.prayLeftSeconds
		viewComponent:setTimeLabel(distanceTime)

	elseif name == POST.ACTIVITY_PRAY_FRUIT.sglName then
		body.recordTime = os.time()
		---@type ActivityJPWishView
		local viewComponent = self:GetViewComponent()
		if self.data.leftFreeTimes > 0  then
			self.data.leftFreeTimes = self.data.leftFreeTimes  - 1
			viewComponent:UpdateLeftTimes(self.data.leftFreeTimes ,self.data.maxFreeTimes)
		else
			CommonUtils.DrawRewards({{ goodsId = self.data.prayGoodsId , num = -self.data.prayGoodsNum}})
			viewComponent:UpdateGoods(self.data.prayGoodsId ,self.data.prayGoodsNum)
		end
		self.data.fruits[#self.data.fruits+1] =  body
		viewComponent:AddFruits(self.data.fruits)
	elseif name == "PRAY_EVENT" then
		local fruitId = checkint(body.fruitId)
		for i = #self.data.fruits , 1,-1 do
			if checkint(self.data.fruits[i].fruitId)  == checkint(fruitId) then
				if self.data.fruits[i].isRipe then
					---@type ActivityJPWishView
					local viewComponent = self:GetViewComponent()
					viewComponent:SetBgVisible(false)
					self:SendSignal(POST.ACTIVITY_PRAY_DRAW.cmdName,{activityId = self.activityId , fruitId = fruitId})
				else
					---@type ActivityJPWishView
					local viewComponent = self:GetViewComponent()
					if viewComponent:getBgTipTag() == fruitId and viewComponent:GetBgVisible() then
						viewComponent:SetBgVisible(false)
					else
						viewComponent:UpdateBgTips(fruitId)
						viewComponent:SetBgVisible(true)
					end

				end
				break
			end
		end
	elseif name == SGL.NEXT_TIME_DATE then
		self:SendSignal(POST.ACTIVITY_PRAY.cmdName , {activityId = self.activityId})
	elseif name == POST.ACTIVITY_PRAY_DRAW.sglName then

		local fruitId = body.requestData.fruitId
		local rewards = body.rewards
		for i = #self.data.fruits , 1,-1 do
			if checkint(self.data.fruits[i].fruitId)  == checkint(fruitId) then
				--删除数据
				table.remove(self.data.fruits , i)
				---@type ActivityJPWishView
				local viewComponent = self:GetViewComponent()
				-- 删除UI
				viewComponent:RemoveFruitByFruitId(checkint(fruitId))
				break
			end
		end
		app.uiMgr:AddDialog("common.RewardPopup",{rewards = rewards})

	end
end
--setString(self.activityHomeDatas[tostring(activityId)].detail[i18n.getLang()])
function ActivityJPWishMediator:UpdateTimeLabel()
	---@type ActivityJPWishView
	local viewComponent = self:GetViewComponent()
	viewComponent:stopAllActions()
	viewComponent:runAction(
		cc.RepeatForever:create(
			cc.Sequence:create(
				cc.CallFunc:create(
					function()
						local curentTime = os.time()
						for i, v in pairs(self.data.fruits) do
							local fruitId = checkint(v.fruitId)
							if v.isRipe then
							else
								local distanceTime = curentTime - v.recordTime
								if  distanceTime  >=  checkint(v.matureLeftSeconds)  then
									v.isRipe = true
									local fruitsLayout = viewComponent.viewData_.fruitsLayout
									local fruitLayout = fruitsLayout:getChildByTag(fruitId)
									if fruitLayout then
										viewComponent:UpdateFruitIndex(fruitLayout , v ,v.isRipe )
									end
									local tag = viewComponent:getBgTipTag()
									if fruitId == tag then
										viewComponent:SetBgVisible(false)
									end
								else
									v.isRipe = false
								end
								viewComponent:setFruitTimeLabel(fruitId , checkint(v.matureLeftSeconds) - distanceTime)
							end
						end

						local isVisible = viewComponent:GetBgVisible()

						if isVisible then
							viewComponent:UpdateBgTips()
						end

						if self.data.prayLeftSeconds <=  86400 then
							local distanceTime = self.data.prayLeftSeconds -  (curentTime - self.data.recordTime)
							viewComponent:setTimeLabel(distanceTime)
						end
					end
				),
				cc.DelayTime:create(1)
			)
		)
	)
end
function ActivityJPWishMediator:Initial(key)
	self.super.Initial(self, key)
	local viewComponent  = require('Game.views.activity.ActivityJPWishView').new({})
	display.commonUIParams(viewComponent, {ap = cc.p(0.5, 0.5), po = cc.p(display.width * 0.5, display.height * 0.5)})
	self:SetViewComponent(viewComponent)
	viewComponent:getViewData().wishBtn:setOnClickScriptHandler(handler(self, self.WishButtonCallback))
	viewComponent:UpdateRuleLable(self.detail)
end

------------------------------------------
-- handler
--[[
前往按钮点击回调
--]]
function ActivityJPWishMediator:WishButtonCallback(sender)
	local data = self.data
	local leftFreeTimes = data.leftFreeTimes
	local fruits = data.fruits
	local maxFruitNum = checkint(data.maxFruitNum)
	local fruitsNum =  #fruits
	local recordTime = data.recordTime
	local curentTime = os.time()
	local distanceTime =  curentTime - recordTime
	if distanceTime <=  checkint(data.prayLeftSeconds) then
		if  fruitsNum < checkint(maxFruitNum)  then
			if leftFreeTimes > 0   then
				self:SendSignal(POST.ACTIVITY_PRAY_FRUIT.cmdName , {activityId = self.activityId })
			else
				local prayGoodsNum = checkint(data.prayGoodsNum)
				local prayGoodsId = data.prayGoodsId
				local owmerNum = CommonUtils.GetCacheProductNum(prayGoodsId)
				if owmerNum >= prayGoodsNum then
					print("self.activityId  = " , self.activityId )
					self:SendSignal(POST.ACTIVITY_PRAY_FRUIT.cmdName , {activityId = self.activityId })
				else
					uiMgr:ShowInformationTips(__('祈愿道具不足'))
				end
			end
		else
			uiMgr:ShowInformationTips(__('祈愿树上果子已满'))
		end
	else
		uiMgr:ShowInformationTips(__('祈愿时间已结束'))
	end
end

------------------------------------------
function ActivityJPWishMediator:EnterLayer()
	self:SendSignal(POST.ACTIVITY_PRAY.cmdName, {activityId = self.activityId})
end
function ActivityJPWishMediator:OnRegist()
	regPost(POST.ACTIVITY_PRAY_FRUIT)
	regPost(POST.ACTIVITY_PRAY)
	regPost(POST.ACTIVITY_PRAY_DRAW)
	self:EnterLayer()
end
function ActivityJPWishMediator:OnUnRegist()
	unregPost(POST.ACTIVITY_PRAY_FRUIT)
	unregPost(POST.ACTIVITY_PRAY)
	unregPost(POST.ACTIVITY_PRAY_DRAW)
	local viewComponent = self:GetViewComponent()
	if viewComponent and (not tolua.isnull(viewComponent)) then
		viewComponent:stopAllActions()
	end
end
return ActivityJPWishMediator
