--[[
新等级奖励mediator
--]]
local Mediator = mvc.Mediator
local ActivityNoviceAccumulativePayMediator = class("ActivityNoviceAccumulativePayMediator", Mediator)
local NAME = "activity.noviceAccumulativePay.ActivityNoviceAccumulativePayMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager('GameManager')
local scheduler = require('cocos.framework.scheduler')

function ActivityNoviceAccumulativePayMediator:ctor( params, viewComponent )
	self.super:ctor(NAME, viewComponent)
	local datas = params or {}
	self.activityId = checkint(datas.activityId) -- 活动Id
	self.isControllable_ = true
	self.curGroupId = 1
	self.isPopup = datas.isPopup and true or false
end


function ActivityNoviceAccumulativePayMediator:InterestSignals()
	local signals = {
		POST.ACTIVITY_NOVICE_ACC_PAY_HOME.sglName,
		POST.ACTIVITY_NOVICE_ACC_PAY_DRAW.sglName,
		SGL.REFRESH_NOT_CLOSE_GOODS_EVENT,
	}
	return signals
end

function ActivityNoviceAccumulativePayMediator:ProcessSignal( signal )
	local name = signal:GetName()
	local body = checktable(signal:GetBody())
	if name == POST.ACTIVITY_NOVICE_ACC_PAY_HOME.sglName then
		self:SetHomeData(body)
		self:StartTimer()
		self:InitStageData()
		self:RefreshCurGroupId()
		self:RefreshRemindIcon()
		self:RefreshView()
	elseif name == POST.ACTIVITY_NOVICE_ACC_PAY_DRAW.sglName then
		local stageData = self:GetStageData()
		for k, v in pairs(stageData) do
			if checkint(v.currencyId) == checkint(body.requestData.currencyId) then
				v.hasDrawn = 1 
				break
			end
		end
		uiMgr:AddDialog('common.RewardPopup', {rewards = body.rewards})
		if self:IsAllRewardsDrawn() then
			self:CloseActivity()
		else
			self:SendSignal(POST.ACTIVITY_NOVICE_ACC_PAY_HOME.cmdName)
		end
	elseif name == SIGNALNAMES.REFRESH_NOT_CLOSE_GOODS_EVENT then
		if not self:IsAllRewardsDrawn() then
			self:SendSignal(POST.ACTIVITY_NOVICE_ACC_PAY_HOME.cmdName)
		end
	end
end

function ActivityNoviceAccumulativePayMediator:Initial( key )
    self.super.Initial(self, key)
    
	local viewComponent = require( 'Game.views.activity.noviceAccumulativePay.ActivityNoviceAccumulativePayView' ).new({isPopup = self.isPopup})
	display.commonUIParams(viewComponent, {ap = display.CENTER, po = display.center})
	if self.isPopup then
		app.uiMgr:GetCurrentScene():AddDialog(viewComponent)
	end
	self:SetViewComponent(viewComponent)
	self.viewData = viewComponent:getViewData()
	self:InitItemConf()
    self:InitView()

end

function ActivityNoviceAccumulativePayMediator:StartTimer()
	local homeData = self:GetHomeData()
	if app.timerMgr:RetriveTimer(NAME) then
        app.timerMgr:RemoveTimer(NAME)
	end
	self:GetViewComponent():UpdateTimeLabel(homeData.remainTime)
	local callback = function(countdown, remindTag, timeNum, datas, timerName)
		if countdown > 0 then
			self:GetViewComponent():UpdateTimeLabel(countdown)
		else
			self:CloseActivity()
		end
    end
	app.timerMgr:AddTimer({name = NAME, callback = callback, countdown = homeData.remainTime})
end

function ActivityNoviceAccumulativePayMediator:InitView()
	local viewComponent = self:GetViewComponent()
	local viewData = self:getViewData()
	local tableView = viewData.tableView
	tableView:setDataSourceAdapterScriptHandler(handler(self, self.onDataSourceAdapter))
	viewData.tipsBtn:setOnClickScriptHandler(handler(self, self.TipsButtonCallback))
	if self.isPopup and viewData.closeBtn then
		viewData.closeBtn:setOnClickScriptHandler(function (sender)
			app:UnRegsitMediator(NAME)
		end)
	end
end

function ActivityNoviceAccumulativePayMediator:RefreshView()
	local itemConf = self:GetItemConf()
	local curGroupId = self.curGroupId
	local isFinalTurn = curGroupId == #itemConf
	local homeData = self:GetHomeData()
	local progress = checkint(homeData.stage[1].progress)
	self:GetViewComponent():refreshUI(itemConf[curGroupId], isFinalTurn, progress)
end

function ActivityNoviceAccumulativePayMediator:RefreshRemindIcon()
	local ActivityMediator = app:RetrieveMediator('ActivityMediator')
	if not ActivityMediator then return end
	local stageData = self:GetStageData()
	local itemConf = self:GetItemConf()
	for i, v in ipairs(itemConf[self.curGroupId]) do
		local data = checktable(stageData[tostring(v.id)])
		if checkint(data.hasDrawn) == 0 and checkint(data.progress) >= checkint( v.moneyPoints) then
			ActivityMediator:AddRemindIcon(self.activityId)
			return 
		end
	end
	ActivityMediator:ClearRemindIcon(self.activityId)
end

function ActivityNoviceAccumulativePayMediator:InitItemConf()
	local conf = CommonUtils.GetConfigAllMess('newbieAccumulativePay', 'activity')
	local itemConf = {}
	for i, v in orderedPairs(conf) do
		if itemConf[checkint(v.groupId)] then
			table.insert(itemConf[checkint(v.groupId)], v)
		else
			itemConf[checkint(v.groupId)] = {v}
		end
	end
	self:SetItemConf(itemConf)
end

function ActivityNoviceAccumulativePayMediator:InitStageData()
	local homeData = self:GetHomeData()
	local stageData = {}
	for i, v in ipairs(homeData.stage) do
		stageData[tostring(v.currencyId)] = v
	end
	self:SetStageData(stageData)
end

function ActivityNoviceAccumulativePayMediator:RefreshCurGroupId()
	local stageData = self:GetStageData()
	local itemConf = self:GetItemConf()
	for groupId, groupData in ipairs(itemConf) do
		for i, v in ipairs(groupData) do
			if checkint(checktable(stageData[tostring(v.id)]).hasDrawn) == 0 then
				self.curGroupId = groupId
				return
			end
		end
	end
	self.curGroupId = #itemConf
end

function ActivityNoviceAccumulativePayMediator:IsAllRewardsDrawn()
	local stageData = self:GetStageData()
	local result = true
	for k, v in pairs(stageData) do
		if checkint(v.hasDrawn) == 0 then
			result = false
			break
		end
	end
	return result
end

function ActivityNoviceAccumulativePayMediator:enterLayer()
	self:SendSignal(POST.ACTIVITY_NOVICE_ACC_PAY_HOME.cmdName)
end

function ActivityNoviceAccumulativePayMediator:onDataSourceAdapter(p_convertview, idx)
	local pCell = p_convertview
    local index = idx + 1

	if pCell == nil then
		local tableView = self:getViewData().tableView
		pCell = self:GetViewComponent():CreateCell(tableView:getSizeOfCell())
		display.commonUIParams(pCell.viewData.drawBtn, {cb = handler(self, self.onDrawBtnAction)})
	end
	local stageData = self:GetStageData()
	local itemConf = self:GetItemConf()
	local group = itemConf[self.curGroupId]
	if group[index] then
		self:GetViewComponent():updateCell(pCell.viewData, group[index], stageData)
	end
	pCell.viewData.drawBtn:setTag(index)
	return pCell
end

function ActivityNoviceAccumulativePayMediator:onDrawBtnAction(sender)
	PlayAudioByClickNormal()
	local tag = sender:getTag()
	local stageData = self:GetStageData()
	local itemConf = self:GetItemConf()
	local group = itemConf[self.curGroupId]
	local data = group[tag]
	if not data then return end
	if not stageData[tostring(data.id)] then return end
	if checkint(stageData[tostring(data.id)].hasDrawn) == 0 and 
	checkint(stageData[tostring(data.id)].progress) >= checkint(data.moneyPoints) then
		self:SendSignal(POST.ACTIVITY_NOVICE_ACC_PAY_DRAW.cmdName, {currencyId = stageData[tostring(data.id)].currencyId})
	end
end

function ActivityNoviceAccumulativePayMediator:TipsButtonCallback( sender )
	PlayAudioByClickNormal()
    app.uiMgr:ShowIntroPopup({moduleId = '-67'})
end

function ActivityNoviceAccumulativePayMediator:CloseActivity()
	gameMgr:GetUserInfo().newbieAccumulativePay = 0
	local ActivityMediator = app:RetrieveMediator('ActivityMediator')
	if ActivityMediator then
		ActivityMediator:ClearActivityLayer()
	end
	if self.isPopup then
		app:UnRegsitMediator(NAME)
	end
end

function ActivityNoviceAccumulativePayMediator:SetHomeData( homeData )
	self.homeData = homeData
end

function ActivityNoviceAccumulativePayMediator:GetHomeData()
	return self.homeData
end

function ActivityNoviceAccumulativePayMediator:SetItemConf( itemConf )
	self.itemConf = itemConf
end

function ActivityNoviceAccumulativePayMediator:GetItemConf()
	return self.itemConf
end

function ActivityNoviceAccumulativePayMediator:SetStageData( stageData )
	self.stageData = checktable(stageData)
end

function ActivityNoviceAccumulativePayMediator:GetStageData()
	return self.stageData or {}
end

function ActivityNoviceAccumulativePayMediator:getViewData()
	return self.viewData
end

function ActivityNoviceAccumulativePayMediator:CleanupView()
	if app.timerMgr:RetriveTimer(NAME) then
        app.timerMgr:RemoveTimer(NAME)
	end
	local viewComponent = self:GetViewComponent()
	local scene = uiMgr:GetCurrentScene()
    if scene and viewComponent and not tolua.isnull(viewComponent) then
		scene:RemoveGameLayer(viewComponent)
		scene:RemoveViewForNoTouch()
    end
end

function ActivityNoviceAccumulativePayMediator:OnRegist(  )
	regPost(POST.ACTIVITY_NOVICE_ACC_PAY_HOME)
	regPost(POST.ACTIVITY_NOVICE_ACC_PAY_DRAW)
	self:enterLayer()
end

function ActivityNoviceAccumulativePayMediator:OnUnRegist(  )
	unregPost(POST.ACTIVITY_NOVICE_ACC_PAY_HOME)
	unregPost(POST.ACTIVITY_NOVICE_ACC_PAY_DRAW)
end


return ActivityNoviceAccumulativePayMediator