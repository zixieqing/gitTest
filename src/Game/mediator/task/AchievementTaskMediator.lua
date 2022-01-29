--[[
    成就任务Mediator
]]
local Mediator = mvc.Mediator
local AchievementTaskMediator = class("AchievementTaskMediator", Mediator)

local NAME = "task.AchievementTaskMediator"
AchievementTaskMediator.NAME = NAME

local uiMgr               = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr             = AppFacade.GetInstance():GetManager("GameManager")

local TaskCell            = require('home.NewRankCell')
local ItemCell            = require('Game.views.summerActivity.carnie.CarnieRankChildCell')
local AchievementTaskView = require('Game.views.task.AchievementTaskView')

local TASK_CONFS          = CommonUtils.GetConfigAllMess('task', 'task')


local RECENTLY_COMPLETED_TASK_SORT_ID  = '0'  -- 最近完成大类id
local RECENTLY_COMPLETED_TASK_GROUP_ID = '0'  -- 最近完成小类id
local OTHER              = checktable(TASK_CONFS['1']).taskSort or '4'  -- 其他

local MAX_ACHIEVELEVEL = table.nums(CommonUtils.GetConfigAllMess('achieveLevel','task'))  -- 最大成就等级

-- 特殊任务类型需要 双条件判断
local SPECIAL_TASK_TYPE = 127   -- 创角超过365天，且主角等级达到100级

function AchievementTaskMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    self.ctorArgs_ = checktable(params)

    self.viewTag           = self.ctorArgs_.viewTag

    self.tastDatas         = {} --成就任务数据
    self.selectModel       = 0 --成就选择大类
    self.selectSecondModel = 0 --成就选择小类
    self.defClickListTag   = self.ctorArgs_.defClickListTag or RECENTLY_COMPLETED_TASK_SORT_ID
    self.canGetTaskReward  = false -- 是否可领取成就升级奖励
    
    self.taskRewardCount   = 0     -- 成就任务中可领取的奖励个数  (用于红点判断)

    self.rewardsLayer      = 10000
end

-------------------------------------------------
-- inheritance method

function AchievementTaskMediator:Initial(key)
    self.super.Initial(self, key)

    self.isControllable_ = true
    
    -- create view
    local viewComponent = AchievementTaskView.new()
    self.viewData_ = viewComponent:getViewData()
    self:SetViewComponent(viewComponent)

    -- inti data
    self:initData()
    -- init view
    self:initView()
end

function AchievementTaskMediator:initData()

    local taskGroupConf = CommonUtils.GetConfigAllMess('taskSmallClass', 'task') or {}
    local taskGroupKeys = {}
    for k, taskGroup in pairs(taskGroupConf) do
        local belongId = taskGroup.belongId
        taskGroupKeys[tostring(belongId)] = taskGroupKeys[tostring(belongId)] or {}
        table.insert(taskGroupKeys[tostring(belongId)], taskGroup)

    end

    local sortFunc = function (a, b)
        if a == nil then return true end
        if b == nil then return false end

        return checkint(a.id) < checkint(b.id)
    end

    local taskSortConf      = CommonUtils.GetConfigAllMess('taskClass', 'task') or {}

    self.taskSortTabData    = {{id = RECENTLY_COMPLETED_TASK_SORT_ID, name = __('最近完成')}}
    for i, taskSort in pairs(taskSortConf) do
        local id = taskSort.id
        local data = {id = id, name = taskSort.name}
        local taskGroupData = taskGroupKeys[tostring(id)]
        if taskGroupData then
            table.sort(taskGroupData, sortFunc)
            data.taskGroupData = taskGroupData
        end
        table.insert(self.taskSortTabData, data)   
    end
    table.sort(self.taskSortTabData, sortFunc)
    
end

function AchievementTaskMediator:initAchieveData(body)
    self.tastDatas = {
        [RECENTLY_COMPLETED_TASK_SORT_ID] = {
            [RECENTLY_COMPLETED_TASK_GROUP_ID] = {}
        }
    }
    self.canReceiveCounts = {
        [RECENTLY_COMPLETED_TASK_SORT_ID] = {
            taskSortReceiveCount = 0,
            [RECENTLY_COMPLETED_TASK_GROUP_ID] = {
                taskGroupRedReceiveCount = 0
            }
        }
    }

    local serverTaskDatas    = body.tasks or {}
    local taskGroupTimeDatas = body.taskGroupTime or {}

    local function listToMap(list, mapField)
        local map = {}
        for i,v in ipairs(list) do
            map[tostring(v[mapField])] = v
        end
        return map
    end

    local curLv = gameMgr:GetUserInfo().level
    local serverDataMap = listToMap(serverTaskDatas, 'taskId')
    local taskGroupDatas = {}
    local serTaskGroupDatas = {}
    for taskId, taskConf in pairs(TASK_CONFS) do
        local taskId      = tostring(taskConf.id)
        local taskSort    = tostring(taskConf.taskSort)
        local taskGroup   = tostring(taskConf.taskGroup)
        local groupId     = tostring(taskConf.groupId)
        local afterTaskId = tostring(taskConf.afterTaskId)
        local openLv      = checkint(taskConf.openLevel)

        self.tastDatas[taskSort] = self.tastDatas[taskSort] or {}
        self.tastDatas[taskSort][taskGroup] = self.tastDatas[taskSort][taskGroup] or {}

        self.canReceiveCounts[taskSort] = self.canReceiveCounts[taskSort] or {}
        self.canReceiveCounts[taskSort].taskSortReceiveCount = self.canReceiveCounts[taskSort].taskSortReceiveCount or 0
        self.canReceiveCounts[taskSort][taskGroup] = self.canReceiveCounts[taskSort][taskGroup] or {}
        self.canReceiveCounts[taskSort][taskGroup].taskGroupRedReceiveCount = self.canReceiveCounts[taskSort][taskGroup].taskGroupRedReceiveCount or 0

        local serverData = serverDataMap[taskId]
        if serverData then
            serTaskGroupDatas[groupId] = taskId
            local dataFormat = {serverData = serverData, conf = taskConf, showComplete = 0, taskId = taskId}

            local progress = checkint(serverData.progress)
            local targetNum = checkint(taskConf.targetNum)

            -- 添加最近完成的数据
            if targetNum > 0 and progress >= targetNum then
                self.canReceiveCounts[taskSort].taskSortReceiveCount = self.canReceiveCounts[taskSort].taskSortReceiveCount + 1
                self.canReceiveCounts[RECENTLY_COMPLETED_TASK_SORT_ID].taskSortReceiveCount = self.canReceiveCounts[RECENTLY_COMPLETED_TASK_SORT_ID].taskSortReceiveCount + 1

                self.canReceiveCounts[taskSort][taskGroup].taskGroupRedReceiveCount = self.canReceiveCounts[taskSort][taskGroup].taskGroupRedReceiveCount + 1
                self.canReceiveCounts[RECENTLY_COMPLETED_TASK_SORT_ID][RECENTLY_COMPLETED_TASK_GROUP_ID].taskGroupRedReceiveCount = self.canReceiveCounts[RECENTLY_COMPLETED_TASK_SORT_ID][RECENTLY_COMPLETED_TASK_GROUP_ID].taskGroupRedReceiveCount + 1

                table.insert(self.tastDatas[RECENTLY_COMPLETED_TASK_SORT_ID][RECENTLY_COMPLETED_TASK_GROUP_ID], dataFormat)
            end

            table.insert(self.tastDatas[taskSort][taskGroup], dataFormat)

        end

        -- 如果该组是最后一个任务 并且 玩家等级大于开放等级 则 保存一次数据
        if afterTaskId == '' and curLv >= openLv then
            taskGroupDatas[groupId] = taskId
        end

    end

    for groupId,taskId in pairs(taskGroupDatas) do
        -- 如果服务端发送的 数据中没有该 groupId  则插入任务完成状态
        if not serTaskGroupDatas[groupId] then
            local taskConf      = TASK_CONFS[tostring(taskId)]
            local taskSort      = tostring(taskConf.taskSort)
            local taskGroup     = tostring(taskConf.taskGroup)
            local serverData    = {progress = taskConf.targetNum, taskId = taskId, taskSort = taskSort, taskGroup = taskGroup}
            local dataFormat    = {serverData = serverData, conf = taskConf, showComplete = 1, taskId = taskId}
            table.insert(self.tastDatas[taskSort][taskGroup], dataFormat)
        end
    end

    local sortFunc = function (a, b)
        if a == nil then return true end
        if b == nil then return false end

        local aServerData = a.serverData
        local bServerData = b.serverData
        local aTaskConf   = a.conf
        local bTaskConf   = b.conf

        if a.showComplete == b.showComplete then
            return checkint(a.taskId) < checkint(b.taskId)
        end
        return a.showComplete < b.showComplete
    end

    for taskSort, taskSortData in pairs(self.tastDatas) do
        for taskGroup,taskGroupData in pairs(taskSortData) do
            table.sort(taskGroupData, sortFunc)
        end
    end

    
end

function AchievementTaskMediator:initView()
    local viewData = self:getViewData()
    local achieveRewardLayer = viewData.achieveRewardLayer
    display.commonUIParams(achieveRewardLayer, {cb = handler(self, self.onClickAchieveLvRewardAction)})

    self:initExpandableListView()

    self:initTaskList()
end

function AchievementTaskMediator:initExpandableListView()
    local viewData = self:getViewData()
    local expandableListView = viewData.expandableListView
    local size = cc.size(198, 86)
    for i, taskSortData in ipairs(self.taskSortTabData) do
        local expandableNode = TaskCell.new(size)
        expandableNode:setName('expandableNode' .. i)
        local button = expandableNode.button
        local id = taskSortData.id
        if button then
            button:setOnClickScriptHandler(handler(self, self.onCkickTabBtnAction))
            button:setUserTag(id)
            button:setTag(i)

            local buttonSize = button:getContentSize()
            local redPointImg = self:GetViewComponent():CreateRedPointImg()
            display.commonUIParams(redPointImg, {po = cc.p(buttonSize.width + 5, buttonSize.height + 5), ap = display.RIGHT_TOP})
            redPointImg:setScale(0.65)
            button:addChild(redPointImg)
            expandableNode.redPointImg = redPointImg

            if checkint(id) == checkint(self.defClickListTag) then
                self.selectModel = i
                self:GetViewComponent():updateTabShowState(button, true)
            end
        end

        local nameLabel = expandableNode.nameLabel
        if nameLabel then
            display.commonLabelParams(expandableNode.nameLabel, {text = tostring(taskSortData.name)})
        end

        local taskGroupData = taskSortData.taskGroupData
        if taskGroupData and next(taskGroupData) ~= nil then
            expandableNode.arrowIcon:setVisible(true)

            for itemIndex, itemData in ipairs(taskGroupData) do
                local childSize = cc.size(size.width, 60)
                local childNode = ItemCell.new(childSize)
                childNode:setName('childNode' .. itemIndex)
                local bgBtn     = childNode.bgBtn
                display.commonLabelParams(bgBtn, fontWithColor(14, {text = tostring(itemData.name)}))
                bgBtn:setOnClickScriptHandler(handler(self, self.onCkickItemBtnAction))
                bgBtn:setUserTag(itemData.id)
                bgBtn:setTag(itemIndex)

                local bgBtnSize = bgBtn:getContentSize()
                local redPointImg = self:GetViewComponent():CreateRedPointImg()
                display.commonUIParams(redPointImg, {po = cc.p(bgBtnSize.width + 5, bgBtnSize.height + 5), ap = display.RIGHT_TOP})
                redPointImg:setScale(0.5)
                bgBtn:addChild(redPointImg)
                childNode.redPointImg = redPointImg

                expandableNode:insertItemNodeAtLast(childNode)
            end
        end

        expandableListView:insertExpandableNodeAtLast(expandableNode)
    end
    expandableListView:reloadData()

end

function AchievementTaskMediator:initTaskList()
    local viewData = self:getViewData()
    local taskList = viewData.taskList

    taskList:setDataSourceAdapterScriptHandler(handler(self,self.onAchieveDataSourceAction))
end

function AchievementTaskMediator:CleanupView()
    
end

function AchievementTaskMediator:OnRegist()
    local DailyTaskCommand = require( 'Game.command.DailyTaskCommand')
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_MainTask, DailyTaskCommand)
    self:GetFacade():RegistSignal(COMMANDS.COMMAND_MainTask_Get, DailyTaskCommand)
    regPost(POST.TASK_ACHIEVE_LEVEL_UP)

    self:enterLayer()
end
function AchievementTaskMediator:OnUnRegist()
    self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_MainTask)
    self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_MainTask_Get)
    unregPost(POST.TASK_ACHIEVE_LEVEL_UP)
end

function AchievementTaskMediator:InterestSignals()
    return {
        SIGNALNAMES.MainTask_Message_Callback,
        SIGNALNAMES.MainTask_Get_Callback,
        POST.TASK_ACHIEVE_LEVEL_UP.sglName,

        SGL.FRESH_ACHIEVEMENT_VIEW
    }
end

function AchievementTaskMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local body = checktable(signal:GetBody())

    if name == SIGNALNAMES.MainTask_Message_Callback then
        self.isControllable_ = false
        app.badgeMgr:initAchievementCacheData(body)
        self:initAchieveData(body)
        self:updateView()
        self.isControllable_ = true
    elseif name == SIGNALNAMES.MainTask_Get_Callback then
        -- 更新奖励
		local mainExp            = checkint(body.mainExp)
		local rewards            = checktable(body.rewards)
		local increaseAchieveExp = checkint(body.increaseAchieveExp)
        uiMgr:AddDialog('common.RewardPopup', {rewards = rewards, mainExp = mainExp, tag = self.rewardsLayer})
        gameMgr:UpdateAchieveExp(increaseAchieveExp)
        self:updateAchieveExp()

        local requestData    = checktable(body.requestData)
        local index          = requestData.index
        local afterTaskId    = body.afterTaskId
        local curTaskData    = self.curTaskList[index]
        if afterTaskId ~= '' then
			-- 1.1 获取后一个任务的配表数据
			local afterTaskData = TASK_CONFS[tostring(afterTaskId)]
			-- 1.2. 替换当前任务数据中 配表数据
			curTaskData.conf = afterTaskData
			-- 1.3. 替换当前任务数据中 taskId
			curTaskData.serverData.taskId = afterTaskId
			curTaskData.taskId = afterTaskId
		else
		-- 2. 否则 显示成就完成状态
			curTaskData.showComplete = 1
        end

        local taskProgress = checktable(body.taskProgress)
        self:updateTaskProgress(taskProgress)

        local oldTaskId   = requestData.taskId
        local curTaskConf = curTaskData.conf
		local taskSort    = tostring(curTaskConf.taskSort)
		local taskGroup   = tostring(curTaskConf.taskGroup)
		local serverData  = curTaskData.serverData
		local progress    = checkint(serverData.progress)
        local targetNum   = checkint(curTaskConf.targetNum)
        local taskId      = curTaskData.taskId

        -- 检查 选择的 task sort id 是不是最近完成
        local taskSortData = self.taskSortTabData[self.selectModel]
        local taskSortId = self:getTaskSortId(self.selectModel)
        if taskSortId == RECENTLY_COMPLETED_TASK_SORT_ID then
            self:updateTaskData(taskSort, taskGroup, oldTaskId, curTaskData)

            if curTaskData.showComplete == 1 or progress < targetNum then
                self:clearRedPointData(RECENTLY_COMPLETED_TASK_SORT_ID, RECENTLY_COMPLETED_TASK_GROUP_ID)
                self:clearRedPointData(taskSort, taskGroup)
                
				table.remove(self.curTaskList, index)
                self:GetViewComponent():updateTaskList(self.curTaskList)
            else
                self:updateCurTaskListCell(index, curTaskData)
            end
        else
            -- 更新 最近完成数据
            self:updateTaskData(RECENTLY_COMPLETED_TASK_SORT_ID, RECENTLY_COMPLETED_TASK_GROUP_ID, oldTaskId, curTaskData)

            -- 移除 最近完成数据
			if curTaskData.showComplete == 1 or progress < targetNum then
				self:clearRedPointData(RECENTLY_COMPLETED_TASK_SORT_ID, RECENTLY_COMPLETED_TASK_GROUP_ID)
                self:clearRedPointData(taskSort, taskGroup)
                
                -- 更新最近完成数据
				local recentlyCompletedList = self.tastDatas[RECENTLY_COMPLETED_TASK_SORT_ID][RECENTLY_COMPLETED_TASK_GROUP_ID]
				for i=#recentlyCompletedList, 1, -1 do
					if recentlyCompletedList[i].taskId == taskId then
						table.remove(recentlyCompletedList, i)
						break
					end
				end
            end
            
            -- 更新当前视图UI
			self:updateCurTaskListCell(index, curTaskData)
        end
        
        local totalRedPointCount = self:updateRedPointData()

        self:updateAchievementCacheData(oldTaskId, taskId, curTaskData.showComplete, totalRedPointCount)
        
        self:updateExternalTabRedPoint()

        self.isControllable_ = true
    elseif name == POST.TASK_ACHIEVE_LEVEL_UP.sglName then
        gameMgr:GetUserInfo().achieveLevel = math.min( gameMgr:GetUserInfo().achieveLevel + 1, MAX_ACHIEVELEVEL)
        uiMgr:AddDialog('common.RewardPopup', {rewards = signal:GetBody().rewards,tag = self.rewardsLayer})
        self:updateAchieveExp()

    elseif name == SGL.FRESH_ACHIEVEMENT_VIEW then
        self:initAchieveData(body)
        self:updateView()
    end
    
end

function AchievementTaskMediator:enterLayer()
    self:SendSignal(COMMANDS.COMMAND_MainTask)
end

--==============================--
--desc: 刷新成就任务界面
--time:2018-01-05 03:25:00
--@return 
--==============================-- 
function AchievementTaskMediator:updateView()
    self:updateAchieveExp()

    self:updateRedPointData()

    self:updateExternalTabRedPoint()

    self:updateTaskList()
end

function AchievementTaskMediator:updateSencondTab(item, isSelect)
    if item and item.bgBtn then
        self:GetViewComponent():updateSencondTabShowState(item.bgBtn, isSelect)
    end
end

--==============================--
--desc: 更新红点数据
--==============================--
function AchievementTaskMediator:updateAchievementCacheData(oldTaskId, taskId, showComplete, totalRedPointCount)
    gameMgr:GetUserInfo().achievementCacheData_.canReceiveCount = checkint(totalRedPointCount)
    -- 移除旧的 任务id
    if gameMgr:GetUserInfo().achievementCacheData_.unreceivedTaskList[tostring(oldTaskId)] then
        gameMgr:GetUserInfo().achievementCacheData_.unreceivedTaskList[tostring(oldTaskId)] = nil
    end
    -- 添加新的 任务id 
    if showComplete ~= 1 then
        gameMgr:GetUserInfo().achievementCacheData_.unreceivedTaskList[tostring(taskId)] = tostring(taskId)
    end
end

function AchievementTaskMediator:updateRedPointData()
    local viewData = self:getViewData()
    local expandableListView = viewData.expandableListView

    local totalRedPointCount = 0
    for taskSortIndex, taskSortData in ipairs(self.taskSortTabData) do
        local taskSortId = taskSortData.id
        local taskGroupData = taskSortData.taskGroupData

        -- warn: 不用判空 下标不对会直接报错
        -- 1.更新大类红点状态
        local expandableNode = expandableListView:getExpandableNodeAtIndex(taskSortIndex - 1)
        local taskSortRedPointData = self.canReceiveCounts[tostring(taskSortId)] or {}
        local taskSortReceiveCount = checkint(taskSortRedPointData.taskSortReceiveCount)
        local redPointImg = expandableNode.redPointImg
        redPointImg:setVisible(taskSortReceiveCount > 0)

        totalRedPointCount = totalRedPointCount + taskSortReceiveCount
        -- 2.更新小类红点状态
        if taskGroupData and next(taskGroupData) ~= nil then
            for itemIndex, itemData in ipairs(taskGroupData) do
                local taskGroupId = itemData.id
                local item = expandableNode:getItemNodeAtIndex(itemIndex - 1)
                local taskGroupRedPointData = taskSortRedPointData[tostring(taskGroupId)] or {}
                local taskGroupRedReceiveCount = checkint(taskGroupRedPointData.taskGroupRedReceiveCount)
                local redPointImg = item.redPointImg
                redPointImg:setVisible(taskGroupRedReceiveCount > 0)
            end
        end
    end
    -- gameMgr:GetUserInfo().achievementCacheData_.canReceiveCount = totalRedPointCount

    -- self:updateExternalTabRedPoint()
    return totalRedPointCount
end

function AchievementTaskMediator:updateExternalTabRedPoint()
    self:GetFacade():DispatchObservers('TASK_UPDATE_EXTERNAL_TAB_RED_POINT', {viewTag = self.viewTag})
end

--==============================--
--desc: 更新任务列表
--==============================--
function AchievementTaskMediator:updateTaskList()
    
    local taskSortData = self.taskSortTabData[self.selectModel]
    local taskSortId = tostring(taskSortData.id)
    local taskGroupData = taskSortData.taskGroupData
    local taskGroupId = RECENTLY_COMPLETED_TASK_GROUP_ID
    self.curTaskList = nil
    if taskGroupData and next(taskGroupData) ~= nil then
        local GroupData = taskGroupData[self.selectSecondModel]
        taskGroupId = tostring(GroupData.id)
    end
    self.curTaskList = checktable(self.tastDatas[taskSortId])[taskGroupId] or {}
    
    self:GetViewComponent():updateTaskList(self.curTaskList)
end

--==============================--
--desc: 更新任务数据
--==============================--
function AchievementTaskMediator:updateTaskData(taskSort, taskGroup, oldTaskId, curTaskData)
    local taskGroupDatas = self.tastDatas[taskSort][taskGroup]
    for taskTypeId,taskTypeData in ipairs(taskGroupDatas) do
        if taskTypeData.id == oldTaskId then
            taskGroupDatas[taskTypeId] = curTaskData
            break
        end
    end
end

--==============================--
--desc: 更新任务cell
--==============================--
function AchievementTaskMediator:updateCurTaskListCell(index, curTaskData)
    local taskList = self:getViewData().taskList
    local cell = taskList:cellAtIndex(index - 1)
    if cell then
        self:GetViewComponent():updateAchievementCell(curTaskData, cell.viewData)
    end
end

--==============================--
--desc: 更新任务进度
--@params taskProgress table 所有的任务进度
--==============================--
function AchievementTaskMediator:updateTaskProgress(taskProgress)
    if next(taskProgress) == nil then return end
    
    for taskGroupId, taskData in pairs(self.tastDatas[OTHER] or {}) do
        for i, otherData in ipairs(taskData) do
            local taskConf = otherData.conf
            local taskAchieveExp = taskProgress[tostring(taskConf.id)]
            if taskAchieveExp then
                local serverData = otherData.serverData
                local taskSort   = taskConf.taskSort
                local taskGroup  = taskConf.taskGroup
                local targetNum  = checkint(taskConf.targetNum)
                local showComplete = otherData.showComplete
                local isInsertData = (serverData.progress < targetNum) and (taskAchieveExp >= targetNum)

                -- 1. 状态是 全部完成状态 则 只更新数据
                if showComplete ~= 1 then
                    -- 更新最忌完成数据  以前
                    if isInsertData then
                        table.insert(self.tastDatas[RECENTLY_COMPLETED_TASK_SORT_ID][RECENTLY_COMPLETED_TASK_GROUP_ID], otherData)
                        self.canReceiveCounts[taskSort].taskSortReceiveCount = self.canReceiveCounts[taskSort].taskSortReceiveCount + 1
                        self.canReceiveCounts[taskSort][taskGroup].taskGroupRedReceiveCount = self.canReceiveCounts[taskSort][taskGroup].taskGroupRedReceiveCount + 1

                        self.canReceiveCounts[RECENTLY_COMPLETED_TASK_SORT_ID].taskSortReceiveCount = self.canReceiveCounts[RECENTLY_COMPLETED_TASK_SORT_ID].taskSortReceiveCount + 1
                        self.canReceiveCounts[RECENTLY_COMPLETED_TASK_SORT_ID][RECENTLY_COMPLETED_TASK_GROUP_ID].taskGroupRedReceiveCount = self.canReceiveCounts[RECENTLY_COMPLETED_TASK_SORT_ID][RECENTLY_COMPLETED_TASK_GROUP_ID].taskGroupRedReceiveCount + 1

                        -- 更新红点 只更新大类红点
                        -- self:updateTaskSortRedPoint(taskSort)
                    end
                    serverData.progress = taskAchieveExp
                end
            end
        end
    end
end

--==============================--
--desc: 更新成就经验
--==============================--
function AchievementTaskMediator:updateAchieveExp()
    local newLvExp = checkint(gameMgr:GetUserInfo().achieveExp)
	if checkint(gameMgr:GetUserInfo().achieveLevel) > 0 then
		newLvExp = checkint(gameMgr:GetUserInfo().achieveExp) - CommonUtils.GetConfig('task', 'achieveLevel',gameMgr:GetUserInfo().achieveLevel).totalExp
	end
	local needLvExp = 0
    if checkint(gameMgr:GetUserInfo().achieveLevel) >= MAX_ACHIEVELEVEL then
		needLvExp = CommonUtils.GetConfig('task', 'achieveLevel',gameMgr:GetUserInfo().achieveLevel).exp
	else
		needLvExp = CommonUtils.GetConfig('task', 'achieveLevel',gameMgr:GetUserInfo().achieveLevel+1).exp
	end
	if newLvExp < 0 then
		newLvExp = 0
    end
    
    self.canGetTaskReward = false
	if checkint(newLvExp) >= checkint(needLvExp) then
		self.canGetTaskReward = true
	end

    self:GetViewComponent():updateAchieveProgress(newLvExp, needLvExp)
end

--==============================--
--desc: 清理红点数据
--@params taskSort  大类id
--@params taskGroup 小类id
--==============================--
function AchievementTaskMediator:clearRedPointData(taskSort, taskGroup)
    self.canReceiveCounts[taskSort].taskSortReceiveCount = self.canReceiveCounts[taskSort].taskSortReceiveCount - 1
    if self.canReceiveCounts[taskSort].taskSortReceiveCount < 0 then
        self.canReceiveCounts[taskSort].taskSortReceiveCount = 0
    end
    self.canReceiveCounts[taskSort][taskGroup].taskGroupRedReceiveCount = self.canReceiveCounts[taskSort][taskGroup].taskGroupRedReceiveCount - 1
    if self.canReceiveCounts[taskSort][taskGroup].taskGroupRedReceiveCount < 0 then
        self.canReceiveCounts[taskSort][taskGroup].taskGroupRedReceiveCount = 0
    end
end


-------------------------------------------------
-- check

-------------------------------------------------
-- handle

function AchievementTaskMediator:onAchieveDataSourceAction(p_convertview,idx)
    local pCell = p_convertview
    local index = idx + 1
    local viewData = self:getViewData()
    local bg = viewData.taskList
    local viewComponent = self:GetViewComponent()
	if pCell == nil then
		pCell = viewComponent:CreateAchievementCell(bg:getSizeOfCell())
		display.commonUIParams(pCell.viewData.btn,  {cb = handler(self, self.onAchievementCellBtnAction)})
	end

	xTry(function()

		local data = self.curTaskList[index]
		local viewData = pCell.viewData

		viewComponent:updateAchievementCell(data, viewData)

        pCell.viewData.btn:setTag(index)
		pCell:setTag(index)

	end,__G__TRACKBACK__)


	return pCell
end

function AchievementTaskMediator:onClickAchieveLvRewardAction(sender)
    if not self.isControllable_ then return end
    if self.canGetTaskReward then
        self:SendSignal(POST.TASK_ACHIEVE_LEVEL_UP.cmdName)
    else
        local rewards = {}
        if checkint(gameMgr:GetUserInfo().achieveLevel) >= MAX_ACHIEVELEVEL then
            rewards = CommonUtils.GetConfig('task', 'achieveLevel',gameMgr:GetUserInfo().achieveLevel).reward
        else
            rewards = CommonUtils.GetConfig('task', 'achieveLevel',gameMgr:GetUserInfo().achieveLevel+1).reward
        end

        uiMgr:ShowInformationTipsBoard({targetNode = sender, iconIds = rewards, type = 4})
    end
end

function AchievementTaskMediator:onCkickTabBtnAction(sender)
    if not self.isControllable_ then return end
    local index = sender:getTag()
    if checkint(self.selectModel) == checkint(index) then
	    return
    end
    local viewData           = self:getViewData()
    local expandableListView = viewData.expandableListView

    -- update old node
    if checkint(self.selectModel) ~= 0 then
        local oldExpandableNode  = expandableListView:getExpandableNodeAtIndex(self.selectModel - 1)
        if oldExpandableNode then
            self:GetViewComponent():updateTabShowState(oldExpandableNode.button, false)
            if self.selectSecondModel > 0 then
                local item = oldExpandableNode:getItemNodeAtIndex(self.selectSecondModel - 1)
                self:updateSencondTab(item, false)
                oldExpandableNode:setExpanded(false)
            end
        end
    end
    
    -- update new node
    self.selectModel = index
    local expandableNode     = expandableListView:getExpandableNodeAtIndex(index - 1)
    local tabData = self.taskSortTabData[index]
    local taskGroupData = tabData.taskGroupData
    local id = tabData.id

    local expanded = taskGroupData and next(taskGroupData) ~= nil
    expandableNode:setExpanded(expanded)
    self.selectSecondModel = 0
    if expanded then
        self.selectSecondModel = 1
        self:GetViewComponent():updateTabShowState(expandableNode.button, true)
        local item = expandableNode:getItemNodeAtIndex(self.selectSecondModel - 1)
        self:updateSencondTab(item, true)
    end
    
    expandableListView:reloadData()

    self:updateTaskList()
end

function AchievementTaskMediator:onCkickItemBtnAction(sender)
    if not self.isControllable_ then return end
    local index = checkint(sender:getTag())
    if self.selectSecondModel == index then return end

    local viewData           = self:getViewData()
    local expandableListView = viewData.expandableListView
    local expandableNode     = expandableListView:getExpandableNodeAtIndex(self.selectModel - 1)

    local oldItem = expandableNode:getItemNodeAtIndex(self.selectSecondModel - 1)
    self:updateSencondTab(oldItem, false)

    local item = expandableNode:getItemNodeAtIndex(index - 1)
    self:updateSencondTab(item, true)

    self.selectSecondModel = index

    self:updateTaskList()
end

function AchievementTaskMediator:onAchievementCellBtnAction(sender)
    if not self.isControllable_ then return end
    local index = sender:getTag()

    local data = self.curTaskList[index] or {}

    if next(data) ~= nil then
        local serverData    = data.serverData
        local taskConf      = data.conf
        local showComplete  = data.showComplete
        local taskId        = checkint(data.taskId)
        local progress      = checkint(serverData.progress)
        local targetNum     = checkint(taskConf.targetNum) == 0 and 1 or checkint(taskConf.targetNum)
        if progress < targetNum then
            uiMgr:ShowInformationTips(__('未完成该成就'))
        elseif checkint(taskConf.taskType) == SPECIAL_TASK_TYPE and gameMgr:GetUserInfo().level < 100 then
            uiMgr:ShowInformationTips(__('等级未到达'))
        else
            self.isControllable_ = false
            self:SendSignal(COMMANDS.COMMAND_MainTask_Get, {taskId = taskId, index = index})
        end
    end
end

-------------------------------------------------
-- get / set

function AchievementTaskMediator:getViewData()
    return self.viewData_
end

function AchievementTaskMediator:getTaskSortId(index)
    local tabData = self.taskSortTabData[index]
    local id = tabData.id
    return id
end

return AchievementTaskMediator