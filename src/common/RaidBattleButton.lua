--[[
组队战斗按钮
@params table {
	pattern int 样式 1 默认
	clickCallback function
}
--]]
local CommonBattleButton = require('common.CommonBattleButton')
local RaidBattleButton = class('RaidBattleButton', CommonBattleButton)

--[[
@override
contrustor
--]]
function RaidBattleButton:ctor( ... )
	CommonBattleButton.ctor(self, ...)
end
---------------------------------------------------
-- logic init begin --
---------------------------------------------------
--[[
初始化
--]]
function RaidBattleButton:Init()
	self:InitValue()
	self:InitUI()
	self:InitClickCallback()
end
--[[
@override
添加文字
--]]
function RaidBattleButton:InitDefaultPattern()
	local btnLabel = display.newLabel(0, 0, {
		text = '准备', fontSize = 36, color = '#ffffff', ttf = true, font = TTF_GAME_FONT, outline = '#311717', outlineSize = 2
	})
	display.commonUIParams(btnLabel, {po = utils.getLocalCenter(self)})
	btnLabel:setName("btnLabel")
	self:addChild(btnLabel, 5)
	self.btnLabel_ = btnLabel

	self:ShowBattleSpine(false)
end
---------------------------------------------------
-- logic init end --
---------------------------------------------------

---------------------------------------------------
-- view control begin --
---------------------------------------------------
--[[
设置按钮为不可用状态
@params enable bool 是否可用
--]]
function RaidBattleButton:SetSelfEnable(enable)
	if false == enable then
		self:ShowBattleSpine(false)
	end
	self:setEnabled(enable)
end
--[[
设置准备火是否显示
@params show bool 是否显示
--]]
function RaidBattleButton:ShowBattleSpine(show)
	self.battleSpine_:setVisible(show)
end
---------------------------------------------------
-- view control end --
---------------------------------------------------

return RaidBattleButton
