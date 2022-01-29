--[[
游乐园（夏活）排行榜cell
--]]
local CarnieRankCell = class('CarnieRankCell', function ()
	local CarnieRankCell = CGridViewCell:new()
	CarnieRankCell.name = 'Game.views.summerActivity.carnie.CarnieRankCell'
	CarnieRankCell:enableNodeEvents()
	return CarnieRankCell
end)

local summerActMgr = app.summerActMgr
local RES_DICT_ = {
	COMMON_BG_LIST = _res('ui/common/common_bg_list.png'),
	RESTAURANT_INFO_BG_RANK_NUM1 = _res('ui/home/rank/restaurant_info_bg_rank_num1.png'),
	RESTAURANT_INFO_BG_RANK_AWARENESS = _res('ui/home/rank/restaurant_info_bg_rank_awareness.png'),
	ACTIVITY_SUMMER_BTN_SEARCH = _res('ui/home/activity/summerActivity/carnie/activity_summer_btn_search.png'),

	SUMMER_ACTIVITY_ICO_POINT = _res('ui/home/activity/summerActivity/entrance/summer_activity_ico_point.png'),
}
local RES_DICT = {}

function CarnieRankCell:ctor( ... )
	RES_DICT = summerActMgr:resetResPath(RES_DICT_)

	local arg = { ... }
	local size = arg[1]
	self:setContentSize(size)
	local eventNode = CLayout:create(size)
	eventNode:setPosition(utils.getLocalCenter(self))
	self:addChild(eventNode)
	self.eventNode = eventNode
	-- bg
	self.bg = display.newImageView(RES_DICT.COMMON_BG_LIST, size.width/2, size.height/2, {scale9 = true, size = cc.size(size.width - 10, 104), capInsets = cc.rect(10, 10, 482, 96)})
   	self.eventNode:addChild(self.bg) 
   	self.rankBg = display.newImageView(RES_DICT.RESTAURANT_INFO_BG_RANK_NUM1, 52, size.height/2)
   	self.eventNode:addChild(self.rankBg, 5)
	self.rankNum = cc.Label:createWithBMFont('font/small/common_text_num.fnt', ' ')
	self.rankNum:setHorizontalAlignment(display.TAR)
	self.rankNum:setScale(1.4)
	self.rankNum:setPosition(52, size.height/2 - 3)
	self.eventNode:addChild(self.rankNum, 10)
    -- 头像
    self.avatarIcon = require('common.FriendHeadNode').new({
        enable = true, scale = 0.6, showLevel = true
    })
    display.commonUIParams(self.avatarIcon, {po = cc.p(156, size.height/2)})
    self.eventNode:addChild(self.avatarIcon, 10)

	self.nameLabel = display.newLabel(218, size.height/2, {ap = cc.p(0, 0.5), text = '', fontSize = 22, color = '#87543'})
	self.eventNode:addChild(self.nameLabel, 10)
	self.scoreBg = display.newImageView(RES_DICT.RESTAURANT_INFO_BG_RANK_AWARENESS, size.width - 16, size.height/2, {scale9 = true, size = cc.size(280, 98), ap = cc.p(1, 0.5)})
	self.eventNode:addChild(self.scoreBg, 5)
	-- 我的得分
	self.scoreNum = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '')
    self.scoreNum:setHorizontalAlignment(display.TAR)
    self.scoreNum:setAnchorPoint(cc.p(1, 0.5))
	self.scoreNum:setPosition(size.width - 80, size.height/2)
	self.eventNode:addChild(self.scoreNum, 10)
	self.scoreIcon = display.newImageView(RES_DICT.SUMMER_ACTIVITY_ICO_POINT, size.width - 50, size.height/2+5)
	self.eventNode:addChild(self.scoreIcon, 10)
    self.scoreIcon:setScale(0.25)
    -- 搜索
    self.searchBtn = display.newButton(700, size.height/2 + 10, {n = RES_DICT.ACTIVITY_SUMMER_BTN_SEARCH})
    self.eventNode:addChild(self.searchBtn, 10)
    display.commonLabelParams(self.searchBtn, {fontSize = 22, color = '#a87543', text = summerActMgr:getThemeTextByText(__('查看')), offset = cc.p(0, - 35)})

end
return CarnieRankCell