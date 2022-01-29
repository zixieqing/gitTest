local SimpleCommand = mvc.SimpleCommand

local MarketSaleCommand = class("MarketSaleCommand", SimpleCommand)


function MarketSaleCommand:ctor( )
	self.super:ctor()
	self.executed = false
end

function MarketSaleCommand:Execute( signal )
	self.executed = true
	--发送网络请求
    local name = signal:GetName()
    local httpManager = AppFacade.GetInstance():GetManager("HttpManager")
    if name == COMMANDS.COMMAND_Market_Consignment then -- 购买
        local data = signal:GetBody()
        httpManager:Post("market/consignmentGoods",SIGNALNAMES.Market_Consignment_Callback, data)
    elseif name == COMMANDS.COMMAND_Market_MyMarket then -- 获取寄售信息
        httpManager:Post("market/myMarket",SIGNALNAMES.Market_MyMarket_Callback)      
    end
end

return MarketSaleCommand