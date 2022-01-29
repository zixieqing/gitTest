--[[
连携按钮
@params {
	objTag int 战斗物体tag
	skillId int 技能id
	callback function 点击回调
}
--]]
local ConnectButton = class('ConnectButton', function ()
	local node = CLayout:create()
	node.name = 'battle.view.ConnectButton'
	node:enableNodeEvents()
	print('ConnectButton', ID(node))
	return node
end)
--[[
constructor
--]]
function ConnectButton:ctor( ... )
	local args = unpack({...})
	self.skillId = checkint(args.skillId)
	self.objTag = args.objTag
	self.callback = args.callback
	self.isTouchEnabled = true
	self.canUseConnectSkill = true

	self:InitUI()
end
--[[
初始化ui
--]]
function ConnectButton:InitUI()
	local function CreateView()

		self:setScale(0.85)

		-- 技能图标
		local skillIconBg = display.newButton(0, 0, {n = _res('ui/battle/battle_bg_lianxie_1.png')})

		local bgSize = skillIconBg:getContentSize()
		self:setContentSize(bgSize)

		display.commonUIParams(skillIconBg, {po = utils.getLocalCenter(skillIconBg)})
		self:addChild(skillIconBg)

		------------ 裁剪技能图标 ------------
		local skillClipNode = cc.ClippingNode:create()
		skillClipNode:setContentSize(bgSize)
		skillClipNode:setAnchorPoint(cc.p(0.5, 0.5))
		skillClipNode:setPosition(utils.getLocalCenter(skillIconBg))
		skillIconBg:addChild(skillClipNode, 3)

		local skillIcon = display.newNSprite(_res(CommonUtils.GetSkillIconPath(self.skillId)), 0, 0)
		display.commonUIParams(skillIcon, {po = utils.getLocalCenter(skillIconBg)})
		skillIcon:setScale(skillIcon:getContentSize().width / bgSize.width * 0.75)
		skillClipNode:addChild(skillIcon)

		local skillIconStencilNode = display.newNSprite(_res('ui/battle/battle_bg_lianxie_unlock.png'), 0, 0)
		skillIconStencilNode:setScale(0.9)
		skillIconStencilNode:setPosition(utils.getLocalCenter(skillIconBg))

		skillClipNode:setInverted(false)
		skillClipNode:setAlphaThreshold(0.1)
		skillClipNode:setStencil(skillIconStencilNode)
		------------ 裁剪技能图标 ------------

		local skillIconCover = display.newNSprite(_res('ui/battle/battle_bg_lianxie_2.png'), 0, 0)
		display.commonUIParams(skillIconCover, {po = utils.getLocalCenter(skillIconBg)})
		skillIconBg:addChild(skillIconCover, 5)

		local skillIconShine = display.newNSprite(_res('ui/battle/battle_bg_lianxie_light.png'), 0, 0)
		display.commonUIParams(skillIconShine, {po = utils.getLocalCenter(skillIconBg)})
		skillIconBg:addChild(skillIconShine, -1)

		local skillIconDisableCover = display.newNSprite(_res('ui/battle/battle_bg_lianxie_unlock.png'), 0, 0)
		display.commonUIParams(skillIconDisableCover, {po = utils.getLocalCenter(skillIconBg)})
		skillIconBg:addChild(skillIconDisableCover, 10)

		local skillIconDisableMark = display.newNSprite(_res('ui/battle/battle_skill_ico_disable.png'), 0, 0)
		display.commonUIParams(skillIconDisableMark, {po = utils.getLocalCenter(skillIconBg)})
		skillIconBg:addChild(skillIconDisableMark, 15)

		-- 连携技拥有者头像
		local casterHeadBg = display.newNSprite(_res('ui/battle/battle_bg_lianxie_head_1.png'), 25, 17)
		self:addChild(casterHeadBg)

		------------ 裁剪连携技拥有者头像 ------------
		local headClipNode = cc.ClippingNode:create()
		headClipNode:setContentSize(casterHeadBg:getContentSize())
		headClipNode:setAnchorPoint(cc.p(0.5, 0.5))
		headClipNode:setPosition(utils.getLocalCenter(casterHeadBg))
		casterHeadBg:addChild(headClipNode, 3)

		local caster = BMediator:IsObjAliveByTag(self.objTag)
		local headIconPath = caster:getDrawPathInfo().headPath
		local headIcon = display.newNSprite(_res(headIconPath), 0, 0)
		display.commonUIParams(headIcon, {po = utils.getLocalCenter(casterHeadBg)})
		headIcon:setScale(headClipNode:getContentSize().width / headIcon:getContentSize().width)
		headClipNode:addChild(headIcon)

		local headIconStencilNode = display.newNSprite(_res('ui/battle/battle_bg_lianxie_head_1.png'), 0, 0)
		headIconStencilNode:setScale(0.9)
		headIconStencilNode:setPosition(utils.getLocalCenter(casterHeadBg))

		headClipNode:setInverted(false)
		headClipNode:setAlphaThreshold(0.1)
		headClipNode:setStencil(headIconStencilNode)
		------------ 裁剪连携技拥有者头像 ------------

		local casterHeadCover = display.newNSprite(_res('ui/battle/battle_bg_lianxie_head_2.png'), 0, 0)
		display.commonUIParams(casterHeadCover, {po = utils.getLocalCenter(casterHeadBg)})
		casterHeadBg:addChild(casterHeadCover, 5)

		local casterHeadDisableCover = display.newNSprite(_res('ui/battle/battle_bg_lianxie_head_unlock.png'), 0, 0)
		display.commonUIParams(casterHeadDisableCover, {po = utils.getLocalCenter(casterHeadBg)})
		casterHeadBg:addChild(casterHeadDisableCover, 10)

		-- 连携技拥有者能量条
		local cardEnergyBar = CProgressBar:create(_res('ui/battle/battle_bg_lianxie_line_2.png'))
		cardEnergyBar:setBackgroundImage(_res('ui/battle/battle_bg_lianxie_line_1.png'))
		cardEnergyBar:setMaxValue(MAX_ENERGY)
		cardEnergyBar:setValue(50)
		cardEnergyBar:setDirection(eProgressBarDirectionLeftToRight)
		cardEnergyBar:setPosition(cc.p(93, 20))
		self:addChild(cardEnergyBar)

		local cardEnergyBarShine = display.newNSprite(_res('ui/battle/battle_bg_lianxie_line_light.png'), 0, 0)
		display.commonUIParams(cardEnergyBarShine, {po = utils.getLocalCenter(cardEnergyBar)})
		cardEnergyBar:addChild(cardEnergyBarShine, 5)

		skillIconShine:setVisible(false)
		skillIconDisableCover:setVisible(false)
		skillIconDisableMark:setVisible(false)
		casterHeadDisableCover:setVisible(false)
		cardEnergyBarShine:setVisible(false)

		return {
			skillIconBg = skillIconBg,
			skillIconShine = skillIconShine,
			skillIconDisableCover = skillIconDisableCover,
			skillIconDisableMark = skillIconDisableMark,
			casterHeadDisableCover = casterHeadDisableCover,
			cardEnergyBar = cardEnergyBar,
			cardEnergyBarShine = cardEnergyBarShine
		}

	end

	xTry(function ( )
		self.viewData = CreateView( )
	end, __G__TRACKBACK__)

	display.commonUIParams(self.viewData.skillIconBg, {cb = handler(self, self.ClickCallback)})

end
--[[
点击回调
--]]
function ConnectButton:ClickCallback(sender)
	if nil ~= self.callback then
		self.callback(self.objTag, self.skillId)
	end
end
--[[
刷新按钮
按钮需要刷新 满足条件后的闪光 不满足条件的黑色遮罩 不可点的红叉
@params energy int obj 能量
@params canAct bool obj是否可以行动
@params state OState obj 状态
@params silent bool 是否被沉默
@params enchanting bool 是否被魅惑
--]]
function ConnectButton:RefreshButton(energy, canAct, state, silent, enchanting)
	self:RefreshButtonByEnergy(energy)
	self:RefreshButtonByState(canAct, state, silent, enchanting)
end
--[[
刷新按钮 单能量
@params energy int obj 能量
--]]
function ConnectButton:RefreshButtonByEnergy(energy)
	self.viewData.cardEnergyBar:setValue(energy)
	if not self:GetCanUse() then
		-- 有连携对象死亡
		self:DisableConnectButton()
		return
	end
	if energy >= MAX_ENERGY then
		-- 能量满了
		self.viewData.skillIconShine:setVisible(true)
		self.viewData.cardEnergyBarShine:setVisible(true)
		self.viewData.skillIconDisableCover:setVisible(false)
	else
		-- 能量不满
		self.viewData.skillIconShine:setVisible(false)
		self.viewData.cardEnergyBarShine:setVisible(false)
		self.viewData.skillIconDisableCover:setVisible(true)
	end
end
--[[
刷新按钮 单状态
@params canAct bool obj是否可以行动
@params state OState obj 状态
@params silent bool 是否被沉默
@params enchanting bool 是否被魅惑
--]]
function ConnectButton:RefreshButtonByState(canAct, state, silent, enchanting)
	if not self:GetCanUse() then
		-- 有连携对象死亡
		self:DisableConnectButton()
		return 
	end
	if silent or not canAct or OState.SLEEP == state or enchanting then
		-- 无法行动
		self.viewData.skillIconDisableMark:setVisible(true)
	elseif OState.DIE == state then
		-- 卡牌死亡技能失效
		self:DisableConnectButton()
	else
		self.viewData.skillIconDisableMark:setVisible(false)
		self.viewData.casterHeadDisableCover:setVisible(false)
	end
end
--[[
熄灭连携按钮
--]]
function ConnectButton:DisableConnectButton()
	self.viewData.skillIconShine:setVisible(false)
	self.viewData.cardEnergyBarShine:setVisible(false)

	self.viewData.skillIconDisableCover:setVisible(true)
	self.viewData.skillIconDisableMark:setVisible(true)
	self.viewData.casterHeadDisableCover:setVisible(true)
end
--[[
点亮连携技按钮
--]]
function ConnectButton:EnableConnectButtonByRevenge()

end

--[[
是否满足连携技的使用条件
--]]
function ConnectButton:GetCanUse()
	return self.canUseConnectSkill
end
function ConnectButton:SetCanUse(b)
	self.canUseConnectSkill = b
end

return ConnectButton
