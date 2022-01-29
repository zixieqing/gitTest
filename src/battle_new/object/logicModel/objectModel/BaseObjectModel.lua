--[[
战斗物体的基类
--]]
local BaseLogicModel = __Require('battle.object.logicModel.BaseLogicModel')
local BaseObjectModel = class('BaseObjectModel', BaseLogicModel)

------------ import ------------
------------ import ------------

------------ define ------------
------------ define ------------

--[[
constructor
--]]
function BaseObjectModel:ctor( ... )
	BaseLogicModel.ctor(self, ...)
end

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化
--]]
function BaseObjectModel:Init()
	BaseLogicModel.Init(self)

	------------ 初始化展示层模型 ------------
	self:InitViewModel()
	------------ 初始化展示层模型 ------------

	------------ 初始化驱动组件 ------------
	self:InitDrivers()
	------------ 初始化驱动组件 ------------

	------------ 初始化技能免疫 ------------
	self:InitInnerBuffImmune()
	------------ 初始化技能免疫 ------------

	------------ 初始化天气免疫 ------------
	self:InitWeatherImmune()
	------------ 初始化天气免疫 ------------
end
--[[
初始化数值
--]]
function BaseObjectModel:InitValue()
	BaseLogicModel.InitValue(self)
end
--[[
初始化固有属性
--]]
function BaseObjectModel:InitInnateProperty()
	BaseLogicModel.InitInnateProperty(self)

	------------ state info ------------
	-- 普通状态
	self.state = {
		cur = OState.SLEEP,
		pre = OState.SLEEP,
		pause = false,
		towards = BattleObjTowards.FORWARD
	}
	------------ state info ------------

	------------ immune info ------------
	self.extraStateInfo = __Require('battle.object.organ.BaseObjectState').new()
	------------ immune info ------------

	------------ buff info ------------
	-- buff缓存
	--[[--
	skillCounter 保存obj身上的buff技能来源 键值对 key为技能id value为buff剩余数
	idx 按倒序插入buff
	id 根据id保存buff
	--]]--
	self.buffs = {skillCounter = {}, idx = {}, id = {}}
	-- 光环缓存
	self.halos = {idx = {}, id = {}}
	-- 护盾缓存
	self.shield = {}
	-- qtebuff缓存
	self.qteBuffs = {idx = {}, id = {}}
	-- 时间传染驱动器
	-- self.timeInfectDrivers = {idx = {}, id = {}}
	------------ buff info ------------

	------------ temp info ------------
	-- 当前施法技能id
	self.castingSkillId = nil
	-- ciScene
	self.ciScene = nil
	-- 是否高亮中
	self.isInHighlight = false
	-- 物体出现的波数
	self.wave = ValueConstants.V_NONE
	-- 物体的队伍序号
	self.teamIndex = ValueConstants.V_NONE
	------------ temp info ------------

	------------ 监听事件指针 ------------
	self.objDieEventHandler_ = nil
	self.objReviveEventHandler_ = nil
	self.objCastEventHandler_ = nil
	self.objLuckEventHandler_ = nil
	------------ 监听事件指针 ------------

	------------ countdown info ------------
	self.countdowns = {
		energy = 1
	}
	------------ countdown info ------------

	------------ 物体的成套行为动画配置信息 ------------
	self:InitActionAnimationConfig()
	------------ 物体的成套行为动画配置信息 ------------
end
--[[
初始化特有属性
--]]
function BaseObjectModel:InitUnitProperty()
	------------ location info ------------
	self.location = ObjectLocation.New(0, 0, 0, 0)
	self.zorderInBattle = 0
	------------ location info ------------

	------------ energy info ------------
	self:InitEnergy()
	------------ energy info ------------

	------------ other info ------------
	-- 仇恨
	self.hate = 0
	------------ other info ------------
end
--[[
初始化物体的动作动画信息
--]]
function BaseObjectModel:InitActionAnimationConfig()
	self.actionAnimationConfig = {}
end
--[[
@override
初始化展示层模型
--]]
function BaseObjectModel:InitViewModel()
	
end
--[[
初始化驱动组件
--]]
function BaseObjectModel:InitDrivers()
	------------ drivers ------------
	-- 随机数驱动器
	self.randomDriver = nil
	-- 移动驱动器
	self.moveDriver = nil
	-- 攻击驱动器
	self.attackDriver = nil
	-- 施法驱动器
	self.castDriver = nil
	-- 阶段转换驱动器
	self.phaseDriver = nil
	-- 变色驱动器
	self.tintDriver = nil
	-- 触发驱动器
	self.triggerDriver = nil
	-- 神器天赋驱动器
	self.artifactTalentDriver = nil
	------------ drivers ------------
end
--[[
激活一次驱动器
--]]
function BaseObjectModel:ActivateDrivers()

end
--[[
初始化技能免疫
--]]
function BaseObjectModel:InitInnerBuffImmune()

end
--[[
初始化天气免疫
--]]
function BaseObjectModel:InitWeatherImmune()
	
end
--[[
初始化能量
--]]
function BaseObjectModel:InitEnergy()
	self.energy = 0
	self.energyRecoverRate = 0
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- state logic begin --
---------------------------------------------------
--[[
是否可以行动
--]]
function BaseObjectModel:CanAct()
	return self:GetObjectExtraStateInfo():CanAct()
end
--[[
唤醒物体
--]]
function BaseObjectModel:AwakeObject()
	self:SetState(OState.NORMAL)
end
--[[
沉睡物体
--]]
function BaseObjectModel:SleepObject()
	self:SetState(OState.SLEEP)
end
--[[
使物体处于异常状态
@params abnormalState AbnormalState 异常状态
@params b bool 是否设置成异常状态
--]]
function BaseObjectModel:SetObjectAbnormalState(abnormalState, b)
	self:GetObjectExtraStateInfo():SetAbnormalState(abnormalState, b)
end
--[[
物体是否处于异常状态
@params abnormalState AbnormalState 异常状态
@return _ bool 是否处于异常状态
--]]
function BaseObjectModel:InAbnormalState(abnormalState)
	return self:GetObjectExtraStateInfo():GetAbnormalState(abnormalState)
end
--[[
设置物体异常状态免疫
@params abnormalState AbnormalState 异常状态
@params b bool 是否免疫
--]]
function BaseObjectModel:SetObjectAbnormalStateImmune(abnormalState, b)
	self:GetObjectExtraStateInfo():SetAbnormalImmune(abnormalState, b)
end
--[[
获取物体异常状态是否免疫
@params abnormalState AbnormalState 异常状态
@return _ bool 是否免疫
--]]
function BaseObjectModel:GetObjectAbnormalStateImmune(abnormalState)
	return self:GetObjectExtraStateInfo():GetAbnormalImmune(abnormalState)
end
--[[
根据buff类型判断是否免疫该buff对应的异常状态
@params buffType ConfigBuffType
@return _ bool 是否免疫
--]]
function BaseObjectModel:ImmuneAbnormalStateByBuffType(buffType)
	return self:GetObjectExtraStateInfo():ImmuneAbnormalStateByBuffType(buffType)
end
--[[
设置全异常状态免疫
-- /***********************************************************************************************************************************\
--  * 该方法只用于处理一些非正常战斗逻辑
-- \***********************************************************************************************************************************/
@params immune bool 是否免疫
--]]
function BaseObjectModel:SetAllImmune(immune)
	self:SetObjectDamageSwitch(immune)
	self:SetObjectAbnormalStateImmune(AbnormalState.SILENT, immune)
	self:SetObjectAbnormalStateImmune(AbnormalState.STUN, immune)
	self:SetObjectAbnormalStateImmune(AbnormalState.FREEZE, immune)
	self:SetObjectAbnormalStateImmune(AbnormalState.ENCHANTING, immune)
end
--[[
获取物体天气免疫
@params weatherId int 天气id
@return _ bool 是否免疫
--]]
function BaseObjectModel:GetObjectWeatherImmune(weatherId)
	return self:GetObjectExtraStateInfo():GetWeatherImmuneByWeatherId(weatherId)
end
--[[
获取物体内置buff免疫
@params buffType ConfigBuffType buff类型
@return _ bool 是否免疫
--]]
function BaseObjectModel:GetObjectInnerBuffImmune(buffType)
	return self:GetObjectExtraStateInfo():GetInnerBuffImmuneByBuffType(buffType)
end
--[[
获取物体buff免疫
@params buffType ConfigBuffType buff类型
@return _ bool 是否免疫
--]]
function BaseObjectModel:GetObjectBuffImmune(buffType)
	return self:GetObjectExtraStateInfo():GetBuffImmuneByBuffType(buffType)
end
--[[
设置物体buff免疫
@params buffType ConfigBuffType buff类型
@params skillId int 技能id
@params immune bool 是否免疫
--]]
function BaseObjectModel:SetObjectBuffImmune(buffType, skillId, immune)
	self:GetObjectExtraStateInfo():SetBuffImmuneByBuffType(buffType, skillId, immune)
end
--[[
根据buff类型判断物体是否免疫该类型buff
@params buffType ConfigBuffType buff类型
@return _ bool 是否免疫
--]]
function BaseObjectModel:IsObjectImmuneBuff(buffType)
	return self:GetObjectInnerBuffImmune(buffType) or self:GetObjectBuffImmune(buffType)
end
--[[
根据伤害类型判断是否免疫伤害
@params damageType DamageType 伤害类型
@return _ bool 是否免疫伤害
--]]
function BaseObjectModel:DamageImmuneByDamageType(damageType)
	local result = self:GetObjectExtraStateInfo():GetDamageImmune(damageType) or
		self:GetObjectExtraStateInfo():GetDamageImmune(DamageType.PHYSICAL) or
		self:GetObjectExtraStateInfo():GetGlobalDamageImmune(damageType) or
		self:GetObjectExtraStateInfo():GetGlobalDamageImmune(DamageType.PHYSICAL) or
		self:GetObjectDamageSwitch()

	return result
end
--[[
根据伤害类型设置伤害免疫
@params damageType DamageType 伤害类型
@params immune bool 是否免疫
--]]
function BaseObjectModel:SetDamageImmuneByDamageType(damageType, immune)
	self:GetObjectExtraStateInfo():SetDamageImmune(damageType, immune)
end
--[[
设置物体伤害免疫总开关
@params b bool 伤害免疫
--]]
function BaseObjectModel:SetObjectDamageSwitch(b)
	self:GetObjectExtraStateInfo():SetDamageSwitch(b)
end
--[[
获取物体伤害免疫总开关
@return _ bool 
--]]
function BaseObjectModel:GetObjectDamageSwitch()
	return self:GetObjectExtraStateInfo():GetDamageSwitch()
end
--[[
@override
是否被暂停
@return _ bool
--]]
function BaseObjectModel:IsPause()
	return self.state.pause
end
--[[
@override
暂停
--]]
function BaseObjectModel:PauseLogic()
	self.state.pause = true
end
--[[
@override
恢复物体
--]]
function BaseObjectModel:ResumeLogic()
	self.state.pause = false
end
--[[
@override
内部判断物体是否还存活
@return _ bool 是否存活
--]]
function BaseObjectModel:IsAlive()
	return true
end
--[[
判断物体是否满足死亡条件
@return _ bool 死亡
--]]
function BaseObjectModel:CanDie()
	return not self:InAbnormalState(AbnormalState.UNDEAD)
end
--[[
设置不可被索敌
@params canBeSearched bool 
--]]
function BaseObjectModel:SetCanBeSearched(canBeSearched)
	self:SetObjectAbnormalState(AbnormalState.LUCK, not canBeSearched)
end
--[[
获取是否可以被索敌
@return _ bool 是否可以被索敌
--]]
function BaseObjectModel:CanBeSearched()
	return not self:InAbnormalState(AbnormalState.LUCK)
end
---------------------------------------------------
-- state logic end --
---------------------------------------------------

---------------------------------------------------
-- logic begin --
---------------------------------------------------
--[[
@override
主循环逻辑
--]]
function BaseObjectModel:Update(dt)
	-- 暂停直接返回
	if self:IsPause() then return end
end
---------------------------------------------------
-- logic end --
---------------------------------------------------

---------------------------------------------------
-- attack logic begin --
---------------------------------------------------
--[[
索敌
--]]
function BaseObjectModel:SeekAttakTarget()
	
end
--[[
失去攻击目标
--]]
function BaseObjectModel:LostAttackTarget()

end
--[[
获取平a的射程
@return _ int 单位列
--]]
function BaseObjectModel:GetAttackRange()
	return 0
end
--[[
攻击
@params targetTag int 攻击对象tag
--]]
function BaseObjectModel:Attack(targetTag)

end
--[[
获取移动速度
@return _ number 像素
--]]
function BaseObjectModel:GetMoveSpeed()
	return 0
end
--[[
被攻击
@params damageData ObjectDamageStruct
@params noTrigger bool 不触发任何触发器
--]]
function BaseObjectModel:BeAttacked(damageData, noTrigger)

end
--[[
生命值变化
@params damageData ObjectDamageStruct
--]]
function BaseObjectModel:HpChange(damageData)

end
--[[
强制变化生命值百分比 不触发触发器
@params percent number 百分比
--]]
function BaseObjectModel:HpPercentChangeForce(percent)

end
--[[
被治疗
@params healData ObjectDamageStruct 治疗信息
@params noTrigger bool 不触发任何触发器
--]]
function BaseObjectModel:BeHealed(healData, noTrigger)
	
end
--[[
仇恨值
--]]
function BaseObjectModel:GetHate()
	return self.hate
end
function BaseObjectModel:SetHate(hate)
	self.hate = hate
end
--[[
春哥一下
@params minHp number 最小血量
--]]
function BaseObjectModel:ForceUndeadOnce(minHp)

end
--[[
修正由攻速变化产生的动画缩放
--]]
function BaseObjectModel:FixAnimationScaleByATKRate()
	
end
---------------------------------------------------
-- attack logic end --
---------------------------------------------------

---------------------------------------------------
-- cast logic begin --
---------------------------------------------------
--[[
根据技能id释放一个技能
@params skillId int 技能id
--]]
function BaseObjectModel:Cast(skillId)

end
--[[
被施法
@params buffInfo ObjectBuffConstructorStruct 构造buff的数据
@return _ bool 是否成功加上了该buff
--]]
function BaseObjectModel:BeCasted(buffInfo)
	return false
end
--[[
刷一次物体的光环数据
--]]
function BaseObjectModel:CastAllHalos()

end
--[[
根据状态判断是否可以释放连携技
@return _ bool 
--]]
function BaseObjectModel:CanCastConnectByAbnormalState()
	return false
end
--[[
判断是否可以释放触发buff
@params skillId int 技能id
@params buffType ConfigBuffType buff类型
@params triggerActionType ConfigObjectTriggerActionType 物体行为触发类型
--]]
function BaseObjectModel:CanTriggerBuff(skillId, buffType, triggerActionType)
	return true
end
--[[
消耗一些触发的buff的资源
@params skillId int 技能id
@params buffType ConfigBuffType buff类型
@params triggerActionType ConfigObjectTriggerActionType 物体行为触发类型
@params countdown number 触发的cd
--]]
function BaseObjectModel:CostTriggerBuffResources(skillId, buffType, triggerActionType, cd)
	
end
---------------------------------------------------
-- cast logic end --
---------------------------------------------------

---------------------------------------------------
-- move logic begin --
---------------------------------------------------
--[[
移动
--]]
function BaseObjectModel:Move(dt, targetTag)
	
end
--[[
强制移动 从一个点移动到另一个点 期间不处理战斗逻辑
@params targetPos cc.p
@params moveActionName string 移动的动作名
@params moveOverCallback function 移动完成后的回调函数
--]]
function BaseObjectModel:ForceMove(targetPos, moveActionName, moveOverCallback)

end
---------------------------------------------------
-- move logic end --
---------------------------------------------------

---------------------------------------------------
-- buff logic begin --
---------------------------------------------------
--[[
对物体添加一个buff
@params buff BaseBuff buff
--]]
function BaseObjectModel:AddBuff(buff)
	local buffId = buff:GetBuffId()
	local skillId = buff:GetSkillId()
	local buffType = buff:GetBuffType()

	------------ 通用数据处理 ------------
	-- buff缓存
	self.buffs.id[tostring(buffId)] = buff
	table.insert(self.buffs.idx, 1, buff)

	-- 技能计数器
	if nil == self.buffs.skillCounter[tostring(skillId)] then
		self.buffs.skillCounter[tostring(skillId)] = 0
	end
	self.buffs.skillCounter[tostring(skillId)] = self.buffs.skillCounter[tostring(skillId)] + 1
	------------ 通用数据处理 ------------

	------------ 特殊类型处理 ------------
	if ConfigBuffType.SHIELD == buffType then
		-- 护盾缓存
		table.insert(self.shield, 1, buff)
	end
	------------ 特殊类型处理 ------------

	------------ buff生效 ------------
	if BuffCauseEffectTime.ADD2OBJ == buff:GetCauseEffectTime() then
		buff:OnCauseEffectEnter()
	end
	------------ buff生效 ------------
end
--[[
移除物体身上的一个buff
@params buff BaseBuff buff
--]]
function BaseObjectModel:RemoveBuff(buff)
	local buffId = buff:GetBuffId()
	local skillId = buff:GetSkillId()
	local buffType = buff:GetBuffType()

	------------ 通用数据结构处理 ------------
	-- buff数据缓存
	self.buffs.id[tostring(buffId)] = nil
	for i = #self.buffs.idx, 1, -1 do
		if buffId == self.buffs.idx[i]:GetBuffId() then
			table.remove(self.buffs.idx, i)
			break
		end
	end

	-- 技能计数器
	if nil ~= self.buffs.skillCounter[tostring(skillId)] then
		self.buffs.skillCounter[tostring(skillId)] = self.buffs.skillCounter[tostring(skillId)] - 1
		if 0 == self.buffs.skillCounter[tostring(skillId)] then
			self.buffs.skillCounter[tostring(skillId)] = nil

			-- 整个技能效果被移除时 清掉传染驱动
			self:RemoveInfecInfo(skillId)
		end
	else
		BattleUtils.PrintBattleWaringLog('here remove a buff and decrease skill counter but can not find skill counter -> ' .. tostring(skillId) .. ', ' .. tostring(buffType))
	end
	------------ 通用数据结构处理 ------------

	------------ 特殊类型处理 ------------
	if ConfigBuffType.SHIELD == buffType then
		-- 移除护盾缓存
		for i = #self.shield, 1, -1 do
			if buffId == self.shield[i]:GetBuffId() then
				table.remove(self.shield, i)
				break
			end
		end
	end
	------------ 特殊类型处理 ------------
end
--[[
清除全部buff
--]]
function BaseObjectModel:ClearBuff()
	for i = #self.buffs.idx, 1, -1 do
		local buff = self.buffs.idx[i]
		self.buffs.id[tostring(buff:GetBuffId())] = nil
		buff:OnRecoverEffectEnter()
	end
end
--[[
添加一个光环
@params buff BaseBuff buff
--]]
function BaseObjectModel:AddHalo(buff)
	local buffId = buff:GetBuffId()
	local skillId = buff:GetSkillId()
	local buffType = buff:GetBuffType()

	------------ 通用数据结构处理 ------------
	-- buff缓存
	self.halos.id[tostring(buffId)] = buff
	table.insert(self.halos.idx, 1, buff)
	------------ 通用数据结构处理 ------------

	------------ 特殊类型处理 ------------
	if ConfigBuffType.SHIELD == buffType then
		-- 护盾缓存
		table.insert(self.shield, 1, buff)
	end
	------------ 特殊类型处理 ------------

	------------ buff生效 ------------
	if BuffCauseEffectTime.ADD2OBJ == buff:GetCauseEffectTime() then
		buff:OnCauseEffectEnter()
	end
	------------ buff生效 ------------
end
--[[
移除一个光环
@params buff BaseBuff buff实例
--]]
function BaseObjectModel:RemoveHalo(buff)
	local buffId = buff:GetBuffId()
	local buffType = buff:GetBuffType()

	------------ 通用数据结构处理 ------------
	-- buff缓存
	self.halos.id[tostring(buffId)] = nil
	for i = #self.halos.idx, 1, -1 do
		if buffId == self.halos.idx[i]:GetBuffId() then
			table.remove(self.halos.idx, i)
			break
		end
	end
	------------ 通用数据结构处理 ------------

	------------ 特殊类型处理 ------------
	-- 护盾缓存
	if ConfigBuffType.SHIELD == buffType then
		for i = #self.shield, 1, -1 do
			if self.shield[i]:GetBuffId() == bid then
				table.remove(self.shield, i)
				break
			end
		end
	end
	------------ 特殊类型处理 ------------
end
--[[
根据buffid获取buff指针
@params buffId string buff的唯一id
@params onlyBuff bool 是否只查找buff
@return result list<BaseBuff>
--]]
function BaseObjectModel:GetBuffsByBuffId(buffId, onlyBuff)
	local result = {}

	local buff = self:GetBuffByBuffId(buffId)
	if nil ~= buff then
		table.insert(result, 1, buff)
	end

	if false == onlyBuff then
		buff = self:GetHaloByBuffId(buffId)
		if nil ~= buff then
			table.insert(result, 1, buff)
		end
	end

	return result
end
--[[
根据buffid获取buff指针
@params buffId string buff的唯一id
@return _ BaseBuff buff
--]]
function BaseObjectModel:GetBuffByBuffId(buffId)
	return self.buffs.id[tostring(buffId)]
end
--[[
根据buffid获取halo指针
@params buffId string buffid
@return _ BaseBuff buffß
--]]
function BaseObjectModel:GetHaloByBuffId(buffId)
	return self.halos.id[tostring(buffId)]
end
--[[
根据buff类型获取物体身上的buff
@params buffType ConfigBuffType buff类型
@params onlyBuff bool 是否只查找buff不查找光环
@return result list buff实例集合
--]]
function BaseObjectModel:GetBuffsByBuffType(buffType, onlyBuff)
	local result = {}

	-- 查找buff
	for i = #self.buffs.idx, 1, -1 do
		if buffType == self.buffs.idx[i]:GetBuffType() then
			table.insert(result, 1, self.buffs.idx[i])
		end
	end

	-- 查找光环
	if false == onlyBuff then
		for i = #self.halos.idx, 1, -1 do
			if buffType == self.halos.idx[i]:GetBuffType() then
				table.insert(result, 1, self.halos.idx[i])
			end
		end
	end

	return result
end
--[[
根据技能id和buff类型获取buff
@params skillId int 技能id
@params buffType ConfigBuffType buff类型
@params onlyBuff bool 是否只查找buff不查找光环
--]]
function BaseObjectModel:GetBuffBySkillId(skillId, buffType, onlyBuff)
	local buff = nil

	for i = #self.buffs.idx, 1, -1 do
		buff = self.buffs.idx[i]
		if buffType == buff:GetBuffType() and skillId == buff:GetSkillId() then
			return buff
		end
	end

	if false == onlyBuff then
		for i = #self.halos.idx, 1, -1 do
			buff = self.halos.idx[i]
			if buffType == buff:GetBuffType() and skillId == buff:GetSkillId() then
				return buff
			end
		end
	end

	return nil
end
--[[
根据buff类型判断buff是否存在
@params buffType ConfigBuffType buff类型
@params onlyBuff bool 是否只查找buff不查找光环
@return _ bool 是否存在
--]]
function BaseObjectModel:HasBuffByBuffType(buffType, onlyBuff)
	-- 查找buff
	for i,v in ipairs(self.buffs.idx) do
		if buffType == v:GetBuffType() then
			return true
		end
	end

	-- 查找光环
	if false == onlyBuff then
		for i,v in ipairs(self.halos.idx) do
			if buffType == v:GetBuffType() then
				return true
			end
		end
	end

	return false
end
--[[
根据buff的icon type判断当前是否存在该buff
@params iconType BuffIconType
@params value number 数值
@return result bool 结果
--]]
function BaseObjectModel:HasBuffByBuffIconType(iconType, value)
	if true == BattleUtils.IsTable(value) then return end
	
	for i,v in ipairs(self.buffs.idx) do
		if iconType == v:GetBuffIconType() and v:GetBuffOriginValue() * value >= 0 then
			return true
		end
	end
	for i,v in ipairs(self.halos.idx) do
		if iconType == v:GetBuffIconType() and v:GetBuffOriginValue() * value >= 0 then
			return true
		end
	end
	return false
end
---------------------------------------------------
-- buff logic end --
---------------------------------------------------

---------------------------------------------------
-- buff infect logic begin --
---------------------------------------------------
--[[
根据技能id判断物体是否已经被传染
@params skillId int 
@return _ bool 是否已经被传染
--]]
function BaseObjectModel:IsInfectBySkillId(skillId)
	return false
end
--[[
添加可点击物体qte
@params qteBuffsInfo map qte数据信息
--]]
function BaseObjectModel:AddQTE(qteBuffsInfo)
	
end
--[[
移除可点击物体
@params skillId int 技能id
--]]
function BaseObjectModel:RemoveQTE(skillId)

end
--[[
根据单个buff移除qte buff
@params skillId int 技能id
@params buffType ConfigBuffType buff 类型
--]]
function BaseObjectModel:RemoveQTEBuff(skillId, buffType)
	
end
--[[
根据技能id获取qte物体
@params skillId int 技能id
--]]
function BaseObjectModel:GetQTEBySkillId(skillId)
	return self.qteBuffs.id[tostring(skillId)]
end
--[[
是否存在qte物体
@return _ bool 是否存在qte物体
--]]
function BaseObjectModel:HasQTE()
	return 0 < #self.qteBuffs.idx
end
--[[
添加传染驱动器
@params infectInfo InfectTransmitStruct 传染信息
--]]
function BaseObjectModel:AddInfectInfo(infectInfo)

end
--[[
移除传染驱动器
@params skillId int 技能id
--]]
function BaseObjectModel:RemoveInfecInfo(skillId)

end
---------------------------------------------------
-- buff infect logic end --
---------------------------------------------------

---------------------------------------------------
-- hp logic begin --
---------------------------------------------------
--[[
获取当前生命百分比
@return _ number
--]]
function BaseObjectModel:GetHPPercent()
	return 0
end
--[[
获取是否需要记录变化血量
@return _ ConfigMonsterRecordDeltaHP 是否需要记录血量变化
--]]
function BaseObjectModel:GetRecordDeltaHp()
	return ConfigMonsterRecordDeltaHP.DONT
end
---------------------------------------------------
-- hp logic end --
---------------------------------------------------

---------------------------------------------------
-- energy logic begin --
---------------------------------------------------
--[[
增加能量
@params delta number 变化的能量
--]]
function BaseObjectModel:AddEnergy(delta)
	self.energy = math.max(0, math.min(self:GetMaxEnergy(), self:GetEnergy() + delta))
end
--[[
获取能量
@return _ number 获取能量
--]]
function BaseObjectModel:GetEnergy()
	return self.energy
end
--[[
获取能量最大值
@return _ number 获取能量
--]]
function  BaseObjectModel:GetMaxEnergy()
	return MAX_ENERGY
end
--[[
获取能量百分比
@return _ number 能量百分比
--]]
function BaseObjectModel:GetEnergyPercent()
	return self:GetEnergy() / self:GetMaxEnergy()
end
--[[
强制变化一次能量百分比
@params percent number 能量百分比
--]]
function BaseObjectModel:EnergyPercentChangeForce(percent)
	local energy = self:GetMaxEnergy() * percent
	self.energy = energy
end
--[[
获取能量秒回参数
@return _ number 能量秒回参数
--]]
function BaseObjectModel:GetEnergyRecoverRate()
	return self.energyRecoverRate
end
--[[
变化能量秒回参数
@params delta number 变化值
--]]
function BaseObjectModel:AddEnergyRecoverRate(delta)
	self.energyRecoverRate = self.energyRecoverRate + delta
end
--[[
获取能量秒回值
--]]
function BaseObjectModel:GetEnergyRecoverRatePerS()
	return 0
end
---------------------------------------------------
-- energy logic end --
---------------------------------------------------

---------------------------------------------------
-- obj shift logic begin --
---------------------------------------------------
--[[
是否能进入下一波
@return 是否能进入下一波
--]]
function BaseObjectModel:CanEnterNextWave()
	return true
end
--[[
物体进入下一波的逻辑
@params nextWave int 下一波序号
--]]
function BaseObjectModel:EnterNextWave(nextWave)
	self:SetObjectWave(nextWave)
end
--[[
胜利
--]]
function BaseObjectModel:Win()
	
end
---------------------------------------------------
-- obj shift logic end --
---------------------------------------------------

---------------------------------------------------
-- escape logic begin --
---------------------------------------------------
--[[
开始逃跑
--]]
function BaseObjectModel:StartEscape()
	
end
--[[
逃跑结束
--]]
function BaseObjectModel:OverEscape()
	
end
--[[
从休息区返回战场
--]]
function BaseObjectModel:AppearFromEscape()

end
--[[
计算当前逃跑目标点
@return result cc.p 逃跑目标点
--]]
function BaseObjectModel:CalcEscapeTargetPosition()
	return nil
end
--[[
获取逃跑后重返战场的波数
--]]
function BaseObjectModel:GetAppearWaveAfterEscape()
	return nil
end
function BaseObjectModel:SetAppearWaveAfterEscape(wave)
	
end
---------------------------------------------------
-- escape logic end --
---------------------------------------------------

---------------------------------------------------
-- blew off logic begin --
---------------------------------------------------
--[[
吹出场外 自动走回场内
@params distance number 吹飞多少横坐标
--]]
function BaseObjectModel:BlewOff(distance)

end
---------------------------------------------------
-- blew off logic end --
---------------------------------------------------

---------------------------------------------------
-- die logic begin --
---------------------------------------------------
--[[
死亡开始
--]]
function BaseObjectModel:DieBegin()

end
--[[
死亡
--]]
function BaseObjectModel:Die()

end
--[[
死亡结束
--]]
function BaseObjectModel:DieEnd()

end
--[[
杀死自己
@params nature bool 是否是自然死亡 自然死亡不计入传给服务器的死亡列表
--]]
function BaseObjectModel:KillSelf(nature)

end
--[[
销毁
--]]
function BaseObjectModel:Destroy()
	
end
--[[
自然死亡
--]]
function BaseObjectModel:KillByNature()
	self:KillSelf(true)
	self:DieEnd()
end
---------------------------------------------------
-- die logic end --
---------------------------------------------------

---------------------------------------------------
-- revive logic begin --
---------------------------------------------------
--[[
复活
@params reviveHpPercent number 复活时的血量百分比
@params reviveEnergyPercent number 复活时的能量百分比
@params healData ObjectDamageStruct 伤害数据
--]]
function BaseObjectModel:Revive(reviveHpPercent, reviveEnergyPercent, healData)
	
end
---------------------------------------------------
-- revive logic end --
---------------------------------------------------

---------------------------------------------------
-- view transform begin --
---------------------------------------------------
--[[
变形
@params oriSkinId int 源皮肤id
@params oriActionName string 源皮肤变形的动作
@params targetSkinId int 目标皮肤id
@params targetActionName string 目标皮肤变形的衔接动作
--]]
function BaseObjectModel:ViewTransform(oriSkinId, oriActionName, targetSkinId, targetActionName)
	
end
--[[
刷新变形后的展示层
@params spineDataStruct ObjectSpineDataStruct spine动画信息
@params avatarScale number avatar缩放
--]]
function BaseObjectModel:RefreshViewModel(spineDataStruct, avatarScale)

end
---------------------------------------------------
-- view transform end --
---------------------------------------------------

---------------------------------------------------
-- abnormal state begin --
---------------------------------------------------
--[[
眩晕
无法行动 重复播放被击动画
@params valid bool 是否有效
--]]
function BaseObjectModel:Stun(valid)
	self:SetObjectAbnormalState(AbnormalState.STUN, valid)
end
--[[
冻结
无法行动 动画暂停
@params valid bool 是否有效
--]]
function BaseObjectModel:Freeze(valid)
	self:SetObjectAbnormalState(AbnormalState.FREEZE, valid)
end
--[[
沉默
无法施法 打断当前施法
@params valid bool 是否有效
--]]
function BaseObjectModel:Silent(valid)
	self:SetObjectAbnormalState(AbnormalState.SILENT, valid)
end
--[[
魅惑 平a敌友性改变 无法释放连携技
@params valid bool 是否有效
--]]
function BaseObjectModel:Enchanting(valid)
	self:SetObjectAbnormalState(AbnormalState.ENCHANTING, valid)
end
---------------------------------------------------
-- abnormal state end --
---------------------------------------------------

---------------------------------------------------
-- animation control begin --
---------------------------------------------------
--[[
让物体做一个动画动作
--]]
function BaseObjectModel:DoAnimation()

end
--[[
清空一个物体的动画动作
--]]
function BaseObjectModel:ClearAnimations()

end
--[[
设置动画的时间缩放
--]]
function BaseObjectModel:SetAnimationTimeScale()

end
--[[
获取动画的时间缩放
--]]
function BaseObjectModel:GetAnimationTimeScale()
	
end
--[[
获取当前正在进行的动作动画名
@return _ sp.AnimationName 动作动画名
--]]
function BaseObjectModel:GetCurrentAnimationName()
	return nil
end
---------------------------------------------------
-- animation control end --
---------------------------------------------------

---------------------------------------------------
-- performance begin --
---------------------------------------------------
--[[
强制眩晕
@params valid bool 是否有效
--]]
function BaseObjectModel:ForceStun(valid)
	
end
--[[
强制消失
@params actionName string 消失时的动作名
@params targetPos string 消失时的目标移动点
@params disappearCallback function 消失后的回调函数
--]]
function BaseObjectModel:ForceDisappear(actionName, targetPos, disappearCallback)
	
end
---------------------------------------------------
-- performance end --
---------------------------------------------------

---------------------------------------------------
-- transform begin --
---------------------------------------------------
--[[
变化物体的坐标
@params p cc.p 坐标信息
--]]
function BaseObjectModel:ChangePosition(p)
	self:UpdateLocation()
end
--[[
获取逻辑物体坐标信息
@return _ ObjectLocation
--]]
function BaseObjectModel:GetLocation()
	return self.location
end
--[[
刷新一次逻辑物体的坐标信息
--]]
function BaseObjectModel:UpdateLocation()

end
--[[
重置物体的站位至初始站位
--]]
function BaseObjectModel:ResetLocation()

end
--[[
获取旋转
--]]
function BaseObjectModel:GetRotate()

end
--[[
设置旋转
--]]
function BaseObjectModel:SetRotate(angle)

end
--[[
设置朝向
@params towards BattleObjTowards
--]]
function BaseObjectModel:SetOrientation(towards)

end
--[[
获取朝向
@return r 是否朝向右
--]]
function BaseObjectModel:GetOrientation()
	return true
end
--[[
获取朝向
@return _ BattleObjTowards
--]]
function BaseObjectModel:GetTowards()
	return self:GetOrientation() and BattleObjTowards.FORWARD or BattleObjTowards.NEGATIVE
end
--[[
获取物体的静态碰撞框信息
@return _ cc.rect 碰撞框信息
--]]
function BaseObjectModel:GetStaticCollisionBox()
	return nil
end
--[[
获取物体静态碰撞框相对于 battle root 的rect信息
@return _ cc.rect 碰撞框信息
--]]
function BaseObjectModel:GetStaticCollisionBoxInBattleRoot()
	return nil
end
--[[
获取物体的静态ui框信息
@return _ cc.rect 碰撞框信息
--]]
function BaseObjectModel:GetStaticViewBox()
	return nil
end
--[[
是否处于高亮
--]]
function BaseObjectModel:IsHighlight()
	return self.isInHighlight
end
function BaseObjectModel:SetHighlight(highlight)
	self.isInHighlight = highlight
end
--[[
zorder
--]]
function BaseObjectModel:GetZOrder()
	return self.zorderInBattle
end
function BaseObjectModel:SetZOrder(zorder)
	self.zorderInBattle = zorder
end
function BaseObjectModel:GetDefaultZOrder()
	return self:GetObjInfo().defaultZOrder
end
---------------------------------------------------
-- transform end --
---------------------------------------------------

---------------------------------------------------
-- event handler begin --
---------------------------------------------------
--[[
注册物体监听事件
--]]
function BaseObjectModel:RegisterObjectEventHandler()

end
--[[
注销物体监听事件
--]]
function BaseObjectModel:UnregistObjectEventHandler()

end
--[[
注册展示层的事件处理回调
--]]
function BaseObjectModel:RegistViewModelEventHandler()
	
end
--[[
注销展示层的事件处理回调
--]]
function BaseObjectModel:UnregistViewModelEventHandler()

end
--[[
死亡事件监听
@params ... 
	args table passed args
--]]
function BaseObjectModel:ObjectEventDieHandler( ... )

end
--[[
复活事件监听
@params ... 
	args table passed args
--]]
function BaseObjectModel:ObjectEventReviveHandler( ... )

end
--[[
施法事件监听
@params ... 
	args table passed args
--]]
function BaseObjectModel:ObjectEventCastHandler( ... )

end
--[[
隐身事件监听
@params ... 
	args table passed args
--]]
function BaseObjectModel:ObjectEventLuckHandler( ... )
	
end
--[[
击杀事件监听
@params ...
	args table passed args
--]]
function BaseObjectModel:ObjectEventSlayHandler( ... )
	
end
---------------------------------------------------
-- event handler end --
---------------------------------------------------

---------------------------------------------------
-- base info get set begin --
---------------------------------------------------
--[[
获取物体名字
--]]
function BaseObjectModel:GetObjectName()
	return 'Tag_' .. self:GetOTag()
end
--[[
@override
获取逻辑层物体与配表关联的id
--]]
function BaseObjectModel:GetObjectConfigId()
	return self:GetObjInfo().cardId
end
--[[
@override
获取逻辑层物体关联的配表信息
@return _ table
--]]
function BaseObjectModel:GetObjectConfig()
	return CardUtils.GetCardConfig(self:GetObjectConfigId())
end
--[[
获取物体的皮肤id
--]]
function BaseObjectModel:GetObjectSkinId()
	return self:GetObjInfo().skinId
end
--[[
获取物体职业特征
@return _ BattleObjectFeature
--]]
function BaseObjectModel:GetObjectFeature()
	return self:GetObjInfo().objectFeature
end
--[[
@override
获取敌友性 是否是敌军
@params o bool 是否获取初始敌友性
@return _ bool 是否是敌军
--]]
function BaseObjectModel:IsEnemy(o)
	return self:GetObjInfo().isEnemy
end
--[[
获取物体的职业类型
@return _ ConfigCardCareer
--]]
function BaseObjectModel:GetOCareer()
	return self:GetObjInfo().career
end
--[[
获取是否是木桩
@return _ bool 是否是木桩
--]]
function BaseObjectModel:IsScarecrow()
	return false
end
--[[
编队所处位置
--]]
function BaseObjectModel:GetTeamPosition()
	return self:GetObjInfo().teamPosition
end
--[[
获取物体等级
--]]
function BaseObjectModel:GetObjectLevel()
	return 1
end
--[[
获取obj基础特征
@return _ BattleObjectFeature 职业专精
--]]
function BaseObjectModel:GetOFeature()
	return self:GetObjInfo().objectFeature
end
--[[
获取物体怪物类型(计算不同类型物体增伤用)
@return _ ConfigMonsterType
--]]
function BaseObjectModel:GetObjectMosnterType()
	return ConfigMonsterType.BASE
end
---------------------------------------------------
-- base info get set end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
获取状态
@params i int -1返回上一个状态
--]]
function BaseObjectModel:GetState(i)
	if -1 == i then
		return self.state.pre
	else
		return self.state.cur
	end
end
--[[
设置状态
@params s OState 状态
@params i int -1设置上一个状态
--]]
function BaseObjectModel:SetState(s, i)
	if -1 == i then
		self.state.pre = s
	else
		self.state.pre = self.state.cur
		self.state.cur = s
	end
end
--[[
获取物体附加状态信息
--]]
function BaseObjectModel:GetObjectExtraStateInfo()
	return self.extraStateInfo
end
--[[
获取主属性信息
--]]
function BaseObjectModel:GetMainProperty()
	return nil
end
--[[
设置物体技能的特效数据
@params skillId int 技能id
@params animationData SkillSpineEffectStruct 动画数据
--]]
function BaseObjectModel:SetActionAnimationConfigBySkillId(skillId, animationConfig)
	self.actionAnimationConfig[tostring(skillId)] = animationConfig
end
--[[
根据物体技能id获取特效数据
@params skillId int 技能id
@return _ SkillSpineEffectStruct 动画配置数据
--]]
function BaseObjectModel:GetActionAnimationConfigBySkillId(skillId)
	return self.actionAnimationConfig[tostring(skillId)]
end
--[[
根据动画的动作名判断物体是否拥有这个动作
@params animationName string 动作名
--]]
function BaseObjectModel:HasAnimationByName(animationName)
	return self:GetViewModel():HasAnimationByName(animationName)
end
--[[
获取物体的波数
@return _ int 波数
--]]
function BaseObjectModel:GetObjectWave()
	return self.wave
end
--[[
设置物体的波数
@params wave int 波数
--]]
function BaseObjectModel:SetObjectWave(wave)
	self.wave = wave
end
--[[
获取物体的队伍序号
@return _ int 队伍序号
--]]
function BaseObjectModel:GetObjectTeamIndex()
	return self.teamIndex
end
--[[
设置物体的队伍序号
@params teamIndex int 队伍序号
--]]
function BaseObjectModel:SetObjectTeamIndex(teamIndex)
	self.teamIndex = teamIndex
end
--[[
根据类型获取属性值
@params propertyType ObjP
@params isOriginal bool 是否获取的初始值
@return _ number 加成后的属性
--]]
function BaseObjectModel:GetPropertyByObjP(propertyType, isOriginal)
	return 0
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

---------------------------------------------------
-- render refresh begin --
---------------------------------------------------
--[[
同步一次坐标
--]]
function BaseObjectModel:RefreshRenderViewPosition()
	
end
--[[
同步一次朝向
--]]
function BaseObjectModel:RefreshRenderViewTowards()
	
end
--[[
做spine动画
--]]
function BaseObjectModel:RefreshRenderAnimation()

end
--[[
清除所有spine动画
--]]
function BaseObjectModel:ClearRenderAnimations()
	
end
--[[
设置动画的时间缩放
@params timeScale number 时间缩放
--]]
function BaseObjectModel:RefreshRenderAnimationTimeScale(timeScale)
	
end
--[[
根据能量刷新所有连携技按钮
--]]
function BaseObjectModel:RefreshConnectButtonsByEnergy()

end
--[[
根据状态刷新所有连携技按钮
--]]
function BaseObjectModel:RefreshConnectButtonsByState()

end
--[[
点亮熄灭连携技按钮
@params skillId int 技能id
@params enable bool 是否可用
--]]
function BaseObjectModel:EnableConnectSkillButton(skillId, enable)

end
--[[
刷新渲染层血条
--]]
function BaseObjectModel:UpdateHpBar()

end
--[[
显示免疫文字
--]]
function BaseObjectModel:ShowImmune()

end
--[[
添加个一个buff icon
@params iconType BuffIconType
@params value number 数值
--]]
function BaseObjectModel:AddBuffIcon(iconType, value)

end
--[[
移除一个buff icon
@params iconType BuffIconType
@params value number 数值
--]]
function BaseObjectModel:RemoveBuffIcon(iconType, value)

end
--[[
显示被击爆点
@params effectData HurtEffectStruct 被击特效数据
--]]
function BaseObjectModel:ShowHurtEffect(effectData)
	
end
--[[
显示附加特效
@params visible bool 是否可见
@params	buffId string buff id
@params effectData AttachEffectStruct 被击特效数据
--]]
function BaseObjectModel:ShowAttachEffect(visible, buffId, effectData)
	
end
--[[
向渲染层发起初始化
--]]
function BaseObjectModel:InitObjectRender()

end
--[[
物体喊话对话框
@params dialogueFrameType int 对话框气泡类型
@params content string 对话内容
--]]
function BaseObjectModel:Speak(dialogueFrameType, content)

end
--[[
强制显示或者隐藏自己
@params show bool 是否显示
--]]
function BaseObjectModel:ForceShowSelf(show)
	
end
--[[
复活
--]]
function BaseObjectModel:ReviveRender()
	
end
--[[
显示目标mark
@params stageCompleteType ConfigStageCompleteType 过关类型
@params show bool 是否显示 
--]]
function BaseObjectModel:ShowStageClearTargetMark(stageCompleteType, show)

end
--[[
隐藏所有目标mark
--]]
function BaseObjectModel:HideAllStageClearTargetMark()
	
end
---------------------------------------------------
-- render refresh end --
---------------------------------------------------












return BaseObjectModel
