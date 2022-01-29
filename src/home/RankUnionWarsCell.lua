--[[
排行榜皇家试炼排行Cell
--]]
local RankUnionWarsCell = class('RankUnionWarsCell', function ()
	local RankUnionWarsCell = CGridViewCell:new()
	RankUnionWarsCell.name = 'home.RankUnionWarsCell'
	RankUnionWarsCell:enableNodeEvents()
	return RankUnionWarsCell
end)

function RankUnionWarsCell:ctor( ... )
	local arg = { ... }
	local size = arg[1]
	self:setContentSize(size)
	local eventNode = CLayout:create(size)
	eventNode:setPosition(utils.getLocalCenter(self))
	self:addChild(eventNode)
	self.eventNode = eventNode
	-- bg
	self.bg = display.newImageView(_res('ui/common/common_bg_list.png'), size.width/2, size.height/2, {scale9 = true, size = cc.size(1006, 104), capInsets = cc.rect(10, 10, 482, 96)})
   	self.eventNode:addChild(self.bg) 
   	self.rankBg = display.newImageView('ui/home/rank/restaurant_info_bg_rank_num1.png', 82, size.height/2)
   	self.eventNode:addChild(self.rankBg, 5)
	self.rankNum = cc.Label:createWithBMFont('font/small/common_text_num.fnt', ' ')
	self.rankNum:setHorizontalAlignment(display.TAR)
	self.rankNum:setScale(1.4)
	self.rankNum:setPosition(79, size.height/2 - 1)
	self.eventNode:addChild(self.rankNum, 10)
	-- 工会头像
	self.headBgImage = display.newImageView(_res('ui/union/guild_head_frame_default'), 180, size.height/2, {scale = 0.65})
	self.eventNode:addChild(self.headBgImage, 10)
	self.headImage = display.newImageView(CommonUtils.GetGoodsIconPathById(101), 180, size.height/2, {scale = 0.65})
	self.eventNode:addChild(self.headImage, 5)
	-- 工会名称
	self.nameLabel = display.newLabel(246, 80, {ap = cc.p(0, 0.5), text = '', fontSize = 24, color = '#7d532a'})
	self.eventNode:addChild(self.nameLabel, 10)
	-- 工会等级
	self.levelLabel = display.newLabel(246, 52, {ap = cc.p(0, 0.5), text = '', fontSize = 22, color = '#a87543'})
	self.eventNode:addChild(self.levelLabel, 10)
	-- 进攻成功次数
	self.attackSuccessLabel = display.newLabel(size.width * 0.5 + 25, size.height/2 + 5, fontWithColor(18, {color = '#5b3c25', ap = display.LEFT_BOTTOM, text = __('进攻成功: ')}))
	self.eventNode:addChild(self.attackSuccessLabel, 10)

	self.attackSuccessTimesLabel = display.newLabel(self.attackSuccessLabel:getPositionX() + display.getLabelContentSize(self.attackSuccessLabel).width, size.height/2 + 5, fontWithColor(18, {color = '#d23d3d', ap = display.LEFT_BOTTOM}))
	self.eventNode:addChild(self.attackSuccessTimesLabel, 10)
	-- 防守成功次数
	self.defendSuccessLabel = display.newLabel(self.attackSuccessLabel:getPositionX(), size.height/2 - 5, fontWithColor(18, {color = '#5b3c25', ap = display.LEFT_TOP, text = __('防守成功: ')}))
	self.eventNode:addChild(self.defendSuccessLabel, 10)

	self.defendSuccessTimesLabel = display.newLabel(self.defendSuccessLabel:getPositionX() + display.getLabelContentSize(self.defendSuccessLabel).width, size.height/2 - 5, fontWithColor(18, {color = '#d23d3d', ap = display.LEFT_TOP}))
	self.eventNode:addChild(self.defendSuccessTimesLabel, 10)

	-- 得分
	self.scoreBg = display.newImageView(_res('ui/home/rank/restaurant_info_bg_rank_awareness.png'), 880, size.height/2, {scale9 = true, size = cc.size(280, 98)})
	self.eventNode:addChild(self.scoreBg, 5)
	self.scoreNum = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '')
	self.scoreNum:setHorizontalAlignment(display.TAR)
	self.scoreNum:setPosition(962, size.height/2)
	self.scoreNum:setAnchorPoint(cc.p(1, 0.5))
	self.eventNode:addChild(self.scoreNum, 10)
	self.scoreIcon = display.newImageView(_res('ui/union/guild_ico_CTBpoint.png'), 986, size.height/2+5)
	self.eventNode:addChild(self.scoreIcon, 10)
	self.scoreIcon:setScale(0.25)
end
return RankUnionWarsCell
