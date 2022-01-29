--[[
qte物体逻辑层模型
--]]
local BaseLogicModel = __Require('battle.object.logicModel.BaseLogicModel')
local BaseAttachModel = class('BaseAttachModel', BaseLogicModel)

------------ import ------------
------------ import ------------

------------ define ------------
------------ define ------------

--[[
constructor
--]]
function BaseAttachModel:ctor( ... )
	BaseLogicModel.ctor(self, ...)
end

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
@override
初始化
--]]
function BaseAttachModel:Init()
	BaseLogicModel.Init(self)
end
--[[
@override
初始化特有属性
--]]
function BaseAttachModel:InitUnitProperty()
	-- 当前点击计数
	self.touchCounter = 0

	-- 当前qte点击阶段计数
	self.touchPace = 0
	-- 最大qte点击阶段数
	self.paceAmount = 3
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- logic begin --
---------------------------------------------------
--[[
点击到qte物体后的处理
--]]
function BaseAttachModel:TouchedAttachObject()
	-- 增加一次点击计数
	self:SetTouchCounter(self:GetTouchCounter() + 1)

	-- 检查一次阶段数
	self:CheckTouchPace(self:GetTouchCounter())

	-- 检查一次是否需要移除满足条件的buff类型
	local canRemoveBuffType = self:CheckBuffStateByTouchCounter(self:GetTouchCounter())

	if nil ~= canRemoveBuffType then
		local owner = self:GetOwner()
		if nil ~= owner then

			local buff = owner:GetBuffBySkillId(self:GetSkillId(), canRemoveBuffType)
			if nil ~= buff then
				-- 移除该buff model
				buff:OnRecoverEffectEnter()
			end

		end
	end
end
--[[
检查一次点击阶段
--]]
function BaseAttachModel:CheckTouchPace(touchCounter)
	local maxTouch = self:GetMaxTouch()
	if touchCounter == math.floor(maxTouch / self.paceAmount * (self:GetTouchPace() + 1)) then
		touchPace = math.min(self:GetTouchPace() + 1, self.paceAmount)
		self:SetTouchPace(touchPace)

		--***---------- 刷新渲染层 ----------***--
		-- 在渲染层创建一个qte层
		G_BattleLogicMgr:AddRenderOperate(
			'G_BattleRenderMgr',
			'RefreshAAttachObjectViewState',
			self:GetOTag(), touchPace
		)
		--***---------- 刷新渲染层 ----------***--
	end
end
--[[
根据点击次数查找可以移除的buff效果
@params touchCounter int 点击次数
@return _ ConfigBuffType buff类型
--]]
function BaseAttachModel:CheckBuffStateByTouchCounter(touchCounter)
	local qteBuffs = self:GetQTEBuffsInfo()
	local buffInfo = nil

	for i = #qteBuffs, 1, -1 do
		buffInfo = qteBuffs[i]
		if touchCounter >= buffInfo.qteTapTime then
			return buffInfo.buffType
		end
	end

	return nil
end
--[[
死亡逻辑
--]]
function BaseAttachModel:Die()
	self:Destroy()
end
--[[
销毁qte物体
--]]
function BaseAttachModel:Destroy()
	--***---------- 刷新渲染层 ----------***--
	-- 在渲染层创建一个qte层
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'DestroyAAttachObjectView',
		self:GetOTag()
	)
	--***---------- 刷新渲染层 ----------***--
end
---------------------------------------------------
-- logic end --
---------------------------------------------------

---------------------------------------------------
-- qte buff info begin --
---------------------------------------------------
--[[
刷新qtebuff信息
@params qteBuffsInfo QTEAttachObjectConstructStruct qte数据信息
--]]
function BaseAttachModel:RefreshQTEBuffs(qteBuffsInfo)
	-- 刷新qte buffs 信息
	self.objInfo = qteBuffsInfo

	-- 重置touch计数器
	self:ResetTouchCounter()
	self:ResetTouchPace()

	--***---------- 刷新渲染层 ----------***--
	-- 刷新渲染层的qte冰块状态
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'RefreshAAttachObjectViewState',
		self:GetOTag(), self:GetTouchPace()
	)
	--***---------- 刷新渲染层 ----------***--
end
--[[
移除单个qte buff
@params buffType ConfigBuffType
--]]
function BaseAttachModel:RemoveQTEBuff(buffType)
	local qteBuffs = self:GetQTEBuffsInfo()
	local buffInfo = nil
	local needDie = false

	for i = #qteBuffs, 1, -1 do
		buffInfo = qteBuffs[i]
		if buffType == buffInfo.buffType then
			-- 移除qte buff
			table.remove(qteBuffs, i)
			if 0 == #qteBuffs then
				needDie = true
			end
			break
		end
	end

	if needDie then
		-- qte物体失效 移除整个qte物体
		local owner = self:GetOwner()
		if nil ~= owner then
			owner:RemoveQTE(self:GetSkillId())
		end
	end

end
---------------------------------------------------
-- qte buff info end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
获取qte物体类型
@return _ QTEAttachObjectType
--]]
function BaseAttachModel:GetAttachType()
	return self:GetObjInfo().attachType
end
--[[
获取qte物体对应的skill id
@return _ params
--]]
function BaseAttachModel:GetSkillId()
	return self:GetObjInfo().skillId
end
--[[
获取owner信息
--]]
function BaseAttachModel:GetOwnerTag()
	return self:GetObjInfo().ownerTag
end
function BaseAttachModel:GetOwner()
	return G_BattleLogicMgr:IsObjAliveByTag(self:GetOwnerTag())
end
--[[
获取qte buffs信息
--]]
function BaseAttachModel:GetQTEBuffsInfo()
	return self:GetObjInfo().qteBuffs
end
--[[
点击计数器
--]]
function BaseAttachModel:GetTouchCounter()
	return self.touchCounter
end
function BaseAttachModel:SetTouchCounter(counter)
	self.touchCounter = counter
end
function BaseAttachModel:ResetTouchCounter()
	self:SetTouchCounter(0)
end
--[[
阶段计数器
--]]
function BaseAttachModel:GetTouchPace()
	return self.touchPace
end
function BaseAttachModel:SetTouchPace(pace)
	self.touchPace = pace
end
function BaseAttachModel:ResetTouchPace()
	self:SetTouchPace(0)
end
--[[
获取最大点击次数
--]]
function BaseAttachModel:GetMaxTouch()
	return self:GetObjInfo().maxTouch
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return BaseAttachModel
