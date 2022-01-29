--[[
 * author : kaishiqi
 * descpt : 爬塔 - root中介者
]]
local TowerModelFactory      = require('Game.models.TowerQuestModelFactory')
local TowerQuestModel        = TowerModelFactory.getModelType('TowerQuest')
local TowerQuestRootMediator = class('TowerQuestRootMediator', mvc.Mediator)

function TowerQuestRootMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'TowerQuestRootMediator', viewComponent)
end


-------------------------------------------------
-- inheritance method

function TowerQuestRootMediator:Initial(key)
    self.super.Initial(self, key)

    self.towerModel_ = TowerQuestModel.new()
end


function TowerQuestRootMediator:CleanupView()
    SpineCache(SpineCacheName.TOWER):clearCache()
end


function TowerQuestRootMediator:OnRegist()
end
function TowerQuestRootMediator:OnUnRegist()
end


function TowerQuestRootMediator:InterestSignals()
    return {
    }
end
function TowerQuestRootMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()
end


-------------------------------------------------
-- get / set

function TowerQuestRootMediator:getTowerModel()
    return self.towerModel_
end


function TowerQuestRootMediator:getBattleResultData()
    return self.battleResultData_
end
function TowerQuestRootMediator:setBattleResultData(resultData)
    self.battleResultData_ = resultData
end


return TowerQuestRootMediator
