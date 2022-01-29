--[[
召回系统Mediator
--]]
local Mediator = mvc.Mediator

local RecallMainMediator = class("RecallMainMediator", Mediator)

local NAME = "RecallMainMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance('AppFacade'):GetManager("GameManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
local dataMgr = AppFacade.GetInstance():GetManager("DataManager")

function RecallMainMediator:ctor( params, viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.args = checktable(params) or {}
	self.showLayer = {} 
	self.rightClickTag = checkint(self.args.recallType or RecallType.RECALL)  --右边好友列表tag
	self.AtimeUpdateFunc = nil --活动倒计时计时器
	self.TtimeUpdateFunc = nil --任务倒计时计时器
	if not self.args.leftSeconds then
		self.args.leftSeconds = 0
	end
	if not self.args.veteranTasks then
		self.args.veteranTasks = {}
	end
	if not self.args.veteranLoginRewards then
		self.args.veteranLoginRewards = {}
	end
	if not self.args.veteranTaskEndLeftSeconds then
		self.args.veteranTaskEndLeftSeconds = 0
	end
	self:SortRecallRewards()
	self:SortRecalledLoginRewards()
end

function RecallMainMediator:InterestSignals()
	local signals = { 
		RECALL_REWARD_DRAW_UI ,
		RECALLED_TASK_DRAW_UI ,
		COUNT_DOWN_ACTION,
	}

	return signals
end

function RecallMainMediator:ProcessSignal( signal )
	local name = signal:GetName() 
	local body = signal:GetBody()
	-- dump(body, name)
	if name == RECALL_REWARD_DRAW_UI then
		self:CheckRedPoint(RecallType.RECALL)
		local viewData = self.viewComponent.viewData_
		local buttons  = viewData.buttons or {}
		local remindBtnRecalled = buttons[tostring(RecallType.RECALLED)]
		local remindBtnRecall   = buttons[tostring(RecallType.RECALL)]
		local remindIconRecalled = remindBtnRecalled and remindBtnRecalled:getChildByName('remindIcon') or nil
		local remindIconRecall   = remindBtnRecall and remindBtnRecall:getChildByName('remindIcon') or nil
		if (remindIconRecall and remindIconRecall:isVisible()) or (remindIconRecalled and remindIconRecalled:isVisible()) then
			dataMgr:AddRedDotNofication(tostring(RemindTag.RECALL),RemindTag.RECALL, "[老玩家召回]RECALL_REWARD_DRAW_UI")
			gameMgr:GetUserInfo().showRedPointForRecallTask = true
		else
			dataMgr:ClearRedDotNofication(tostring(RemindTag.RECALL),RemindTag.RECALL, "[老玩家召回]RECALL_REWARD_DRAW_UI")
			gameMgr:GetUserInfo().showRedPointForRecallTask = false
		end
		AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, tag = RemindTag.RECALL})
	elseif name == RECALLED_TASK_DRAW_UI then
		self:CheckRedPoint(RecallType.RECALLED)
		local viewData = self.viewComponent.viewData_
		local remindIconRecalled = viewData.buttons[tostring(RecallType.RECALLED)]:getChildByName('remindIcon')
		local recallBtn          = viewData.buttons[tostring(RecallType.RECALL)]
		local remindIconRecall   = recallBtn and recallBtn:getChildByName('remindIcon') or nil
		if (remindIconRecall and remindIconRecall:isVisible()) or remindIconRecalled:isVisible() then
			dataMgr:AddRedDotNofication(tostring(RemindTag.RECALL),RemindTag.RECALL, "[老玩家召回]RECALLED_TASK_DRAW_UI")
			gameMgr:GetUserInfo().showRedPointForRecallTask = true
		else
			dataMgr:ClearRedDotNofication(tostring(RemindTag.RECALL),RemindTag.RECALL, "[老玩家召回]RECALLED_TASK_DRAW_UI")
			gameMgr:GetUserInfo().showRedPointForRecallTask = false
		end
		AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, tag = RemindTag.RECALL})
	elseif name == COUNT_DOWN_ACTION then
		if body.countdown and checkint(body.countdown) == 0 then
			if checkint(body.tag) == RemindTag.RECALLEDMASTER then -- 老玩家成功召回其他人
				self:CheckRedPoint(RecallType.RECALL)
			elseif checkint(body.tag) == RemindTag.RECALLH5 then -- 老玩家H5界面可以领奖
				self:CheckRedPoint(RecallType.RECALL)
			end
		end
	end
end

function RecallMainMediator:Initial( key )
	self.super.Initial(self, key)
	local scene = uiMgr:GetCurrentScene()
	local viewComponent  = require('Game.views.RecallMainView').new({onlyRecalled = ((0 < self.args.veteranTaskEndLeftSeconds) and (0 == self.args.leftSeconds))})
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	scene:AddDialog(viewComponent)
    local viewData = viewComponent.viewData_
	for k, v in pairs( viewData.buttons ) do
		v:setOnClickScriptHandler(handler(self,self.RightButtonActions))
	end
	self:RightButtonActions(self.rightClickTag)	
	-- self:UpdateTimeLabel(self.args.leftSeconds)
	if 0 < self.args.leftSeconds then
		self.AtimeUpdateFunc = scheduler.scheduleGlobal(function(dt)
			--事件的计时器
			self.args.leftSeconds = self.args.leftSeconds - 1
			local leftSeconds = self.args.leftSeconds
			if checkint(leftSeconds) <= 0 then
				scheduler.unscheduleGlobal(self.AtimeUpdateFunc)
				self.AtimeUpdateFunc = nil
			end
			AppFacade.GetInstance():DispatchObservers(RECALL_MAIN_TIME_UPDATE_EVENT, {leftSeconds = self.args.leftSeconds})
			-- self:UpdateTimeLabel(self.args.leftSeconds)
		end,1.0)
	end
	if 0 < self.args.veteranTaskEndLeftSeconds and gameMgr:CheckIsVeteran() then
		self.TtimeUpdateFunc = scheduler.scheduleGlobal(function(dt)
			--事件的计时器
			self.args.veteranTaskEndLeftSeconds = self.args.veteranTaskEndLeftSeconds - 1
			local leftSeconds = self.args.veteranTaskEndLeftSeconds
			if checkint(leftSeconds) <= 0 then
				scheduler.unscheduleGlobal(self.TtimeUpdateFunc)
				self.TtimeUpdateFunc = nil
			end
			AppFacade.GetInstance():DispatchObservers(RECALLED_TASK_TIME_UPDATE_EVENT, {leftSeconds = self.args.veteranTaskEndLeftSeconds})
		end,1.0)
	end
	self:CheckRedPoint(RecallType.RECALL)
	if gameMgr:CheckIsVeteran() then
		self:CheckRedPoint(RecallType.RECALLED)
	end
end

function RecallMainMediator:SortRecallRewards(  )
	table.sort(self.args.recallRewards, function ( a, b )
		local function GetTaskIsFinish( task )
			return checkint(task.progress) >= checkint(task.targetNum)
		end
		if a.hasDrawn == b.hasDrawn then
			if GetTaskIsFinish(a) == GetTaskIsFinish(b) then
				return a.id < b.id
			else
				return GetTaskIsFinish(a)
			end
		else
			return 0 == a.hasDrawn -- 未领取
		end
	end)
end

function RecallMainMediator:SortRecalledLoginRewards(  )
	table.sort(self.args.veteranLoginRewards, function ( a, b )
		if a.hasDrawn == b.hasDrawn then
			if a.status == b.status then
				return a.id < b.id
			else
				return a.status < b.status
			end
		else
			return 0 == a.hasDrawn -- 未领取
		end
	end)
end

-- 检查tab页签的小红点显示
function RecallMainMediator:CheckRedPoint( recallType )
	local viewData = self.viewComponent.viewData_
	if RecallType.RECALLED == recallType then
		if not viewData.buttons[tostring(RecallType.RECALLED)] then
			return
		end
		local remindIcon = viewData.buttons[tostring(RecallType.RECALLED)]:getChildByName('remindIcon')
		if not gameMgr:CheckIsVeteran() then
			remindIcon:setVisible(false)
			return false
		end
		local isRewardAvailable = false
		-- 登陆奖励
		for k,v in pairs(self.args.veteranLoginRewards) do
			if 1 == checkint(v.status) and 0 == checkint(v.hasDrawn) then
				isRewardAvailable = true
				break
			end
		end
		-- 7天任务
		local showRedPoint = false
		if 0 < checkint(self.args.veteranTaskEndLeftSeconds) then
			for i=1,math.min(self.args.veteranDayNum, table.nums(self.args.veteranTasks)) do
				local tasks = self.args.veteranTasks[tostring(i)]
				for _,task in pairs(tasks) do
					if task.hasDrawn == 0 then -- 说明有未领取任务
						if checkint(task.progress) >= checkint(task.targetNum) then
							showRedPoint = true
							break
						end
					end
				end
				if showRedPoint then
					break
				end
			end
			-- 是否所有任务都完成需要领取最终奖励
			if not showRedPoint then
				if checkint(self.args.veteranTasks) >= table.nums(self.args.veteranTasks) then
					local isAllDrawn = true
					for day, tasks in pairs(self.args.veteranTasks) do
						for _,task in pairs(tasks) do
							if task.hasDrawn == 0 then -- 说明有未领取任务
								isAllDrawn = false
								break
							end
						end
						if not isAllDrawn then
							break
						end
					end
					showRedPoint = isAllDrawn
				end
			end
		end
		if self.showLayer[tostring(RecallType.RECALLED)] then
			self.showLayer[tostring(RecallType.RECALLED)].viewData_.remindIcon:setVisible(showRedPoint)
		end
		remindIcon:setVisible(showRedPoint or isRewardAvailable)
		return showRedPoint or isRewardAvailable
	elseif RecallType.RECALL == recallType then
		if not viewData.buttons[tostring(RecallType.RECALL)] then
			return
		end
		local remindIcon = viewData.buttons[tostring(RecallType.RECALL)]:getChildByName('remindIcon')
		if gameMgr:GetUserInfo().showRedPointForMasterRecalled or gameMgr:GetUserInfo().showRedPointForRecallH5 then
			remindIcon:setVisible(true)
			return true
		end
		local showRedPoint = false
		for _, task in pairs(self.args.recallRewards) do
			if checkint(task.hasDrawn) == 0 then -- 说明有未领取任务
				if checkint(task.progress) >= checkint(task.targetNum) then
					showRedPoint = true
					break
				end
			end
		end
		remindIcon:setVisible(showRedPoint)
		return showRedPoint
	end
end

-- function RecallMainMediator:UpdateTimeLabel( leftSeconds )
-- 	local viewData = self.viewComponent.viewData_
-- 	if checkint(leftSeconds) <= 0 then
-- 		if self.AtimeUpdateFunc then
-- 			scheduler.unscheduleGlobal(self.AtimeUpdateFunc)
-- 			self.AtimeUpdateFunc = nil
-- 		end
-- 		viewData.timeLabel:setString('00:00:00')
-- 	else
-- 		if checkint(leftSeconds) <= 86400 then
-- 			viewData.timeLabel:setString(string.formattedTime(checkint(leftSeconds),'%02i:%02i:%02i'))
-- 		else
-- 			local day = math.floor(checkint(leftSeconds)/86400)
-- 			local hour = math.floor((leftSeconds - day * 86400) / 3600)
-- 			viewData.timeLabel:setString(string.fmt(__('_day_天_hour_小时'),{_day_ = day, _hour_ = hour}))
-- 		end
-- 	end
-- end

--[[
右边不同类型model按钮的事件处理逻辑
@param sender button对象
--]]
function RecallMainMediator:RightButtonActions( sender )
	local tag = 0
	local temp_data = {}
	if type(sender) == 'number' then
		tag = sender
	else
		tag = sender:getTag()
		PlayAudioClip(AUDIOS.UI.ui_depot_tabchange.id)
		if self.rightClickTag == tag then
			sender:setChecked(true)
			return
		end
	end
	
	local isTabExist = false
	local viewData = self:GetViewComponent().viewData_
	for k, v in pairs( viewData.buttons ) do
		local curTag = v:getTag()
		if tag == curTag then
			isTabExist = true
			v:setChecked(true)
			v:getChildByName('title'):setColor(cc.c3b(233, 73, 26))
			if curTag == RecallType.INVITED_CODE then
				v.tabSpine:setAnimation(0, 'idle2', true)
				v.tabSpine:setPositionY(viewData.spinePos + 5)
			end
		else
			v:setChecked(false)
			v:getChildByName('title'):setColor(cc.c3b(92, 92, 92))
			if curTag == RecallType.INVITED_CODE then
				v.tabSpine:setAnimation(0, 'idle1', true)
				v.tabSpine:setPositionY(viewData.spinePos)
			end
		end
	end
	if not isTabExist then
		for k,v in pairs(viewData.buttons) do
			local curTag = v:getTag()
			v:setChecked(true)
			v:getChildByName('title'):setColor(cc.c3b(233, 73, 26))
			if curTag == RecallType.INVITED_CODE then
				v.tabSpine:setAnimation(0, 'idle2', true)
				v.tabSpine:setPositionY(viewData.spinePos + 5)
			end
			tag = curTag
			isTabExist = true
			break
		end
	end
	if not isTabExist then
		return
	end

	local prePanel = self.showLayer[tostring(self.rightClickTag)]
	if prePanel then
		prePanel:setVisible(false)
	end

	self.rightClickTag = tag
	if tag == RecallType.RECALL then -- 召回
		if self.showLayer[tostring(tag)] then
			self.showLayer[tostring(tag)]:setVisible(true)
		else
			local RecallMediator = require( 'Game.mediator.RecallMediator')
			local mediator = RecallMediator.new(self.args)
			self:GetFacade():RegistMediator(mediator)
	    	viewData.view:addChild(mediator:GetViewComponent())
	    	mediator:GetViewComponent():setAnchorPoint(cc.p(0,0))
			mediator:GetViewComponent():setPosition(cc.p(0,0))
			self.showLayer[tostring(tag)] = mediator:GetViewComponent()
		end
	elseif tag == RecallType.RECALLED then -- 被召回
		if self.showLayer[tostring(tag)] then
			self.showLayer[tostring(tag)]:setVisible(true)
		else
			local RecalledMediator = require( 'Game.mediator.RecalledMediator' )
			local mediator = RecalledMediator.new(self.args)
			self:GetFacade():RegistMediator(mediator)
	    	viewData.view:addChild(mediator:GetViewComponent())
	    	mediator:GetViewComponent():setAnchorPoint(cc.p(0,0))
			mediator:GetViewComponent():setPosition(cc.p(0,0))
			self.showLayer[tostring(tag)] = mediator:GetViewComponent() 

			self:CheckRedPoint(RecallType.RECALLED)
		end
	elseif tag == RecallType.INVITED_CODE then -- 输入召回码
		if self.showLayer[tostring(tag)] then
			self.showLayer[tostring(tag)]:setVisible(true)
		else
			local RecallInvitedCodeMediator = require( 'Game.mediator.RecallInvitedCodeMediator' )
			local mediator = RecallInvitedCodeMediator.new(self.args)
			self:GetFacade():RegistMediator(mediator)
	    	viewData.view:addChild(mediator:GetViewComponent())
	    	mediator:GetViewComponent():setAnchorPoint(cc.p(0,0))
			mediator:GetViewComponent():setPosition(cc.p(0,0))
			self.showLayer[tostring(tag)] = mediator:GetViewComponent() 
		end
	end
end

function RecallMainMediator:OnRegist(  )
end

function RecallMainMediator:OnUnRegist(  )
	if self.TtimeUpdateFunc then
		scheduler.unscheduleGlobal(self.TtimeUpdateFunc)
	end
	if self.AtimeUpdateFunc then
		scheduler.unscheduleGlobal(self.AtimeUpdateFunc)
	end
	local scene = uiMgr:GetCurrentScene()
	scene:RemoveGameLayer(self.viewComponent)
	AppFacade.GetInstance():UnRegsitMediator('RecallMediator')
	AppFacade.GetInstance():UnRegsitMediator('RecalledMediator')
	AppFacade.GetInstance():UnRegsitMediator('RecallInvitedCodeMediator')
end

return RecallMainMediator