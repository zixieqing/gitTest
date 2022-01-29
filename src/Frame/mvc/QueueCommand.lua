---@class QueueCommand : Dispatch
local QueueCommand = class("QueueCommand", mvc.Dispatch)


function QueueCommand:ctor(  )
	mvc.Dispatch.ctor(self)
	---@type SimpleCommand[] | QueueCommand[]
	self.subCommands = {}
	self:InitalSubCommand()
end


function QueueCommand:InitalSubCommand(  )
end


---@param commandClassRef SimpleCommand | QueueCommand
function QueueCommand:AddSubCommand( commandClassRef )
	table.insert( self.subCommands, commandClassRef)
end


function QueueCommand:Execute( signal )
	repeat
		local ref = table.remove( self.subCommands, 1 )
		---@type SimpleCommand | QueueCommand
		local command = ref:New()
		command:Inital(self.targetKey)
		command:Execute(signal) --执行所有命令集合
	until (next( self.subCommands) == nil)
end


return QueueCommand
