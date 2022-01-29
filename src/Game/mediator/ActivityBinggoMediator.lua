local VIEW_TAG = 110123
local Mediator = mvc.Mediator
local NAME = "ActivityBinggoMediator"
local ActivityBinggoMediator = class(NAME, Mediator)

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local timerMgr = AppFacade.GetInstance():GetManager("TimerManager")
local labelparser = require("Game.labelparser")

function ActivityBinggoMediator:ctor(params, viewComponent )
	self.super:ctor(NAME,viewComponent)

	local data = params and checktable(params.data) or {}

	self.isControllable_ = true

	self.allTasks = {}      -- 所有任务列表
	self.allCoverState = {} -- 所有遮盖状态
	self.isOpenAllCover = true -- 是否打开过所有遮盖
	self.openCoverCount = 0    -- 开盖个数
	self.activityHomeDatas = data.activityHomeDatas or {}

	self.activityId   = checkint(data.activityId)
	self.leftSeconds  = checkint(data.leftSeconds)
	self.endStoryId   = data.endStoryId
	self.doneConsumeCD = checkint(self.activityHomeDatas.doneConsumeCD)
	self.doneConsumeDayCount = checkint(self.activityHomeDatas.doneConsumeDayCount)
	self.isConsumeDiamondUnlock = self:checkIsConsumeDiamondUnlock()

	-- logInfo.add(5, 'ActivityBinggoMediator --->>>>>>>>')
	-- logInfo.add(5, tableToString(self.activityHomeDatas))
	-- dump(self.activityHomeDatas, '2CreateBinggoActivity22')

	
end

function ActivityBinggoMediator:InterestSignals()
	local signals = {
		COUNT_DOWN_ACTION,
		SIGNALNAMES.Activity_DrawBinggoTask_Callback,
		SIGNALNAMES.Activity_BinggoOpen_Callback,
	}

	return signals
end

function ActivityBinggoMediator:ProcessSignal(signal)
	local name = signal:GetName()
	local body = signal:GetBody() or {}

	if name == COUNT_DOWN_ACTION then
		local timerName = body.timerName
		if timerName == NAME then
			local countdown = body.countdown
			local timeTitleLabel = self:getViewData().timeTitleLabel
			if not self.isConsumeDiamondUnlock and self:checkIsConsumeDiamondUnlock() then
				self.isConsumeDiamondUnlock = true
				-- todo 刷新一次 所有 cover
				self:updateAllCoverUnlockBtnImg()
			end
			if self.activityMediator then
				local time = self.activityMediator:ChangeTimeFormat(countdown,  ACTIVITY_TYPE.BINGGO)
				display.commonLabelParams(timeTitleLabel, {text = string.fmt(__('活动剩余时间:_time_'), {_time_ = time})})
			end
		end
	elseif name == SIGNALNAMES.Activity_DrawBinggoTask_Callback then
		local requestData = body.requestData
		if requestData.type == 2 then
			self.activityHomeDatas.finalRewardsHasDrawn = 1
			self:updateRewardBtn()
			
			local rewards = body.rewards or {}
			if #rewards > 0 then
				uiMgr:AddDialog('common.RewardPopup', {rewards = rewards, closeCallback = function ()
					if self.activityMediator then
						if checkint(self.endStoryId) > 0 then
							app.activityMgr:ShowActivityStory({
								activityId = self.activityId,
								storyId = self.endStoryId,
								storyType = 'END',
							})
						end
					end
				end})
			end

			if self.activityMediator then
				self.activityMediator:checkBinggoRedPoint(self.activityId)
			end

			self.isControllable_ = true
		end
	elseif name == SIGNALNAMES.Activity_BinggoOpen_Callback then
		local requestData = body.requestData
		local taskId = requestData.taskId
		local binggoId = requestData.binggoId
		local isConsumeDone = checkint(requestData.isConsumeDone)

		self.openCoverCount = self.openCoverCount + 1
		self.activityHomeDatas.canOpenCoverCount = self.activityHomeDatas.canOpenCoverCount - 1
		self.activityHomeDatas.surplusCoverCount = self.activityHomeDatas.surplusCoverCount - 1

		if self.activityMediator then
			self.activityMediator:checkBinggoRedPoint(self.activityId)
		end

		local curIndex = 0
		for i,v in ipairs(self.allTasks) do
			if v.taskId == taskId then
				curIndex = i
				break
			end
		end

		if curIndex ~= 0 then
			local taskData = self.allTasks[curIndex]
			taskData.isBinggoOpen = 1
			if isConsumeDone == 1 then
				
				local doneOnceConsume = self.activityHomeDatas.doneOnceConsume
				local priceConf = doneOnceConsume[binggoId] or doneOnceConsume[1]
				local goodsId = priceConf.goodsId
				local price = tonumber(priceConf.num)
				-- 扣除消耗
				CommonUtils.DrawRewards({
					{goodsId = goodsId, num = -price}
				})

				self.activityHomeDatas.taskTotalProgress = self.activityHomeDatas.taskTotalProgress + 1
				self:updateTaskTotalProgress()
				
				for i, groupTask in ipairs(self.activityHomeDatas.allGroupTask) do
					local tasks = groupTask.tasks
					local isOwnBinggoId = false
					for i, task in ipairs(tasks) do
						local taskBinggoId = checkint(task.binggoId)
						if taskBinggoId == binggoId then
							isOwnBinggoId = true
							groupTask.groupTaskProgress = groupTask.groupTaskProgress + 1
						end
					end

					if isOwnBinggoId and groupTask.groupTaskProgress >= groupTask.groupTaskTargetNum then
						self.activityHomeDatas.canReceiveGroupTaskCount = self.activityHomeDatas.canReceiveGroupTaskCount + 1
					end
				end

				if self.activityMediator then
					self.activityMediator:binggoGroupTaskSort(self.activityHomeDatas.allGroupTask)
					self.activityMediator:updateBinggoActivity(self.activityId)
					self.activityMediator:checkBinggoRedPoint(self.activityId)
				end

				taskData.progress = taskData.target
				local taskListViewData = self:getViewData().taskListViewData
				local gridView = taskListViewData.gridView
				local cell = gridView:cellAtIndex(curIndex - 1)
				if cell then
					self:updateCellState(cell.viewData, taskData)
				end
			end
		end
		-- logInfo.ad
		-- logInfo.add(5, tableToString(self.activityHomeDatas.allGroupTask[1].tasks))
		-- logInfo.add(5, tableToString(self.activityHomeDatas.allGroupTask))

		local cb = function ()
			self.isControllable_ = true
			self:updateRewardBtn()
		end
		self:showBinggoImg(binggoId, cb)
		
	end
end

function ActivityBinggoMediator:Initial(key)
	self.super:Initial(key)

    local viewComponent = require('Game.views.ActivityBinggoView').new()
	viewComponent:setTag(VIEW_TAG)
	display.commonUIParams(viewComponent, {ap = display.CENTER, po = cc.p(display.width * 0.5, display.height * 0.5)})
	self:SetViewComponent(viewComponent)
	
	local scene = uiMgr:GetCurrentScene()
	scene:AddDialog(viewComponent)

	self.curScene_      = scene
	self.viewComponent_ = viewComponent
	self.viewData_      = viewComponent:getViewData()
	self.activityMediator = self:GetFacade():RetrieveMediator('ActivityMediator')

	self:initData()
	self:initUi()
end

function ActivityBinggoMediator:initData()
	local binggoTasks = self.activityHomeDatas.binggoTasks or {}
	
	-- self.isShow
	for puzzleId,puzzleTasks in ipairs(binggoTasks) do
		local isCanOpenCover = true -- 是否能遮盖
		local isOpenCover = true -- 是否打开过遮盖
		for i,task in ipairs(puzzleTasks) do
			local target = checkint(task.target)
			local progress = checkint(task.progress)
			local isBinggoOpen = checkint(task.isBinggoOpen) == 1
			isOpenCover = isOpenCover and isBinggoOpen
			isCanOpenCover = isCanOpenCover and (progress >= target)
			table.insert(self.allTasks, task)
		end
		
		self.allCoverState[tostring(puzzleId)] = {isCanOpenCover = isCanOpenCover, isOpenCover = isOpenCover}
		
		if isOpenCover then
			self.openCoverCount = self.openCoverCount + 1
		end
	end
	
	self:sortAllTask()
end

function ActivityBinggoMediator:initUi()
	local viewData  = self:getViewData()
	local closeView = viewData.closeView
	display.commonUIParams(closeView, {cb = handler(self, self.closeViewHandler), animate = false})

	timerMgr:AddTimer({name = NAME, countdown = self.leftSeconds})

	local tipBtn = viewData.tipBtn
	display.commonUIParams(tipBtn, {cb = handler(self, self.onClickTipHandler), animate = false})

	local puzzleViewData   = viewData.puzzleViewData
	
	local puzzleBg         = puzzleViewData.puzzleBg
	local skinId = self.activityHomeDatas.finalRewards[1].goodsId
	puzzleBg:setTexture(app.activityMgr:getBinngoFinalRewardImgBySkinId(skinId))

	local rewardBtn		   = puzzleViewData.rewardBtn
	display.commonUIParams(rewardBtn, {cb = handler(self, self.onReceiveRewardHandler)})
	self:updateBinggoState()

	local taskListViewData = viewData.taskListViewData

	-- local progressLabel = taskListViewData.progressLabel
	-- local taskTotalProgress = checkint(self.activityHomeDatas.taskTotalProgress)
	-- local taskTotalTargetNum = checkint(self.activityHomeDatas.taskTotalTargetNum)
	-- display.commonLabelParams(progressLabel, {text = string.fmt('当前进度 (_progress_/_targetNum_)', {_progress_ = taskTotalProgress, _targetNum_ = taskTotalTargetNum})})
	self:updateTaskTotalProgress()

	local gridView = taskListViewData.gridView
	gridView:setDataSourceAdapterScriptHandler(handler(self, self.onDataSource))
	gridView:setCountOfCell(#self.allTasks)
	gridView:reloadData()
end


-----------------------------------
-- handler
function ActivityBinggoMediator:closeViewHandler(sender)
	-- 做个检查  防止 领取 最终奖励是奖励还没插入背包 就 退出该界面
	if not self.isControllable_ then return end
	PlayAudioByClickClose()
	self:GetFacade():UnRegsitMediator(NAME)
end

function ActivityBinggoMediator:onReceiveRewardHandler(sender)
	if not self.isControllable_ then return end
	PlayAudioByClickNormal()
	self.isControllable_ = false
	self:SendSignal(COMMANDS.COMMAND_Activity_Draw_BinggoTask, {activityId = self.activityId, type = 2, taskGroupId = 0})
end

function ActivityBinggoMediator:onClickTipHandler(sender)
	if not self.isControllable_ then return end
	PlayAudioByClickNormal()
	uiMgr:ShowInformationTipsBoard({targetNode = sender, descr = __('解开所有拼图获得神秘奖励'), type = 5, bgSize = cc.size(300, 120)})
end

function ActivityBinggoMediator:binggoOpenHandler(binggoId, isConsumeDone)
	local binggoTasks = self.activityHomeDatas.binggoTasks or {}
	local binggoTask = binggoTasks[binggoId] or {}
	local data = binggoTask[1]
	isConsumeDone = isConsumeDone or 0
	if data then
		self:SendSignal(COMMANDS.COMMAND_Activity_BinggoOpen, {activityId = self.activityId, taskId = data.taskId, binggoId = binggoId, isConsumeDone = isConsumeDone})
	end
end

function ActivityBinggoMediator:onDataSource(p_convertview, idx)
	local pCell = p_convertview
    local index = idx + 1

	if pCell == nil then
		pCell = self.viewComponent_:CreateListCell(cc.size(479, 126))
	end
	
	xTry(function()
		
		local viewData = pCell.viewData
		self:updateCellState(viewData, self.allTasks[index])

	end,__G__TRACKBACK__)

	return pCell
end

function ActivityBinggoMediator:onClickCoverHandler(sender)
	if not self.isControllable_ then return end
	PlayAudioByClickNormal()
	self.isControllable_ = false
	local binngoId = sender:getTag()
	self:binggoOpenHandler(binngoId)
	-- for i,v in ipairs(self.allTasks) do
	-- 	if v.taskId == data.taskId then
	-- 		v.isBinggoOpen = 1
	-- 	end
	-- end
end

function ActivityBinggoMediator:onClickUnlockCoverAction(sender)
	if not self.isControllable_ then return end
	PlayAudioByClickNormal()
	local binngoId = sender:getTag()
	local doneOnceConsume = self.activityHomeDatas.doneOnceConsume
	local priceConf = doneOnceConsume[binngoId] or doneOnceConsume[1]
	local goodsId = priceConf.goodsId
	local price = tonumber(priceConf.num)
	local parsedtable = labelparser.parse(string.format(__('是否消耗%s<img>x</img>揭秘任务'), price))
	
	local richtext = {}
	for i, v in ipairs(parsedtable) do
		if v.labelname == 'div' then
			table.insert(richtext, fontWithColor(4, {text = v.content}))
		elseif v.labelname == 'img' then
			table.insert(richtext, {img = CommonUtils.GetGoodsIconPathById(goodsId), scale = 0.15})
		end
	end
	
	-- 弹提示
	local commonTip = require('common.NewCommonTip').new({
		richtext = richtext,
		richTextW = 300,
		callback = function ()
			if self.isConsumeDiamondUnlock then
				local diamond = CommonUtils.GetCacheProductNum(goodsId)
				if diamond < price then
					if GAME_MODULE_OPEN.NEW_STORE then
						app.uiMgr:showDiamonTips()
					else
						uiMgr:ShowInformationTips(__('幻晶石不足'))
					end
				else
					self:binggoOpenHandler(binngoId, 1)
				end
			else
				-- self:binggoOpenHandler(binngoId, 1)
				uiMgr:ShowInformationTips(string.format( __('活动第%s天可消耗幻晶石解锁'), self.doneConsumeDayCount))
			end
		end
	})
	commonTip:setPosition(display.center)
	uiMgr:GetCurrentScene():AddDialog(commonTip)

	-- if diamond < price then
	-- 	uiMgr:ShowInformationTips(__('幻晶石不足'))
	-- else

	-- end

end

--[[
   显示拼图
   @params binngoId  拼图id
   @params callback  动画结束回调
]]
function ActivityBinggoMediator:showBinggoImg(binngoId, callback)
	local viewData  = self:getViewData()
	local puzzleViewData   = viewData.puzzleViewData

	local covers = puzzleViewData.covers
	local cover = covers[binngoId]
	self:updateUnlockCoverBtnState(cover, false)
	self.viewComponent_:showCoverAction(cover, 1, callback)
end

-----------------------------------
-- update

--[[
   更新总任务进度
]]
function ActivityBinggoMediator:updateTaskTotalProgress()
	local viewData  = self:getViewData()
	local taskListViewData = viewData.taskListViewData
	local progressLabel = taskListViewData.progressLabel
	local taskTotalProgress = checkint(self.activityHomeDatas.taskTotalProgress)
	local taskTotalTargetNum = checkint(self.activityHomeDatas.taskTotalTargetNum)
	display.commonLabelParams(progressLabel, {text = string.fmt(__('当前进度 (_progress_/_targetNum_)'), {_progress_ = taskTotalProgress, _targetNum_ = taskTotalTargetNum})})
end

--[[
   更新CEll 显示状态
   @params viewData  视图数据
   @params data      拼图数据
]]
function ActivityBinggoMediator:updateCellState(viewData, data)
	if viewData == nil or nil == data then return end

	local puzzleLabel = viewData.puzzleLabel
	local binggoId    = tostring(data.binggoId)
	display.commonLabelParams(puzzleLabel, {text = string.fmt(__('拼图_num_'), {_num_ = binggoId})})
	
	local descLabel = viewData.descLabel
	local descr = tostring(data.descr)
	local targetNum = checkint(data.target)
	display.commonLabelParams(descLabel, {text = string.fmt(descr, {_target_num_ = targetNum})})

	local progress = checkint(data.progress)
	local progressLabel = viewData.progressLabel
	local commplete = viewData.commplete

	local isComplete = progress >= targetNum
	
	progressLabel:setVisible(not isComplete)
	commplete:setVisible(isComplete)
	if not isComplete then
		display.commonLabelParams(progressLabel, {text = string.format('(%s/%s)', progress, targetNum)})
	end
	
	local bg = viewData.bg
	self.viewComponent_:updateCellBg(bg, isComplete)
end

--[[
   更新拼图 显示状态
]]
function ActivityBinggoMediator:updateBinggoState()
	local viewData         = self:getViewData()
	local puzzleViewData   = viewData.puzzleViewData
	local covers           = puzzleViewData.covers

	local count = 1
	for i,cover in ipairs(covers) do
		local touchView = cover:getChildByName('touchView')
		display.commonUIParams(touchView, {cb = handler(self, self.onClickCoverHandler)})
		local coverState = self.allCoverState[tostring(i)]
		if coverState then
			local isCanOpenCover, isOpenCover = coverState.isCanOpenCover, coverState.isOpenCover
			-- 1.检查是否打开过遮盖
			if isOpenCover then
				-- 2.打开过  
				cover:setVisible(false)
			else
				-- 3.检查能不能开盖
				if isCanOpenCover then
					self.viewComponent_:showClickCoverAction(cover, count)
					count = count + 1
					self:updateUnlockCoverBtnState(cover, false)
				else
					cover:setVisible(true)
					self:updateUnlockCoverBtnState(cover, true, i)
				end
			end
		else
			cover:setVisible(true)
			self:updateUnlockCoverBtnState(cover, true, i)
		end
	end
	-- self.viewComponent_:showCoverAction(covers[1], 1)
	-- self.viewComponent_:showClickCoverAction(covers[2], 1)
	
	self:updateRewardBtn()
	
end

--[[
   更新最终奖励按钮
]]
function ActivityBinggoMediator:updateRewardBtn()
	local viewData  = self:getViewData()
	local puzzleViewData   = viewData.puzzleViewData
	local rewardBtn = puzzleViewData.rewardBtn
	-- 显示最终奖励按钮条件  没领过 并且 打开过所有遮盖
	local isShowRewardBtn = (self.activityHomeDatas.finalRewardsHasDrawn == 0) and self.openCoverCount >= 9
	rewardBtn:setVisible(isShowRewardBtn)
end

--[[
   更新遮盖解锁按钮状态
   @params cover           遮盖
   @params isShow          是否显示遮盖
   @params coverIndex      遮盖下标
]]
function ActivityBinggoMediator:updateUnlockCoverBtnState(cover, isShow, coverIndex)
	if cover == nil then return end
	local unlockCoverLayer = cover:getChildByName('unlockCoverLayer')
	unlockCoverLayer:setVisible(isShow)

	
	if isShow then
		local unlockCoverLayerViewData = unlockCoverLayer.viewData
		local unlockCoverTouchLayer = unlockCoverLayerViewData.unlockCoverTouchLayer
		local unlockCoverImg = unlockCoverLayerViewData.unlockCoverImg
		local unlockCoverTip = unlockCoverLayerViewData.unlockCoverTip
		
		self:GetViewComponent():updateUnlockCoverImg(unlockCoverImg, self.isConsumeDiamondUnlock)

		display.commonUIParams(unlockCoverTouchLayer, {cb = handler(self, self.onClickUnlockCoverAction)})
		unlockCoverTouchLayer:setTag(coverIndex)
		
		local doneOnceConsume = self.activityHomeDatas.doneOnceConsume
		local priceConf = doneOnceConsume[coverIndex] or doneOnceConsume[1]
		
		display.reloadRichLabel(unlockCoverTip, {
			c = {
				fontWithColor(18, {fontSize = 18, text = tonumber(priceConf.num)}),
				{img = CommonUtils.GetGoodsIconPathById(priceConf.goodsId), scale = 0.15} ,
				fontWithColor(18, {fontSize = 18, text = __('解锁')}),
			}
		})
	end
end

--[[
   更新所有遮盖解锁按钮图片
]]
function ActivityBinggoMediator:updateAllCoverUnlockBtnImg()
	local viewData         = self:getViewData()
	local puzzleViewData   = viewData.puzzleViewData
	local covers           = puzzleViewData.covers
	for i, cover in ipairs(covers) do
		local unlockCoverLayer = cover:getChildByName('unlockCoverLayer')
		local unlockCoverLayerViewData = unlockCoverLayer.viewData
		local unlockCoverImg = unlockCoverLayerViewData.unlockCoverImg
		self:GetViewComponent():updateUnlockCoverImg(unlockCoverImg, self.isConsumeDiamondUnlock)
	end
end

-- update
-----------------------------------

-----------------------------------
-- get/set

function ActivityBinggoMediator:getViewData()
	return self.viewData_
end

function ActivityBinggoMediator:checkIsConsumeDiamondUnlock()
	return self.leftSeconds <= self.doneConsumeCD
end

-- get/set
-----------------------------------

function ActivityBinggoMediator:sortAllTask()
	
	local getPriorityByData = function (data)
		local priority = 0
		
		local target = checkint(data.target)
		local progress = checkint(data.progress)

		if progress < target then
			priority = priority + 1
		end

		return priority
	end

	local sortfunction = function (a, b)
		if a == nil then return true end
		if b == nil then return false end
		
		local aPriority = getPriorityByData(a)
		local bPriority = getPriorityByData(b)

		local aBinggoId = checkint(a.binggoId)
		local bBinggoId = checkint(b.binggoId)
		if aPriority == bPriority then
			return aBinggoId < bBinggoId
		end
		return aPriority > bPriority
	end

	table.sort(self.allTasks, sortfunction)
end

-----------------------------------
-- regist/unRegist
function ActivityBinggoMediator:OnRegist() 
	local ActivityCommand = require('Game.command.ActivityCommand')
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Activity_BinggoOpen, ActivityCommand)

	self.hasSignal = self:GetFacade():HasSignal(COMMANDS.COMMAND_Activity_Draw_BinggoTask)
	
	-- 如果 没注册的话  则注册
	if not self.hasSignal then
		self:GetFacade():RegistSignal(COMMANDS.COMMAND_Activity_Draw_BinggoTask, ActivityCommand)
	end
end

function ActivityBinggoMediator:OnUnRegist()
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Activity_BinggoOpen)

	-- 在此 Mediator 注册成功才解除
	if not self.hasSignal then
		self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Activity_Draw_BinggoTask)
	end

	self.curScene_:RemoveDialog(self.viewComponent_)
	timerMgr:RemoveTimer(NAME)
end
-- regist/unRegist
-----------------------------------

return ActivityBinggoMediator
