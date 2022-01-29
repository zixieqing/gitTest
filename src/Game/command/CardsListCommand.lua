local SimpleCommand = mvc.SimpleCommand


local CardsListCommand = class("CardsListCommand", SimpleCommand)


function CardsListCommand:ctor( )
	self.super:ctor()
	self.executed = false
end

function CardsListCommand:Execute( signal )
	self.executed = true
	--发送网络请求
    local name = signal:GetName()
    local httpManager = AppFacade.GetInstance():GetManager("HttpManager")
    if name == COMMANDS.COMMAND_Hero_LevelUp_Callback then
        local data = signal:GetBody()
        httpManager:Post("card/cardLevelUp",SIGNALNAMES.Hero_LevelUp_Callback,data)
    elseif name == COMMANDS.COMMAND_Hero_Break_Callback then
        local data = signal:GetBody()
        httpManager:Post("card/cardBreakUp",SIGNALNAMES.Hero_Break_Callback,data)
    elseif name == COMMANDS.COMMAND_Hero_SkillUp_Callback then
        local data = signal:GetBody()
        httpManager:Post("card/skillLevelUp",SIGNALNAMES.Hero_SkillUp_Callback,data)
    elseif name == COMMANDS.COMMAND_Hero_Compose_Callback then
        local data = signal:GetBody()
        httpManager:Post("card/cardCompose",SIGNALNAMES.Hero_Compose_Callback,data)
    elseif name == COMMANDS.COMMAND_Hero_EatFood then
        local data = signal:GetBody()
        httpManager:Post("card/feed",SIGNALNAMES.Hero_EatFood_Callback,data)
    elseif name == COMMANDS.COMMAND_Hero_SetSignboard then
        local data = signal:GetBody()
        httpManager:Post("card/defaultCard",SIGNALNAMES.Hero_SetSignboard_Callback,data)
    elseif name == COMMANDS.COMMAND_HERO_MARRIAGE then
        local data = signal:GetBody()
        httpManager:Post("card/marry",SIGNALNAMES.Hero_MARRIAGE_CALLBACK,data)
    end
end

return CardsListCommand