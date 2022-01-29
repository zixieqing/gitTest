local SimpleCommand = mvc.SimpleCommand

local ExplorationChooseCommand = class("ExplorationChooseCommand", SimpleCommand)
function ExplorationChooseCommand:ctor(  )
	self.super:ctor()
	self.executed = false 
end

function ExplorationChooseCommand:Execute( signal )
	self.executed = true
	local name = signal:GetName()
	local httpManager = AppFacade.GetInstance():GetManager("HttpManager")
	if name == COMMANDS.COMMAND_Exploration_DiamondRecover then
		local data = signal:GetBody()
		httpManager:Post("card/vigourDiamondRecover", SIGNALNAMES.Exploration_DiamondRecover_Callback, data)
	elseif name == COMMANDS.COMMAND_Exploration_GetRecord then
		local data = signal:GetBody()
		httpManager:Post("Explore/getExploreRecord", SIGNALNAMES.Exploration_GetRecord_Callback, data)
	elseif name == COMMANDS.COMMAND_Exploration_ChooseExitExplore then
		local data = signal:GetBody()
		httpManager:Post("Explore/exitExplore", SIGNALNAMES.Exploration_ChooseExitExplore_Callback, data)
	end
end

return ExplorationChooseCommand