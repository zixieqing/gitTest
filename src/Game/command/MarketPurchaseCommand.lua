local SimpleCommand = mvc.SimpleCommand

local MarketPurchaseCommand = class("MarketPurchaseCommand", SimpleCommand)


function MarketPurchaseCommand:ctor( )
	self.super:ctor()
	self.executed = false
end

function MarketPurchaseCommand:Execute( signal )
	self.executed = true
	--发送网络请求
    local name = signal:GetName()
    local httpManager = AppFacade.GetInstance():GetManager("HttpManager")
    if name == COMMANDS.COMMAND_Market_Purchase then -- 购买
        local data = signal:GetBody()
        httpManager:Post("market/purchaseGoods",SIGNALNAMES.Market_Purchase_Callback, data)
    elseif name == COMMANDS.COMMAND_Market_Refresh then -- 刷新
        httpManager:Post("market/refreshMarket",SIGNALNAMES.Market_Refresh_Callback) 
    elseif name == COMMANDS.COMMAND_Market_Market then -- 市场信息
        httpManager:Post("market/market",SIGNALNAMES.Market_Market_Callback)          
    end
end

return MarketPurchaseCommand