--[[
 * author : kaishiqi
 * descpt : 游戏通知层
]]
local GameNoticeLayer = class('GameNoticeLayer', function()
    return display.newLayer(0, 0, {name = 'home.GameNoticeLayer', enableEvent = true})
end)

local RES_DICT = {
    NOTICE_BAR  = 'ui/home/main_bg_highlight.png',
}

local CreateNoticeView = nil

local SCROLL_TEXT_GAP = 36


-------------------------------------------------
-- life cycle

function GameNoticeLayer:ctor(params)
    local noticeData     = checktable(params)
    self.isControllable_ = true
    self.gameNoticeList_ = {}

    -- create view
    self:addGameNotice(noticeData)
end


CreateNoticeView = function()
    local view = display.newLayer(0, 0, {color = cc.r4b(0)})

    -- scroll text bg
    local scrollTextBg   = display.newImageView(_res(RES_DICT.NOTICE_BAR), display.cx - 270, display.height - 20)
    local scrollTextSize = scrollTextBg:getContentSize()
    view:addChild(scrollTextBg)

    -- [scroll container]
    local contentSize = cc.size(460, scrollTextSize.height - 8)
    local scrollPoint = cc.p(scrollTextBg:getPositionX(), scrollTextBg:getPositionY())
    local scrollView  = CScrollView:create(contentSize)
    scrollView:setAnchorPoint(scrollTextBg:getAnchorPoint())
    scrollView:setPosition(scrollPoint)
    scrollView:setDragable(false)
    view:addChild(scrollView)

    return {
        view         = view,
        scrollView   = scrollView,
        scrollTextBg = scrollTextBg,
    }
end


-------------------------------------------------
-- public method

function GameNoticeLayer:close()
    self:stopTextScroll_()
    self:runAction(cc.RemoveSelf:create())
end


function GameNoticeLayer:addGameNotice(noticeData)
    local noticeData    = checktable(noticeData)
    local noticeTimes   = math.max(1, checkint(noticeData.times))
    local noticeContent = checkstr(checktable(noticeData.content)[i18n.getLang()])

    if self.noticeViewData_ then
        -- wait to list
        table.insert(self.gameNoticeList_, noticeData)

    else
        -- create view
        self.noticeViewData_  = CreateNoticeView()
        self:addChild(self.noticeViewData_.view)

        -- init view
        local scrollView      = self.noticeViewData_.scrollView
        local scrollWidth     = scrollView:getContainerSize().width
        self.scrollTextWidth_ = scrollWidth
        for i = 1, noticeTimes do
            local contentRLabel   = self:buildContentRLabel_(noticeContent)
            local scrollTextWidth = display.getLabelContentSize(contentRLabel).width
            contentRLabel:setPosition(cc.p(self.scrollTextWidth_, 0))
            scrollView:getContainer():addChild(contentRLabel)
            self.scrollTextWidth_ = self.scrollTextWidth_ + (scrollTextWidth + SCROLL_TEXT_GAP)
        end

        -- show view
        self:showNoticeView()
    end
end


function GameNoticeLayer:showNoticeView()
    if not self.noticeViewData_ then return end

    -- init action
    local scrollView   = self.noticeViewData_.scrollView
    local scrollTextBg = self.noticeViewData_.scrollTextBg
    scrollTextBg:setScaleX(0)

    -- run action
    local actionTime = 0.3
    self.noticeViewData_.view:runAction(cc.Sequence:create(
        cc.TargetedAction:create(scrollTextBg, cc.ScaleTo:create(actionTime, 1)),
        cc.DelayTime:create(0.1),
        cc.CallFunc:create(function()
            self:startTextScroll_()
        end)
    ))
end
function GameNoticeLayer:hideNoticeView()
    if not self.noticeViewData_ then return end

    -- init action
    local scrollView   = self.noticeViewData_.scrollView
    local scrollTextBg = self.noticeViewData_.scrollTextBg
    scrollTextBg:setScaleX(1)

    -- run action
    local actionTime = 0.3
    self.noticeViewData_.view:runAction(cc.Sequence:create(
        cc.TargetedAction:create(scrollTextBg, cc.ScaleTo:create(actionTime, 0, 1)),
        cc.DelayTime:create(0.1),
        cc.RemoveSelf:create(),
        cc.CallFunc:create(function()
            if #self.gameNoticeList_ > 0 then
                self:addGameNotice(table.remove(self.gameNoticeList_, 1))
            else
                self:close()
            end
        end)
    ))
    self.noticeViewData_ = nil
end


-------------------------------------------------
-- private method

function GameNoticeLayer:buildContentRLabel_(noticeContent)
    local labelParser   = require('Game.labelparser')
    local parsedTable   = labelParser.parse(tostring(noticeContent))
    local msgRichLabel  = display.newRichLabel(0, 0, {ap = display.LEFT_BOTTOM})
    local rLabelContent = {}
    for name, data in ipairs(parsedTable) do
        table.insert(rLabelContent, {text = tostring(data.content), fontSize = 22, color = data.color or '#FFFFFF'} )
    end
    if table.nums(rLabelContent) > 0 then
        display.reloadRichLabel(msgRichLabel, {c = rLabelContent})
    end
    return msgRichLabel
end


function GameNoticeLayer:startTextScroll_()
    if self.scrollTextSchedule_ then return end
    self.scrollTextSchedule_ = scheduler.scheduleGlobal(function()
        if not self.noticeViewData_ then return end

        local scrollView = self.noticeViewData_.scrollView
        local scrollPos  = scrollView:getContentOffset()
        scrollPos.x      = scrollPos.x - 2
        scrollView:setContentOffset(scrollPos)

        -- limit check
        if scrollPos.x < -self.scrollTextWidth_ then
            self:stopTextScroll_()
            self:hideNoticeView()
        end
    end, 0.01)
end
function GameNoticeLayer:stopTextScroll_()
    if self.scrollTextSchedule_ then
        scheduler.unscheduleGlobal(self.scrollTextSchedule_)
        self.scrollTextSchedule_ = nil
    end
end


return GameNoticeLayer
