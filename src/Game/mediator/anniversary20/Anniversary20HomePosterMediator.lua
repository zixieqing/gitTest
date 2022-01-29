--[[
 * author : kaishiqi
 * descpt : 周年庆-主页面广告 中介者
]]
local Anniversary20HomePosterMediator = class('Anniversary20HomePosterMediator', mvc.Mediator)

local RES_DICT = {
    BTN_BACK    = 'ui/common/common_btn_back.png',
    BTN_REPLAY  = 'ui/common/common_btn_white_default.png',
    BTN_GOTO_H5 = 'ui/anniversary/poster/btn_anni_h5.png',
    POSTER_BG   = 'ui/anniversary/poster/inform_bg_record_1.jpg',
    MAGIC_LIGHT = 'ui/anniversary/poster/inform_record_shape.png',
    TITLE_TEXT  = 'ui/anniversary/poster/inform_title_record_1.png',
}

local CreateView = nil


function Anniversary20HomePosterMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'Anniversary20HomePosterMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance method

function Anniversary20HomePosterMediator:Initial(key)
    self.super.Initial(self, key)

    self.closeCallback_  = self.ctorArgs_.closeCB
    self.isControllable_ = true
    
    -- create view
    self.viewData_   = CreateView()
    self.ownerScene_ = app.uiMgr:GetCurrentScene()
    self.ownerScene_:AddDialog(self.viewData_.view)

    -- init view
    display.commonUIParams(self.viewData_.backBtn, {cb = handler(self, self.onClickBackButtonHandler_)})
    display.commonUIParams(self.viewData_.replayBtn, {cb = handler(self, self.onClickReplayButtonHandler_)})
    display.commonUIParams(self.viewData_.gotoH5Btn, {cb = handler(self, self.onClickGotoH5ButtonHandler_)})

    -- update view
    self:playAnimation_()
end


function Anniversary20HomePosterMediator:CleanupView()
    if self:getViewData() and not tolua.isnull(self:getViewData().view) then
        self:getViewData().view:runAction(cc.RemoveSelf:create())
        self.ownerScene_ = nil
        self.viewData_   = nil
    end     
end


function Anniversary20HomePosterMediator:OnRegist()
end
function Anniversary20HomePosterMediator:OnUnRegist()
end


function Anniversary20HomePosterMediator:InterestSignals()
    return {
    }
end
function Anniversary20HomePosterMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()
end


-------------------------------------------------
-- view defines

CreateView = function()
    local view = display.newLayer()
    local size = view:getContentSize()

    -- black bg
    local blackBg = display.newLayer(0, 0, {color = cc.c4b(0,0,0,150), enable = true})
    view:addChild(blackBg)

    -- poster bg
    view:addChild(display.newImageView(_res(RES_DICT.POSTER_BG), size.width/2, size.height/2))
    view:addChild(display.newImageView(_res(RES_DICT.TITLE_TEXT), display.SAFE_R - 230, size.height/2 + 70, {ap = display.RIGHT_CENTER}))

    -- magic light
    local magicLight = display.newImageView(_res(RES_DICT.MAGIC_LIGHT), size.width/2 - 275, size.height/2)
    view:addChild(magicLight)
    magicLight:runAction(cc.RepeatForever:create(
        cc.Spawn:create(
            cc.RotateBy:create(4, 40),
            cc.Sequence:create(
                cc.FadeTo:create(2, 55),
                cc.FadeTo:create(2, 255)
            )
        )
    ))

    -- back button
    local backBtn = display.newButton(display.SAFE_L + 75, size.height - 52, {n = _res(RES_DICT.BTN_BACK)})
    view:addChild(backBtn)

    -- replay button
    local replayBtn = display.newButton(display.SAFE_R - 175, size.height - 110, {n = _res(RES_DICT.BTN_REPLAY)})
    display.commonLabelParams(replayBtn, fontWithColor(14, {text = __('回看')}))
    view:addChild(replayBtn)
    
    -- gotoH5 button
    local gotoH5Btn = display.newButton(display.SAFE_R - 325, 90, {n = _res(RES_DICT.BTN_GOTO_H5)})
    display.commonLabelParams(gotoH5Btn, fontWithColor(20, {text = __('周年回顾'), fontSize = 38, outline = '#984814'}))
    view:addChild(gotoH5Btn)

    return {
        view       = view,
        backBtn    = backBtn,
        replayBtn  = replayBtn,
        gotoH5Btn  = gotoH5Btn,
        magicLight = magicLight,
    }
end


-------------------------------------------------
-- get / set

function Anniversary20HomePosterMediator:getViewData()
    return self.viewData_
end


-------------------------------------------------
-- public method

function Anniversary20HomePosterMediator:close()
    app:UnRegsitMediator(self:GetMediatorName())
end


-------------------------------------------------
-- private method

function Anniversary20HomePosterMediator:playAnimation_()
    app.anniv2020Mgr:ShowReviewAnimationDialog()
end


-------------------------------------------------
-- handler

function Anniversary20HomePosterMediator:onClickBackButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    app.anniv2020Mgr:SetOpenedHomePoster(true)
    self:close()
end


function Anniversary20HomePosterMediator:onClickReplayButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    self:playAnimation_()
end


function Anniversary20HomePosterMediator:onClickGotoH5ButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    app.anniv2020Mgr:OpenReviewBrowserUrl()
end


return Anniversary20HomePosterMediator
