local SimpleCommand = mvc.SimpleCommand

local MapCommand = class('MapCommand', SimpleCommand)
local httpManager = AppFacade.GetInstance():GetManager("HttpManager")

function MapCommand:ctor( )
    SimpleCommand.ctor(self)
    self.executed = false
end

function MapCommand:Execute( signal )
    self.executed = true
    -- 发送网络请求
    local name = signal:GetName()
    if COMMANDS.COMMAND_Quest_SwitchCity == name then

        httpManager:Post('quest/switchCity', SIGNALNAMES.Quest_SwitchCity_Callback)

    elseif COMMANDS.COMMAND_Quest_Get_City_Reward == name then

        local data = signal:GetBody()
        if data then
            httpManager:Post('quest/getCityReward', SIGNALNAMES.Quest_GetCityReward_Callback, data)
        end

    elseif COMMANDS.COMMAND_Quest_Draw_City_Reward == name then

        local data = signal:GetBody()
        if data then
            httpManager:Post('quest/drawCityReward', SIGNALNAMES.Quest_DrawCityReward_Callback, data)
        end

    else

    end
end




return MapCommand