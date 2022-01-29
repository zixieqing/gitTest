local SimpleCommand = mvc.SimpleCommand

local LobbyTaskCommond = class("LobbyTaskCommond", SimpleCommand)


function LobbyTaskCommond:ctor( )
	self.super:ctor()
	self.executed = false
end


function LobbyTaskCommond:Execute( signal )
	self.executed = true
	local name = signal:GetName()
    local body = signal:GetBody()
	local httpManager = AppFacade.GetInstance():GetManager("HttpManager")
    if name == COMMANDS.COMMAND_Restaurant_ChooseRestaurantTask then--CACHE_MONEY
        httpManager:Post("Restaurant/chooseRestaurantTask",SIGNALNAMES.Restaurant_ChooseRestaurantTask_Callback, body)
    elseif name == COMMANDS.COMMAND_Restaurant_CancelRestaurantTask then
    	httpManager:Post("Restaurant/cancelRestaurantTask",SIGNALNAMES.Restaurant_CancelRestaurantTask_Callback)
    end
end

return LobbyTaskCommond
