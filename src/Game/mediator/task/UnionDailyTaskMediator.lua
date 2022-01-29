--[[
    工会任务Mediator
]]
local Mediator = mvc.Mediator
local UnionDailyTaskMediator = class("UnionDailyTaskMediator", Mediator)

local NAME = "task.UnionDailyTaskMediator"
UnionDailyTaskMediator.NAME = NAME

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")

local UNION_TASK_TYPE_CONFS = CommonUtils.GetConfigAllMess('taskType', 'union') or {}


function UnionDailyTaskMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    self.ctorArgs_ = checktable(params)
    self.viewTag   = self.ctorArgs_.viewTag
end

-------------------------------------------------
-- inheritance method

function UnionDailyTaskMediator:Initial(key)
    self.super.Initial(self, key)

    self.taskDatas       = {}
    self.isTimeEnd       = false
    self.isControllable_ = true
    
    -- create view
    local view = require('Game.views.task.UnionDailyTaskView').new()
    self.viewData_ = view:getViewData()
    self:SetViewComponent(view)

    -- init view
    self:initView()
end

function UnionDailyTaskMediator:initData(body)
    
    
end

function UnionDailyTaskMediator:initTaskData(task)

    for i,v in ipairs(task) do
        local taskTypeData = CommonUtils.GetConfig('task', 'taskType', v.taskType)
        v.name = v.taskName
        if taskTypeData then
            v.descr = string.fmt(taskTypeData.descr, {_target_num_ = v.targetNum})
        end
        if checkint(v.progress) >= checkint(v.targetNum) then
            v.hasDrawn = 1
        end
    end

    table.sort(task, function (a, b)
        if a == nil then return true end
        if b == nil then return false end

        local aProgress = checkint(a.progress)
        local bProgress = checkint(b.progress)
        local aTargetNum = checkint(a.targetNum)
        local bTargetNum = checkint(b.targetNum)
        local aTaskId = checkint(a.taskId)
        local bTaskId = checkint(b.taskId)
        local aHasDrawn = checkint(a.hasDrawn)
        local bHasDrawn = checkint(b.hasDrawn)
    
        local aState = aProgress >= aTargetNum and 1 or 0
        local bState = bProgress >= bTargetNum and 1 or 0
    
        if aHasDrawn == bHasDrawn then
            if aState == bState then
                return aTaskId < bTaskId
            end
            return aState > bState
        end
    
        return checkint(a.hasDrawn) < checkint(b.hasDrawn)
    end)

    
    return task
end

function UnionDailyTaskMediator:initView()
    local viewData = self:getViewData()
    local boxs         = viewData.boxs
    for k, box in pairs(boxs) do
        display.commonUIParams(box, {cb = handler(self,self.onPersonalContributionBoxActions), animate = false})
    end

    local unionContributionBoxs  = viewData.unionContributionBoxs
    for i, boxLayer in ipairs(unionContributionBoxs) do
        local boxLayerViewData = boxLayer.viewData
        local boxTouchLayer = boxLayerViewData.boxTouchLayer
        boxTouchLayer:setTag(i)
        display.commonUIParams(boxTouchLayer, {cb = handler(self,self.onUnionContributionBoxAction), animate = false})
    end

    local taskListView = viewData.taskListView
    taskListView:setDataSourceAdapterScriptHandler(handler(self, self.onDataSource))

    local oneKeyReceiveBtn = viewData.oneKeyReceiveBtn
    display.commonUIParams(oneKeyReceiveBtn, {cb = handler(self, self.oneKeyReceiveBtnAction)})

end

function UnionDailyTaskMediator:CleanupView()
    
end


function UnionDailyTaskMediator:OnRegist()
    regPost(POST.UNION_TASK)
    regPost(POST.UNION_DRAW_CONTRIBUTION_POINT)

    self:enterLayer()
end
function UnionDailyTaskMediator:OnUnRegist()
    unregPost(POST.UNION_TASK)
    unregPost(POST.UNION_DRAW_CONTRIBUTION_POINT)
end

function UnionDailyTaskMediator:InterestSignals()
    return {
        POST.UNION_TASK.sglName,
        POST.UNION_DRAW_CONTRIBUTION_POINT.sglName,

        -- UNION_TASK_FINISH_EVENT,   -- 工会任务完成
        SGL.FRESH_UNION_TASK_VIEW,
        UNION_TASK_REFRESH_EVENT,  -- 刷新工会任务
    }
end

function UnionDailyTaskMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local body = checktable(signal:GetBody())

    if name == POST.UNION_TASK.sglName then
        app.badgeMgr:initUnionTaskCacheData(body)
        self:updateView(body)
    elseif name == POST.UNION_DRAW_CONTRIBUTION_POINT.sglName then
        local requestData = body.requestData or {}
        local rewardId = requestData.rewardId
        if rewardId ~= -1 then
            local index, data = self:updatePersonalContributionData(rewardId)
            if index == nil then return end
            
            -- self.canReceiveRewardCount = self.canReceiveRewardCount - 1
            gameMgr:GetUserInfo().unionTaskCacheData_.canReceiveCount = checkint(gameMgr:GetUserInfo().unionTaskCacheData_.canReceiveCount) - 1
            gameMgr:GetUserInfo().unionTaskCacheData_.unreceivedTaskList[tostring(rewardId)] = nil

            self:updateRedPoint()
            local rewards = body.rewards or self.taskDatas.personalContributionPointRewards[index].rewards or {}
            if next(rewards) ~= nil then
                uiMgr:AddDialog('common.RewardPopup', {rewards = rewards})
            end

            self:GetViewComponent():updatePersonalContributtonCell(index, data, self.taskDatas.personalContributionPoint)
        else
            self:ReceiveAllRewards(body.rewards)
        end
    
    elseif name == SGL.FRESH_UNION_TASK_VIEW then
        self:updateView(body)
    -- elseif name == UNION_TASK_FINISH_EVENT then
    --     self:enterLayer()
    elseif name == UNION_TASK_REFRESH_EVENT then
        self.isTimeEnd = true
        -- self.canReceiveRewardCount = 0

        self:enterLayer()
    end
end

function UnionDailyTaskMediator:enterLayer()
    self:SendSignal(POST.UNION_TASK.cmdName)
end

--==============================--
--desc: 刷新任务界面
--time:2018-01-05 03:25:00
--@return 
--==============================-- 
function UnionDailyTaskMediator:updateView(body)
    self.taskDatas = body
    local tasks = self.taskDatas.tasks or {}
    
    local tasks = self:initTaskData(tasks)
    self.taskDatas.tasks = tasks

    self:updateRedPoint()

    self:GetViewComponent():refreshView(self.taskDatas)
end

function UnionDailyTaskMediator:updateRedPoint()
    self:GetFacade():DispatchObservers('TASK_UPDATE_EXTERNAL_TAB_RED_POINT', {viewTag = self.viewTag})
end

function UnionDailyTaskMediator:updatePersonalContributionData(rewardId)
    if self.taskDatas == nil then return end
    local index = nil
    local data  = nil
    for i, v in ipairs(self.taskDatas.personalContributionPointRewards) do
        if v.rewardId == rewardId then
            index = i
            v.hasDrawn = 1
            data = v
            break
        end
    end
    return index, data
end

function UnionDailyTaskMediator:onDataSource(p_convertview, idx)
    local pCell = p_convertview
    local index = idx + 1
    local data = self.taskDatas.tasks[index]
    
    local pButton = nil
    if pCell == nil then
        local bg = self:getViewData().taskListView
        pCell = CGridViewCell:new()
        local size = bg:getSizeOfCell()
        pCell:setContentSize(size)

        pButton = require('home.TaskCellNode').new({size = cc.size(size.width,  size.height)})
        pButton:setName('pButton')
        pButton:setAnchorPoint(cc.p(1,0.5))
        pButton:setPosition(cc.p(size.width ,size.height*0.5))
        pCell:addChild(pButton,1)

        -- pButton.expLabel
        display.commonLabelParams(pButton.viewData.expBtn, {offset = cc.p(-10,0)})
        display.commonUIParams(pButton.viewData.button, {cb = handler(self,self.onCellButtonAction)})
    else
        pButton = pCell:getChildByName('pButton')
    end

    xTry(function()

       self:GetViewComponent():updateTaskCell(pCell, data)
       local viewData = pButton.viewData
        viewData.button:setTag(index)
    end,__G__TRACKBACK__)
    return pCell
end

function UnionDailyTaskMediator:onCellButtonAction(sender)
    if self.taskDatas == nil then return end
    local index = sender:getTag()
    local data = self.taskDatas.tasks[index]
    if data == nil then return end
    
    if checkint(data.progress) < checkint(data.targetNum) then
        uiMgr:ShowInformationTips(__('未完成'))
    end

end

function UnionDailyTaskMediator:onPersonalContributionBoxActions(sender)
    if self.taskDatas == nil then return end
    local index = sender:getTag()
    local data = self.taskDatas.personalContributionPointRewards[index]
    if data == nil then return end
    
    if data.hasDrawn == 0 then
		if checkint(self.taskDatas.personalContributionPoint) < checkint(data.contributionPoint) then
			uiMgr:ShowInformationTipsBoard({targetNode = sender, iconIds = data.rewards, type = 4})
		else
			self:SendSignal(POST.UNION_DRAW_CONTRIBUTION_POINT.cmdName, {rewardId = data.rewardId})
		end
	else
		uiMgr:ShowInformationTipsBoard({targetNode = sender, iconIds = data.rewards, type = 4})
	end
end

function UnionDailyTaskMediator:onUnionContributionBoxAction(sender)
    if self.taskDatas == nil or self.taskDatas.unionContributionPointRewards == nil then return end
    local index = sender:getTag()
    local data = self.taskDatas.unionContributionPointRewards[index]
    if data == nil then return end

    uiMgr:ShowInformationTipsBoard({targetNode = sender, iconIds = data.rewards, type = 4})
end

function UnionDailyTaskMediator:oneKeyReceiveBtnAction()
    if self:IsCanReceive() then
        self:SendSignal(POST.UNION_DRAW_CONTRIBUTION_POINT.cmdName, {rewardId = -1})
    else
        uiMgr:ShowInformationTips(__('没有可领取的奖励'))
    end
end

function UnionDailyTaskMediator:IsCanReceive()
    local point = checkint(checktable(self.taskDatas).personalContributionPoint)
    for i, v in ipairs(checktable(self.taskDatas).personalContributionPointRewards or {}) do
        if checkint(v.hasDrawn) == 0 and point >= checkint(v.contributionPoint) then
            return true
        end
    end
    return false
end

function UnionDailyTaskMediator:ReceiveAllRewards( rewards )
    local point = self.taskDatas.personalContributionPoint
    for i, v in ipairs(self.taskDatas.personalContributionPointRewards) do
        if checkint(v.hasDrawn) == 0 and point >= checkint(v.contributionPoint) then
            local index, data = self:updatePersonalContributionData(v.rewardId)
            if index then
                gameMgr:GetUserInfo().unionTaskCacheData_.canReceiveCount = checkint(gameMgr:GetUserInfo().unionTaskCacheData_.canReceiveCount) - 1
                gameMgr:GetUserInfo().unionTaskCacheData_.unreceivedTaskList[tostring(rewardId)] = nil                
                self:GetViewComponent():updatePersonalContributtonCell(index, data, self.taskDatas.personalContributionPoint)
            end
        end
    end
    self:updateRedPoint()
    uiMgr:AddDialog('common.RewardPopup', {rewards = rewards})
end
-------------------------------------------------
-- get / set

function UnionDailyTaskMediator:getViewData()
    return self.viewData_
end



return UnionDailyTaskMediator