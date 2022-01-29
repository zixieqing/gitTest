local SimpleCommand = mvc.SimpleCommand


local LobbyCookingCommand = class("LobbyCookingCommand", SimpleCommand)

 --  
function LobbyCookingCommand:ctor( )
	self.super:ctor()
	self.executed = false
end

function LobbyCookingCommand:Execute( signal )
	self.executed = true
	--发送网络请求
    local name = signal:GetName()
    local httpManager = AppFacade.GetInstance():GetManager("HttpManager")
    if name == COMMANDS.COMMANDS_Lobby_RecipeCooking then
        local data = signal:GetBody()
        httpManager:Post("Restaurant/recipeCooking",SIGNALNAMES.Lobby_RecipeCooking_Callback,data)
    elseif name == COMMANDS.COMMANDS_Lobby_AccelerateRecipeCooking then
        local data = signal:GetBody()
        httpManager:Post("Restaurant/accelerateRecipeCooking",SIGNALNAMES.Lobby_AccelerateRecipeCooking_Callback,data)
    elseif name == COMMANDS.COMMANDS_Lobby_CancelRecipeCooking then
        local data = signal:GetBody()
        httpManager:Post("Restaurant/cancelRecipeCooking",SIGNALNAMES.Lobby_CancelRecipeCooking_Callback,data)
    elseif name == COMMANDS.COMMANDS_Lobby_EmptyRecipe then
        local data = signal:GetBody()
        httpManager:Post("Restaurant/emptyRecipe",SIGNALNAMES.Lobby_EmptyRecipe_Callback,data)
    elseif name == COMMANDS.COMMANDS_Lobby_RecipeCookingDone then
        local data = signal:GetBody()
        httpManager:Post("Restaurant/recipeCookingDone",SIGNALNAMES.Lobby_RecipeCookingDone_Callback,data)

    end
end

return LobbyCookingCommand