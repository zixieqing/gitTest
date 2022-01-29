--[[
包厢主题商店cell
--]]
local PrivateRoomThemeCell = class('PrivateRoomThemeCell', function ()
    local PrivateRoomThemeCell = CGridViewCell:new()
	PrivateRoomThemeCell.name = 'home.PrivateRoomThemeCell'
	PrivateRoomThemeCell:enableNodeEvents()
	return PrivateRoomThemeCell
end)
local RES_DICT = {
    THEME_BG = _res('avatar/ui/avatarShop/avator_goods_bg_l.png'),
    THEME_DEFAULT = _res('avatar/privateRoomTheme/vip_theme_pic_330001_s.jpg'),
    THEME_FRAME = _res('avatar/ui/avatarShop/avator_goods_bg_l_selected.png'),
    OWN_BG = _res('avatar/ui/avatarShop/avator_ico_own_label.png'),
    TITLE_BG = _res('avatar/ui/avatarShop/avator_goods_bg_title_name.png'),
    LOCK_BG  = _res('avatar/ui/avatarShop/avator_bg_lock_text.png'),
    DISCOUNT_BG = _res('avatar/ui/avatarShop/shop_tag_sale_member.png'), 
}
function PrivateRoomThemeCell:ctor( ... )
	local arg = { ... }
	local size = arg[1]
	self:setContentSize(size)
	local eventNode = CLayout:create(size)
	eventNode:setPosition(utils.getLocalCenter(self))
	self:addChild(eventNode)
    self.eventNode = eventNode
    self.themeBg = display.newButton(size.width / 2, size.height / 2, {n = RES_DICT.THEME_BG, useS = false})
    self.eventNode:addChild(self.themeBg, 1)
    self.themeImg = display.newImageView(RES_DICT.THEME_DEFAULT, size.width / 2, size.height / 2 + 4)
    self.eventNode:addChild(self.themeImg, 1)
    self.themeFrame = display.newImageView(RES_DICT.THEME_FRAME,size.width / 2, size.height / 2, {scale9 = true, size = cc.size(size.width - 15, size.height - 15)})
    self.eventNode:addChild(self.themeFrame, 10)
    self.ownBg = display.newImageView(RES_DICT.OWN_BG, size.width - 12, 16, {ap = cc.p(1, 0)})
    self.eventNode:addChild(self.ownBg, 5)
    self.titleBg = display.newImageView(RES_DICT.TITLE_BG, 16, 20, {ap = cc.p(0, 0)})
    self.eventNode:addChild(self.titleBg, 5)
    self.titleLabel = display.newLabel(10, self.titleBg:getContentSize().height / 2, fontWithColor(18, {text = '力量之拳',ap = cc.p(0, 0.5)}))
    self.titleBg:addChild(self.titleLabel, 5)
    self.lockBg = display.newImageView(RES_DICT.LOCK_BG, size.width / 2, size.height / 2)
    self.eventNode:addChild(self.lockBg, 10)
    self.lockTitle = display.newLabel(size.width / 2, size.height / 2, fontWithColor(4, {text = ''}))
    self.eventNode:addChild(self.lockTitle, 10)
    self.discountBg = display.newImageView(RES_DICT.DISCOUNT_BG, 15, size.height - 35, {ap = cc.p(0, 0.5)})
    self.eventNode:addChild(self.discountBg, 5)
    self.discountLabel = display.newLabel(10, self.discountBg:getContentSize().height / 2, fontWithColor(14, {text = '8折', ap = cc.p(0, 0.5)}))
    self.discountBg:addChild(self.discountLabel, 5)

    
end
return PrivateRoomThemeCell