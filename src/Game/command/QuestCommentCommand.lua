local SimpleCommand = mvc.SimpleCommand

local QuestCommentCommand = class("QuestCommentCommand", SimpleCommand)
function QuestCommentCommand:ctor(  )
	self.super:ctor()
	self.executed = false
end

function QuestCommentCommand:Execute( signal )
	self.executed = true
	local name = signal:GetName()
	local data = signal:GetBody()
	local httpManager = AppFacade.GetInstance():GetManager("HttpManager")
	if name == COMMANDS.COMMANDS_QuestComment_Disscuss then
		httpManager:Post("quest/discuss", SIGNALNAMES.QuestComment_Discuss,data)
	elseif name == COMMANDS.COMMANDS_QuestComment_DisscussAct then
		httpManager:Post("quest/discussAct", SIGNALNAMES.QuestComment_DiscussAct,data)
	elseif name == COMMANDS.COMMANDS_QuestComment_DisscussList then
		httpManager:Post("quest/discussList", SIGNALNAMES.QuestComment_DiscussList,data)
	end
end

return QuestCommentCommand