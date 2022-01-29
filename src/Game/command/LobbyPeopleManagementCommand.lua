local SimpleCommand = mvc.SimpleCommand


local LobbyPeopleManagementCommand = class("LobbyPeopleManagementCommand", SimpleCommand)

 
function LobbyPeopleManagementCommand:ctor( )
	self.super:ctor()
	self.executed = false
end

function LobbyPeopleManagementCommand:Execute( signal )
	self.executed = true
	--发送网络请求
    local name = signal:GetName()
    local httpManager = AppFacade.GetInstance():GetManager("HttpManager")
    if name == COMMANDS.COMMANDS_Lobby_EmployeeSwitch then
        local data = signal:GetBody()
        httpManager:Post("Restaurant/employeeSwitch",SIGNALNAMES.Lobby_EmployeeSwitch_Callback,data)
    elseif name == COMMANDS.COMMANDS_Lobby_EmployeeUnlock then
        local data = signal:GetBody()
        httpManager:Post("Restaurant/employeeUnlock",SIGNALNAMES.Lobby_EmployeeUnlock_Callback,data)
    -- elseif name == COMMANDS.COMMAND_BackPack_Use then
    --     local data = signal:GetBody()
    --     httpManager:Post("backpack/useProps",SIGNALNAMES.BackPack_UseGoods_Callback,data)


    end
end

return LobbyPeopleManagementCommand