--[[
高级米饭心意活动mediator
--]]
local Mediator = mvc.Mediator
local ActivityLevelAdvanceChestMediator = class("ActivityLevelAdvanceChestMediator", Mediator)
local NAME = "activity.levelAdvanceChest.ActivityLevelAdvanceChestMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager('GameManager')
local scheduler = require('cocos.framework.scheduler')

local BOX_STATE = {
	LOCK      = 0,
	NORMAL    = 1,
	PURCHASED = 2,
}

local ANI_STATE = {
	STOP = 0,
	WAIT = 1,
	PLAY = 2
}

function ActivityLevelAdvanceChestMediator:ctor( params, viewComponent )
	self.super:ctor(NAME, viewComponent)
	local datas = params or {}
	self.activityId = checkint(datas.activityId) -- 活动Id
	self.activityData = {} -- 活动home数据
	self.isControllable_ = true
	self.curSelectBoxIndex = 1
	self.isFirstEnter = true

	self.enterAniState = ANI_STATE.STOP
	self.openBoxAniState = ANI_STATE.STOP
end


function ActivityLevelAdvanceChestMediator:InterestSignals()
	local signals = {
		POST.ACTIVITY_LEVEL_ADVANCE_CHEST.sglName,
		SIGNALNAMES.Restaurant_Shop_GetPayOrder_Callback,
		EVENT_APP_STORE_PRODUCTS,
		EVENT_PAY_MONEY_SUCCESS_UI,
		'REFRESH_NOT_CLOSE_GOODS_EVENT'
	}
	return signals
end

function ActivityLevelAdvanceChestMediator:ProcessSignal( signal )
	local name = signal:GetName()
	-- print(name)
	local body = checktable(signal:GetBody())
	if name == POST.ACTIVITY_LEVEL_ADVANCE_CHEST.sglName then
		
		self:initActivityData(body.chests or {})

		self:GetViewComponent():updateList(self.activityData, self.curSelectBoxIndex)
		
		self:refreshBoxRewardLayer(self.activityData[self.curSelectBoxIndex], not self.isFirstEnter)
		if self.isFirstEnter then
			if self.enterAniState == ANI_STATE.PLAY then
				self.openBoxAniState = ANI_STATE.WAIT
			elseif self.enterAniState == ANI_STATE.STOP then
				local scene = uiMgr:GetCurrentScene()
				scene:AddViewForNoTouch()
				self.isControllable_ = false
				self:GetViewComponent():showUIAction(function ()
					scene:RemoveViewForNoTouch()
					self.isControllable_ = true
				end, true)
			end
			if isElexSdk() then
				local t = {}
				for name,val in pairs(body.chests or {}) do
					if val.channelProductId then
						table.insert(t, val.channelProductId)
					end
				end
				require('root.AppSDK').GetInstance():QueryProducts(t)
			end
			self.isFirstEnter = false
		end

	elseif name == SIGNALNAMES.Restaurant_Shop_GetPayOrder_Callback then
		local requestData = body.requestData
		if requestData.name ~= NAME then return end

		if body.orderNo then
			if device.platform == 'android' or device.platform == 'ios' then
				local data = self.activityData[self.curSelectBoxIndex]
				local chestDatas = data.chestDatas or {}
				local tag = requestData.tag
				local chestData = chestDatas[tag]
				local AppSDK = require('root.AppSDK')
				AppSDK.GetInstance():InvokePay({amount = chestData.price, property = body.orderNo, goodsId = tostring(chestData.channelProductId), goodsName = __('幻晶石'), quantifier = __('个'), price = 0.1, count = 1})
			end
		end
	elseif name == EVENT_PAY_MONEY_SUCCESS_UI then
		if checkint(body.type) == PAY_TYPE.PT_LEVEL_ADVANCE_CHEST then
            self:enterLayer()
        end
	elseif name == 'REFRESH_NOT_CLOSE_GOODS_EVENT' then 
	elseif name == EVENT_APP_STORE_PRODUCTS then
		self:enterLayer()
	end
end

function ActivityLevelAdvanceChestMediator:Initial( key )
    self.super.Initial(self, key)
    
	local viewComponent = require( 'Game.views.activity.levelAdvanceChest.ActivityLevelAdvanceChestView' ).new()
	display.commonUIParams(viewComponent, {ap = display.CENTER, po = display.center})
	self:SetViewComponent(viewComponent)
	
	self.viewData = viewComponent:getViewData()
    self:initView()

end

function ActivityLevelAdvanceChestMediator:initView()
	local viewData = self:getViewData()
	local gridView = viewData.gridView
	gridView:setDataSourceAdapterScriptHandler(handler(self, self.onDataSourceAdapter))

	local boxRewardLayers = viewData.boxRewardLayers
	for i, boxRewardLayer in ipairs(boxRewardLayers) do
		display.commonUIParams(boxRewardLayer.viewData.btn, {cb = handler(self, self.onClickBuyChestAction)})
	end

	local ruleBtn = viewData.ruleBtn
	display.commonUIParams(ruleBtn, {cb = handler(self, self.onClickRuleBtnAction)})

	self.enterAniState = ANI_STATE.PLAY
	
	local scene = uiMgr:GetCurrentScene()
	scene:AddViewForNoTouch()
	self.isControllable_ = false
	self:GetViewComponent():showEnterAction(function ()
		self.enterAniState = ANI_STATE.STOP
		if self.openBoxAniState == ANI_STATE.WAIT then
			self:GetViewComponent():showUIAction(function ()
				scene:RemoveViewForNoTouch()
				self.isControllable_ = true
			end, true)
		end
	end)

end

function ActivityLevelAdvanceChestMediator:initActivityData(data)
	local activityData = {}
	if data == nil then return activityData end
	
	for i, chestData in ipairs(data) do
		local groupId = checkint(chestData.groupId)
		activityData[groupId] = activityData[groupId] or {}

		activityData[groupId].chestDatas = activityData[groupId].chestDatas or {}
		table.insert(activityData[groupId].chestDatas, chestData)
	end

	local curGroupIndex = 1
	local curSelectIndex = 0
	local curLv = gameMgr:GetUserInfo().level
	for i, data in ipairs(activityData) do
		local chestDatas = data.chestDatas
		local openLevel  = nil
		local goupHasPurchased = 0
		local boxState = BOX_STATE.LOCK
		for i, chestData in ipairs(chestDatas) do
			if openLevel == nil then
				openLevel = checkint(chestData.openLevel)
			end
			local hasPurchased = checkint(chestData.hasPurchased)
			if hasPurchased > 0 then
				goupHasPurchased = hasPurchased
			end

		end

		if openLevel <= curLv then
			if curGroupIndex ~= i then
				curGroupIndex = math.max(curGroupIndex, i)
			end
			if goupHasPurchased <= 0 then
				boxState = BOX_STATE.NORMAL
				curSelectIndex = math.max(curSelectIndex, i)
			else
				boxState = BOX_STATE.PURCHASED
			end
		end
		data.boxState = boxState
		data.openLevel = openLevel
		data.goupHasPurchased = goupHasPurchased
	end

	if curSelectIndex == 0 then
		curSelectIndex = curGroupIndex
	end
	self.curSelectBoxIndex = curSelectIndex
	-- logInfo.add(5, tableToString(activityData))
	self.activityData = activityData
end

--[[
刷新活动页面
--]]
function ActivityLevelAdvanceChestMediator:refreshView()

end

--[[
刷新手提箱奖励
@params data 手提箱数据
--]]
function ActivityLevelAdvanceChestMediator:refreshBoxRewardLayer(data, isShow)
	local viewData = self:getViewData()
	local boxRewardLayers = viewData.boxRewardLayers
	local chestDatas = data.chestDatas or {}
	local boxRewardLayer = nil
	for i, boxRewardData in ipairs(chestDatas) do
		if checkint(boxRewardData.luxury) == 1 then
			boxRewardLayer = boxRewardLayers[1]
		else
			boxRewardLayer = boxRewardLayers[2]
		end
		boxRewardLayer:setVisible(checkbool(isShow))
		boxRewardLayer.viewData.btn:setTag(i)
		self:GetViewComponent():updateBoxRewardLayer(boxRewardLayer, boxRewardData)
	end
end


function ActivityLevelAdvanceChestMediator:enterLayer()
	self:SendSignal(POST.ACTIVITY_LEVEL_ADVANCE_CHEST.cmdName, {activityId = self.activityId})
end

function ActivityLevelAdvanceChestMediator:onDataSourceAdapter(p_convertview, idx)
	local pCell = p_convertview
    local index = idx + 1

	if pCell == nil then
		local gridView = self:getViewData().gridView
		pCell = self:GetViewComponent():CreateCell(gridView:getSizeOfCell())
		display.commonUIParams(pCell.viewData.boxImg, {cb = handler(self, self.onClickBoxBtnAction)})
	end
	local data = self.activityData[index]
	if data then
		self:GetViewComponent():updateCell(pCell.viewData, data, self.curSelectBoxIndex == index)
		pCell.viewData.boxImg:setTag(index)
	end
	return pCell
end

function ActivityLevelAdvanceChestMediator:onClickBoxBtnAction(sender)
	local index = sender:getTag()
	if not self.isControllable_ then return end
	if self.curSelectBoxIndex == index then
		return
	end
	-- logInfo.add(5, "onClickBoxBtnAction -->>>")
	local data = self.activityData[index]
	if data.boxState == BOX_STATE.LOCK then
		uiMgr:ShowInformationTips(__('等级未达到'))
		return
	end

	self.isControllable_ = false

	self:refreshBoxRewardLayer(data)
	
	local scene = uiMgr:GetCurrentScene()
	scene:AddViewForNoTouch()
	local gridView = self:getViewData().gridView
	self:GetViewComponent():showUIAction(function ()
		scene:RemoveViewForNoTouch()
		self.isControllable_ = true
		
	end)
	local cell = gridView:cellAtIndex(index - 1)
	if cell then
		self:GetViewComponent():updateCellState(cell.viewData, data.boxState, true)
	end
	
	local oldCell = gridView:cellAtIndex(self.curSelectBoxIndex - 1)
	if oldCell then
		local oldData = self.activityData[self.curSelectBoxIndex]
		self:GetViewComponent():updateCellState(oldCell.viewData, oldData.boxState, false)
	end
	
	self.curSelectBoxIndex = index
	
	
end

function ActivityLevelAdvanceChestMediator:onClickBuyChestAction(sender)
	local tag = sender:getTag()
	local data = self.activityData[self.curSelectBoxIndex] or {}
	
	if data.boxState == BOX_STATE.LOCK then
		uiMgr:ShowInformationTips(__('等级未达到'))
		return
	elseif data.boxState == BOX_STATE.PURCHASED then
		uiMgr:ShowInformationTips(__('你已选购了另一个手提箱，不能重复购买'))
		return
	end
	
	local chestDatas = data.chestDatas or {}
	local chestData = chestDatas[tag]
	if chestData ~= nil then
		local productId = chestData.productId
		self:SendSignal(COMMANDS.COMMANDS_All_Shop_GetPayOrder,{productId = productId, name = NAME, tag = tag})
	end

end

function ActivityLevelAdvanceChestMediator:onClickRuleBtnAction(sender)
	local descr = __('1.威士忌的手提箱作为长期活动，永久开放。\n 2.游戏等级达到45级后，解锁威士忌的手提箱。每5级解锁一次，每次都会出现2个手提箱：破旧手提箱和复古手提箱，御侍只能选择其中1个购买。（购买威士忌的手提箱，也可以享受首充奖励的福利）')
	uiMgr:ShowIntroPopup({title = __('活动规则说明'), descr = descr})
end

function ActivityLevelAdvanceChestMediator:getViewData()
	return self.viewData
end

function ActivityLevelAdvanceChestMediator:CleanupView()
	local viewComponent = self:GetViewComponent()
	local scene = uiMgr:GetCurrentScene()
    if scene and viewComponent and not tolua.isnull(viewComponent) then
		scene:RemoveGameLayer(viewComponent)
		scene:RemoveViewForNoTouch()
    end
end

function ActivityLevelAdvanceChestMediator:OnRegist(  )
	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "show")
	regPost(POST.ACTIVITY_LEVEL_ADVANCE_CHEST)
	self:enterLayer()
end

function ActivityLevelAdvanceChestMediator:OnUnRegist(  )
	unregPost(POST.ACTIVITY_LEVEL_ADVANCE_CHEST)
end


return ActivityLevelAdvanceChestMediator