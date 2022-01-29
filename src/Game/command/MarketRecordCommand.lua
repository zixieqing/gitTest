local SimpleCommand = mvc.SimpleCommand

local MarketRecordCommand = class("MarketRecordCommand", SimpleCommand)


function MarketRecordCommand:ctor( )
	self.super:ctor()
	self.executed = false
end

function MarketRecordCommand:Execute( signal )
	self.executed = true
	--发送网络请求
    local name = signal:GetName()
    local httpManager = AppFacade.GetInstance():GetManager("HttpManager")
    if name == COMMANDS.COMMAND_Market_MyMarket then -- 获取寄售信息
        httpManager:Post("market/myMarket",SIGNALNAMES.Market_MyMarket_Callback)
    elseif name == COMMANDS.COMMAND_Market_Cancel then -- 取消寄售
        local data = signal:GetBody()
        httpManager:Post("market/cancelConsignment",SIGNALNAMES.Market_CancelConSignment_Callback, data)
    elseif name == COMMANDS.COMMAND_Market_Draw then -- 领取   
        local data = signal:GetBody()
        httpManager:Post("market/draw",SIGNALNAMES.Market_Draw_Callback, data)
    elseif name == COMMANDS.COMMAND_Market_GetGoodsBack then -- 取回背包 
        local data = signal:GetBody()
        httpManager:Post("market/getGoodsBack",SIGNALNAMES.Market_GetGoodsBack_Callback, data) 
    elseif name == COMMANDS.COMMAND_Market_ConsignmentAgain then -- 再次寄售
        local data = signal:GetBody()
        httpManager:Post("market/consignmentAgainGoods",SIGNALNAMES.Market_ConsignmentAgain_Callback, data) 
    end
end

return MarketRecordCommand