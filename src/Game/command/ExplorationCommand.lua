local SimpleCommand = mvc.SimpleCommand

local ExplorationCommand = class("ExplorationCommand", SimpleCommand)
function ExplorationCommand:ctor(  )
	self.super:ctor()
	self.executed = false 
end

function ExplorationCommand:Execute( signal )
	self.executed = true
	local name = signal:GetName()
	local httpManager = AppFacade.GetInstance():GetManager("HttpManager")
	if name == COMMANDS.COMMAND_Exploration_Home then
		httpManager:Post("Explore/home", SIGNALNAMES.Exploration_Home_Callback)
	elseif name == COMMANDS.COMMAND_Exploration_Enter then
		local data = signal:GetBody()
		httpManager:Post("Explore/enter", SIGNALNAMES.Exploration_Enter_Callback, data)
	elseif name == COMMANDS.COMMAND_Exploration_Explore then
		local data = signal:GetBody()
		httpManager:Post("Explore/explore", SIGNALNAMES.Exploration_Explore_Callback, data)
	elseif name == COMMANDS.COMMAND_Exploration_EnterNextFloor then
		local data = signal:GetBody()
		httpManager:Post("Explore/enterNextFloor", SIGNALNAMES.Exploration_EnterNextFloor_Callback, data)
	elseif name == COMMANDS.COMMAND_Exploration_Continue then
		local data = signal:GetBody()
		httpManager:Post("Explore/exploreContinue", SIGNALNAMES.Exploration_Continue_Callback, data)
	end
end

return ExplorationCommand