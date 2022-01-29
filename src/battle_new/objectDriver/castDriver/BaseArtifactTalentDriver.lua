--[[
神器天赋驱动器
@params table {
	owner BaseObject 挂载的战斗物体
	talentData ArtifactTalentConstructorStruct 神器天赋信息
}
--]]
local BaseActionDriver = __Require('battle.objectDriver.BaseActionDriver')
local BaseArtifactTalentDriver = class('BaseArtifactTalentDriver', BaseActionDriver)

------------ import ------------
------------ import ------------

------------ define ------------
------------ define ------------

--[[
@override
constructor
--]]
function BaseArtifactTalentDriver:ctor( ... )
	BaseActionDriver.ctor(self, ...)

	local args = unpack({...})

	-- -- debug --
	-- if self.owner:GetObjectConfigId() == 200002 then
	-- 	self.talentData = {
	-- 		cardId = 200002,
	-- 		talentData = {
	-- 			['1'] = {
	-- 				createTime = '2018-06-12 16:13:52',
	-- 				fragmentNum = 7,
	-- 				id = '21',
	-- 				level = 2,
	-- 				playerCardId = 386,
	-- 				playerId = '100183',
	-- 				talentId = 1,
	-- 				type = 1
	-- 			},
	-- 			['2'] = {
	-- 				createTime = '2018-06-12 16:13:52',
	-- 				fragmentNum = 9,
	-- 				id = '22',
	-- 				level = 2,
	-- 				playerCardId = 386,
	-- 				playerId = '100183',
	-- 				talentId = 2,
	-- 				type = 1
	-- 			},
	-- 			['3'] = {
	-- 				createTime = '2018-06-12 16:13:52',
	-- 				fragmentNum = 7,
	-- 				gemstoneId   = "284102",
	-- 				id = '21',
	-- 				level = 1,
	-- 				playerCardId = 386,
	-- 				playerId = '100183',
	-- 				talentId = 3,
	-- 				type = 2
	-- 			}
	-- 		}
	-- 	}
	-- else
	-- 	self.talentData = args.talentData
	-- end
	-- -- debug --

	self.talentData = args.talentData

	self:Init()
end

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
@override
初始化逻辑
--]]
function BaseArtifactTalentDriver:Init()
	self:InitTalentDataAdditions()
end
--[[
初始化天赋信息生效的加成
--]]
function BaseArtifactTalentDriver:InitTalentDataAdditions()
	local talentPAdditions = {}
	local talentSkillAdditions = {}
	local gemstonePAdditions = {}

	local cardId = self:GetOwner():GetObjectConfigId()

	local objTalentData = self:GetTalentData()
	if nil ~= objTalentData then

		local sk = sortByKey(objTalentData)

		for _, talentId_ in ipairs(sk) do
			local talentId = checkint(talentId_)
			local talentData = self:GetTalentDataByTalentId(talentId)
			local level = checkint(talentData.level)
			local gemstoneId = nil
			if nil ~= talentData.gemstoneId and 0 ~= checkint(talentData.gemstoneId) then
				gemstoneId = checkint(talentData.gemstoneId)
			end

			------------ 计算属性加成 天赋属性只有一种全部相加 ------------
			local talentptype, talentpvalue = ArtifactUtils.GetArtifactTalentInnateProperty(cardId, talentId, level, gemstoneId)
			if nil ~= talentptype then
				if nil == talentPAdditions[talentptype] then
					talentPAdditions[talentptype] = {value = 0, valueMulti = 0}
				end
				talentPAdditions[talentptype].value = talentPAdditions[talentptype].value + talentpvalue
			end
			------------ 计算属性加成 天赋属性只有一种全部相加 ------------

			------------ 计算技能加成 ------------
			local skillId = ArtifactUtils.GetArtifactTalentInnateSkill(cardId, talentId, level, gemstoneId)
			if nil ~= skillId then
				table.insert(talentSkillAdditions, {skillId = skillId, level = level})
			end
			------------ 计算技能加成 ------------

			------------ 计算宝石属性加成 宝石属性有乘法和加法系数 ------------
			if nil ~= gemstoneId then
				local gemstonePAddition = ArtifactUtils.GetGemstonePropertyAddition(gemstoneId)
				for _, addition_ in ipairs(gemstonePAddition) do

					local gemstoneptype = addition_.ptype
					local gemstonepvalue = addition_.pvalue
					local gemstonepvaluemulti = addition_.pvalueMulti

					if nil ~= gemstoneptype then
						if nil == gemstonePAdditions[gemstoneptype] then
							gemstonePAdditions[gemstoneptype] = {value = 0, valueMulti = 0}
						end
						gemstonePAdditions[gemstoneptype].value = gemstonePAdditions[gemstoneptype].value + gemstonepvalue
						gemstonePAdditions[gemstoneptype].valueMulti = gemstonePAdditions[gemstoneptype].valueMulti + gemstonepvaluemulti
					end

				end
			end
			------------ 计算宝石属性加成 宝石属性有乘法和加法系数 ------------
		end

	end

	self.talentPAdditions = talentPAdditions
	self.gemstonePAdditions = gemstonePAdditions
	self.talentSkillAdditions = talentSkillAdditions

	-- dump(talentPAdditions)
	-- dump(talentSkillAdditions)
	-- dump(gemstonePAdditions)
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- control logic begin --
---------------------------------------------------
--[[
@override
是否能进行动作
--]]
function BaseArtifactTalentDriver:CanDoAction()

end
--[[
@override
进入动作
--]]
function BaseArtifactTalentDriver:OnActionEnter()
	-- 初始化一次神器天赋的效果
	self:AddArtifactTalentEffect()
end
--[[
@override
结束动作
--]]
function BaseArtifactTalentDriver:OnActionExit()

end
--[[
@override
动作进行中
@params dt number delta time
--]]
function BaseArtifactTalentDriver:OnActionUpdate(dt)

end
--[[
@override
动作被打断
--]]
function BaseArtifactTalentDriver:OnActionBreak()
	
end
--[[
@override
消耗做出行为需要的资源
--]]
function BaseArtifactTalentDriver:CostActionResources()

end
--[[
初始化神器天赋的效果
--]]
function BaseArtifactTalentDriver:AddArtifactTalentEffect()
	------------ 生效一次天赋技能 ------------
	self:GetOwner().castDriver:AddSkillsBySkillData(self:GetTalentSkillAddition())
	------------ 生效一次天赋技能 ------------
end
---------------------------------------------------
-- control logic end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
获取天赋信息
--]]
function BaseArtifactTalentDriver:GetTalentData()
	if nil ~= self.talentData then
		return self.talentData.talentData
	else
		return nil
	end
end
--[[
根据id获取天赋信息
@params talentId int 天赋id
@return _ table 天赋数据
--]]
function BaseArtifactTalentDriver:GetTalentDataByTalentId(talentId)
	return self:GetTalentData()[tostring(talentId)]
end
--[[
获取天赋激活的属性加法系数
@return _ map {
	[ObjP] = {value = 0, valueMulti = 0},
	[ObjP] = {value = 0, valueMulti = 0},
	[ObjP] = {value = 0, valueMulti = 0}
	...
}
--]]
function BaseArtifactTalentDriver:GetTalentPropertyAddition()
	return self.talentPAdditions
end
--[[
获取天赋激活的技能
@return _ list {
	{skillId = nil, level = nil},
	{skillId = nil, level = nil},
	{skillId = nil, level = nil}
	...
}
--]]
function BaseArtifactTalentDriver:GetTalentSkillAddition()
	return self.talentSkillAdditions
end
--[[
获取宝石激活的属性乘法系数
@return _ map {
	[ObjP] = {value = 0, valueMulti = 0},
	[ObjP] = {value = 0, valueMulti = 0},
	[ObjP] = {value = 0, valueMulti = 0}
	...
}
--]]
function BaseArtifactTalentDriver:GetGemstonePropertyAddition()
	return self.gemstonePAdditions
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return BaseArtifactTalentDriver
