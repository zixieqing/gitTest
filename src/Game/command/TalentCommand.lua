local SimpleCommand = mvc.SimpleCommand

local TalentCommand = class("TalentCommand", SimpleCommand)
function TalentCommand:ctor(  )
	self.super:ctor()
	self.executed = false 
end

function TalentCommand:Execute( signal )
	self.executed = true
	local name = signal:GetName()
	local httpManager = AppFacade.GetInstance():GetManager("HttpManager")
	if name == COMMANDS.COMMAND_Talent_Talents then
		httpManager:Post("talent/talents", SIGNALNAMES.Talent_Talents_Callback)
	elseif name == COMMANDS.COMMAND_Talent_LightTalent then
		local data = signal:GetBody()
		httpManager:Post("talent/lightTalent", SIGNALNAMES.Talent_LightTalent_Callback, data)
	elseif name == COMMANDS.COMMAND_Talent_LevelUp then 
		local data = signal:GetBody()
		httpManager:Post("talent/talentLevelUp", SIGNALNAMES.Talent_LevelUp_Callback, data)
	elseif name == COMMANDS.COMMAND_Talent_Reset then
		local data = signal:GetBody()
		httpManager:Post("talent/resetTalent", SIGNALNAMES.Talent_Reset_Callback, data)
	end
end

return TalentCommand