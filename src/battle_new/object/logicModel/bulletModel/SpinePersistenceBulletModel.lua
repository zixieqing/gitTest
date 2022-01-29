--[[
持续性效果子弹 大雾风沙类效果
@params {
	objinfo ObjectSendBulletData 子弹的构造数据
}
--]]
local BaseSpineBulletModel = __Require('battle.object.logicModel.bulletModel.BaseSpineBulletModel')
local SpinePersistenceBulletModel = class('SpinePersistenceBulletModel', BaseSpineBulletModel)

------------ import ------------
------------ import ------------

------------ define ------------
------------ define ------------

--[[
constructor
--]]
function SpinePersistenceBulletModel:ctor( ... )
	BaseSpineBulletModel.ctor(self, ...)
end

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化特有属性
--]]
function SpinePersistenceBulletModel:InitUnitProperty()
	BaseSpineBulletModel.InitUnitProperty(self)

	-- 初始化一次持续时间
	self.leftTime = nil
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- logic begin --
---------------------------------------------------
--[[
自动行为逻辑
--]]
function SpinePersistenceBulletModel:AutoController(dt)
	if self:IsAllAnimationOver() then
		-- 杀死自己
		self:Die()
		return
	end

	-- 刷新一次时间
	if nil ~= self:GetLeftTime() then
		self:SetLeftTime(math.max(0, self:GetLeftTime() - dt))
	end
end
---------------------------------------------------
-- logic end --
---------------------------------------------------

---------------------------------------------------
-- state logic begin --
---------------------------------------------------
--[[
唤醒物体
--]]
function SpinePersistenceBulletModel:AwakeObject()
	BaseSpineBulletModel.AwakeObject(self)
end
--[[
所有动作是否完成
@return _ bool 
--]]
function SpinePersistenceBulletModel:IsAllAnimationOver()
	return nil ~= self:GetLeftTime() and 0 >= self:GetLeftTime()
end
--[[
是否能进入下一波
@return result bool
--]]
function SpinePersistenceBulletModel:CanEnterNextWave()
	-- 该类型不判断 直接进入下一波
	return true
end
---------------------------------------------------
-- state logic end --
---------------------------------------------------

---------------------------------------------------
-- animation control begin --
---------------------------------------------------
--[[
开始做子弹的spine动画
--]]
function SpinePersistenceBulletModel:StartDoBulletAnimation()
	-- 该类型不存在xxx_end动作
	self:DoAnimation(
		true,nil,
		self:GetBulletActionAnimationName(), true
	)

	self:RefreshRenderAnimation(
		true,nil,
		self:GetBulletActionAnimationName(), true
	)
end
---------------------------------------------------
-- animation control end --
---------------------------------------------------

---------------------------------------------------
-- spine handler begin --
---------------------------------------------------
--[[
展示层模拟的spine动画事件处理 [sp.EventType.ANIMATION_COMPLETE]
@params eventType 事件类型
@params event 事件数据 {
	animation string 动画名
}
--]]
function SpinePersistenceBulletModel:SpineEventCompleteHandler(eventType, event)
	
end
--[[
展示层模拟的spine动画事件处理 [sp.EventType.ANIMATION_EVENT]
@params eventType 事件类型
@params event 事件数据 {
	animation string 动画名
	eventData table {
		
	}
}
--]]
function SpinePersistenceBulletModel:SpineEventCustomHandler(eventType, event)
	if GState.START ~= G_BattleLogicMgr:GetGState() or OState.DIE == self:GetState() then return end

	local animationName = event.animation
	local eventName = event.eventData.name

	if self:GetBulletActionAnimationName() == animationName and sp.CustomEvent.cause_effect == eventName then

		---------- 处理接收到的事件 ----------
		-- 分段计数器增加
		self:SetPhaseCounter(self:GetPhaseCounter() + 1)

		-- 处理spine分段的权重
		local percent = event.eventData.intValue * 0.01
		if 0 >= percent then percent = 1 end

		-- 走攻击生效的逻辑
		self:Attack(self:GetAttackTargetTag(), percent, self:GetPhaseCounter())
		---------- 处理接收到的事件 ----------

		---------- 第一次接受时间刷新特效的持续时间 ----------
		if 1 == self:GetPhaseCounter() then
			self:SetLeftTime(self:GetEffectDuration())
		end
		---------- 第一次接受时间刷新特效的持续时间 ----------

	end

end
---------------------------------------------------
-- spine handler end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
获取子弹的持续时间
--]]
function SpinePersistenceBulletModel:GetEffectDuration()
	return self:GetObjInfo().durationTime
end
--[[
获取缓存的持续时间
--]]
function SpinePersistenceBulletModel:GetLeftTime()
	return self.leftTime
end
function SpinePersistenceBulletModel:SetLeftTime(leftTime)
	self.leftTime = leftTime
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return SpinePersistenceBulletModel
