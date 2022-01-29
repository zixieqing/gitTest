--[[
 * author : kaishiqi
 * descpt : 武道会 - 投票竞猜中介者
]]
local ChampionshipVoteGuessView     = require('Game.views.championship.ChampionshipVoteGuessView')
local ChampionshipVoteGuessMediator = class('ChampionshipVoteGuessMediator', mvc.Mediator)

local MAIN_PROXY_NAME   = FOOD.CHAMPIONSHIP.MAIN.PROXY_NAME
local MAIN_PROXY_STRUCT = FOOD.CHAMPIONSHIP.MAIN.PROXY_STRUCT

function ChampionshipVoteGuessMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'ChampionshipVoteGuessMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance

function ChampionshipVoteGuessMediator:Initial(key)
    self.super.Initial(self, key)

    -- init vars
    self.ownerNode_      = self.ctorArgs_.ownerNode
    self.isControllable_ = true

    -- init model
    self.mainProxy_ = app:RetrieveProxy(MAIN_PROXY_NAME)

    -- create view
    if self.ownerNode_ then
        self.viewNode_ = ChampionshipVoteGuessView.new(self.ownerNode_:getContentSize())
        self.ownerNode_:addChild(self:getViewNode())

        -- add listener
        ui.bindClick(self:getViewData().shopBtn, handler(self, self.onClickShopButtonHandler_))
        ui.bindClick(self:getViewData().guessLogBtn, handler(self, self.onClickGuessLogButtonHandler_))
        ui.bindClick(self:getViewData().scheduleFrame, handler(self, self.onClickScheduleFrameHandler_), false)
    end
end


function ChampionshipVoteGuessMediator:CleanupView()
    if self:getViewNode() and not tolua.isnull(self:getViewNode()) then
        self:getViewNode():removeFromParent()
        self.viewNode_ = nil
    end
end


function ChampionshipVoteGuessMediator:OnRegist()
end


function ChampionshipVoteGuessMediator:OnUnRegist()
end


function ChampionshipVoteGuessMediator:InterestSignals()
    return {}
end
function ChampionshipVoteGuessMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()
end


-------------------------------------------------
-- get / set

function ChampionshipVoteGuessMediator:getViewNode()
    return  self.viewNode_
end
function ChampionshipVoteGuessMediator:getViewData()
    return self:getViewNode():getViewData()
end


-------------------------------------------------
-- public

function ChampionshipVoteGuessMediator:close()
    app:UnRegsitMediator(self:GetMediatorName())
end


-------------------------------------------------
-- handler

function ChampionshipVoteGuessMediator:onClickShopButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end
    
    local storeMdt = require('Game.mediator.championship.ChampionshipShopMediator').new()
    app:RegistMediator(storeMdt)
end


function ChampionshipVoteGuessMediator:onClickGuessLogButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local reportMdt = require('Game.mediator.championship.ChampionshipReportMediator').new({type = FOOD.CHAMPIONSHIP.REPORT.TYPE.GUESS})
    app:RegistMediator(reportMdt)
end


function ChampionshipVoteGuessMediator:onClickScheduleFrameHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end
    
    app.uiMgr:AddDialog('Game.views.championship.ChampionshipTimelinePopup')
end


return ChampionshipVoteGuessMediator
