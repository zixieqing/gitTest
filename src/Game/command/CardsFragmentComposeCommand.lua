local SimpleCommand = mvc.SimpleCommand


local CardsFragmentComposeCommand = class("CardsFragmentComposeCommand", SimpleCommand)


function CardsFragmentComposeCommand:ctor( )
    self.super:ctor()
    self.executed = false
end

function CardsFragmentComposeCommand:Execute( signal )
    self.executed = true
    --发送网络请求
    local name = signal:GetName()
    local httpManager = AppFacade.GetInstance():GetManager("HttpManager")
    if name == COMMANDS.COMMANDS_CardsFragment_Compose then
        local data = signal:GetBody()
        httpManager:Post("backpack/cardFragmentCompound",SIGNALNAMES.CardsFragment_Compose_Callback,data)
    elseif name == COMMANDS.COMMANDS_CardsFragment_MultiCompose then
        local data = signal:GetBody()
        httpManager:Post("backpack/cardFragmentCompoundMulti",SIGNALNAMES.CardsFragment_MultiCompose_Callback,data)
    end
end

return CardsFragmentComposeCommand