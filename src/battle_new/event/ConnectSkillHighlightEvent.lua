--[[
连携技高亮事件
@params table {
	owner 宿主
}
--]]
local BaseEvent = __Require('battle.event.BaseEvent')
local ConnectSkillHighlightEvent = class('ConnectSkillHighlightEvent', BaseEvent)
--[[
@override
constructor
--]]
function ConnectSkillHighlightEvent:ctor( ... )
	local args = unpack{(...)}

	BaseEvent.ctor(self, ...)
end
---------------------------------------------------
-- init logic begin --
---------------------------------------------------
--[[
@override
初始化
--]]
function ConnectSkillHighlightEvent:Init()
	BaseEvent.Init(self)
	-- 保存高亮单位tag集合
	self.highlightObjTags = {}
	-- 保存高亮单位计数器
	self.highlightCounter = {}
end
---------------------------------------------------
-- init logic end --
---------------------------------------------------

---------------------------------------------------
-- control logic begin --
---------------------------------------------------
--[[
@override
进入事件
@params skillId int 技能id
@params casterTag int 施法者tag
@params targets table 被施法者集合
--]]
function ConnectSkillHighlightEvent:OnEventEnter(skillId, casterTag, targets)
	if not self:IsInEvent() then
		self:OnHighlightStart(skillId, casterTag, targets)
	else
		self:AddHighlightObjects(skillId, casterTag, targets)
	end
end
--[[
@override
结束事件
@params skillId int 技能id
@params casterTag int 施法者tag
--]]
function ConnectSkillHighlightEvent:OnEventExit(skillId, casterTag)
	self:RemoveHighlightObjectsByCasterTag(casterTag, skillId)
	if 0 == table.nums(self.highlightObjTags) then
		self:OnHighlightOver()
	end
end
--[[
@override
刷新事件
--]]
function ConnectSkillHighlightEvent:OnEventUpdate()

end
--[[
@override
意外中断事件
--]]
function ConnectSkillHighlightEvent:OnEventBreak()

end
--[[
开始连携技高亮
@params skillId int 技能id
@params casterTag int 施法者tag
@params targets table 被施法者集合
--]]
function ConnectSkillHighlightEvent:OnHighlightStart(skillId, casterTag, targets)
	self:SetIsInEvent(true)
	self:AddHighlightObjects(skillId, casterTag, targets)

	--***---------- 刷新渲染层 ----------***--
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'ShowBattleEffectLayer',
		true
	)
	--***---------- 刷新渲染层 ----------***--
end
--[[
结束连携技高亮
--]]
function ConnectSkillHighlightEvent:OnHighlightOver()
	self:SetIsInEvent(false)

	--***---------- 刷新渲染层 ----------***--
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'ShowBattleEffectLayer',
		false
	)
	--***---------- 刷新渲染层 ----------***--
end
--[[
增加高亮单位
@params skillId int 技能id
@params casterTag int 施法者tag
@params targets table 被施法者集合
--]]
function ConnectSkillHighlightEvent:AddHighlightObjects(skillId, casterTag, targets)
	local highlightData = {skillId = skillId, targetTags = {}, connectCardTags = {}}

	---------- 施法者高亮 ----------
	local caster = G_BattleLogicMgr:IsObjAliveByTag(casterTag)

	-- 检查高亮计数器
	if nil == self.highlightCounter[tostring(casterTag)] then
		self.highlightCounter[tostring(casterTag)] = 0
	end

	if nil ~= caster then
		if 0 == self.highlightCounter[tostring(casterTag)] then

			caster:SetHighlight(true)
			caster:UpdateLocation()

			--***---------- 刷新渲染层 ----------***--
			caster:RefreshRenderViewPosition()
			--***---------- 刷新渲染层 ----------***--

		else

			local preHighLightData = self.highlightObjTags[tostring(casterTag)]
			if nil ~= preHighLightData then
				-- 移除上一次未结束的高亮

				---------- 施法者高亮计数-1 ----------
				self.highlightCounter[tostring(casterTag)] = self.highlightCounter[tostring(casterTag)] - 1
				---------- 施法者高亮计数-1 ----------

				---------- 移除目标高亮 ----------
				local tTag = nil
				local target = nil
				for i, v in ipairs(preHighLightData.targetTags) do
					tTag = v
					target = G_BattleLogicMgr:GetObjByTagForce(tTag)
					if nil ~= target then
						self.highlightCounter[tostring(tTag)] = self.highlightCounter[tostring(tTag)] - 1
						if 0 >= self.highlightCounter[tostring(tTag)] then
							target:SetHighlight(false)
							target:UpdateLocation()

							--***---------- 刷新渲染层 ----------***--
							target:RefreshRenderViewPosition()
							--***---------- 刷新渲染层 ----------***--
						end
					end
				end
				---------- 移除目标高亮 ----------

			end

		end
		self.highlightCounter[tostring(casterTag)] = self.highlightCounter[tostring(casterTag)] + 1
	end
	---------- 施法者高亮 ----------

	---------- 目标高亮 ----------
	local tTag = nil
	local target = nil
	for i, v in ipairs(targets) do
		tTag = v.tag
		target = G_BattleLogicMgr:GetObjByTagForce(tTag)

		if nil ~= target then
			-- 检查高亮计数器
			if nil == self.highlightCounter[tostring(tTag)] then
				self.highlightCounter[tostring(tTag)] = 0
			end
			
			if 0 == self.highlightCounter[tostring(tTag)] then
				target:SetHighlight(true)
				target:UpdateLocation()

				--***---------- 刷新渲染层 ----------***--
				target:RefreshRenderViewPosition()
				--***---------- 刷新渲染层 ----------***--
			end

			table.insert(highlightData.targetTags, 1, tTag)
			self.highlightCounter[tostring(tTag)] = self.highlightCounter[tostring(tTag)] + 1
		end
	end
	---------- 目标高亮 ----------

	-- 保存数据
	self.highlightObjTags[tostring(casterTag)] = highlightData
end
--[[
移除一个高亮单位
@params casterTag int 施法者tag
@params skillId int 技能id
--]]
function ConnectSkillHighlightEvent:RemoveHighlightObjectsByCasterTag(casterTag, skillId)
	local highlightData = self.highlightObjTags[tostring(casterTag)]
	local highlightCounterData = self.highlightCounter[tostring(casterTag)]
	local caster = G_BattleLogicMgr:GetObjByTagForce(casterTag)

	---------- 施法者高亮 ----------
	if nil ~= highlightCounterData then

		self.highlightCounter[tostring(casterTag)] = self.highlightCounter[tostring(casterTag)] - 1

		if nil ~= caster then
			if 0 >= self.highlightCounter[tostring(casterTag)] then
				caster:SetHighlight(false)
				caster:UpdateLocation()

				--***---------- 刷新渲染层 ----------***--
				caster:RefreshRenderViewPosition()
				--***---------- 刷新渲染层 ----------***--
			end
		end

	end
	---------- 施法者高亮 ----------

	--------- 目标高亮 ----------
	if nil ~= highlightData then

		local tTag = nil
		local target = nil
		for i, v in ipairs(highlightData.targetTags) do
			tTag = v
			target = G_BattleLogicMgr:GetObjByTagForce(tTag)
			if nil ~= target then
				self.highlightCounter[tostring(tTag)] = self.highlightCounter[tostring(tTag)] - 1
				if 0 >= self.highlightCounter[tostring(tTag)] then
					target:SetHighlight(false)
					target:UpdateLocation()

					--***---------- 刷新渲染层 ----------***--
					target:RefreshRenderViewPosition()
					--***---------- 刷新渲染层 ----------***--
				end
			end
		end
		
	end
	--------- 目标高亮 ----------

	self.highlightObjTags[tostring(casterTag)] = nil
end
---------------------------------------------------
-- control logic end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
根据物体tag判断该物体是否发起了一次高亮
@params casterTag int 施法者tag
@return _ bool
--]]
function ConnectSkillHighlightEvent:IfCausedHighlightByCasterTag(casterTag)
	if nil == self.highlightObjTags[tostring(casterTag)] then
		return false
	else
		return true
	end
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return ConnectSkillHighlightEvent
