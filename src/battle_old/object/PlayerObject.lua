--[[
主角模型
@params table {
	tag int obj tag
	oname string obj name
	battleElementType BattleElementType 战斗物体大类型 
	objInfo ObjectConstructorStruct 战斗物体构造函数
}
--]]
local BaseObject = __Require('battle.object.BaseObject')
local PlayerObject = class('PlayerObject', BaseObject)

------------ import ------------
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
------------ import ------------

--[[
@override
constructor
--]]
function PlayerObject:ctor( ... )
	local args = unpack({...})

	------------ 初始化id信息 ------------
	self.idInfo = {
		tag = args.tag,
		oname = args.oname,
		battleElementType = args.battleElementType
	}
	------------ 初始化id信息 ------------

	------------ 初始化卡牌基本信息 ------------
	self.objInfo = args.objInfo
	------------ 初始化卡牌基本信息 ------------

	------------ 初始化ui信息 ------------
	self.view = {
		viewComponent = nil,
		avatar = nil,
		animationsData = nil,
		hpBar = nil,
		energyBar = nil,
		skillButtons = nil
	}
	------------ 初始化ui信息 ------------

	self:init()
	self:registerObjEventHandler()
end
---------------------------------------------------
-- init logic begin --
---------------------------------------------------
--[[
@override
初始化逻辑
--]]
function PlayerObject:init()
	self:initValue()
	self:initView()
	self:initDrivers()
end
--[[
@override
初始化个体属性
--]]
function PlayerObject:initUnitProperty()
	------------ location info ------------
	self.location = ObjectLocation.New(
		self.objInfo.oriLocation.po.x,
		self.objInfo.oriLocation.po.y,
		self.objInfo.oriLocation.po.r,
		self.objInfo.oriLocation.po.c
	)
	------------ location info ------------

	------------ energy info ------------
	self.energy = RBQN.New(0)
	self.energyRecoverRate = RBQN.New(0)
	------------ energy info ------------

	------------ view info ------------
	self.drawPathInfo = nil
	------------ view info ------------

	------------ other info ------------
	-- 仇恨
	self.hate = 0
	------------ other info ------------
end
--[[
@override
初始化外貌
--]]
function PlayerObject:initView()

	local function CreateView()
		-- 初始化主角ui
		BMediator:GetViewComponent():InitPlayerView()

		local skillButtons = {}
		local skillConf = nil

		if table.nums(self.objInfo.skillData.activeSkill) > 0 then
			for i, v in ipairs(self.objInfo.skillData.activeSkill) do
				skillConf = CommonUtils.GetSkillConf(checkint(v.skillId))
				local playerSkillButton = BMediator:GetViewComponent():AddPlayerSkillButton(v.skillId, {
					index = i,
					callback = handler(self, self.playerSkillButtonClickHandler),
					energyCost = checknumber(skillConf.triggerType[tostring(ConfigSkillTriggerType.ENERGY)])
				})
				playerSkillButton:setTag(checkint(v.skillId))
				skillButtons[tostring(v.skillId)] = playerSkillButton
			end
		else
			-- 没带主角技 弹提示
			local unlockLevel = CommonUtils.GetConfigAllMess('module')[tostring(MODULE_DATA[tostring(RemindTag.TALENT)])].openLevel
			local playerSkillDescr = string.format(__('%d级解锁料理天赋，需要手动装备。'), checkint(unlockLevel))
			for i,v in ipairs(BMediator:GetViewComponent().viewData.playerSkillHintBtns) do
				v:setVisible(true)
				display.commonUIParams(v, {animate = false, cb = function (sender)
					uiMgr:ShowInformationTipsBoard({targetNode = sender, title = __('料理天赋'), descr = playerSkillDescr, type = 5})
				end})
			end
		end

		return {
			skillButtons = skillButtons
		}
	end

	xTry(function ()
		local viewData = CreateView()
		self.view.skillButtons = viewData.skillButtons
	end, __G__TRACKBACK__)

end
--[[
@override
初始化行为驱动器
--]]
function PlayerObject:initDrivers()
	-- 为主角创建一个施法驱动
	self.castDriver = __Require('battle.objectDriver.PlayerCastDriver').new({
		owner = self,
		skillIds = self.objInfo.skillData
	})
end
--[[
@override
注册战斗物体之间通信的回调函数
--]]
function PlayerObject:registerObjEventHandler()
	if nil == self.objCastEventHandler_ then
		self.objCastEventHandler_ = handler(self, self.objCastEventHandler)
	end
	BMediator:AddObjEvent(ObjectEvent.OBJECT_CAST_ENTER, self, self.objCastEventHandler_)
end
--[[
@override
销毁战斗物体之间通信的回调函数
--]]
function PlayerObject:unregisterObjEventHandler()
	BMediator:RemoveObjEvent(ObjectEvent.OBJECT_CAST_ENTER, self)
end
---------------------------------------------------
-- init logic end --
---------------------------------------------------

---------------------------------------------------
-- logic begin --
---------------------------------------------------
--[[
@override
被施法
@params buffInfo table buff信息
@return _ bool 是否成功加上了该buff
--]]
function PlayerObject:beCasted(buffInfo)
	if BuffCauseEffectTime.INSTANT == buffInfo.causeEffectTime then
		local buff = __Require(buffInfo.className).new(buffInfo)
		buff:OnCauseEffectEnter()
	else

		-- 需要加入buff缓存中的buff
		if buffInfo.isHalo then
			local buff = self:getHaloByBuffId(buffInfo.bid)
			if nil == buff then
				buff = __Require(buffInfo.className).new(buffInfo)
				self:addHalo(buff)
			else
				buff:OnRefreshBuffEnter(buffInfo)
			end
		else
			local buff = self:getBuffByBuffId(buffInfo.bid)
			if nil == buff then
				buff = __Require(buffInfo.className).new(buffInfo)
				self:addBuff(buff)
			else
				buff:OnRefreshBuffEnter(buffInfo)
			end
		end

	end
	return true
end
--[[
@override
施放所有光环
--]]
function PlayerObject:castAllHalos()
	self.castDriver:CastAllHalos()
end
--[[
@override
物体施法回调
@params ...
	args table passed args
--]]
function PlayerObject:objCastEventHandler(...)
	local args = unpack({...})
	
	-- 友方卡牌释放技能时增加主角技能量 小技能+2其他技能+5
	if self:isEnemy() == args.isEnemy and
		BattleElementType.BET_CARD == BMediator:GetBattleElementTypeByTag(args.tag) then

		local skillConf = CommonUtils.GetSkillConf(args.skillId)
		if nil ~= skillConf then
			if ConfigSkillType.SKILL_NORMAL == checkint(skillConf.property) then
				self:addEnergy(PLAYER_ENERGY_BY_NORMAL_SKILL)
			elseif ConfigSkillType.SKILL_CONNECT == checkint(skillConf.property) then
				self:addEnergy(PLAYER_ENERGY_BY_CI_SKILL)
			end
		end

	end
end
---------------------------------------------------
-- logic end --
---------------------------------------------------

---------------------------------------------------
-- action logic end --
---------------------------------------------------
--[[
@override
销毁 不可逆！
--]]
function PlayerObject:destroy()
	self.view.skillButtons = {}
end
---------------------------------------------------
-- action logic end --
---------------------------------------------------

---------------------------------------------------
-- update begin --
---------------------------------------------------
--[[
@override
主循环
--]]
function PlayerObject:update(dt)
	if self:isPause() then return end

	-- 自动回能量
	self.countdowns.energy = math.max(0, self.countdowns.energy - dt)
	if 0 >= self.countdowns.energy then
		self.countdowns.energy = 1
		self:addEnergy(self:getEnergyRecoverRatePerS())
	end

	-- 刷新技能触发器
	self.castDriver:UpdateActionTrigger(ActionTriggerType.CD, dt)

	-- 刷新技能按钮的时间
	local cdPercent = nil
	for k,v in pairs(self.view.skillButtons) do
		cdPercent = self.castDriver:GetCDPercentBySkillId(checkint(k))
		if nil ~= cdPercent then
			v:RefreshButtonCountdownPercent(cdPercent * 100)
		end
	end

	------------ skill effect ------------
	for i = #self.halos.idx, 1, -1 do
		self.halos.idx[i]:OnBuffUpdateEnter(dt)
	end
	for i = #self.buffs.idx, 1, -1 do
		self.buffs.idx[i]:OnBuffUpdateEnter(dt)
	end
	------------ skill effect ------------

end
---------------------------------------------------
-- update end --
---------------------------------------------------

---------------------------------------------------
-- view control begin --
---------------------------------------------------
--[[
@override
刷新能量条
@params all bool(nil) true时更新最大能量
--]]
function PlayerObject:updateEnergyBar(all)
	BMediator:GetViewComponent().viewData.energyLabel:setString(math.ceil(self:getEnergy():ObtainVal()))
	BMediator:GetViewComponent().viewData.playerEnergyBar:setValue(math.ceil(self:getEnergy():ObtainVal()))
	BMediator:GetViewComponent().viewData.playerEnergyBarLight:setVisible(self:getEnergy():ObtainVal() >= MAX_ENERGY)
	self:refreshSkillButtonsState()
end
--[[
主角技按钮回调
--]]
function PlayerObject:playerSkillButtonClickHandler(sender)
	-- 判断是否可以触摸
	if not BMediator:IsBattleTouchEnable() then return end

	PlayUIEffects(AUDIOS.UI.ui_click_normal.id)
	local skillId = sender:getTag()
	if true == self.castDriver:CanDoAction(skillId) then
		self.castDriver:OnActionEnter(skillId)
	end
end
--[[
刷新所有按钮状态
--]]
function PlayerObject:refreshSkillButtonsState()
	for i,v in ipairs(self.objInfo.skillData.activeSkill) do
		self.view.skillButtons[tostring(v.skillId)]:RefreshButtonState(self.castDriver:CanDoAction(v.skillId))
	end
end
---------------------------------------------------
-- view control end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
@override
获取是否是敌人
@params o bool 是否是原始敌友性
--]]
function PlayerObject:isEnemy(o)
	return self.objInfo.isEnemy
end
--[[
@override
能量增加
--]]
function PlayerObject:addEnergy(delta)
	if not delta then return end
	BaseObject.addEnergy(self, delta)
	self:updateEnergyBar()
end
--[[
@override
获取能量秒回 能量秒回
--]]
function PlayerObject:getEnergyRecoverRatePerS()
	return PLAYER_ENERGY_PER_S + self:getEnergyRecoverRate()
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return PlayerObject
