--[[
 * author : kaishiqi
 * descpt : 信息验证弹窗
]]
local VerifyInfoPopup = class('VerifyInfoPopup', function()
    return display.newLayer(0, 0, {name = 'common.VerifyInfoPopup'})
end)

local RES_DICT = {
    PROGRESS_BAR = 'ui/home/infor/settings_ico_loading.png',
    PROGRESS_BG  = 'ui/home/infor/settings_bg_2.png',
    INFO_BAR     = 'ui/common/common_bg_close.png',
    ORANGE_BTN   = 'ui/common/common_btn_orange.png',
}

local CreateView = nil


-------------------------------------------------
-- life cycle

function VerifyInfoPopup:ctor(args)
    local args = checktable(args)
    self.isControllable_ = true

    -- create view
    self.viewData_ = CreateView()
    self:addChild(self.viewData_.view)

    -- init status
    display.commonUIParams(self.viewData_.closeBtn, {cb = handler(self, self.onClickCloseButtonHandler_)})
    self:setIsVerifying(true)

    -- black bg
    local blackFg = display.newLayer(0, 0, {color = cc.r4b(0), enable = true})
    self:addChild(blackFg)

    self.viewData_.view:setVisible(false)
    self:runAction(cc.Sequence:create(
        cc.DelayTime:create(1),
        cc.CallFunc:create(function()
            blackFg:setVisible(false)
            self.viewData_.view:setVisible(true)
        end)
    ))
end


CreateView = function()
    local view = display.newLayer()
    local size = view:getContentSize()

    -- black bg
    local blackBg = display.newLayer(0, 0, {color = cc.c4b(0,0,0,150), enable = true})
    blackBg:setCascadeOpacityEnabled(true)
    view:addChild(blackBg)

    local progressBarSize  = display.newImageView(_res(RES_DICT.PROGRESS_BAR)):getContentSize()
    local progressBarWidth = progressBarSize.width - 2
    
    -- scroll view
    local scrollSize = cc.size(progressBarWidth * 2, progressBarSize.height)
    local scrollView = CScrollView:create(scrollSize)
    scrollView:setDirection(eScrollViewDirectionHorizontal)
    scrollView:setAnchorPoint(display.CENTER)
    scrollView:setPosition(display.center)
    scrollView:setDragable(false)
    scrollView:setOpacity(200)
    scrollView:setScaleX(-1)
    view:addChild(display.newImageView(_res(RES_DICT.PROGRESS_BG), display.cx, display.cy, {size = scrollSize, scale9 = true}))
    view:addChild(scrollView)

    -- scroll images
    for i = 1, 4 do
        local progressBarImg = display.newImageView(_res(RES_DICT.PROGRESS_BAR), 0, 0, {ap = display.CENTER_BOTTOM})
        progressBarImg:setPositionX(progressBarWidth * (i-0.5))
        progressBarImg:setScaleX(i % 2 == 0 and -1 or 1)
        scrollView:getContainer():addChild(progressBarImg)
    end

    -- info bar
    local infoBar = display.newButton(display.cx, display.cy - 50, {n = _res(RES_DICT.INFO_BAR), scale9 = true, size = cc.size(200, 42), enable = false})
    display.commonLabelParams(infoBar, fontWithColor(3))
    view:addChild(infoBar)

    -- close button
    local closeBtn = display.newButton(display.cx, display.cy - 150, {n = _res(RES_DICT.ORANGE_BTN)})
    display.commonLabelParams(closeBtn, fontWithColor(14, {text = __('关闭')}))
    view:addChild(closeBtn)

    return {
        view       = view,
        blackBg    = blackBg,
        scrollView = scrollView,
        infoBar    = infoBar,
        closeBtn   = closeBtn,
    }
end


-------------------------------------------------
-- get / set

function VerifyInfoPopup:getViewData()
    return self.viewData_
end


function VerifyInfoPopup:getInfoText()
    return self.infoText_
end
function VerifyInfoPopup:setInfoText(text)
    self.infoText_ = tostring(text)
    local viewData = self:getViewData()
    display.commonLabelParams(viewData.infoBar, {text = self.infoText_, paddingW = 50, safeW = 200})
end


function VerifyInfoPopup:getIsVerifying()
    return self.isVerifying_ == true
end
function VerifyInfoPopup:setIsVerifying(isVerifying)
    self.isVerifying_ = isVerifying == true
    if self.isVerifying_ then
        self:verifyingStatus_()
    else
        self:verifyFailStatus_()
    end
end


-------------------------------------------------
-- public method

function VerifyInfoPopup:close()
    self:stopAllActions()
    self:runAction(cc.RemoveSelf:create())
end


-------------------------------------------------
-- private method

function VerifyInfoPopup:verifyingStatus_()
    local viewData = self:getViewData()
    viewData.closeBtn:setVisible(false)

    viewData.scrollView:stopAllActions()
    viewData.scrollView:runAction(cc.RepeatForever:create(cc.Sequence:create(
        cc.DelayTime:create(0.01),
        cc.CallFunc:create(function()
            local scrollPos  = viewData.scrollView:getContentOffset()
            local scrollSize = viewData.scrollView:getContentSize()
            scrollPos.x = scrollPos.x - 16
            if scrollPos.x <= -scrollSize.width then
                scrollPos.x = scrollPos.x + scrollSize.width
            end
            viewData.scrollView:setContentOffset(scrollPos)
        end)
    )))
end


function VerifyInfoPopup:verifyFailStatus_()
    local viewData = self:getViewData()
    viewData.closeBtn:setVisible(true)
    viewData.scrollView:stopAllActions()
end


-------------------------------------------------
-- handler

function VerifyInfoPopup:onClickCloseButtonHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end
    
    self:close()
end


return VerifyInfoPopup
