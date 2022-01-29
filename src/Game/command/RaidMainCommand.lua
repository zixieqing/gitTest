local SimpleCommand = mvc.SimpleCommand


local RaidMainCommand = class("RaidMainCommand", SimpleCommand)


function RaidMainCommand:ctor( )
	self.super:ctor()
	self.executed = false
end

function RaidMainCommand:Execute( signal )
	self.executed = true
	--发送网络请求
    local name = signal:GetName()
    local httpManager = AppFacade.GetInstance():GetManager("HttpManager")
    if name == COMMANDS.COMMAND_RaidDetail_Bulid then
        local data = signal:GetBody()
        httpManager:Post("QuestTeam/create",SIGNALNAMES.RaidDetail_Bulid_Callback,data)
    elseif name == COMMANDS.COMMAND_RaidDetail_AutoMatching then
        local data = signal:GetBody()
        httpManager:Post("QuestTeam/autoMatching",SIGNALNAMES.RaidDetail_AutoMatching_Callback,data)
    elseif name == COMMANDS.COMMAND_RaidDetail_SearchTeam then
        local data = signal:GetBody()
        httpManager:Post("QuestTeam/search",SIGNALNAMES.RaidDetail_SearchTeam_Callback,data)
    elseif name == COMMANDS.COMMAND_RaidMain_BuyAttendTimes then
        local data = signal:GetBody()
        httpManager:Post("QuestTeam/buyAttendTimes",SIGNALNAMES.RaidMain_BuyAttendTimes_Callback,data)
    end
end

return RaidMainCommand