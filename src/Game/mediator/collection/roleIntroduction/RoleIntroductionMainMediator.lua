--[[
 * author : panmeng
 * descpt : 人物介绍，点入角色之卷和堕神之卷
]]

local RoleIntroductionMainMediator = class('RoleIntroductionMainMediator', mvc.Mediator)

function RoleIntroductionMainMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'RoleIntroductionMainMediator', viewComponent)
    local initArgs = checktable(params)
    self.ctorArgs_ = initArgs.requestData or {}
    self.homeArgs_ = initArgs
    self.homeArgs_.requestData = nil
end


RoleIntroductionMainMediator.CELL_MODULE_NAME = {
    "NPCManualHomeMediator",
    "BossStoryMediator",
}


-------------------------------------------------
-- life cycle
function RoleIntroductionMainMediator:Initial(key)
    self.super.Initial(self, key)

    -- init vars
    self.isControllable_ = true

    -- create view
    self.ownerScene_ = app.uiMgr:SwitchToTargetScene('Game.views.collection.roleIntroduction.RoleIntroductionMainScene')
    self:SetViewComponent(self.ownerScene_)

    -- add listener
    ui.bindClick(self:getViewData().backBtn, handler(self, self.onClickBackButtonHandler_))
    self:getViewData().moduleTableView:setCellInitHandler(function(cellViewData)
        ui.bindClick(cellViewData.moduleBg, handler(self, self.onClickModuleBtnHandler_))
    end)

    self:getViewData().moduleTableView:resetCellCount(#RoleIntroductionMainMediator.CELL_MODULE_NAME, true)

    -- update views
    self.isControllable_ = false
    self:getViewNode():showUI(function()
        self:initHomeData_(self.homeArgs_)
        self.isControllable_ = true
    end)
end


function RoleIntroductionMainMediator:CleanupView()
end


function RoleIntroductionMainMediator:OnRegist()
    app:DispatchObservers(HomeScene_ChangeCenterContainer, 'rightHide')
    app:DispatchObservers(HomeScene_ChangeCenterContainer, 'allhide')
end


function RoleIntroductionMainMediator:OnUnRegist()
    app:DispatchObservers(HomeScene_ChangeCenterContainer, 'rightShow')
    app:DispatchObservers(HomeScene_ChangeCenterContainer, 'hide')
end


function RoleIntroductionMainMediator:InterestSignals()
    return {
    }
end
function RoleIntroductionMainMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()
end


-------------------------------------------------
-- get / set

function RoleIntroductionMainMediator:getViewNode()
    return self.ownerScene_
end
function RoleIntroductionMainMediator:getViewData()
    return self:getViewNode():getViewData()
end


function RoleIntroductionMainMediator:getJumpMdtName(moduleIndex)
    return RoleIntroductionMainMediator.CELL_MODULE_NAME[moduleIndex]
end


-------------------------------------------------
-- public

function RoleIntroductionMainMediator:close()
    -- back to homeMdt
    AppFacade.GetInstance():BackHomeMediator({showHandbook = true})
end


-------------------------------------------------
-- private

function RoleIntroductionMainMediator:initHomeData_(homeData)
end


-------------------------------------------------
-- handler

function RoleIntroductionMainMediator:onClickBackButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    self:close()
end


function RoleIntroductionMainMediator:onClickModuleBtnHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local moduleIndex = checkint(sender:getTag())
    local jumpMdtName = self:getJumpMdtName(moduleIndex)
    if jumpMdtName then
        app.router:Dispatch({name = "collection.roleIntroduction.RoleIntroductionMainMediator"}, {name = jumpMdtName})
    end
end


return RoleIntroductionMainMediator
