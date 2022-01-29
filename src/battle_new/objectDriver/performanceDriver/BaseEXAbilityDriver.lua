--[[
超能力驱动基类
@params table {
	owner BaseObject 挂载的战斗物体
}
--]]
local BaseActionDriver = __Require('battle.objectDriver.BaseActionDriver')
local BaseEXAbilityDriver = class('BaseEXAbilityDriver', BaseActionDriver)

------------ import ------------
------------ import ------------

------------ define ------------
------------ define ------------

--[[
constructor
--]]
function BaseEXAbilityDriver:ctor( ... )
	BaseActionDriver.ctor(self, ...)

	local args = unpack({...})

	self.exAbilityData = args.exAbilityData

	-- debug --
	-- if false == self:GetOwner():IsEnemy(true) then
	-- 	self.exAbilityData = EXAbilityConstructorStruct.New(
	-- 		self:GetOwner():GetObjectConfigId(),
	-- 		{29999}
	-- 	)
	-- end
	-- debug --

	self:Init()
end

---------------------------------------------------
-- init logic begin --
---------------------------------------------------
--[[
@override
初始化逻辑
--]]
function BaseEXAbilityDriver:Init()
	self:InitInnateValue()
	self:InitUnitValue()

	self:InitEXAbilitySkills()
end
--[[
初始化固有属性
--]]
function BaseEXAbilityDriver:InitInnateValue()
	-- 变形中的数据
	self.viewTransformData = nil
end
--[[
初始化独有属性
--]]
function BaseEXAbilityDriver:InitUnitValue()

end
--[[
初始化超能力技能的效果
--]]
function BaseEXAbilityDriver:InitEXAbilitySkills()
	if nil ~= self.exAbilityData and nil ~= self.exAbilityData.skills then
		local skillInfo = {}
		for _, skillId_ in ipairs(self.exAbilityData.skills) do
			table.insert(skillInfo, {skillId = checkint(skillId_), level = 1})
		end
		------------ 生效一次天赋技能 ------------
		self:GetOwner().castDriver:AddSkillsBySkillData(skillInfo)
		------------ 生效一次天赋技能 ------------
	end
end
---------------------------------------------------
-- init logic end --
---------------------------------------------------

---------------------------------------------------
-- view transfrom logic begin --
---------------------------------------------------
--[[
是否可以进行变形
@params oriSkinId int 源皮肤id
@return _ bool 是否可以变形
--]]
function BaseEXAbilityDriver:CanDoViewTransform(oriSkinId)
	-- 判断是否能变形 当前皮肤不吻合 状态不允许 无法变形
	if oriSkinId ~= self:GetOwner():GetObjectSkinId() then
		return false
	end
	if not self:GetOwner():IsAlive() or OState.VIEW_TRANSFORM == self:GetOwner():GetState() then
		return false
	end
	return true
end
--[[
进入变形
@params oriSkinId int 源皮肤id
@params oriActionName string 源皮肤变形的动作
@params targetSkinId int 目标皮肤id
@params targetActionName string 目标皮肤变形的衔接动作
--]]
function BaseEXAbilityDriver:OnViewTransformEnter(oriSkinId, oriActionName, targetSkinId, targetActionName)
	self:GetOwner():SetState(OState.VIEW_TRANSFORM)

	-- 设置变形数据
	self:SetViewTransformData(
		oriSkinId, oriActionName, targetSkinId, targetActionName
	)

	self:CostViewTransformResource()

	-- 做变形动作
	self:GetOwner():DoAnimation(true, nil, oriActionName, false, sp.AnimationName.idle, true)

	--***---------- 刷新渲染层 ----------***--
	-- 通知渲染层变形
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'StartObjectViewTransform',
		self:GetOwner():GetViewModelTag(),
		oriSkinId, oriActionName, targetSkinId, targetActionName
	)
	--***---------- 刷新渲染层 ----------***--
end
--[[
变形!
--]]
function BaseEXAbilityDriver:ViewTransform()
	local viewTransformData = self:GetViewTransformData()

	if nil ~= viewTransformData then

		------------ 替换obj展示层的spine信息 ------------
		local skinId = viewTransformData.targetSkinId
		local skinConfig = CardUtils.GetCardSkinConfig(skinId)

		local spineDataStruct = BattleUtils.GetAvatarSpineDataStructBySpineId(
			skinConfig.spineId,
			G_BattleLogicMgr:GetSpineAvatarScaleByCardId(self:GetOwner():GetObjectConfigId())
		)
		local avatarScale = self:GetOwner():GetObjInfo().avatarScale

		self:GetOwner():RefreshViewModel(spineDataStruct, avatarScale)

		-- 设置一些变身后的动画状态
		self:GetOwner():DoAnimation(true, nil, viewTransformData.targetActionName, false, sp.AnimationName.idle, true)
		------------ 替换obj展示层的spine信息 ------------

		--***---------- 刷新渲染层 ----------***--
		-- 通知渲染层变形
		G_BattleLogicMgr:AddRenderOperate(
			'G_BattleRenderMgr',
			'DoObjectViewTransform',
			self:GetOwner():GetViewModelTag(),
			viewTransformData.oriSkinId,
			viewTransformData.oriActionName,
			viewTransformData.targetSkinId,
			viewTransformData.targetActionName
		)
		--***---------- 刷新渲染层 ----------***--

	end
end
--[[
结束变形
--]]
function BaseEXAbilityDriver:OnViewTransformExit()
	-- 清空数据
	self:ClearViewTransformData()

	-- 重置状态
	self:GetOwner():SetState(self:GetOwner():GetState(-1))
	self:GetOwner():SetState(OState.NORMAL, -1)
end
--[[
变形被打断
--]]
function BaseEXAbilityDriver:OnViewTransformBreak()
	self:OnViewTransformExit()

	self:GetOwner():DoAnimation(true, self:GetOwner():GetAvatarTimeScale(), sp.AnimationName.idle, true)

	--***---------- 插入刷新渲染层计时器 ----------***--
	-- 动画
	self:GetOwner():RefreshRenderAnimation(
		true, self:GetOwner():GetAvatarTimeScale(), sp.AnimationName.idle, true
	)
	--***---------- 插入刷新渲染层计时器 ----------***--
end
--[[
消耗变形的资源
--]]
function BaseEXAbilityDriver:CostViewTransformResource()

end
--[[
设置变形数据
@params oriSkinId int 源皮肤id
@params oriActionName string 源皮肤变形的动作
@params targetSkinId int 目标皮肤id
@params targetActionName string 目标皮肤变形的衔接动作
--]]
function BaseEXAbilityDriver:SetViewTransformData(oriSkinId, oriActionName, targetSkinId, targetActionName)
	self.viewTransformData = {
		oriSkinId = oriSkinId,
		oriActionName = oriActionName,
		targetSkinId = targetSkinId,
		targetActionName = targetActionName
	}
end
--[[
清空变形数据
--]]
function BaseEXAbilityDriver:ClearViewTransformData()
	self.viewTransformData = nil
end
--[[
获取变形的数据
@return _ map {
	oriSkinId int 源皮肤id
	oriActionName string 源皮肤变形的动作
	targetSkinId int 目标皮肤id
	targetActionName string 目标皮肤变形的衔接动作
}
--]]
function BaseEXAbilityDriver:GetViewTransformData()
	return self.viewTransformData
end
---------------------------------------------------
-- view transfrom logic end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------

---------------------------------------------------
-- get set end --
---------------------------------------------------

return BaseEXAbilityDriver
