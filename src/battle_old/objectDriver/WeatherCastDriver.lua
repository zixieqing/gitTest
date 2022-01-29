--[[
天气施法驱动器
@params table {
	weatherId int 天气id
	skillIds itable 技能集合 有序
}
--]]
local BaseCastDriver = __Require('battle.objectDriver.BaseCastDriver')
local WeatherCastDriver = class('WeatherCastDriver', BaseCastDriver)

------------ import ------------
local cardMgr = AppFacade.GetInstance():GetManager('CardManager')
------------ import ------------

--[[
@override
constructor
--]]
function WeatherCastDriver:ctor( ... )
	local args = unpack({...})

	self.weatherId = args.weatherId
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
function WeatherCastDriver:InitUnitValue()
	
end
---------------------------------------------------
-- init logic end --
---------------------------------------------------

---------------------------------------------------
-- control begin --
---------------------------------------------------
--[[
@override
是否能进行动作
@params skillId int 技能id
@return _ int 可释放的技能id
--]]
function WeatherCastDriver:CanDoAction(actionTriggerType)
	if ActionTriggerType.CD == actionTriggerType then
		return self:CanCastByCD()
	end
	return nil
end
--[[
@override
进入动作
@params skillId int 技能id
--]]
function WeatherCastDriver:OnActionEnter(skillId)
	print('\n**************\n', ' cast skill(weather) -> ', skillId, '\n**************\n')
	---------- logic ----------
	-- 消耗释放技能的资源
	self:CostActionResources(skillId)
	-- 广播信号
	BMediator:SendObjEvent(ObjectEvent.OBJECT_CAST_ENTER, {
		tag = self:GetOwner():getOTag(), isEnemy = self:GetOwner():isEnemy(true), skillId = skillId
	})
	---------- logic ----------
	-- 施法
	self:Cast(skillId)
end
--[[
@override
结束动作
--]]
function WeatherCastDriver:OnActionExit()
	
end
--[[
是否可以释放cd触发的技能
@return _ int 可释放的技能id
--]]
function WeatherCastDriver:CanCastByCD()
	-- ### serialized ### --
	for i, skillId in ipairs(self.skills.random) do
		if true == self:CanCastSkillJudgeByTriggerType(skillId) then
			return skillId
		end
	end
	return nil
end
--[[
@override
施法逻辑
@params skillId int 技能id
--]]
function WeatherCastDriver:Cast(skillId)
	local bulletOriPosition = cc.p(0, 0)
	local params = ObjectCastParameterStruct.New(
		1,
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
@override
是否可以释放对应id的技能
@params int skillId int 技能id
@return result bool 是否可以释放技能
--]]
function WeatherCastDriver:CanCastBySkillId(skillId)
	local result = false
	-- 普通技能检测
	if self:CanCastSkillJudgeByTriggerType(skillId) then
		result = true
	end
	return result
end
--[[
@override
处理技能触发类型判定
@params skillId int 技能id
@return result bool 是否满足条件释放该技能
--]]
function WeatherCastDriver:CanCastSkillJudgeByTriggerType(skillId)
	local skillInfo = CommonUtils.GetSkillConf(skillId)
	local result = true
	local triggerType = 0
	local triggerValue = 0

	-- 首先判断内置cd是否满足
	local insideCD = self.skillInsideCountdown[tostring(skillId)]
	if nil ~= insideCD and insideCD > 0 then
		return false
	end

	-- ### serialized ### --
	local sk = sortByKey(skillInfo.triggerType)
	for i, key in ipairs(sk) do

		triggerType = checkint(key)
		triggerValue = checknumber(skillInfo.triggerType[key])

		if ConfigSkillTriggerType.RESIDENT == triggerType then

			-- 常驻触发类型视为光环 光环只在特定事件初始化
			return false

		elseif ConfigSkillTriggerType.RANDOM == triggerType then

			-- 随机
			local randomResult = (BMediator:GetRandomManager():GetRandomInt(1000) <= (triggerValue * 1000))
			if false == randomResult then
				return false
			end

		elseif ConfigSkillTriggerType.ENERGY == triggerType then

			-- 能量
			print('!!!!!!! waring !!!!!!! weather skill have no energy !!!!!!!!!!')
			return false

		elseif ConfigSkillTriggerType.CD == triggerType then

			-- cd
			if self:GetActionTrigger(ActionTriggerType.CD, skillId) > 0 then
				return false
			end

		end
	end

	return result
end
--[[
@override
刷新触发器
@params actionTriggerType ActionTriggerType 技能触发类型
@params delta number 变化量
--]]
function WeatherCastDriver:UpdateActionTrigger(actionTriggerType, delta)
	if ActionTriggerType.CD == actionTriggerType then
		for k,v in pairs(self.actionTrigger[ActionTriggerType.CD]) do
			self.actionTrigger[ActionTriggerType.CD][k] = math.max(0, v - delta)
		end

		-- 刷新内置cd
		for k,v in pairs(self.skillInsideCountdown) do
			self.skillInsideCountdown[k] = math.max(0, v - delta)
		end
	end
end
--[[
@override
消耗做出行为需要的资源
@params skillId int 技能id
--]]
function WeatherCastDriver:CostActionResources(skillId)
	local skillConf = CommonUtils.GetSkillConf(skillId)

	if nil ~= skillConf.triggerType[tostring(ConfigSkillTriggerType.CD)] then
		-- 刷新cd
		self:SetActionTrigger(
			ActionTriggerType.CD,
			skillId,
			checknumber(skillConf.triggerType[tostring(ConfigSkillTriggerType.CD)])
		)
	end

	-- 刷新技能内置cd
	self.skillInsideCountdown[tostring(skillId)] = checknumber(skillConf.insideCd)
end
--[[
@override
操作触发器
--]]
function WeatherCastDriver:GetActionTrigger(actionTriggerType, skillId)
	if nil ~= self.actionTrigger[actionTriggerType] then
		return self.actionTrigger[actionTriggerType][tostring(skillId)]
	end
	return nil
end
function WeatherCastDriver:SetActionTrigger(actionTriggerType, skillId, value)
	if nil ~= self.actionTrigger[actionTriggerType] then
		self.actionTrigger[actionTriggerType][tostring(skillId)] = value
	end
	return nil
end
--[[
@override
初始化所有光环效果
--]]
function WeatherCastDriver:CastAllHalos()
	local skill = nil
	-- ### serialized ### --
	for i, sid in ipairs(self.skills.halo) do
		skill = self.skills[tostring(sid)].skill
		if true == skill:IsSkillHalo() then
			local params = ObjectCastParameterStruct.New(
				1,
				1,
				nil,
				bulletOriPosition,
				false,
				false
			)
			skill:CastBegin(params)
		end
	end
end
---------------------------------------------------
-- control end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
初始化技能数据结构
--]]
function WeatherCastDriver:InitSkills()
	self.skills = {
		halo = {},
		random = {}
	}

	-- 技能触发器
	self.actionTrigger = {
		[ActionTriggerType.CD] = {}
	}

	self.skillSpineActionData = {}

	-- 技能内置cd
	self.skillInsideCountdown = {}

	local weatherConf = CommonUtils.GetConfig('quest', 'weather', self.weatherId)
	local effectConf = CardUtils.GetCardEffectConfigBySkinId(ConfigSpecialCardId.WEATHER, ConfigSpecialCardId.WEATHER)

	local sid = 0
	local skillConf = nil
	local triggerType = 0
	local weatherTriggerType = 0
	local triggerValue = nil
	for i, sconf in ipairs(self.skillIds) do
		sid = checkint(sconf)
		skillConf = CommonUtils.GetSkillConf(sid)

		if nil ~= skillConf then
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
				false,
				self:GetOwner():getOTag(),
				skillSpineEffectData,
				{weatherId = self.weatherId}
			)

			local skill = __Require('battle.skill.WeatherSkill').new(skillBaseData)
			local skillInfo = ObjectSkillStruct.New(sid, skill)
			self.skills[tostring(sid)] = skillInfo

			weatherTriggerType = checkint(weatherConf.weatherType)
			if ConfigWeatherTriggerType.HALO == weatherTriggerType then
				table.insert(self.skills.halo, sid)
			elseif ConfigWeatherTriggerType.RANDOM == weatherTriggerType then
				table.insert(self.skills.random, sid)
			end
		end

	end

end
--[[
根据技能类型获取一个随机的技能id
@params skillType ConfigSkillType 技能类型
@return _ int 技能id 
--]]
function WeatherCastDriver:GetRandomSkillIdBySkillType(skillType)
	return nil
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return WeatherCastDriver
