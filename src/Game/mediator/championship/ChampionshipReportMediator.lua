--[[
 * author : kaishiqi
 * descpt : 武道会 - 战报中介者
]]
local ChampionshipReportView     = require('Game.views.championship.ChampionshipReportView')
local ChampionshipReportMediator = class('ChampionshipReportMediator', mvc.Mediator)

local MAIN_PROXY_NAME     = FOOD.CHAMPIONSHIP.MAIN.PROXY_NAME
local MAIN_PROXY_STRUCT   = FOOD.CHAMPIONSHIP.MAIN.PROXY_STRUCT
local REPORT_PROXY_NAME   = FOOD.CHAMPIONSHIP.REPORT.PROXY_NAME
local REPORT_PROXY_STRUCT = FOOD.CHAMPIONSHIP.REPORT.PROXY_STRUCT

function ChampionshipReportMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'ChampionshipReportMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance

function ChampionshipReportMediator:Initial(key)
    self.super.Initial(self, key)

    -- init vars
    local reportType     = self.ctorArgs_.type
    self.isControllable_ = true

    -- init model
    self.mainProxy_   = app:RetrieveProxy(MAIN_PROXY_NAME)
    self.reportProxy_ = regVoProxy(REPORT_PROXY_NAME, REPORT_PROXY_STRUCT)
    self.reportProxy_:set(REPORT_PROXY_STRUCT.REPORT_TYPE, reportType)
    self:initReportModel_()

    -- create view
    self.viewNode_ = ChampionshipReportView.new()
    self:SetViewComponent(self:getViewNode())
    app.uiMgr:GetCurrentScene():AddDialog(self:getViewNode())

    -- add listener
    ui.bindClick(self:getViewData().blockLayer, handler(self, self.onClickBackButtonHandler_), false)
    self:getViewData().reportTableView:setCellInitHandler(function(cellViewData)
        ui.bindClick(cellViewData.replayBtn, handler(self, self.onClickReportCellReplayButtonHandler_))
    end)
end


function ChampionshipReportMediator:CleanupView()
    unregVoProxy(REPORT_PROXY_NAME)

    if self:getViewNode() and not tolua.isnull(self:getViewNode()) then
        self:getViewNode():removeFromParent()
        self.viewNode_ = nil
    end
end


function ChampionshipReportMediator:OnRegist()
end


function ChampionshipReportMediator:OnUnRegist()
end


function ChampionshipReportMediator:InterestSignals()
    return {}
end
function ChampionshipReportMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()
end


-------------------------------------------------
-- get / set

function ChampionshipReportMediator:getViewNode()
    return  self.viewNode_
end
function ChampionshipReportMediator:getViewData()
    return self:getViewNode():getViewData()
end


-------------------------------------------------
-- public

function ChampionshipReportMediator:close()
    app:UnRegsitMediator(self:GetMediatorName())
end


-------------------------------------------------
-- private

function ChampionshipReportMediator:initReportModel_()
    local reportType = self.reportProxy_:get(REPORT_PROXY_STRUCT.REPORT_TYPE)
    
    -- 战斗记录
    if reportType == FOOD.CHAMPIONSHIP.REPORT.TYPE.BATTLE then
        local matchIdList  = table.keys(self.mainProxy_:get(MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.PROMOTION_MATCHES):getData())
        local scheduleStep = self.mainProxy_:get(MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.SCHEDULE_STEP)
        local endedStepId  = 0
        for roundNum, stepDefine in ipairs(FOOD.CHAMPIONSHIP.ROUND_NUM) do
            local beganStep = checkint(stepDefine.beganStep)
            local endedStep = checkint(stepDefine.endedStep)
            if beganStep <= scheduleStep and scheduleStep <= endedStep then
                endedStepId = endedStep
                break
            end
        end
        -- 过滤掉进度还未达到的比赛
        for index = #matchIdList, 1, -1 do
            if checkint(matchIdList[index]) > endedStepId then
                table.remove(matchIdList, index)
            end
        end
        table.sort(matchIdList, function(a, b)
            return checkint(a) > checkint(b)
        end)
        self.reportProxy_:set(REPORT_PROXY_STRUCT.PROMOTION_MATCHES, matchIdList)

    -- 竞猜记录
    elseif reportType == FOOD.CHAMPIONSHIP.REPORT.TYPE.GUESS then
        local matchIdList = table.keys(self.mainProxy_:get(MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.GUESS_DETAIL):getData())
        table.sort(matchIdList, function(a, b)
            return checkint(a) > checkint(b)
        end)
        self.reportProxy_:set(REPORT_PROXY_STRUCT.PROMOTION_MATCHES, matchIdList)
    end
end



-------------------------------------------------
-- handler

function ChampionshipReportMediator:onClickBackButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    self:close()
end


function ChampionshipReportMediator:onClickReportCellReplayButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local cellIndex       = checkint(sender:getTag())
    local CELL_STRUCT     = REPORT_PROXY_STRUCT.PROMOTION_MATCHES.MATCH_ID
    local cellMatchId     = self.reportProxy_:get(CELL_STRUCT, cellIndex)
    local SCHEDULE_STRUCT = MAIN_PROXY_STRUCT.MAIN_HOME_TAKE.PROMOTION_SCHEDULE
    local dataProxy       = self.mainProxy_:get(SCHEDULE_STRUCT.MATCH_DATA, tostring(cellMatchId))
    local attackerId      = dataProxy:get(SCHEDULE_STRUCT.MATCH_DATA.ATTACKER_ID)
    local defenderId      = dataProxy:get(SCHEDULE_STRUCT.MATCH_DATA.DEFENDER_ID)
    if attackerId > 0 and defenderId > 0 then
        local replayMdt   = require('Game.mediator.championship.ChampionshipReplayMediator').new({matchId = cellMatchId})
        app:RegistMediator(replayMdt)
    else
        app.uiMgr:ShowInformationTips(__('有选手放弃了比赛，无法回看'))
    end
end


return ChampionshipReportMediator
