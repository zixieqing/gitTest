local SimpleCommand = mvc.SimpleCommand

local BattleSocketCommand = class("BattleSocketCommand", SimpleCommand)

local shareFacade = AppFacade.GetInstance()
local dataMgr = shareFacade:GetManager("DataManager")

function BattleSocketCommand:ctor( )
	self.super:ctor()
	self.executed = false
end

function BattleSocketCommand:Execute( signal )
    self.executed = true
    local name = signal:GetName()
    local data = signal:GetBody()
    print('here check socket start data>>>>>>>>>>>>>>')
    dump(data)
    if COMMANDS.COMMANDS_Battle_Start_Socket == name then
        ------------ 起socket ------------
        AppFacade.GetInstance():AddManager("battleEntry.network.BattleSocketManager")
        local bsm = AppFacade.GetInstance():GetManager("BattleSocketManager")
        bsm:Connect(data.ip, data.port)
    -- debug --
        bsm:SetOnConnectedSuccess(function ()
            -- 连接成功 进入队伍
            bsm:SendPacket(4001, {questTeamId = data.questTeamId, password = data.password})
        end)
    -- debug --
        AppFacade.GetInstance():UnRegsitSignal(COMMANDS.COMMANDS_Battle_Start_Socket)
    end
end

return BattleSocketCommand
