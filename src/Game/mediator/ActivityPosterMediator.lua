--[[
 * author : kaishiqi
 * descpt : 活动广告页
]]
local WebSprite              = require('root.WebSprite')
local ZoomSliderList         = require('common.ZoomSliderList')
local ActivityPosterMediator = class('ActivityPosterMediator', mvc.Mediator)

local RES_DICT = {
    POSTER_FRAME = 'ui/home/nmain/main_ad_frame.png',
    LOADING_IMG  = 'ui/home/nmain/activity_ad_loading.png',
    BTN_CHECK_D  = 'ui/common/common_btn_check_default.png',
    BTN_CHECK_S  = 'ui/common/common_btn_check_selected.png',
    ALPHA_IMG    = 'ui/common/story_tranparent_bg.png',
    JUMP_BTN     = 'ui/home/activity/activity_ad_icon_enter.png',
}

local CreateView = nil
local CreateCell = nil


function ActivityPosterMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'ActivityPosterMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


CreateView = function()
    local view = display.newLayer()
    local size = view:getContentSize()

    -- black bg
    local blackBg = display.newLayer(0, 0, {color = cc.c4b(0,0,0,150), enable = true})
    view:addChild(blackBg)

    -- poster slider list
    local sliderCellSize = cc.size(920 , 620)
    local posterSlider   = ZoomSliderList.new()
    posterSlider:setBasePoint(cc.p(size.width/2, size.height/2 + 25))
    posterSlider:setDirection(ZoomSliderList.D_HORIZONTAL)
    posterSlider:setAlignType(ZoomSliderList.ALIGN_CENTER)
    posterSlider:setCellSpace(sliderCellSize.width + 140)
    posterSlider:setCellSize(sliderCellSize)
    posterSlider:setScaleMin(0.8)
    posterSlider:setSideCount(1)
    posterSlider:setSwallowTouches(false)
    view:addChild(posterSlider)

    -- tips label
    local tipsLable = display.newLabel(size.width/2, 55, fontWithColor(19, {text = __('滑动查看更多')}))
    view:addChild(tipsLable)

    -- tips lable
    local closeLable = display.newLabel(size.width/2, 55, fontWithColor(19, {text = __('点击空白关闭')}))
    closeLable:runAction(cc.RepeatForever:create(cc.Sequence:create(
        cc.FadeOut:create(0.5),
        cc.FadeIn:create(0.5)
    )))
    view:addChild(closeLable)

    -- today cbox
    local todaySize = cc.size(220, 64)
    local todayCBox = display.newToggleView(display.SAFE_L + 50, 55, {n = _res(RES_DICT.ALPHA_IMG), s = _res(RES_DICT.ALPHA_IMG), size = todaySize, scale9 = true, ap = display.LEFT_CENTER})
    todayCBox:addChild(display.newLabel(60, todaySize.height/2, fontWithColor(19, {fontSize = 24, text = __('今日不再显示'), ap = display.LEFT_CENTER})))
    todayCBox:getNormalImage():addChild(display.newImageView(_res(RES_DICT.BTN_CHECK_D), 30, todaySize.height/2))
    todayCBox:getSelectedImage():addChild(display.newImageView(_res(RES_DICT.BTN_CHECK_S), 30, todaySize.height/2))
    view:addChild(todayCBox)

    return {
        view         = view,
        blackBg      = blackBg,
        tipsLable    = tipsLable,
        closeLable   = closeLable,
        posterSlider = posterSlider,
        todayCBox    = todayCBox,
    }
end


CreateCell = function(size)
    local view = display.newLayer(0, 0, {size = size})

    view:addChild(display.newLayer(0, 0, {size = size, color = cc.r4b(0), enable = true}))
    view:addChild(display.newImageView(_res(RES_DICT.POSTER_FRAME), size.width/2, size.height/2))

    local imageSize = cc.size(900, 550)
    local webSprite = WebSprite.new({url = '', hpath = _res(RES_DICT.LOADING_IMG), tsize = imageSize})
    webSprite:setAnchorPoint(display.CENTER_BOTTOM)
    webSprite:setPosition(cc.p(size.width/2, 12))
    view:addChild(webSprite)

    local nameLable = display.newLabel(20, size.height - 30, fontWithColor(19, {fontSize = 28, color = '#FFF8E7', ap = display.LEFT_CENTER}))
    view:addChild(nameLable)

    local timeLabel = display.newLabel(size.width - 20, nameLable:getPositionY(), fontWithColor(19, {fontSize = 28, color = '#FFF8E7', ap = display.RIGHT_CENTER}))
    view:addChild(timeLabel)
    
    local timeTips = display.newLabel(0, timeLabel:getPositionY(), fontWithColor(19, {fontSize = 22, color = '#FFF8E7', ap = display.RIGHT_CENTER, text = __('活动时间：')}))
    view:addChild(timeTips)

    local jumpBtn = display.newButton(688, size.height - 424, {n = RES_DICT.JUMP_BTN, ap = display.LEFT_TOP})
    display.commonLabelParams(jumpBtn, fontWithColor(14, {text = __('前 往')}))
    view:addChild(jumpBtn)
    
    return {
        view      = view,
        webSprite = webSprite,
        nameLable = nameLable,
        timeLabel = timeLabel,
        timeTips  = timeTips,
        jumpBtn   = jumpBtn,
    }
end


-------------------------------------------------
-- inheritance method

function ActivityPosterMediator:Initial(key)
    self.super.Initial(self, key)
    
    self.closeCallback_  = self.ctorArgs_.closeCB
    self.isControllable_ = true
    self.posterCellDict_ = {}

    -- create view
    self.viewData_   = CreateView()
    self.ownerScene_ = AppFacade.GetInstance():GetManager('UIManager'):GetCurrentScene()
    self.ownerScene_:AddDialog(self.viewData_.view)

    -- init view
    local posterSlider = self:getViewData().posterSlider
    posterSlider:setIndexOverChangeCB(handler(self, self.onPosterIndexOverChangeHandler_))
    posterSlider:setCellChangeCB(handler(self, self.onPosterCellChangeHandler_))
    posterSlider:setCellCount(#self:getPosterData())
    posterSlider:setCenterIndex(1)
    posterSlider:reloadData()
    
    display.commonUIParams(self:getViewData().blackBg, {cb = handler(self, self.onClickBlackBgHandler_), animate = false})
    self:setEnableClose(posterSlider:getCellCount() <= 1)

    -- show view
    self:getViewData().view:setOpacity(0)
    self:getViewData().view:runAction(cc.FadeIn:create(0.8))
end


function ActivityPosterMediator:CleanupView()
    if self:getViewData().view and  (not tolua.isnull(self:getViewData().view)) then
        self:getViewData().view:runAction(cc.RemoveSelf:create())
        self:getViewData().view = nil
        self.ownerScene_ = nil
    end
end


function ActivityPosterMediator:OnRegist()
end
function ActivityPosterMediator:OnUnRegist()
end


function ActivityPosterMediator:InterestSignals()
    return {}
end
function ActivityPosterMediator:ProcessSignal(signal)
end


-------------------------------------------------
-- get / set

function ActivityPosterMediator:getViewData()
    return self.viewData_
end


function ActivityPosterMediator:getPosterData()
    local gameManager = AppFacade.GetInstance():GetManager('GameManager')
    return gameManager:GetUserInfo().activityAd or {}
end


function ActivityPosterMediator:isEnableClose()
    return self.isEnableClose_ == true
end
function ActivityPosterMediator:setEnableClose(isEnable)
    self.isEnableClose_ = isEnable == true
    local viewData = self:getViewData()
    viewData.closeLable:setVisible(self.isEnableClose_)
    viewData.tipsLable:setVisible(not self.isEnableClose_)
end


-------------------------------------------------
-- public method

function ActivityPosterMediator:close()
    local todayCBox     = self:getViewData().todayCBox
    local isIgnoreToday = todayCBox:isChecked() == true
    local gameManager   = AppFacade.GetInstance():GetManager('GameManager')
    if isIgnoreToday then
        cc.UserDefault:getInstance():setStringForKey(gameManager:getPosterTodayKey(), gameManager:getPosterTodayValue())
        cc.UserDefault:getInstance():flush()
    end
    
    if self.closeCallback_ then
        self.closeCallback_()
    end
    self:GetFacade():UnRegsitMediator(self:GetMediatorName())
end


-------------------------------------------------
-- handler

function ActivityPosterMediator:onClickBlackBgHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    if self:isEnableClose() then
        self:close()
    else
        local posterSlider = self:getViewData().posterSlider
        local maxCellCount = posterSlider:getCellCount()
        local centerIndex  = posterSlider:getCenterIndex()
        if centerIndex < maxCellCount then
            posterSlider:setCenterIndex(posterSlider:getCenterIndex() + 1)
        end
    end
end


function ActivityPosterMediator:onPosterCellChangeHandler_(p_cell, idx)
    local cell  = p_cell
    local index = idx

    -- create cell
    if not cell then
        local posterSlider   = self:getViewData().posterSlider
        local posterCellSize = posterSlider:getCellSize()
        local posterCell     = CreateCell(posterCellSize)

        cell = posterCell.view
        self.posterCellDict_[cell] = posterCell

        display.commonUIParams(posterCell.jumpBtn, {cb = handler(self, self.onClickPosterCellHandler_)})
    end

    -- update cell
    local posterCell  = self.posterCellDict_[cell]
    local posterData  = self:getPosterData()[index] or {}
    local posterName  = checktable(posterData.name)[i18n.getLang()]
    local posterImage = checktable(posterData.image)[i18n.getLang()]
    local startTime   = checkint(posterData.fromTime)
    local endedTime   = checkint(posterData.toTime)
    
    if startTime > 0 and endedTime > 0 then
        local startTimeText = os.date('%m/%d', checkint(startTime))
        local endedTimeText = os.date('%m/%d', checkint(endedTime))
        local timeLabelText = string.fmt('_startTime_-_endedTime_', {_startTime_ = startTimeText, _endedTime_ = endedTimeText})
        display.commonLabelParams(posterCell.timeLabel, {text = timeLabelText})
        posterCell.timeTips:setPositionX(posterCell.timeLabel:getPositionX() - display.getLabelContentSize(posterCell.timeLabel).width - 5)
        posterCell.timeTips:setVisible(true)
    else
        display.commonLabelParams(posterCell.timeLabel, {text = ''})
        posterCell.timeTips:setVisible(false)
    end

    display.commonLabelParams(posterCell.nameLable, {text = tostring(posterName)})
    posterCell.webSprite:setWebURL(posterImage)
    
    posterCell.jumpBtn:setTag(index)
    if GAME_MODULE_OPEN.ACT_POSTER_JUMP then
        posterCell.jumpBtn:setVisible(ActivityUtils.CanJump(posterData.type))
    else
        posterCell.jumpBtn:setVisible(false)
    end
    return cell
end


function ActivityPosterMediator:onPosterIndexOverChangeHandler_(sender, idx)
    if not self:isEnableClose() then
        local viewData = self:getViewData()
        local nowIndex = idx
        local maxIndex = viewData.posterSlider:getCellCount()
        if nowIndex >= maxIndex then
            self:setEnableClose(true)
        end
    end
end


function ActivityPosterMediator:onClickPosterCellHandler_(sender)
    local clickIndex = checkint(sender:getTag())
    local posterData = self:getPosterData()[clickIndex] or {}
    ActivityUtils.ActivityJump(posterData, true)
end


return ActivityPosterMediator
