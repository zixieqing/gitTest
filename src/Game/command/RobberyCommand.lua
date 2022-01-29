local SimpleCommand = mvc.SimpleCommand

local RobberyCommand = class("RobberyCommand", SimpleCommand)
function RobberyCommand:ctor(  )
	self.super:ctor()
	self.executed = false
end

function RobberyCommand:Execute( signal )
	self.executed = true
	local name = signal:GetName()
	local httpManager = AppFacade.GetInstance():GetManager("HttpManager")
	if name == COMMANDS.COMMAND_RobberyView_Name_Callback then
		local data = signal:GetBody()
		httpManager:Post("Takeaway/robbery", SIGNALNAMES.RobberyView_Name_Callback,data)
	elseif name == COMMANDS.COMMAND_RobberyOneDetaiView_Name_Callback then
		local data = signal:GetBody()
		httpManager:Post("Takeaway/order", SIGNALNAMES.RobberyOneDetailView_Name_Callback,data)
	elseif name == COMMANDS.COMMAND_RobberyResult_Name_Callback then
		local data = signal:GetBody()
		httpManager:Post("Lobby/robberyResult", SIGNALNAMES.RobberyResult_Name_Callback, data)
	elseif name == COMMANDS.COMMAND_RobberyDetailView_Name_Callback then
		httpManager:Post("Takeaway/robberyHistory", SIGNALNAMES.RobberyDetailView_Name_Callback, data)
	end
end

return RobberyCommand