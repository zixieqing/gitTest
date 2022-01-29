local SimpleCommand = mvc.SimpleCommand

local LargeAndOrdinaryCommand = class("LargeAndOrdinaryCommand", SimpleCommand)
local httpManager = AppFacade.GetInstance():GetManager("HttpManager")

function LargeAndOrdinaryCommand:ctor( )
	self.super:ctor()
	self.executed = false
end
function LargeAndOrdinaryCommand:Execute( signal )
	self.executed = true
	local name = signal:GetName()
    local data = signal:GetBody()
	local httpManager = AppFacade.GetInstance():GetManager("HttpManager")
    if name == COMMANDS.COMMANDS_LargeAndOrdinary_TakeAwayReward then
        --充值体力
        httpManager:Post("Takeaway/draw",SIGNALNAMES.LargeAndOrdinary_TakeAwayReward,data)
    elseif name == COMMANDS.COMMANDS_LargeAndOrdinary_TakeAwayOrder then 
        httpManager:Post("Takeaway/order",SIGNALNAMES.LargeAndOrdinary_TakeAwayOrder,data)
    end
end

return LargeAndOrdinaryCommand