--[[
抽卡动画mediator
--]]
local Mediator = mvc.Mediator
---@class OrderChestMediator : Mediator
local OrderChestMediator = class("OrderChestMediator", Mediator)
local NAME = "OrderChestMediator"
function OrderChestMediator:ctor( params, viewComponent )
	self.super:ctor(NAME, viewComponent)
	params = params or {}
	self.chestsModuleData = params.chestsModuleData
	self.chestActivityData = {}

end
function OrderChestMediator:InterestSignals()
	local signals = {
		ACTIVITY_CHEST_REWARD_EVENT ,
		POST.ACTIVITY2_CR_BOX.sglName ,
		"CHEST_TITLE_UPDATE_EVENT"
	}
	return signals
end

function OrderChestMediator:ProcessSignal( signal )
	local name = signal:GetName()
	if name == ACTIVITY_CHEST_REWARD_EVENT then
		local body = signal:GetBody()
		self:SetChestDataByActivity(body)
		local isFull = self:CheckChestIsFullByActivity()
		---@type OrderChestView
		local viewComponent = self:GetViewComponent()
		viewComponent:UpdateView(isFull)
	elseif name == "CHEST_TITLE_UPDATE_EVENT" then
		local body = signal:GetBody()
		local posIndex = body.posIndex
		---@type OrderChestView
		local viewComponent = self:GetViewComponent()
		viewComponent:UpdateTitlePos(posIndex)
	elseif name == POST.ACTIVITY2_CR_BOX.sglName then
		local body = signal:GetBody()
		local requestData = body.requestData
		local activityId = requestData.activityId
		self.chestActivityData[tostring(activityId)] = body
		local isFull = self:CheckChestIsFullByActivity()
		---@type OrderChestView
		local viewComponent = self:GetViewComponent()
		viewComponent:UpdateView(isFull)
	end
end

function OrderChestMediator:Initial( key )
	self.super.Initial(self, key)
	local viewComponent = require("Game.views.order.OrderChestView").new()
	self:SetViewComponent(viewComponent)
	---@type OrderMediator
	local mediator = app:RetrieveMediator("OrderMediator")
	---@type OrderView
	local orderView = mediator:GetViewComponent()
	orderView.viewData.bgLayer:addChild(viewComponent,20)
end
function OrderChestMediator:EnterLayer()
	if table.nums(self.chestsModuleData) > 0 then
		for activityId, moduleId in pairs(self.chestsModuleData) do
			self:SendSignal(POST.ACTIVITY2_CR_BOX.cmdName , {activityId = activityId })
		end
	end
end
----=======================----
--@author : xingweihao
--@date : 2020/5/5 10:45 AM
--@Description 设置宝箱的数据
--@params
--@return
---=======================----
function OrderChestMediator:SetChestDataByActivity(goodsData)
	for index, goodData in pairs(goodsData) do
		if self.chestActivityData[tostring(goodsData.activityId)] then
			if not self.chestActivityData[tostring(goodsData.activityId)].boxes  then
				self.chestActivityData[tostring(goodsData.activityId)].boxes = {}
			end
			local boxes = self.chestActivityData[tostring(goodsData.activityId)].boxes
			for i = 1, 4 do
				if (not boxes[tostring(i)]) or checkint(boxes[tostring(i)].goodsId) == 0 then
					boxes[tostring(i)] = {
						goodsId = goodData.goodsId ,
						status = 1
					}
					break 
				end
				if boxes[tostring(i)] and checkint(boxes[tostring(i)].status) == 3 then
					boxes[tostring(i)] = {
						goodsId = goodData.goodsId ,
						status = 1
					}
					break
				end
			end
		end
	end
end
----=======================----
--@author : xingweihao
--@date : 2020/5/5 10:47 AM
--@Description 检测活动的宝箱位置是否填满
--@params
--@return
---=======================----
function OrderChestMediator:CheckChestIsFullByActivity()
	for activityId, crBoxData in pairs(self.chestActivityData) do
		local isFull = true
		local boxes = crBoxData.boxes or {}
		for i = 1, 4 do
			if (not (boxes[tostring(i)]) or
			(checkint(boxes[tostring(i)].status) ~= 3)) or
			(checkint(boxes[tostring(i)].goodsId) == 0)  then
				isFull = false
				break
			end
		end
		if isFull then
			return  isFull
		end
	end
	return false
end
function OrderChestMediator:UnRegsitMediator()
	AppFacade.GetInstance():UnRegsitMediator(NAME)
end
function OrderChestMediator:OnRegist(  )
	-- 开启背景音乐
	regPost(POST.ACTIVITY2_CR_BOX)
	self:EnterLayer()
end


function OrderChestMediator:OnUnRegist(  )
	unregPost(POST.ACTIVITY2_CR_BOX)
end
return OrderChestMediator