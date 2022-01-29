--[[
兑换列表cell
--]]
local ActivityExchangeLargeCell = class('ActivityExchangeLargeCell', function ()
	local ActivityExchangeLargeCell = CGridViewCell:new()
	ActivityExchangeLargeCell.name = 'home.ActivityExchangeLargeCell'
	ActivityExchangeLargeCell:enableNodeEvents()
	return ActivityExchangeLargeCell
end)

function ActivityExchangeLargeCell:ctor( params )
	local size = params.size
	local isLarge = params.isLarge
	self:setContentSize(size)
	local eventNode = CLayout:create(size)
	eventNode:setPosition(utils.getLocalCenter(self))
	self:addChild(eventNode)
	self.eventNode = eventNode

    -- 背景
    local bgImg = nil
    local timeBgImg = nil
    local cellMaskImg = nil 
    if isLarge then
    	bgImg = _res("ui/home/activity/activity_exchange_bg_goods_xl.png")
    	timeBgImg = _res("ui/home/activity/activity_exchange_bg_time_xl.png")
    	cellMaskImg = _res("ui/home/activity/activity_exchange_bg_goods_notunlock_xl.png")
    else
    	bgImg = _res("ui/home/activity/activity_exchange_bg_goods.png")
    	timeBgImg = _res("ui/home/activity/activity_exchange_bg_time.png")
    	cellMaskImg = _res("ui/home/activity/activity_exchange_bg_goods_notunlock.png")
    end
    self.bg = display.newImageView(bgImg, size.width/2, size.height/2)
    local bgSize = self.bg:getContentSize()
    eventNode:addChild(self.bg, 1)
    self.bgMask = display.newImageView(cellMaskImg, bgSize.width / 2, bgSize.height / 2)
    self.bgMask:setVisible(false)
    eventNode:addChild(self.bgMask, 10)
    -- 次数
    self.timeBg = display.newImageView(timeBgImg, bgSize.width / 2, bgSize.height, {ap = display.CENTER_TOP})
    eventNode:addChild(self.timeBg, 3)
    local timeBgSize = self.timeBg:getContentSize()
    self.timeLb = display.newLabel(timeBgSize.width - 10, timeBgSize.height / 2, fontWithColor(18, {text = '', ap = display.RIGHT_CENTER}))
    self.timeBg:addChild(self.timeLb)
    -- 兑换
    self.exchangeBtn = display.newButton(bgSize.width - 30, (bgSize.height - timeBgSize.height) / 2, {n = _res("ui/common/common_btn_orange.png"), ap = display.RIGHT_CENTER})
    display.commonLabelParams(self.exchangeBtn, fontWithColor(14, {text = __("兑换")}))
    eventNode:addChild(self.exchangeBtn, 5)
    -- 已兑换
    self.exchangeLb = display.newLabel(bgSize.width * 0.88, (bgSize.height - timeBgSize.height) / 2, fontWithColor(1, {fontSize = 22, color = '#452b1d', text = __('已兑换')}))
    self.exchangeLb:setVisible(false)
    eventNode:addChild(self.exchangeLb, 5)
    -- 材料层
    local materialLayerSize = cc.size(bgSize.width * 0.35, bgSize.height - timeBgSize.height)
    if isLarge then 
    	materialLayerSize = cc.size(620, bgSize.height - timeBgSize.height)
    end
    self.materialLayer = display.newLayer(0, 0, {size = materialLayerSize, ap = display.LEFT_BOTTOM})
    eventNode:addChild(self.materialLayer, 5)
    -- 奖励层
    local rewardLayerSize = nil
    local rewardLayerPosX = nil
    if isLarge then 
    	rewardLayerSize = cc.size(210, bgSize.height - timeBgSize.height)
    	rewardLayerPosX = 700
    else
    	rewardLayerSize = cc.size(bgSize.width * 0.88 - self.exchangeBtn:getContentSize().width / 2 - bgSize.width * 0.35, bgSize.height - timeBgSize.height)
    	rewardLayerPosX = bgSize.width * 0.35
    end
   	self.rewardLayer = display.newLayer(rewardLayerPosX, 0, {size = rewardLayerSize, ap = display.LEFT_BOTTOM})
    eventNode:addChild(self.rewardLayer, 5)
    -- 箭头
    local iconSize = nil
    for i = 1 ,3 do
        local icon_Up = display.newImageView(_res("ui/home/kitchen/cooking_level_up_ico_arrow.png"), 0, 0)
        if iconSize == nil then
            iconSize = icon_Up:getContentSize()
        end
        local pos = nil
        if isLarge then
        	pos = cc.p(630 + (i - 0.5) * iconSize.width, (bgSize.height - timeBgSize.height) / 2)
        else
        	pos = cc.p(bgSize.width * 0.32 + (i - 0.5) * iconSize.width, (bgSize.height - timeBgSize.height) / 2)
        end
        display.commonUIParams(icon_Up, {po = pos})
        eventNode:addChild(icon_Up, 5)
    end
end
return ActivityExchangeLargeCell