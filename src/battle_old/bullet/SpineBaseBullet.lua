--[[
带spine动画的子弹基类
@params{
	tag int obj tag
	oname string obj name
	otype int obj type
	ownerTag int 发射者tag
	targetTag int 目标tag
	oriLocation cc.p origin pos
	targetLocation cc.p origin pos
	damageData table 伤害信息
	spineId int spine动画id
	actionName string 动作名字
	hurtEffectId int 被击特效id
	timeScale number 动画速率
	causeEffectCallback(nil) function 起效时的回调
}
--]]
local BaseBullet = __Require('battle.bullet.BaseBullet')
local SpineBaseBullet = class('SpineBaseBullet', BaseBullet)

---------------------------------------------------
-- init logic begin --
---------------------------------------------------
--[[
@override
--]]
function SpineBaseBullet:init()

	self.spineId = self.args.spineId
	self.actionName = self.args.actionName
	self.spTimeScale = self.args.timeScale or 1
	self.bulletScale = self.args.bulletScale
	self.spineTowards = self.args.towards

	self.view = {
		viewComponent = nil,
		avatar = nil,
	}

	self:initValue()
	self:initView()
	self:initSpineCallback()
end
--[[
@override
--]]
function SpineBaseBullet:initView()
	local view = __Require('battle.bullet.SpineBaseBulletView').new({
		spineName = string.format('effect_%d', checkint(self.spineId)),
		avatarScale = self.bulletScale,
		spineTowards = self.spineTowards
	})
	self.view.viewComponent = view
	self.view.avatar = view.viewData.avatar

	-- 设置位置
	self.view.viewComponent:setPosition(self.args.targetLocation)
	self:updateLocation()

	-- 设置spine动画速率 攻击加速后攻击动作可能会加快
	self.view.avatar:setTimeScale(tonumber(self.spTimeScale))

end
--[[
初始化spine事件
--]]
function SpineBaseBullet:initSpineCallback()
	-- 初始化spine事件
	self.view.avatar:registerSpineEventHandler(handler(self, self.spineEventEndHandler), sp.EventType.ANIMATION_END)
	self.view.avatar:registerSpineEventHandler(handler(self, self.spineEventCustomHandler), sp.EventType.ANIMATION_EVENT)
end
--[[
所有动作是否完成
@return _ bool 
--]]
function SpineBaseBullet:isAllSpineAnimationOver()
	return (nil == self.view.avatar:getCurrent())
end
---------------------------------------------------
-- init logic end --
---------------------------------------------------

---------------------------------------------------
-- action logic begin --
---------------------------------------------------
--[[
@override
awake logic
唤醒obj
--]]
function SpineBaseBullet:awake()
	self:setState(OState.BATTLE)
	self:updateLocation()
	self.view.avatar:setToSetupPose()
	self.view.avatar:setAnimation(0, self.actionName, false)
end
--[[
战斗行为 碰撞到造成伤害 没碰撞到跑路
@params dt number delta time
--]]
function SpineBaseBullet:autoController(dt)
	-- 所有动画播完再杀死self
	if true == self:isAllSpineAnimationOver() then
		self:die()
	end
end
--[[
攻击结束
@override
--]]
function SpineBaseBullet:attackEnd()
	local nextActionName = self.actionName .. '_end'
	if nil ~= self.view.avatar:getAnimationsData()[nextActionName] then
		self.view.avatar:setToSetupPose()
		self.view.avatar:setAnimation(0, nextActionName, false)
	end
end
--[[
设置暂停
@override
--]]
function SpineBaseBullet:pauseObj()
	self.state.pause = true
	self.view.avatar:setTimeScale(0)
end
--[[
恢复暂停
@override
--]]
function SpineBaseBullet:resumeObj()
	self.state.pause = false
	self.view.avatar:setTimeScale(self.spTimeScale)
end
--[[
@override
死亡动画结束
--]]
function SpineBaseBullet:dieEnd()
	-- 清除spine动画回调
	self.view.avatar:clearTracks()
	self.view.avatar:unregisterSpineEventHandler(sp.EventType.ANIMATION_END)
	self.view.avatar:unregisterSpineEventHandler(sp.EventType.ANIMATION_EVENT)

	self.view.viewComponent:die()
	self:destroy()
end
--[[
Override
销毁
--]]
function SpineBaseBullet:destroy()
	if OState.DIE ~= self:getState() then
		self:setState(OState.DIE)
		BMediator:RemoveObjEvent(ObjectEvent.OBJECT_DIE, self)
		self.view.avatar:clearTracks()
		self.view.avatar:unregisterSpineEventHandler(sp.EventType.ANIMATION_END)
		self.view.avatar:unregisterSpineEventHandler(sp.EventType.ANIMATION_EVENT)
	end
	self.view.viewComponent:destroy()
end
---------------------------------------------------
-- action logic end --
---------------------------------------------------

---------------------------------------------------
-- o update logic begin --
---------------------------------------------------
--[[
main update
--]]
function SpineBaseBullet:update(dt)
	-- dt = math.round(dt * TIME_ACCURACY) / TIME_ACCURACY
	local _dt = dt
	if self:isPause() then return end
	if OState.BATTLE == self:getState() then
		self:autoController(dt)
	end
end
---------------------------------------------------
-- o update logic end --
---------------------------------------------------

---------------------------------------------------
-- spine callback begin --
---------------------------------------------------
--[[
spine动画事件回调 动画结束回调
@params event table {
	animation string 动画名
	loopCount int 循环次数
	trackIndex int 时间线序号
	type string 回调类型
}
--]]
function SpineBaseBullet:spineEventEndHandler(event)
	if not event or OState.BATTLE ~= self:getState() then return end
	local eventName = event.animation
end
--[[
spine动画事件回调 用户自定义事件
@params event table {
	animation string 触发事件的动画名
	loopCount int 循环次数
	trackIndex int 时间线序号
	type string 回调类型
	eventData {
		name string 事件名称
		intValue int 占比 1-100
	}
}
--]]
function SpineBaseBullet:spineEventCustomHandler(event)
	if GState.START ~= BMediator:GetGState() or OState.BATTLE ~= self:getState() or nil ~= string.find(event.animation, 'end') then return end
	local eventName = event.eventData.name
	if sp.CustomEvent.cause_effect == eventName then

		local percent = event.eventData.intValue * 0.01
		if percent == 0 then percent = 1 end
		
		-- 在此处为特效添加一个震屏效果
		local owner = BMediator:IsObjAliveByTag(self.ownerTag)

		-- 分段计数器累加
		self.phaseCounter = self.phaseCounter + 1

		self:attack(self.aTargetTag, percent, self.phaseCounter)

	end
end
---------------------------------------------------
-- spine callback end --
---------------------------------------------------

---------------------------------------------------
-- spine utils begin --
---------------------------------------------------
--[[
获取自身碰撞框的世界坐标
--]]
function SpineBaseBullet:getCollisionBoxInWorldSpace()
	local cb = self.view.avatar:getBorderBox('collisionBox')
	if nil == cb then
		BattleUtils.PrintBattleWaringLog(string.format('cannot find collisionBox by spine animation name -> %s, action name -> %s', self.spineId, self.actionName))
	end
	local p = self.view.viewComponent:convertToWorldSpace(cc.p(cb.x, cb.y))
	local p_ = self.view.viewComponent:convertToWorldSpace(cc.p(cb.x + cb.width, cb.y + cb.height))
	return cc.rect(p.x, p.y, p_.x - p.x, p_.y - p.y)
end
---------------------------------------------------
-- spine utils end --
---------------------------------------------------

return SpineBaseBullet
