local SimpleCommand = mvc.SimpleCommand

local RankingListCommand = class("RankingListCommand", SimpleCommand)
function RankingListCommand:ctor(  )
	self.super:ctor()
	self.executed = false 
end

function RankingListCommand:Execute( signal )
	self.executed = true
	local name = signal:GetName()
	local httpManager = AppFacade.GetInstance():GetManager("HttpManager")
	if name == COMMANDS.COMMAND_Rank_Restaurant then
		httpManager:Post('Rank/restaurant',SIGNALNAMES.Rank_Restaurant_Callback)
	elseif name == COMMANDS.COMMAND_Rank_RestaurantRevenue then
		httpManager:Post('Rank/restaurantRevenue',SIGNALNAMES.Rank_RestaurantRevenue_Callback)
	elseif name == COMMANDS.COMMAND_Rank_Tower then
		httpManager:Post('Rank/tower',SIGNALNAMES.Rank_Tower_Callback)
	elseif name == COMMANDS.COMMAND_Rank_TowerHistory then
		httpManager:Post('Rank/towerHistory',SIGNALNAMES.Rank_TowerHistory_Callback)
	elseif name == COMMANDS.COMMAND_Rank_ArenaRank then
		httpManager:Post('Rank/arenaRank',SIGNALNAMES.Rank_ArenaRank_Callback)
	elseif name == COMMANDS.COMMAND_Rank_Airship then	
		httpManager:Post('Rank/airship',SIGNALNAMES.Rank_Airship_Callback)
	elseif name == COMMANDS.COMMAND_Rank_Union_Contribution then	
		httpManager:Post('Rank/unionContributionPoint',SIGNALNAMES.Rank_Union_Contribution_Callback)
	elseif name == COMMANDS.COMMAND_Rank_Union_ContributionHistory then	
		httpManager:Post('Rank/unionContributionPointHistory',SIGNALNAMES.Rank_Union_ContributionHistory_Callback)
	elseif name == COMMANDS.COMMAND_Rank_Union_GodBeast then	
		httpManager:Post('Rank/unionGodBeast',SIGNALNAMES.Rank_Union_GodBeast_Callback)
	elseif name == COMMANDS.COMMAND_Rank_BOSS_Person then
		httpManager:Post('Rank/worldBossPlayer',SIGNALNAMES.Rank_BOSS_Person_Callback)
	elseif name == COMMANDS.COMMAND_Rank_BOSS_Union then
		httpManager:Post('Rank/worldBossUnion',SIGNALNAMES.Rank_BOSS_Union_Callback)
	end
end

return RankingListCommand