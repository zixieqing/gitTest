---@class CardManualSkinCell
local CardManualSkinCell = class('home.CardManualSkinCell',function ()
    local pageviewcell = CGridViewCell:new()
    pageviewcell:setCascadeOpacityEnabled(true)
    pageviewcell.name = 'home.CardManualSkinCell'
    pageviewcell:enableNodeEvents()
    return pageviewcell
end)

function CardManualSkinCell:ctor( ... )
    local arg = {...}
    local size = arg[1] 
    self:setContentSize(size)
    local eventNode = CLayout:create(size)
    eventNode:setCascadeOpacityEnabled(true)
    eventNode:setPosition(utils.getLocalCenter(self))
    self:addChild(eventNode)
    self.eventNode = eventNode
    -- 裁剪节点
    local sceneClipNode = cc.ClippingNode:create()
    sceneClipNode:setCascadeOpacityEnabled(true)
    sceneClipNode:setContentSize(size)
    sceneClipNode:setAnchorPoint(cc.p(0.5, 0.5))
	sceneClipNode:setPosition(utils.getLocalCenter(eventNode))
	eventNode:addChild(sceneClipNode, 3)
	local stencilLayer = display.newLayer(0, 0, {size = size})	
	stencilLayer:setCascadeOpacityEnabled(true)
	sceneClipNode:setInverted(false)
	sceneClipNode:setAlphaThreshold(0.1)
	sceneClipNode:setStencil(stencilLayer)
	self.stencilLayer = stencilLayer
	local mask = display.newImageView(_res('ui/home/handbook/pokedex_card_bg_skin_head_unlock.png'), size.width/2, size.height/2 - 2)
	stencilLayer:addChild(mask)
	-- 头像
	self.headIcon = display.newImageView(_res(''), size.width/2, size.height/2 - 2)
	self.headIcon:setScale(0.6)
	sceneClipNode:addChild(self.headIcon, 10)
	-- 头像框
	self.frame = display.newButton(size.width/2, size.height/2 - 2, {n = _res('ui/home/handbook/pokedex_card_bg_skin_head.png')})
	eventNode:addChild(self.frame, 7)
	self.lockMask = display.newImageView(_res('ui/home/handbook/pokedex_card_bg_skin_head_unlock.png'), size.width/2, size.height/2 - 2)
	eventNode:addChild(self.lockMask, 10)
	self.lockIcon = display.newImageView(_res('ui/common/common_ico_lock.png'), size.width/2, size.height/2 - 2)
	eventNode:addChild(self.lockIcon, 10)
	self.selectFrame = display.newImageView(_res('ui/home/handbook/pokedex_card_bg_skin_head_select.png'), size.width/2, size.height/2 - 2)
	eventNode:addChild(self.selectFrame)
	-- 名称
	self.nameBg = display.newImageView(_res('ui/home/handbook/pokedex_card_skin_name_bg.png'), size.width/2, 14)
	eventNode:addChild(self.nameBg, 10)
	self.nameLabel = display.newLabel(size.width/2, 14, {text = '', fontSize = 20, color = '#ffffff'})
	eventNode:addChild(self.nameLabel, 10)
end
--[[
判断是否需要滚动
--]]
function CardManualSkinCell:IsNeedScroll(  )
	return display.getLabelContentSize(self.nameLabel).width > 120
end
--[[
开启滚动
--]]
function CardManualSkinCell:StartScrollAction(  )
	local scrollDistance = display.getLabelContentSize(self.nameLabel).width - 100 -- 滚动距离
	local scrollTime = scrollDistance/20 -- 滚动时间
	self.nameLabel:setAnchorPoint(cc.p(0, 0.5))
	-- 置为初始位置
	local function setStartPos()
		self.nameLabel:setPositionX(20)
	end
	self.nameLabel:runAction(
		cc.RepeatForever:create(
			cc.Sequence:create(
				cc.Sequence:create(
					cc.CallFunc:create(setStartPos),
					cc.MoveBy:create(scrollTime, cc.p(-scrollDistance, 0)),
					cc.DelayTime:create(0.5)
				)
			)
		)
	)
end
--[[
停止滚动
--]]
function CardManualSkinCell:StopScrollAction(  )
	self.nameLabel:stopAllActions()
	self.nameLabel:setAnchorPoint(cc.p(0.5, 0.5))
	self.nameLabel:setPositionX(self:getContentSize().width/2)
end
return CardManualSkinCell