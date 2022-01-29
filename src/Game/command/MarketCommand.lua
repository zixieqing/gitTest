local SimpleCommand = mvc.SimpleCommand

local MarketCommand = class("MarketCommand", SimpleCommand)


function MarketCommand:ctor( )
	self.super:ctor()
	self.executed = false
end

function MarketCommand:Execute( signal )
	self.executed = true
	--发送网络请求
    local name = signal:GetName()
    local httpManager = AppFacade.GetInstance():GetManager("HttpManager")
    if name == COMMANDS.COMMAND_Market_Close then -- 获取寄售信息
    	httpManager:Post("market/close", SIGNALNAMES.Market_Close_Callback)
    end
end

return MarketCommand