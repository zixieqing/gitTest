--[[
 * descpt : 新天城演武 战斗预览 中介者
]]
local NAME = 'NewKofArenaFightPrepareMediator'
local NewKofArenaFightPrepareMediator = class(NAME, mvc.Mediator)

local AppFacadeInstance = AppFacade.GetInstance()
local uiMgr    = AppFacadeInstance:GetManager('UIManager')

-- 进入战斗
local ENTER_TAG_MATCH_BATTLE = 'ENTER_TAG_MATCH_BATTLE'
-- 显示编辑团队界面
-- local SHOW_TAG_MATCH_EDIT_TEAM = 'SHOW_TAG_MATCH_EDIT_TEAM'

local UPDATE_TEAM_HEAD = 'UPDATE_TEAM_HEAD'

function NewKofArenaFightPrepareMediator:ctor(params, viewComponent)
    
    self.super.ctor(self, NAME, viewComponent)
    self.ctorArgs_ = checktable(params)
end

-------------------------------------------------
-- init method
function NewKofArenaFightPrepareMediator:Initial(key)
    self.super.Initial(self, key)

    self.isControllable_ = true
    self.activeJump = true

    -- create view
    local viewComponent = require('Game.views.tagMatchNew.NewKofArenaFightPrepareView').new()
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

function NewKofArenaFightPrepareMediator:initData_()
    -- self.playerAttackData = self:getCtorArgs().playerAttackData
    -- self.opponentData      = self:getCtorArgs().opponentData

end

function NewKofArenaFightPrepareMediator:initView_()
    local viewData = self:getViewData()
    local backBtn  = viewData.backBtn
    display.commonUIParams(backBtn, {cb = handler(self, self.onCloseViewAction)})

    local fightBtn = viewData.fightBtn
    display.commonUIParams(fightBtn, {cb = handler(self, self.onEnterBattleAction)})

    -- local editTeamBtn = viewData.editTeamBtn

    -- display.commonUIParams(editTeamBtn, {cb = handler(self, self.onEditTeamAction)})

    self:GetViewComponent():refreshUI(self:getCtorArgs())

    self.isControllable_ = false
    local cb = function ()
        self.isControllable_ = true
    end
    self:GetViewComponent():showUIAction(cb)
end

function NewKofArenaFightPrepareMediator:CleanupView()
    if self.ownerScene_ and self:getViewData().view:getParent() then
        self.ownerScene_:RemoveDialog(self:GetViewComponent())
        self.ownerScene_ = nil
    end
end


function NewKofArenaFightPrepareMediator:OnRegist()
    self:enterLayer()
end
function NewKofArenaFightPrepareMediator:OnUnRegist()

end


function NewKofArenaFightPrepareMediator:InterestSignals()
    return {
        UPDATE_TEAM_HEAD
    }
end

function NewKofArenaFightPrepareMediator:ProcessSignal(signal)
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

function NewKofArenaFightPrepareMediator:getCtorArgs()
    return self.ctorArgs_
end

function NewKofArenaFightPrepareMediator:getViewData()
    return self.viewData_
end

function NewKofArenaFightPrepareMediator:getOwnerScene()
    return self.ownerScene_
end

-------------------------------------------------
-- public method
function NewKofArenaFightPrepareMediator:enterLayer()
    
end

-------------------------------------------------
-- private method


-------------------------------------------------
-- check

-------------------------------------------------
-- handler
function NewKofArenaFightPrepareMediator:onCloseViewAction(sender)
    if not self.isControllable_ then return end
    self:GetFacade():UnRegsitMediator(NAME)
end

function NewKofArenaFightPrepareMediator:onEnterBattleAction(sender)
    if not self.isControllable_ then return end
    local opponentData = self:getCtorArgs().opponentData
    self:GetFacade():DispatchObservers(ENTER_TAG_MATCH_BATTLE, {enemyPositionId = opponentData.id})
end

-- function NewKofArenaFightPrepareMediator:onEditTeamAction()
--     if not self.isControllable_ then return end
--     self:GetFacade():DispatchObservers(SHOW_TAG_MATCH_EDIT_TEAM)
-- end

return NewKofArenaFightPrepareMediator
