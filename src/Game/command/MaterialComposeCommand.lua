local SimpleCommand = mvc.SimpleCommand


local MaterialComposeCommand = class("MaterialComposeCommand", SimpleCommand)


function MaterialComposeCommand:ctor( )
    self.super:ctor()
    self.executed = false
end

function MaterialComposeCommand:Execute( signal )
    self.executed = true
    --发送网络请求
    local name = signal:GetName()
    local httpManager = AppFacade.GetInstance():GetManager("HttpManager")
    if name == COMMANDS.COMMANDS_Material_Compose then
        local data = signal:GetBody()
        httpManager:Post("backpack/materialCompound",SIGNALNAMES.Material_Compose_Callback,data)
    -- elseif name == COMMANDS.COMMANDS_CardsFragment_MultiCompose then
    --     local data = signal:GetBody()
    --     httpManager:Post("backpack/cardFragmentCompoundMulti",SIGNALNAMES.CardsFragment_MultiCompose_Callback,data)
    end
end

return MaterialComposeCommand