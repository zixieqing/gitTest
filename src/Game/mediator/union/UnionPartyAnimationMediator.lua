--[[
 * author : kaishiqi
 * descpt : 工会派对 - 动画中介者
]]
local UnionPartyAnimationMediator = class('UnionPartyAnimationMediator', mvc.Mediator)

local RES_DICT = {
    ALPHA_IMG = 'ui/common/story_tranparent_bg.png',
    DIALOG_BG = 'arts/stage/ui/dialogue_bg_2.png',
}

local CreateView          = nil
local CreateCountdownView = nil


function UnionPartyAnimationMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'UnionPartyAnimationMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance method

function UnionPartyAnimationMediator:Initial(key)
    self.super.Initial(self, key)

    -- parse args
    local spinePath  = self.ctorArgs_.spinePath
    local descrText  = tostring(self.ctorArgs_.descrText)
    self.targetTime_ = checkint(self.ctorArgs_.targetTime)

    -- create view
    self.viewData_   = CreateView()
    local uiManager  = self:GetFacade():GetManager('UIManager')
    self.ownerScene_ = uiManager:GetCurrentScene()
    self.ownerScene_:AddDialog(self.viewData_.view)

    if spinePath then
        -- spine animation
        self.animationSpine_ = sp.SkeletonAnimation:create(spinePath .. '.json', spinePath .. '.atlas', 1)
        self:getViewData().animationLayer:addChild(self.animationSpine_)

    else
        -- countdown animation
        self.countdownViewData_ = CreateCountdownView()
        self:getViewData().animationLayer:addChild(self.countdownViewData_.view)

        display.commonLabelParams(self.countdownViewData_.descrLabel, {text = descrText})
        self:updateCountdownAnimation_()
        self:startCountdownUpdate_()
    end
end


function UnionPartyAnimationMediator:CleanupView()
    self:stopCountdownUpdate_()

    if self.ownerScene_ and self:getViewData().view:getParent() then
        self.ownerScene_:RemoveDialog(self:getViewData().view)
        self.ownerScene_ = nil
    end
end


function UnionPartyAnimationMediator:OnRegist()
end
function UnionPartyAnimationMediator:OnUnRegist()
end


function UnionPartyAnimationMediator:InterestSignals()
    return {
    }
end
function UnionPartyAnimationMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()
end


-------------------------------------------------
-- view defines

CreateView = function()
    local view = display.newLayer()
    local size = view:getContentSize()

    local blackBg = display.newLayer(0, 0, {color = cc.c4b(0,0,0,150), enable = true})
    view:addChild(blackBg)

    local animationLayer = display.newLayer(size.width/2, size.height/2)
    view:addChild(animationLayer)

    return {
        view           = view,
        animationLayer = animationLayer,
    }
end


CreateCountdownView = function()
    local view = display.newLayer(0, 0, {ap = display.CENTER})
    local size = view:getContentSize()

    local dialogFrame = display.newImageView(_res(RES_DICT.DIALOG_BG), size.width/2, size.height/2 + 220)
    view:addChild(dialogFrame)

    local descrLabel = display.newLabel(dialogFrame:getPositionX(), dialogFrame:getPositionY() + 30, fontWithColor(1, {color = '#6c6c6c', hAlign = display.TAC}))
    view:addChild(descrLabel)

    local timeLabel = display.newLabel(dialogFrame:getPositionX(), dialogFrame:getPositionY() - 30, fontWithColor(20))
    view:addChild(timeLabel)

    -- boss spine
    local bossSpine = AssetsUtils.GetCardSpineNode({confId = 300103, cacheName = SpineCacheName.UNION, spineName = '300103'})
    bossSpine:setPosition(display.cx, display.cy - 300)
    bossSpine:setAnimation(0, 'idle2', true)
    view:addChild(bossSpine)

    return {
        view       = view,
        descrLabel = descrLabel,
        timeLabel  = timeLabel,
    }
end


-------------------------------------------------
-- get / set

function UnionPartyAnimationMediator:getViewData()
    return self.viewData_
end


-------------------------------------------------
-- public method

function UnionPartyAnimationMediator:playAnimation(animationName, isLoop)
    if self.animationSpine_ and animationName then
        self.animationSpine_:setToSetupPose()
        self.animationSpine_:setAnimation(0, animationName, isLoop == true)
    end
end
function UnionPartyAnimationMediator:listenSpineCompleteCB(callback)
    if self.animationSpine_ and callback then
        self.animationSpine_:registerSpineEventHandler(callback, sp.EventType.ANIMATION_COMPLETE)
    end
end


-------------------------------------------------
-- private method

function UnionPartyAnimationMediator:startCountdownUpdate_()
    if self.countdownHandler_ then return end
    self.countdownHandler_ = scheduler.scheduleGlobal(function()
        self:updateCountdownAnimation_()
    end, 1)
end
function UnionPartyAnimationMediator:stopCountdownUpdate_()
    if self.countdownHandler_ then
        scheduler.unscheduleGlobal(self.countdownHandler_)
        self.countdownHandler_ = nil
    end
end
function UnionPartyAnimationMediator:updateCountdownAnimation_()
    if not self.countdownViewData_ then return end
    
    local countdownTime = self.targetTime_ - getServerTime()
    display.commonLabelParams(self.countdownViewData_.timeLabel, {text = tostring(countdownTime)})
end


return UnionPartyAnimationMediator
