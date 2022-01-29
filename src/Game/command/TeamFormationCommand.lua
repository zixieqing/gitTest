local SimpleCommand = mvc.SimpleCommand


local TeamFormationCommand = class("TeamFormationCommand", SimpleCommand)


function TeamFormationCommand:ctor( )
	self.super:ctor()
	self.executed = false
end

function TeamFormationCommand:Execute( signal )
	self.executed = true
	--发送网络请求
    local name = signal:GetName()
    local httpManager = AppFacade.GetInstance():GetManager("HttpManager")
    if name == COMMANDS.COMMAND_TeamFormation then
        local data = signal:GetBody()
        httpManager:Post("card/saveTeam",SIGNALNAMES.TeamFormation_Name_Callback,data)
    elseif name == COMMANDS.COMMAND_TeamFormation_UnLock then
        local data = signal:GetBody()
        httpManager:Post("card/unlockTeam",SIGNALNAMES.TeamFormation_UnLock_Callback,data)
    elseif name == COMMANDS.COMMAND_TeamFormation_switchTeam then
        local data = signal:GetBody()
        httpManager:Post("card/switchTeam",SIGNALNAMES.TeamFormation_switchTeam_Callback,data)
    elseif name == COMMANDS.COMMANDS_ICEPLACE_HOME then
        local data = signal:GetBody()
        httpManager:Post("IcePlace/home", SIGNALNAMES.IcePlace_Home_Callback, data)
    elseif name == COMMANDS.COMMANDS_ICEPLACE then
        local data = signal:GetBody()
        httpManager:Post(string.format("IcePlace/addCardInIcePlace/playerCardId/%d",checkint(data.playerCardId)),SIGNALNAMES.IcePlace_AddCard_Callback,data, true)
    end
end

return TeamFormationCommand