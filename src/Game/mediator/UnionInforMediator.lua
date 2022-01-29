
---
--- Created by xingweihao.
--- DateTime: 27/09/2017 2:35 PM
--- 交易和探索的修改

local Mediator = mvc.Mediator
---@class UnionInforMediator :Mediator
local UnionInforMediator = class("UnionInforMediator", Mediator)
local NAME = "UnionInforMediator"
---@type UIManager
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
---@type UnionManager
local unionMgr=AppFacade.GetInstance():GetManager("UnionManager")
local BUTTON_CLICK = {
    INFORCLICK = 1004 ,     --工会信息的点击
    APPLY_REQUEST = RemindTag.UNION_INFO ,    --申请骑牛

}
local UnionTableMediator = {
    [tostring(BUTTON_CLICK.APPLY_REQUEST)] = "UnionApplyMediator",
    [tostring(BUTTON_CLICK.INFORCLICK)]    = "UnionInforDetailMediator",
}
function UnionInforMediator:ctor( params, viewComponent )
    self.super:ctor(NAME,viewComponent)
    self.datas = params or {}
    self.collectMediator = {} -- 用于收集和管理mediator
    self.isMemberChange = false
    self.preIndex = nil  -- 上一次点击
end

function UnionInforMediator:InterestSignals()
    local signals = {
        UNION_INSIDE_APPLY_EVENT
    }
    return signals
end
function UnionInforMediator:Initial( key )
    self.super.Initial(self,key)
    ---@type PersonInformationNewView
    self.isFirst = true
    self.viewComponent = require("Game.views.UnionInforView").new()
    local viewData = self.viewComponent.viewData
    self:SetViewComponent(self.viewComponent)
    self.viewComponent:setPosition(display.center)
    viewData.closeView:setOnClickScriptHandler(function ()
        PlayAudioByClickClose()
        self:CloseMediator()
    end)
    local scene   =  uiMgr:GetCurrentScene()
    scene:AddDialog(self.viewComponent)
    for i, v in pairs(viewData.buttonTable) do
        v:setOnClickScriptHandler(handler(self ,self.ButtonAction))
    end
    self:ButtonAction(viewData.buttonTable[tostring(BUTTON_CLICK.INFORCLICK)])

end

-- 关闭mediator
function UnionInforMediator:CloseMediator()
    for k , v in pairs(self.collectMediator) do
        self:GetFacade():UnRegsitMediator(k)
    end
    self:GetFacade():UnRegsitMediator(NAME)
end
-- 点击事件
function  UnionInforMediator:ButtonAction(sender)
    if not self.isFirst then
        PlayAudioByClickNormal()
    end
    self.isFirst = false

    local tag = sender:getTag()
    local name = UnionTableMediator[tostring(tag)]
    if not  name then -- 没有该观察者就直接报错
        return
    end
    if   not  self.collectMediator[name] then
        local mediator = require("Game.mediator." .. name).new(self.datas)
        self:GetFacade():RegistMediator(mediator)
        local viewComponent = mediator:GetViewComponent()
        self.viewComponent.viewData.contentLayout:addChild(viewComponent)
        viewComponent:setPosition(cc.p(1136/2 , 639/2))
        self.collectMediator[name] = mediator
    end
    if self.preIndex then
        if self.preIndex == tag then
            return
        else
            self:DealWithButtonStatus(self.preIndex , false)
            self:DealWithButtonStatus(tag , true)
            local preName =  UnionTableMediator[tostring(self.preIndex)]
            self.collectMediator[preName]:GetViewComponent():setVisible(false)
            self.collectMediator[name]:GetViewComponent():setVisible(true)
            if   tag == BUTTON_CLICK.INFORCLICK  then
                self.collectMediator[name]:EnterLayer()
                self.collectMediator[name]:UpdateLeftView()
             end
            if tag == BUTTON_CLICK.APPLY_REQUEST and unionMgr.applyMessage == 1   then
                unionMgr.applyMessage = 0
                app.badgeMgr:CheckUnionRed()
            end
            self.preIndex = tag
        end
    else
        self:DealWithButtonStatus(tag , true)
        self.preIndex = tag
    end
end
--- 处理btn 的状态
function UnionInforMediator:DealWithButtonStatus(tag , selected)
    local name = UnionTableMediator[tostring(tag)]
    if not  name then -- 没有该观察者就直接报错
        return
    end
    local sender = self.viewComponent.viewData.buttonLayot:getChildByTag(tag)
    if  sender  then
        if selected then
            sender:setChecked(true)
            sender:setEnabled(false)
            display.commonLabelParams(sender:getChildByTag(111),fontWithColor('10'))
        else
            sender:setChecked(false)
            sender:setEnabled(true)
            display.commonLabelParams(sender:getChildByTag(111),fontWithColor('6'))
        end
    end
end

function UnionInforMediator:EnterLayer()
end
function UnionInforMediator:ProcessSignal(signal)
end

function UnionInforMediator:OnRegist()
end

function UnionInforMediator:OnUnRegist()
    for k , v in pairs(UnionTableMediator) do
        self:GetFacade():UnRegsitMediator(v)
    end
    self.viewComponent:runAction(cc.RemoveSelf:create())
end

return UnionInforMediator



