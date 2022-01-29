--[[
主角施法驱动器
--]]
local BaseCastDriver = __Require('battle.objectDriver.castDriver.BaseCastDriver')
local PlayerCastDriver = class('PlayerCastDriver', BaseCastDriver)

------------ import ------------
------------ import ------------

--[[
@override
constructor
--]]
function PlayerCastDriver:ctor( ... )
	local args = unpack({...})

	self.skillIds = args.skillIds

	BaseCastDriver.ctor(self, ...)
end
---------------------------------------------------
-- init logic begin --
---------------------------------------------------
--[[
@override
初始化独有属性
--]]
function PlayerCastDriver:InitUnitValue()
	
end
---------------------------------------------------
-- init logic end --
---------------------------------------------------

---------------------------------------------------
-- control logic begin --
---------------------------------------------------
--[[
@override
是否能进行动作
@params skillId int 技能id
@return _ 是否可以释放
--]]
function PlayerCastDriver:CanDoAction(skillId)
	return self:CanCastBySkillId(skillId)
end
--[[
进入动作
@override
@params skillId int 技能id
--]]
function PlayerCastDriver:OnActionEnter(skillId)
	print('\n**************\n', ' cast player skill(new logic) -> ', skillId, '\n**************\n')

	------------ logic ------------
	-- 重置全局增伤系数
	self:ClearNextSkillExtra()

	-- 消耗释放技能的资源
	self:CostActionResources(skillId)
	------------ logic ------------

	-- 进入施法
	self:OnCastEnter(skillId)

	-- 显示黑色遮罩
	--***---------- 刷新渲染层 ----------***--
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'ShowCastPlayerSkillCover'
	)
	--***---------- 刷新渲染层 ----------***--
end
--[[
结束动作
--]]
function PlayerCastDriver:OnActionExit()
	self:OnCastExit()
end
--[[
打断动作
--]]
function PlayerCastDriver:OnActionBreak()

end
--[[
动作进行中
@params dt number delta time
--]]
function PlayerCastDriver:OnActionUpdate(dt)

end
--[[
@override
准备施法
@params skillId int 技能id
--]]
function PlayerCastDriver:OnCastEnter(skillId)
	---------- 发送物体施法事件 ----------
	G_BattleLogicMgr:SendObjEvent(ObjectEvent.OBJECT_CAST_ENTER, {
		tag = self:GetOwner():GetOTag(), isEnemy = self:GetOwner():IsEnemy(true), skillId = skillId
	})
	---------- 发送物体施法事件 ----------

	-- 施法
	self:Cast(skillId)

	-- 直接调用施法结束
	self:OnActionExit()
end
--[[
准备施法
@params skillId int 技能id
--]]
function PlayerCastDriver:Cast(skillId)
	local bulletOriPosition = self:GetOwner():GetLocation().po
	local params = ObjectCastParameterStruct.New(
		self:GetSkillExtra(),
		1,
		nil,
		bulletOriPosition,
		false,
		false
	)

	local skillModel = self:GetSkillModelBySkillId(skillId)
	if nil ~= skillModel then
		skillModel:CastBegin(params)
	end

	------------ sound effect ------------
	local animationData = self:GetOwner():GetActionAnimationConfigBySkillId(skillId)
	if nil ~= animationData then
		G_BattleLogicMgr:RenderPlayBattleSoundEffect(animationData.actionSE)
		G_BattleLogicMgr:RenderPlayBattleSoundEffect(animationData.actionVoice)
		G_BattleLogicMgr:RenderPlayBattleSoundEffect(animationData.actionCauseSE)
	end
	------------ sound effect ------------
end
--[[
@override
施法结束
--]]
function PlayerCastDriver:OnCastExit()
	------------ 重置一些参数 ------------
	self:ClearNextSkillExtra()
	self:SetCastingEcho(false)
	------------ 重置一些参数 ------------
end
--[[
是否可以释放对应id的技能
@params int skillId int 技能id
@return result bool 是否可以释放技能
--]]
function PlayerCastDriver:CanCastBySkillId(skillId)
	local result = false
	local skillConfig = CommonUtils.GetSkillConf(skillId)

	---------- 复活技能有特殊的机制 ----------
	if true == BattleUtils.IsSkillHaveBuffEffectByBuffType(skillId, ConfigBuffType.REVIVE) then
		if false == self:CanCastRevive(skillId) then
			return false
		end
	end
	---------- 复活技能有特殊的机制 ----------

	-- 普通技能检测
	if self:CanCastSkillJudgeByTriggerType(skillId) then
		result = true
	end

	return result
end
--[[
处理技能触发类型判定
@params skillId int 技能id
@return result bool 是否满足条件释放该技能
--]]
function PlayerCastDriver:CanCastSkillJudgeByTriggerType(skillId)
	local result = true

	---------- 内置cd ----------
	local insideCD = self:GetSkillInsideCD(skillId)
	if nil ~= insideCD and insideCD > 0 then
		return false
	end
	---------- 内置cd ----------

	local triggerType = 0
	local triggerValue = 0

	local judgeFunc = {
		[ConfigSkillTriggerType.RESIDENT] = function (triggerValue)

			-- 常驻触发类型视为光环 光环只在特定事件初始化
			return false

		end,
		[ConfigSkillTriggerType.RANDOM] = function (triggerValue)

			-- 随机
			return (triggerValue * 1000) >= (G_BattleLogicMgr:GetRandomManager():GetRandomInt(1000))

		end,
		[ConfigSkillTriggerType.ENERGY] = function (triggerValue)

			-- 能量
			return triggerValue <= self:GetOwner():GetEnergy()

		end,
		[ConfigSkillTriggerType.CD] = function (triggerValue)

			-- cd
			return 0 >= self:GetActionTrigger(ActionTriggerType.CD, skillId)

		end,
		[ConfigSkillTriggerType.LOST_HP] = function (triggerValue)

			-- 损失的血量百分比
			return false

		end,
		[ConfigSkillTriggerType.COST_HP] = function (triggerValue)

			-- 固定的血量
			return false

		end,
		[ConfigSkillTriggerType.COST_CHP] = function (triggerValue)

			-- 当前血量百分比
			return false

		end,
		[ConfigSkillTriggerType.COST_OHP] = function (triggerValue)

			-- 最大血量百分比
			return false

		end
	}

	---------- 判断触发条件 ----------
	local skillTriggerInfo = self:GetSkillTriggerInfoBySkillId(skillId)
	local sk = sortByKey(skillTriggerInfo)
	for _, key in ipairs(sk) do

		triggerType = key
		triggerValue = skillTriggerInfo[triggerType]

		local result = judgeFunc[triggerType](triggerValue)

		if not result then
			return false
		end

	end
	---------- 判断触发条件 ----------

	return result
end
--[[
是否可以施放复活技能
@params skillId int 技能id
@return _ bool 
--]]
function PlayerCastDriver:CanCastRevive(skillId)
	local skillConfig = CommonUtils.GetSkillConf(skillId)
	local isEnemy = self:GetOwner():IsEnemy()
	local canReviveCards = BattleExpression.GetDeadFriendlyTargetsForPlayerSkill(
		isEnemy,
		checkint(skillConfig.target[tostring(ConfigBuffType.REVIVE)].type),
		self:GetOwner(),
		true
	)
	return #canReviveCards > 0
end
---------------------------------------------------
-- control logic begin --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
根据技能id获取该技能的cd时间百分比
@params skillId int 技能id
@return percent number 冷却百分比
--]]
function PlayerCastDriver:GetCDPercentBySkillId(skillId)
	local currentCd = self:GetActionTrigger(ActionTriggerType.CD, skillId)
	if nil ~= currentCd then
		local skillConf = CommonUtils.GetSkillConf(skillId)
		return currentCd / checknumber(skillConf.triggerType[tostring(ConfigSkillTriggerType.CD)])
	else
		return nil	
	end
end
--[[
初始化技能数据结构
--]]
function PlayerCastDriver:InitSkills()
	-- 技能结构 主角技分成主动和被动 主动需要手动释放
	self.skills = {
		active = {}, 	-- 主动
		halo = {} 		-- 被动
	}

	-- 初始化外部影响的触发器
	self.actionTrigger = {
		[ActionTriggerType.CD] = {}
	}

	local skillId = nil
	local skillConfig = nil

	-- 主动主角技
	for _, skillIdInfo in ipairs(self.skillIds.activeSkill) do
		skillId = checkint(skillIdInfo.skillId)
		skillConfig = CommonUtils.GetSkillConf(skillId)

		if nil ~= skillConfig then

			self:AddASkill(skillId, 1)

		end
	end

	-- 被动主角技
	for _, skillIdInfo in ipairs(self.skillIds.passiveSkill) do
		skillId = checkint(skillIdInfo.skillId)
		skillConfig = CommonUtils.GetSkillConf(skillId)

		if nil ~= skillConfig then

			self:AddASkill(skillId, 1)

		end
	end

end
--[[
@override
添加一个技能
@params skillId int 技能id
@params level int 技能等级
--]]
function PlayerCastDriver:AddASkill(skillId, level)
	local skillConfig = CommonUtils.GetSkillConf(skillId)

	if nil == skillConfig then
		BattleUtils.PrintConfigLogicError('cannot find skill config in PlayerCastDriver -> AddASkill : ' .. tostring(skillId))
		return
	end

	if not self:CanInitSkillBySkillId(checkint(skillId)) then return end

	local skillClassPath = 'battle.skill.PlayerSkill'
	local skillType = checkint(skillConfig.property)

	---------- 处理一次内部触发条件 ----------
	local triggerInfo = {}
	for triggerType, triggerValue in pairs(skillConfig.triggerType) do
		triggerInfo[checkint(triggerType)] = checknumber(triggerValue)
	end
	self:SetSkillTriggerInfoBySkillId(skillId, triggerInfo)

	if nil ~= triggerInfo[ConfigSkillTriggerType.CD] then
		-- 存在cd触发的技能 初始化一次cd触发器
		self.actionTrigger[ActionTriggerType.CD][tostring(skillId)] = triggerInfo[ConfigSkillTriggerType.CD]
	end
	---------- 处理一次内部触发条件 ----------

	-- 初始化内置cd 第一次初始化为0
	self:SetSkillInsideCD(skillId, 0)

	-- 初始化技能动作 特效信息
	local effect = CardUtils.GetCardEffectConfigBySkinId(ConfigSpecialCardId.PLAYER, ConfigSpecialCardId.PLAYER)
	local spineActionData = BSCUtils.GetSkillSpineEffectStruct(skillId, effect, G_BattleLogicMgr:GetCurrentWave())

	-- 添加一次技能的动画信息
	self:GetOwner():SetActionAnimationConfigBySkillId(skillId, spineActionData)

	local skillBaseData = SkillConstructorStruct.New(
		skillId,
		level,
		BattleUtils.GetSkillInfoStructBySkillId(skillId, level),
		self:GetOwner():IsEnemy(true),
		self:GetOwner():GetOTag(),
		spineActionData
	)

	local skill = __Require(skillClassPath).new(skillBaseData)
	local skillInfo = ObjectSkillStruct.New(skillId, skill)
	self:SetSkillStructBySkillId(skillId, skillInfo)

	if ConfigSkillType.SKILL_HALO == skillType then

		table.insert(self.skills.halo, skillId)

	elseif ConfigSkillType.SKILL_PLAYER == skillType then

		table.insert(self.skills.active, skillId)

	end
end
--[[
根据技能类型获取一个随机的技能id
@params skillType ConfigSkillType 技能类型
@return _ int 技能id 
--]]
function PlayerCastDriver:GetRandomSkillIdBySkillType(skillType)
	return nil
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return PlayerCastDriver
