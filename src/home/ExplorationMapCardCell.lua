local ExplorationMapCardCell = class('ExplorationMapCardCell', function ()
	local ExplorationMapCardCell = CLayout:create()
	ExplorationMapCardCell.name = 'home.ExplorationMapCardCell'
	ExplorationMapCardCell:enableNodeEvents()
	return ExplorationMapCardCell
end)

function ExplorationMapCardCell:ctor( ... )
	local arg = { ... }
	local size = arg[1]
	self.size = size
	self:setContentSize(size)
	local eventNode = CLayout:create(size)
	self.eventNode = eventNode
	eventNode:setPosition(utils.getLocalCenter(self))
	self:addChild(eventNode)
	-- 背景
	self.cardBtn = display.newButton(size.width/2, size.height/2, {n = _res('ui/home/exploration/maps_small/discovery_main_pic_1.jpg'), useS = false})
	eventNode:addChild(self.cardBtn, 5)
	-- 边框
	self.cardBtnFrame = display.newImageView(_res('ui/home/exploration/discovery_main_bg_pic.png'), size.width/2, size.height/2-3)
	eventNode:addChild(self.cardBtnFrame, 5)
	-- 选中框
	self.selectFrame = display.newImageView(_res('ui/home/exploration/discovery_bg_selected.png'), size.width/2, size.height/2)
	eventNode:addChild(self.selectFrame, 3)
	self.selectFrame:setScale(0.94)
	self.selectFrame:setVisible(false)
	-- 地图名称
	self.cardName = display.newLabel(size.width/2, size.height+5, fontWithColor(19, {text = ''}))
	eventNode:addChild(self.cardName, 10)
	-- 新鲜度
	self.vigourBg = display.newImageView(_res('ui/home/exploration/discovery_bg_common_info.png'), 80, 144)
	eventNode:addChild(self.vigourBg, 7)
	self.vigourIcon = display.newImageView(_res('ui/common/common_ico_leaf.png'), 25, 144)
	self.vigourIcon:setScale(0.5)
	eventNode:addChild(self.vigourIcon, 10)
	self.vigourNum = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '')
	self.vigourNum:setPosition(cc.p(80, 144))
	eventNode:addChild(self.vigourNum, 10)
	-- 时间
	self.timeBg = display.newImageView(_res('ui/home/exploration/discovery_bg_common_info.png'), 248, 144)
	eventNode:addChild(self.timeBg, 7)
	self.timeIcon = display.newButton(175, 144, {n = _res('ui/common/common_ico_time.png')})
	self.timeIcon:setScale(0.5)
	eventNode:addChild(self.timeIcon, 10)

	self.timeNum = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '')
	self.timeNum:setPosition(cc.p(248, 144))
	eventNode:addChild(self.timeNum, 10)
	-- 奖励
	self.prizeBg = display.newImageView(_res('ui/home/exploration/discovery_main_bgprize.png'), size.width/2, 70)
	eventNode:addChild(self.prizeBg, 5)
	self.prizeLabelBg = display.newButton(size.width/2, 107, {n = _res('ui/common/common_title_7.png'), enable = false})
	eventNode:addChild(self.prizeLabelBg, 10)
	display.commonLabelParams(self.prizeLabelBg, fontWithColor(18, {text = __('探索奖励')}))

end
return ExplorationMapCardCell