--[[
 * author : kaishiqi
 * descpt : 武道会 - 赛程中介者
]]
local ChampionshipScheduleView     = require('Game.views.championship.ChampionshipScheduleView')
local ChampionshipScheduleMediator = class('ChampionshipScheduleMediator', mvc.Mediator)

function ChampionshipScheduleMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'ChampionshipScheduleMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance

function ChampionshipScheduleMediator:Initial(key)
    self.super.Initial(self, key)

    -- init vars
    self.isControllable_ = true

    -- create view
    self.viewNode_ = ChampionshipScheduleView.new()
    self:SetViewComponent(self:getViewNode())
    app.uiMgr:GetCurrentScene():AddDialog(self:getViewNode())

    -- add listener
    ui.bindClick(self:getViewData().backBtn, handler(self, self.onClickBackButtonHandler_))
    ui.bindClick(self:getViewData().titleBtn, handler(self, self.onClickTitleButtonHandler_))
end


function ChampionshipScheduleMediator:CleanupView()
    if self:getViewNode() and not tolua.isnull(self:getViewNode()) then
        self:getViewNode():removeFromParent()
        self.viewNode_ = nil
    end
end


function ChampionshipScheduleMediator:OnRegist()
end


function ChampionshipScheduleMediator:OnUnRegist()
end


function ChampionshipScheduleMediator:InterestSignals()
    return {}
end
function ChampionshipScheduleMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()
end


-------------------------------------------------
-- get / set

function ChampionshipScheduleMediator:getViewNode()
    return  self.viewNode_
end
function ChampionshipScheduleMediator:getViewData()
    return self:getViewNode():getViewData()
end


-------------------------------------------------
-- public

function ChampionshipScheduleMediator:close()
    app:UnRegsitMediator(self:GetMediatorName())
end


-------------------------------------------------
-- handler

function ChampionshipScheduleMediator:onClickBackButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    self:close()
end


function ChampionshipScheduleMediator:onClickTitleButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    app.uiMgr:ShowIntroPopup({moduleId = MODULE_DATA[tostring(RemindTag.CHAMPIONSHIP)]})
end


return ChampionshipScheduleMediator
