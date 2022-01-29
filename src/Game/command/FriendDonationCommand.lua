local SimpleCommand = mvc.SimpleCommand


local FriendDonationCommand = class("FriendDonationCommand", SimpleCommand)


function FriendDonationCommand:ctor( )
	self.super:ctor()
	self.executed = false
end

function FriendDonationCommand:Execute( signal )
	self.executed = true
	--发送网络请求
    local name = signal:GetName()
    local httpManager = AppFacade.GetInstance():GetManager("HttpManager")
    if name == COMMANDS.COMMAND_Friend_Assistance then
        local data = signal:GetBody()
        httpManager:Post("friend/assistance",SIGNALNAMES.Friend_Assistance_Callback, data)
    end
end
return FriendDonationCommand