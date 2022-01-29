--[[
 * descpt : 创建HOME工会 中介者
]]
local NAME = 'UnionCreateHomeMediator'
local UnionCreateHomeMediator = class(NAME, mvc.Mediator)

local CreateView = nil
local TAB_TAG = {
    TAB_LOOKUP_LABOUR_UNION = 1001,     -- 查找工会
    TAB_CREATE_LABOUR_UNION = 1002,     -- 创建工会
}

local TAB_CONFIG = {
    [tostring(TAB_TAG.TAB_LOOKUP_LABOUR_UNION)] = {mediaorName = 'UnionLookupMediator', titleName = __('查找工会')},
    [tostring(TAB_TAG.TAB_CREATE_LABOUR_UNION)] = {mediaorName = 'UnionCreateMediator', titleName = __('创建工会')}
}

function UnionCreateHomeMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    self.ctorArgs_ = checktable(params)

    -- 保存 上次选择 tab 标识
    self.preChoiceTag = nil

    -- mediator 储存器
    self.mediatorStore = {}
end

-------------------------------------------------
-- inheritance method

function UnionCreateHomeMediator:Initial(key)
    self.super.Initial(self, key)

    self.isControllable_ = true
    self.isFirst = true

    -- create view
    local viewParams = {tag = VIEW_TAG, mediatorName = NAME}
    local view = require('Game.views.UnionCreateHomeView').new(viewParams)
    self.viewData_   = view:getViewData()
    local uiManager  = self:GetFacade():GetManager('UIManager')
    self:SetViewComponent(view)
    self.ownerScene_ = uiManager:GetCurrentScene()
    self.ownerScene_:AddDialog(self.viewData_.view)

    -- init view
    self:initView()
end

function UnionCreateHomeMediator:initView()
    -- display.commonUIParams(self.viewData_.createBtn, {cb = handler(self, self.onClickCreateButtonHandler_)})
    display.commonUIParams(self.viewData_.blackBg, {cb = handler(self, self.onCloseView), animate = false})

    local defChoiceTag = self.ctorArgs_.tag or TAB_TAG.TAB_LOOKUP_LABOUR_UNION
    local tabButtons = self.viewData_.tabButtons

    self:onClickTabButtonHandler_(tabButtons[tostring(defChoiceTag)])

    for tag,tabButton in pairs(tabButtons) do
        tabButton:setOnClickScriptHandler(handler(self, self.onClickTabButtonHandler_))
    end

end

function UnionCreateHomeMediator:CleanupView()
    if self.ownerScene_ and self:getViewData().view:getParent() then
        self.ownerScene_:RemoveDialog(self:getViewData().view)
        self.ownerScene_ = nil
    end
end


function UnionCreateHomeMediator:OnRegist()
end
function UnionCreateHomeMediator:OnUnRegist()
end


function UnionCreateHomeMediator:InterestSignals()
    return {
        UNION_JOIN_SUCCESS,  -- 申请进入工会成功
    }
end

function UnionCreateHomeMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local body = signal:GetBody()

    if name == UNION_JOIN_SUCCESS then
        self:onCloseView()
        self:getAppRouter():Dispatch({name = 'HomeMediator'}, {name = 'UnionLobbyMediator'})
    end
end

-------------------------------------------------
-- get / set

function UnionCreateHomeMediator:getViewData()
    return self.viewData_
end


function UnionCreateHomeMediator:getAppRouter()
    return AppFacade.GetInstance():RetrieveMediator('Router')
end


-------------------------------------------------
-- public method


-------------------------------------------------
-- private method

function UnionCreateHomeMediator:updateTabSelectState_(sender, isSelect)
    sender:setChecked(isSelect)
    -- sender:setEnabled(not isSelect)
end

-------------------------------------------------
-- handler

function UnionCreateHomeMediator:onClickTabButtonHandler_(sender)
    if not self.isFirst then
        PlayAudioByClickNormal() 
    end
    self.isFirst = false --表示不是第一次了
    local tag = sender:getTag()
    local mediaorName = TAB_CONFIG[tostring(tag)].mediaorName

    if not self.isControllable_ or mediaorName == nil or mediaorName == ''  then return end

    -- 存储器中没有 则创建 此 mediaor
    if not self.mediatorStore[mediaorName] then
        local mediator = require("Game.mediator." .. mediaorName).new()
        self:GetFacade():RegistMediator(mediator)
        self:getViewData().bgLayer:addChild(mediator:GetViewComponent())
        local bgLayerSize = self:getViewData().bgLayer:getContentSize()
        display.commonUIParams(mediator:GetViewComponent(), {po = cc.p(bgLayerSize.width / 2, bgLayerSize.height / 2 - 20)})

        self.mediatorStore[mediaorName] = mediator
    end

    self:updateTabSelectState_(sender, true)

    local titleName = TAB_CONFIG[tostring(tag)].titleName
    local titleBg = self:getViewData().titleBg
    -- print(titleName, 'titleNametitleName222')
    display.commonLabelParams(titleBg, {text = tostring(titleName)})

    if self.preChoiceTag then
        if self.preChoiceTag == tag then return end

        self.mediatorStore[mediaorName]:GetViewComponent():setVisible(true)

        local oldMediaorName = TAB_CONFIG[tostring(self.preChoiceTag)].mediaorName
        self.mediatorStore[oldMediaorName]:GetViewComponent():setVisible(false)
        local oldSender = self:getViewData().tabButtons[tostring(self.preChoiceTag)]
        self:updateTabSelectState_(oldSender, false)
    else
        -- 默认选中
    end



    self.preChoiceTag = tag

end

function UnionCreateHomeMediator:onCloseView(sender)
    PlayAudioByClickClose()
    for mediatorName,mediator in pairs(self.mediatorStore) do
        self:GetFacade():UnRegsitMediator(mediatorName)
    end
    AppFacade.GetInstance():UnRegsitMediator(NAME)
end

return UnionCreateHomeMediator
