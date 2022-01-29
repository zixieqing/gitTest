--[[
抽卡卡池cell
--]]
local CapsuleCell = class('CapsuleCell', function ()
	local CapsuleCell = CTableViewCell:new()
	CapsuleCell.name = 'home.CapsuleCell'
	CapsuleCell:setCascadeOpacityEnabled(true)
	CapsuleCell:enableNodeEvents()
	return CapsuleCell
end)

function CapsuleCell:ctor( ... )
	local arg = { ... }
	local size = arg[1]
	self:setContentSize(size)
	local eventNode = CLayout:create(size)
	eventNode:setPosition(utils.getLocalCenter(self))
	self:addChild(eventNode)
	self.eventNode = eventNode
	-- 背景按钮
	self.bgBtn = display.newButton(size.width/2, size.height/2, {n = 'empty', size = cc.size(530, 510)})
	eventNode:addChild(self.bgBtn, 1)
	-- 背景动画
	self.bgSpine = sp.SkeletonAnimation:create(
      'effects/capsule/draw_card.json',
      'effects/capsule/draw_card.atlas',
      1)
    self.bgSpine:setPosition(cc.p(size.width/2, size.height/2))
    eventNode:addChild(self.bgSpine, 1)
    self.nameBg = display.newButton(size.width/2, display.cy - 245, {n = _res('ui/home/capsule/draw_card_bg_text_btn.png')})
    self.nameBg:setEnabled(false)
    eventNode:addChild(self.nameBg, 5)
    display.commonLabelParams(self.nameBg, {text = '', fontSize = 24, color = '#ffffff', outline = '#4c2121', outlineSize = 1, font = TTF_GAME_FONT, ttf = true})
    -- 提示按钮
   	self.tipsBtn = display.newButton(150, display.cy - 245, {n = _res('ui/common/common_btn_tips.png')})
   	eventNode:addChild(self.tipsBtn, 10)
   	-- 图标 
   	self.icon = display.newImageView(CommonUtils.GetGoodsIconPathById(CAPSULE_VOUCHER_ID),size.width/2 + 110, display.cy - 245)
   	self.icon:setScale(0.5)
   	eventNode:addChild(self.icon, 10)
   	-- 广告图
   	self.adImage = display.newImageView(_res('empty'), size.width/2, size.height/2)
    self.adImage:setScale(0.6)
   	eventNode:addChild(self.adImage, 10)
end
return CapsuleCell
