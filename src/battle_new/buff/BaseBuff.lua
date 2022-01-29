--[[
buff基类
@params args ObjectBuffConstructorStruct
--]]
local BaseBuff = class('BaseBuff')

------------ import ------------
------------ import ------------

------------ define ------------
------------ define ------------

--[[
constructor
--]]
function BaseBuff:ctor( ... )
	local args = unpack({...})
	self.buffInfo = args

	self:Init()
end

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化
--]]
function BaseBuff:Init()
	self:InitValue()
	self:InitTrigger()
end
--[[
初始化数值
--]]
function BaseBuff:InitValue()
	self:InitInnateValue()
	self:InitUnitValue()
end
--[[
初始化固有属性
--]]
function BaseBuff:InitInnateValue()
	-- buff是否有效
	self.buffVaild = true

	-- 叠加上限
	self.innerPile = math.max(self:GetInnerPileMax(), 1)

	------------ 光环叠加专用逻辑 ------------
	-- 光环叠加的施法者 效果 数据
	self.haloCasterValueInfo = {
		id = {},
		idx = {}
	}
	-- 手动添加一次外部光环叠加数据
	self:AddHaloOuterPile(self.buffInfo)
	------------ 光环叠加专用逻辑 ------------
end
--[[
初始化特有属性
--]]
function BaseBuff:InitUnitValue()
	self.p = {
		value = self.buffInfo.value,
		countdown = self.buffInfo.time
	}
	self:InitExtraValue()
end
--[[
初始化buff特有的数据
--]]
function BaseBuff:InitExtraValue()

end
--[[
初始化buff内部触发器
--]]
function BaseBuff:InitTrigger()
	self.triggers = {}

	local triggerTypeConfig = self:GetTriggerTypeConfig()
	if nil == next(triggerTypeConfig) then return end

	local owner = self:GetBuffOwner()
	if nil == owner then return end

	for _, triggerType in ipairs(triggerTypeConfig) do
		-- 创建触发器
		local trigger = __Require('battle.trigger.BaseTrigger').new(ObjectTriggerConstructorStruct.New(
			G_BattleLogicMgr:GetBData():GetTagByTagType(BattleTags.BT_TRIGGER),
			triggerType,
			handler(self, self.TriggerHandler)
		))
		self.triggers[triggerType] = trigger
		owner.triggerDriver:AddATrigger(trigger)
	end
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- logic begin --
---------------------------------------------------
--[[
造成效果
@params ... 变长参数
@return result number 造成效果以后的结果
--]]
function BaseBuff:OnCauseEffectEnter( ... )
	return self:CauseEffect(...)
end
--[[
造成效果
--]]
function BaseBuff:CauseEffect( ... )
	self:AddView()
	return 0
end
--[[
造成效果结束
--]]
function BaseBuff:OnCauseEffectExit()

end
--[[
恢复效果
@params casterTag int 施法者tag
@return result number 恢复效果以后的结果
--]]
function BaseBuff:OnRecoverEffectEnter(casterTag)
	if self:IsHaloBuff() then
		return self:RecoverEffectHalo(casterTag)
	else
		return self:RecoverEffectCommon()
	end
end
--[[
恢复halo效果
@params casterTag int 施法者tag
@return result number 恢复效果以后的结果
--]]
function BaseBuff:RecoverEffectHalo(casterTag)
	-- 转阶段怪物指针保存在休息池不会被移除buff
	local owner = self:GetBuffOwner()

	if nil ~= owner then
		if 1 >= #self.haloCasterValueInfo.idx then

			-- 移除buff
			self:RecoverBuff()

		else

			if casterTag and self:HasHaloOuterPileByCasterTag(casterTag) then
				-- 有叠加
				local casterTag_ = nil

				for i = #self.haloCasterValueInfo.idx, 1, -1 do
					casterTag_ = self.haloCasterValueInfo.idx[i].casterTag
					if casterTag and casterTag == casterTag_ then
						table.remove(self.haloCasterValueInfo.idx, i)
						self.haloCasterValueInfo.id[tostring(casterTag_)] = nil
					end
				end

				-- 如果当前施法者是被移除的光环 刷新一次光环
				if casterTag == self:GetBuffCasterTag() then
					for i = #self.haloCasterValueInfo.idx, 1, -1 do
						local buffInfo_ = self.haloCasterValueInfo.idx[i]
						-- 修改buff数据
						self:SetSkillId(buffInfo_.skillId)
						self:SetBuffCasterTag(buffInfo_.casterTag)

						self:RefreshBuffEffect(buffInfo_.value, buffInfo_.time)
						break
					end
				end
			end

		end
	end

	return 0
end
--[[
恢复普通buff效果
@return result number 恢复效果以后的结果
--]]
function BaseBuff:RecoverEffectCommon()
	-- 转阶段怪物指针保存在休息池不会被移除buff
	local owner = self:GetBuffOwner()

	if nil ~= owner then
		-- 移除buff
		self:RecoverBuff()
		-- 移除qte效果
		if self:HasQTE() then
			owner:RemoveQTEBuff(self:GetSkillId(), self:GetBuffType())
		end
	end

	return 0
end
--[[
恢复buff 移除buff
@return result number 恢复效果以后的结果
--]]
function BaseBuff:RecoverBuff()
	-- 恢复buff的效果
	local result = self:RecoverEffect()

	-- 移除buff
	self:OnRecoverEffectExit()

	return result
end
--[[
恢复效果
@return result number 恢复效果以后的结果
--]]
function BaseBuff:RecoverEffect()
	return 0
end
--[[
恢复效果结束
--]]
function BaseBuff:OnRecoverEffectExit()
	-- 移除所有的触发器
	self:ClearTriggers()

	local owner = self:GetBuffOwner()

	if nil ~= owner then
		if self:IsHaloBuff() then
			owner:RemoveHalo(self)
		else
			owner:RemoveBuff(self)
		end
		self:RemoveView()
	end
end
--[[
添加buff对应的展示
--]]
function BaseBuff:AddView()
	local owner = self:GetBuffOwner()

	if nil ~= owner then
		owner:ShowAttachEffect(true, self:GetBuffId(), self.buffInfo.attachAniEffectData)
	end
end
--[[
移除buff对应的展示
--]]
function BaseBuff:RemoveView()
	local owner = self:GetBuffOwner()

	if nil ~= owner then
		owner:ShowAttachEffect(false, self:GetBuffId(), self.buffInfo.attachAniEffectData)
	end
end
--[[
刷新buff
@params buffInfo ObjectBuffConstructorStruct buff数据
--]]
function BaseBuff:OnRefreshBuffEnter(buffInfo)
	if self:CanInnerPile() then
		-- /***********************************************************************************************************************************\
		--  * 内部叠加的buff必须满足外部无法叠加
		-- \***********************************************************************************************************************************/
		assert(
			buffInfo.casterTag == self:GetBuffCasterTag(),
			'\n' ..
			'************ logic error ************\n' ..
			'** inner pile but get a buff from other caster\n' .. 
			'>>>>>>old data -> casterTag, ownerTag, skillId, buffType\n' .. 
			string.format('%s, %s, %s, %s', self:GetBuffCasterTag(), self:GetBuffOwnerTag(), self:GetSkillId(), self:GetBuffType()) .. '\n' .. 
			'<<<<<<new data -> casterTag, ownerTag, skillId, buffType\n' .. 
			string.format('%s, %s, %s, %s', buffInfo.casterTag, buffInfo.ownerTag, buffInfo.skillId, buffInfo.btype) .. '\n' ..
			'************ logic error ************\n'
		)
		self:OnInnerPileEnter(buffInfo)
	else
		self:RefreshBuff(buffInfo)
	end
end
--[[
刷新buff
@params buffInfo ObjectBuffConstructorStruct buff数据
--]]
function BaseBuff:RefreshBuff(buffInfo)
	if self:IsHaloBuff() then
		------------ 光环叠加 ------------
		self:RefreshBuffHalo(buffInfo)
		------------ 光环叠加 ------------
	else
		------------ 普通buff刷新 ------------
		self:RefreshBuffCommon(buffInfo)
		------------ 普通buff刷新 ------------
	end
end
--[[
刷新光环buff
@params buffInfo ObjectBuffConstructorStruct buff数据
--]]
function BaseBuff:RefreshBuffHalo(buffInfo)
	if buffInfo.casterTag == self:GetBuffCasterTag() then return end
	
	self:AddHaloOuterPile(buffInfo)

	-- 修改buff数据
	self:SetSkillId(buffInfo.skillId)
	self:SetBuffCasterTag(buffInfo.casterTag)

	self:RefreshBuffEffect(buffInfo.value, buffInfo.time)
end
--[[
刷新正常buff
@params buffInfo ObjectBuffConstructorStruct buff数据
--]]
function BaseBuff:RefreshBuffCommon(buffInfo)
	-- 修改一次buff数据
	self.buffInfo = buffInfo

	self:RefreshBuffEffect(buffInfo.value, buffInfo.time)
end
--[[
刷新buff效果
@params value number
@params time number
--]]
function BaseBuff:RefreshBuffEffect(value, time)
	-- print('>>>>>>>>>>>>refresh buff', self:GetBuffOwnerTag(), self:GetSkillId(), self:GetBuffType(), self:GetBuffId(), self.p.value, self.p.countdown, value, time)

	-- 刷新缓存数据
	self.p.value = value
	self.p.countdown = time
end
--[[
叠加buff
@params buffInfo ObjectBuffConstructorStruct buff数据
--]]
function BaseBuff:OnInnerPileEnter(buffInfo)
	self:SetInnerPile(math.max(self:GetInnerPileMax(), self:GetInnerPile() + 1))

	self:RefreshBuffEffect(buffInfo.value * self:GetInnerPile(), buffInfo.time)
end
--[[
主逻辑更新
--]]
function BaseBuff:OnBuffUpdateEnter(dt)
	if self:IsHaloBuff() then return end

	-- 更新buff计时
	self.p.countdown = math.max(0, self.p.countdown - dt)
	if 0 >= self.p.countdown then
		self:OnRecoverEffectEnter()
	end
end
--[[
被驱散时的逻辑
--]]
function BaseBuff:OnBeDispeledEnter()
	self:OnRecoverEffectEnter()
end
--[[
处理外部光环叠加
@params buffInfo ObjectBuffConstructorStruct buff数据
--]]
function BaseBuff:AddHaloOuterPile(buffInfo)
	if self:HasHaloOuterPileByCasterTag() then return end
	
	local data = {
		skillId = buffInfo.skillId,
		casterTag = buffInfo.casterTag,
		value = buffInfo.value,
		time = buffInfo.time
	}
	table.insert(self.haloCasterValueInfo.idx, 1, data)
	self.haloCasterValueInfo.id[tostring(buffInfo.casterTag)] = buffInfo.casterTag
end
--[[
根据施法者tag判断光环外部叠加是否存在该物体
@params casterTag int 施法者tag
@return _ bool 
--]]
function BaseBuff:HasHaloOuterPileByCasterTag(casterTag)
	return nil ~= self.haloCasterValueInfo.id[tostring(casterTag)]
end
--[[
清除所有触发器
--]]
function BaseBuff:ClearTriggers()
	if nil == next(self:GetTriggerTypeConfig()) then return end

	local owner = G_BattleLogicMgr:GetObjByTagForce(self:GetBuffOwnerTag())
	if nil == owner then return end

	for _, trigger in pairs(self.triggers) do
		owner.triggerDriver:RemoveATrigger(trigger:GetTriggerTag())
		trigger:Destroy()
	end
end
--[[
触发触发器后的处理
@params triggerType ConfigObjectTriggerActionType 触发类型
@params ... 变长参数
--]]
function BaseBuff:TriggerHandler(triggerType, ...)

end
---------------------------------------------------
-- logic end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
获取buff信息
@return _ ObjectBuffConstructorStruct buff信息
--]]
function BaseBuff:GetBuffInfo()
	return self.buffInfo
end
--[[
获取buff对应的技能id
@return _ skillId int 技能id
--]]
function BaseBuff:GetSkillId()
	return self.buffInfo.skillId
end
function BaseBuff:SetSkillId()
	
end
--[[
获取buffid
@return _ string buff id
--]]
function BaseBuff:GetBuffId()
	return self.buffInfo.bid
end
--[[
获取buff类型
@params _ ConfigBuffType buff 类型
--]]
function BaseBuff:GetBuffType()
	return self.buffInfo.btype
end
--[[
获取buff种类
@return _ BKIND buff 种类
--]]
function BaseBuff:GetBuffKind()
	return self.buffInfo.bkind
end
--[[
获取buff icon图标
--]]
function BaseBuff:GetBuffIconType()
	return self.buffInfo.iconType
end
--[[
获取buff原始数值
@return _ number
--]]
function BaseBuff:GetBuffOriginValue()
	return self.buffInfo.value
end
--[[
获取buff原始cd
@return _ number
--]]
function BaseBuff:GetBuffOriginCountdown()
	return self.buffInfo.time
end
--[[
buff是否逻辑中有效
--]]
function BaseBuff:SetBuffVaild(b)
	self.buffVaild = b
end
function BaseBuff:GetBuffVaild()
	return self.buffVaild
end
--[[
buff内叠加层数
--]]
function BaseBuff:SetInnerPile(pile)
	self.innerPile = pile
end
function BaseBuff:GetInnerPile()
	return self.innerPile
end
--[[
buff内叠加上限
--]]
function BaseBuff:GetInnerPileMax()
	return self.buffInfo.innerPileMax
end
--[[
判断是否可以buff内叠加层数
@return _ bool
--]]
function BaseBuff:CanInnerPile()
	return ValueConstants.V_NORMAL < self:GetInnerPileMax()
end
--[[
是否是被动效果
--]]
function BaseBuff:IsHaloBuff()
	return self.buffInfo.isHalo
end
--[[
该buff是否是附加qte
--]]
function BaseBuff:HasQTE()
	return 0 < self.buffInfo.qteTapTime
end
--[[
获取buff拥有物体的tag
@return _ int obj tag
--]]
function BaseBuff:GetBuffOwnerTag()
	return self.buffInfo.ownerTag
end
--[[
获取buff施法物体的tag
@return _ BaseObject obj
--]]
function BaseBuff:GetBuffOwner()
	return G_BattleLogicMgr:IsObjAliveByTag(self:GetBuffOwnerTag())
end
--[[
获取buff施法物体的tag
@return _ int obj tag
--]]
function BaseBuff:GetBuffCasterTag()
	return self.buffInfo.casterTag
end
function BaseBuff:SetBuffCasterTag(otag)
	self.buffInfo.casterTag = otag
end
--[[
获取buff施法物体
@return _ BaseObject obj
--]]
function BaseBuff:GetBuffCaster()
	return G_BattleLogicMgr:IsObjAliveByTag(self:GetBuffCasterTag())
end
--[[
判断对于宿主是否是debuff
@return _ bool 是否是debuff
--]]
function BaseBuff:IsDebuff()
	return self.buffInfo.isDebuff
end
--[[
效果值
--]]
function BaseBuff:GetValue()
	return self.p.value
end
function BaseBuff:SetValue(value)
	self.p.value = value
end
--[[
持续时间
--]]
function BaseBuff:GetLeftCountdown()
	return self.p.countdown
end
function BaseBuff:SetLeftCountdown(cd)
	self.p.countdown = cd
end
--[[
获取buff生效时间类型
@return _ BuffCauseEffectTime 生效时间类型
--]]
function BaseBuff:GetCauseEffectTime()
	return self.buffInfo.causeEffectTime
end
--[[
获取buff内部trigger信息
--]]
function BaseBuff:GetTriggerTypeConfig()
	return {}
end
--[[
获取buff作用的内置cd
--]]
function BaseBuff:GetBuffTriggerInsideCD()
	return self.buffInfo.triggerInsideCD
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return BaseBuff
