--[[
子弹物体base
@params{
	tag int obj tag
	oname string obj name
	otype int obj type
	ownerTag int 发射者tag
	targetTag int 目标tag
	oriLocation cc.p origin pos
	targetLocation cc.p origin pos
	damageData table 伤害信息
	causeEffectCallback(nil) function 起效时的回调
	hurtEffectData table 被击特效信息
}
--]]
local scheduler = require('cocos.framework.scheduler')

local BaseBullet = class('BaseBullet')
--[[
construstor
--]]
function BaseBullet:ctor( ... )
	self.args = unpack({...}) or {}

	--------------------------------------
	-- ui

	self.view = {
		viewComponent = nil,
	}

	self:init()

	self.objEventHandler_ = handler(self, self.objEventHandler)
	BMediator:AddObjEvent(ObjectEvent.OBJECT_DIE, self, self.objEventHandler_)
end
---------------------------------------------------
-- init logic begin --
---------------------------------------------------
function BaseBullet:init()
	self:initValue()
	self:initView()
end
function BaseBullet:initValue()
	-- 攻击目标
	self.ownerTag = self.args.ownerTag
	self.aTargetTag = self.args.targetTag
	self.causeEffectCallback = self.args.causeEffectCallback
	self.shouldShakeWorld = self.args.shouldShakeWorld
	-- 特效分段计数
	self.phaseCounter = 0
	self.op = {
		tag = checkint(self.args.tag),
		oname = tostring(self.args.oname),
		oriLocation = self.args.oriLocation,
		targetLocation = self.args.targetLocation,
		walkSpeed = BMediator:GetBConf().cellSize.width * 2,
		damageData = self.args.damageData,
		causeType = self.args.causeType

	}
	self.p = {
		oriLocation = self.op.oriLocation,
		targetLocation = self.op.targetLocation,
		location = {po = {x = 0, y = 0}, rc = {r = 0, c = 0}},
	}
	self.state = {
		cur = OState.SLEEP,
		pre = OState.SLEEP,
		pause = false
	}
	self.borderBox = {
		collisionBox = cc.rect(0, 0, 0, 0)
	}

	-- 被击特效信息
	self.hurtEffectData = self.args.hurtEffectData
end
function BaseBullet:initView()
	local view = __Require('battle.bullet.BaseBulletView').new({avatarScale = 1})
	self.view.viewComponent = view
	view:setVisible(false)

	-- 设置zorder
	self.view.viewComponent:setPosition(self.args.oriLocation)
	self:updateLocation()
end
---------------------------------------------------
-- init logic begin --
---------------------------------------------------

---------------------------------------------------
-- state logic begin --
---------------------------------------------------
--[[
awake logic
唤醒obj
--]]
function BaseBullet:awake()
	self:setState(OState.BATTLE)
	self:updateLocation()
end
--[[
sleep logic
睡眠obj
--]]
function BaseBullet:sleep()
	self:setState(OState.SLEEP)
end
--[[
get ostate
@params i int -1时返回上一个状态
@return state OState
--]]
function BaseBullet:getState(i)
	if -1 == idx then
		return self.state.pre
	else
		return self.state.cur
	end
end
--[[
set state
@params s OState
@params i int -1时设置前状态
--]]
function BaseBullet:setState(s, i)
	if -1 == idx then
		self.state.pre = s
	else
		self.state.pre = self.state.cur
		self.state.cur = s
	end
end
--[[
获取是否暂停
--]]
function BaseBullet:isPause()
	return self.state.pause
end
--[[
设置暂停
--]]
function BaseBullet:pauseObj()
	self.state.pause = true
end
--[[
恢复暂停
--]]
function BaseBullet:resumeObj()
	self.state.pause = false
end
--[[
所有动作是否完成
@return _ bool 
--]]
function BaseBullet:isAllSpineAnimationOver()
	return true
end
--[[
是否能进入下一波
@return result bool
--]]
function BaseBullet:canEnterNextWave()
	return self:isAllSpineAnimationOver()
end
---------------------------------------------------
-- state logic end --
---------------------------------------------------

---------------------------------------------------
-- action logic begin --
---------------------------------------------------
--[[
战斗行为 碰撞到造成伤害 没碰撞到跑路
@params dt number delta time
--]]
function BaseBullet:autoController(dt)
	-- print('new bullet attack ready -> ', self.aTargetTag, self.ownerTag)
	if not BMediator:IsObjAliveByTag(self.aTargetTag) and nil == self.causeEffectCallback then
		print('new bullet die - - -> ', self.aTargetTag, self.ownerTag)
		self:die()
	elseif self:canAttack(self.aTargetTag, dt) then
		-- 分段计数器累加
		self.phaseCounter = self.phaseCounter + 1
		self:attack(self.aTargetTag, 1, self.phaseCounter)
	end
end
--[[
跑路行为
@params targetTag int 攻击对象tag
@params dt number delta time
--]]
function BaseBullet:move(targetTag, dt)

end
--[[
是否能攻击
@params targetTag int 攻击对象tag
@params dt number 时间差
@return result bool 结果
--]]
function BaseBullet:canAttack(targetTag, dt)
	return true
end
--[[
攻击行为
@params targetTag int 攻击对象 tag
@params percent number 分段百分比
@params phaseCounter int 分段计数
--]]
function BaseBullet:attack(targetTag, percent, phaseCounter)
	-- 如果外部传入处理函数 则走外部函数 否则默认走扣血函数
	if self.causeEffectCallback then
		self.causeEffectCallback(percent, phaseCounter)
	else
		local target = BMediator:IsObjAliveByTag(targetTag)
		if nil ~= target then
			local damageData = clone(self.op.damageData)
			damageData.damage = damageData.damage * percent

			target:beAttacked(damageData)

			-- 显示被击特效
			target:showHurtEffect(self.hurtEffectData)
		end
	end

	if true == self.shouldShakeWorld then
		BMediator:GetViewComponent():ShakeWorld()
	end

	self:attackEnd()
end
--[[
攻击结束
--]]
function BaseBullet:attackEnd()
	self:die()
end
--[[
死亡行为
--]]
function BaseBullet:die()
	self:setState(OState.DIE)
	BMediator:RemoveObjEvent(ObjectEvent.OBJECT_DIE, self)
	BMediator:GetBData():removeABullet(self)
	self:dieEnd()
end
--[[
死亡动画
--]]
function BaseBullet:dieEnd()
	self.view.viewComponent:die()
	self:destroy()
end
--[[
销毁
--]]
function BaseBullet:destroy()
	if OState.DIE ~= self:getState() then
		self:setState(OState.DIE)
		BMediator:RemoveObjEvent(ObjectEvent.OBJECT_DIE, self)
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
function BaseBullet:update(dt)
	-- dt = math.round(dt * TIME_ACCURACY) / TIME_ACCURACY
	local _dt = dt
	if self:isPause() then return end
	if OState.BATTLE == self:getState() then
		self:autoController(dt)
	end
end
--[[
update location info
--]]
function BaseBullet:updateLocation()
	self.p.location.po.x = self.view.viewComponent:getPositionX()
	self.p.location.po.y = self.view.viewComponent:getPositionY()
	self.p.location.rc.r = BMediator:GetRowColByPos(cc.p(self.p.location.po.x, self.p.location.po.y)).r
	self.p.location.rc.c = BMediator:GetRowColByPos(cc.p(self.p.location.po.x, self.p.location.po.y)).c
	-- 更新zorder
	-- self.view.viewComponent:setLocalZOrder(BMediator:GetZorderInBattle(self.p.location.po))
end
---------------------------------------------------
-- o update logic end --
---------------------------------------------------

---------------------------------------------------
-- properties get set begin --
---------------------------------------------------
--[[
获取tag
--]]
function BaseBullet:getOTag()
	return self.op.tag
end
--[[
获取name
--]]
function BaseBullet:getOName()
	return self.op.oname
end
--[[
获取坐标信息
--]]
function BaseBullet:getLocation()
	return self.p.location
end
--[[
获取obj碰撞方格 世界坐标
--]]
function BaseBullet:getCollisionBoxInWorldSpace()
	local cb = self.borderBox.collisionBox
	local p = self:convertToWorldSpace(cc.p(cb.x, cb.y))
	local p_ = self:convertToWorldSpace(cc.p(cb.x + cb.width, cb.y + cb.height))
	return cc.rect(p.x, p.y, p_.x - p.x, p_.y - p.y)
end
---------------------------------------------------
-- properties get set end --
---------------------------------------------------

---------------------------------------------------
-- handler logic begin --
---------------------------------------------------
--[[
死亡事件回调
@params evt table
@params ... table {
	tag int died-obj tag
}
--]]
function BaseBullet:objEventHandler( ... )
	local args = unpack({...})
	if checkint(args.tag) == self.aTargetTag then
		self.aTargetTag = nil
	end
end
---------------------------------------------------
-- handler logic end --
---------------------------------------------------

return BaseBullet
