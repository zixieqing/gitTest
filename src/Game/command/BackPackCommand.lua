local SimpleCommand = mvc.SimpleCommand


local BackPackCommand = class("BackPackCommand", SimpleCommand)


function BackPackCommand:ctor( )
	self.super:ctor()
	self.executed = false
end

function BackPackCommand:Execute( signal )
	self.executed = true
	--发送网络请求
    local name = signal:GetName()
    local httpManager = AppFacade.GetInstance():GetManager("HttpManager")
    if name == COMMANDS.COMMAND_BackPack then
        -- httpManager:Post("BackPack/backPack",SIGNALNAMES.BackPack_Name_Callback)
    elseif name == COMMANDS.COMMAND_BackPack_Sale then
        local data = signal:GetBody()
        httpManager:Post("Backpack/sell",SIGNALNAMES.BackPack_SaleGoods_Callback,data)
    elseif name == COMMANDS.COMMAND_BackPack_Use then
        local data = signal:GetBody()
        httpManager:Post("backpack/useProps",SIGNALNAMES.BackPack_UseGoods_Callback,data)


    end
end

return BackPackCommand