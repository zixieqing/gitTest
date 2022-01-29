--[[
主角模型view
--]]
local PlayerObjectView = class('PlayerObjectView')

------------ import ------------
------------ import ------------

------------ define ------------
local RES_DICT = {
	PLAYER_MODULE_BG 					= 'ui/battle/battle_bg_lead_skill.png',
	PLAYER_ENERGY_BAR 					= 'ui/battle/battle_bg_skill_energy_line_1.png',
	PLAYER_ENERGY_BAR_BG 				= 'ui/battle/battle_bg_skill_energy_line_2.png',
	PLAYER_ENERGY_BAR_LIGHT 			= 'ui/battle/battle_bg_skill_energy_light.png',
	PLAYER_SKILL_ICON_BG 				= 'ui/battle/battle_bg_skill_default.png',
	PLAYER_SKILL_ICON_ENERGY_BG 		= 'ui/battle/battle_bg_skill_energy.png'
}

local PlayerSkillIconInfo = {
	[1] = {skillIconPos = cc.p(78 + 60, 188), energyIconPos = cc.p(-41, -39)},
	[2] = {skillIconPos = cc.p(185 + 60, 81), energyIconPos = cc.p(-41, -39)}
}
------------ define ------------

--[[
constructor
--]]
function PlayerObjectView:ctor( ... )
	local args = unpack({...})
	self.idInfo = {
		tag = args.tag,
		logicTag = args.logicTag
	}
	self.viewInfo = args.viewInfo

	self:InitValue()
	self:InitView()
end

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化数值
--]]
function PlayerObjectView:InitValue()
	-- 主角技模块底层
	self.playerSkillLayer = nil

	-- 技能按钮集合
	self.playerSkillButtons = {}

	-- 技能按钮map
	self.playerSkillButtonsId = {}

	self.energyLabel = nil
	self.playerEnergyBar = nil
	self.playerEnergyBarLight = nil
end
--[[
初始化视图
--]]
function PlayerObjectView:InitView()
	self:InitUI()
end
--[[
创建ui
--]]
function PlayerObjectView:InitUI()
	-- 父节点
	local parentNode = G_BattleRenderMgr:GetBattleScene().viewData.uiLayer

	-- 创建底板层
	local playerSkillBg = display.newImageView(_res(RES_DICT.PLAYER_MODULE_BG), 0, 0)
	local playerSkillLayer = display.newLayer(0, 0, {size = playerSkillBg:getContentSize()})
	display.commonUIParams(playerSkillLayer, {ap = cc.p(0, 0), po = cc.p(display.SAFE_L - 60, 0)})
	parentNode:addChild(playerSkillLayer)

	display.commonUIParams(playerSkillBg, {ap = cc.p(0, 0), po = cc.p(0, 0)})
	playerSkillLayer:addChild(playerSkillBg)

	self.playerSkillLayer = playerSkillLayer

	-- 主角能量条
	local playerEnergyBar = CProgressBar:create(_res(RES_DICT.PLAYER_ENERGY_BAR))
	playerEnergyBar:setBackgroundImage(_res(RES_DICT.PLAYER_ENERGY_BAR_BG))
	playerEnergyBar:setMaxValue(MAX_ENERGY)
	playerEnergyBar:setValue(0)
	playerEnergyBar:setDirection(eProgressBarDirectionLeftToRight)
	playerEnergyBar:setPosition(cc.p(400 + 60, 23))
	playerSkillBg:addChild(playerEnergyBar)
	self.playerEnergyBar = playerEnergyBar

	local playerEnergyBarLight = display.newNSprite(_res(RES_DICT.PLAYER_ENERGY_BAR_LIGHT), 0, 0)
	display.commonUIParams(playerEnergyBarLight, {po = utils.getLocalCenter(playerEnergyBar)})
	playerEnergyBar:addChild(playerEnergyBarLight, -1)
	playerEnergyBarLight:setVisible(false)
	self.playerEnergyBarLight = playerEnergyBarLight

	local energyLabel = display.newLabel(playerEnergyBar:getPositionX(), playerEnergyBar:getPositionY(), fontWithColor('9', {text = '0'}))
	playerSkillBg:addChild(energyLabel)
	self.energyLabel = energyLabel

	-- 初始化技能图标
	for skillIndex, v in ipairs(PlayerSkillIconInfo) do
		-- 图标背景
		local playerSkillIconFrame = display.newNSprite(_res(RES_DICT.PLAYER_SKILL_ICON_BG), v.skillIconPos.x, v.skillIconPos.y)
		playerSkillBg:addChild(playerSkillIconFrame)

		-- 空版式的提示按钮
		local playerSkillHintButton = display.newButton(0, 0, {size = playerSkillIconFrame:getContentSize(), animte = false})
		display.commonUIParams(playerSkillHintButton, {animate = false, cb = handler(self, self.EmptySkillClickHandler)})
		display.commonUIParams(playerSkillHintButton, {po = cc.p(v.skillIconPos.x, v.skillIconPos.y)})
		playerSkillLayer:addChild(playerSkillHintButton, 5)

		local playerSkillEnergyFrame = display.newNSprite(_res(RES_DICT.PLAYER_SKILL_ICON_ENERGY_BG),
			v.skillIconPos.x + v.energyIconPos.x,
			v.skillIconPos.y + v.energyIconPos.y)
		playerSkillLayer:addChild(playerSkillEnergyFrame, 10)

		-- 设置一次技能信息
		local buttonInfo = {
			playerSkillHintButton = playerSkillHintButton,
			playerSkillEnergyFrame = playerSkillEnergyFrame,
			playerSkillButton = nil
		}
		self:SetPlayerSkillButtonInfo(skillIndex, buttonInfo)
	end
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- view control begin --
---------------------------------------------------
--[[
添加一个主角技按钮
@params skillIndex int 序号
@params skillId int 技能id
@params callback function 点击回调
--]]
function PlayerObjectView:AddAPlayerSkillIcon(skillIndex, skillId, callback)
	local buttonInfo = self:GetPlayerSkillButtonInfo(skillIndex)
	if nil ~= buttonInfo then
		if nil == buttonInfo.playerSkillButton then
			buttonInfo.playerSkillHintButton:setVisible(false)

			local skillConfig = CommonUtils.GetSkillConf(skillId)

			-- 创建技能按钮
			local playerSkillButton = __Require('battle.view.PlayerSkillButton').new({
				logicTag = self:GetLogicTag(),
				skillId = skillId,
				callback = callback
			})
			playerSkillButton:setTag(skillId)
			local buttonSize = playerSkillButton:getContentSize()
			local pos = PlayerSkillIconInfo[skillIndex].skillIconPos
			display.commonUIParams(playerSkillButton, {po = pos})
			self.playerSkillLayer:addChild(playerSkillButton, 5)

			buttonInfo.playerSkillButton = playerSkillButton
			self:SetPlayerSkillButtonBySkillId(skillId, playerSkillButton)

			-- 创建技能能量消耗
			local energyCost = checknumber(skillConfig.triggerType[tostring(ConfigSkillTriggerType.ENERGY)])
			local playerSkillEnergyFrame = buttonInfo.playerSkillEnergyFrame
			local playerSkillEnergyCostLabel = display.newLabel(utils.getLocalCenter(playerSkillEnergyFrame).x, utils.getLocalCenter(playerSkillEnergyFrame).y,
				{text = energyCost, fontSize = 20, color = '#ffffff'})
			playerSkillEnergyFrame:addChild(playerSkillEnergyCostLabel)
		end
	else
		-- TODO --
	end
end
--[[
刷新一个主角技按钮的状态 -> cd时间
@params skillId int 技能id
@params cdPercent number 冷却时间百分比
--]]
function PlayerObjectView:RefreshPlayerSkillByCDPercent(skillId, cdPercent)
	local skillButton = self:GetPlayerSkillButtonBySkillId(skillId)
	if skillButton and skillButton.RefreshButtonCountdownPercent then
		skillButton:RefreshButtonCountdownPercent(cdPercent)
	end
end
--[[
刷新一个主角技按钮的状态 -> 是否可以释放
@params skillId int 技能id
@params canCast bool 是否可以释放
--]]
function PlayerObjectView:RefreshPlayerSkillByState(skillId, canCast)
	local skillButton = self:GetPlayerSkillButtonBySkillId(skillId)
	if skillButton and skillButton.RefreshButtonState then
		skillButton:RefreshButtonState(canCast)
	end
end
--[[
刷新能量条
@params percent 能量百分比
--]]
function PlayerObjectView:UpdateEnergyBar(percent)
	local energyValue = math.ceil(MAX_ENERGY * percent)
	self.energyLabel:setString(energyValue)
	self.playerEnergyBar:setValue(energyValue)
	self.playerEnergyBarLight:setVisible(energyValue >= MAX_ENERGY)
end
--[[
设置是否可见
@params visible bool 是否可见
--]]
function PlayerObjectView:SetVisible(visible)
	self.playerSkillLayer:setVisible(visible)
end
---------------------------------------------------
-- view control end --
---------------------------------------------------

---------------------------------------------------
-- click handler begin --
---------------------------------------------------
--[[
默认的按钮提示
--]]
function PlayerObjectView:EmptySkillClickHandler(sender)
	local unlockLevel = CommonUtils.GetConfigAllMess('module')[tostring(MODULE_DATA[tostring(RemindTag.TALENT)])].openLevel
	local playerSkillDescr = string.format(__('%d级解锁料理天赋，需要手动装备。'), checkint(unlockLevel))
	app.uiMgr:ShowInformationTipsBoard({targetNode = sender, title = __('料理天赋'), descr = playerSkillDescr, type = 5})
end
---------------------------------------------------
-- click handler end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
获取展示层tag
--]]
function PlayerObjectView:GetVTag()
	return self.idInfo.tag
end
--[[
获取逻辑层tag
--]]
function PlayerObjectView:GetLogicTag()
	return self.idInfo.logicTag
end
--[[
根据技能序号获取主角技按钮信息
@params skillIndex int 技能序号
@return _ table {
	playerSkillHintButton = nil,
	playerSkillEnergyFrame = nil,
	playerSkillButton = nil
}
--]]
function PlayerObjectView:GetPlayerSkillButtonInfo(skillIndex)
	return self.playerSkillButtons[skillIndex]
end
function PlayerObjectView:SetPlayerSkillButtonInfo(skillIndex, buttonInfo)
	self.playerSkillButtons[skillIndex] = buttonInfo
end
--[[
根据技能id获取主角技按钮
@params skillId int 技能id
--]]
function PlayerObjectView:GetPlayerSkillButtonBySkillId(skillId)
	return self.playerSkillButtonsId[tostring(skillId)]
end
function PlayerObjectView:SetPlayerSkillButtonBySkillId(skillId, skillButton)
	self.playerSkillButtonsId[tostring(skillId)] = skillButton
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return PlayerObjectView
