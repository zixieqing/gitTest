local SimpleCommand = mvc.SimpleCommand

local FriendCommand = class("FriendCommand", SimpleCommand)
function FriendCommand:ctor(  )
	self.super:ctor()
	self.executed = false 
end

function FriendCommand:Execute( signal )
	self.executed = true
	local name = signal:GetName()
	local httpManager = AppFacade.GetInstance():GetManager("HttpManager")
	if name == COMMANDS.COMMAND_Friend_List then
		httpManager:Post("friend/home", SIGNALNAMES.Friend_List_Callback)
	elseif name == COMMANDS.COMMAND_Friend_PlayerInfo then
		local data = signal:GetBody()
		httpManager:Post("friend/playerInfo", SIGNALNAMES.Friend_PlayerInfo_Callback, data)
	end
end

return FriendCommand