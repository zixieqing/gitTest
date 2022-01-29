local SimpleCommand = mvc.SimpleCommand

local LobbyInformationCommand = class("LobbyInformationCommand", SimpleCommand)
function LobbyInformationCommand:ctor(  )
	self.super:ctor()
	self.executed = false 
end

function LobbyInformationCommand:Execute( signal )
	self.executed = true
	local name = signal:GetName()
	local httpManager = AppFacade.GetInstance():GetManager("HttpManager")
	if name == COMMANDS.COMMAND_Restaurant_LevelUp then
		-- local data = signal:GetBody()
		httpManager:Post("Restaurant/levelUp", SIGNALNAMES.Restaurant_LevelUp_Callback)
	end
end

return LobbyInformationCommand