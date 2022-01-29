local SimpleCommand = mvc.SimpleCommand

local AvatarCommand = class("AvatarCommand", SimpleCommand)


function AvatarCommand:ctor( )
	self.super:ctor()
	self.executed = false
end


function AvatarCommand:Execute( signal )
	self.executed = true
	local name = signal:GetName()
    local body = signal:GetBody()
	local httpManager = AppFacade.GetInstance():GetManager("HttpManager")
    if name == COMMANDS.COMMAND_BUY_AVATAR then--CACHE_MONEY
        httpManager:Post("Restaurant/buyAvatar",SIGNALNAMES.SIGNALNAME_BUY_AVATAR, body)
    elseif name == COMMANDS.COMMAND_UNLOCK_AVATAR then
        httpManager:Post("Restaurant/unlockAvatar",SIGNALNAMES.SIGNALNAME_UNLOCK_AVATAR, body)
    elseif name == COMMANDS.COMMAND_HOME_AVATAR then
        httpManager:Post("Restaurant/home",SIGNALNAMES.SIGNALNAME_HOME_AVATAR, body)
    elseif name == COMMANDS.COMMAND_GET_TASK then
        httpManager:Post("Restaurant/restaurantTask",SIGNALNAMES.SIGNALNAME_GET_TASK)
    elseif name == COMMANDS.COMMAND_DRAW_TASK then
        httpManager:Post("Restaurant/drawRestaurantTask",SIGNALNAMES.SIGNALNAME_DRAW_TASK)
    elseif name == COMMANDS.COMMAND_CANCEL_QUEST then
        --取消霸王餐
        httpManager:Post("Restaurant/cancelQuest",SIGNALNAMES.SIGNALNAME_CANCEL_AVATAR_QUEST, body)
    elseif name == COMMANDS.COMMANDS_Home_RecipeCookingDone then
        httpManager:Post("Restaurant/recipeCookingDone",SIGNALNAMES.SIGNALNAME_Home_RecipeCookingDone,body)
    elseif name == COMMANDS.COMMANDS_FRIEND_MESSAGEBOOK then
        httpManager:Post("Restaurant/message", SIGNALNAMES.SIGNALNAME_FRIEND_MESSAGEBOOK, body)
    elseif name == COMMANDS.COMMANDS_ICEPLACE_HOME then
        httpManager:Post("IcePlace/home", SIGNALNAMES.IcePlace_Home_Callback, body)
    elseif name == COMMANDS.COMMANDS_ICEPLACE then
        local data = signal:GetBody()
        httpManager:Post(string.format("IcePlace/addCardInIcePlace/playerCardId/%d",checkint(data.playerCardId)),SIGNALNAMES.IcePlace_AddCard_Callback,data, true)
    end
end

return AvatarCommand
