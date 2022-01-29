--[[
 * author : liuzhipeng
 * descpt : 活动 组合活动 循环任务Mediator
--]]
local AssemblyActivityTaskMediator = class('AssemblyActivityTaskMediator', mvc.Mediator)
local NAME = 'activity.assemblyActivity.AssemblyActivityTaskMediator'
function AssemblyActivityTaskMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    local args = checktable(params)
    self.activityId = checkint(args.activityId)
    self.isGoto = false
end
-------------------------------------------------
------------------ inheritance ------------------
function AssemblyActivityTaskMediator:Initial( key )
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
    
function AssemblyActivityTaskMediator:InterestSignals()
    local signals = {
        POST.ASSEMBLY_ACTIVITY_CIRCLE_TASK_HOME.sglName,
        POST.ASSEMBLY_ACTIVITY_CIRCLE_TASK_DRAW.sglName,
    }
    return signals
end
function AssemblyActivityTaskMediator:ProcessSignal( signal )
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

function AssemblyActivityTaskMediator:OnRegist()
    regPost(POST.ASSEMBLY_ACTIVITY_CIRCLE_TASK_HOME)
    regPost(POST.ASSEMBLY_ACTIVITY_CIRCLE_TASK_DRAW)
    self:EnterLayer()
end
function AssemblyActivityTaskMediator:OnUnRegist()
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
function AssemblyActivityTaskMediator:BackButtonCallback( sender )
    PlayAudioByClickClose()
    app:UnRegsitMediator(NAME)
end
--[[
循环任务领取按钮回调
--]]
function AssemblyActivityTaskMediator:CyclicTasksDrawBtnCallback( sender )
    if self.isGoto then return end
	PlayAudioByClickNormal()
    local tag = sender:getTag()
    local homeData = self:GetHomeData()
    local taskData = homeData.tasks[tag]
    if checkint(taskData.progress) >= checkint(taskData.target) then
        DotGameEvent.DynamicSendEvent({
                                          game_uuid = DotGameEvent.GAME_UUIDS.RETURN_FACTORY,
                                          event_id = table.concat({"2_" ,"daily_task_" , taskData.taskId , "_1"},"") ,
                                          event_content = "daily_task"
                                      })
        self:SendSignal(POST.ASSEMBLY_ACTIVITY_CIRCLE_TASK_DRAW.cmdName, {activityId = self.activityId, taskId = taskData.taskId})
    else
        DotGameEvent.DynamicSendEvent({
              game_uuid = DotGameEvent.GAME_UUIDS.RETURN_FACTORY,
              event_id = table.concat({"2_"  ,"daily_task_",taskData.taskId , "_0"},"") ,
              event_content = "daily_task"
       })
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
function AssemblyActivityTaskMediator:OnUpdateGoodsListCellHandler( cellIndex, cellViewData )
    local homeData = self:GetHomeData()
    local viewComponent = self:GetViewComponent()
    local taskData = homeData.tasks[cellIndex]
    cellViewData.button:setTag(cellIndex)
    viewComponent:RefreshTaskState(cellViewData, taskData)
end
--[[
列表cell初始化
--]]
function AssemblyActivityTaskMediator:OnInitGoodsListCellHandler( cellViewData )
    display.commonUIParams(cellViewData.button, {cb = handler(self, self.CyclicTasksDrawBtnCallback)})
end
-------------------- handler --------------------
-------------------------------------------------

-------------------------------------------------
-------------------- private --------------------
--[[
初始化view
--]]
function AssemblyActivityTaskMediator:InitView()
    local homeData = self:GetHomeData()
    local viewComponent = self:GetViewComponent()
    viewComponent:GetViewData().taskGridView:resetCellCount(#homeData.tasks)
end
--[[
进入页面
--]]
function AssemblyActivityTaskMediator:EnterLayer()
    self:SendSignal(POST.ASSEMBLY_ACTIVITY_CIRCLE_TASK_HOME.cmdName, {activityId = self.activityId})
end
--[[
任务领取处理
--]]
function AssemblyActivityTaskMediator:DrawTaskResponseHandler(data)
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
function AssemblyActivityTaskMediator:SortFunction()
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
function AssemblyActivityTaskMediator:SetHomeData( homeData )
    self.homeData = homeData
end
--[[
获取homeData
--]]
function AssemblyActivityTaskMediator:GetHomeData()
    return self.homeData
end
------------------- get / set -------------------
-------------------------------------------------
return AssemblyActivityTaskMediator