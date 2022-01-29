local SimpleCommand = mvc.SimpleCommand


local DailyTaskCommand = class("DailyTaskCommand", SimpleCommand)


function DailyTaskCommand:ctor( )
	self.super:ctor()
	self.executed = false
end

function DailyTaskCommand:Execute( signal )
	self.executed = true
	--发送网络请求
    local name = signal:GetName()
    local httpManager = AppFacade.GetInstance():GetManager("HttpManager")
    if name == COMMANDS.COMMAND_DailyTask then
        httpManager:Post("dailyTask/home",SIGNALNAMES.DailyTask_Message_Callback)
    elseif name == COMMANDS.COMMAND_DailyTask_Get then
        local data = signal:GetBody()
        httpManager:Post("dailyTask/drawTask",SIGNALNAMES.DailyTask_Get_Callback,data)
    elseif name == COMMANDS.COMMAND_DailyTask_ActiveGet then
        local data = signal:GetBody()
        httpManager:Post("dailyTask/drawActivePoint",SIGNALNAMES.DailyTask_ActiveGet_Callback,data)
    elseif name == COMMANDS.COMMAND_MainTask then
        httpManager:Post("task/taskList",SIGNALNAMES.MainTask_Message_Callback)--task/task
    elseif name == COMMANDS.COMMAND_MainTask_Get then
        local data = signal:GetBody()
        httpManager:Post("task/drawReward",SIGNALNAMES.MainTask_Get_Callback,data)--
    end
end

return DailyTaskCommand