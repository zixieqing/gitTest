local SimpleCommand = mvc.SimpleCommand

local CardManualCommand = class("CardManualCommand", SimpleCommand)
function CardManualCommand:ctor(  )
	self.super:ctor()
	self.executed = false
end

function CardManualCommand:Execute( signal )
	self.executed = true
	local name = signal:GetName()
	local httpManager = AppFacade.GetInstance():GetManager("HttpManager")
	if name == COMMANDS.COMMAND_Collection_CardStoryUnlock then
		local data = signal:GetBody()
		httpManager:Post("Collection/cardStoryUnlock", SIGNALNAMES.Collection_CardStoryUnlock_Callback, data)
	elseif name == COMMANDS.COMMAND_Collection_CardVoiceUnlock then
		local data = signal:GetBody()
		httpManager:Post("Collection/cardVoiceUnlock", SIGNALNAMES.Collection_CardVoiceUnlock_Callback, data)
	end
end

return CardManualCommand