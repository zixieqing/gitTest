local SimpleCommand = mvc.SimpleCommand

local StartDeliveryOrderCommand = class("StartDeliveryOrderCommand", SimpleCommand)
local httpManager = AppFacade.GetInstance():GetManager("HttpManager")

function StartDeliveryOrderCommand:ctor( )
	self.super:ctor()
	self.executed = false
end
function StartDeliveryOrderCommand:Execute( signal )
	self.executed = true
	local name = signal:GetName()
    local data = signal:GetBody()
    if name == COMMANDS.COMMANDS_StartDeliveryOrder_Dlivery then
        --订单发车
        httpManager:Post("Takeaway/delivery",SIGNALNAMES.StartDeliveryOrder_Dlivery,data)
    elseif name == COMMANDS.COMMANDS_StartDeliveryOrder_Cancel then
        --订单取消
        httpManager:Post("Takeaway/deliveryAbort",SIGNALNAMES.StartDeliveryOrder_Cancel, data)
    elseif name  == COMMANDS.COMMANDS_StartDeliveryTakeAway_Home then
        httpManager:Post("Takeaway/home",SIGNALNAMES.StartDeliveryTakeAway_Home)
    elseif name  == COMMANDS.COMMANDS_StartDeliveryOrder_Refuse then
        httpManager:Post("Takeaway/cancel",SIGNALNAMES.StartDeliveryOrder_Refuse,data)
    end
end

return StartDeliveryOrderCommand