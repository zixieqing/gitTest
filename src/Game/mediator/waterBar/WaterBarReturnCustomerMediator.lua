--[[
 * author : kaishiqi
 * descpt : 水吧 - 信息中介者
]]
---@class WaterBarReturnCustomerMediator:Mediator
local WaterBarReturnCustomerMediator = class('WaterBarReturnCustomerMediator', mvc.Mediator)
local NAME = "WaterBarReturnCustomerMediator"
local waterBarMgr = app.waterBarMgr
local BAR_RETURN_EVENTS = {
	SELECT_FORMULA_EVENT = "SELECT_FORMULA_EVENT",
	SELECT_SORT_TYPE_EVENT = "SELECT_SORT_TYPE_EVENT",
}
local CustomerFrequencyPoint = CONF.BAR.CUSTOMER_FREQUENCY_POINT:GetAll() 
function WaterBarReturnCustomerMediator:ctor(params, viewComponent)
	self.super.ctor(self, NAME, viewComponent)
	self.activityId = app.activityMgr:GetActivityIdByType(ACTIVITY_TYPE.BAR_VISITOR)
	self.activityCountDownName = nil
	self.leftSconeds = 0

	if checkint(self.activityId) > 0 then
		self.activityCountDownName =  "COUNT_DOWN_TAG_VISTOR"
		local timerInfo = app.timerMgr:RetriveTimer(self.activityCountDownName)
		if timerInfo then
			self.leftSconeds = checkint(timerInfo.countdown)
		end
	end
	self.customerListData = {}  -- 顾客列表
	self.customersRewardsIdList = {}
	self.selectCustomerType = 2
	self.preCellIndex = 1
	self.selectFormulaId = nil
	-- 活动顾客
	self.customers = self:GetCurrentAndActivityCustomers()
	self.activitysIndex = {} --活动客人的index
end
-------------------------------------------------
-- inheritance

function WaterBarReturnCustomerMediator:InterestSignals()
	local event = {
		BAR_RETURN_EVENTS.SELECT_FORMULA_EVENT ,
		BAR_RETURN_EVENTS.SELECT_SORT_TYPE_EVENT ,
		POST.WATER_BAR_CUSTOMER_DRAW.sglName ,
	}
	if checkint(self.activityId) > 0 then
		event[#event+1] = COUNT_DOWN_ACTION
	end
	return event
end

function WaterBarReturnCustomerMediator:ProcessSignal(signal)
	local name = signal:GetName()
	local body = signal:GetBody()
	if name == BAR_RETURN_EVENTS.SELECT_FORMULA_EVENT then
		local formulaId = body.formulaId
		local formulaData = waterBarMgr:getFormulaData(formulaId)
		local drinkId = nil
		if formulaData then
			local highStar =  app.waterBarMgr:getFormulaMaxStar(formulaId)
			local formulaConf = CONF.BAR.FORMULA:GetValue(formulaId)
			local drinks = formulaConf.drinks
			drinkId = drinks[highStar+1]
		end
		---@type WaterBarReturnCustomerView
		local viewComponent = self:GetViewComponent()

		viewComponent:UpdateView(drinkId)
		viewComponent:UpdateSelectDrinkNode(formulaId)
		self.selectFormulaId = formulaId
	elseif name == BAR_RETURN_EVENTS.SELECT_SORT_TYPE_EVENT then
		local viewComponent = self:GetViewComponent()
		viewComponent:SortBordIsVisible(false)
		if  checkint(body.sortType) == self.selectCustomerType then
			return
		end
		self.selectCustomerType = checkint(body.sortType)
		local text = nil
		if self.selectCustomerType == 1 then -- 全部
			text = __('全部')
		else
			text = __('今日客人')
		end
		viewComponent.viewData.selectKindsBtn:setChecked(false)
		display.commonLabelParams(viewComponent.viewData.selectKindsBtnLabel ,{text = text})
		self:ReloadGrideView()
		self:DealWithCellIndex(self.preCellIndex)
	elseif name == COUNT_DOWN_ACTION  then
		local timerName = body.timerName
		if self.activityCountDownName == timerName then
			self.leftSconeds = body.countdown
			if self.leftSconeds > 0  then
				local viewComponent = self:GetViewComponent()
				local viewData = viewComponent.viewData
				local gridView = viewData.gridView
				if gridView and (not tolua.isnull(gridView)) then
					for i = 1, #self.activitysIndex do
						local cell = gridView:cellAtIndex( self.activitysIndex[i] - 1)
						if cell and (not tolua.isnull(cell)) then
							self:OnDatSources(cell , self.activitysIndex[i] - 1)
						end
					end
				end
			end
		end
	elseif name == POST.WATER_BAR_CUSTOMER_DRAW.sglName then
		local requestData = body.requestData
		local index = requestData.index
		local rewardId = requestData.rewardId
		local customerId = requestData.customerId
		waterBarMgr:UpdateFrequencyPointRewardsByCustomerId(customerId, rewardId)
		app.uiMgr:AddDialog("common.RewardPopup" , {rewards = body.rewards })
		local viewComponent = self:GetViewComponent()
		local viewData = viewComponent.viewData
		local cell =  viewData.gridView:cellAtIndex(index -1)
		if cell and not tolua.isnull(cell) then
			local cellViewData = cell.viewData
			for i, rewardValue in pairs(self.customersRewardsIdList[tostring(customerId)]) do
				if rewardId == checkint(rewardValue) then
					local goodNode = cellViewData.goodNodes[i]
					local lockImage = goodNode:getChildByName("lockImage")
					local iconImage = goodNode:getChildByName("iconImage")
					local arrowImag = goodNode:getChildByName("arrowImag")
					iconImage:setVisible(false)
					arrowImag:setVisible(true)
					lockImage:setVisible(true)
				end
			end
		end
		app.badgeMgr:CheckHasFrequencyPointRewards()
	end
end

function WaterBarReturnCustomerMediator:Initial(key)
	self.super.Initial(self, key)
	---@type WaterBarReturnCustomerView
	local viewComponent = require("Game.views.waterBar.WaterBarReturnCustomerView").new()
	viewComponent:setPosition(display.center)
	self:SetViewComponent(viewComponent)
	app.uiMgr:GetCurrentScene():AddDialog(viewComponent)

	local viewData = viewComponent.viewData
	display.commonUIParams(viewData.closeLayer , {animate = false,  cb = function()
		self:GetFacade():UnRegistMediator(NAME)
	end })
	display.commonUIParams(viewData.makeBtn , {cb = handler(self , self.MakeClick) })
	display.commonUIParams(viewData.selectKindsBtn , {animate =false,  cb = handler(self , self.KindClick) })
	self:ReloadGrideView()
	local customerData = self.customerListData[self.preCellIndex] or {}
	viewComponent:UpdateDrinksKindLayout(customerData.customerId)
end

function WaterBarReturnCustomerMediator:ReloadGrideView()
	self.customerListData = self:GetCustomerCustomerListData()
	self.activitysIndex = self:GetActivityCustomersIndex(self.customerListData)
	self.preCellIndex = 1
	local viewComponent = self:GetViewComponent()
	local viewData = viewComponent.viewData
	viewData.gridView:setDataSourceAdapterScriptHandler(handler(self, self.OnDatSources))
	viewData.gridView:setCountOfCell(#self.customerListData)
	viewData.gridView:reloadData()
end

function WaterBarReturnCustomerMediator:GetCurrentAndActivityCustomers()
	local customerConf = CONF.BAR.CUSTOMER:GetAll()
	local homedata = app.waterBarMgr:getHomeData()
	local currentScheduleCustomers = homedata.currentScheduleCustomers or {}
	local customersCA = {
		activity = {},
		current = {} ,
	}
	--获取活动飨灵和今日飨灵
	for i, v in pairs(currentScheduleCustomers) do
		local customerId = checkint(v)
		local oneConf = customerConf[tostring(customerId)]
		if self.leftSconeds > 0 and checkint(oneConf.activity) > 0 then
			customersCA.activity[tostring(customerId)] = customerId
		else
			customersCA.current[tostring(customerId)] = customerId
		end
	end
	return customersCA
end
function WaterBarReturnCustomerMediator:GetCustomerCustomerListData()
	local homedata = app.waterBarMgr:getHomeData()
	local customers = homedata.customers or {}
	local ownCustomers = {}
	local activityCustomers = {}
	local currentCustomers = {}
	local notCurrentCustomers = {}
	local customerConf = CONF.BAR.CUSTOMER:GetAll()

	local customersKey = {}
	for index , customer in pairs(customers) do
		customersKey[tostring(customer.customerId)] = customer
		ownCustomers[tostring(customer.customerId)] = customer.customerId
	end
	for i, customerId in pairs(self.customers.activity) do
		if checkint(customerConf[tostring(customerId)].openBarLevel) >= checkint(app.waterBarMgr.level) then
			if customersKey[tostring(customerId)] then
				activityCustomers[#activityCustomers+1] = customersKey[tostring(customerId)]
			else
				activityCustomers[#activityCustomers+1]  = {
					customerId = customerId ,
					frequencyPoint = 0 ,
					frequencyPointRewards = {}
				}
			end
		end
		ownCustomers[tostring(customerId)] = customerId
	end
	for i, customerId in pairs(self.customers.current) do
		if checkint(customerConf[tostring(customerId)].openBarLevel) >= checkint(app.waterBarMgr.level) then
			if customersKey[tostring(customerId)] then
				currentCustomers[#currentCustomers+1] = customersKey[tostring(customerId)]
			else
				currentCustomers[#currentCustomers+1]  = {
					customerId = customerId ,
					frequencyPoint = 0 ,
					frequencyPointRewards = {}
				}
			end
		end
		ownCustomers[tostring(customerId)] = customerId
	end
	if self.selectCustomerType == 1 then
		for customerId, customerOneConf in pairs(customerConf) do
			if checkint(customerOneConf.openBarLevel) >=  checkint(app.waterBarMgr.level) then
				if not ownCustomers[tostring(customerId)] then
					notCurrentCustomers[#notCurrentCustomers+1] = {
						customerId = customerId ,
						frequencyPoint = 0 ,
						frequencyPointRewards = {}
					}
				else
					if not (self.customers.activity[tostring(customerId)]
							or self.customers.current[tostring(customerId)] ) and
							customersKey[tostring(customerId)] then
						notCurrentCustomers[#notCurrentCustomers+1] = customersKey[tostring(customerId)]
					end
				end
			end
		end
	end
	-- 三种飨灵按照品质排序
	self:SortCoustomerIdByQuality(activityCustomers)
	self:SortCoustomerIdByQuality(currentCustomers)
	self:SortCoustomerIdByQuality(notCurrentCustomers)
	table.insertto(currentCustomers , notCurrentCustomers)
	local drawCustomers = {}
	for i = #currentCustomers ,1 , -1 do
		local customer = currentCustomers[i]
		if waterBarMgr:JudgeCustomerDrawRewardsByCustomerId(customer.customerId) then
			drawCustomers[#drawCustomers+1] = table.remove(currentCustomers , i)
		end
	end
	table.insertto(activityCustomers , currentCustomers)
	table.insertto(drawCustomers , activityCustomers)
	return drawCustomers
end

function WaterBarReturnCustomerMediator:SortCoustomerIdByQuality(coustomerData)
	if #coustomerData == 0  then return end
	local cardConf = CommonUtils.GetConfigAllMess('card' , 'card')
	local customerConf = CONF.BAR.CUSTOMER:GetAll()
	table.sort(coustomerData , function(aCustomer , bCustomer)
		local aCardId = customerConf[tostring(aCustomer.customerId)].cardId
		local bCardId = customerConf[tostring(bCustomer.customerId)].cardId
		local aQuality = cardConf[tostring(aCardId)].qualityId
		local bQuality = cardConf[tostring(bCardId)].qualityId
		if checkint(aQuality)  == checkint(bQuality) then
			return checkint(aCardId) > checkint(bCardId)
		else
			return checkint(aQuality) > checkint(bQuality)
		end
	end)
end

function WaterBarReturnCustomerMediator:GetActivityCustomersIndex(customers)
	local customerConf = CONF.BAR.CUSTOMER:GetAll()
	local activitysIndex = {}
	for index, customer in pairs(customers) do
		if checkint(customerConf[tostring(customer.customerId)].activity) == 1 then
			activitysIndex[#activitysIndex+1] = index
		end
	end
	return activitysIndex
end


----=======================----
--@author : xingweihao
--@date : 2020/3/26 11:08 AM
--@Description 根据玩家id 获取
--@params
--@return
---=======================----
function WaterBarReturnCustomerMediator:GetRewardKeysListByCustomerId(customerId)
	local customerRewardsConf = CustomerFrequencyPoint[tostring(customerId)] or {}
	local rewardIdkeys = table.keys(customerRewardsConf)
	if #rewardIdkeys == 0 then return {} end
	table.sort(rewardIdkeys , function(a, b )
		if checkint(a) < checkint(b) then
			return true
		end
		return false
	end)
	return rewardIdkeys or {}
end

function WaterBarReturnCustomerMediator:OnDatSources(cell , idx)
	local pcell = cell 
	local index = idx +1
	local CustomerConf = CONF.BAR.CUSTOMER:GetAll()
	---@type WaterBarReturnCustomerView
	local viewComponent = self:GetViewComponent()
	if not pcell then
		pcell = viewComponent:CreateCell()
	end
	local data = self.customerListData[index]
	local viewData = pcell.viewData
	local cellSelectImage = viewData.cellSelectImage
	local cardHeadNode = viewData.cardHeadNode
	local customerId = tostring(data.customerId)
	viewData.clickImage:setTag(index)
	display.commonUIParams(viewData.clickImage , {animate = false ,  cb = handler(self, self.CellIndex)})
	if self.preCellIndex == index then
		viewData.clickImage:setVisible(false)
		cellSelectImage:setTexture(_res(string.format('ui/waterBar/returnCustom/bar_bg_task_working_3')))
	else
		viewData.clickImage:setVisible(true)
		cellSelectImage:setTexture(_res(string.format('ui/waterBar/returnCustom/bar_bg_task_working_1')))
	end
	cardHeadNode:RefreshUI({
		cardData = {
			cardId = CustomerConf[customerId].cardId
		}
	})
	viewData.prograssLayout:setVisible(false)
	viewData.prograssLabel:setVisible(false)
	viewData.decrLabel:setVisible(false)
	viewData.activityTimeImage:setVisible(false)
	display.commonLabelParams(viewData.cardName , fontWithColor(14 , { fontSize = 28 , color = "#ba5c5c" ,  text = CustomerConf[customerId].name , outline = false  }))
	if not self.customers.activity[customerId] then
		-- 首先是重置掉进度的奖励显示
		if not self.customersRewardsIdList[customerId] then
			self.customersRewardsIdList[customerId] =  self:GetRewardKeysListByCustomerId(customerId)
		end
		local rewardsKeyList = self.customersRewardsIdList[customerId]
		local isAllRewards = false
		local maxValue = checkint(rewardsKeyList[#rewardsKeyList])
		if checkint(data.frequencyPoint) >= maxValue  then
			-- 熟客值满以后，分为两种情况 ， 一种是熟客值满奖励已经 全部领取 ， 熟客值满 奖励为领取
			for i, aId in pairs(rewardsKeyList) do
				isAllRewards = false
				data.frequencyPointRewards = data.frequencyPointRewards or {}
				for j, bId  in pairs(data.frequencyPointRewards) do
					if checkint(aId) == checkint(bId) then
						isAllRewards = true
						break 
					end
				end
				if not isAllRewards then break end
			end
		end
		-- 已经领取过全部奖励
		if isAllRewards then
			viewData.decrLabel:setVisible(true)
			viewData.prograssLabel:setVisible(true)
			display.reloadRichLabel(viewData.decrLabel , {
				c = { {fontSize = 20 , color = "#614030" , text = __('熟客值满后，继续招待该飨灵几率获得礼包') } }
			})
			display.reloadRichLabel(viewData.prograssLabel , {
				c = { fontWithColor( 14 , { fontSize = 22 , color = "#ba5c5c" , text = "MAX" }) }
			})
		else
			viewData.prograssLayout:setVisible(true)
			viewData.prograssLabel:setVisible(true)
			if maxValue == 0 then
				viewData.prograssLabel:setVisible(false)
				viewData.prograssBar:setVisible(false)
			else
				viewData.prograssBar:setVisible(true)
				viewData.prograssBar:setMaxValue(maxValue)
				viewData.prograssBar:setValue(checkint(data.frequencyPoint) > maxValue and maxValue or checkint(data.frequencyPoint))
			end

			display.reloadRichLabel(viewData.prograssLabel , {
				c = {
					fontWithColor( 14 , { fontSize = 22 , color = "#5b3c25" , text = data.frequencyPoint }),
					fontWithColor( 14 , { fontSize = 22 , color = "#ba5c5c" , text = "/" ..maxValue })
				}
			})
			local prograssBarSize = viewData.prograssBarSize
			for i = 1 , 6 do
				viewData.goodNodes[i]:setVisible(false)
				viewData.prograssLabels[i]:setVisible(false)
				viewData.lines[i]:setVisible(false)
			end
			local count = #rewardsKeyList
			for i = 1 , count do
				if i == count then
					viewData.lines[i]:setVisible(false)
				else
					viewData.lines[i]:setVisible(true)
				end
				viewData.goodNodes[i]:setVisible(true)
				viewData.goodNodes[i]:setTag(checkint(rewardsKeyList[i]))
				display.commonUIParams(viewData.goodNodes[i] , { animate = false , cb = handler(self, self.GoodClick)})
				viewData.prograssLabels[i]:setVisible(true)
				local rewardId = checkint(rewardsKeyList[i])
				local status = 0
				local posX = prograssBarSize.width * (rewardsKeyList[i]/maxValue)
				viewData.lines[i]:setPositionX(posX+15)
				viewData.goodNodes[i]:setPositionX(posX+15)
				local lockImage = viewData.goodNodes[i]:getChildByName("lockImage")
				local iconImage = viewData.goodNodes[i]:getChildByName("iconImage")
				local arrowImag = viewData.goodNodes[i]:getChildByName("arrowImag")
				viewData.prograssLabels[i]:setString(rewardsKeyList[i])
				viewData.prograssLabels[i]:setPositionX(posX+15)
				lockImage:setVisible(false)
				iconImage:setVisible(false)
				arrowImag:setVisible(false)
				if checkint(data.frequencyPoint) > rewardId then
					status = 1 
				end

				for j = 1 , #data.frequencyPointRewards do
					if checkint(rewardsKeyList[i]) == checkint(data.frequencyPointRewards[j]) then
						status = 2
						break
					end
				end
				if status == 1 then
					iconImage:setVisible(true)
				elseif status == 2 then
					lockImage:setVisible(true)
					arrowImag:setVisible(true)
				end
				viewData.goodNodes[i]:RefreshSelf(CustomerFrequencyPoint[customerId][tostring(rewardId)].rewards[1])
			end
		end
		return pcell
	end
	if self.customers.activity[customerId] then
		viewData.decrLabel:setVisible(true)
		viewData.activityTimeImage:setVisible(true)
		display.reloadRichLabel(viewData.decrLabel , {
			c = { {fontSize = 20 , color = "#ee4e29" , text = __('活动期间内，招待该飨灵有几率获得碎片') } }
		})
		display.reloadRichLabel(viewData.activityTimeLabel , {
			c = {
				fontWithColor(14 , {text =__('活动倒计时：') ,fontSize = 22 , color ="#614030"}),
				fontWithColor(14 , {text = CommonUtils.getTimeFormatByType(self.leftSconeds)  ,fontSize = 22 , color ="#614030"})
			}
		})
	end
	return pcell
end

function WaterBarReturnCustomerMediator:GoodClick(sender)
	local rewardId = sender:getTag()
	local cell = sender:getParent():getParent():getParent()
	local clickImage = cell.viewData.clickImage
	local index = clickImage:getTag()
	local customerData = self.customerListData[index]
	local customerId = tostring(customerData.customerId)
	if self.customers.activity[customerId] then
		app.uiMgr:ShowInformationTips(__('当前顾客在活动中，不可领取奖励'))
		return
	end
	if checkint(customerData.frequencyPoint) < rewardId then
		app.uiMgr:ShowInformationTips(__('熟客值不足，不能领取奖励'))
		return
	end
	for i, v in pairs(customerData.frequencyPointRewards) do
		if checkint(v) == rewardId then
			app.uiMgr:ShowInformationTips(__('奖励已经领取'))
			return
		end
	end
	self:SendSignal(POST.WATER_BAR_CUSTOMER_DRAW.cmdName , {customerId = customerId , rewardId = rewardId , index = index })
end
function WaterBarReturnCustomerMediator:MakeClick(sender)
	if waterBarMgr:getHomeStatus() == 1 then
		app.uiMgr:ShowInformationTips(__('正在营业中，不可以制作'))
		return
	end
	local hasFormula = waterBarMgr:hasFormula(self.selectFormulaId)
	local formulaConf = CONF.BAR.FORMULA:GetValue(self.selectFormulaId)
	if not hasFormula then
		if  checkint(formulaConf.openBarLevel) >  waterBarMgr:getBarLevel() then
			app.uiMgr:ShowInformationTips(__('酒吧等级不足，配方暂未解锁'))
			return
		end
		if checkint(formulaConf.hide) == 1 then
			local meditaor = require("Game.mediator.waterBar.WaterBarDeployFormulaMediator").new({
				developWay = 1,
				fromData = {
					mediatorName = "waterBar.WaterBarReturnCustomerMediator" ,
				}
			})
			app:RegistMediator(meditaor)
			app:UnRegistMediator(NAME)
			return
		end
	else
		if  checkint(formulaConf.openBarLevel) >  waterBarMgr:getBarLevel() then
			app.uiMgr:ShowInformationTips(__('酒吧等级不足，不能制作该配方'))
			return
		end
	end
	local meditaor = require("Game.mediator.waterBar.WaterBarDeployFormulaMediator").new({
		developWay = 2 ,
		formulaId = self.selectFormulaId,
		fromData = {
			mediatorName = "waterBar.WaterBarReturnCustomerMediator" ,
		}
	})
	app:RegistMediator(meditaor)
	app:UnRegistMediator(NAME)
end
function WaterBarReturnCustomerMediator:KindClick(sender)
	---@type WaterBarReturnCustomerView
	local isChecked = sender:isChecked()
	sender:setChecked(isChecked)
	local viewComponent = self:GetViewComponent()
	viewComponent:UpdateSortLayout(self.selectCustomerType)
	viewComponent:SortBordIsVisible(isChecked)
end

-- 选择配方的回调事件
function WaterBarReturnCustomerMediator:CellIndex(sender)
	PlayAudioByClickNormal()
	local index = sender:getTag()
	if self.preCellIndex == index then return end
	self:DealWithCellIndex(index)
end

function WaterBarReturnCustomerMediator:DealWithCellIndex(index)
	if #self.customerListData < self.preCellIndex  then return end
	---@type WaterBarReturnCustomerView
	local viewComponent = self:GetViewComponent()
	local viewData = viewComponent.viewData
	local gridView = viewData.gridView
	local preIndex = self.preCellIndex
	local preCell = gridView:cellAtIndex(preIndex - 1)
	if preCell and (not tolua.isnull(preCell)) then
		local cellViewData = preCell.viewData
		local cellSelectImage = cellViewData.cellSelectImage
		cellSelectImage:setTexture(_res(string.format('ui/waterBar/returnCustom/bar_bg_task_working_1')))
		local clickImage = cellViewData.clickImage
		clickImage:setVisible(true)
	end
	self.preCellIndex = index
	local cell = gridView:cellAtIndex(self.preCellIndex - 1)
	if cell and (not tolua.isnull(cell)) then
		local cellViewData = cell.viewData
		local cellSelectImage = cellViewData.cellSelectImage
		cellSelectImage:setTexture(_res(string.format('ui/waterBar/returnCustom/bar_bg_task_working_3')))
		cellSelectImage:setVisible(true)
		local clickImage = cellViewData.clickImage
		clickImage:setVisible(false)
	end
	local coustomerData = self.customerListData[self.preCellIndex]
	local customerConf = CONF.BAR.CUSTOMER:GetValue(coustomerData.customerId)
	if self.customerListData[self.preCellIndex] then
		viewComponent:UpdateDrinksKindLayout(self.customerListData[self.preCellIndex].customerId)
	end
	local formulas  = customerConf.formula
	local formulaId = formulas[1]
	for i, id in pairs(formulas) do
		local highStar = waterBarMgr:getFormulaMaxStar(id)
		if highStar >= 0 then
			formulaId = id
			break
		end
	end
	if formulaId then
		app:DispatchObservers(BAR_RETURN_EVENTS.SELECT_FORMULA_EVENT , { formulaId = formulaId })
	end
end

function WaterBarReturnCustomerMediator:OnRegist()
	regPost(POST.WATER_BAR_CUSTOMER_DRAW)
	self:DealWithCellIndex(self.preCellIndex)
end

function WaterBarReturnCustomerMediator:OnUnRegist()
	unregPost(POST.WATER_BAR_CUSTOMER_DRAW)
	local viewComponent = self:GetViewComponent()
	if viewComponent and (not tolua.isnull(viewComponent)) then
		viewComponent:stopAllActions()
		viewComponent:runAction(
				cc.RemoveSelf:create()
		)
	end
end
return WaterBarReturnCustomerMediator
