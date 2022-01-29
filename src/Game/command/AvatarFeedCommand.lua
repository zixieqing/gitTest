local SimpleCommand = mvc.SimpleCommand


local AvatarFeedCommand = class("AvatarFeedCommand", SimpleCommand)


function AvatarFeedCommand:ctor( )
	self.super:ctor()
	self.executed = false
end

function AvatarFeedCommand:Execute( signal )
	self.executed = true
	--发送网络请求
    local name = signal:GetName()
    local action = signal:GetType()
    local httpManager = AppFacade.GetInstance():GetManager("HttpManager")
    if name == COMMANDS.COMMAND_FEED_AVATAR then
        local data = signal:GetBody()
        if action == 'vigour' then
            httpManager:Post("backpack/cardVigourMagicFoodRecover",SIGNALNAMES.Exploration_AddVigour_Callback, data)
        end
    end
end

return AvatarFeedCommand
