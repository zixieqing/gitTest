--[[
 * author : liuzhipeng
 * descpt : 活动 循环任务Mediator
--]]
local ActivityCyclicTaskMediator = class('ActivityCyclicTaskMediator', mvc.Mediator)
local NAME = 'activity.cyclicTask.ActivityCyclicTaskMediator'
function ActivityCyclicTaskMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    local args = params or {}
    self.activityHomeData = checktable(args.activityHomeData)
    self.activityId = checkint(self.activityHomeData.activityId)
end
-------------------------------------------------
------------------ inheritance ------------------
function ActivityCyclicTaskMediator:Initial( key )
    self.super.Initial(self, key)
end
    
function ActivityCyclicTaskMediator:InterestSignals()
    local signals = {
        SIGNALNAMES.Activity_CyclicTasks_Callback,
		SIGNALNAMES.Activity_Buy_CyclicTasks_Callback,
        SIGNALNAMES.Activity_Draw_CyclicTasks_Callback,
        CYCLICTASKS_BUY_SUCCESS
    }
    return signals
end
function ActivityCyclicTaskMediator:ProcessSignal( signal )
    local name = signal:GetName()
    local body = signal:GetBody()
    if name == SIGNALNAMES.Activity_CyclicTasks_Callback then
        self:SetHomeData(body)
        self:StartTimer()
        self:InitView()
    elseif name == SIGNALNAMES.Activity_Buy_CyclicTasks_Callback then
        self:GetViewComponent():TaskPointBuyAction( body )
    elseif name == CYCLICTASKS_BUY_SUCCESS then
        self:CyclicTasksBuyBtnCallback()
    elseif name == SIGNALNAMES.Activity_Draw_CyclicTasks_Callback then
        self:GetViewComponent():CompleteTask( body )
    end
end

function ActivityCyclicTaskMediator:OnRegist()
    local ActivityCommand = require('Game.command.ActivityCommand')
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Activity_CyclicTasks, ActivityCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Activity_Buy_CyclicTasks, ActivityCommand)
    self:GetFacade():RegistSignal(COMMANDS.COMMAND_Activity_Draw_CyclicTasks, ActivityCommand)
    self:EnterLayer()
end
function ActivityCyclicTaskMediator:OnUnRegist()
    if app.timerMgr:RetriveTimer(NAME) then
        app.timerMgr:RemoveTimer(NAME)
	end
    self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Activity_CyclicTasks)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Activity_Buy_CyclicTasks)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Activity_Draw_CyclicTasks)
    -- 移除界面
    local scene = app.uiMgr:GetCurrentScene()
    scene:RemoveDialog(self:GetViewComponent())
end
------------------ inheritance ------------------
-------------------------------------------------

-------------------------------------------------
-------------------- handler --------------------
--[[
返回主界面
--]]
function ActivityCyclicTaskMediator:BackButtonCallback( sender )
    PlayAudioByClickClose()
    app:UnRegsitMediator(NAME)
end
-------------------- handler --------------------
-------------------------------------------------

-------------------------------------------------
-------------------- private --------------------
--[[
初始化view
--]]
function ActivityCyclicTaskMediator:InitView()
    local datas = clone(self:GetHomeData())
    local activityHomeData = self:GetActivityHomeData()
	datas.cellDrawCallback = handler(self, self.CyclicTasksDrawBtnCallback)
	datas.finalDrawCallback = handler(self, self.CyclicTasksFinalDrawBtnCallback)
	datas.leftSeconds = checkint(activityHomeData.leftSeconds)
	datas.title = activityHomeData.title[i18n.getLang()]
	local cyclicTasksView = app.uiMgr:GetCurrentScene():GetDialogByName("cyclicTasksView")
	if cyclicTasksView then
		cyclicTasksView:InitUi( datas )
	else
		local cyclicTasksView = require('Game.views.CyclicTasksView').new(datas)
		cyclicTasksView:setName('cyclicTasksView')
        app.uiMgr:GetCurrentScene():AddDialog(cyclicTasksView)
        self:SetViewComponent(cyclicTasksView)
	end
end
--[[
进入页面
--]]
function ActivityCyclicTaskMediator:EnterLayer()
    self:SendSignal(COMMANDS.COMMAND_Activity_CyclicTasks, {activityId = self.activityId})
end
--[[
循环任务领取按钮回调
--]]
function ActivityCyclicTaskMediator:CyclicTasksDrawBtnCallback( sender )
	PlayAudioByClickNormal()
	local taskId = sender:getTag()
	self:SendSignal(COMMANDS.COMMAND_Activity_Draw_CyclicTasks, {activityId = self.activityId, type = 1, taskId = taskId})
end
--[[
循环任务购买按钮回调
--]]
function ActivityCyclicTaskMediator:CyclicTasksBuyBtnCallback( sender )
	self:SendSignal(COMMANDS.COMMAND_Activity_Buy_CyclicTasks, {activityId = self.activityId})
end
--[[
循环任务最终奖励领取按钮回调
--]]
function ActivityCyclicTaskMediator:CyclicTasksFinalDrawBtnCallback( sender )
	PlayAudioByClickNormal()
	self:SendSignal(COMMANDS.COMMAND_Activity_Draw_CyclicTasks, {activityId = self.activityId, type = 2, taskId = 0})
end
--[[
开启定时器
--]]
function ActivityCyclicTaskMediator:StartTimer()
	local activityHomeData = self:GetActivityHomeData()
	if app.timerMgr:RetriveTimer(NAME) then
        app.timerMgr:RemoveTimer(NAME)
	end
	local callback = function(countdown, remindTag, timeNum, datas, timerName)
		if countdown >= 0 then
			self:GetViewComponent():UpdateTimeLabel(countdown, self.activityId)
		end
    end
	app.timerMgr:AddTimer({name = NAME, callback = callback, countdown = activityHomeData.leftSeconds})
end
-------------------- private --------------------
-------------------------------------------------

-------------------------------------------------
------------------- get / set -------------------
--[[
设置homeData
--]]
function ActivityCyclicTaskMediator:SetHomeData( homeData )
    self.homeData = homeData
end
--[[
获取homeData
--]]
function ActivityCyclicTaskMediator:GetHomeData()
    return self.homeData
end
--[[
获取activityHomeData
--]]
function ActivityCyclicTaskMediator:GetActivityHomeData()
    return self.activityHomeData
end
------------------- get / set -------------------
-------------------------------------------------
return ActivityCyclicTaskMediator