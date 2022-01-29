---@class ScratcherTaskMediator : Mediator
---@field viewComponent ScratcherTaskView
local ScratcherTaskMediator = class('ScratcherTaskMediator', mvc.Mediator)

local NAME = "ScratcherTaskMediator"

function ScratcherTaskMediator:ctor(params, viewComponent)
	self.super.ctor(self, NAME, viewComponent)
	self.data = checktable(params) or {}

	local t = {}      
	for n in pairs(self.data.tasks) do          
		t[#t+1] = n      
	end      
	table.sort(t, function ( a, b )
		return checkint(a) < checkint(b)
	end)      
	self.tasks = t

end


function ScratcherTaskMediator:Initial(key)
	self.super.Initial(self, key)
	local scene = app.uiMgr:GetCurrentScene()
	local viewComponent = require('Game.views.scratcher.ScratcherTaskView').new(self.data)
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	scene:AddDialog(viewComponent)

	local viewData = viewComponent.viewData
	viewData.backBtn:setOnClickScriptHandler(handler(self, self.OnBackBtnClickHandler))
	viewData.tipsBtn:setOnClickScriptHandler(handler(self, self.OnTipsBtnClickHandler))
	viewData.scrapeBtn:setOnClickScriptHandler(handler(self, self.OnScrapeBtnClickHandler))
	viewData.statusBtn:setOnClickScriptHandler(handler(self, self.OnStatusBtnClickHandler))
	viewData.taskGridview:setDataSourceAdapterScriptHandler(handler(self,self.OnDataSourceAction))
	viewData.taskGridview:setCountOfCell(table.nums(self.tasks))
	viewData.taskGridview:reloadData()
	self:UpdateCountDown(self.data.countDown)
end


function ScratcherTaskMediator:OnRegist()
	regPost(POST.FOOD_COMPARE_LOTTERY_HOME)
	regPost(POST.FOOD_COMPARE_COMPARE_INFO)
	regPost(POST.FOOD_COMPARE_DRAW_TASK_REWARD)
end

function ScratcherTaskMediator:OnUnRegist()
	app.timerMgr:RemoveTimer('scratcher')
    unregPost(POST.FOOD_COMPARE_LOTTERY_HOME)
    unregPost(POST.FOOD_COMPARE_COMPARE_INFO)
    unregPost(POST.FOOD_COMPARE_DRAW_TASK_REWARD)
	local scene = app.uiMgr:GetCurrentScene()
	scene:RemoveGameLayer(self.viewComponent)
end


function ScratcherTaskMediator:InterestSignals()
    local signals = {
        POST.FOOD_COMPARE_LOTTERY_HOME.sglName,
        POST.FOOD_COMPARE_COMPARE_INFO.sglName,
        POST.FOOD_COMPARE_DRAW_TASK_REWARD.sglName,
	}
	return signals
end

function ScratcherTaskMediator:ProcessSignal(signal)
    local name = signal:GetName()
	local body = signal:GetBody()
	-- dump(body, name)
	if POST.FOOD_COMPARE_LOTTERY_HOME.sglName == name then
		local mediator = require('Game.mediator.scratcher.ScratcherGameMediator').new({status = body, tasks = self.data})
		AppFacade.GetInstance():RegistMediator(mediator)
	elseif POST.FOOD_COMPARE_COMPARE_INFO.sglName == name then
		local mediator = require('Game.mediator.scratcher.ScratcherStatusMediator').new({status = body, tasks = self.data})
		AppFacade.GetInstance():RegistMediator(mediator)
	elseif POST.FOOD_COMPARE_DRAW_TASK_REWARD.sglName == name then
		app.uiMgr:AddDialog('common.RewardPopup', body)

		local taskId = body.requestData.taskId
		local task = self.data.tasks[taskId]
		task.status = 1
		for i, v in ipairs(self.tasks) do
			if v == taskId then
				local viewData = self.viewComponent.viewData
				local pCell = viewData.taskGridview:cellAtIndex(i - 1)
				if pCell then
					self:ReloadGridViewCell(pCell, i - 1)
				end
				break
			end
		end
	elseif "SCRATCHER_COUNT_DOWN" == name then
		self.data.countDown = body.countdown
		self:UpdateCountDown(self.data.countDown)
	end
end

function ScratcherTaskMediator:OnBackBtnClickHandler( sender )
	PlayAudioByClickNormal()
	
    app:UnRegsitMediator(NAME)
end

function ScratcherTaskMediator:OnTipsBtnClickHandler( sender )
    PlayAudioByClickNormal()
    
	app.uiMgr:ShowIntroPopup({moduleId = '-50'})
end

function ScratcherTaskMediator:OnScrapeBtnClickHandler( sender )
	PlayAudioByClickNormal()
	
	if 0 == self.data.poolId then
		if self:IsActivityEnd() then
			app.uiMgr:ShowInformationTips(__('活动已结束'))
			return
		end
	
		local mediator = require('Game.mediator.scratcher.ScratcherSelectMediator').new(self.data)
		AppFacade.GetInstance():RegistMediator(mediator)
	else
		self:SendSignal(POST.FOOD_COMPARE_LOTTERY_HOME.cmdName, {activityId = self.data.requestData.activityId})
	end
end

function ScratcherTaskMediator:OnStatusBtnClickHandler( sender )
	PlayAudioByClickNormal()
	
	self:SendSignal(POST.FOOD_COMPARE_COMPARE_INFO.cmdName, {activityId = self.data.requestData.activityId})
end

function ScratcherTaskMediator:OnDataSourceAction(p_convertview,idx)
	---@type ScratcherTaskCell
    local pCell = p_convertview
    if pCell == nil then
		pCell = require('Game.views.scratcher.ScratcherTaskCell').new()
		pCell.viewData.goodsIcon:setOnClickScriptHandler(handler(self, self.OnCellRewardBtnClickHandler))
		pCell.viewData.drawBtn:setOnClickScriptHandler(handler(self, self.OnCellDrawBtnClickHandler))
	end
	self:ReloadGridViewCell(pCell, idx)
	return pCell
end

function ScratcherTaskMediator:ReloadGridViewCell( pCell, idx )
	local viewData = pCell.viewData
	local task = self.data.tasks[self.tasks[idx + 1]]
	local content = {
		string.fmt(task.descr, {_target_num_ = task.targetNum}),
		"\n(",
		checkint(task.progress),
		" / ",
		task.targetNum,
		")"
	}
	viewData.taskContent:setString(table.concat( content ))
	viewData.goodsIcon:RefreshSelf(task.rewards[1])

	local drawBtn = viewData.drawBtn
	drawBtn:setTag(idx)
	if checkint(task.progress) < tonumber(task.targetNum) then
		drawBtn:setNormalImage(_res('ui/common/common_btn_orange_disable.png'))
		drawBtn:setSelectedImage(_res('ui/common/common_btn_orange_disable.png'))
		display.commonLabelParams(drawBtn, fontWithColor('14', {text = __('领取')}))
		drawBtn:setEnabled(true)
	else
		if 1 == task.status then
			drawBtn:setNormalImage(_res('ui/common/activity_mifan_by_ico.png'))
			drawBtn:setSelectedImage(_res('ui/common/activity_mifan_by_ico.png'))
			display.commonLabelParams(drawBtn, fontWithColor('14', {text = __('已领取')}))
			drawBtn:setEnabled(false)
		else
			drawBtn:setNormalImage(_res('ui/common/common_btn_orange.png'))
			drawBtn:setSelectedImage(_res('ui/common/common_btn_orange.png'))
			display.commonLabelParams(drawBtn, fontWithColor('14', {text = __('领取')}))
			drawBtn:setEnabled(true)
		end
	end
end

function ScratcherTaskMediator:OnCellRewardBtnClickHandler(sender)
	app.uiMgr:ShowInformationTipsBoard({
		targetNode = sender, iconId = checkint(sender.goodId), type = 1
	})
end

function ScratcherTaskMediator:OnCellDrawBtnClickHandler(sender)
	PlayAudioByClickNormal()

	if self:IsActivityEnd() then
		app.uiMgr:ShowInformationTips(__('活动已结束'))
		return
	end

	local tag = sender:getTag()
	local taskId = self.tasks[tag + 1]
	local task = self.data.tasks[taskId]
	if checkint(task.progress) < tonumber(task.targetNum) then
		app.uiMgr:ShowInformationTips(__('未达成'))
	else
		if 1 == task.status then
			app.uiMgr:ShowInformationTips(__('已领取'))
		else
			self:SendSignal(POST.FOOD_COMPARE_DRAW_TASK_REWARD.cmdName, {activityId = self.data.requestData.activityId, taskId = taskId})
		end
	end
end

function ScratcherTaskMediator:UpdateCountDown( countdown )
	local viewData = self.viewComponent.viewData
	if countdown <= 0 then
		viewData.timeLabel:setString(__('已结束'))
	else
		if checkint(countdown) <= 86400 then
			viewData.timeLabel:setString(string.formattedTime(checkint(countdown),'%02i:%02i:%02i'))
		else
			local day = math.floor(checkint(countdown)/86400)
			local hour = math.floor((countdown - day * 86400) / 3600)
			viewData.timeLabel:setString(string.fmt(__('_day_天_hour_小时'),{_day_ = day, _hour_ = hour}))
		end
	end
end

function ScratcherTaskMediator:IsActivityEnd()
	return self.data.countDown <= 0
end

return ScratcherTaskMediator
