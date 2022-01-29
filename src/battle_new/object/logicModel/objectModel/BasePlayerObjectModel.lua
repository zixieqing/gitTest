--[[
主角物体的基类
--]]
local BaseObjectModel = __Require('battle.object.logicModel.objectModel.BaseObjectModel')
local BasePlayerObjectModel = class('BasePlayerObjectModel', BaseObjectModel)

------------ import ------------
------------ import ------------

------------ define ------------
------------ define ------------

--[[
constructor
--]]
function BasePlayerObjectModel:ctor( ... )
	BaseObjectModel.ctor(self, ...)
end

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化
--]]
function BasePlayerObjectModel:Init()
	BaseObjectModel.Init(self)

	------------ 初始化物体监听事件 ------------
	self:RegisterObjectEventHandler()
	------------ 初始化物体监听事件 ------------
end
--[[
初始化特有属性
--]]
function BasePlayerObjectModel:InitUnitProperty()
	BaseObjectModel.InitUnitProperty(self)

	-- 展示层tag
	self.viewModelTag = nil

	if nil == self:GetPlayerSkills() then
		self:GetObjInfo().skillData = {
			activeSkill = {},
			passiveSkill = {}
		}
	end
end
--[[
@override
初始化展示层模型
--]]
function BasePlayerObjectModel:InitViewModel()
	local viewModelTag = G_BattleLogicMgr:GetBData():GetTagByTagType(BattleTags.BT_VIEW_MODEL)
	self:SetViewModelTag(viewModelTag)

	--***---------- 刷新渲染层 ----------***--
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'CreateAPlayerObjectView',
		self:GetViewModelTag(),
		self:GetPlayerSkills().activeSkill,
		self:GetOTag()
	)
	--***---------- 刷新渲染层 ----------***--
end
--[[
初始化驱动组件
--]]
function BasePlayerObjectModel:InitDrivers()
	-- 为主角模型创建一个施法驱动器
	self.castDriver = __Require('battle.objectDriver.castDriver.PlayerCastDriver').new({
		owner = self,
		skillIds = self:GetPlayerSkills()
	})
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- logic begin --
---------------------------------------------------
--[[
@override
主循环逻辑
--]]
function BasePlayerObjectModel:Update(dt)
	-- 暂停直接返回
	if self:IsPause() then return end

	-- 刷新一些计时器
	self:UpdateCountdown(dt)

	-- 刷新驱动器
	self:UpdateDrivers(dt)

	-- 刷新一次所有buff和光环
	self:UpdateBuffs(dt)
end
--[[
刷新一些计时器
--]]
function BasePlayerObjectModel:UpdateCountdown(dt)
	-- 刷新计时器
	for k,v in pairs(self.countdowns) do
		self.countdowns[k] = math.max(v - dt, 0)
	end

	------------ 检测计时器带来的变化 ------------
	if 0 >= self.countdowns.energy then
		-- 能量计时器 
		self.countdowns.energy = 1
		self:AddEnergy(self:GetEnergyRecoverRatePerS())
	end
	------------ 检测计时器带来的变化 ------------

	-- 刷新技能图标的cd百分比
	local cdPercent = nil
	for _, skillId in ipairs(self.castDriver.skills.active) do
		cdPercent = self.castDriver:GetCDPercentBySkillId(skillId)
		if nil ~= cdPercent then
			--***---------- 刷新渲染层 ----------***--
			G_BattleLogicMgr:AddRenderOperate(
				'G_BattleRenderMgr',
				'RefreshPlayerSkillCDPercent',
				self:GetViewModelTag(),
				skillId, cdPercent * 100
			)
			--***---------- 刷新渲染层 ----------***--
		end
	end
end
--[[
刷新驱动器
--]]
function BasePlayerObjectModel:UpdateDrivers(dt)
	-- 施法驱动器
	self.castDriver:UpdateActionTrigger(ActionTriggerType.CD, dt)
end
--[[
刷新一次所有buff和光环
--]]
function BasePlayerObjectModel:UpdateBuffs(dt)
	for i = #self.halos.idx, 1, -1 do
		self.halos.idx[i]:OnBuffUpdateEnter(dt)
	end

	for i = #self.buffs.idx, 1, -1 do
		self.buffs.idx[i]:OnBuffUpdateEnter(dt)
	end
end
---------------------------------------------------
-- logic end --
---------------------------------------------------

---------------------------------------------------
-- cast logic begin --
---------------------------------------------------
--[[
@override
被施法
@params buffInfo ObjectBuffConstructorStruct 构造buff的数据
@return _ bool 是否成功加上了该buff
--]]
function BasePlayerObjectModel:BeCasted(buffInfo)
	if BuffCauseEffectTime.INSTANT == buffInfo.causeEffectTime then

		-- 瞬时起效类型 不加入缓存
		local buff = __Require(buffInfo.className).new(buffInfo)
		buff:OnCauseEffectEnter()

	else

		-- 其他类型
		if buffInfo.isHalo then
			-- 光环逻辑
			local buff = self:GetHaloByBuffId(buffInfo:GetStructBuffId())

			if nil == buff then

				-- 未找到buff 创建一个buff
				buff = __Require(buffInfo.className).new(buffInfo)
				self:AddHalo(buff)

			else

				-- buff已经存在 刷新buff
				buff:OnRefreshBuffEnter(buffInfo)

			end

		else
			-- buff逻辑
			local buff = self:GetBuffByBuffId(buffInfo:GetStructBuffId())

			if nil == buff then

				buff = __Require(buffInfo.className).new(buffInfo)
				self:AddBuff(buff)

			else

				-- buff已经存在 刷新buff
				buff:OnRefreshBuffEnter(buffInfo)

			end

		end

	end

	return true
end
--[[
@override
刷一次物体的光环数据
--]]
function BasePlayerObjectModel:CastAllHalos()
	--[[
	new logic todo

	刷新光环时需要把老的光环buff数据移除
	--]]
	self.castDriver:CastAllHalos()
end
--[[
释放主角技
@params skillId
--]]
function BasePlayerObjectModel:CastPlayerSkill(skillId)
	if self.castDriver:HasSkillBySkillId(skillId) then
		if true == self.castDriver:CanDoAction(skillId) then
			self.castDriver:OnActionEnter(skillId)
		end
	end
end
---------------------------------------------------
-- cast logic end --
---------------------------------------------------

---------------------------------------------------
-- energy logic begin --
---------------------------------------------------
--[[
@override
增加能量
@params delta number 变化的能量
--]]
function BasePlayerObjectModel:AddEnergy(delta)
	BaseObjectModel.AddEnergy(self, delta)

	--***---------- 插入刷新渲染层计时器 ----------***--
	-- 刷新主角技能量
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'SetPlayerObjectViewEnergyPercent',
		self:GetViewModelTag(),
		self:GetEnergyPercent()
	)

	-- 刷新主角技按钮状态
	for _, skillId in ipairs(self.castDriver.skills.active) do
		G_BattleLogicMgr:AddRenderOperate(
			'G_BattleRenderMgr',
			'RefreshPlayerSkillState',
			self:GetViewModelTag(),
			skillId, self.castDriver:CanDoAction(skillId)
		)
	end
	--***---------- 插入刷新渲染层计时器 ----------***--
end
--[[
@override
获取能量秒回值
--]]
function BasePlayerObjectModel:GetEnergyRecoverRatePerS()
	return PLAYER_ENERGY_PER_S + self:GetEnergyRecoverRate()
end
---------------------------------------------------
-- energy logic end --
---------------------------------------------------

---------------------------------------------------
-- event handler begin --
---------------------------------------------------
--[[
注册物体监听事件
--]]
function BasePlayerObjectModel:RegisterObjectEventHandler()
	local eventHandlerInfo = {
		{member = 'objCastEventHandler_', 			eventType = ObjectEvent.OBJECT_CAST_ENTER, 	handler = handler(self, self.ObjectEventCastHandler)}
	}

	for _,v in ipairs(eventHandlerInfo) do
		if nil == self[v.member] then
			self[v.member] = v.handler
		end
		G_BattleLogicMgr:AddObjEvent(v.eventType, self, self[v.member])
	end
end
--[[
注销物体监听事件
--]]
function BasePlayerObjectModel:UnregistObjectEventHandler()
	local eventHandlerInfo = {
		{member = 'objCastEventHandler_', 			eventType = ObjectEvent.OBJECT_CAST_ENTER, 	handler = handler(self, self.ObjectEventCastHandler)}
	}

	for _,v in ipairs(eventHandlerInfo) do
		G_BattleLogicMgr:RemoveObjEvent(v.eventType, self)
	end
end
--[[
施法事件监听
@params ... 
	args table passed args
--]]
function BasePlayerObjectModel:ObjectEventCastHandler( ... )
	-- 友方卡牌释放技能时增加主角技能量
	local args = unpack({...})
	local bet = G_BattleLogicMgr:GetBattleElementTypeByTag(args.tag)
	local skillId = args.skillId

	if BattleElementType.BET_CARD == bet and self:IsEnemy(true) == args.isEnemy then
		local skillConfig = CommonUtils.GetSkillConf(skillId)
		if nil ~= skillConfig then
			if ConfigSkillType.SKILL_NORMAL == checkint(skillConfig.property) then
				self:AddEnergy(PLAYER_ENERGY_BY_NORMAL_SKILL)
			else
				self:AddEnergy(PLAYER_ENERGY_BY_CI_SKILL)
			end
		end
	end
end
---------------------------------------------------
-- event handler end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
获取技能信息
@return map {
	activeSkill list 主动技能的技能id
	passiveSkill list 被动技能的技能id
}
--]]
function BasePlayerObjectModel:GetPlayerSkills()
	return self:GetObjInfo().skillData
end
--[[
设置展示层tag
@params viewModelTag int 展示层tag
--]]
function BasePlayerObjectModel:SetViewModelTag(viewModelTag)
	self.viewModelTag = viewModelTag
end
--[[
@override
获取展示层tag
--]]
function BasePlayerObjectModel:GetViewModelTag()
	return self.viewModelTag
end
---------------------------------------------------
-- get set end --
---------------------------------------------------














return BasePlayerObjectModel
