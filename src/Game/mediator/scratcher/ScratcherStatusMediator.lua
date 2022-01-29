---@class ScratcherStatusMediator : Mediator
---@field viewComponent ScratcherStatusView
local ScratcherStatusMediator = class('ScratcherStatusMediator', mvc.Mediator)

local NAME = "ScratcherStatusMediator"

function ScratcherStatusMediator:ctor(params, viewComponent)
	self.super.ctor(self, NAME, viewComponent)

	self.data = checktable(params.status) or {}

	local groupId = 1
	if params.needCloseAction then
		groupId = self.data.groupId
	else
		groupId = params.tasks.groupId
	end
	local parameter = CONF.FOOD_VOTE.PARMS:GetValue(groupId)
	
	self.tasks = self.data.myTask
	self.taskContent = CONF.FOOD_VOTE.TASK:GetAll()
	self.finalRewards = parameter.rewards
	self.needCloseAction = params.needCloseAction
	if not params.needCloseAction then
		self.countDown = params.tasks.countDown
	end
end

function ScratcherStatusMediator:Initial(key)
	self.super.Initial(self, key)
	local scene = app.uiMgr:GetCurrentScene()
	local viewComponent = require('Game.views.scratcher.ScratcherStatusView').new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	scene:AddDialog(viewComponent)
    local viewData = viewComponent.viewData
	viewData.eaterLayer:setOnClickScriptHandler(handler(self, self.OnBackBtnClickHandler))
	viewData.tipsBtn:setOnClickScriptHandler(handler(self, self.OnTipsBtnClickHandler))
	viewData.myBtn:setOnClickScriptHandler(handler(self, self.OnMyBtnClickHandler))
	viewData.previewBtn:setOnClickScriptHandler(handler(self, self.OnPreviewBtnClickHandler))

	for k, v in pairs(viewData.leftBars) do
		v:setOnProgressEndedScriptHandler(handler(self, self.ProgressActionEnded))
	end
	for k, v in pairs(viewData.rightBars) do
		v:setOnProgressEndedScriptHandler(handler(self, self.ProgressActionEnded))
	end

	viewComponent:updateLeftCardImg(self.data.cardId1)
	viewComponent:updateRightCardImg(self.data.cardId2)

	-- init
	local leftTaskMap = {}
	for taskId, value in pairs(self.data.info1 or {}) do
		local taskType = self.taskContent[taskId].taskType
		leftTaskMap[tostring(taskType)] = checkint(value)
	end
	local rightTaskMap = {}
	for taskId, value in pairs(self.data.info2 or {}) do
		local taskType = self.taskContent[taskId].taskType
		rightTaskMap[tostring(taskType)] = checkint(value)
	end

	-- update
	local left  = 0
	local right = 0
	local taskList = {
		{ type = 41,  title	= __("邪神遗迹层数") },
		{ type = 50,  title	= __("皇家对决次数") },
		{ type = 3,   title	= __("通过关卡次数") },
		{ type = 118, title	= __("包厢招待次数") },
		{ type = 88,  title	= __("公共订单次数") },
	}
	for index, data in ipairs(taskList) do
		local leftNum  = checkint(leftTaskMap[tostring(data.type)])
		local rightNum = checkint(rightTaskMap[tostring(data.type)])
		viewData.taskNameLabels[index]:setString(data.title)
		self:SetProgressBarValue(index, leftNum, rightNum)
		if leftNum > rightNum then left = left + 1 end
		if leftNum < rightNum then right = right + 1 end
	end

	-- 刮刮次数
	self:SetProgressBarValue(6, self.data.lotteryPlay1, self.data.lotteryPlay2)
	viewData.taskNameLabels[6]:setString(__("刮刮乐次数"))
	if checkint(self.data.lotteryPlay1) > checkint(self.data.lotteryPlay2) then
		left = left + 1
	elseif checkint(self.data.lotteryPlay1) < checkint(self.data.lotteryPlay2) then
		right = right + 1
	end
	
	-- 支持人数
	if 0 >= checkint(self.countDown) then
		self:SetProgressBarValue(7, checkint(self.data.support1), checkint(self.data.support2))
	else
		self:SetProgressBarValue(7, "???", "???")
	end
	viewData.taskNameLabels[7]:setString(__("支持人数"))

	if 0 >= checkint(self.countDown) then
		if checkint(self.data.support1) > checkint(self.data.support2) then
			left = left + 1
		elseif checkint(self.data.support1) < checkint(self.data.support2) then
			right = right + 1
		end
	end

	-- 票数
	viewData.leftVoteLabel:setString(string.fmt( __("_num_票"), {_num_ = left} ))
	viewData.rightVoteLabel:setString(string.fmt( __("_num_票"), {_num_ = right} ))
	
	if self.data.winnerId then
		if tonumber(self.data.winnerId) == tonumber(self.data.cardId1) then
			viewData.leftChampionImage:setVisible(true)
		elseif tonumber(self.data.winnerId) == tonumber(self.data.cardId2) then
			viewData.rightChampionImage:setVisible(true)
		end
	end
end

function ScratcherStatusMediator:SetProgressBarValue(idx, left, right)
	local viewData = self.viewComponent.viewData
	local leftBar = viewData.leftBars[idx]
	local rightBar = viewData.rightBars[idx]
	local leftNum = viewData.leftNums[idx]
	local rightNum = viewData.rightNums[idx]

	leftNum:setString(left)
	rightNum:setString(right)
	leftNum:setVisible(false)
	rightNum:setVisible(false)

	left = checkint(left)
	right = checkint(right)
	local total = left + right
	local time = 0.1
	local safeW = self.viewComponent.safeProgressWidth
	if 0 == total then
		leftBar:setMaxValue(100)
		rightBar:setMaxValue(100)
		-- leftBar:setValue(50)
		-- rightBar:setValue(50)
		leftBar:startProgress(50, time)
		rightBar:startProgress(50, time)

		leftNum:setPositionX(602)
		rightNum:setPositionX(620)
	else
		leftBar:setMaxValue(total)
		-- leftBar:setValue(left)

		rightBar:setMaxValue(total)
		-- rightBar:setValue(right)

		leftBar:startProgress(left, time)
		rightBar:startProgress(right, time)

		leftNum:setPositionX(370+safeW + left / total * (460-safeW*2))
		rightNum:setPositionX(852-safeW - right / total * (460-safeW*2))
	end
end

function ScratcherStatusMediator:OnRegist()
	regPost(POST.ACTIVITY_FOOD_COMPARE_RESULT_ACK)
end

function ScratcherStatusMediator:OnUnRegist()
    unregPost(POST.ACTIVITY_FOOD_COMPARE_RESULT_ACK)
	local scene = app.uiMgr:GetCurrentScene()
	scene:RemoveGameLayer(self.viewComponent)
end

function ScratcherStatusMediator:InterestSignals()
    local signals = {
        POST.ACTIVITY_FOOD_COMPARE_RESULT_ACK.sglName,
	}
	return signals
end

function ScratcherStatusMediator:ProcessSignal(signal)
    local name = signal:GetName()
	local body = signal:GetBody()
	-- dump(body, name)
	if POST.ACTIVITY_FOOD_COMPARE_RESULT_ACK.sglName == name then
		app.gameMgr:GetUserInfo().foodCompareResultAck = 1

		app:UnRegsitMediator(NAME)
	end
end

function ScratcherStatusMediator:OnBackBtnClickHandler( sender )
	PlayAudioByClickClose()
	
	if self.needCloseAction then
		self:SendSignal(POST.ACTIVITY_FOOD_COMPARE_RESULT_ACK.cmdName)
	else
		app:UnRegsitMediator(NAME)
	end
end

function ScratcherStatusMediator:OnTipsBtnClickHandler( sender )
    PlayAudioByClickNormal()
    
	app.uiMgr:ShowIntroPopup({moduleId = '-51'})
end

function ScratcherStatusMediator:OnMyBtnClickHandler( sender )
	PlayAudioByClickNormal()
	
	local mediator = require('Game.mediator.scratcher.ScratcherTaskProgressMediator').new(self.data)
	AppFacade.GetInstance():RegistMediator(mediator)
end

function ScratcherStatusMediator:OnPreviewBtnClickHandler( sender )
	PlayAudioByClickNormal()
	
	app.uiMgr:ShowInformationTipsBoard({targetNode = sender, iconIds = self.finalRewards, type = 4})
end

function ScratcherStatusMediator:ProgressActionEnded(sender)
	local tag = sender:getTag()
	local viewData = self.viewComponent.viewData
	local nums = viewData.leftNums
	if 10 < tag then
		nums = viewData.rightNums
	end
	tag = tag % 10
	local num = nums[tag]
	num:setVisible(true)
end

return ScratcherStatusMediator
