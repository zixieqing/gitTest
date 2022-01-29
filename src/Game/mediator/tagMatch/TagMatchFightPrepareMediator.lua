--[[
 * descpt : 天城演武 战斗预览 中介者
]]
local NAME = 'TagMatchFightPrepareMediator'
local TagMatchFightPrepareMediator = class(NAME, mvc.Mediator)

local AppFacadeInstance = AppFacade.GetInstance()
local uiMgr    = AppFacadeInstance:GetManager('UIManager')
local gameMgr  = AppFacadeInstance:GetManager("GameManager")
local timerMgr = AppFacadeInstance:GetManager("TimerManager")

-- 进入战斗
local ENTER_TAG_MATCH_BATTLE = 'ENTER_TAG_MATCH_BATTLE'
-- 显示编辑团队界面
local SHOW_TAG_MATCH_EDIT_TEAM = 'SHOW_TAG_MATCH_EDIT_TEAM'

local UPDATE_TEAM_HEAD = 'UPDATE_TEAM_HEAD'

function TagMatchFightPrepareMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    self.ctorArgs_ = checktable(params)
    -- zoneId, stageId
end

-------------------------------------------------
-- init method
function TagMatchFightPrepareMediator:Initial(key)
    self.super.Initial(self, key)

    self.isControllable_ = true
    self.activeJump = true

    -- create view
    local viewComponent = require('Game.views.tagMatch.TagMatchFightPrepareView').new()
    self.viewData_      = viewComponent:getViewData()
    self:SetViewComponent(viewComponent)
    -- add layer
    self.ownerScene_ = uiMgr:GetCurrentScene()
    display.commonUIParams(viewComponent,{po = display.center, ap = display.CENTER})
    self:getOwnerScene():AddDialog(viewComponent)
    
    -- init data
    self:initData_()
    -- init view
    self:initView_()
    
end

function TagMatchFightPrepareMediator:initData_()
    -- self.playerAttackData = self:getCtorArgs().playerAttackData
    -- self.oppoentData      = self:getCtorArgs().oppoentData

end

function TagMatchFightPrepareMediator:initView_()
    local viewData = self:getViewData()
    local backBtn  = viewData.backBtn
    display.commonUIParams(backBtn, {cb = handler(self, self.onCloseViewAction)})

    local fightBtn = viewData.fightBtn
    display.commonUIParams(fightBtn, {cb = handler(self, self.onEnterBattleAction)})

    local editTeamBtn = viewData.editTeamBtn
    display.commonUIParams(editTeamBtn, {cb = handler(self, self.onEditTeamAction)})

    self:GetViewComponent():refreshUI(self:getCtorArgs())

    self.isControllable_ = false
    local cb = function ()
        self.isControllable_ = true
    end
    self:GetViewComponent():showUIAction(cb)
end

function TagMatchFightPrepareMediator:CleanupView()
    if self.ownerScene_ and self:getViewData().view:getParent() then
        self.ownerScene_:RemoveDialog(self:GetViewComponent())
        self.ownerScene_ = nil
    end
end


function TagMatchFightPrepareMediator:OnRegist()
    -- regPost(POST.TAG_MATCH_QUEST_AT)
    -- regPost(POST.TAG_MATCH_QUEST_GRADE)
    self:enterLayer()
end
function TagMatchFightPrepareMediator:OnUnRegist()
    -- unregPost(POST.TAG_MATCH_QUEST_AT)
    -- unregPost(POST.TAG_MATCH_QUEST_GRADE)
end


function TagMatchFightPrepareMediator:InterestSignals()
    return {
        UPDATE_TEAM_HEAD
    }
end

function TagMatchFightPrepareMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local body = signal:GetBody() or {}
    
    if name == UPDATE_TEAM_HEAD then
        local playerAttackData = self:getCtorArgs().playerAttackData
        self:GetViewComponent():updatePlayerLineup(playerAttackData)

        self:GetViewComponent():updateMyTeamTypeIcon(checkint(body.attackTeamId) > 0)
    end
    
end 

-------------------------------------------------
-- get / set

function TagMatchFightPrepareMediator:getCtorArgs()
    return self.ctorArgs_
end

function TagMatchFightPrepareMediator:getViewData()
    return self.viewData_
end

function TagMatchFightPrepareMediator:getOwnerScene()
    return self.ownerScene_
end

-------------------------------------------------
-- public method
function TagMatchFightPrepareMediator:enterLayer()
    
end

-------------------------------------------------
-- private method


-------------------------------------------------
-- check

-------------------------------------------------
-- handler
function TagMatchFightPrepareMediator:onCloseViewAction(sender)
    if not self.isControllable_ then return end
    self:GetFacade():UnRegsitMediator(NAME)
end

function TagMatchFightPrepareMediator:onEnterBattleAction(sender)
    if not self.isControllable_ then return end
    local oppoentData = self:getCtorArgs().oppoentData
    self:GetFacade():DispatchObservers(ENTER_TAG_MATCH_BATTLE, {enemyPlayerId = oppoentData.playerId})
end

function TagMatchFightPrepareMediator:onEditTeamAction()
    if not self.isControllable_ then return end
    self:GetFacade():DispatchObservers(SHOW_TAG_MATCH_EDIT_TEAM)
end

return TagMatchFightPrepareMediator
