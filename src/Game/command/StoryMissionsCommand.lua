local SimpleCommand = mvc.SimpleCommand

local StoryMissionsCommand = class("StoryMissionsCommand", SimpleCommand)
function StoryMissionsCommand:ctor(  )
	self.super:ctor()
	self.executed = false
end

function StoryMissionsCommand:Execute( signal )
	self.executed = true
	local name = signal:GetName()
	local httpManager = AppFacade.GetInstance():GetManager("HttpManager")
	if name == COMMANDS.COMMAND_StoryMissions_List then   --plotTask/plotTaskList
		httpManager:Post("plotTask/home", SIGNALNAMES.StoryMissions_List_Callback)
	elseif name == COMMANDS.COMMAND_RegionalMissions_List then
		httpManager:Post("branch/branchTaskList", SIGNALNAMES.RegionalMissions_List_Callback)
	elseif name == COMMANDS.COMMAND_Story_AcceptMissions then
		local data = signal:GetBody()
		httpManager:Post("plotTask/acceptPlotTask", SIGNALNAMES.Story_AcceptMissions_Callback, data)


	elseif name == COMMANDS.COMMAND_Regional_AcceptMissions then
		local data = signal:GetBody()
		httpManager:Post("branch/acceptBranchTask", SIGNALNAMES.Story_AcceptMissions_Callback, data)
	elseif name == COMMANDS.COMMAND_Story_DrawReward then
		local data = signal:GetBody()
		httpManager:Post("plotTask/drawPlotReward", SIGNALNAMES.Story_DrawReward_Callback, data)
		
	elseif name == COMMANDS.COMMAND_Regional_DrawReward then
		local data = signal:GetBody()
		httpManager:Post("branch/drawBranchReward", SIGNALNAMES.Story_DrawReward_Callback, data)
 
	elseif name == COMMANDS.COMMAND_Story_SubmitMissions then
		local data = signal:GetBody()
		httpManager:Post("plotTask/submitPlotTask", SIGNALNAMES.Story_SubmitMissions_Callback, data)

	elseif name == COMMANDS.COMMAND_Regional_SubmitMissions then
		local data = signal:GetBody()
		httpManager:Post("branch/submitBranchTask", SIGNALNAMES.Story_SubmitMissions_Callback, data)	
	end
end

return StoryMissionsCommand