--[[
排行榜皇家试炼排行Cell
--]]
local ActivityHoneyBentoCell = class('ActivityHoneyBentoCell', function ()
	local ActivityHoneyBentoCell = CGridViewCell:new()
	ActivityHoneyBentoCell.name = 'home.ActivityHoneyBentoCell'
	ActivityHoneyBentoCell:enableNodeEvents()
	return ActivityHoneyBentoCell
end)

function ActivityHoneyBentoCell:ctor( ... )
	local arg = { ... }
	local size = arg[1]
	self:setContentSize(size)
	local eventNode = CLayout:create(size)
	eventNode:setPosition(utils.getLocalCenter(self))
	self:addChild(eventNode)
	self.eventNode = eventNode
	self.bg = display.newImageView(_res('ui/home/activity/activity_love_lunch_bg_1.png'), size.width/2, size.height/2-4)
	self.eventNode:addChild(self.bg, 3)
	self.title = display.newLabel(size.width/2, 414, {text = '每日午餐', fontSize = 28, color = '#ffc24c', font = TTF_GAME_FONT, ttf = true, outline = '#5b3c25', outlineSize = 1})
	self.eventNode:addChild(self.title, 10)
	self.timeLabel = display.newLabel(size.width/2, 372, fontWithColor(19, {}))
	self.eventNode:addChild(self.timeLabel, 10)
	self.icon = display.newImageView(_res('ui/home/activity/activity_love_lunch_ico_foods_1.png'), size.width/2, 196, {ap = cc.p(0.5, 0)})
	self.eventNode:addChild(self.icon, 7)
	self.rewardBg = display.newImageView(_res('ui/home/activity/activity_love_lunch_bg_spirit.png'), size.width/2, 174)
	self.eventNode:addChild(self.rewardBg, 10)
	self.rewardNum = display.newLabel(size.width/2 - 2, 174, {ap = cc.p(1, 0.5), text = '50', fontSize = 34, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#5b3c25', outlineSize = 1})
	self.eventNode:addChild(self.rewardNum, 10)
	self.rewardIcon = display.newImageView(_res(CommonUtils.GetGoodsIconPathById(HP_ID)), size.width/2+2, 174, {ap = cc.p(0, 0.5)})
	self.rewardIcon:setScale(0.25)
	self.eventNode:addChild(self.rewardIcon, 10)
	self.drawBtn = display.newButton(size.width/2, 56, {n = _res('ui/common/common_btn_orange.png'), d = _res('ui/common/common_btn_orange_disable.png')})
	self.eventNode:addChild(self.drawBtn, 10)
	self.drawIcon = display.newImageView(_res('ui/home/activity/activity_love_lunch_ico_have.png'), size.width/2, 308)
	self.drawIcon:setRotation(-15)
	self.eventNode:addChild(self.drawIcon, 10)
	self.unlockMask = display.newImageView(_res('ui/home/activity/activity_love_lunch_bg_unlock.png'), size.width/2, size.height/2-4)
	self.eventNode:addChild(self.unlockMask, 15)
	self.frame = sp.SkeletonAnimation:create(
      'effects/activity/xianshiqiandao_effect.json',
      'effects/activity/xianshiqiandao_effect.atlas',
      1)
    self.frame:update(0)
    self.frame:setToSetupPose()
    self.frame:setAnimation(0, 'idle', true)
    self.frame:setPosition(cc.p(size.width/2, size.height/2))
    self.frame:setVisible(false)
    self.eventNode:addChild(self.frame, 10)
	self.status = false
end


function ActivityHoneyBentoCell:updateDrawButtonStatus(isEnable)
	local isEnable   = isEnable == true
	local normalImg  = _res('ui/common/common_btn_orange.png')
	local disableImg = _res('ui/common/common_btn_orange_disable.png')
	local currentImg = isEnable and normalImg or disableImg
	self.drawBtn:setNormalImage(currentImg)
	self.drawBtn:setSelectedImage(currentImg)
	-- self.drawBtn:setEnabled(isEnable)
end

return ActivityHoneyBentoCell
