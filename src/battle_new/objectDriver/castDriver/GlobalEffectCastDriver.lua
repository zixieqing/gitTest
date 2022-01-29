--[[
全局buff施法驱动
@params table {
	owner BaseObject 挂载的战斗物体
}
--]]
local BaseCastDriver = __Require('battle.objectDriver.castDriver.BaseCastDriver')
local GlobalEffectCastDriver = class('GlobalEffectCastDriver', BaseCastDriver)

------------ import ------------
------------ import ------------

------------ define ------------
------------ define ------------

--[[
constructor
--]]
function GlobalEffectCastDriver:ctor( ... )
	BaseCastDriver.ctor(self, ...)

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
	self:InitInnateValue()
	self:InitUnitValue()
end
--[[
初始化数值
--]]
function GlobalEffectCastDriver:InitValue()
	
end
--[[
初始化固有数值
--]]
function GlobalEffectCastDriver:InitInnateValue()
	BaseCastDriver.InitInnateValue(self)
end
--[[
初始化独有数值
--]]
function GlobalEffectCastDriver:InitUnitValue()
	self.skills = {
		halo = {},
		scene = {},
		towerContract = {}
	}
end
---------------------------------------------------
-- init logic end --
---------------------------------------------------

---------------------------------------------------
-- skill logic begin --
---------------------------------------------------
--[[
增加一些技能
@params skills list 技能信息
--]]
function GlobalEffectCastDriver:AddSkills(skills)
	if nil == skills then return end

	local skillId = nil
	local skillLevel = nil

	for _, v in ipairs(skills) do

		skillId = checkint(v.skillId)
		skillLevel = checkint(v.level)

		self:AddASkill(skillId, skillLevel)

	end
end
--[[
增加一个技能
@params skillId int 技能id
@params level int 技能等级
--]]
function GlobalEffectCastDriver:AddASkill(skillId, level)
	local skillConfig = CommonUtils.GetSkillConf(skillId)

	if nil == skillConfig then
		BattleUtils.PrintConfigLogicError('cannot find skill config in GlobalEffectCastDriver -> AddASkill : ' .. tostring(skillId))
		return
	end

	if not self:CanInitSkillBySkillId(checkint(skillId)) then return end

	local skillType = checkint(skillConfig.property)
	local skillClassPath = 'battle.skill.BaseSkill'

	if ConfigSkillType.SKILL_HALO == skillType then

		skillClassPath = 'battle.skill.HaloSkill'
		table.insert(self.skills.halo, skillId)

	elseif ConfigSkillType.SKILL_SCENE == skillType then

		skillClassPath = 'battle.skill.SceneSkill'
		table.insert(self.skills.scene, skillId)

	end

	-- 初始化内置cd 第一次初始化为0
	self:SetSkillInsideCD(skillId, 0)

	---------- 创建技能模型 ----------
	local spineActionData = BSCUtils.GetSkillSpineEffectStruct(skillId, nil, G_BattleLogicMgr:GetCurrentWave())
	local skillBaseData = SkillConstructorStruct.New(
		skillId,
		skillLevel,
		BattleUtils.GetSkillInfoStructBySkillId(skillId, skillLevel),
		self:GetOwner():IsEnemy(),
		self:GetOwner():GetOTag(),
		spineActionData
	)
	local skill = __Require(skillClassPath).new(skillBaseData)
	local skillInfo = ObjectSkillStruct.New(skillId, skill)
	self:SetSkillStructBySkillId(skillId, skillInfo)
	---------- 创建技能模型 ----------

	local skillSection = CommonUtils.GetSkillSectionTypeBySkillId(skillId)

	if SkillSectionType.SPECIAL_SKILL == skillSection then

		--***---------- 刷新渲染层 ----------***--
		-- 在战斗场景左上方添加全局buff图标
		G_BattleLogicMgr:AddRenderOperate(
			'G_BattleRenderMgr',
			'AddASpecialSkillIcon',
			skillId
		)
		--***---------- 刷新渲染层 ----------***--

	end
end
--[[
添加一个爬塔契约
@params towerEffectId int 爬塔契约id
--]]
function GlobalEffectCastDriver:AddATowerEffect(towerEffectId)
	local towerEffectConfig = CommonUtils.GetConfig('tower', 'towerContract', towerEffectId)
	if nil ~= towerEffectConfig and ConfigGlobalEffectType.INSIDE == checkint(towerEffectConfig.contractType) then
		local skill = __Require('battle.skill.TowerContractSkill').new({
			towerContractId = towerEffectId
		})

		local skillInfo = ObjectSkillStruct.New(towerEffectId, skill)
		self:SetSkillStructBySkillId(towerEffectId, skillInfo)
		table.insert(self.skills.towerContract, towerEffectId)
	end
end
---------------------------------------------------
-- skill logic end --
---------------------------------------------------

---------------------------------------------------
-- control logic begin --
---------------------------------------------------
--[[
@override
是否能进行动作
--]]
function GlobalEffectCastDriver:CanDoAction()

end
--[[
@override
进入动作
@params targetTag int 目标tag
--]]
function GlobalEffectCastDriver:OnActionEnter()

end
--[[
@override
结束动作
--]]
function GlobalEffectCastDriver:OnActionExit()

end
--[[
@override
动作进行中
@params dt number delta time
--]]
function GlobalEffectCastDriver:OnActionUpdate(dt)

end
--[[
@override
动作被打断
--]]
function GlobalEffectCastDriver:OnActionBreak()
	
end
--[[
@override
消耗做出行为需要的资源
--]]
function GlobalEffectCastDriver:CostActionResources()

end
--[[
@override
初始化所有光环效果
--]]
function GlobalEffectCastDriver:CastAllHalos()
	local params = ObjectCastParameterStruct.New(
		1,
		1,
		nil,
		cc.p(0, 0),
		false,
		false
	)
	for i, skillId in ipairs(self.skills.halo) do
		self:DoCastEnterLogic(skillId, params)
	end
	for i, skillId in ipairs(self.skills.towerContract) do
		self:DoCastEnterLogic(skillId, params)
	end
end
--[[
@override
初始化一次情景类技能
--]]
function GlobalEffectCastDriver:CastAllSceneSkills()
	local params = ObjectCastParameterStruct.New(
		1,
		1,
		nil,
		cc.p(0, 0),
		false,
		false
	)
	for i, skillId in ipairs(self.skills.scene) do
		self:DoCastEnterLogic(skillId, params)
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
