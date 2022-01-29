--[[
monster view
--]]
local CardObjectView = __Require('battle.objectView.cardObject.CardObjectView')
local MonsterView = class('MonsterView', CardObjectView)
local ExpressionNode = require('common.ExpressionNode')

------------ import ------------
------------ import ------------

------------ define ------------
------------ define ------------

---------------------------------------------------
-- init view begin --
---------------------------------------------------
--[[
@override
初始化视图
--]]
function MonsterView:InitView()
	CardObjectView.InitView(self)
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
	avatarShadow:setScale(0.5 * (self:GetAvatarStaticViewBox().width / avatarShadow:getContentSize().width))
	avatarShadow:setVisible(not self:GetForceHideAvatarShadow())

	-- hp bar
	local hpBarPath = 'ui/battle/battle_monster_blood_bg_1_green.png'
	if self:GetVEnemy() then
		hpBarPath = 'ui/battle/battle_monster_blood_bg_1.png'
	end
	local hpBar = CProgressBar:create(_res(hpBarPath))
    hpBar:setBackgroundImage(_res('ui/battle/battle_monster_blood_bg_2.png'))
    hpBar:setDirection(eProgressBarDirectionLeftToRight)
    hpBar:setPosition(cc.p(bgSize.width * 0.5, self:GetAvatarStaticViewBox().height + 15))
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
---------------------------------------------------
-- init view end --
---------------------------------------------------

---------------------------------------------------
-- object ui control begin --
---------------------------------------------------
--[[
@override
显示能量条
@params show bool 是否显示
--]]
function MonsterView:ShowEnergyBar(show)
	-- 能量条 怪物永远隐藏能量条
	self.viewData.energyBar:setVisible(false)
end
---------------------------------------------------
-- object ui control end --
---------------------------------------------------

return MonsterView
