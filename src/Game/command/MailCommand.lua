local SimpleCommand = mvc.SimpleCommand

local MailCommand = class("MailCommand", SimpleCommand)
function MailCommand:ctor(  )
	self.super:ctor()
	self.executed = false 
end

function MailCommand:Execute( signal )
	self.executed = true
	local name = signal:GetName()
	local httpManager = AppFacade.GetInstance():GetManager("HttpManager")
	if name == COMMANDS.COMMAND_Mail then
		httpManager:Post('Prize/enter',SIGNALNAMES.Mail_Name_Callback)
	elseif name == COMMANDS.COMMAND_Mail_Draw then
		local data = signal:GetBody()
		httpManager:Post('Prize/draw',SIGNALNAMES.Mail_Get_Callback, data)
	elseif name == COMMANDS.COMMAND_Mail_Delete then
		local data = signal:GetBody()
		httpManager:Post('Prize/delete',SIGNALNAMES.Mail_Delete_Callback, data)
	end
end

return MailCommand
