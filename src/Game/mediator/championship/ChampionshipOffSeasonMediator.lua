--[[
 * author : kaishiqi
 * descpt : 武道会 - 休赛期中介者
]]
local ChampionshipOffSeasonView     = require('Game.views.championship.ChampionshipOffSeasonView')
local ChampionshipOffSeasonMediator = class('ChampionshipOffSeasonMediator', mvc.Mediator)

local MAIN_PROXY_NAME   = FOOD.CHAMPIONSHIP.MAIN.PROXY_NAME
local MAIN_PROXY_STRUCT = FOOD.CHAMPIONSHIP.MAIN.PROXY_STRUCT

function ChampionshipOffSeasonMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'ChampionshipOffSeasonMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance

function ChampionshipOffSeasonMediator:Initial(key)
    self.super.Initial(self, key)

    -- init vars
    self.ownerNode_      = self.ctorArgs_.ownerNode
    self.isControllable_ = true

    -- init model
    self.mainProxy_ = app:RetrieveProxy(MAIN_PROXY_NAME)

    -- create view
    if self.ownerNode_ then
        self.viewNode_ = ChampionshipOffSeasonView.new(self.ownerNode_:getContentSize())
        self.ownerNode_:addChild(self:getViewNode())

        -- add listener
        ui.bindClick(self:getViewData().shopBtn, handler(self, self.onClickShopButtonHandler_))
        ui.bindClick(self:getViewData().championBtn, handler(self, self.onClickChampionButtonHandler_))
        ui.bindClick(self:getViewData().scheduleBtn, handler(self, self.onClickScheduleButtonHandler_))
    end
end


function ChampionshipOffSeasonMediator:CleanupView()
    if self:getViewNode() and not tolua.isnull(self:getViewNode()) then
        self:getViewNode():removeFromParent()
        self.viewNode_ = nil
    end
end


function ChampionshipOffSeasonMediator:OnRegist()
end


function ChampionshipOffSeasonMediator:OnUnRegist()
end


function ChampionshipOffSeasonMediator:InterestSignals()
    return {}
end
function ChampionshipOffSeasonMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()
end


-------------------------------------------------
-- get / set

function ChampionshipOffSeasonMediator:getViewNode()
    return  self.viewNode_
end
function ChampionshipOffSeasonMediator:getViewData()
    return self:getViewNode():getViewData()
end


-------------------------------------------------
-- public

function ChampionshipOffSeasonMediator:close()
    app:UnRegsitMediator(self:GetMediatorName())
end


-------------------------------------------------
-- handler

function ChampionshipOffSeasonMediator:onClickShopButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end
    
    local storeMdt = require('Game.mediator.championship.ChampionshipShopMediator').new()
    app:RegistMediator(storeMdt)
end


function ChampionshipOffSeasonMediator:onClickChampionButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local historyMdt = require('Game.mediator.championship.ChampionshipHistoryChampionMediator').new()
    app:RegistMediator(historyMdt)
end


function ChampionshipOffSeasonMediator:onClickScheduleButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local scheduleMdt = require('Game.mediator.championship.ChampionshipScheduleMediator').new()
    app:RegistMediator(scheduleMdt)
end


return ChampionshipOffSeasonMediator
