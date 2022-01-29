--[[
常驻单笔充值活动列表cell
--]]
local ActivityPermanentSinglePayCell = class('ActivityPermanentSinglePayCell', function ()
	local ActivityPermanentSinglePayCell = CGridViewCell:new()
	ActivityPermanentSinglePayCell.name = 'home.ActivityPermanentSinglePayCell'
	ActivityPermanentSinglePayCell:enableNodeEvents()
	return ActivityPermanentSinglePayCell
end)

function ActivityPermanentSinglePayCell:ctor( params )
	local size = params.size
	self:setContentSize(size)
	local eventNode = CLayout:create(size)
	eventNode:setPosition(utils.getLocalCenter(self))
	self:addChild(eventNode)
	self.eventNode = eventNode

    -- 背景
    local bgImg = _res("ui/home/activity/activity_quanfushua_bg.png")
    local cellMaskImg = _res("ui/home/activity/activity_exchange_bg_goods_notunlock.png")
    self.bg = display.newImageView(bgImg, size.width/2, size.height/2)
    local bgSize = self.bg:getContentSize()
    self.bgSize = bgSize
    eventNode:addChild(self.bg, 1)
    self.bgMask = display.newImageView(cellMaskImg, bgSize.width / 2, bgSize.height / 2)
    self.bgMask:setVisible(false)
    eventNode:addChild(self.bgMask, 10)
    -- 描述
    self.descrLabel = display.newLabel(20, bgSize.height - 16, {text = '', ap = cc.p(0, 0.5), fontSize = 22, color = '#ca2100'})
    eventNode:addChild(self.descrLabel, 5)
    -- 领取次数
    self.drawLabel = display.newLabel(bgSize.width - 20, bgSize.height - 16, fontWithColor(16, {text = __('领取次数'), ap = cc.p(1, 0.5)}))
    eventNode:addChild(self.drawLabel, 5)
    self.timeLabel = display.newLabel(bgSize.width - 20, bgSize.height - 16, fontWithColor(10, {text = '', ap = cc.p(1, 0.5)}))
    eventNode:addChild(self.timeLabel, 5)
    -- 领取
    self.drawBtn = display.newButton(bgSize.width - 30, (bgSize.height - 38) / 2, {n = _res("ui/common/common_btn_orange.png"), ap = display.RIGHT_CENTER})
    display.commonLabelParams(self.drawBtn, fontWithColor(14, {text = __("领取")}))
    eventNode:addChild(self.drawBtn, 5)
    -- 已领取
    self.drawLb = display.newLabel(bgSize.width - 100, (bgSize.height - 38) / 2, {fontSize = 22, color = '#ffffff', text = __('已领取'), ttf = true, font = TTF_GAME_FONT})
    self.drawLb:setVisible(false)
    eventNode:addChild(self.drawLb, 5)
    -- 奖励层
    self.rewardLayerSize = cc.size(500, bgSize.height - 38)
   	self.rewardLayer = display.newLayer(20, 0, {size = rewardLayerSize, ap = display.LEFT_BOTTOM})
    eventNode:addChild(self.rewardLayer, 5)
end
return ActivityPermanentSinglePayCell