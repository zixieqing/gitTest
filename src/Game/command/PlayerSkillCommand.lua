local SimpleCommand = mvc.SimpleCommand

local PlayerSkillCommand = class('PlayerSkillCommand', SimpleCommand)
local httpManager = AppFacade.GetInstance():GetManager("HttpManager")

function PlayerSkillCommand:ctor( )
	SimpleCommand.ctor(self)
	self.executed = false
end

function PlayerSkillCommand:Execute( signal )
	self.executed = true
	-- 发送网络请求
	local name = signal:GetName()
	if COMMANDS.COMMAND_Quest_SwitchPlayerSkill == name then

		local data = signal:GetBody()
		if data then
			httpManager:Post('quest/switchPlayerSkill', SIGNALNAMES.Quest_SwitchPlayerSkill_Callback, data)
		end

	else

	end
end




return PlayerSkillCommand