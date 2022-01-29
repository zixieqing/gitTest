local SimpleCommand = mvc.SimpleCommand

local AssistCommand = class("AssistCommand", SimpleCommand)
function AssistCommand:ctor(  )
	self.super:ctor()
	self.executed = false 
end

function AssistCommand:Execute( signal )
	self.executed = true
	local name = signal:GetName()
	local httpManager = AppFacade.GetInstance():GetManager("HttpManager")
	if name == COMMANDS.COMMAND_Assist_Share then
		local data = signal:GetBody()
		httpManager:Post("Takeaway/share", SIGNALNAMES.Assist_Share_Callback, data)
	elseif name == COMMANDS.COMMAND_Assist_OrdinarySubmit then
		local data = signal:GetBody()
		httpManager:Post("Takeaway/assistanceSubmit", SIGNALNAMES.Assist_OrdinarySubmit_Callback, data)
	elseif name == COMMANDS.COMMAND_Assist_HugeSubmit then 
		local data = signal:GetBody()
		httpManager:Post("Takeaway/hugeOrderSubmit", SIGNALNAMES.Assist_HugeSubmit_Callback, data)
	elseif name == COMMANDS.COMMAND_Assist_assistance then
		httpManager:Post("Takeaway/assistance", SIGNALNAMES.Assist_Assistance_Callback)
	elseif name == COMMANDS.COMMAND_Assist_Refresh then
		httpManager:Post("Takeaway/flushAssistance", SIGNALNAMES.Assist_Refresh_Callback)
	end
end

return AssistCommand