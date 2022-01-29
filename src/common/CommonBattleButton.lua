--[[
通用战斗按钮版式
@params table {
	pattern int 样式 1 默认（战斗按钮）
				样式 2 配送
				样式 3 探索		
				样式 4 新探索
				样式 6 自定义文字
	clickCallback function
	battleText string 自定义文字的内容
	battleFontSize int 自定义文字的大小
	buttonSkinType BattleButtonSkinType 战斗按钮的皮肤类型
}
--]]
---@class CommonBattleButton : CButton
local CommonBattleButton = class('CommonBattleButton', function ()
	local node = CButton:create()
	node.name = 'common.CommonBattleButton'
	node:enableNodeEvents()
	return node
end)

------------ import ------------
------------ import ------------

------------ define ------------
local RES_DICT = {
	-- 按钮底图
	BTN_N = 'ui/common/mb.png',
	BTN_D = 'ui/common/mb_g.png',
	BTN_N_EX = 'ui/common/lunatower_btn_exfight.png',
	-- 特效spine
	BTN_EFFECT_JSON = 'battle/effect/button_start_battle.json',
	BTN_EFFECT_ATLAS = 'battle/effect/button_start_battle.atlas',
	BTN_EFFECT_JSON_EX = 'battle/effect/button_start_battle_ex.json',
	BTN_EFFECT_ATLAS_EX = 'battle/effect/button_start_battle_ex.atlas'
}

-- 战斗按钮的皮肤类型
BattleButtonSkinType = {
	BASE 		= 0, -- 最基本的皮肤样式
	EX 			= 1, -- ex类型的战斗样式 浑身发紫
}

-- 战斗按钮的皮肤定义
local BattleButtonSkinConfig = {
	[BattleButtonSkinType.BASE] 	= {n = RES_DICT.BTN_N, d = RES_DICT.BTN_D, spJson = RES_DICT.BTN_EFFECT_JSON, spAtlas = RES_DICT.BTN_EFFECT_ATLAS},
	[BattleButtonSkinType.EX] 		= {n = RES_DICT.BTN_N_EX, d = RES_DICT.BTN_D, spJson = RES_DICT.BTN_EFFECT_JSON_EX, spAtlas = RES_DICT.BTN_EFFECT_ATLAS_EX},
}
------------ define ------------

--[[
contrustor
--]]
function CommonBattleButton:ctor( ... )
	local args = unpack({...}) or {}

	self.pattern = args.pattern or 1
	self.clickCallback = args.clickCallback
	self.battleText = args.battleText
	self.battleFontSize = args.battleFontSize
	self.buttonSkinType = args.buttonSkinType or BattleButtonSkinType.BASE

	self:Init()
end
---------------------------------------------------
-- logic init begin --
---------------------------------------------------
--[[
初始化
--]]
function CommonBattleButton:Init()
	self:InitValue()
	self:InitUI()
	self:InitClickCallback()

	local setEnabledFunc = self.setEnabled
	if self.pattern ~= 4 then
		self.setEnabled = function(obj, isEnabled)
			setEnabledFunc(obj, isEnabled)
			self.battleSpine_:setVisible(isEnabled == true)
		end
	end
end
--[[
初始化数据
--]]
function CommonBattleButton:InitValue()
	self.battleSpine_ = nil
	self.btnLabel_ = nil
end
--[[
初始化样式
--]]
function CommonBattleButton:InitUI()
	local buttonSkinConfig = BattleButtonSkinConfig[self.buttonSkinType]

	------------ 按钮底板 ------------
	self:setNormalImage(_res(buttonSkinConfig.n))
	self:setDisabledImage(_res(buttonSkinConfig.d))
	------------ 按钮底板 ------------

	------------ 火焰特效 ------------
	local battleSpine = sp.SkeletonAnimation:create(
		buttonSkinConfig.spJson,
		buttonSkinConfig.spAtlas,
		1
	)
	battleSpine:update(0)
	battleSpine:setAnimation(0, 'idle', true)
	self.battleSpine_ = battleSpine

	battleSpine:setPosition(utils.getLocalCenter(self))
	self:addChild(battleSpine, 2)
	------------ 火焰特效 ------------

	------------ 文字 ------------
	self:InitDefaultPattern()
	------------ 文字 ------------
end
--[[
初始化按钮回调
--]]
function CommonBattleButton:InitClickCallback()
	display.commonUIParams(self, {cb = handler(self, self.ClickHandler), animate = self.isClickAnimate})
end
--[[
添加文字
--]]
function CommonBattleButton:InitDefaultPattern()
	local centerPos = utils.getLocalCenter(self)

	local btnLabel = nil

	if self.pattern == 2 then
		btnLabel = display.newLabel(centerPos.x, centerPos.y, fontWithColor('20', { fontSize = 46, text = __('配送'),reqW = 130 }))
		btnLabel:setName("btnLabel")
		self:addChild(btnLabel, 5)
	elseif self.pattern == 3 or self.pattern == 4 then
		btnLabel = display.newLabel(centerPos.x, centerPos.y, fontWithColor('20', { fontSize = 46, text = __('探索'),reqW = 130 }))
		btnLabel:setName("btnLabel")
		self:addChild(btnLabel, 5)
	elseif self.pattern == 6 then
		btnLabel = display.newLabel(centerPos.x, centerPos.y, fontWithColor('20', { fontSize = self.battleFontSize, text = self.battleText, reqW = 110}))
		btnLabel:setName("btnLabel")
		self:addChild(btnLabel, 5)
	else
		btnLabel = display.newImageView(_res('ui/common/mb_zi.png'), centerPos.x, centerPos.y)
		btnLabel:setName("btnLabel")
		self:addChild(btnLabel, 5)
	end

	self.btnLabel_ = btnLabel
end
--[[
设置按钮回调
--]]
function CommonBattleButton:SetClickCallback(clickCallback, isAnimate)
	if nil ~= clickCallback then
		self.ClickHandler   = clickCallback
		self.isClickAnimate = isAnimate
		self:InitClickCallback()
	end
end
---------------------------------------------------
-- logic init end --
---------------------------------------------------

---------------------------------------------------
-- refresh begin --
---------------------------------------------------
--[[
刷新按钮样式
@params {
	buttonSkinType BattleButtonSkinType 按钮皮肤类型
}
--]]
function CommonBattleButton:RefreshButton(params)
	-- 皮肤样式
	local buttonSkinType = params.buttonSkinType
	if nil ~= buttonSkinType then
		self:RefreshButtonSkinType(buttonSkinType)
	end
end
--[[
刷新按钮皮肤类型
@params buttonSkinType BattleButtonSkinType 按钮皮肤类型
--]]
function CommonBattleButton:RefreshButtonSkinType(buttonSkinType)
	if buttonSkinType == self.buttonSkinType then return end

	self.buttonSkinType = buttonSkinType
	local buttonSkinConfig = BattleButtonSkinConfig[self.buttonSkinType]

	------------ 按钮底板 ------------
	self:setNormalImage(_res(buttonSkinConfig.n))
	self:setDisabledImage(_res(buttonSkinConfig.d))
	------------ 按钮底板 ------------

	------------ 火焰特效 ------------
	-- 移除老的spine
	self.battleSpine_:setVisible(false)
	self.battleSpine_:clearTracks()
	self.battleSpine_:removeFromParent()

	-- 创建新的spine
	local battleSpine = sp.SkeletonAnimation:create(
		buttonSkinConfig.spJson,
		buttonSkinConfig.spAtlas,
		1
	)
	battleSpine:update(0)
	battleSpine:setAnimation(0, 'idle', true)
	self.battleSpine_ = battleSpine

	battleSpine:setPosition(utils.getLocalCenter(self))
	self:addChild(battleSpine, 2)
	------------ 火焰特效 ------------
end
--[[
刷新文字
@params text string 按钮文字
--]]
function CommonBattleButton:SetText(text)
	if 'ccw.CLabel' == tolua.type(self.btnLabel_) and nil ~= self.btnLabel_.setString then
		self.btnLabel_:setString(text)
	end
end
function CommonBattleButton:updatePattern(args)
	self.pattern = args.pattern or self.pattern
	self.battleText = args.battleText
	local btnLabel = self:getChildByName("btnLabel")
	if btnLabel ~= nil then
		btnLabel:removeFromParent()
		btnLabel = nil
	end
	self:InitDefaultPattern()
end
---------------------------------------------------
-- refresh end --
---------------------------------------------------

---------------------------------------------------
-- click callback begin --
---------------------------------------------------
--[[
点击回调
--]]
function CommonBattleButton:ClickHandler(sender)
	PlayAudioByClickNormal()
	if nil ~= self.clickCallback then
		xTry(function ()	
			self.clickCallback(sender)
		end, __G__TRACKBACK__)
	end
end
---------------------------------------------------
-- click callback end --
---------------------------------------------------


return CommonBattleButton
