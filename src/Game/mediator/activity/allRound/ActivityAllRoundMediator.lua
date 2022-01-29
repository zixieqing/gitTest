--[[
 * author : liuzhipeng
 * descpt : 活动 全能活动Mediator
--]]
local ActivityAllRoundMediator = class('ActivityAllRoundMediator', mvc.Mediator)
local NAME = "activity.allRound.ActivityAllRoundMediator"
function ActivityAllRoundMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    self.activityId = checktable(params).activityId
end
-------------------------------------------------
------------------ inheritance ------------------
function ActivityAllRoundMediator:Initial( key )
    self.super.Initial(self, key)
    local viewComponent = require('Game.views.activity.allRound.ActivityAllRoundView').new()
    viewComponent:setPosition(display.center)
    app.uiMgr:GetCurrentScene():AddDialog(viewComponent)
    self:SetViewComponent(viewComponent)
    local viewData = viewComponent.viewData

    viewData.tabNameLabel:setOnClickScriptHandler(handler(self, self.TipsButtonCallback))
    viewData.backBtn:setOnClickScriptHandler(handler(self, self.BackButtonCallback))
end

function ActivityAllRoundMediator:InterestSignals()
    local signals = {
        POST.ACTIVITY_ALLROUND_HOME.sglName,
        POST.ACTIVITY_ALLROUND_PATH_DRAW.sglName,
        'ACTIVITY_ALL_ROUND_TASK_DRAW_EVENT', 
        'ACTIVITY_ALL_ROUND_PATH_DRAW_EVENT', 
    }
    return signals
end
function ActivityAllRoundMediator:ProcessSignal( signal )
    local name = signal:GetName()
    local body = signal:GetBody()
    if name == POST.ACTIVITY_ALLROUND_HOME.sglName then
        local homeData = self:ConvertHomeData(body)
        self:SetHomeData(homeData)
        self:InitView()
        self:RefreshRemindIcon()
    elseif name == POST.ACTIVITY_ALLROUND_PATH_DRAW.sglName then -- 路线奖励领取
        self:DrawPathRewards(body)
    elseif name == 'ACTIVITY_ALL_ROUND_TASK_DRAW_EVENT' then -- 任务领取
        self:DrawPathTaskRewards(body)
    elseif name == 'ACTIVITY_ALL_ROUND_PATH_DRAW_EVENT' then -- 路线奖励领取事件
        self:SendSignal(POST.ACTIVITY_ALLROUND_PATH_DRAW.cmdName, {pathId = checkint(body.pathId), activityId = self.activityId})
    end
end

function ActivityAllRoundMediator:OnRegist()
    regPost(POST.ACTIVITY_ALLROUND_HOME)
    regPost(POST.ACTIVITY_ALLROUND_PATH_DRAW)
    self:EnterLayer()
end
function ActivityAllRoundMediator:OnUnRegist()
    unregPost(POST.ACTIVITY_ALLROUND_HOME)
    unregPost(POST.ACTIVITY_ALLROUND_PATH_DRAW)
    -- 移除界面
    local scene = app.uiMgr:GetCurrentScene()
	scene:RemoveDialog(self:GetViewComponent())
end
------------------ inheritance ------------------
-------------------------------------------------

-------------------------------------------------
-------------------- handler --------------------
--[[
提示按钮点击回调
--]]
function ActivityAllRoundMediator:TipsButtonCallback( sender )
    PlayAudioByClickNormal()
    app.uiMgr:ShowIntroPopup({moduleId = '-66'})
end
--[[
返回主界面
--]]
function ActivityAllRoundMediator:BackButtonCallback( sender )
    PlayAudioByClickClose()
    app:UnRegsitMediator(NAME)
end
-------------------- handler --------------------
-------------------------------------------------

-------------------------------------------------
-------------------- private --------------------
--[[
转换homeData
--]]
function ActivityAllRoundMediator:ConvertHomeData( data )
    local taskCompletion = true
    local rewardsData = nil 
    -- 判断最终奖励是否可以领奖
    for i, v in ipairs(data.path) do
        if checkint(v.type) == 0 then
            if checkint(v.canDrawn) == 0 then
                -- 最终奖励为不可领取类型
                v.taskCompletion = false
                return data
            else
                -- 记录奖励类型数据
                rewardsData = v
            end
        else
            if checkint(v.hasDrawn) == 0 then
                taskCompletion = false
            end
        end
    end
    rewardsData.taskCompletion = taskCompletion
    return data
end
--[[
初始化view
--]]
function ActivityAllRoundMediator:InitView()
    local homeData = self:GetHomeData()
    local view = self:GetViewComponent()
    local viewComponent = self:GetViewComponent()
    self.pathNodeList = viewComponent:CreatePathLayout(homeData.path, self.activityId)
end
--[[
领取路线任务奖励
@params map {
    pathId int 路线id
    taskId int 任务id
}
--]]
function ActivityAllRoundMediator:DrawPathTaskRewards( params )
    local homeData = self:GetHomeData()
    for i, pathData in ipairs(homeData.path) do
        if checkint(pathData.pathId) == checkint(params.pathId) then
            for _, taskData in ipairs(pathData.tasks) do
                if checkint(params.taskId) == checkint(taskData.taskId) then
                    taskData.hasDrawn = 1
                    break
                end
            end
            self.pathNodeList[i]:RefreshNode(pathData)
            break
        end
    end
    self:RefreshRemindIcon()
end
--[[
领取路线最终奖励
--]]
function ActivityAllRoundMediator:DrawPathRewards( params )
    local homeData = self:GetHomeData()
    local pathId = params.requestData.pathId
    -- 领取奖励
    app.uiMgr:AddDialog('common.RewardPopup', params)
    -- 更新本地数据
    for i, v in ipairs(homeData.path) do
        if checkint(v.pathId) == pathId then
            v.hasDrawn = 1
            break
        end
    end
    self:ConvertHomeData(homeData)
    -- 刷新页面
    for i, v in ipairs(homeData.path) do
        self.pathNodeList[i]:RefreshNode(v)
    end
    self:RefreshRemindIcon()
end
--[[
刷新红点
--]]
function ActivityAllRoundMediator:RefreshRemindIcon()
    local homeData = self:GetHomeData()
    for _, pathData in ipairs(homeData.path) do
        if checkint(pathData.canDrawn) > 0 and checkint(pathData.hasDrawn) == 0 then
            local canReceive = true
            for _, v in ipairs(pathData.tasks) do
                if checkint(v.hasDrawn) == 0 and checkint(v.progress) >= checkint(v.targetNum) then
                    return
                end
                if checkint(v.hasDrawn) == 0 then
                    canReceive = false
                end
            end
            if canReceive == true then
                return
            end
        end
    end
    local activityMediator = self:GetFacade():RetrieveMediator('ActivityMediator') 
    if activityMediator then
        activityMediator:ClearRemindIcon(self.activityId)
    end
    app:DispatchObservers('ACTIVITY_ALL_ROUND_CLEAR_REMIND_ICON', {activityId = self.activityId})
end
--[[
进入页面
--]]
function ActivityAllRoundMediator:EnterLayer()
    self:SendSignal(POST.ACTIVITY_ALLROUND_HOME.cmdName, {activityId = self.activityId})
end
-------------------- private --------------------
-------------------------------------------------

-------------------------------------------------
------------------- get / set -------------------
--[[
设置homeData
--]]
function ActivityAllRoundMediator:SetHomeData( homeData )
    self.homeData = homeData
end
--[[
获取homeData
--]]
function ActivityAllRoundMediator:GetHomeData()
    return self.homeData
end
------------------- get / set -------------------
-------------------------------------------------
return ActivityAllRoundMediator