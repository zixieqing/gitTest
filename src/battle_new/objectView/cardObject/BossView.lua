--[[
boss view
--]]
local CardObjectView = __Require('battle.objectView.cardObject.CardObjectView')
local BossView = class('BossView', CardObjectView)
local ExpressionNode = require('common.ExpressionNode')
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")

------------ import ------------
------------ import ------------

------------ define ------------
-- buff icon缩放
local BUFF_ICON_SCALE = 0.25
------------ define ------------

---------------------------------------------------
-- init view begin --
---------------------------------------------------
--[[
@override
初始化视图
--]]
function BossView:InitView()
	CardObjectView.InitView(self)
end
--[[
@override
创建ui
--]]
function BossView:InitUI()
	local battleScene = G_BattleRenderMgr:GetBattleScene()

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
	local hpBarPath = 'ui/battle/battle_boss_blood_bg_green.png'
	if self:GetVEnemy() then
		hpBarPath = 'ui/battle/battle_boss_blood_bg_2.png'
	end
	local hpBar = CProgressBar:create(_res(hpBarPath))
	hpBar:setBackgroundImage(_res('ui/battle/battle_boss_blood_bg_3.png'))
	hpBar:setDirection(eProgressBarDirectionLeftToRight)
	hpBar:setAnchorPoint(cc.p(1, 0.5))
	battleScene.viewData.uiLayer:addChild(hpBar)
	hpBar:setPosition(cc.p(
		battleScene.viewData.battleInfoBg:getPositionX() - 100,
		battleScene.viewData.battleInfoBg:getPositionY() - 30))

    local hpBarCover = display.newImageView(_res('ui/battle/battle_boss_blood_bg_1.png'), utils.getLocalCenter(hpBar).x, utils.getLocalCenter(hpBar).y)
    hpBar:addChild(hpBarCover, 99)

    local cardConf = CardUtils.GetCardConfig(self:GetVCardId())
    local nameLabel = display.newLabel(utils.getLocalCenter(hpBar).x, utils.getLocalCenter(hpBar).y + 15,
    	{text = cardConf.name, fontSize = 24, color = fontWithColor('BC').color, ttf = true, font = TTF_GAME_FONT, ap = cc.p(0.5, 0)})
    nameLabel:enableOutline(cc.c4b(0, 0, 0, 255), 1)
    hpBar:addChild(nameLabel, 99)

    local bossHpBarMark = display.newNSprite(_res('ui/battle/battle_boss_blood_jiao.png'), 40, utils.getLocalCenter(hpBar).y + 15)
    hpBar:addChild(bossHpBarMark, 99)

    -- energy bar
	local energyBar = CProgressBar:create(_res('ui/battle/battle_blood_bg_5.png'))
    energyBar:setDirection(eProgressBarDirectionLeftToRight)
    energyBar:setAnchorPoint(cc.p(0.5, 1))
    energyBar:setPosition(cc.p(bgSize.width * 0.5, self:GetAvatarStaticViewBox().height + 10))
    self:addChild(energyBar, 10)
    energyBar:setVisible(false)

    -- hp percent
    local hpPercentLabel = CLabelBMFont:create('100%', 'font/small/common_text_num.fnt')
    hpPercentLabel:setBMFontSize(24)
    hpPercentLabel:setAnchorPoint(cc.p(0.5, 0.5))
    hpPercentLabel:setPosition(cc.p(
    	hpBar:getContentSize().width * 0.5,
    	hpBar:getContentSize().height * 0.5
    ))
    hpBar:addChild(hpPercentLabel, 99)

	self.viewData.hpBar = hpBar
	self.viewData.energyBar = energyBar
	self.viewData.avatarShadow = avatarShadow
	self.viewData.hpPercentLabel = hpPercentLabel
	self.viewData.clearTargetMark = nil
	self.viewData.clearTargetShadow = nil
end
---------------------------------------------------
-- init view end --
---------------------------------------------------

---------------------------------------------------
-- view control begin --
---------------------------------------------------
--[[
@override
刷新一次ui大小 位置
--]]
function BossView:FixUIState()
	local avatar = self.avatar

	------------ 刷新根据spine avatar确定的变量 ------------
	self.staticViewBox = avatar:getBorderBox(sp.CustomName.VIEW_BOX)
	self.staticCollisionBox = avatar:getBorderBox(sp.CustomName.COLLISION_BOX)
	------------ 刷新根据spine avatar确定的变量 ------------

	------------ 刷新脚底阴影的大小 ------------
	self.viewData.avatarShadow:setScale(0.5 * (self:GetAvatarStaticViewBox().width / self.viewData.avatarShadow:getContentSize().width))
	------------ 刷新脚底阴影的大小 ------------
end
---------------------------------------------------
-- view control end --
---------------------------------------------------

---------------------------------------------------
-- object ui control begin --
---------------------------------------------------
--[[
@override
显示能量条
@params show bool 是否显示
--]]
function BossView:ShowEnergyBar(show)
	-- 能量条 怪物永远隐藏能量条
	self.viewData.energyBar:setVisible(false)
end
---------------------------------------------------
-- object ui control end --
---------------------------------------------------

---------------------------------------------------
-- hp energy control begin --
---------------------------------------------------
--[[
@override
刷新血条
@params hpPercent number 血量百分比
--]]
function BossView:UpdateHpBar(hpPercent)
	CardObjectView.UpdateHpBar(self, hpPercent)
	self.viewData.hpPercentLabel:setString(string.format('%0.2f%%', math.max(0, math.ceil(hpPercent * 10000) * 0.01)))
end
---------------------------------------------------
-- hp energy control end --
---------------------------------------------------

---------------------------------------------------
-- buff control begin --
---------------------------------------------------
--[[
@override
add buff
@params iconType BuffIconType 图标类型
@params value number 数值
--]]
function BossView:AddBuff(iconType, value)
    local iconPath = self:GetBuffIconPath(iconType, value)
	local buffTag = self:GetBuffIconTag(iconType, value)

	local buffIcon = display.newNSprite(_res(iconPath), 0, 0)
    display.commonUIParams(buffIcon, {ap = cc.p(0.5, 1)})
    buffIcon:setScale(BUFF_ICON_SCALE)
    self.viewData.hpBar:getParent():addChild(buffIcon, self.viewData.hpBar:getLocalZOrder())
    buffIcon:setTag(buffTag)

    table.insert(self.buffIcons, buffIcon)
    self:RefreshBuffIcons()
end
--[[
@override
刷新buff坐标
--]]
function BossView:RefreshBuffIcons()
	local y = -5
	local spaceW = 5
	display.setNodesToNodeOnCenter(self.viewData.hpBar, self.buffIcons, {y = y, spaceW = spaceW})
end
---------------------------------------------------
-- buff control end --
---------------------------------------------------

---------------------------------------------------
-- expression begin --
---------------------------------------------------
--[[
@override
显示表情
@params expressionType ExpressionType 表情类型
--]]
function BossView:ShowExpression(expressionType)
	local expressionNode = ExpressionNode.new({nodeType = expressionType})
	self:addChild(expressionNode, 20)
	local viewBox = self:GetAvatarStaticViewBox()
	expressionNode:setPosition(cc.p(viewBox.width * 0.25, viewBox.height * 0.75))
	expressionNode:setTag(357)

	local fps = 30
	local oriScale = 1
	local deltaP1 = cc.p(30, 30)
	local deltaP2 = cc.p(10, 10)
	local deltaP3 = cc.p(20, 20)
	expressionNode:setScale(0)
	expressionNode:setOpacity(0)

	local actionSeq = cc.Sequence:create(
		cc.Spawn:create(
			cc.ScaleTo:create(10 / fps, oriScale),
			cc.MoveBy:create(10 / fps, deltaP1),
			cc.FadeTo:create(10 / fps, 255)
		),
		cc.MoveBy:create(28 / fps, deltaP2),
		cc.Spawn:create(
			cc.ScaleTo:create(8 / fps, oriScale * 1.1),
			cc.MoveBy:create(8 / fps, deltaP3),
			cc.FadeTo:create(8 / fps, 0)
		),
		cc.RemoveSelf:create()
	)
	expressionNode:runAction(actionSeq)
end
---------------------------------------------------
-- expression end --
---------------------------------------------------
































-- --[[
-- 设置外部ui可见
-- @params visible bool 是否可见
-- --]]
-- function BossView:setOtherUIVisible(visible)
-- 	-- 血条
-- 	self.viewData.hpBar:setVisible(visible)

-- 	-- buff icon
-- 	for i,v in ipairs(self.buffIcons) do
-- 		v:setVisible(visible)
-- 	end

-- 	-- 周身ui
-- 	self:ShowAllObjectUI(visible)
-- end
-- --[[
-- 变身消失
-- @params fadeTime number 消失时间
-- @params callback function 回调
-- --]]
-- function BossView:deformDisappear(fadeTime, callback)
-- 	local actionSeq = cc.Sequence:create(
-- 		cc.FadeTo:create(fadeTime, 0),
-- 		cc.CallFunc:create(function ()
-- 			-- 隐藏外部ui
-- 			self:setOtherUIVisible(false)
-- 			if nil ~= callback then
-- 				callback()
-- 			end
-- 		end)
-- 	)
-- 	self:runAction(actionSeq)
-- end
-- --[[
-- 变身出现
-- @params delayTime number 延迟
-- @params fadeTime number 消失时间
-- @params callback function 回调
-- --]]
-- function BossView:deformAppear(delayTime, fadeTime, callback)
-- 	local actionSeqTable = {
-- 		cc.DelayTime:create(delayTime),
-- 		cc.Show:create(),
-- 		cc.FadeTo:create(fadeTime, 255),
-- 		cc.DelayTime:create(1)
-- 	}

-- 	if nil ~= callback then
-- 		table.insert(actionSeqTable, cc.CallFunc:create(callback))
-- 	end

-- 	local actionSeq = cc.Sequence:create(actionSeqTable)
-- 	self:runAction(actionSeq)
-- end
-- --[[
-- 开始逃跑
-- --]]
-- function BossView:escape()
-- 	self:setOtherUIVisible(false)
-- end
-- --[[
-- 逃跑消失
-- --]]
-- function BossView:escapeDisappear()
-- 	self:setVisible(false)
-- end
-- --[[
-- 逃跑后出现
-- --]]
-- function BossView:escapeAppear()
-- 	self:setVisible(true)
-- 	self:setOtherUIVisible(true)
-- end
-- --[[
-- @override
-- 强制隐藏
-- --]]
-- function BossView:forceHide()
-- 	self:ShowAllObjectUI(false)
-- 	self:setVisible(false)
-- end
-- --[[
-- @override
-- 强制显示
-- --]]
-- function BossView:forceShow()
-- 	self:ShowAllObjectUI(true)
-- 	self:setVisible(true)
-- end
--[[
@override
显示杀戮模式相关信息
@params show bool 是否显示
--]]
function BossView:ShowSlayStageClearTarget(show)
	CardObjectView.ShowSlayStageClearTarget(self, show)
	
	if nil ~= self.viewData.clearTargetMark then
		self.viewData.clearTargetMark:setPositionX(
			self.viewData.hpBar:getPositionX() - self.viewData.hpBar:getContentSize().width - self.viewData.clearTargetMark:getContentSize().width * 0.5 - 10
		)
		self.viewData.clearTargetMark:setScale(1)
	end
end
--[[
@override
显示治疗目标信息
@params show bool 是否显示
--]]
function BossView:ShowHealStageClearTarget(show)
	CardObjectView.ShowHealStageClearTarget(self, show)
	
	if nil ~= self.viewData.clearTargetMark then
		self.viewData.clearTargetMark:setPositionX(
			self.viewData.hpBar:getPositionX() - self.viewData.hpBar:getContentSize().width - self.viewData.clearTargetMark:getContentSize().width * 0.5 - 10
		)
		self.viewData.clearTargetMark:setScale(1)
	end
end


return BossView
