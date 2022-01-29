--[[
 * descpt : 创建HOME工会 中介者
]]
local NAME = 'UnionPartyPrepareHomeMediator'
local UnionPartyPrepareHomeMediator = class(NAME, mvc.Mediator)

local uiMgr    = AppFacade.GetInstance():GetManager('UIManager')
local gameMgr  = AppFacade.GetInstance():GetManager("GameManager")
local unionMgr = AppFacade.GetInstance():GetManager("UnionManager")
local timerMgr = AppFacade.GetInstance():GetManager("TimerManager")

local UnionConfigParser  = require('Game.Datas.Parser.UnionConfigParser')
local PARTY_SIZE_CONFS   = CommonUtils.GetConfigAllMess(UnionConfigParser.TYPE.PARTY_SIZE, 'union') or {}

local PREPARE_TAG = {
    CLOSED  = '0',        -- 派对结束
    PREVIEW = '1',        -- 预览
    TASK    = '2',        -- 交菜
    SUCESS  = '3',        -- 筹备成功
    FAIL    = '4',        -- 筹备失败
    UNLOCK  = '5',        -- 未解锁
}

local MEDIATOR_CONF = {
    [PREPARE_TAG.PREVIEW] = {mediaorName = 'UnionPartyPreparePreviewMediator'},
    [PREPARE_TAG.TASK]    = {mediaorName = 'UnionPartyPrepareTaskMediator'},
}

function UnionPartyPrepareHomeMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    self.ctorArgs_ = checktable(params)
    
    self.countdownEndCount = 0
    self.curPrepareState = PREPARE_TAG.CLOSED
    self.prePrepareState = nil 
    -- mediator 储存器
    self.mediatorStore = {}
    -- view 储存器
    self.viewStore  = {}
end

-------------------------------------------------
-- inheritance method
function UnionPartyPrepareHomeMediator:Initial(key)
    self.super.Initial(self, key)

    self.isControllable_ = true
    
    -- create view
    local viewComponent = require('Game.views.union.UnionPartyPrepareHomeView').new()
    self.viewData_      = viewComponent:getViewData()
    self:SetViewComponent(viewComponent)
    -- add layer
    self:initOwnerScene_()
    display.commonUIParams(viewComponent,{po = display.center, ap = display.CENTER})
    self:getOwnerScene():AddGameLayer(viewComponent)

    -- init view
    self:initView_()
    
end

function UnionPartyPrepareHomeMediator:initOwnerScene_()
    self.ownerScene_ = nil
    local UnionActivityMediator = self:GetFacade():RetrieveMediator('UnionActivityMediator')
    -- 如果 UnionActivityMediator 中的viewComponent 不是 继承 GameScence 的话 走uimgr 缓存的curScene
    if UnionActivityMediator then
        local unionActivityViewComponent = UnionActivityMediator:GetViewComponent()
        self.ownerScene_ = UnionActivityMediator:GetViewComponent()
    else
        self.ownerScene_ = uiMgr:GetCurrentScene()
    end
end

function UnionPartyPrepareHomeMediator:initView_()
    local viewData = self:getViewData()

    local backBtn = viewData.backBtn
    display.commonUIParams(backBtn, {cb = handler(self, self.onClickBackBtnHandler_), animate = false})
    
    local ruleBtn = viewData.ruleBtn
    display.commonUIParams(ruleBtn, {cb = handler(self, self.onClickRuleBtnHandler_)})

    display.commonUIParams(viewData.recordBtn, {cb = handler(self, self.onClickRecordBtnHandler_)})
    
end

function UnionPartyPrepareHomeMediator:CleanupView()
    if self.ownerScene_ and self:getViewData().view:getParent() then
        self.ownerScene_:RemoveGameLayer(self:GetViewComponent())
        self.ownerScene_ = nil
    end
end


function UnionPartyPrepareHomeMediator:OnRegist()
    regPost(POST.UNION_PARTY)
    regPost(POST.UNION_PARTY_SUBMIT_FOOD_LOG)
    
    self:enterLayer()
end
function UnionPartyPrepareHomeMediator:OnUnRegist()
    unregPost(POST.UNION_PARTY)
    unregPost(POST.UNION_PARTY_SUBMIT_FOOD_LOG)

    if timerMgr:RetriveTimer(NAME) then
        timerMgr:RemoveTimer(NAME)
    end
end


function UnionPartyPrepareHomeMediator:InterestSignals()
    return {
        POST.UNION_PARTY.sglName,
        POST.UNION_PARTY_SUBMIT_FOOD_LOG.sglName,

        --------------- local --------------- 
        SGL.UNION_PARTY_PREPARE_REFRESH_UI,
        COUNT_DOWN_ACTION,
    }
end

function UnionPartyPrepareHomeMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local body = signal:GetBody()

    if name == POST.UNION_PARTY.sglName then
        
        -- 清理可能显示的 dialog
        self:clearShowDialog()
        local isUpdateAll = self:initPrepareState(body)
        local section = checkint(body.sectionId)
        if section ~= UNION_PARTY_STEPS.UNOPEN  then
            self:startCountDown(body)
        end
        if isUpdateAll then
            self:showViewByPrepareState_(body)
        end

        self:getViewData().recordBtn:setVisible(self.curPrepareState == PREPARE_TAG.TASK)
        
    elseif name == POST.UNION_PARTY_SUBMIT_FOOD_LOG.sglName then
        uiMgr:AddDialog("Game.views.union.UnionPartyPrepareLogView", body.submitLog)

    elseif name == COUNT_DOWN_ACTION then
        local timerName = tostring(body.timerName)
        if NAME == timerName then
            local countdown = checkint(body.countdown)
            if self:isShowTop() then
                self:updateCountDown(countdown)
            end
            if self.countdownEndCount <= 2 and countdown <= 0 then
                self:enterLayer()
            end
        end
    elseif name == SGL.UNION_PARTY_PREPARE_REFRESH_UI then
        uiMgr:GetCurrentScene():RemoveDialogByTag(5556)
        self:enterLayer()
    end

end

function UnionPartyPrepareHomeMediator:initPrepareState(data)
    local section = checkint(data.sectionId)
    
    local partyId = checkint(data.partyId)
    if section == UNION_PARTY_STEPS.FORESEE then
        self.curPrepareState = PREPARE_TAG.PREVIEW
    elseif section == UNION_PARTY_STEPS.PREPARING then
        self.curPrepareState = PREPARE_TAG.TASK
    elseif section >= UNION_PARTY_STEPS.CLEARING and section < UNION_PARTY_STEPS.ENDING then
        if partyId == 0 then
            self.curPrepareState = PREPARE_TAG.FAIL
        else
            self.curPrepareState = PREPARE_TAG.SUCESS
        end
    elseif section == UNION_PARTY_STEPS.UNOPEN then
        self.curPrepareState = PREPARE_TAG.UNLOCK
    else
        self.curPrepareState = PREPARE_TAG.CLOSED
    end

    local isUpdateAll = false
    if self.prePrepareState ~= self.curPrepareState then
        self.prePrepareState = self.curPrepareState
        isUpdateAll = true
    end
    return isUpdateAll
end

function UnionPartyPrepareHomeMediator:startCountDown(data)

    local leftSeconds    = checkint(data.sectionLeftSeconds)
    local isCountDownEnd = leftSeconds == 0
    if isCountDownEnd then
        self.countdownEndCount = self.countdownEndCount + 1
    else
        self.countdownEndCount = 0
    end
    local sectionLeftSeconds = isCountDownEnd and 3 or leftSeconds + 5

    local timerInfo = timerMgr:RetriveTimer(NAME)
    if timerInfo then
        timerMgr:RemoveTimer(NAME)
    end
    if sectionLeftSeconds > 0 then
        timerMgr:AddTimer({name = NAME, countdown = sectionLeftSeconds})
    else
        AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, timerName = NAME})
    end
    
end

-------------------------------------------------
-- get / set

function UnionPartyPrepareHomeMediator:getViewData()
    return self.viewData_
end

function UnionPartyPrepareHomeMediator:getOwnerScene()
    return self.ownerScene_
end

function UnionPartyPrepareHomeMediator:getMediaorNameBySection(prepareState)
    return MEDIATOR_CONF[prepareState].mediaorName
end

-------------------------------------------------
-- public method
function UnionPartyPrepareHomeMediator:enterLayer()
    self:SendSignal(POST.UNION_PARTY.cmdName)
end

-------------------------------------------------
-- private method
function UnionPartyPrepareHomeMediator:showViewByPrepareState_(data)
    
    self:showTopViewByPrepareState()
    if self.curPrepareState == PREPARE_TAG.PREVIEW or self.curPrepareState == PREPARE_TAG.TASK then
        self:createMediaor_(self.curPrepareState, data)
    else
        self:createPrepareStateView_(self.curPrepareState, data)
    end

    for prepareState,view in pairs(self.viewStore) do
        view:setVisible(prepareState == self.curPrepareState)
    end

end

function UnionPartyPrepareHomeMediator:showTopViewByPrepareState()
    
    local viewData = self:getViewData()
    local topImgLayer = viewData.topImgLayer
    if self.curPrepareState == PREPARE_TAG.FAIL or self.curPrepareState == PREPARE_TAG.UNLOCK or self.curPrepareState == PREPARE_TAG.CLOSED then
        topImgLayer:setVisible(false)
    else
        topImgLayer:setVisible(true)
        local leftTimeDescLabel = viewData.leftTimeDescLabel
        local leftTimeLabel = viewData.leftTimeLabel
        if self.curPrepareState == PREPARE_TAG.PREVIEW or self.curPrepareState == PREPARE_TAG.TASK then
            display.commonLabelParams(leftTimeDescLabel, fontWithColor(7, {fontSize = 24, color = '#ffffff'}))
            display.commonLabelParams(leftTimeLabel, fontWithColor(7, {fontSize = 24, color = '#ffb20e'}))
        elseif self.curPrepareState == PREPARE_TAG.SUCESS then
            display.commonLabelParams(leftTimeDescLabel, fontWithColor(7, {fontSize = 24, color = '#ffd4bf'}))
            display.commonLabelParams(leftTimeLabel, fontWithColor(7, {fontSize = 26, color = '#ffffff'}))
        end
    end

end

function UnionPartyPrepareHomeMediator:updateCountDown(time)
    local viewData = self:getViewData()
    local leftTimeDescLabel = viewData.leftTimeDescLabel
    local desc = ''
    if self.curPrepareState == PREPARE_TAG.PREVIEW then
        desc = __('筹备开启倒计时:')
    elseif self.curPrepareState == PREPARE_TAG.TASK then
        desc = __('筹备倒计时:')
    elseif self.curPrepareState == PREPARE_TAG.SUCESS then
        desc = __('派对开启倒计时:')
    end
    -- if leftTimeDescLabel.getTTFConfig then
        leftTimeDescLabel:setString(desc)
    -- else
    --     display.commonLabelParams(leftTimeDescLabel,{text = desc})
    -- end
    local leftTimeLabel = viewData.leftTimeLabel
    leftTimeLabel:setString(CommonUtils.getTimeFormatByType(time))
    
    local leftTimeDescLabelSize = display.getLabelContentSize(leftTimeDescLabel)
    local leftTimeLabelSize     = display.getLabelContentSize(leftTimeLabel)
    local topTitleBgSize        = viewData.topTitleBgSize

    display.commonUIParams(leftTimeDescLabel,{po = cc.p(topTitleBgSize.width / 2 - leftTimeLabelSize.width / 2, leftTimeDescLabel:getPositionY())})
    display.commonUIParams(leftTimeLabel,{po = cc.p(topTitleBgSize.width / 2 + leftTimeDescLabelSize.width / 2, leftTimeLabel:getPositionY())})
end

function UnionPartyPrepareHomeMediator:createMediaor_(prepareState, data)
    local mediaorName = self:getMediaorNameBySection(prepareState)
    -- logInfo.add(4,'2222sdfawefw'..mediaorName)
    if mediaorName == '' or mediaorName == nil then return end
    
    if not self.mediatorStore[mediaorName] then
        local mediator = require("Game.mediator.union." .. mediaorName).new({data = data})
        self:GetFacade():RegistMediator(mediator)
        
        local contentLayer = self:getViewData().contentLayer
        local view = mediator:GetViewComponent()
        contentLayer:addChild(view)
        local contentLayerSize = contentLayer:getContentSize()
        display.commonUIParams(view, {po = cc.p(contentLayerSize.width / 2, contentLayerSize.height / 2)})

        self.mediatorStore[mediaorName] = mediator
        self.viewStore[prepareState] = view
    end

end

function UnionPartyPrepareHomeMediator:createPrepareStateView_(prepareState, data)
    if self.viewStore[prepareState] ~= nil then return end

    local view = nil
    if prepareState == PREPARE_TAG.SUCESS then
        local partySizeData = PARTY_SIZE_CONFS[tostring(data.partyId)] or {}
        view = self:GetViewComponent():CreatePrepareCompleteView(partySizeData)
    elseif prepareState == PREPARE_TAG.FAIL then
        view = self:GetViewComponent():CreatePrepareNotCompleteView()
    elseif prepareState == PREPARE_TAG.UNLOCK or prepareState == PREPARE_TAG.CLOSED then
        view = self:GetViewComponent():CreatePrepareUnopenedView()
    end

    if view ~= nil then
        local contentLayer = self:getViewData().contentLayer
        contentLayer:addChild(view)
        local contentLayerSize = contentLayer:getContentSize()
        display.commonUIParams(view, {po = cc.p(contentLayerSize.width / 2, contentLayerSize.height / 2)})
        self.viewStore[prepareState] = view
    end
end

function UnionPartyPrepareHomeMediator:hideAllView()
    
end

function UnionPartyPrepareHomeMediator:clearShowDialog()
    local scene = uiMgr:GetCurrentScene()
    scene:RemoveDialogByTag(23456)
    scene:RemoveDialogByTag(5555)
    scene:RemoveDialogByTag(5556)
end

-------------------------------------------------
-- check
function UnionPartyPrepareHomeMediator:isShowTop()
    if  self.curPrepareState == PREPARE_TAG.PREVIEW or 
        self.curPrepareState == PREPARE_TAG.TASK or 
        self.curPrepareState == PREPARE_TAG.SUCESS then
        return true
    else
        return false
    end
end


-------------------------------------------------
-- handler
function UnionPartyPrepareHomeMediator:onClickRuleBtnHandler_(sender)
    PlayAudioByClickNormal()
    uiMgr:ShowIntroPopup({moduleId = MODULE_DATA[tostring(RemindTag.UNION_PARTY)]})
end

function UnionPartyPrepareHomeMediator:onClickRecordBtnHandler_(sender)
    PlayAudioByClickNormal()
    self:SendSignal(POST.UNION_PARTY_SUBMIT_FOOD_LOG.cmdName)
end

function UnionPartyPrepareHomeMediator:onClickBackBtnHandler_(sender)
    PlayAudioByClickClose()
    for mediatorName,mediator in pairs(self.mediatorStore) do
        self:GetFacade():UnRegsitMediator(mediatorName)
    end
    self:GetFacade():UnRegsitMediator(NAME)
end


return UnionPartyPrepareHomeMediator
