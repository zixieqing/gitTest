--[[
 * author : kaishiqi
 * descpt : 武道会 - 海选赛排行榜中介者
]]
local ChampionshipAuditionsRankView     = require('Game.views.championship.ChampionshipAuditionsRankView')
local ChampionshipAuditionsRankMediator = class('ChampionshipAuditionsRankMediator', mvc.Mediator)

local MAIN_PROXY_NAME   = FOOD.CHAMPIONSHIP.MAIN.PROXY_NAME
local MAIN_PROXY_STRUCT = FOOD.CHAMPIONSHIP.MAIN.PROXY_STRUCT
local RANK_PROXY_NAME   = FOOD.CHAMPIONSHIP.RANK.PROXY_NAME
local RANK_PROXY_STRUCT = FOOD.CHAMPIONSHIP.RANK.PROXY_STRUCT

function ChampionshipAuditionsRankMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'ChampionshipAuditionsRankMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance

function ChampionshipAuditionsRankMediator:Initial(key)
    self.super.Initial(self, key)

    -- init vars
    self.isControllable_ = true

    -- init model
    self.mainProxy_ = app:RetrieveProxy(MAIN_PROXY_NAME)
    self.rankProxy_ = regVoProxy(RANK_PROXY_NAME, RANK_PROXY_STRUCT)

    -- create view
    self.viewNode_ = ChampionshipAuditionsRankView.new()
    self:SetViewComponent(self:getViewNode())
    app.uiMgr:GetCurrentScene():AddDialog(self:getViewNode())

    -- add listener
    ui.bindClick(self:getViewData().blockLayer, handler(self, self.onClickBackButtonHandler_), false)
end


function ChampionshipAuditionsRankMediator:CleanupView()
    unregVoProxy(RANK_PROXY_NAME)

    if self:getViewNode() and not tolua.isnull(self:getViewNode()) then
        self:getViewNode():removeFromParent()
        self.viewNode_ = nil
    end
end


function ChampionshipAuditionsRankMediator:OnRegist()
    regPost(POST.CHAMPIONSHIP_RANK)

    self:SendSignal(POST.CHAMPIONSHIP_RANK.cmdName)
end


function ChampionshipAuditionsRankMediator:OnUnRegist()
    unregPost(POST.CHAMPIONSHIP_RANK)
end


function ChampionshipAuditionsRankMediator:InterestSignals()
    return {
        POST.CHAMPIONSHIP_RANK.sglName,
    }
end
function ChampionshipAuditionsRankMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    if name == POST.CHAMPIONSHIP_RANK.sglName then
        -- update rank takeData
        self.rankProxy_:set(RANK_PROXY_STRUCT.RANK_TAKE, data)

        -- update mainProxy : myScore / myRank
        local newMyRank  = self.rankProxy_:get(RANK_PROXY_STRUCT.RANK_TAKE.MY_RANK)
        local newMyScore = self.rankProxy_:get(RANK_PROXY_STRUCT.RANK_TAKE.MY_SCORE)
        self.mainProxy_:set(MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.AUDITION_RANK, newMyRank)
        self.mainProxy_:set(MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.AUDITION_SCORE, newMyScore)
    end
end


-------------------------------------------------
-- get / set

function ChampionshipAuditionsRankMediator:getViewNode()
    return  self.viewNode_
end
function ChampionshipAuditionsRankMediator:getViewData()
    return self:getViewNode():getViewData()
end


-------------------------------------------------
-- public

function ChampionshipAuditionsRankMediator:close()
    app:UnRegsitMediator(self:GetMediatorName())
end


-------------------------------------------------
-- handler

function ChampionshipAuditionsRankMediator:onClickBackButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    self:close()
end


return ChampionshipAuditionsRankMediator
