--[[
 * author : liuzhipeng
 * descpt : 特殊活动 拼图活动页签mediator
]]
local SpActivityBinggoPageMediator = class('SpActivityBinggoPageMediator', mvc.Mediator)

local CreateView = nil
local SpActivityBinggoPageView = require("Game.views.specialActivity.SpActivityBinggoPageView")
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager('GameManager')
function SpActivityBinggoPageMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'SpActivityBinggoPageMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance method

function SpActivityBinggoPageMediator:Initial(key)
    self.super.Initial(self, key)
    self.ownerNode_ = self.ctorArgs_.ownerNode
    self.typeData_  = self.ctorArgs_.typeData

    -- create view
    if self.ownerNode_ then
        local size = self.ownerNode_:getContentSize()
        local view = SpActivityBinggoPageView.new({size = size})
        display.commonUIParams(view, {po = cc.p(size.width * 0.5, size.height * 0.5)})
        self.ownerNode_:addChild(view,19)
        self:SetViewComponent(view)
        local viewData = self.viewComponent.viewData
        viewData.gridView:setDataSourceAdapterScriptHandler(handler(self, self.onBinggoActivityDataSource))
        viewData.enterBtn:setOnClickScriptHandler(handler(self, self.enterBinggoMediator))
    end
end


function SpActivityBinggoPageMediator:CleanupView()
    if self.ownerNode_ then
        if self.viewComponent and self.viewComponent:getParent() then
            self.viewComponent:runAction(cc.RemoveSelf:create())
            self.viewComponent = nil
        end
        self.ownerNode_ = nil
    end
end


function SpActivityBinggoPageMediator:OnRegist()
	regPost(POST.ACTIVITY_BINGGO_DRAW_TASK)
end
function SpActivityBinggoPageMediator:OnUnRegist()
	unregPost(POST.ACTIVITY_BINGGO_DRAW_TASK)
end


function SpActivityBinggoPageMediator:InterestSignals()
    local signals = {
        POST.ACTIVITY_BINGGO_DRAW_TASK.sglName,
	}
	return signals
end
function SpActivityBinggoPageMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local body = signal:GetBody()
	if name == POST.ACTIVITY_BINGGO_DRAW_TASK.sglName then
		local datas = checktable(signal:GetBody())
		local requestData = datas.requestData
		local requestType = requestData.type
		local activityId = requestData.activityId
		if requestType == 1 then
			local rewards = datas.rewards or {}
			if #rewards > 0 then
				uiMgr:AddDialog('common.RewardPopup', {rewards = rewards})
			end

			-- 更新宝箱状态
			local activityHomeData = self.typeData_
			if activityHomeData == nil  then return end

			local index     = requestData.index
			local homeData  = activityHomeData.homeDatas
			if homeData and homeData.allGroupTask and homeData.allGroupTask[index] then
				local groupTaskData = homeData.allGroupTask[index]
				groupTaskData.hasDrawn = true
				-- homeData.taskTotalProgress = homeData.taskTotalProgress + 1
				-- 领过组任务 则 减一
				homeData.canReceiveGroupTaskCount = homeData.canReceiveGroupTaskCount - 1
				self:binggoGroupTaskSort(homeData.allGroupTask)
				self:updateBinggoActivity(activityId)

				-- self:checkBinggoRedPoint(activityId)
			end
		end
    end
end


-------------------------------------------------
-- handler method

-------------------------------------------------
-- get /set
-------------------------------------------------
-- private method
--[[
刷新页面
--]]
function SpActivityBinggoPageMediator:RefreshView()
    local viewComponent = self:GetViewComponent()
    local viewData = viewComponent.viewData
	local homeData = self.homeData_
	local skinId = homeData.finalRewards[1].goodsId
	local finalRewardsHasDrawn = homeData.finalRewardsHasDrawn
	viewComponent:updateRoleImg(finalRewardsHasDrawn ~= 0, skinId)

	local gridView = viewData.gridView
	gridView:setCountOfCell(#homeData.allGroupTask)
	gridView:reloadData()
end
function SpActivityBinggoPageMediator:updateBinggoActivity(activityId)
    local viewComponent = self:GetViewComponent()
    local viewData = viewComponent.viewData
	local homeData = self.homeData_
	local skinId = homeData.finalRewards[1].goodsId
	local finalRewardsHasDrawn = homeData.finalRewardsHasDrawn
	viewComponent:updateRoleImg(finalRewardsHasDrawn ~= 0, skinId)

	local gridView = viewData.gridView
	gridView:setCountOfCell(#homeData.allGroupTask)
	gridView:reloadData()
end
function SpActivityBinggoPageMediator:enterBinggoMediator(sender)
	PlayAudioByClickNormal()
	local activityId = checkint(self.typeData_.activityId)
	local activityHomeDatas = self.typeData_
    local homeDatas = self.homeData_
    local leftSeconds = checkint(activityHomeDatas.closeTimestamp_) - os.time()
    local endStoryId = homeDatas.endStoryId

	local enterView = function ()
		local mediator = require( 'Game.mediator.ActivityBinggoMediator').new({data = {
			activityId = activityId, activityHomeDatas = homeDatas,
			leftSeconds = leftSeconds, endStoryId = endStoryId}})
		self:GetFacade():RegistMediator(mediator)
	end
	if checkint(homeDatas.startStoryId) > 0 then
		app.activityMgr:ShowActivityStory({
			activityId = activityId,
			storyId = homeDatas.startStoryId,
			storyType = 'START',
			callback = enterView
		})
	else
		enterView()
	end
end

function SpActivityBinggoPageMediator:onBinggoActivityDataSource(p_convertview, idx)
	local pCell = p_convertview
    local index = idx + 1
    -- local size = cc.size(212, 88)
	local activityHomeData = self.typeData_
	if activityHomeData == nil then return end

	if pCell == nil then
        pCell = require("home.ActivityBinggoCell").new()
		display.commonUIParams(pCell:getViewData().boxLayer, {cb = handler(self, self.onDrawBinggoTaskAction), animate = false})
	end

	xTry(function()
		local viewData      = pCell:getViewData()

		local homeData      = activityHomeData.homeDatas
		if homeData and homeData.allGroupTask and homeData.allGroupTask[index] then
			local groupData  = homeData.allGroupTask[index]

			local descLabel     = viewData.descLabel
			display.commonLabelParams(descLabel, {text = string.fmt(__('完成拼图_desc_任务'), {_desc_ = tostring(groupData.desc)})})

			local progressLabel = viewData.progressLabel

			local groupTaskProgress = groupData.groupTaskProgress
			local groupTaskTargetNum = groupData.groupTaskTargetNum
			local hasDrawn  = groupData.hasDrawn

			local bgBlack = viewData.bgBlack
			bgBlack:setVisible(hasDrawn)

			local c = nil
			local isCompleteProgress = groupTaskProgress >= groupTaskTargetNum
			if hasDrawn then
				c = {
					fontWithColor(16, {text = string.format("(%s/%s)", groupTaskProgress, groupTaskTargetNum)})
				}
			elseif isCompleteProgress then
				c = {
					fontWithColor(16, {text = string.format("(%s/%s)", groupTaskProgress, groupTaskTargetNum)})
				}
			else
				c = {
					fontWithColor(16, {text = "("}),
					fontWithColor(10, {fontSize = 22, text = groupTaskProgress}),
					fontWithColor(16, {text = string.format( "/%s)", groupTaskTargetNum)}),
				}
			end

			display.reloadRichLabel(progressLabel, {c = c})

			local boxLayer = viewData.boxLayer
			boxLayer:setTag(index)
			self:updateBoxState(viewData, hasDrawn, isCompleteProgress)
		end


	end,__G__TRACKBACK__)

	return pCell
end

function SpActivityBinggoPageMediator:updateBoxState(viewData, hasDrawn, isCompleteProgress)
	local rewardBox = viewData.rewardBox

	rewardBox:setToSetupPose()
	if hasDrawn then
		rewardBox:setAnimation(0, 'play', true)
	elseif isCompleteProgress then
		rewardBox:setAnimation(0, 'idle', true)
	else
		rewardBox:setAnimation(0, 'stop', true)
	end
end

function SpActivityBinggoPageMediator:onDrawBinggoTaskAction(sender)
	PlayAudioByClickNormal()
	local index = sender:getTag()
	local activityHomeData = self.typeData_
	if activityHomeData == nil  then return end

	local homeData      = activityHomeData.homeDatas

	if homeData and homeData.allGroupTask and homeData.allGroupTask[index] then

		local groupTaskData = homeData.allGroupTask[index]
		local hasDrawn  = groupTaskData.hasDrawn
		local groupTaskProgress = groupTaskData.groupTaskProgress
		local groupTaskTargetNum = groupTaskData.groupTaskTargetNum
		if hasDrawn then
			uiMgr:ShowInformationTips(__('该奖励已领取'))
		elseif groupTaskProgress >= groupTaskTargetNum then
			self:SendSignal(POST.ACTIVITY_BINGGO_DRAW_TASK.cmdName, {activityId = checkint(self.typeData_.activityId), type = 1, taskGroupId = checkint(groupTaskData.groupId), index = index})
		else
			local rewards = groupTaskData.rewards or {}
			uiMgr:ShowInformationTipsBoard({targetNode = sender, iconIds = rewards, type = 4})
		end
	end

end

function SpActivityBinggoPageMediator:initBinggoActivityData(datas)
	local temp = {}
	-- 保存 所有拼图对应的任务 格式：[1] = {{}, {}}
	local binggoTasks = {}
	-- 保存所有 组任务
	local allGroupTask = {}
	-- 总任务进度
	local taskTotalProgress = 0
	-- 总任务所需进度
	local taskTotalTargetNum = 0
	-- 能领取组任务的奖励个数
	local canReceiveGroupTaskCount = 0
	-- 能翻牌的个数
	local canOpenCoverCount = 0
	-- 剩余遮盖个数
	local surplusCoverCount = 0

	for groupId,groupData in pairs(datas.allTask) do
		groupData.groupId = groupId
		local desc = ''
		local groupTask = groupData.tasks

		local groupTaskTargetNum = #groupTask
		local groupTaskProgress = 0

		for i = 1, groupTaskTargetNum do
			local task = groupTask[i]
			local binggoId = checkint(task.binggoId)
			desc = desc .. task.binggoId
			if i ~= groupTaskTargetNum then
				desc = desc .. '.'
			end
			task.desc = desc

			local progress = checkint(task.progress)
			local target = checkint(task.target)
			if temp[task.taskId] == nil then
				taskTotalTargetNum = taskTotalTargetNum + 1

				local isCompleteProgress = progress >= target
				if isCompleteProgress then
					taskTotalProgress = taskTotalProgress + 1
				end

				-- 没翻过牌子  并且 进度完成  添加红点
				if checkint(task.isBinggoOpen) == 0 then
					surplusCoverCount = surplusCoverCount + 1
					if isCompleteProgress then
						canOpenCoverCount = canOpenCoverCount + 1
					end
				end

				binggoTasks[binggoId] = binggoTasks[binggoId] or {}
				table.insert(binggoTasks[binggoId], task)
			end

			if progress >= target then
				groupTaskProgress = groupTaskProgress + 1
			end

			temp[task.taskId] = true
		end

		-- 没领取过组任务奖励 并且 组任务完成 添加红点
		if not groupData.hasDrawn and groupTaskProgress >= groupTaskTargetNum then
			canReceiveGroupTaskCount = canReceiveGroupTaskCount + 1
		end

		groupData.groupTaskTargetNum = groupTaskTargetNum
		groupData.groupTaskProgress  = groupTaskProgress
		groupData.desc = desc

		table.insert(allGroupTask, groupData)
	end

	datas.binggoTasks = binggoTasks
	datas.allGroupTask = allGroupTask
	datas.taskTotalProgress = taskTotalProgress
	datas.taskTotalTargetNum = taskTotalTargetNum
	datas.canReceiveGroupTaskCount = canReceiveGroupTaskCount
	datas.canOpenCoverCount = canOpenCoverCount
	datas.surplusCoverCount = surplusCoverCount
	-- print(canReceiveGroupTaskCount, canOpenCoverCount, surplusCoverCount, 'dhhohdacoiwe')
	return datas
end

function SpActivityBinggoPageMediator:checkBinggoRedPoint(activityId)
	-- local activityHomeData = self.typeData_
	-- if activityHomeData == nil then return end

	-- local homeDatas = activityHomeData.homeDatas
	-- if homeDatas == nil then return end

	-- local canReceiveGroupTaskCount = checkint(homeDatas.canReceiveGroupTaskCount)
	-- local canOpenCoverCount = checkint(homeDatas.canOpenCoverCount)
	-- local finalRewardsHasDrawn = checkint(homeDatas.finalRewardsHasDrawn)
	-- local surplusCoverCount = checkint(homeDatas.surplusCoverCount)

	-- -- 外部红点
	-- local externalRedPoint = canReceiveGroupTaskCount > 0
	-- -- 内部红点
	-- local insideRedPoint = (canOpenCoverCount > 0 or (finalRewardsHasDrawn == 0 and surplusCoverCount == 0))
	-- -- 总红点
	-- app.badgeMgr:SetActivityTipByActivitiyId(activityId, (externalRedPoint or insideRedPoint) and 1 or 0)

	-- for i,v in ipairs(self.activityTabDatas) do
	-- 	if v.type == ACTIVITY_TYPE.BINGGO and tostring(activityId) == tostring(v.activityId) then
	-- 		v.showRemindIcon = gameMgr:GetUserInfo().binggoTask[tostring(activityId)]
	-- 		local gridView = self:GetViewComponent().viewData.gridView
	-- 		local cell = gridView:cellAtIndex(i-1)
	-- 		if cell then
	-- 			cell.tipsIcon:setVisible(v.showRemindIcon == 1)
	-- 		end
	-- 		break
	-- 	end
	-- end

	-- local view = self.showLayer[tostring(activityId)]
	-- if view then
	-- 	local viewData = view:getViewData()
	-- 	local redPoint = viewData.enterBtn:getChildByName('BTN_RED_POINT')
	-- 	redPoint:setVisible(insideRedPoint)
	-- end
end

function SpActivityBinggoPageMediator:binggoGroupTaskSort(allGroupTask)

	local getPriorityByData = function (data)
		local priority = 0
		if not data.hasDrawn then
			local groupTaskTargetNum = data.groupTaskTargetNum
			local groupTaskProgress = data.groupTaskProgress

			if groupTaskProgress >= groupTaskTargetNum then
				priority = priority + 1
			end
			priority = priority + 1
		else
			priority = 0
		end

		return priority
	end

	local sortfunction = function (a, b)
		if a == nil then return true end
		if b == nil then return false end

		local aPriority = getPriorityByData(a)
		local bPriority = getPriorityByData(b)

		local aGroupId = a.groupId
		local bGroupId = b.groupId
		if aPriority == bPriority then
			return aGroupId < bGroupId
		end

		return aPriority > bPriority
	end
	table.sort( allGroupTask, sortfunction )
end

-------------------------------------------------
-- public method
function SpActivityBinggoPageMediator:resetHomeData(homeData)
	local realDatas = self:initBinggoActivityData(homeData)
	self:binggoGroupTaskSort(realDatas.allGroupTask)

	realDatas.doneConsumeDayCount = (realDatas.doneConsumeTime - self.typeData_.fromTime) / 86400 + 1
	realDatas.doneConsumeCD = self.typeData_.toTime - realDatas.doneConsumeTime
	self.typeData_.homeDatas = realDatas
    self.homeData_ = homeData
    self:RefreshView()
end


return SpActivityBinggoPageMediator
