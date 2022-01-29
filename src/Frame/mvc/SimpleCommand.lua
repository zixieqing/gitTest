---@class SimpleCommand : Dispatch
local SimpleCommand = class("SimpleCommand", mvc.Dispatch)


function SimpleCommand:ctor(  )
	mvc.Dispatch.ctor(self)
end


---@param signal Signal
function SimpleCommand:Execute( signal )
	--执行指定的信号
end


return SimpleCommand
