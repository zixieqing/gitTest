local SimpleCommand = mvc.SimpleCommand


local ShopCommand = class("ShopCommand", SimpleCommand)


function ShopCommand:ctor( )
	self.super:ctor()
	self.executed = false
end

function ShopCommand:Execute( signal )
	self.executed = true
	--发送网络请求
    local name = signal:GetName()
    local httpManager = AppFacade.GetInstance():GetManager("HttpManager")
    if name == COMMANDS.COMMANDS_Restaurant_Shop_Home then
        httpManager:Post("mall/home",SIGNALNAMES.Restaurant_Shop_Home_Callback)
    elseif name == COMMANDS.COMMANDS_All_Shop_Buy then --COMMANDS_All_Shop_Buy
        local data = signal:GetBody()
        httpManager:Post("mall/buy",SIGNALNAMES.All_Shop_Buy_Callback,data)
    elseif name == COMMANDS.COMMANDS_Restaurant_Shop_Refresh then
        httpManager:Post("mall/restaurantRefresh",SIGNALNAMES.Restaurant_Shop_Refresh_Callback)
    elseif name == COMMANDS.COMMANDS_All_Shop_GetPayOrder then
        local data = signal:GetBody()
        httpManager:Post("pay/order",SIGNALNAMES.Restaurant_Shop_GetPayOrder_Callback,data)        
    elseif name == COMMANDS.COMMANDS_PVC_Shop_Refresh then
        httpManager:Post("mall/arenaRefresh",SIGNALNAMES.PVC_Shop_Refresh_Callback)        
    elseif name == COMMANDS.COMMANDS_PVC_Shop_Home then
        httpManager:Post("mall/home",SIGNALNAMES.PVC_Shop_Home_Callback)  
    elseif name == COMMANDS.COMMANDS_KOF_Shop_Refresh then
        httpManager:Post("mall/kofArenaRefresh",SIGNALNAMES.KOF_Shop_Refresh_Callback)        
    elseif name == COMMANDS.COMMANDS_SHOP_AVATAR then
        httpManager:Post("mall/avatar", SIGNALNAMES.SHOP_AVATAR_CALLBACK)
    elseif name == COMMANDS.COMMANDS_SHOP_AVATAR_BUYAVATAR then
        local data = signal:GetBody()
        httpManager:Post("mall/buyAvatar", SIGNALNAMES.SHOP_AVATAR_BUYAVATAR_CALLBACK, data)      
    end
end

return ShopCommand