local SimpleCommand = mvc.SimpleCommand

local AnnouncementCommand = class("AnnouncementCommand", SimpleCommand)
function AnnouncementCommand:ctor(  )
	self.super:ctor()
	self.executed = false
end

function AnnouncementCommand:Execute( signal )
	self.executed = true
	local name = signal:GetName()
	local httpManager = AppFacade.GetInstance():GetManager("HttpManager")
	if name == COMMANDS.COMMAND_Announcement then
		httpManager:Post("notice/publicNotice", SIGNALNAMES.Announcement_Name_Callback)
	end
end

return AnnouncementCommand