local SimpleCommand = mvc.SimpleCommand


local IceRoomCommand = class("IceRoomCommand", SimpleCommand)


function IceRoomCommand:ctor( )
	self.super:ctor()
	self.executed = false
end

function IceRoomCommand:Execute( signal )
	self.executed = true
	--发送网络请求
    local name = signal:GetName()
    local action = signal:GetType()
    local httpManager = AppFacade.GetInstance():GetManager("HttpManager")
    if name == COMMANDS.COMMANDS_ICEPLACE then
        local data = signal:GetBody() or  {}
        if action == 'home' then
            httpManager:Post("IcePlace/home",SIGNALNAMES.IcePlace_Home_Callback ,data)
        elseif action == 'unlock' then
            local data = signal:GetBody()
            httpManager:Post("IcePlace/unlockIcePlace",SIGNALNAMES.IcePlace_Unlock_Callback,data)
        elseif action == 'addCard' then
            local data = signal:GetBody()
            httpManager:Post(string.format("IcePlace/addCardInIcePlace/playerCardId/%d",checkint(data.playerCardId)),SIGNALNAMES.IcePlace_AddCard_Callback,data, true)
        elseif action == 'removeCard' then
            local data = signal:GetBody()
            httpManager:Post("IcePlace/addCardInIcePlace",SIGNALNAMES.IcePlace_RemoveCardOut_Callback,data, true)
        elseif action == 'unlockPosition' then
            local data = signal:GetBody()
            httpManager:Post("IcePlace/unlockIcePlaceBed", SIGNALNAMES.ICEPLACE_UnLockPosition, data)
        elseif action == 'unload' then
            --单一的下冰场的操作的逻辑
            local data = signal:GetBody()
            httpManager:Post("IcePlace/removeCard", SIGNALNAMES.ICEPLACE_UnLoad, data)
        elseif action == 'addMultiCard' then
            --单一的下冰场的操作的逻辑
            local data = signal:GetBody()
            httpManager:Post("IcePlace/addMultiCardInIcePlace", SIGNALNAMES.ICEPLACE_ADD_MULTI_CARD, data)
        end
    end
end

return IceRoomCommand
