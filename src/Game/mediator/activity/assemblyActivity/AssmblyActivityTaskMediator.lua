--[[
 * author : liuzhipeng
 * descpt : 活动 组合活动 循环任务Mediator
--]]
local AssmblyActivityTaskMediator = class('AssmblyActivityTaskMediator', mvc.Mediator)
local NAME = 'activity.assemblyActivity.AssmblyActivityTaskMediator'
function AssmblyActivityTaskMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    local args = checktable(params)
    self.activityId = checkint(args.activityId)
    self.isGoto = false
end
-------------------------------------------------
------------------ inheritance ------------------
function AssmblyActivityTaskMediator:Initial( key )
    self.super.Initial(self, key)
    local viewComponent = require('Game.views.activity.assemblyActivity.AssemblyActivityTaskView').new()
    viewComponent:setPosition(display.center)
    app.uiMgr:GetCurrentScene():AddDialog(viewComponent)
    self:SetViewComponent(viewComponent)
    local viewData = viewComponent.viewData

    viewComponent.eaterLayer:setOnClickScriptHandler(handler(self, self.BackButtonCallback))
    viewData.taskGridView:setCellUpdateHandler(handler(self, self.OnUpdateGoodsListCellHandler))
    viewData.taskGridView:setCellInitHandler(handler(self, self.OnInitGoodsListCellHandler))
end
    
function AssmblyActivityTaskMediator:InterestSignals()
    local signals = {
        POST.ASSEMBLY_ACTIVITY_CIRCLE_TASK_HOME.sglName,
        POST.ASSEMBLY_ACTIVITY_CIRCLE_TASK_DRAW.sglName,
    }
    return signals
end
function AssmblyActivityTaskMediator:ProcessSignal( signal )
    local name = signal:GetName()
    local body = signal:GetBody()
    if name == POST.ASSEMBLY_ACTIVITY_CIRCLE_TASK_HOME.sglName then
        self:SetHomeData(body)
        self:SortFunction()
        self:InitView()
    elseif name == POST.ASSEMBLY_ACTIVITY_CIRCLE_TASK_DRAW.sglName then
        self:DrawTaskResponseHandler(body)
    end
end

function AssmblyActivityTaskMediator:OnRegist()
    regPost(POST.ASSEMBLY_ACTIVITY_CIRCLE_TASK_HOME)
    regPost(POST.ASSEMBLY_ACTIVITY_CIRCLE_TASK_DRAW)
    self:EnterLayer()
end
function AssmblyActivityTaskMediator:OnUnRegist()
    unregPost(POST.ASSEMBLY_ACTIVITY_CIRCLE_TASK_HOME)
    unregPost(POST.ASSEMBLY_ACTIVITY_CIRCLE_TASK_DRAW)
    -- 移除界面
    local viewComponent = self:GetViewComponent()
    viewComponent:CloseAction()
    
end
------------------ inheritance ------------------
-------------------------------------------------

-------------------------------------------------
-------------------- handler --------------------
--[[
返回主界面
--]]
function AssmblyActivityTaskMediator:BackButtonCallback( sender )
    PlayAudioByClickClose()
    app:UnRegsitMediator(NAME)
end
--[[
循环任务领取按钮回调
--]]
function AssmblyActivityTaskMediator:CyclicTasksDrawBtnCallback( sender )
    if self.isGoto then return end
	PlayAudioByClickNormal()
    local tag = sender:getTag()
    local homeData = self:GetHomeData()
    local taskData = homeData.tasks[tag]
    if checkint(taskData.progress) >= checkint(taskData.target) then
        self:SendSignal(POST.ASSEMBLY_ACTIVITY_CIRCLE_TASK_DRAW.cmdName, {activityId = self.activityId, taskId = taskData.taskId})
    else
        app:UnRegsitMediator(NAME)
        CommonUtils.JumpModuleByTaskData( taskData )
        sceneWorld:runAction(
            cc.Sequence:create(
                cc.CallFunc:create(function()
                    self.isGoto = true
                end),
                cc.DelayTime:create(2) ,
                cc.CallFunc:create(function()
                    self.isGoto = false
                end)
            )
        )
    end
end
--[[
列表刷新
--]]
function AssmblyActivityTaskMediator:OnUpdateGoodsListCellHandler( cellIndex, cellViewData )
    local homeData = self:GetHomeData()
    local viewComponent = self:GetViewComponent()
    local taskData = homeData.tasks[cellIndex]
    cellViewData.button:setTag(cellIndex)
    viewComponent:RefreshTaskState(cellViewData, taskData)
end
--[[
列表cell初始化
--]]
function AssmblyActivityTaskMediator:OnInitGoodsListCellHandler( cellViewData )
    display.commonUIParams(cellViewData.button, {cb = handler(self, self.CyclicTasksDrawBtnCallback)})
end
-------------------- handler --------------------
-------------------------------------------------

-------------------------------------------------
-------------------- private --------------------
--[[
初始化view
--]]
function AssmblyActivityTaskMediator:InitView()
    local homeData = self:GetHomeData()
    local viewComponent = self:GetViewComponent()
    viewComponent:GetViewData().taskGridView:resetCellCount(#homeData.tasks)
end
--[[
进入页面
--]]
function AssmblyActivityTaskMediator:EnterLayer()
    self:SendSignal(POST.ASSEMBLY_ACTIVITY_CIRCLE_TASK_HOME.cmdName, {activityId = self.activityId})
end
--[[
任务领取处理
--]]
function AssmblyActivityTaskMediator:DrawTaskResponseHandler(data)
    app.uiMgr:AddDialog('common.RewardPopup', data)
    local requestData = data.requestData
    local taskId = requestData.taskId
    local index = 0
    local homeData = self:GetHomeData()
    for k, v in pairs(homeData.tasks) do
        if checkint(v.taskId) == checkint(taskId) then
            v.hasDrawn = true
            break
        end
    end
    self:SortFunction()
    local viewComponent = self:GetViewComponent()
    local viewData = viewComponent.viewData
    viewData.taskGridView:reloadData()
end
--[[
任务排序
--]]
function AssmblyActivityTaskMediator:SortFunction()
    local homeData = self:GetHomeData()
    table.sort(homeData.tasks, function(aTaskData , bTaskData)
        local isTrue  = true
        if aTaskData.hasDrawn ==  bTaskData.hasDrawn then
            if aTaskData.hasDrawn  == true then
                if checkint(aTaskData.taskId) >= checkint(bTaskData.taskId)  then
                     isTrue = false
                else
                    isTrue = true
                end
            else
                local aReady = 0
                local bReady = 0
                if checkint(aTaskData.progress)  >=  checkint(aTaskData.target) then
                    aReady = 1
                end
                if checkint(bTaskData.progress)  >=  checkint(bTaskData.target) then
                    bReady = 1
                end
                if aReady == bReady  then
                    if checkint(aTaskData.taskId) >= checkint(bTaskData.taskId)  then
                        isTrue = false
                    else
                        isTrue = true
                    end
                else
                    isTrue = aReady > bReady and true or false
                end
            end
        else
            if aTaskData.hasDrawn  then
                isTrue = false
            else
                isTrue = true
            end
        end
        return isTrue
    end)
end
-------------------- private --------------------
-------------------------------------------------

-------------------------------------------------
------------------- get / set -------------------
--[[
设置homeData
--]]
function AssmblyActivityTaskMediator:SetHomeData( homeData )
    self.homeData = homeData
end
--[[
获取homeData
--]]
function AssmblyActivityTaskMediator:GetHomeData()
    return self.homeData
end
------------------- get / set -------------------
-------------------------------------------------
return AssmblyActivityTaskMediator