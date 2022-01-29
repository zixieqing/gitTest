--[[
全局buff的基类
--]]
local BaseObjectModel = __Require('battle.object.logicModel.objectModel.BaseObjectModel')
local GlobalEffectObjectModel = class('GlobalEffectObjectModel', BaseObjectModel)

------------ import ------------
------------ import ------------

------------ define ------------
------------ define ------------

--[[
constructor
--]]
function GlobalEffectObjectModel:ctor( ... )
	BaseObjectModel.ctor(self, ...)
end

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化驱动组件
--]]
function GlobalEffectObjectModel:InitDrivers()
	-- 初始化施法驱动器
	self.castDriver = __Require('battle.objectDriver.castDriver.GlobalEffectCastDriver').new({
		owner = self
	})
end
--[[
增加全局技能
@params skills list
--]]
function GlobalEffectObjectModel:AddSkills(skills)
	self.castDriver:AddSkills(skills)
end
--[[
添加工会宠物效果
@params unionPetsData map 神兽信息
--]]
function GlobalEffectObjectModel:AddUnionPetsEffect(unionPetsData)
	if nil == unionPetsData then return end

	local skills = {}

	local unionPetId = nil
	local unionPetData = nil
	local unionBeastBabyConfig = nil

	local sk = sortByKey(unionPetsData)
	for _, key in ipairs(sk) do

		unionPetId = checkint(key)
		unionPetData = unionPetsData[key]
		unionBeastBabyConfig = UnionBeastUtils.GetUnionPetConfig(unionPetId)

		if nil ~= unionBeastBabyConfig then

			local unionPetSkills = checktable(unionBeastBabyConfig.skill)
			for _, skillId_ in ipairs(skills) do
				-- 工会宠物技能等级取决于饱食度等级
				local skillId = checkint(skillId_)
				local level = checkint(unionPetData.satietyLevel)
				table.insert(skills, {skillId = skillId, level = level})
			end

		end

	end

	self:AddSkills(skills)
end
--[[
添加爬塔效果
@params towerEffects list 爬塔效果
--]]
function GlobalEffectObjectModel:AddTowerEffects(towerEffects)
	if nil == towerEffects then return end

	local skills = {}

	local towerEffectId = nil

	for _, towerEffectId_ in ipairs(towerEffects) do

		towerEffectId = checkint(towerEffectId_)
		self.castDriver:AddATowerEffect(towerEffectId)



		--[[
		-- TODO --
		-- 新的爬塔效果逻辑
		-- /== TODO =================================================================================================================================\
		--  = 新的爬塔效果逻辑需要改配表 [爬塔契约表中添加字段skills 这个是爬塔契约的实际效果]
		-- \== TODO =================================================================================================================================/
		if nil ~= towerEffectConfig and nil ~= towerEffectConfig.skills then
			for _, skillId_ in ipairs(towerEffectConfig.skills) do
				local skillId = checkint(skillId_)
				local level = 1
				table.insert(skills, {skillId = skillId, level = level})
			end
		end
		-- TODO --
		--]]

	end

	self:AddSkills(skills)
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
function GlobalEffectObjectModel:Update(dt)
	if self:IsPause() then return end
end
---------------------------------------------------
-- logic end --
---------------------------------------------------

---------------------------------------------------
-- cast logic begin --
---------------------------------------------------
--[[
全局物体搭载情景buff逻辑
@params buffInfo ObjectBuffConstructorStruct 构造buff的数据
@return _ bool 是否成功加上了该buff
--]]
function GlobalEffectObjectModel:BeCasted(buffInfo)
	-- 全局效果物体处理的buff类型
	local targetBuffsConfig = {
		[ConfigBuffType.LIVE_CHEAT_FREE] = true,
		[ConfigBuffType.BATTLE_TIME] = true
	}

	if true == targetBuffsConfig[buffInfo.btype] then

		if BuffCauseEffectTime.INSTANT == buffInfo.causeEffectTime then

			-- 瞬时起效类型 不加入缓存
			local buff = __Require(buffInfo.className).new(buffInfo)
			buff:OnCauseEffectEnter()

		else

			local buff = self:GetBuffByBuffId(buffInfo:GetStructBuffId())
			if nil == buff then
				buff = __Require(buffInfo.className).new(buffInfo)
				self:AddBuff(buff)
			else
				buff:OnRefreshBuffEnter(buffInfo)
			end

		end

		return true
	end
	
	return false
end
--[[
刷一次物体的光环数据
--]]
function GlobalEffectObjectModel:CastAllHalos()
	--[[
	new logic todo

	刷新光环时需要把老的光环buff数据移除
	--]]
	self.castDriver:CastAllHalos()
end
--[[
刷一次情景类技能
--]]
function GlobalEffectObjectModel:CastAllSceneSkills()
	self.castDriver:CastAllSceneSkills()
end
---------------------------------------------------
-- cast logic end --
---------------------------------------------------

return GlobalEffectObjectModel
