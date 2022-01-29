local Command = require( 'Frame.Opera.Command' )

local Director = require( "Frame.Opera.Director" )

local FightCommand = Command:New()

FightCommand.NAME = "FightCommand"


--[[--*
* @param color 对应的色彩值
* @param time 持续时间
--]]
function FightCommand:New(color, time)
    local this = {}
    setmetatable( this, {__index = FightCommand} )
    this.inAction = true
    return this
end
--[[
设置图象的反转
@param color 色彩值
--]]
function FightCommand:SetColor( color )
    this.color = ccc4FromInt(color)
end

function FightCommand:CanMoveNext()
    return false
end

--[[
--执行方法的虚方法
--真实调用的方法逻辑
--执行窗口抖动
--]]
function FightCommand:Execute( )
    --执行方法的虚方法
    --去模拟战斗页面
    local battleConstructor = require('battleEntry.BattleConstructor').new()
    local fromToStruct      = BattleMediatorsConnectStruct.New('AuthorMediator', 'AuthorTransMediator')
    battleConstructor:InitDataByPerformanceStageId(8999, nil, fromToStruct)
    if not AppFacade.GetInstance():RetrieveMediator('EnterBattleMediator') then
        local enterBattleMediator = require('Game.mediator.EnterBattleMediator').new()
        AppFacade.GetInstance():RegistMediator(enterBattleMediator)
    end
    AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.Battle_Enter, battleConstructor)
end

return FightCommand
