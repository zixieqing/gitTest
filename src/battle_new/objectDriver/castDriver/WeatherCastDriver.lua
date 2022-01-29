--[[
天气施法驱动器
@params table {
	weatherId int 天气id
	skillIds itable 技能集合 有序
}
--]]
local BaseCastDriver = __Require('battle.objectDriver.castDriver.BaseCastDriver')
local WeatherCastDriver = class('WeatherCastDriver', BaseCastDriver)

------------ import ------------
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
	---------- logic ----------
	-- 缓存当前施法的技能id
	self:SetCastingSkillId(skillId)

	-- 消耗释放技能的资源
	self:CostActionResources(skillId)
	---------- logic ----------
		
	-- 进入施法
	self:OnCastEnter(skillId)
end
--[[
@override
结束动作
--]]
function WeatherCastDriver:OnActionExit()
	self:OnCastExit()
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
准备施法
@params skillId int 技能id
--]]
function WeatherCastDriver:OnCastEnter(skillId)
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
function WeatherCastDriver:OnCastExit()
	------------ 重置一些参数 ------------
	self:ClearNextSkillExtra()
	self:SetCastingEcho(false)
	self:SetCastingSkillId(nil)
	------------ 重置一些参数 ------------
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
			BattleUtils.PrintBattleWaringLog('!!!!!!! waring !!!!!!! weather skill have no energy !!!!!!!!!!')
			return false

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
		self:UpdateAllSkillsInsideCD(delta)
	end
end
--[[
@override
消耗做出行为需要的资源
@params skillId int 技能id
--]]
function WeatherCastDriver:CostActionResources(skillId)
	local skillConfig = CommonUtils.GetSkillConf(skillId)

	------------ 刷新内置cd ------------
	self:SetSkillInsideCD(skillId, checknumber(skillConfig.insideCd))
	------------ 刷新内置cd ------------

	local skillTriggerInfo = self:GetSkillTriggerInfoBySkillId(skillId)

	------------ cd消耗 ------------
	if nil ~= skillTriggerInfo[ConfigSkillTriggerType.CD] then

		-- cd
		self:SetActionTrigger(
			ActionTriggerType.CD,
			skillId,
			skillTriggerInfo[ConfigSkillTriggerType.CD]
		)

	end
	------------ cd消耗 ------------
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
	for _, skillId in ipairs(self.skills.halo) do

		local params = ObjectCastParameterStruct.New(
			1,
			1,
			nil,
			cc.p(0, 0),
			false,
			false
		)
		self:DoCastEnterLogic(skillId, params)

	end
end
---------------------------------------------------
-- control end --
---------------------------------------------------

---------------------------------------------------
-- init skill begin --
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

	-- 初始化技能
	local skillId = nil
	local skillConfig = nil

	for _, skillId_ in ipairs(self.skillIds) do
		skillId = checkint(skillId_)
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
function WeatherCastDriver:AddASkill(skillId, level)
	local skillConfig = CommonUtils.GetSkillConf(skillId)

	if nil == skillConfig then
		BattleUtils.PrintConfigLogicError('cannot find skill config in WeatherCastDriver -> InitSkills : ' .. tostring(skillId))
		return
	end

	if not self:CanInitSkillBySkillId(checkint(skillId)) then return end

	local skillClassPath = 'battle.skill.WeatherSkill'
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
	local effect = CardUtils.GetCardEffectConfigBySkinId(ConfigSpecialCardId.WEATHER, ConfigSpecialCardId.WEATHER)
	local spineActionData = BSCUtils.GetSkillSpineEffectStruct(skillId, effect, G_BattleLogicMgr:GetCurrentWave())

	-- 添加一次技能的动画信息
	self:GetOwner():SetActionAnimationConfigBySkillId(skillId, spineActionData)

	local skillBaseData = SkillConstructorStruct.New(
		skillId,
		level,
		BattleUtils.GetSkillInfoStructBySkillId(skillId, level),
		self:GetOwner():IsEnemy(true),
		self:GetOwner():GetOTag(),
		spineActionData,
		{weatherId = self:GetWeatherId()}
	)

	local skill = __Require(skillClassPath).new(skillBaseData)
	local skillInfo = ObjectSkillStruct.New(skillId, skill)
	self:SetSkillStructBySkillId(skillId, skillInfo)

	local weatherTriggerType = checkint(self:GetWeatherConfig().weatherType)

	if ConfigWeatherTriggerType.HALO == weatherTriggerType then

		table.insert(self.skills.halo, skillId)

	elseif ConfigWeatherTriggerType.RANDOM == weatherTriggerType then

		table.insert(self.skills.random, skillId)

	end
end
---------------------------------------------------
-- init skill end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
根据技能类型获取一个随机的技能id
@params skillType ConfigSkillType 技能类型
@return _ int 技能id 
--]]
function WeatherCastDriver:GetRandomSkillIdBySkillType(skillType)
	return nil
end
--[[
获取天气id
@return _ int 天气id
--]]
function WeatherCastDriver:GetWeatherId()
	return self.weatherId
end
--[[
获取天气配置
--]]
function WeatherCastDriver:GetWeatherConfig()
	return CommonUtils.GetConfig('quest', 'weather', self:GetWeatherId())
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return WeatherCastDriver
