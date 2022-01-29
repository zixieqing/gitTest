--[[
主角施法驱动器
--]]
local BaseCastDriver = __Require('battle.objectDriver.BaseCastDriver')
local PlayerCastDriver = class('PlayerCastDriver', BaseCastDriver)

------------ import ------------
local cardMgr = AppFacade.GetInstance():GetManager('CardManager')
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
	---------- logic ----------
	-- 重置技能最终乘法参数
	self.skillExtra = 1
	-- 消耗释放技能的资源
	self:CostActionResources(skillId)
	-- 广播信号
	BMediator:SendObjEvent(ObjectEvent.OBJECT_CAST_ENTER, {
		tag = self:GetOwner():getOTag(), isEnemy = self:GetOwner():isEnemy(true), skillId = skillId
	})
	---------- logic ----------

	---------- view ----------
	-- 显示黑色遮罩
	BMediator:ShowCastPlayerSkillCover()
	---------- view ----------

	self:Cast(skillId)
end
--[[
结束动作
--]]
function PlayerCastDriver:OnActionExit()

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
准备施法
@params skillId int 技能id
--]]
function PlayerCastDriver:Cast(skillId)
	local bulletOriPosition = self:GetOwner():getLocation().po
	local params = ObjectCastParameterStruct.New(
		self.skillExtra,
		1,
		nil,
		bulletOriPosition,
		false,
		false
	)
	self.skills[tostring(skillId)].skill:CastBegin(params)

	------------ sound effect ------------
	PlayBattleEffects(self.skillSpineActionData[tostring(skillId)].actionSE)
	PlayBattleEffects(self.skillSpineActionData[tostring(skillId)].actionVoice)
	PlayBattleEffects(self.skillSpineActionData[tostring(skillId)].actionCauseSE)
	------------ sound effect ------------
end
--[[
是否可以释放对应id的技能
@params int skillId int 技能id
@return result bool 是否可以释放技能
--]]
function PlayerCastDriver:CanCastBySkillId(skillId)
	local result = false
	local skillConf = CommonUtils.GetSkillConf(skillId)

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
	local insideCD = self.skillInsideCountdown[tostring(skillId)]
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
			return (triggerValue * 1000) >= (BMediator:GetRandomManager():GetRandomInt(1000))

		end,
		[ConfigSkillTriggerType.ENERGY] = function (triggerValue)

			-- 能量
			return triggerValue <= self:GetOwner():getEnergy():ObtainVal()

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
function BaseCastDriver:CanCastRevive(skillId)
	local skillConf = CommonUtils.GetSkillConf(skillId)
	local isEnemy = self:GetOwner():isEnemy()
	local canReviveCards = BattleExpression.GetDeadFriendlyTargets(
		isEnemy,
		checkint(skillConf.target[tostring(ConfigBuffType.REVIVE)].type),
		self:GetOwner()
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
	-- 初始化外部影响的触发器
	self.actionTrigger = {
		[ActionTriggerType.CD] = {}
	}

	-- 技能结构 主角技分成主动和被动 主动需要手动释放
	self.skills = {
		halo = {}, -- 被动
		active = {} -- 主动
	}

	self.skillSpineActionData = {}

	-- 技能内置cd
	self.skillInsideCountdown = {}

	-- 技能的触发条件
	self.skillTriggerInfo = {}

	local effectConf = CardUtils.GetCardEffectConfigBySkinId(ConfigSpecialCardId.PLAYER, ConfigSpecialCardId.PLAYER)

	local sid = 0
	local skillConf = 0
	local triggerType = 0
	local triggerValue = nil

	for i,v in ipairs(self.skillIds.activeSkill) do
		sid = checkint(v.skillId)
		skillConf = CommonUtils.GetSkillConf(sid)

		if ConfigSkillType.SKILL_PLAYER == checkint(skillConf.property) then
			---------- 处理一次内部触发条件 ----------
			local triggerInfo = {}
			for triggerType, triggerValue in pairs(skillConf.triggerType) do
				triggerInfo[checkint(triggerType)] = checknumber(triggerValue)
			end
			self.skillTriggerInfo[tostring(sid)] = triggerInfo
			---------- 处理一次内部触发条件 ----------

			---------- 技能包含cd触发类型 ----------
			triggerValue = skillConf.triggerType[tostring(ConfigSkillTriggerType.CD)]
			if nil ~= triggerValue then
				self.actionTrigger[ActionTriggerType.CD][tostring(sid)] = checknumber(triggerValue)
			end
			---------- 技能包含cd触发类型 ----------

			-- 初始化内置cd 第一次初始化为0
			self.skillInsideCountdown[tostring(sid)] = 0

			local skillSpineEffectData = SkillSpineEffectStruct.New(sid, effectConf)
			self.skillSpineActionData[tostring(sid)] = skillSpineEffectData

			local skillBaseData = SkillConstructorStruct.New(
				sid,
				1,
				BattleUtils.GetSkillInfoStructBySkillId(sid, 1),
				self:GetOwner():isEnemy(),
				self:GetOwner():getOTag(),
				skillSpineEffectData
			)

			local skill = __Require('battle.skill.PlayerSkill').new(skillBaseData)
			local skillInfo = ObjectSkillStruct.New(sid, skill)
			self.skills[tostring(sid)] = skillInfo
			self.skills.active[tostring(sid)] = sid
		else
			BattleUtils.PrintConfigLogicError(string.format('player skill error from battle ready, it is active skill but in config is not, skilId -> %s', tostring(sid)))
		end

	end

	for i,v in ipairs(self.skillIds.passiveSkill) do
		sid = checkint(v.skillId)
		skillConf = CommonUtils.GetSkillConf(sid)

		if ConfigSkillType.SKILL_HALO == checkint(skillConf.property) then
			-- 光环不操作触发器
			local skillSpineEffectData = SkillSpineEffectStruct.New(sid, effectConf)
			local skillBaseData = SkillConstructorStruct.New(
				sid,
				1,
				BattleUtils.GetSkillInfoStructBySkillId(sid, 1),
				self:GetOwner():isEnemy(),
				self:GetOwner():getOTag(),
				skillSpineEffectData
			)

			local skill = __Require('battle.skill.PlayerSkill').new(skillBaseData)
			local skillInfo = ObjectSkillStruct.New(sid, skill)
			self.skills[tostring(sid)] = skillInfo
			table.insert(self.skills.halo, sid)
		else
			BattleUtils.PrintConfigLogicError(string.format('player skill error from battle ready, it is passive skill but in config is not, skilId -> %s', tostring(sid)))
		end

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
