--[[
离线竞技场
--]]
local SimpleCommand = mvc.SimpleCommand
local PVCCommand = class('PVCCommand', SimpleCommand)
local httpManager = AppFacade.GetInstance():GetManager("HttpManager")
--[[
constructor
--]]
function PVCCommand:ctor()
	SimpleCommand.ctor(self)
	self.executed = false
end
--[[
@override
--]]
function PVCCommand:Execute(signal)
	self.executed = true

	local name = signal:GetName()
	local data = signal:GetBody()

	if COMMANDS.COMMANDS_PVC_OfflineArena_Home == name then

		-- 离线竞技场 home
		httpManager:Post('offlineArena/home', SIGNALNAMES.PVC_OfflineArena_Home_Callback)

	elseif COMMANDS.COMMANDS_PVC_OfflineArena_SetDefenseTeam == name then

		if data then
			-- 设置防守队伍
			httpManager:Post('offlineArena/setDefenseTeam', SIGNALNAMES.PVC_OfflineArena_SetDefenseTeam_Callback, data)
		end

	elseif COMMANDS.COMMANDS_PVC_OfflineArena_SetFightTeam == name then

		if data then
			-- 设置进攻队伍
			httpManager:Post('offlineArena/setFightTeam', SIGNALNAMES.PVC_OfflineArena_SetFightTeam_Callback, data)
		end

	elseif COMMANDS.COMMANDS_PVC_OfflineArena_MatchOpponent == name then

		-- 更换竞技场对手
		httpManager:Post('offlineArena/matchOpponent', SIGNALNAMES.PVC_OfflineArena_MatchOpponent_Callback)

	elseif COMMANDS.COMMANDS_PVC_OfflineArena_FirstWinReward == name then

		-- 首胜奖励
		httpManager:Post('offlineArena/firstWinReward', SIGNALNAMES.PVC_OfflineArena_FirstWinReward_Callback)

	elseif COMMANDS.COMMANDS_PVC_OfflineArena_BuyArenaQuestTimes == name then

		-- 购买pvc战斗次数
		httpManager:Post('offlineArena/buyArenaQuestTimes', SIGNALNAMES.PVC_OfflineArena_BuyArenaQuestTimes_Callback)

	elseif COMMANDS.COMMANDS_PVC_OfflineArena_ArenaRecord == name then

		-- 查看竞技场战报
		httpManager:Post('offlineArena/arenaRecord', SIGNALNAMES.PVC_OfflineArena_ArenaRecord)

	end

end





return PVCCommand
