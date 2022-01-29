--[[
 * author : kaishiqi
 * descpt : 工会派对 - 对话中介者
]]
local labelParser                = require('Game.labelparser')
local UnionConfigParser          = require('Game.Datas.Parser.UnionConfigParser')
local UnionPartyDialogueMediator = class('UnionPartyDialogueMediator', mvc.Mediator)

UnionPartyDialogueMediator.TYPE = {
    OPENING    = 1, -- 开场对白
    BOSS_QUEST = 2, -- 打BOSS
    CLOSING    = 3, -- 结束对白
}

local RES_DICT = {
    ALPHA_IMG    = 'ui/common/story_tranparent_bg.png',
    DIALOG_FRAME = 'arts/stage/ui/dialogue_bg_2.png',
    DIALOG_HORN  = 'arts/stage/ui/dialogue_horn.png',
}

local CreateView  = nil
local DIALOG_TIME = 3


function UnionPartyDialogueMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'UnionPartyDialogueMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance method

function UnionPartyDialogueMediator:Initial(key)
    self.super.Initial(self, key)

    -- parse args
    local dialogId    = self.ctorArgs_.dialogId
    local storyConfs  = CommonUtils.GetConfigAllMess(UnionConfigParser.TYPE.PARTY_STORY, 'union') or {}
    self.dialogList_  = storyConfs[tostring(dialogId)] or {}
    self.dialogIndex_ = 1

    self.descrText_  = tostring(self.ctorArgs_.descrText)
    self.targetTime_ = checkint(self.ctorArgs_.targetTime)

    -- create view
    self.viewData_   = CreateView()
    local uiManager  = self:GetFacade():GetManager('UIManager')
    self.ownerScene_ = uiManager:GetCurrentScene()
    self.ownerScene_:AddDialog(self.viewData_.view)

    -- update view
    if self:hasNextDialog() then
        self:getViewData().dialogueLayer:setVisible(true)
        self:getViewData().countdownLayer:setVisible(false)
        self:updateDialogueText_()

    elseif self:hasCountdownTime() then
        self:getViewData().dialogueLayer:setVisible(false)
        self:getViewData().countdownLayer:setVisible(true)
        self:updateCountdownText_()
    end
    self:showDialogue_()
end


function UnionPartyDialogueMediator:CleanupView()
    self:stopCountdownUpdate_()
    self:stopAutoDialogue_()

    if self.ownerScene_ and self:getViewData().view:getParent() then
        self.ownerScene_:RemoveDialog(self:getViewData().view)
        self.ownerScene_ = nil
    end
end


function UnionPartyDialogueMediator:OnRegist()
end
function UnionPartyDialogueMediator:OnUnRegist()
end


function UnionPartyDialogueMediator:InterestSignals()
    return {
    }
end
function UnionPartyDialogueMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()
end


-------------------------------------------------
-- view defines

CreateView = function()
    local view = display.newLayer()
    local size = view:getContentSize()

    -- block bg
    view:addChild(display.newLayer(0, 0, {color = cc.r4b(0), enable = true}))

    -- black bg
    local blackBg = display.newLayer(0, 0, {color = cc.c4b(0,0,0,255), coEnable = true})
    blackBg:setOpacity(150)
    view:addChild(blackBg)

    -- roleLayer
    local roleLayer = display.newLayer()
    view:addChild(roleLayer)

    -- dialogue role
    local dialogueRole = CommonUtils.GetRoleNodeById('role_48', 1)
    dialogueRole:setPosition(display.SAFE_R - 280, -80)
    dialogueRole:setScaleX(-1)
    roleLayer:addChild(dialogueRole)

    -- dialogue frame
    local dialogueFrame = display.newImageView(_res(RES_DICT.DIALOG_FRAME), display.cx + 220, display.cy + 60, {ap = display.RIGHT_BOTTOM})
    dialogueFrame:addChild(display.newImageView(_res(RES_DICT.DIALOG_HORN), 460, 5, {scaleX = -1, rotation = -8}))
    view:addChild(dialogueFrame)

    -------------------------------------------------
    -- dialogue layer
    local dialogueLayer = display.newLayer()
    dialogueFrame:addChild(dialogueLayer)

    -- dialogue label
    local dialogueSize  = dialogueFrame:getContentSize()
    local dialogueRLabel = display.newRichLabel(dialogueSize.width/2, dialogueSize.height/2, {sp = 12, w = 44})
    dialogueLayer:addChild(dialogueRLabel)

    -------------------------------------------------
    -- countdown layer
    local countdownLayer = display.newLayer()
    dialogueFrame:addChild(countdownLayer)

    local descrLabel = display.newLabel(dialogueSize.width/2, dialogueSize.height/2 + 30, fontWithColor(1, {color = '#6c6c6c', hAlign = display.TAC}))
    countdownLayer:addChild(descrLabel)

    local timeLabel = display.newLabel(dialogueSize.width/2, dialogueSize.height/2 - 30, fontWithColor(20))
    countdownLayer:addChild(timeLabel)

    return {
        view           = view,
        blackBg        = blackBg,
        roleLayer      = roleLayer,
        dialogueRole   = dialogueRole,
        dialogueFrame  = dialogueFrame,
        dialogueLayer  = dialogueLayer,
        dialogueRLabel = dialogueRLabel,
        countdownLayer = countdownLayer,
        descrLabel     = descrLabel,
        timeLabel      = timeLabel,
    }
end


-------------------------------------------------
-- get / set

function UnionPartyDialogueMediator:getViewData()
    return self.viewData_
end


function UnionPartyDialogueMediator:setFinishCB(callback)
    self.finishCB_ = callback
end


function UnionPartyDialogueMediator:setCountdownCB(callback)
    self.countdownCB_ = callback
end


-------------------------------------------------
-- public  method

function UnionPartyDialogueMediator:close()
    self:GetFacade():UnRegsitMediator(self:GetMediatorName())
end


function UnionPartyDialogueMediator:hasNextDialog()
    return self.dialogIndex_ < #self.dialogList_
end


function UnionPartyDialogueMediator:getCountdownTime()
    return self.targetTime_ - getServerTime()
end
function UnionPartyDialogueMediator:hasCountdownTime()
    return self:getCountdownTime() >= 0
end


-------------------------------------------------
-- private method

function UnionPartyDialogueMediator:showDialogue_()
    local viewData = self:getViewData()
    viewData.roleLayer:setSkewX(10)
    viewData.roleLayer:setPositionX(display.cx)
    viewData.dialogueFrame:setScale(0)
    viewData.dialogueFrame:setOpacity(0)
    viewData.dialogueFrame:setRotation(90)

    viewData.view:runAction(cc.Sequence:create({
        cc.Spawn:create({
            cc.TargetedAction:create(viewData.roleLayer, cc.MoveTo:create(0.2, cc.p(0, 0)))
        }),
        cc.TargetedAction:create(viewData.roleLayer, cc.SkewTo:create(0.1, -3, 0)),
        cc.TargetedAction:create(viewData.roleLayer, cc.SkewTo:create(0.1, 0, 0)),
        cc.Spawn:create({
            cc.TargetedAction:create(viewData.dialogueFrame, cc.FadeIn:create(0.2)),
            cc.TargetedAction:create(viewData.dialogueFrame, cc.ScaleTo:create(0.2, 1)),
            cc.TargetedAction:create(viewData.dialogueFrame, cc.RotateTo:create(0.2, 0))
        }),
        cc.CallFunc:create(function()
            self:launchNextTask_()
        end)
    }))
end
function UnionPartyDialogueMediator:hideDialogue_()
    local viewData = self:getViewData()
    viewData.view:runAction(cc.Sequence:create({
        cc.Spawn:create({
            cc.TargetedAction:create(viewData.roleLayer, cc.MoveTo:create(0.3, cc.p(display.cx, 0))),
            cc.TargetedAction:create(viewData.roleLayer, cc.SkewTo:create(0.1, -10, 0)),
            cc.TargetedAction:create(viewData.dialogueFrame, cc.FadeOut:create(0.1)),
            cc.TargetedAction:create(viewData.dialogueFrame, cc.ScaleTo:create(0.1, 0)),
            cc.TargetedAction:create(viewData.dialogueFrame, cc.RotateTo:create(0.1, -90))
        }),
        cc.DelayTime:create(0.1),
        cc.CallFunc:create(function()
            if self.finishCB_ then
                self.finishCB_()
            end
            self:close()
        end)
    }))
end
function UnionPartyDialogueMediator:launchNextTask_()
    self:stopCountdownUpdate_()
    self:stopAutoDialogue_()

    if self:hasNextDialog() then
        self:getViewData().dialogueLayer:setVisible(true)
        self:getViewData().countdownLayer:setVisible(false)
        self:updateDialogueText_()
        self:startAutoDialogue_()

    elseif self:hasCountdownTime() then
        self:getViewData().dialogueLayer:setVisible(false)
        self:getViewData().countdownLayer:setVisible(true)
        self:updateCountdownText_()
        self:startCountdownUpdate_()

    else
        self:hideDialogue_()
    end
end


function UnionPartyDialogueMediator:startAutoDialogue_()
    if self.autoDialogueHandler_ then return end
    self.autoDialogueHandler_ = scheduler.scheduleGlobal(function()
        self:toNextDialogue_()
    end, DIALOG_TIME)
end
function UnionPartyDialogueMediator:stopAutoDialogue_()
    if self.autoDialogueHandler_ then
        scheduler.unscheduleGlobal(self.autoDialogueHandler_)
        self.autoDialogueHandler_ = nil
    end
end
function UnionPartyDialogueMediator:toNextDialogue_()
    if self:hasNextDialog() then
        local hideDialogueTime = 0.1
        local showDialogueTime = 0.15

        -- add dialog index
        self.dialogIndex_ = self.dialogIndex_ + 1

        -- switch dialogue action
        local viewData = self:getViewData()
        viewData.view:stopAllActions()
        viewData.view:runAction(cc.Sequence:create({
            -- hide dialogue
            cc.Spawn:create({
                cc.TargetedAction:create(viewData.roleLayer, cc.SkewTo:create(hideDialogueTime, 2, 0)),
                cc.TargetedAction:create(viewData.dialogueFrame, cc.FadeOut:create(hideDialogueTime)),
                cc.TargetedAction:create(viewData.dialogueFrame, cc.ScaleTo:create(hideDialogueTime, 0)),
                cc.TargetedAction:create(viewData.dialogueFrame, cc.RotateTo:create(hideDialogueTime, -90))
            }),
            -- update dialogue
            cc.CallFunc:create(function()
                self:updateDialogueText_()
                viewData.dialogueFrame:setScale(0)
                viewData.dialogueFrame:setOpacity(0)
                viewData.dialogueFrame:setRotation(90)
            end),
            -- show dialogue
            cc.Spawn:create({
                cc.TargetedAction:create(viewData.roleLayer, cc.SkewTo:create(0.1, 0, 0)),
                cc.TargetedAction:create(viewData.dialogueFrame, cc.FadeIn:create(showDialogueTime)),
                cc.TargetedAction:create(viewData.dialogueFrame, cc.ScaleTo:create(showDialogueTime, 1)),
                cc.TargetedAction:create(viewData.dialogueFrame, cc.RotateTo:create(showDialogueTime, 0))
            })
        }))
    else
        self:launchNextTask_()
    end
end
function UnionPartyDialogueMediator:updateDialogueText_()
    local dialogList = {}
    local dialogText = tostring(self.dialogList_[self.dialogIndex_])
    local parsedList = labelParser.parse(dialogText)
    for name, data in ipairs(parsedList or {}) do
        local colorStr = data.labelname == 'red' and '#f3600f' or '#6c6c6c'
        table.insert(dialogList, fontWithColor(1, {fontSize = 24, color = colorStr, text = tostring(data.content)}))
    end
    display.reloadRichLabel(self:getViewData().dialogueRLabel, {c = dialogList})
end


function UnionPartyDialogueMediator:startCountdownUpdate_()
    if self.countdownHandler_ then return end
    self.countdownHandler_ = scheduler.scheduleGlobal(function()
        self:updateCountdownText_()
        if self.countdownCB_ then self.countdownCB_(self:getCountdownTime()) end
    end, 1)
end
function UnionPartyDialogueMediator:stopCountdownUpdate_()
    if self.countdownHandler_ then
        scheduler.unscheduleGlobal(self.countdownHandler_)
        self.countdownHandler_ = nil
    end
end
function UnionPartyDialogueMediator:updateCountdownText_()
    display.commonLabelParams(self:getViewData().timeLabel, {text = tostring(self:getCountdownTime())})
    display.commonLabelParams(self:getViewData().descrLabel, {text = tostring(self.descrText_)})
end


return UnionPartyDialogueMediator
