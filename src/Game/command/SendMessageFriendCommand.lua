local SimpleCommand = mvc.SimpleCommand

local SendMessageFriendCommand = class("SendMessageFriendCommand", SimpleCommand)
function SendMessageFriendCommand:ctor(  )
	self.super:ctor()
	self.executed = false
end

function SendMessageFriendCommand:Execute( signal )
	self.executed = true
	local name = signal:GetName()
	local httpManager = AppFacade.GetInstance():GetManager("HttpManager")
	-- if name == COMMANDS.COMMAND_Friend_MessageList then
	-- 	local data = signal:GetBody()
	-- 	httpManager:Post("friend/messageList", SIGNALNAMES.Friend_MessageList_Callback, data)
	-- elseif name == COMMANDS.COMMAND_Friend_SendMessage then
	-- 	local data = signal:GetBody()
	-- 	httpManager:Post("friend/sendMessage", SIGNALNAMES.Friend_SendMessage_Callback, data)
	-- end
end

return SendMessageFriendCommand