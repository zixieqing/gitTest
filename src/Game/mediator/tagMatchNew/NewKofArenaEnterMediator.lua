--[[
 * descpt : 新天城演武 入口 中介者
]]
local NAME = 'NewKofArenaEnterMediator'
local NewKofArenaEnterMediator = class(NAME, mvc.Mediator)

------------ import ------------
local AppFacadeInstance = AppFacade.GetInstance()
local uiMgr    = AppFacadeInstance:GetManager('UIManager')
local timerMgr = AppFacadeInstance:GetManager("TimerManager")
------------ import ------------

local BUTTON_TAG = {
    RULE        = 100,     -- 规则说明
    FIGHT       = 101,     -- 战斗
}

local SECTION_ACTION_TAG = {
    UP   = 1,
    FLAT = 2,
    DOWN = 3
}

function NewKofArenaEnterMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    self.ctorArgs_ = checktable(params)
end

-------------------------------------------------
-- init method
function NewKofArenaEnterMediator:Initial(key)
    self.super.Initial(self, key)
    self.datas = {}
    -- create view
    local viewComponent = require('Game.views.tagMatchNew.NewKofArenaEnterView').new()
    self.viewData_      = viewComponent:getViewData()
    self:SetViewComponent(viewComponent)
    
    -- init data
    self:initData_()
    -- init view
    self:initView_()
end

function NewKofArenaEnterMediator:initData_()
    self.segmentConf = CONF.NEW_KOF.SEGMENT:GetAll()
end

function NewKofArenaEnterMediator:initView_()
    local viewData   = self:getViewData()
    local actionBtns = viewData.actionBtns

    for tag, btn in pairs(actionBtns) do
        btn:setTag(checkint(tag))
        display.commonUIParams(btn, {cb = handler(self, self.onButtonAction)})    
    end

    -- set rule
    local moduleExplainConf = CONF.BASE.MODULE_DESCR:GetValue('-80')
    self:GetViewComponent():updateRule(moduleExplainConf.descr)
end

function NewKofArenaEnterMediator:OnRegist()
    regPost(POST.NEW_TAG_MATCH_ACTIVITY, true)
    self:enterLayer()
end
function NewKofArenaEnterMediator:OnUnRegist()
    unregPost(POST.NEW_TAG_MATCH_ACTIVITY, true)
    timerMgr:RemoveTimer(NAME)
end

function NewKofArenaEnterMediator:InterestSignals()
    return {
        POST.NEW_TAG_MATCH_ACTIVITY.sglName,
        COUNT_DOWN_ACTION,
    }
end

function NewKofArenaEnterMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local body = signal:GetBody() or {}
    
    if name == POST.NEW_TAG_MATCH_ACTIVITY.sglName then
        local segmentConf = self:getSegmentDataById(body.segmentId)
        local sectionAction = self:getCurrentSectionAction(body.segmentId,body.rankPercent)
        self:GetViewComponent():refreshUi(body,segmentConf,sectionAction)
        self:startCountDown(body.leftSeconds)
        if checkint(body.status) == NEW_MATCH_BATTLE_3V3_TYPE.OPEN and self:getIsFromBattle() then
            self:GetFacade():RetrieveMediator("Router"):Dispatch({name = "HomeMediator"}, {name = "tagMatchNew.NewKofArenaLobbyMediator"})
        end
    elseif name == COUNT_DOWN_ACTION then
        local timerName = tostring(body.timerName)
        if NAME == timerName then
            local countdown = checkint(body.countdown)
            if self:GetViewComponent() and not tolua.isnull(self:GetViewComponent()) then
                self:GetViewComponent():updateCountDown(countdown)
                if countdown <= 0 then
                    self:SendSignal(POST.NEW_TAG_MATCH_ACTIVITY.cmdName)
                end
            end
        end
    end
end 

-------------------------------------------------
-- get / set

function NewKofArenaEnterMediator:getCtorArgs()
    return self.ctorArgs_
end

function NewKofArenaEnterMediator:getViewData()
    return self.viewData_
end

function NewKofArenaEnterMediator:getIsFromBattle()
    return self:getCtorArgs().isFromBattle
end

--[[
    获取相应段位数据
]]
function NewKofArenaEnterMediator:getSegmentDataById(segment)
    segment = checkint(segment)
    for k, v in pairs(self.segmentConf) do
        if segment == checkint(v.id) then
            return v
        end
    end
end

--[[
    根据排名比获取降级｜升级｜保级
]]
function NewKofArenaEnterMediator:getCurrentSectionAction(segmentId, rankPercent)
    local sectionAction
    local rankPercent = checknumber(rankPercent)/100
    if rankPercent == 0 then return nil end 
    for k, v in pairs(self.segmentConf) do
        if checkint(segmentId) == checkint(v.id) then
            local upPercent = checknumber(v.upPercent)
            local downPercent = checknumber(v.downPercent)
            local flatPercent = checknumber(v.flatPercent)
            if rankPercent <= upPercent and upPercent ~= 0 then
                sectionAction = SECTION_ACTION_TAG.UP
            elseif rankPercent <= flatPercent + upPercent then
                sectionAction = SECTION_ACTION_TAG.FLAT
            elseif rankPercent <= 1  and downPercent ~= 0 then
                sectionAction = SECTION_ACTION_TAG.DOWN
            end
        end
    end
    return sectionAction
end
-------------------------------------------------
-- public method
function NewKofArenaEnterMediator:enterLayer()
    self:SendSignal(POST.NEW_TAG_MATCH_ACTIVITY.cmdName)
end

--[[
    开启倒计时
    @params leftSeconds 剩余时间
]]
function NewKofArenaEnterMediator:startCountDown(leftSeconds)
    leftSeconds = checkint(leftSeconds)
    local timerInfo = timerMgr:RetriveTimer(NAME)
    if timerInfo then
        timerMgr:RemoveTimer(NAME)
    end
    if leftSeconds > 0 then
        timerMgr:AddTimer({name = NAME, countdown = leftSeconds})
    else
        AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, timerName = NAME})
    end
end

-------------------------------------------------
-- private method
function NewKofArenaEnterMediator:CleanupView()
    local viewComponent = self:GetViewComponent()
    if viewComponent and not tolua.isnull(viewComponent) then
        viewComponent:setVisible(false)
        viewComponent:setLocalZOrder(-9999)
        viewComponent:runAction(cc.RemoveSelf:create())
    end
end
-------------------------------------------------
-- check

-------------------------------------------------
-- handler
function NewKofArenaEnterMediator:onButtonAction(sender)
    local tag = sender:getTag()
    if tag == BUTTON_TAG.RULE then
        uiMgr:ShowIntroPopup({moduleId = MODULE_DATA[tostring(RemindTag.NEW_TAG_MATCH)]})
    elseif tag == BUTTON_TAG.FIGHT then
        self:GetFacade():RetrieveMediator("Router"):Dispatch({name = "HomeMediator"}, {name = "tagMatchNew.NewKofArenaLobbyMediator"})
    end
end

return NewKofArenaEnterMediator
