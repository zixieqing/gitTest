local SimpleCommand = mvc.SimpleCommand

local FriendListCommand = class("FriendListCommand", SimpleCommand)
function FriendListCommand:ctor(  )
	self.super:ctor()
	self.executed = false 
end

function FriendListCommand:Execute( signal )
	self.executed = true
	local name = signal:GetName()
	local httpManager = AppFacade.GetInstance():GetManager("HttpManager")
	if name == COMMANDS.COMMAND_Friend_List then
		httpManager:Post("friend/friendList", SIGNALNAMES.Friend_List_Callback)
	-- elseif name == COMMANDS.COMMAND_Friend_DelFriend then
	-- 	local data = signal:GetBody()
	-- 	httpManager:Post("friend/delFriend", SIGNALNAMES.Friend_DelFriend_Callback, data)
	elseif name == COMMANDS.COMMAND_Friend_FindFriend then	
		local data = signal:GetBody()
		httpManager:Post("friend/findFriend", SIGNALNAMES.Friend_FindFriend_Callback, data)
	elseif name == COMMANDS.COMMAND_Friend_AddFriend then
		local data = signal:GetBody()
		httpManager:Post("friend/addFriend", SIGNALNAMES.Friend_AddFriend_Callback, data)
	elseif name == COMMANDS.COMMAND_Friend_HandleAddFriend then
		local data = signal:GetBody()
		httpManager:Post("friend/handleAddFriend", SIGNALNAMES.Friend_HandleAddFriend_Callback, data)
	elseif name == COMMANDS.COMMAND_Friend_RefreshRecmmend then
		httpManager:Post("friend/refreshRecommendFriend", SIGNALNAMES.Friend_RefreshRecmmend_Callback)	
	elseif name == COMMANDS.COMMAND_Friend_EmptyRequest then
		httpManager:Post("friend/handelDelFriends", SIGNALNAMES.Friend_EmptyRequest_Callback)
	elseif name == COMMANDS.COMMAND_Friend_NewPlayerInfo then
		local data = signal:GetBody()
		httpManager:Post("friend/playerInfo", SIGNALNAMES.Friend_NewPlayerInfo_Callback, data)
	end
end

return FriendListCommand
