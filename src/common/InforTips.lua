--[[ 信息通知提示 ]]
local InformationTips = class('InformationTips', function()
    local clb = CLayout:create(cc.size(display.width,display.height))
    clb.name = 'common.InformationTips'
    clb:enableNodeEvents()
    return clb
end)

local RES_DICT = {
    FRAME = 'ui/common/common_bg_tips_s.png'
}

local CreateTipsView = nil

local WAIT_TIME      = 2
local SHOW_TIME      = 0.2
local HIDE_TIME      = 0.2
local TIPS_TIME      = SHOW_TIME + WAIT_TIME + HIDE_TIME
local TIPS_GAP       = 6
local MAX_NUM        = 4


-------------------------------------------------
-- life cycle

function InformationTips:ctor(...)
    self.args = unpack({...})
    -- parse args
    local args        = checktable(self.args)
    local text        = args.text
    local pos         = args.pos
    self.tipsPosDict_ = {}  -- {pos:{ViewData, ...}, ...}

    -- first tips
    self:addTips(text, pos)
end


CreateTipsView = function(text)
    local view = CLayout:create()
    view:setAnchorPoint(cc.p(0.5, 0.5))
    view:setContentSize(cc.size(0, 0))
    view:setPosition(0, 0)

    -- text label
    local FONT_SIZE  = 22
    local MAX_WIDTH  = 700
    local template   = display.newLabel(0, 0, {fontSize = FONT_SIZE, color = '#ffffff', text = text, hAlign = display.TAC})
    local tempSize   = display.getLabelContentSize(template)
    local textWidth  = math.min(MAX_WIDTH, tempSize.width)
    local textHeight = tempSize.height * math.ceil(tempSize.width / MAX_WIDTH)
    -- print("w textHeight ", textWidth, textHeight)
    local textLabel  = display.newLabel(0, 0, {fontSize = FONT_SIZE, color = '#ffffff', text = text, hAlign = display.TAC, w = textWidth, h = textHeight})
    view:addChild(textLabel, 1)

    -- bgImg
    local textLabelSize = display.getLabelContentSize(textLabel)
    local originImgSize = cc.size(326, 35)
    local targetImgSize = cc.size(textLabelSize.width  + 150, textLabelSize.height + 20)
    -- print("w h ", targetImgSize.width, targetImgSize.height)
    local bgImg         = display.newImageView(_res(RES_DICT.FRAME), 0, 0, {scale9 = true, size = targetImgSize, capInsets = cc.rect(86, 8, originImgSize.width - 86*2, originImgSize.height - 8*2)})
    view:addChild(bgImg, 0)

    local viewData = {
        view      = view,
        bgImg     = bgImg,
        textLabel = textLabel
    }
    return viewData
end


-------------------------------------------------
-- public method

function InformationTips:close()
    self:runAction(cc.RemoveSelf:create())
end


-- @param text string
--
function InformationTips:addTips(text, pos)
    text = text or '----'
    pos  = pos or cc.p(0, 0)
    local posKey = self:createPosKey_(pos)
    self.tipsPosDict_[posKey] = self.tipsPosDict_[posKey] or {}
    local tipsViewDataList = self.tipsPosDict_[posKey]

    -- create view
    local tipsViewData = CreateTipsView(text)
    local tipsView     = tipsViewData.view
    tipsView:setPosition(pos)
    self:addChild(tipsView)

    -- show view
    tipsView:setScaleY(0)
    tipsView:runAction(cc.Sequence:create(
        cc.ScaleTo:create(SHOW_TIME, 1),
        cc.DelayTime:create(WAIT_TIME),
        cc.ScaleTo:create(HIDE_TIME, 0, 1),
        cc.CallFunc:create(function()
            -- remove for tipsViewDataList
            for i,v in ipairs(tipsViewDataList) do
                if v.view == tipsView then
                    table.remove(tipsViewDataList, i)
                    break
                end
            end
            -- check close
            self:checkClose_()
        end),
        cc.RemoveSelf:create()
    ))

    -- sort pos
    local tipsViewHalfH = tipsViewData.bgImg:getContentSize().height/2
    local posY = pos.y + tipsViewHalfH + TIPS_GAP
    for i = #tipsViewDataList, 1, -1 do
        local viewData = tipsViewDataList[i]
        local view     = viewData.view
        local viewH    = viewData.bgImg:getContentSize().height
        local moveAct  = cc.MoveTo:create(SHOW_TIME, cc.p(pos.x, posY + viewH/2))
        moveAct:setTag(77)
        view:stopActionByTag(77)
        view:runAction(moveAct)
        posY = posY + viewH + TIPS_GAP
    end

    -- push list
    table.insert(tipsViewDataList, tipsViewData)

    -- limit check
    while #tipsViewDataList > MAX_NUM do
        local view = tipsViewDataList[1].view
        view:stopAllActions()
        self:removeChild(view)
        table.remove(tipsViewDataList, 1)
    end
end


function InformationTips:closeTips(pos)
    local posKey = self:createPosKey_(pos)
    local tipsViewDataList = self.tipsPosDict_[posKey] or {}
    while #tipsViewDataList > 1 do
        local view = tipsViewDataList[1].view
        view:stopAllActions()
        self:removeChild(view)
        table.remove(tipsViewDataList, 1)
    end

    self:checkClose_()
end


-------------------------------------------------
-- private method

function InformationTips:createPosKey_(pos)
    return string.format('%dx%d', math.floor(pos.x), math.floor(pos.y))
end


function InformationTips:checkClose_()
    local isClose = true
    for _, tipsViewDataList in pairs(self.tipsPosDict_) do
        if #tipsViewDataList > 0 then
            isClose = false
            break
        end
    end
    if isClose then
        self:close()
    end
end

function InformationTips:onCleanup()
    isShowInformationTips = false
end


return InformationTips
