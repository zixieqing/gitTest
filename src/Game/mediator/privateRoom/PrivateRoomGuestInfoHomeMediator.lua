--[[
包厢功能 贵宾信息主页面 mediator
--]]
local NAME = 'privateRoom.PrivateRoomGuestInfoHomeMediator'
local PrivateRoomGuestInfoHomeMediator = class(NAME, mvc.Mediator)

local uiMgr             = app.uiMgr
local gameMgr           = app.gameMgr
local privateRoomMgr    = app.privateRoomMgr

local PrivateRoomGuestInfoListMediator = require("Game.mediator.privateRoom.PrivateRoomGuestInfoListMediator")
local PrivateRoomGuestInfoDescMediator = require("Game.mediator.privateRoom.PrivateRoomGuestInfoDescMediator")

local DIALOG_TAG = {
    RANK_REWARD = 1000,
}

local BUTTON_TAG = {
    BACK     = 100, -- 返回
    RULE     = 101, --规则
}

local VIEW_TAG = {
    LIST = 10000,
    DESC = 10001,
}

function PrivateRoomGuestInfoHomeMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    self.ctorArgs_ = checktable(params)
    -- self.homeData = json.decode([[
	-- 	{"data":{"leftServeTimes":1,"baseServeTimes":5,"leftBuyTimes":1,"assistantId":446,"themeId":330001,"refreshLeftTimes":46974,"guestId":null,"guestDialogueId":null,"foods":null,"rewards":[],"gold":0,"popularity":0,"wall":[],"guests":[{"guestId":3,"grade":1,"serveTimes":1,"dialogues":{"3003":{"assistantId":446}},"hasDrawn":0},{"guestId":7,"grade":1,"serveTimes":1,"dialogues":{"7001":{"assistantId":446}},"hasDrawn":0},{"guestId":2,"grade":1,"serveTimes":1,"dialogues":{"2001":{"assistantId":446}},"hasDrawn":0},{"guestId":1,"grade":1,"serveTimes":1,"dialogues":{"1003":{"assistantId":446}},"hasDrawn":0}]},"timestamp":1537325826,"errcode":0,"errmsg":"","rand":"5ba1bb02bd9d61537325826","sign":"b437901ee659fb41d59100d8ba867711"}
	-- ]]).data
    -- app.privateRoomMgr:InitPrivateRoomData(self.homeData)
end

-------------------------------------------------
-- inheritance method
function PrivateRoomGuestInfoHomeMediator:Initial(key)
    self.super.Initial(self, key)

    self.isControllable_ = true
    self.mediatorStore   = {}
    self.curChildViewTag = VIEW_TAG.LIST

    self.childMediaorClassMap_ = {
        [tostring(VIEW_TAG.LIST)]  = PrivateRoomGuestInfoListMediator,
        [tostring(VIEW_TAG.DESC)]  = PrivateRoomGuestInfoDescMediator,
    }

    -- create view
    local viewComponent = require('Game.views.privateRoom.PrivateRoomGuestInfoHomeView').new()
    self.viewData_      = viewComponent:getViewData()
    self:SetViewComponent(viewComponent)
    -- add layer
    self:initOwnerScene_()
    display.commonUIParams(viewComponent,{po = display.center, ap = display.CENTER})
    self:getOwnerScene():AddDialog(viewComponent)

    -- init data
    self:initData_()

    -- init view
    self:initView_()
    
end

function PrivateRoomGuestInfoHomeMediator:initOwnerScene_()
    self.ownerScene_ = uiMgr:GetCurrentScene()
end

function PrivateRoomGuestInfoHomeMediator:initData_()
    privateRoomMgr:InitGuestListDatas()
end

function PrivateRoomGuestInfoHomeMediator:initView_()
    local viewData = self:getViewData()
    local actionBtns = viewData.actionBtns
    for tag, btn in pairs(actionBtns) do
        btn:setTag(checkint(tag))
        display.commonUIParams(btn, {cb = handler(self, self.onBtnAction)})
    end

    self:GetViewComponent():updateBg(privateRoomMgr:GetThemeWallpaperPath(privateRoomMgr:GetThemeId()))

    self:swiChildView_(self.curChildViewTag)
end

function PrivateRoomGuestInfoHomeMediator:CleanupView()
    local viewComponent = self:GetViewComponent()
    if self.ownerScene_ and viewComponent and not tolua.isnull(viewComponent) then
        self.ownerScene_:RemoveDialog(viewComponent)
        self.ownerScene_ = nil
    end
end


function PrivateRoomGuestInfoHomeMediator:OnRegist()
    
end
function PrivateRoomGuestInfoHomeMediator:OnUnRegist()
    
end


function PrivateRoomGuestInfoHomeMediator:InterestSignals()
    return {
        'PRIVATEROOMGUESTINFO_SWI_VIEW'
    }
end

function PrivateRoomGuestInfoHomeMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local body = signal:GetBody() or {}

    if name == 'PRIVATEROOMGUESTINFO_SWI_VIEW' then
        -- 
        local viewTag = body.viewTag
        self:swiChildView_(viewTag, body)
    end
    
end

-------------------------------------------------
-- get / set

function PrivateRoomGuestInfoHomeMediator:getViewData()
    return self.viewData_
end

function PrivateRoomGuestInfoHomeMediator:getOwnerScene()
    return self.ownerScene_
end

function PrivateRoomGuestInfoHomeMediator:getMediatorByTag(tag)
    return self.childMediaorClassMap_[tag]
end

-------------------------------------------------
-- public method
function PrivateRoomGuestInfoHomeMediator:enterLayer()
end

-------------------------------------------------
-- private method

--==============================--
--desc: 切换子view
--@params viewTag int 视图标识
--@params data table  视图数据
--==============================--
function PrivateRoomGuestInfoHomeMediator:swiChildView_(viewTag, data)
    local Mediator = self:getMediatorByTag(tostring(viewTag))
    if Mediator == nil then return end

    if not self.mediatorStore[viewTag] then
        local viewData     = self:getViewData()
        local contentLayer = viewData.contentLayer
        local mediatorIns = Mediator.new()
        self:GetFacade():RegistMediator(mediatorIns)
        local mediatorViewComponent = mediatorIns:GetViewComponent()
        contentLayer:addChild(mediatorViewComponent)
        display.commonUIParams(mediatorViewComponent,{po = display.center, ap = display.CENTER})

        self.mediatorStore[viewTag] = mediatorIns
    end

    if self.curChildViewTag ~= viewTag then
        self.mediatorStore[self.curChildViewTag]:GetViewComponent():setVisible(false)
        self.mediatorStore[viewTag]:GetViewComponent():setVisible(true)
        self.curChildViewTag = viewTag
    end

    self.mediatorStore[viewTag]:refreshUI(data)
end

-------------------------------------------------
-- check

-------------------------------------------------
-- handler
function PrivateRoomGuestInfoHomeMediator:onBtnAction(sender)
    local tag = sender:getTag()
    if tag == BUTTON_TAG.BACK then
        self:handleBackAction()
    elseif tag == BUTTON_TAG.RULE then
        self:handleRuleAction()
    end
end

--==============================--
--desc: 处理返回事件
--@params sender userdata btn
--==============================--
function PrivateRoomGuestInfoHomeMediator:handleBackAction(sender)
    PlayAudioByClickClose()

    if self.curChildViewTag == VIEW_TAG.DESC then
       self:swiChildView_(VIEW_TAG.LIST, true)
    else
        for _, mdtClass in pairs(self.childMediaorClassMap_) do
            self:GetFacade():UnRegsitMediator(mdtClass.NAME)
        end
        AppFacade.GetInstance():UnRegsitMediator(NAME)
    end

    -- self:GetFacade():UnRegsitMediator(NAME)
end

function PrivateRoomGuestInfoHomeMediator:handleRuleAction(sender)
    
end

return PrivateRoomGuestInfoHomeMediator