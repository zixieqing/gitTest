--[[
    任务主Mediator
]]
local Mediator = mvc.Mediator
local TaskHomeMediator = class("TaskHomeMediator", Mediator)

local NAME = "task.TaskHomeMediator"

local uiMgr   = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local dataMgr = AppFacade.GetInstance():GetManager("DataManager")

local DailyTaskNewMediator    = require('Game.mediator.task.DailyTaskNewMediator')
local AchievementTaskMediator = require('Game.mediator.task.AchievementTaskMediator')
local UnionDailyTaskMediator  = require('Game.mediator.task.UnionDailyTaskMediator')

local TAB_TAG = {
    DAILY           = 1001,     -- 日常任务
    ACHIEVEMENT     = 1002,     -- 成长任务
    UNION           = 1003,     -- 工会日常任务
}

function TaskHomeMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    self.ctorArgs_ = checktable(params)
    -- 保存 上次选择 tab 标识
    self.preChoiceTag = nil

    self.isExecuteDefSingle = self.ctorArgs_.isExecuteDefSingle

    self.isGameLayer = self.ctorArgs_.isGameLayer

    -- tab conf
    self.tabConfs = nil

    -- mediator 储存器
    self.mediatorStore = {}

    self.subMediaorClassMap_ = {
        [TAB_TAG.DAILY]       = DailyTaskNewMediator,
        [TAB_TAG.UNION]       = UnionDailyTaskMediator,
        [TAB_TAG.ACHIEVEMENT] = AchievementTaskMediator,
    }
end

-------------------------------------------------
-- inheritance method

function TaskHomeMediator:Initial(key)
    self.super.Initial(self, key)

    self.isControllable_ = true

    -- init tab conf
    self:initTabConf()

    -- create view
    local viewParams = {tabConfs = self.tabConfs, mediatorName = NAME}
    local view = require('Game.views.task.TaskHomeView').new(viewParams)
    display.commonUIParams(view, {ap = display.CENTER, po = display.center})
    self:SetViewComponent(view)
    self.viewData_   = view:getViewData()
    self.ownerScene_ = uiMgr:GetCurrentScene()

    if self.isGameLayer == 1 then
        self.ownerScene_:AddGameLayer(view)
    else
        self.ownerScene_:AddDialog(view)
    end
    
    -- init view
    self:initView()
end

function TaskHomeMediator:initTabConf()
    self.tabConfs = {}

    if CommonUtils.GetModuleAvailable(MODULE_SWITCH.DAILYTASK) then
        self.tabConfs[tostring(TAB_TAG.DAILY)] = {tag = TAB_TAG.DAILY, titleName = __('日常任务')}
    end

    if CommonUtils.GetModuleAvailable(MODULE_SWITCH.ACHIEVEMENT) then
        self.tabConfs[tostring(TAB_TAG.ACHIEVEMENT)] = {tag = TAB_TAG.ACHIEVEMENT, titleName = __('成长任务')}
    end
    
    if gameMgr:hasUnion() and CommonUtils.GetModuleAvailable(MODULE_SWITCH.UNION_TASK) then
        self.tabConfs[tostring(TAB_TAG.UNION)] = {tag = TAB_TAG.UNION, titleName = __('工会任务'), ruleTag = RemindTag.UNION_TASK}
    end
end

function TaskHomeMediator:initView()
    display.commonUIParams(self:getViewData().blackBg, {cb = handler(self, self.onCloseView), animate = false})
    local defChoiceTag = self.ctorArgs_.clickTag or TAB_TAG.DAILY
    local tabButtons = self.viewData_.tabButtons
    
    self:onClickTabButtonHandler_(tabButtons[tostring(defChoiceTag)])

    for tag,tabButton in pairs(tabButtons) do
        display.commonUIParams(tabButton, {cb = handler(self, self.onClickTabButtonHandler_)})
    end

    local ruleBtn = self.viewData_.ruleBtn
    display.commonUIParams(ruleBtn, {cb = handler(self, self.onClickRuleBtnAction)})

    for i, tag in pairs(TAB_TAG) do
        self:updateTabRedPointState(tag)
    end
end

function TaskHomeMediator:updateTabRedPointState(tag)
    local viewData   = self:getViewData()
    local tabButtons = viewData.tabButtons
    local tabButton  = tabButtons[tostring(tag)]
    if tabButton then
        local redPointImg = tabButton:getChildByTag(789)
        if checkint(tag) == TAB_TAG.DAILY then
            local dailyTaskCacheData_ = gameMgr:GetUserInfo().dailyTaskCacheData_
            redPointImg:setVisible(checkint(dailyTaskCacheData_.daily) > 0 or checkint(dailyTaskCacheData_.activePoint) > 0)
        elseif checkint(tag) == TAB_TAG.ACHIEVEMENT then
            redPointImg:setVisible(checkint(gameMgr:GetUserInfo().achievementCacheData_.canReceiveCount) > 0)
        elseif checkint(tag) == TAB_TAG.UNION then
            redPointImg:setVisible(gameMgr:hasUnion() and checkint(gameMgr:GetUserInfo().unionTaskCacheData_.canReceiveCount) > 0)
        end
    end
end

function TaskHomeMediator:CleanupView()
    local viewComponent = self:GetViewComponent()
    if self.ownerScene_ and viewComponent and not tolua.isnull(viewComponent) then

        self.ownerScene_:RemoveDialogByTag(23456)

        if self.isGameLayer == 1 then
            self.ownerScene_:RemoveGameLayer(viewComponent)
        else
            self.ownerScene_:RemoveDialog(viewComponent)
        end
        self.ownerScene_ = nil
    end
end


function TaskHomeMediator:OnRegist()
    if self.isExecuteDefSingle == 1 then
        self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "allhide")
    end
end
function TaskHomeMediator:OnUnRegist()
    if self.isExecuteDefSingle == 1 then
        self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "hide")
    end
	
	app.badgeMgr:CheckTaskHomeRed()
	app.badgeMgr:CheckUnionRed()
	AppFacade.GetInstance():DispatchObservers(SGL.BREAK_TO_HOME_MEDIATOR)
end

function TaskHomeMediator:InterestSignals()
    return {
        'TASK_UPDATE_EXTERNAL_TAB_RED_POINT',
        UNION_KICK_OUT_EVENT,
    }
end

function TaskHomeMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local body = signal:GetBody() or {}

    if name == 'TASK_UPDATE_EXTERNAL_TAB_RED_POINT' then
        local viewTag     = body.viewTag
        self:updateTabRedPointState(viewTag)
    elseif name == UNION_KICK_OUT_EVENT then
        self:updateTabRedPointState(TAB_TAG.UNION)
    end
end

-------------------------------------------------
-- handler
function TaskHomeMediator:onClickTabButtonHandler_(sender)
    PlayAudioByClickNormal()
    local tag = checkint(sender:getTag())
    local Mediator = self:getMediaorByTag(tag)

    if not self.isControllable_ or Mediator == nil then return end

    -- 存储器中没有 则创建 此 mediaor
    if not self.mediatorStore[tag] then
        local mediatorIns = Mediator.new({viewTag = tag})
        self:GetFacade():RegistMediator(mediatorIns)
        self:getViewData().layer:addChild(mediatorIns:GetViewComponent())
        local bgLayerSize = self:getViewData().layer:getContentSize()
        display.commonUIParams(mediatorIns:GetViewComponent(), {po = cc.p(bgLayerSize.width / 2, bgLayerSize.height / 2)})

        self.mediatorStore[tag] = mediatorIns
    end

    -- local tabConf = self.tabConfs[tostring(tag)] or {}
    -- local titleName = tabConf.titleName
    -- local titleLabel = self:getViewData().titleLabel
    -- display.commonLabelParams(titleLabel, {text = tostring(titleName)})

    self:GetViewComponent():updateTab(tag)

    if self.preChoiceTag then
        if self.preChoiceTag == tag then return end
        
        self.mediatorStore[tag]:GetViewComponent():setVisible(true)

        self.mediatorStore[self.preChoiceTag]:GetViewComponent():setVisible(false)
        
        local oldSender = self:getViewData().tabButtons[tostring(self.preChoiceTag)]
        self:GetViewComponent():updateTabSelectState_(oldSender, false)
    else
        -- 默认选中
    end

    self:GetViewComponent():updateTabSelectState_(sender, true)

    self.preChoiceTag = tag

end

function TaskHomeMediator:onClickRuleBtnAction()
    
    local tabConf = self.tabConfs[tostring(self.preChoiceTag)] or {}
    local ruleTag = tabConf.ruleTag
    if ruleTag then
        uiMgr:ShowIntroPopup({moduleId = MODULE_DATA[tostring(ruleTag)]})
    end
end

-------------------------------------------------
-- get / set

function TaskHomeMediator:getViewData()
    return self.viewData_
end

function TaskHomeMediator:getOwnerScene()
    return self.ownerScene_
end

function TaskHomeMediator:getMediaorByTag(tag)
    return self.subMediaorClassMap_[tag]
end

function TaskHomeMediator:onCloseView()
    for _, mdtClass in pairs(self.subMediaorClassMap_) do
        self:GetFacade():UnRegsitMediator(mdtClass.NAME)
    end
    AppFacade.GetInstance():UnRegsitMediator(NAME)
end

return TaskHomeMediator