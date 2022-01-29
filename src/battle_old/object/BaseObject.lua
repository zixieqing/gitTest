--[[
战斗物体基类
@params t table {
	tag int obj tag
	oname string obj name
	battleElementType BattleElementType 战斗物体大类型 
	objInfo ObjectConstructorStruct 战斗物体构造函数
}
--]]
local BaseObject = class('BaseObject')
--[[
constructor
--]]
function BaseObject:ctor( ... )
	local args = unpack({...})

	------------ id信息 ------------
	self.idInfo = {
		tag = nil,
		oname = nil,
		battleElementType = BattleElementType.BET_BASE
	}
	------------ id信息 ------------

	------------ 初始化卡牌基本信息 ------------
	self.objInfo = nil
	------------ 初始化卡牌基本信息 ------------

	------------ 初始化ui信息 ------------
	self.view = {
		viewComponent = nil,
		avatar = nil,
		animationsData = nil,
		hpBar = nil,
		energyBar = nil,
	}
	------------ 初始化ui信息 ------------
	
end
---------------------------------------------------
-- init logic begin --
---------------------------------------------------
--[[
初始化战斗物体逻辑
--]]
function BaseObject:init()

end
--[[
初始化数值
--]]
function BaseObject:initValue()
	self:initInnateProperty()
	self:initUnitProperty()
end
--[[
初始化固有属性
--]]
function BaseObject:initInnateProperty()
	------------ logic info ------------
	self.viewModel = nil
	------------ logic info ------------

	------------ state info ------------
	-- 普通状态
	self.state = {
		cur = OState.SLEEP,
		pre = OState.SLEEP,
		pause = false,
		towards = BattleObjTowards.FORWARD
	}
	-- 特殊状态
	self.specialState = {
		silent = false,
		stun = false,
		freeze = false,
		enchanting = false,
		undead = false
	}
	------------ state info ------------

	------------ immune info ------------
	self.immune = {
		-- 静态免疫
		damage = false,
		silent = false,
		stun = false,
		freeze = false,
		enchanting = false,
		-- 动态免疫
		weather = {},
		skillBuff = {},
		innerSkillBuff = {}
	}
	-- 初始化伤害免疫
	self:initDamageImmune()
	-- 初始化全局伤害免疫
	self:initGlobalDamageImmune()
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
	self.timeInfectDrivers = {idx = {}, id = {}}
	------------ buff info ------------

	------------ temp info ------------
	-- 当前施法技能id
	self.castingSkillId = nil
	-- ciScene
	self.ciScene = nil
	-- 弱点id中间量
	self.curClickedWeakPointId = 0
	-- 逃跑后再次出现的波数 0为初始状态未逃跑过
	self.appearWaveAfterEscape = 0
	-- 是否高亮中
	self.isInHighlight = false
	-- 物体出现的波数
	self.wave = ValueConstants.V_NONE
	-- 物体的队伍序号
	self.teamIndex = ValueConstants.V_NONE
	-- 隐匿 非隐匿状态才可以被索敌
	self.luck = false
	------------ temp info ------------

	------------ countdown info ------------
	self.countdowns = {
		energy = 1
	}
	------------ countdown info ------------
end
--[[
初始化个体属性
--]]
function BaseObject:initUnitProperty()
	------------ location info ------------
	self.location = ObjectLocation.New(0, 0, 0, 0)
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
初始化展示层的逻辑
--]]
function BaseObject:InitViewModel()

end
--[[
初始化外貌
--]]
function BaseObject:initView()

end
--[[
初始化行为驱动器
--]]
function BaseObject:initDrivers()
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
	------------ drivers ------------

	------------ drivers ------------
	-- 同步驱动器
	self.synchronizeDriver = nil
	------------ drivers ------------	
end
--[[
注册战斗物体之间通信的回调函数
--]]
function BaseObject:registerObjEventHandler()

end
--[[
销毁战斗物体之间通信的回调函数
--]]
function BaseObject:unregisterObjEventHandler()
	
end
--[[
初始化技能免疫
--]]
function BaseObject:initSkillImmune()
	
end
--[[
初始化天气免疫
--]]
function BaseObject:initWeatherImmune()

end
--[[
初始化伤害免疫
--]]
function BaseObject:initDamageImmune()
	self.damageImmune = {}
	for _, v in pairs(DamageType) do
		self.damageImmune[v] = false
	end
end
--[[
初始化全局伤害免疫
--]]
function BaseObject:initGlobalDamageImmune()
	self.globalDamageImmune = {}
	for _, v in pairs(DamageType) do
		self.damageImmune[v] = false
	end
end
--[[
激活一次驱动器
--]]
function BaseObject:activateDrivers()
	
end
---------------------------------------------------
-- init logic end --
---------------------------------------------------

---------------------------------------------------
-- state logic begin --
---------------------------------------------------
--[[
get ostate
@params i int -1时返回上一个状态
@return state OState
--]]
function BaseObject:getState(i)
	if -1 == i then
		return self.state.pre
	else
		return self.state.cur
	end
end
--[[
set state
@params s OState
@params i int -1时设置前状态
--]]
function BaseObject:setState(s, i)
	if -1 == i then
		self.state.pre = s
	else
		self.state.pre = self.state.cur
		self.state.cur = s
	end
end
--[[
是否处于无法行动的状态
@return _ bool 是否可以行动
--]]
function BaseObject:canAct()
	return not (self.specialState.stun or self.specialState.freeze)
end
--[[
awake logic
唤醒obj
--]]
function BaseObject:awake()
	self:setState(OState.NORMAL)
	self:setLuck(false)
end
--[[
sleep logic
睡眠obj
--]]
function BaseObject:sleep()
	self:setState(OState.SLEEP)
end
--[[
沉默
@params s bool 是否被沉默
--]]
function BaseObject:silent(s)
	self.specialState.silent = s
end
--[[
是否被沉默
@return result bool 是否被沉默
--]]
function BaseObject:isSilent()
	return self.specialState.silent
end
--[[
不死
--]]
function BaseObject:isUndead()
	return self.specialState.undead
end
function BaseObject:setUndead(b)
	self.specialState.undead = b
end
--[[
设置免疫
@params bkind BKIND 免疫类型
@params b bool 是否免疫
--]]
function BaseObject:setImmune(bkind, b)
	if BKIND.INSTANT == bkind then
		self.immune.damage = b
	elseif BKIND.STUN == bkind then
		self.immune.stun = b
	elseif BKIND.SILENT == bkind then
		self.immune.silent = b
	elseif BKIND.FREEZE == bkind then
		self.immune.freeze = b
	elseif BKIND.ENCHANTING == bkind then
		self.immune.enchanting = b
	end
end
--[[
获取是否免疫
@params bkind BKIND 免疫类型
@return result bool
--]]
function BaseObject:isImmune(bkind)
	if BKIND.INSTANT == bkind then
		return self.immune.damage
	elseif BKIND.STUN == bkind then
		return self.immune.stun
	elseif BKIND.SILENT == bkind then
		return self.immune.silent
	elseif BKIND.FREEZE == bkind then
		return self.immune.freeze
	elseif BKIND.ENCHANTING == bkind then
		return self.immune.enchanting
	else
		return false
	end
end
--[[
设置全免疫
@params b bool 是否免疫
--]]
function BaseObject:setAllImmune(b)
	self.immune.damage = b
	self.immune.stun = b
	self.immune.silent = b
	self.immune.freeze = b
	self.immune.enchanting = b
end
--[[
设置伤害免疫
@params damageType DamageType 伤害类型
@params immune bool 是否免疫
--]]
function BaseObject:setDamageImmune(damageType, immune)
	self.damageImmune[damageType] = immune
end
function BaseObject:setGlobalDamageImmune(damageType, immune)
	self.globalDamageImmune[damageType] = immune
end
--[[
根据伤害类型获取是否免疫
@params damageType DamageType 伤害类型
@return _ bool 是否免疫该类型伤害
--]]
function BaseObject:isDamageImmune(damageType)
	return self.damageImmune[damageType]
end
function BaseObject:isGlobalDamageImmune(damageType)
	return self.globalDamageImmune[damageType]
end
--[[
判断buff免疫
@params btype ConfigBuffType buff类型
@return _ bool 是否免疫
--]]
function BaseObject:isBuffImmune(btype)
	return self:isImmuneByInnerSkillBuffType(btype) or self:isImmuneBySkillBuffType(btype)
end
--[[
根据buff类型判断是否免疫
@params btype ConfigBuffType buff类型
@return _ bool 是否免疫
--]]
function BaseObject:isImmuneBySkillBuffType(btype)
	if nil == self.immune.skillBuff[tostring(btype)] then
		return false
	else
		local immuneInfo = self.immune.skillBuff[tostring(btype)]
		for _, immune in pairs(immuneInfo) do
			if true == immune then
				return true
			end
		end
		return false
	end
end
--[[
设置buff免疫
@params skillId int 技能id
@params btype ConfigBuffType buff类型
@params immune 是否免疫
--]]
function BaseObject:setSkillBuffTypeImmune(skillId, btype, immune)
	if nil == self.immune.skillBuff[tostring(btype)] then
		self.immune.skillBuff[tostring(btype)] = {}
	end
	self.immune.skillBuff[tostring(btype)][tostring(skillId)] = immune
end
--[[
根据buff类型判断内置buff免疫
@params btype ConfigBuffType buff类型
@return _ bool 是否免疫
--]]
function BaseObject:isImmuneByInnerSkillBuffType(btype)
	if nil == self.immune.innerSkillBuff[tostring(btype)] then
		return false
	else
		return self.immune.innerSkillBuff[tostring(btype)]
	end
end
--[[
设置内置buff免疫
@params btype ConfigBuffType buff类型
@params immune 是否免疫
--]]
function BaseObject:setInnerSkillBuffTypeImmune(btype, immune)
	self.immune.innerSkillBuff[tostring(btype)] = immune
end
--[[
根据天气id判断是否免疫天气技能
@params weatherId int 天气id
@return _ bool 是否免疫
--]]
function BaseObject:isImmuneByWeatherId(weatherId)
	local weatherConf = CommonUtils.GetConfig('quest', 'weather', weatherId)
	if nil ~= weatherConf and true == self.immune.weather[tostring(weatherConf.weatherProperty)] then
		return true
	end
end
--[[
获取是否暂停
--]]
function BaseObject:isPause()
	return self.state.pause
end
--[[
设置暂停
--]]
function BaseObject:pauseObj()
	self.state.pause = true
end
--[[
恢复暂停
--]]
function BaseObject:resumeObj()
	self.state.pause = false
end
--[[
是否活着
--]]
function BaseObject:isAlive()
	return OState.DIE ~= self:getState()
end
--[[
获取朝向
@params return r 是否朝向右
--]]
function BaseObject:getOrientation()
	return self.state.towards == BattleObjTowards.FORWARD
end
--[[
判断物体是否满足死亡条件
@return result bool 死亡
--]]
function BaseObject:canDie()
	return not self:isUndead()
end
---------------------------------------------------
-- state logic end --
---------------------------------------------------

---------------------------------------------------
-- action logic begin --
---------------------------------------------------
--[[
索敌行为
--]]
function BaseObject:seekAttackTarget()
	
end
--[[
移动
@params dt number delta time
@params targetTag int 移动对象tag
--]]
function BaseObject:move(dt, targetTag)

end
--[[
攻击
@params targetTag int 攻击对象tag
--]]
function BaseObject:attack(targetTag)

end
--[[
施法
@params skillId int 技能id
--]]
function BaseObject:cast(skillId)

end
--[[
判断是否可以释放触发buff
@params skillId int 技能id
@params buffType ConfigBuffType buff类型
@params triggerActionType ConfigObjectTriggerActionType 物体行为触发类型
--]]
function BaseObject:CanTriggerBuff(skillId, buffType, triggerActionType)
	return true
end
--[[
消耗一些触发的buff的资源
@params skillId int 技能id
@params buffType ConfigBuffType buff类型
@params triggerActionType ConfigObjectTriggerActionType 物体行为触发类型
@params countdown number 触发的cd
--]]
function BaseObject:CostTriggerBuffResources(skillId, buffType, triggerActionType, cd)
	
end
--[[
变化朝向
@params b bool if is towards to right
--]]
function BaseObject:changeOrientation(b)

end
--[[
受到伤害 攻击方传来的伤害 先检查无敌 后消耗护盾
@params damageData table 伤害信息
--]]
function BaseObject:beAttacked(damageData)

end
--[[
受到治疗
@params healData table 治疗信息
--]]
function BaseObject:beHealed(healData)

end
--[[
最终血量变化 不计算减伤
@params damageData ObjectDamageStruct 伤害信息
--]]
function BaseObject:hpChange(damageData)
	
end
--[[
被施法
@params buffInfo table buff信息
@return _ bool 是否成功加上了该buff
--]]
function BaseObject:beCasted(buffInfo)
	return true
end
--[[
加buff
@params buff BaseBuff buff实例
--]]
function BaseObject:addBuff(buff)
	local bid = buff:GetBuffId()
	local skillId = buff:GetSkillId()
	local bkind = buff:GetBuffKind()
	local btype = buff:GetBuffType()

	------------ 通用数据结构处理 ------------
	-- buff数据缓存
	self.buffs.id[tostring(bid)] = buff
	table.insert(self.buffs.idx, 1, buff)

	-- 技能计数器
	if nil == self.buffs.skillCounter[tostring(skillId)] then
		self.buffs.skillCounter[tostring(skillId)] = 0
	end
	self.buffs.skillCounter[tostring(skillId)] = self.buffs.skillCounter[tostring(skillId)] + 1
	------------ 通用数据结构处理 ------------

	------------ 特殊类型处理 ------------
	if BKIND.SHIELD == bkind then
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
清buff
@params buff BaseBuff buff实例
--]]
function BaseObject:removeBuff(buff)
	local bid = buff:GetBuffId()
	local skillId = buff:GetSkillId()
	local bkind = buff:GetBuffKind()
	local btype = buff:GetBuffType()

	------------ 通用数据结构处理 ------------
	-- buff数据缓存
	self.buffs.id[tostring(bid)] = nil
	for i = #self.buffs.idx, 1, -1 do
		if self.buffs.idx[i]:GetBuffId() == bid then
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
			local timeInfectDriver = self:findInfectDriverExistBySkillId(skillId)
			if timeInfectDriver then
				timeInfectDriver:Kill()
			end
		end
	else
		print('\n!!!!!!!!!!!!!!!!!!\n', 'here data error !!! -> ', skillId, '\n!!!!!!!!!!!!!!!!!!\n')
	end
	------------ 通用数据结构处理 ------------

	------------ 特殊类型处理 ------------
	if BKIND.SHIELD == bkind then
		-- 移除护盾缓存
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
清除全部buff
--]]
function BaseObject:clearBuff()
	for i = #self.buffs.idx, 1, -1 do
		local buff = self.buffs.idx[i]
		self.buffs.id[tostring(buff:GetBuffId())] = nil
		buff:OnRecoverEffectEnter()
	end
end
--[[
添加光环
@params buff BaseBuff buff实例
--]]
function BaseObject:addHalo(buff)
	local bid = buff:GetBuffId()
	local bkind = buff:GetBuffKind()
	local btype = buff:GetBuffType()

	------------ 通用数据结构处理 ------------
	-- buff缓存
	self.halos.id[tostring(bid)] = buff
	table.insert(self.halos.idx, 1, buff)
	------------ 通用数据结构处理 ------------

	------------ 特殊类型处理 ------------
	if BKIND.SHIELD == bkind then
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
清光环
@params buff BaseBuff buff实例
--]]
function BaseObject:removeHalo(buff)
	local bid = buff:GetBuffId()
	local bkind = buff:GetBuffKind()
	local btype = buff:GetBuffType()

	------------ 通用数据结构处理 ------------
	-- buff缓存
	self.halos.id[tostring(bid)] = nil
	for i = #self.halos.idx, 1, -1 do
		if self.halos.idx[i]:GetBuffId() == bid then
			table.remove(self.halos.idx, i)
			break
		end
	end
	------------ 通用数据结构处理 ------------

	------------ 特殊类型处理 ------------
	-- 护盾缓存
	if BKIND.SHIELD == btype then
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
添加可点击物体qte
@params qteBuffsInfo table qte数据信息
--]]
function BaseObject:addQTE(qteBuffsInfo)
	
end
--[[
移除可点击物体
@params skillId int 技能id
--]]
function BaseObject:removeQTE(skillId)

end
--[[
根据单个buff移除qte buff
@params skillId int 技能id
@params btype ConfigBuffType buff 类型
--]]
function BaseObject:removeQTEBuff(skillId, btype)
	
end
--[[
根据技能id获取qte物体
@params skillId int 技能id
--]]
function BaseObject:getQTEBySkillId(skillId)
	return nil
end
--[[
是否存在qte物体
@return _ bool 是否存在qte物体
--]]
function BaseObject:hasQTE()
	
end
--[[
添加传染驱动器
@params infectInfo InfectTransmitStruct 传染信息
--]]
function BaseObject:addInfectDriver(infectInfo)
	local infectDriver = __Require('battle.skill.InfectDriver').new({infectInfo = infectInfo})
	self.timeInfectDrivers.id[tostring(infectInfo.skillId)] = infectDriver
	table.insert(self.timeInfectDrivers.idx, 1, infectDriver)
end
--[[
移除传染驱动器
--]]
function BaseObject:removeInfectDriver(skillId)
	for i = #self.timeInfectDrivers.idx, 1, -1 do
		if checkint(skillId) == checkint(self.timeInfectDrivers.idx[i]:GetSkillId()) then
			table.remove(self.timeInfectDrivers.idx, i)
			break
		end 
	end
	self.timeInfectDrivers.id[tostring(skillId)] = nil
end
--[[
是否已经携带传染驱动器
@params skillId int 技能id
@return _ InfectDriver 传染驱动器指针
--]]
function BaseObject:findInfectDriverExistBySkillId(skillId)
	if nil == skillId then return nil end
	return self.timeInfectDrivers.id[tostring(skillId)]
end
--[[
施放所有光环
--]]
function BaseObject:castAllHalos()

end
--[[
眩晕
@params s bool 是否被眩晕
--]]
function BaseObject:stun(s)
	self.specialState.stun = s
end
--[[
冻结
@params s bool 是否被冻结
--]]
function BaseObject:freeze(f)
	self.specialState.freeze = f
end
--[[
魅惑
@params e bool 是否被魅惑
--]]
function BaseObject:enchanting(e)
	self.specialState.enchanting = e
end
--[[
是否被魅惑
@return _ bool 是否被魅惑
--]]
function BaseObject:isEnchanting()
	return self.specialState.enchanting
end
--[[
死亡动作开始
--]]
function BaseObject:dieBegin()
	
end
--[[
死亡
--]]
function BaseObject:die()

end
--[[
死亡结束
--]]
function BaseObject:dieEnd()
	
end
--[[
销毁 不可逆！
--]]
function BaseObject:destroy()
	
end
--[[
杀死该对象 处理数据结构
@params nature bool 是否是自然死亡 自然死亡不计入传给服务器的死亡列表
--]]
function BaseObject:killSelf(nature)

end
--[[
自然死亡
--]]
function BaseObject:KillByNature()
	
end
--[[
胜利
--]]
function BaseObject:win()
	
end
--[[
复活
@params reviveHpPercent number 复活时的血量百分比
@params reviveEnergyPercent number 复活时的能量百分比
--]]
function BaseObject:revive(reviveHpPercent, reviveEnergyPercent)
	
end
--[[
强制隐藏
--]]
function BaseObject:forceHide()

end
--[[
强制显示
--]]
function BaseObject:forceShow()
	
end
---------------------------------------------------
-- action logic begin --
---------------------------------------------------

---------------------------------------------------
-- controller logic begin --
---------------------------------------------------
--[[
是否能进入下一波
@return 是否能进入下一波
--]]
function BaseObject:canEnterNextWave()
	return true
end
--[[
进入下一波
@params nextWave int 下一波
--]]
function BaseObject:enterNextWave(nextWave)
	self:setObjectWave(nextWave)
end
---------------------------------------------------
-- controller logic end --
---------------------------------------------------

---------------------------------------------------
-- update logic begin --
---------------------------------------------------
--[[
main update
--]]
function BaseObject:update(dt)

end
--[[
update location info
--]]
function BaseObject:updateLocation()
	self:getLocation().po.x = self.view.viewComponent:getPositionX()
	self:getLocation().po.y = self.view.viewComponent:getPositionY()
	self:getLocation().rc.r = BMediator:GetRowColByPos(cc.p(self:getLocation().po.x, self:getLocation().po.y)).r
	self:getLocation().rc.c = BMediator:GetRowColByPos(cc.p(self:getLocation().po.x, self:getLocation().po.y)).c
end
---------------------------------------------------
-- update logic end --
---------------------------------------------------

---------------------------------------------------
-- view update begin --
---------------------------------------------------
--[[
刷新血条
@params all bool(nil) true时更新最大血量
--]]
function BaseObject:updateHpBar(all)
	
end
--[[
刷新能量条
@params all bool(nil) true时更新最大能量
--]]
function BaseObject:updateEnergyBar(all)
	
end
--[[
显示被击特效
@params params table {
	hurtEffectId int 被击特效id
	hurtEffectPos cc.p 被击特效单位坐标
	hurtEffectZOrder int 被击特效层级
}
--]]
function BaseObject:showHurtEffect(params)

end
--[[
显示或隐藏附加在人物身上的特效
@params v bool 是否可见
@params bid string buff id
@params params table {
	attachEffectId int 特效id
	attachEffectPos cc.p 特效位置坐标
	attachEffectZOrder int 特效层级
}
--]]
function BaseObject:showAttachEffect(v, bid, params)

end
--[[
显示目标mark
@params stageCompleteType ConfigStageCompleteType 过关类型
@params show bool 是否显示 
--]]
function BaseObject:ShowStageClearTargetMark(stageCompleteType, show)

end
--[[
隐藏所有目标mark
--]]
function BaseObject:HideAllStageClearTargetMark()
	
end
---------------------------------------------------
-- view update end --
---------------------------------------------------

---------------------------------------------------
-- handler logic begin --
---------------------------------------------------
--[[
死亡事件回调
@params ... 
	args table passed args
--]]
function BaseObject:objDieEventHandler(...)
	
end
--[[
复活回调
@params ... 
	args table passed args
--]]
function BaseObject:objReviveEventHandler(...)

end
--[[
施法事件回调
@params ... 
	args table passed args
--]]
function BaseObject:objCastEventHandler(...)
	
end
--[[
隐身事件回调
@params ... 
	args table passed args
--]]
function BaseObject:objLuckEventHandler(...)
	
end
--[[
击杀事件回调
@params ... 
	args table passed args
--]]
function BaseObject:slayObjEventHandler(...)
	
end
---------------------------------------------------
-- handler logic end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
获取tag
--]]
function BaseObject:getOTag()
	return self.idInfo.tag
end
--[[
获取name
--]]
function BaseObject:getOName()
	return self.idInfo.oname
end
--[[
获取obj大类
@return _ BattleElementType 战斗元素类型
--]]
function BaseObject:getOBEType()
	return self.idInfo.battleElementType
end
--[[
获取obj基础特征
@return _ BattleObjectFeature 职业专精
--]]
function BaseObject:getOFeature()
	return self.objInfo.objectFeature
end
--[[
获取战斗物体外部配置
@return _ table
--]]
function BaseObject:getObjectConfig()
	assert(false, 'you must override this function-> #BaseObject:getObjectConfig# in child class')
end
--[[
获取obj职业
@return _ ConfigCardCareer obj职业
--]]
function BaseObject:getOCareer()
	return self.objInfo.career
end
--[[
获取obj等级
@return _ int 等级
--]]
function BaseObject:getObjectLevel()
	return 1
end
--[[
获取是否是敌人
@params o bool 是否是原始敌友性
--]]
function BaseObject:isEnemy(o)
	return false
end
--[[
获取坐标信息
--]]
function BaseObject:getLocation()
	return self.location
end
--[[
仇恨值
--]]
function BaseObject:getHate()
	return self.hate
end
function BaseObject:setHate(hate)
	self.hate = hate
end
--[[
能量增加
--]]
function BaseObject:addEnergy(delta)
	self.energy = RBQN.New(math.max(0, math.min(MAX_ENERGY, self.energy + delta)))
end
--[[
获取能量
--]]
function BaseObject:getEnergy()
	return self.energy
end
--[[
获取能量秒回 能量秒回
--]]
function BaseObject:getEnergyRecoverRatePerS()
	return ENERGY_PER_S + self:getEnergyRecoverRate()
end
--[[
获取能量秒回参数
--]]
function BaseObject:getEnergyRecoverRate()
	return self.energyRecoverRate
end
--[[
变化能量秒回参数
@params delta number 变化值
--]]
function BaseObject:addEnergyRecoverRate(delta)
	self.energyRecoverRate = RBQN.New(self.energyRecoverRate + delta)
end
--[[
根据buffid获取buff
@params buffId int buff id
@return result basebuff 
--]]
function BaseObject:getBuffByBuffId(buffId)
	result = self.buffs.id[tostring(buffId)]
	return result
end
--[[
根据id获取光环
@params id int buff id
@return result basebuff 
--]]
function BaseObject:getHaloByBuffId(id)
	result = self.halos.id[tostring(id)]
	return result
end
--[[
查找buff
@params skillId int 技能id
@params btype ConfigBuffType 
@params result 目标buff
--]]
function BaseObject:findBuff(skillId, btype)
	if nil == skillId then
		return self.buffs.id[tostring(btype)]
	end
	local bid = tostring(btype) .. '_' .. tostring(skillId)
	local result = self.buffs.id[bid]
	if not result then
		result = self.buffs.id[tostring(btype)]
	end
	return result
end
--[[
根据buff类型判断buff是否存在
@params btype ConfigBuffType 
@params onlyBuff bool 是否只查找buff不查找光环
@return _ bool 是否存在
--]]
function BaseObject:HasBuffByBuffType(btype, onlyBuff)
	for i,v in ipairs(self.buffs.idx) do
		if btype == v:GetBuffType() then
			return true
		end
	end
	if false == onlyBuff then
		for i,v in ipairs(self.halos.idx) do
			if btype == v:GetBuffType() then
				return true
			end
		end
	end
	return false
end
--[[
根据buff类型获取buff实例
@params btype ConfigBuffType
@params onlyBuff bool 是否只查找buff不查找halo
@return result list buff实例集合
--]]
function BaseObject:GetBuffsByBuffType(btype, onlyBuff)
	local result = {}
	for i = #self.buffs.idx, 1, -1 do
		if btype == self.buffs.idx[i]:GetBuffType() then
			table.insert(result, 1, self.buffs.idx[i])
		end
	end
	if false == onlyBuff then
		for i = #self.halos.idx, 1, -1 do
			if btype == self.halos.idx[i]:GetBuffType() then
				table.insert(result, 1, self.halos.idx[i])
			end
		end
	end
	return result
end
--[[
查找某类buff是否存在
@params iconType BuffIconType
@params value number 数值
@return result bool 结果
--]]
function BaseObject:isBuffExistByIconType(iconType, value)
	local valueJudge = false
	
	if BattleUtils.IsTable(value) then 
		-- 数值是table的buff 不判断正负
		return true
	end
	
	for i,v in ipairs(self.buffs.idx) do
		if iconType == v:GetBuffIconType() then
			if not BattleUtils.IsTable(value) and nil ~= tonumber(value) and v:GetBuffOriginValue() * checknumber(value) >= 0 then
				return true
			end
		end
	end
	for i,v in ipairs(self.halos.idx) do
		if iconType == v:GetBuffIconType() then
			if not BattleUtils.IsTable(value) and nil ~= tonumber(value) and v:GetBuffOriginValue() * checknumber(value) >= 0 then
				return true
			end
		end
	end
	return false
end
--[[
设置血量百分比
@params percent number 百分比
--]]
function BaseObject:setHpPercentForce(percent)
	
end
--[[
获取obj碰撞方格
--]]
function BaseObject:getStaticCollisionBox()
	return cc.rect(0, 0, 0, 0)
end
--[[
高亮
--]]
function BaseObject:isHighlight()
	return self.isInHighlight
end
function BaseObject:setHighlight(b)
	self.isInHighlight = b
end
--[[
获取皮肤id
@return int 皮肤id
--]]
function BaseObject:getOSkinId()
	return self.objInfo.skinId
end
--[[
获取物体默认图层
@return int 物体图层
--]]
function BaseObject:getODefaultZOrder()
	return self.objInfo.defaultZOrder
end
--[[
获取卡牌资源信息
@return _ CardObjDrawInfoStruct 卡牌资源信息
--]]
function BaseObject:getDrawPathInfo()
	return self.drawPathInfo
end
--[[
获取是否是木桩
@return _ bool 是否是木桩
--]]
function BaseObject:isScarecrow()
	return false
end
--[[
获取物体的波数
@return _ int 波数
--]]
function BaseObject:getObjectWave()
	return self.wave
end
--[[
设置物体的波数
@params wave int 波数
--]]
function BaseObject:setObjectWave(wave)
	self.wave = wave
end
--[[
获取物体的队伍序号
@return _ int 队伍序号
--]]
function BaseObject:getObjectTeamIndex()
	return self.teamIndex
end
--[[
设置物体的队伍序号
@params teamIndex int 队伍序号
--]]
function BaseObject:setObjectTeamIndex(teamIndex)
	self.teamIndex = teamIndex
end
--[[
是否可以被索敌
--]]
function BaseObject:setLuck(b)
	self.luck = b
end
function BaseObject:isLuck()
	return self.luck
end
--[[
根据类型获取属性值
@params propertyType ObjP
@params isOriginal bool 是否获取的初始值
@return _ number 加成后的属性
--]]
function BaseObject:getPropertyByObjP(propertyType, isOriginal)
	return nil
end
--[[
获取物体类型(计算不同类型物体增伤用)
@return _ ConfigMonsterType
--]]
function BaseObject:getObjectMosnterType()
	return ConfigMonsterType.BASE
end
--[[
获取展示层的模型
@return _ BaseViewModel
--]]
function BaseObject:GetViewModel()
	return self.viewModel
end
--[[
设置展示层模型
--]]
function BaseObject:SetViewModel(viewModel)
	self.viewModel = viewModel
end
--[[
是否需要记录变化的血量
--]]
function BaseObject:GetRecordDeltaHp()
	return ConfigMonsterRecordDeltaHP.DONT
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

---------------------------------------------------
-- force control begin --
---------------------------------------------------
--[[
强制眩晕
@params s bool 眩晕或解除
--]]
function BaseObject:forceStun(s)
	
end
--[[
吹出场外 自动走回场内
@params distance number 吹飞多少横坐标
--]]
function BaseObject:blewOff(distance)

end
--[[
逃跑
--]]
function BaseObject:escape()

end
--[[
逃跑结束
--]]
function BaseObject:appearFromEscape()

end
---------------------------------------------------
-- force control end --
---------------------------------------------------

return BaseObject
