
---
--- Created by xingweihao.
--- DateTime: 27/10/2017 9:53 AM
---
local Mediator = mvc.Mediator
---@class RealNameAuthenicationMediator :Mediator
local RealNameAuthenicationMediator = class("RealNameAuthenicationMediator", Mediator)
local NAME = "RealNameAuthenicationMediator"
---@type UIManager
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")

local BTN_TAG = {
    CANCEL_BTN = 1102,
    AUTHOR_BTN = 1103,
    NAME_TEXT  = 1104,
    ID_TEXT    = 1105,
}
function RealNameAuthenicationMediator:ctor( param, viewComponent )
    self.super:ctor(NAME,viewComponent)
    param  = param or {}
    self.payData = param.payData
    self.canClose = 0
    self.isGuide = GuideUtils.GetDirector():IsInGuiding()

    if self.isGuide then
        local stage = GuideUtils.GetDirector():GetStage()
        if stage and (not tolua.isnull(stage)) then
            stage:RemoveTouchEvent()
        end
    end
    if param.canClose then
        self.canClose = checkint(param.canClose)
    end
end
function RealNameAuthenicationMediator:InterestSignals()
    local signals = {
    }
    return signals
end


function RealNameAuthenicationMediator:Initial( key )
    self.super.Initial(self,key)
    --获取排列材料本的拍了顺序
    -- 将当前层加到最顶层去除引导的影响
    ---@type RealNameAuthenicationView
    local viewComponent = require('Game.views.RealNameAuthenicationView').new({canClose = self.canClose})
    viewComponent:setPosition(display.center)
    self:SetViewComponent(viewComponent)
    uiMgr:Scene():addChild(self.viewComponent , GameSceneTag.BootLoader_GameSceneTag)
    local viewData_ = self.viewComponent.viewData_
    display.commonUIParams(viewData_.cancelBtn, { cb = handler(self, self.ButtonAction)})
    display.commonUIParams(viewData_.authorBtn, { cb = handler(self, self.ButtonAction)})
end

function RealNameAuthenicationMediator:ButtonAction(sender)
    local tag = sender:getTag()
    if tag == BTN_TAG.CANCEL_BTN then
        self:GetFacade():UnRegsitMediator(NAME)
    elseif tag == BTN_TAG.AUTHOR_BTN  then
        local viewData_ = self.viewComponent.viewData_
        local name  =  viewData_.nameText:getText()
        local id = viewData_.idNumText:getText()
        if string.len(name) >  0 and string.len(id) >0   then
            if self.payData then
                self:SendSignal(POST.USER_ACCOUNT_BIND_REAL_AUTH.cmdName, {realName =name , idNo = id ,payData =  json.encode(self.payData) })
            else
                self:SendSignal(POST.USER_ACCOUNT_BIND_REAL_AUTH.cmdName, {realName =name , idNo = id })
            end
        else
            uiMgr:ShowInformationTips(__('填写信息不完整'))
        end
    end
end

function RealNameAuthenicationMediator:OnRegist()
    regPost(POST.USER_ACCOUNT_BIND_REAL_AUTH)
end

function RealNameAuthenicationMediator:OnUnRegist()
    unregPost(POST.USER_ACCOUNT_BIND_REAL_AUTH)
    local viewComponent = self:GetViewComponent()
    if viewComponent and (not tolua.isnull(viewComponent)) then
        viewComponent:runAction(cc.RemoveSelf:create())
    end
    if self.isGuide then
        local stage = GuideUtils.GetDirector():GetStage()
        if stage and (not tolua.isnull(stage)) then
            stage:RecoverTouchEvent()
        end
    end

end

return RealNameAuthenicationMediator



