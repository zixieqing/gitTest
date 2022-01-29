--[[
主角技按钮
@params {
	skillId int 技能id
}
--]]
local PlayerSkillButton = class('PlayerSkillButton', function ()
	local node = CButton:create()
	node.name = 'battle.view.PlayerSkillButton'
	node:enableNodeEvents()
	print('PlayerSkillButton', ID(node))
	return node
end)
--[[
constructor
--]]
function PlayerSkillButton:ctor( ... )
	self.args = unpack({...})
	self.isBtnEnabled = false

	self:InitUI()
end
--[[
初始化ui
--]]
function PlayerSkillButton:InitUI()

	local function CreateView()

		local skillConf = CommonUtils.GetConfig('player', 'skill', checkint(self.args.skillId))

		local cover = display.newNSprite(_res('ui/battle/team_lead_skill_frame_l.png'), 0, 0)
		local size = cover:getContentSize()
		self:setContentSize(size)
		display.commonUIParams(cover, {po = cc.p(size.width * 0.5, size.height * 0.5)})
		self:addChild(cover, 10)

		local skillIcon = display.newNSprite(_res(CommonUtils.GetSkillIconPath(self.args.skillId)), size.width * 0.5, size.height * 0.5)
		skillIcon:setScale((size.width - 15) / skillIcon:getContentSize().width)
		self:addChild(skillIcon, 4)

		local disableCover = display.newNSprite(_res('ui/battle/team_lead_skill_frame_disable.png'), size.width * 0.5, size.height * 0.5)
		self:addChild(disableCover, 5)
		disableCover:setVisible(false)

		local shine = display.newNSprite(_res('ui/battle/battle_skill_light.png'), size.width * 0.5, size.height * 0.5)
		self:addChild(shine, 1)
		shine:setVisible(false)

		local opacityShine = display.newNSprite(_res('ui/battle/light.png'), size.width * 0.5, size.height * 0.5)
		self:addChild(opacityShine, 11)
		opacityShine:setVisible(false)

		local passiveRotateShine = display.newNSprite(_res('ui/battle/light_2.png'), size.width * 0.5, size.height * 0.5)
		self:addChild(passiveRotateShine, 12)
		passiveRotateShine:setVisible(false)

		local cdProgressBar = nil
		if ConfigSkillType.SKILL_HALO ~= skillConf.property then
			for k,v in pairs(skillConf.triggerType) do
				if 5 == checkint(k) then
					-- 能量消耗
					local costEnergyBg = display.newNSprite(_res('ui/battle/battle_energy_number_bg.png'), size.width * 0.5, 25)
					self:addChild(costEnergyBg, 9)

					local costEnergyIcon = display.newNSprite(_res('ui/battle/battle_ico_energy_s.png'), 0, 0)
					self:addChild(costEnergyIcon, 9)
					local costEnergyLabel = display.newLabel(0, 0,
						fontWithColor(9,{text = tonumber(v)}))
					self:addChild(costEnergyLabel, 9)
					display.setNodesToNodeOnCenter(costEnergyBg, {costEnergyIcon, costEnergyLabel})
				elseif 4 == checkint(k) then
					-- cd
					cdProgressBar = cc.ProgressTimer:create(cc.Sprite:create(_res('ui/battle/team_lead_skill_frame_disable.png')))
					cdProgressBar:setScaleX(-1)
					cdProgressBar:setType(cc.PROGRESS_TIMER_TYPE_RADIAL)
					cdProgressBar:setPercentage(100)
					cdProgressBar:setPosition(cc.p(size.width * 0.5, size.height * 0.5))
					self:addChild(cdProgressBar, 5)
				end
			end
		end

		return {
			disableCover = disableCover,
			shine = shine,
			opacityShine = opacityShine,
			passiveRotateShine = passiveRotateShine,
			cdProgressBar = cdProgressBar
		}

	end

	xTry(function ( )
		self.viewData = CreateView( )
	end, __G__TRACKBACK__)

	self:InitButtonState()
	self:setEnabled(false)
end
--[[
初始化主角技按钮状态
--]]
function PlayerSkillButton:InitButtonState()
	local skillConf = CommonUtils.GetConfig('player', 'skill', checkint(self.args.skillId))
	if ConfigSkillType.SKILL_HALO == skillConf.property then
		-- 被动技能
		local actionSeq = cc.RepeatForever:create(cc.RotateBy:create(0.1, 15))
		self.viewData.passiveRotateShine:runAction(actionSeq)
	else
		-- 主动技能
		self.viewData.disableCover:setVisible(true)
	end
end
--[[
刷新按钮状态
@params canCast bool 是否可以释放
--]]
function PlayerSkillButton:RefreshButtonState(canCast)
	if canCast and not self.isBtnEnabled then
		-- 按钮可用
		self:setEnabled(true)
		self.isBtnEnabled = true
		self.viewData.disableCover:setVisible(false)

		-- 激活动画
		self.viewData.opacityShine:setVisible(true)
		self.viewData.opacityShine:setScale(1)
		self.viewData.opacityShine:setOpacity(0)
		local opacityShineActionSeq = cc.Sequence:create(
			cc.Spawn:create(
				cc.ScaleTo:create(0.4, 1.25),
				cc.FadeTo:create(0.2, 255)
			),
			cc.Spawn:create(
				cc.ScaleTo:create(0.4, 1),
				cc.Sequence:create(
					cc.DelayTime:create(0.2),
					cc.FadeTo:create(0.2, 0)
				)
			)
		)
		self.viewData.opacityShine:runAction(opacityShineActionSeq)

		self.viewData.shine:setVisible(true)
		self.viewData.shine:setOpacity(0)
		local shineActionSeq = cc.Sequence:create(
			cc.DelayTime:create(1),
			cc.FadeTo:create(0.25, 255)
		)
		self.viewData.shine:runAction(shineActionSeq)
	elseif not canCast and self.isBtnEnabled then
		-- 按钮不可用
		self:setEnabled(false)
		self.isBtnEnabled = false
		self.viewData.disableCover:setVisible(true)
		self.viewData.opacityShine:setVisible(false)
		self.viewData.opacityShine:stopAllActions()
		self.viewData.shine:setVisible(false)
		self.viewData.shine:stopAllActions()
	end
end
function PlayerSkillButton:RefreshButtonCountdownPercent(percentage)
	if self.viewData.cdProgressBar then
		self.viewData.cdProgressBar:setPercentage(percentage)
	end
end

return PlayerSkillButton
