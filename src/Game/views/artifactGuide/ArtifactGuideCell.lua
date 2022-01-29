local ArtifactGuideCell = class('ArtifactGuideCell', function ()
	local ArtifactGuideCell = CGridViewCell:new()
	ArtifactGuideCell.name = 'Game.views.artifactGuide.ArtifactGuideCell'
	ArtifactGuideCell:enableNodeEvents()
    ArtifactGuideCell:setCascadeOpacityEnabled(true)
	return ArtifactGuideCell
end)
local RES_DICT = {
    BG                  = _res('ui/common/common_bg_list.png'),
    TITLE_BG            = _res('ui/home/task/task_bg_title.png'),
    COMMON_BTN_N        = _res('ui/common/common_btn_orange.png'), 
    COMMON_BTN_W        = _res('ui/common/common_btn_white_default.png'), 
    COMMON_BTN_F        = _res('ui/common/activity_mifan_by_ico.png'),
}
function ArtifactGuideCell:ctor( ... )
	local arg = { ... }
	local size = arg[1]
	self:setContentSize(size)
    -- bg
    self.bg = display.newImageView(RES_DICT.BG, size.width / 2, size.height / 2, {scale9 = true, size = cc.size(665, 138)})
    self:addChild(self.bg, 1)
    -- titleBg
    self.titleBg = display.newImageView(RES_DICT.TITLE_BG, 8, size.height - 28, {ap = display.LEFT_CENTER})
    self:addChild(self.titleBg, 3)
    -- title 
    self.title = display.newLabel(20, size.height - 28, {text = '', fontSize = 22, color = '#964006', ap = display.LEFT_CENTER})
    self:addChild(self.title, 5)
    -- descrLabel
    self.descrLabel = display.newLabel(20, size.height - 50, {text = '', fontSize = 20, color = '#5c5c5c', w = 370, ap = display.LEFT_TOP})
    self:addChild(self.descrLabel, 5)
    -- goodsIcon
    self.goodsIcon = require('common.GoodNode').new({
        id = GOLD_ID,
        showAmount = true,
        callBack = function (sender)
        end
    })
    self.goodsIcon:setPosition(cc.p(size.width - 225, size.height / 2))
    self.goodsIcon:setScale(0.9)
    self:addChild(self.goodsIcon, 5)
    -- drawBtn
    self.drawBtn = display.newButton(size.width - 90, size.height / 2, {n = RES_DICT.COMMON_BTN_N})
    display.commonLabelParams(self.drawBtn, fontWithColor(14, {text = __('领取')}))
    self:addChild(self.drawBtn, 5)
    -- progressLabel
    self.progressLabel = display.newLabel(size.width - 90, 42, {text = '', fontSize = 20, color = '#5c5c5c'})
    self:addChild(self.progressLabel, 5)
end

--[[
改变领取按钮状态
@params state int 状态 （1--可领取  2--不可领取（跳转）  3-- 已领取）
@params progress int 完成进度
@params targetNum int 目标进度
--]]
function ArtifactGuideCell:ChangeDrawBtnState( state, progress, targetNum )
    local drawBtn = self.drawBtn
    local progressLabel = self.progressLabel
    if state == 1 then
        drawBtn:setNormalImage(RES_DICT.COMMON_BTN_N)
        drawBtn:setSelectedImage(RES_DICT.COMMON_BTN_N)
        drawBtn:setEnabled(true)
        drawBtn:setScale(0.9)
        display.commonLabelParams(drawBtn,fontWithColor(14, {text = __('领取')}))
        drawBtn:setPositionY(self:getContentSize().height / 2)

        progressLabel:setVisible(false)
    elseif state == 2 then
        drawBtn:setNormalImage(RES_DICT.COMMON_BTN_W)
        drawBtn:setSelectedImage(RES_DICT.COMMON_BTN_W)
        drawBtn:setEnabled(true)
        drawBtn:setScale(0.9)
        display.commonLabelParams(drawBtn,fontWithColor(14, {text = __('前往')}))
        drawBtn:setPositionY(self:getContentSize().height / 2 + 12)

        progressLabel:setVisible(true)
        progressLabel:setString(string.format('(%d/%d)', math.min(progress, targetNum), targetNum))
    elseif state == 3 then
        drawBtn:setNormalImage(RES_DICT.COMMON_BTN_F)
        drawBtn:setSelectedImage(RES_DICT.COMMON_BTN_F)
        drawBtn:setEnabled(false)
        drawBtn:setScale(0.8)
        display.commonLabelParams(drawBtn, {text = __('已领取'), fontSize = 22, ttf = true, font = TTF_GAME_FONT})
        drawBtn:setPositionY(self:getContentSize().height / 2)

        progressLabel:setVisible(false)
    end
end
return ArtifactGuideCell