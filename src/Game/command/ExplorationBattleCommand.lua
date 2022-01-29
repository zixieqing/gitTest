local SimpleCommand = mvc.SimpleCommand

local ExplorationBattleCommand = class("ExplorationBattleCommand", SimpleCommand)
function ExplorationBattleCommand:ctor(  )
	self.super:ctor()
	self.executed = false 
end

function ExplorationBattleCommand:Execute( signal )
	self.executed = true
	local name = signal:GetName()
	local httpManager = AppFacade.GetInstance():GetManager("HttpManager")
	if name == COMMANDS.COMMAND_Exploration_DrawBaseReward then
		local data = signal:GetBody()
		httpManager:Post("Explore/drawBaseReward", SIGNALNAMES.Exploration_DrawBaseReward_Callback, data)
	elseif name == COMMANDS.COMMAND_Exploration_DrawChestReward then
		local data = signal:GetBody()
		httpManager:Post("Explore/drawChestReward", SIGNALNAMES.Exploration_DrawChestReward_Callback, data)
	elseif name == COMMANDS.COMMAND_Exploration_ExitExplore then
		local data = signal:GetBody()
		httpManager:Post("Explore/exitExplore", SIGNALNAMES.Exploration_ExitExplore_Callback, data)
	elseif name == COMMANDS.COMMAND_Exploration_BuyBossFightNum then
		local data = signal:GetBody()
		httpManager:Post("Explore/buyBossFightNum", SIGNALNAMES.Exploration_BuyBossFightNum_Callback, data)
	end
end

return ExplorationBattleCommand