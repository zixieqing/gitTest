--[[
激光类型子弹
--]]
local SpineBaseBullet = __Require('battle.bullet.SpineBaseBullet')
local SpineLaserBullet = class('SpineLaserBullet', SpineBaseBullet)
--[[
@override
--]]
function SpineLaserBullet:initView()
	local view = __Require('battle.bullet.SpineLaserBulletView').new({
		spineName = string.format('effect_%d', checkint(self.spineId)),
		actionName = self.actionName,
		avatarScale = self.bulletScale
	})

	self.view = {
		viewComponent = view,
		laserEnd = view.viewData.laserEnd,
		avatar = view.viewData.avatar,
		laserHead = view.viewData.laserHead,
		laserOriSize = view.viewData.laserOriSize
	}

	-- 设置spine动画速率 攻击加速后攻击动作可能会加快
	self.view.avatar:setTimeScale(tonumber(self.spTimeScale))

end
--[[
@override
初始化spine事件
--]]
function SpineLaserBullet:initSpineCallback()
	-- 初始化spine事件
	self.view.avatar:registerSpineEventHandler(handler(self, self.spineEventEndHandler), sp.EventType.ANIMATION_END)
	self.view.avatar:registerSpineEventHandler(handler(self, self.spineEventCustomHandler), sp.EventType.ANIMATION_EVENT)

	if self.view.laserHead then
		self.view.laserHead:registerSpineEventHandler(handler(self, self.spineEventEndHandler), sp.EventType.ANIMATION_END)
		self.view.laserHead:registerSpineEventHandler(handler(self, self.spineEventCustomHandler), sp.EventType.ANIMATION_EVENT)
	end
end
--[[
@override
awake logic
唤醒obj
--]]
function SpineLaserBullet:awake()
	self:setState(OState.BATTLE)
	-- 如果存在激光头 将激光头加到目标位置
	if nil ~= self.view.laserHead then
		self.view.laserHead:setToSetupPose()
		self.view.viewComponent:getParent():addChild(self.view.laserHead, self.view.viewComponent:getLocalZOrder())
	end
	self:updateLaserPosition()
	self:updateLocation()
	self.view.avatar:setToSetupPose()
	self.view.avatar:setAnimation(0, self:getLaserSpineActionName(sp.LaserAnimationName.laserBody), false)
	if nil ~= self.view.laserEnd then
		self.view.laserEnd:setToSetupPose()
		self.view.laserEnd:setAnimation(0, self:getLaserSpineActionName(sp.LaserAnimationName.laserEnd), false)
	end
end
--[[
@override
战斗行为 
@params dt number delta time
--]]
function SpineLaserBullet:autoController(dt)
	-- 所有动画播完再杀死self
	-- print('laser bullet tag --> ', self.op.tag, self.ownerTag, self.aTargetTag)
	if true == self:isAllSpineAnimationOver() then
		self:die()
		return 
	else
		-- 算位置 更新激光束
		-- 激光尾和激光束
		local owner = BMediator:IsObjAliveByTag(self.ownerTag)
		if nil ~= owner then
			-- TODO 暂时屏蔽刷新起始点的位置 --
			-- self.p.oriLocation = owner:getLocation().po
		end
		-- 激光头
		if ConfigEffectCauseType.POINT == self.op.causeType then
			local target = BMediator:IsObjAliveByTag(self.aTargetTag)
			if nil ~= target then
				if target:getLocation().po ~= self.p.targetLocation then
					self.p.targetLocation = target:getLocation().po
					self:updateLaserPosition()
				end
			end
		end
	end
end
--[[
更新激光位置
--]]
function SpineLaserBullet:updateLaserPosition()
	-- 刷新激光位置

	------------ 激光尾和激光束的位置 缩放 旋转 ------------
	-- 激光尾位置
	self.view.viewComponent:setPosition(self.p.oriLocation)

	-- 激光长度
	local laserLength = cc.pGetDistance(self.p.oriLocation, self.p.targetLocation)
	self.view.avatar:setScaleX(laserLength / self.view.laserOriSize.width)

	-- 激光角度
	local angle = BattleUtils.GetAngleByPoints(self.p.oriLocation, self.p.targetLocation)

	-- 激光是否需要翻转 默认向右
	if self.p.targetLocation.x < self.p.oriLocation.x then
		angle = -angle
		if self.view.viewComponent:getScaleX() > 0 then
			self.view.viewComponent:setScaleX(-1)
		end
	else
		if self.view.viewComponent:getScaleX() < 0 then
			self.view.viewComponent:setScaleX(1)
		end
	end
	self.view.avatar:setRotation(angle)
	------------ 激光尾和激光束的位置 缩放 旋转 ------------

	------------ 激光头的位置 不做旋转缩放 ------------
	if nil ~= self.view.laserHead then
		self.view.laserHead:setPosition(self.p.targetLocation)
	end
	------------ 激光头的位置 不做旋转缩放 ------------
end
--[[
@override
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
function SpineLaserBullet:spineEventCustomHandler(event)
	if GState.START ~= BMediator:GetGState() or OState.BATTLE ~= self:getState() then return end

	if self:getLaserSpineActionName(sp.LaserAnimationName.laserBody) == event.animation then

		self:laserBodySpineEventCustomHandler(event)

	elseif self:getLaserSpineActionName(sp.LaserAnimationName.laserHead) == event.animation then

		self:laserHeadSpineEventCustomHandler(event)

	end

end
--[[
激光束事件回调处理
--]]
function SpineLaserBullet:laserBodySpineEventCustomHandler(event)
	if nil ~= self.view.laserHead then
		-- 如果存在激光头 则跑激光头的逻辑
		if not self.view.laserHead:isVisible() then
			self.view.laserHead:setVisible(true)
			self.view.laserHead:setAnimation(0, self:getLaserSpineActionName(sp.LaserAnimationName.laserHead), false)
		end
	else
		local eventName = event.eventData.name
		-- 如果不存在激光头 则直接造成效果
		if sp.CustomEvent.cause_effect == eventName then

			local percent = event.eventData.intValue * 0.01
			if percent == 0 then percent = 1 end

			-- 分段计数器累加
			self.phaseCounter = self.phaseCounter + 1
			
			self:attack(self.aTargetTag, percent, self.phaseCounter)

		end
	end
end
--[[
激光头事件回调处理
--]]
function SpineLaserBullet:laserHeadSpineEventCustomHandler(event)
	local eventName = event.eventData.name
	if sp.CustomEvent.cause_effect == eventName then

		local percent = event.eventData.intValue * 0.01
		if percent == 0 then percent = 1 end

		-- 分段计数器累加
		self.phaseCounter = self.phaseCounter + 1
		
		self:attack(self.aTargetTag, percent, self.phaseCounter)

	end
end
--[[
获取激光尾束头动作名
@params part sp.LaserAnimationName
--]]
function SpineLaserBullet:getLaserSpineActionName(part)
	return self.actionName .. part
end
--[[
动画是否结束
@override
@return _ bool 动画是否结束
--]]
function SpineLaserBullet:isAllSpineAnimationOver()
	if nil == self.view.avatar:getCurrent() then
		if nil ~= self.view.laserHead and nil == self.view.laserHead:getCurrent() then
			return true
		elseif nil == self.view.laserHead then
			return true
		end
	end
	return false
end
--[[
设置暂停
@override
--]]
function SpineLaserBullet:pauseObj()
	self.state.pause = true

	self.view.avatar:setTimeScale(0)

	if nil ~= self.view.laserHead then
		self.view.laserHead:setTimeScale(0)
	end

	if nil ~= self.view.laserEnd then
		self.view.laserEnd:setTimeScale(0)
	end
end
--[[
恢复暂停
@override
--]]
function SpineLaserBullet:resumeObj()
	self.state.pause = false

	self.view.avatar:setTimeScale(self.spTimeScale)

	if nil ~= self.view.laserHead then
		self.view.laserHead:setTimeScale(self.spTimeScale)
	end

	if nil ~= self.view.laserEnd then
		self.view.laserEnd:setTimeScale(self.spTimeScale)
	end
end
---------------------------------------------------
-- handler logic begin --
---------------------------------------------------
--[[
@override
死亡事件回调
施法者死亡 移除自己
@params evt table
@params ... table {
	tag int died-obj tag
}
--]]
function SpineLaserBullet:objEventHandler( ... )
	SpineBaseBullet.objEventHandler(self, ...)
	local args = unpack({...})
	if checkint(args.tag) == self.ownerTag then
		self:die()
	end
end
---------------------------------------------------
-- handler logic end --
---------------------------------------------------

return SpineLaserBullet
