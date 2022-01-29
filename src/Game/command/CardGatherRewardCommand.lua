local SimpleCommand = mvc.SimpleCommand

local CardGatherRewardCommand = class("CardGatherRewardCommand", SimpleCommand)
function CardGatherRewardCommand:ctor(  )
	self.super:ctor()
	self.executed = false 
end

function CardGatherRewardCommand:Execute( signal )
	self.executed = true
	local name = signal:GetName()
	local httpManager = AppFacade.GetInstance():GetManager("HttpManager")
	if name == COMMANDS.COMMANDS_CARD_GATHER_AREA_REWARD then
		local data = signal:GetBody()
		httpManager:Post("cardCollection/areaReward", SIGNALNAMES.CARD_GATHER_AREA_REWARD_CALLBACK, data)
	elseif name == COMMANDS.COMMANDS_CARD_GATHER_CP_REWARD then 
		local data = signal:GetBody()
		httpManager:Post("cardCollection/groupReward", SIGNALNAMES.CARD_GATHER_CP_REWARD_CALLBACK, data)
	end
end

return CardGatherRewardCommand