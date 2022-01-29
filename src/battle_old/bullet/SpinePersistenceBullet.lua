--[[
持续性效果子弹 大雾风沙类效果
@params durationTime number 持续时间
--]]
local SpineBaseBullet = __Require('battle.bullet.SpineBaseBullet')
local SpinePersistenceBullet = class('SpinePersistenceBullet', SpineBaseBullet) 
--[[
@override
--]]
function SpinePersistenceBullet:init()
	SpineBaseBullet.init(self)
	self.op.durationTime = self.args.durationTime or 0
	self.p.durationTime = self.op.durationTime
	self.spineTowards = self.args.towards
end
--[[
@override
awake logic
唤醒obj
--]]
function SpinePersistenceBullet:awake()
	self:setState(OState.BATTLE)
	self:updateLocation()
	self.view.avatar:setToSetupPose()
	self.view.avatar:setAnimation(0, self.actionName, true)

	self.view.viewComponent:setOpacity(0)
	local appearActionSeq = cc.FadeTo:create(0.5, 255)
	self.view.viewComponent:runAction(appearActionSeq)
end
--[[
@override
@params dt number delta time
--]]
function SpinePersistenceBullet:autoController(dt)
	-- 持续时间结束杀死动画
	if true == self:isAllSpineAnimationOver() then
		self:die()
		return
	end

	-- 更新时间
	self.p.durationTime = self.p.durationTime - dt
end
--[[
@override
动画是否结束
@return _ bool 动画是否结束
--]]
function SpinePersistenceBullet:isAllSpineAnimationOver()
	return 0 >= self.p.durationTime
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
function SpinePersistenceBullet:spineEventCustomHandler(event)
	if GState.START ~= BMediator:GetGState() or OState.BATTLE ~= self:getState() then return end
	local eventName = event.eventData.name
	if sp.CustomEvent.cause_effect == eventName then

		local percent = event.eventData.intValue * 0.01
		if percent == 0 then percent = 1 end

		-- 分段计数器累加
		self.phaseCounter = self.phaseCounter + 1
		
		self:attack(self.aTargetTag, percent, self.phaseCounter)

		if 1 == self.phaseCounter then
			-- 第一次接收事件刷新特效的持续时间
			self.p.durationTime = self.op.durationTime
		end

	end
end
--[[
@override
死亡行为
--]]
function SpinePersistenceBullet:die()
	self:setState(OState.DIE)
	BMediator:RemoveObjEvent(ObjectEvent.OBJECT_DIE, self)
	BMediator:GetBData():removeABullet(self)

	local disappearActionSeq = cc.Sequence:create(
		cc.FadeTo:create(0.5, 0),
		cc.CallFunc:create(function ()
			self:dieEnd()
		end)
	)
	self.view.viewComponent:runAction(disappearActionSeq)
end
--[[
是否能进入下一波
@return result bool
--]]
function SpinePersistenceBullet:canEnterNextWave()
	return true
end

return SpinePersistenceBullet
