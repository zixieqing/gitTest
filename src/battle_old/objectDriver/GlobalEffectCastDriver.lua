--[[
全局buff施法驱动
@params table {
	owner BaseObject 挂载的战斗物体
	globalEffects list 全局buff效果
}
--]]
local BaseActionDriver = __Require('battle.objectDriver.BaseActionDriver')
local GlobalEffectCastDriver = class('GlobalEffectCastDriver', BaseActionDriver)

------------ import ------------
local cardMgr = AppFacade.GetInstance():GetManager('CardManager')
------------ import ------------

--[[
constructor
--]]
function GlobalEffectCastDriver:ctor( ... )
	BaseActionDriver.ctor(self, ...)

	local args = unpack({...})

	self.globalEffects = {}

	self:Init()
end
---------------------------------------------------
-- init logic begin --
---------------------------------------------------
--[[
初始化逻辑
--]]
function GlobalEffectCastDriver:Init()
	self:InitValue()
end
--[[
初始化数值
--]]
function GlobalEffectCastDriver:InitValue()
	-- 全局buff逻辑
	self.globalBuffs = {
		[ConfigGlobalBuffSeekTargetRule.T_OBJ_FRIEND] = {},
		[ConfigGlobalBuffSeekTargetRule.T_OBJ_ENEMY] = {},
		[ConfigGlobalBuffSeekTargetRule.T_OBJ_ALL] = {},
		[ConfigGlobalBuffSeekTargetRule.T_OBJ_OTHER] = {}
	}
	-- 工会神兽逻辑
	self.unionPetskills = {
		halo = {}
	}

	-- 全局buff
	self.skills = {
		halo = {},
		scene = {}
	}
end
--[[
初始化buff效果
@params globalEffects list 全局效果
--]]
function GlobalEffectCastDriver:InitEffects(globalEffects)
	if nil == globalEffects then return end

	self.globalEffects = globalEffects

	local geffectId = nil
	local geffectConfig = nil

	for i,v in ipairs(self.globalEffects) do
		geffectId = checkint(v)
		geffectConfig = CommonUtils.GetConfig('tower', 'towerContract', geffectId)
		if nil ~= geffectConfig then
			if ConfigGlobalEffectType.INSIDE == checkint(geffectConfig.contractType) then
				self:AddAGlobalBuff(geffectConfig)
			end
		end
	end
end
--[[
根据工会神兽信息初始化神兽技能
@params unionPetsData map 神兽信息
--]]
function GlobalEffectCastDriver:InitUnionPetSkills(unionPetsData)
	if nil == unionPetsData then return end
	local sk = sortByKey(unionPetsData)
	for i, key in ipairs(sk) do
		local unionPetId = checkint(key)
		local unionPetData = unionPetsData[key]
		local unionBeastBabyConfig = cardMgr.GetBeastBabyConfig(unionPetId)

		if nil ~= unionBeastBabyConfig then

			local skills = checktable(unionBeastBabyConfig.skill)
			for i, skillId in ipairs(skills) do
				local skillConfig = CommonUtils.GetSkillConf(checkint(skillId))
				if nil ~= skillConfig then

					-- 首先判断一次战斗类型是否满足
					if nil ~= skillConfig.battleType then
						for _, battleType in ipairs(skillConfig.battleType) do
							if QuestBattleType.ALL == checkint(battleType) then
								self:AddAUnionPetSkill(skillId, checkint(unionPetData.satietyLevel))
								break
							elseif BMediator:GetBData():getBattleConstructData().questBattleType == checkint(battleType) then
								self:AddAUnionPetSkill(skillId, checkint(unionPetData.satietyLevel))
								break
							end
						end
					end

				end
			end

		end
	end
end
--[[
初始化技能
@params skills list 技能集合
--]]
function GlobalEffectCastDriver:InitSkills(skills)
	if nil == skills then return end

	for i,v in ipairs(skills) do
		local skillId = checkint(v.skillId)
		local skillLevel = checkint(v.level)

		local skillConfig = CommonUtils.GetSkillConf(skillId)
		if nil ~= skillConfig then
			local skillType = checkint(skillConfig.property)
			local skillClassPath = 'battle.skill.BaseSkill'

			if ConfigSkillType.SKILL_HALO == skillType then
				skillClassPath = 'battle.skill.HaloSkill'
				table.insert(self.skills.halo, skillId)
			elseif ConfigSkillType.SKILL_SCENE == skillType then
				skillClassPath = 'battle.skill.SceneSkill'
				table.insert(self.skills.scene, skillId)
			end

			local spineActionData = SkillSpineEffectStruct.New(skillId, nil)
			local skillBaseData = SkillConstructorStruct.New(
				skillId,
				skillLevel,
				BattleUtils.GetSkillInfoStructBySkillId(skillId, skillLevel),
				self:GetOwner():isEnemy(),
				self:GetOwner():getOTag(),
				spineActionData
			)

			local skill = __Require(skillClassPath).new(skillBaseData)
			local skillInfo = ObjectSkillStruct.New(skillId, skill)
			self.skills[tostring(skillId)] = skillInfo

			-- 添加技能图标
			BMediator:GetViewComponent():AddAGlobalEffect(skillId)
		end
	end
end
---------------------------------------------------
-- init logic end --
---------------------------------------------------

---------------------------------------------------
-- control logic begin --
---------------------------------------------------
--[[
是否能进行动作
--]]
function GlobalEffectCastDriver:CanDoAction()

end
--[[
进入动作
@params targetTag int 目标tag
--]]
function GlobalEffectCastDriver:OnActionEnter(targetTag)
	if nil == targetTag then
		-- 如果目标tag为nil 则是针对非逻辑物体进行干涉
		local buffData = nil
		for i = #self.globalBuffs[ConfigGlobalBuffSeekTargetRule.T_OBJ_OTHER], 1, -1 do
			buffData = self.globalBuffs[ConfigGlobalBuffSeekTargetRule.T_OBJ_OTHER][i]
			buffData.buff:CauseEffect()
		end

		-- 初始化一次情景效果
		local params = ObjectCastParameterStruct.New(
			1,
			1,
			nil,
			cc.p(0, 0),
			false,
			false
		)

		for i = #self.skills.scene, 1, -1 do
			local skillId = self.skills.scene[i]
			local skill = self:GetSkillBySkillId(skillId)
			if nil ~= skill then
				skill.skill:CastBegin(params)
			end
		end
	else
		local target = BMediator:IsObjAliveByTag(targetTag)
		if nil ~= target then
			local seekTargetRule = ConfigGlobalBuffSeekTargetRule.T_OBJ_FRIEND
			if target:isEnemy(o) then
				seekTargetRule = ConfigGlobalBuffSeekTargetRule.T_OBJ_ENEMY
			end

			local buffData = nil

			for i = #self.globalBuffs[seekTargetRule], 1, -1 do
				buffData = self.globalBuffs[seekTargetRule][i]
				buffData.buff:CauseEffect(targetTag)
			end

			for i = #self.globalBuffs[ConfigGlobalBuffSeekTargetRule.T_OBJ_ALL], 1, -1 do
				buffData = self.globalBuffs[ConfigGlobalBuffSeekTargetRule.T_OBJ_ALL][i]
				buffData.buff:CauseEffect(targetTag)
			end
		end
	end

	self:OnActionExit()
end
--[[
结束动作
--]]
function GlobalEffectCastDriver:OnActionExit()

end
--[[
动作进行中
@params dt number delta time
--]]
function GlobalEffectCastDriver:OnActionUpdate(dt)

end
--[[
动作被打断
--]]
function GlobalEffectCastDriver:OnActionBreak()
	
end
--[[
消耗做出行为需要的资源
--]]
function GlobalEffectCastDriver:CostActionResources()

end
--[[
根据配置添加一个全局buff数据
--]]
function GlobalEffectCastDriver:AddAGlobalBuff(config)
	if nil == config then return end

	local sk = sortByKey(config.fullBuff)
	local gbufftype = nil
	local gbuffdata = nil
	local gbbufftargetdata = nil

	for i, key in ipairs(sk) do
		gbufftype = checkint(key)
		gbuffdata = config.fullBuff[tostring(gbufftype)]
		gbbufftargetdata = config.fullBuffTarget[tostring(gbufftype)]

		local globalBuffInfo = GlobalBuffConstructStruct.New(
			checkint(config.id),
			gbuffdata.effect,
			0,
			checkint(gbuffdata.type),
			self:GetOwner():getOTag()
		)

		local buffClassName = 'battle.globalBuff.BaseGlobalBuff'
		if ConfigGlobalBuffType.BATTLE_TIME_A == gbufftype then

			buffClassName = 'battle.globalBuff.GlobalBattleTimeBuff'

		elseif ConfigGlobalBuffType.IMMUNE_ATTACK_PHYSICAL == gbufftype or
			ConfigGlobalBuffType.IMMUNE_SKILL_PHYSICAL == gbufftype then

			buffClassName = 'battle.globalBuff.GlobalImmuneBuff'

		elseif ConfigGlobalBuffType.OHP_A == gbufftype or
			ConfigGlobalBuffType.ATTACK_A == gbufftype or
			ConfigGlobalBuffType.DEFENCE_A == gbufftype or
			ConfigGlobalBuffType.CDAMAGE_A == gbufftype then

			buffClassName = 'battle.globalBuff.GlobalAbilityBuff'

		end

		local buff = __Require(buffClassName).new(globalBuffInfo)
		local buffData = {
			buff = buff
		}
		table.insert(self.globalBuffs[checkint(gbbufftargetdata.type)], 1, buffData)
	end
end
--[[
添加一个神兽技能
@params skillId int 技能id
@params skillLevel int 技能等级
--]]
function GlobalEffectCastDriver:AddAUnionPetSkill(skillId, skillLevel)
	local skillConfig = CommonUtils.GetSkillConf(skillId)
	if nil ~= skillConfig then
		-- TODO -- 先只初始化光环
		if ConfigSkillType.SKILL_HALO == checkint(skillConfig.property) then
			-- 初始化技能动作 特效信息
			local skillClassPath = 'battle.skill.HaloSkill'
			local spineActionData = SkillSpineEffectStruct.New(skillId, nil)
			local skillBaseData = SkillConstructorStruct.New(
				skillId,
				skillLevel,
				BattleUtils.GetSkillInfoStructBySkillId(skillId, skillLevel),
				self:GetOwner():isEnemy(),
				self:GetOwner():getOTag(),
				spineActionData
			)
			local skill = __Require(skillClassPath).new(skillBaseData)
			local skillInfo = ObjectSkillStruct.New(skillId, skill)
			self.unionPetskills[tostring(skillId)] = skillInfo
			table.insert(self.unionPetskills.halo, skillId)
		end
	end
end
--[[
初始化所有光环效果
--]]
function GlobalEffectCastDriver:CastAllHalos()
	-- ### serialized ### --
	local params = ObjectCastParameterStruct.New(
		1,
		1,
		nil,
		cc.p(0, 0),
		false,
		false
	)
	for i, sid in ipairs(self.unionPetskills.halo) do
		self.unionPetskills[tostring(sid)].skill:CastBegin(params)
	end

	for i, sid in ipairs(self.skills.halo) do
		self.skills[tostring(sid)].skill:CastBegin(params)
	end
end
---------------------------------------------------
-- control logic end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
根据id获取技能模型
@params skillId int 技能id
--]]
function GlobalEffectCastDriver:GetSkillBySkillId(skillId)
	return self.skills[tostring(skillId)]
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return GlobalEffectCastDriver
