--[[
monster view
--]]
local CardObjectView = __Require('battle.objectView.CardObjectView')
local MonsterView = class('MonsterView', CardObjectView)
local ExpressionNode = require('common.ExpressionNode')
--[[
@override
初始化视图
--]]
function MonsterView:initView()
	CardObjectView.initView(self)
end
--[[
@override
创建ui
--]]
function MonsterView:InitUI()
	-- 处理大小
	local bgSize = cc.size(0, 0)
	self:setContentSize(bgSize)
	self:setAnchorPoint(cc.p(0.5, 0))
	-- self:setBackgroundColor(cc.c4b(255, 0, 0, 255))

	-- 角色阴影
	local avatarShadow = display.newNSprite(_res('ui/battle/battle_role_shadow.png'), bgSize.width * 0.5, 0)
	self:addChild(avatarShadow, 1)
	avatarShadow:setScale(0.5 * (self:getAvatarStaticViewBox().width / avatarShadow:getContentSize().width))
	avatarShadow:setVisible(not self:getForceHideAvatarShadow())

	-- hp bar
	local hpBarPath = 'ui/battle/battle_monster_blood_bg_1_green.png'
	if self:getVEnemy() then
		hpBarPath = 'ui/battle/battle_monster_blood_bg_1.png'
	end
	local hpBar = CProgressBar:create(_res(hpBarPath))
    hpBar:setBackgroundImage(_res('ui/battle/battle_monster_blood_bg_2.png'))
    hpBar:setDirection(eProgressBarDirectionLeftToRight)
    hpBar:setPosition(cc.p(bgSize.width * 0.5, self:getAvatarStaticViewBox().height + 15))
    self:addChild(hpBar, 10)

    -- energy bar
	local energyBar = CProgressBar:create(_res('ui/battle/battle_blood_bg_5.png'))
    energyBar:setDirection(eProgressBarDirectionLeftToRight)
    energyBar:setPosition(cc.p(hpBar:getPositionX(), hpBar:getPositionY()))
    self:addChild(energyBar, 11)
    energyBar:setVisible(false)

	self.viewData.hpBar = hpBar
	self.viewData.energyBar = energyBar
	self.viewData.avatarShadow = avatarShadow
	self.viewData.clearTargetMark = nil
	self.viewData.clearTargetShadow = nil
end
--[[
@override
显示周身ui
@params show bool 是否显示
--]]
function MonsterView:ShowAllObjectUI(show)
	self.viewData.hpBar:setVisible(show)
	self.viewData.energyBar:setVisible(false)
	self:showAvatarShadow(show)

	for i,v in ipairs(self.buffIcons) do
		v:setVisible(show)
	end

	-- 目标mark
	if not show then
		if nil ~= self.viewData.clearTargetMark then
			self.viewData.clearTargetMark:setVisible(false)
		end

		if nil ~= self.viewData.clearTargetShadow then
			self.viewData.clearTargetShadow:setVisible(false)
			self.viewData.clearTargetShadow:clearTracks()
		end
	end
end
--[[
@override
复活
--]]
function MonsterView:revive()
	-- 显示周身特效
	CardObjectView.revive(self)
	
	-- 显示周身ui
	self:ShowAllObjectUI(true)
end

return MonsterView
