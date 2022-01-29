--[[
spine飞行物子弹 程序控制运动轨迹 碰撞到目标物体就造成效果
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
local SpineBaseBullet = __Require('battle.bullet.SpineBaseBullet')
local SpineUFOBullet = class('SpineUFOBullet', SpineBaseBullet)
--[[
@override
awake logic
唤醒obj
--]]
function SpineUFOBullet:awake()
	-- print('>>>>>>>>>>here check ufo bullet owner name<<<<<<<<<<', BMediator:IsObjAliveByTag(self.ownerTag):getOCardName(), self.op.tag)
	self:setState(OState.BATTLE)
	self:updateLocation()
	self.view.avatar:setToSetupPose()
	self.view.avatar:setAnimation(0, self.actionName, true)

	-- debug --
	-- local testLayer = display.newLayer(self.view.viewComponent:getPositionX(), self.view.viewComponent:getPositionY(), {size = cc.size(50, 50), color = '#3c3c3c'})
	-- self.view.viewComponent:getParent():addChild(testLayer, self.view.viewComponent:getLocalZOrder())
	-- debug --
end
--[[
初始化伤害标识符
--]]
function SpineUFOBullet:initValue()
	SpineBaseBullet.initValue(self)
	self.causedDamage = false
	-- 初始化目标碰撞框
	self.p.targetCollisionBox = cc.rect(0, 0, 0, 0)
	local target = BMediator:IsObjAliveByTag(self.aTargetTag)
	if nil ~= target then
		self.p.targetCollisionBox = target:getCollisionBoxInWorldSpace()
	end
end
--[[
@override
--]]
function SpineUFOBullet:initView()
	local spineTowards = true
	if cc.pSub(self.p.targetLocation, self.p.oriLocation).x < 0 then
		spineTowards = false
	end
	local view = __Require('battle.bullet.SpineUFOBulletView').new({
		spineName = string.format('effect_%d', checkint(self.spineId)),
		avatarScale = self.bulletScale,
		spineTowards = spineTowards
	})
	self.view.viewComponent = view
	self.view.avatar = view.viewData.avatar

	-- 设置位置
	self.view.viewComponent:setPosition(self.args.oriLocation)
	self:updateLocation()

	-- 设置spine动画速率 攻击加速后攻击动作可能会加快
	self.view.avatar:setTimeScale(tonumber(self.spTimeScale))

	-- 修正旋转
	self:fixRotate(self.p.oriLocation, self.p.targetLocation)

end
--[[
@override
战斗行为 碰撞到造成伤害 没碰撞到跑路
@params dt number delta time
--]]
function SpineUFOBullet:autoController(dt)
	-- 所有动画播完再杀死self
	if nil == self.view.avatar:getCurrent() then
		self:die()
	elseif true == self:canAttack(self.aTargetTag, dt) then
		self.causedDamage = true
		-- 分段计数器累加
		self.phaseCounter = self.phaseCounter + 1
		self:attack(self.aTargetTag, 1, self.phaseCounter)
	end
end
--[[
@override
是否能攻击
@params targetTag int 攻击对象tag
@params dt number 时间差
@return result bool 结果
--]]
function SpineUFOBullet:canAttack(targetTag, dt)
	-- 判断碰撞
	if true == self.causedDamage then
		-- 如果已经造成过伤害 则返回
		return false
	else
		if nil ~= BMediator:IsObjAliveByTag(targetTag) then
			local target = BMediator:IsObjAliveByTag(targetTag)
			-- 刷新目标数据
			self.p.targetCollisionBox = target:getCollisionBoxInWorldSpace()
			self.p.targetLocation = target:getLocation().po
		end

		local selfCollisionBox = self:getCollisionBoxInWorldSpace()

		-- print('here check fuck collisionbox<<<<<<<<<<<<<<<<<<<<<', self.ownerTag)
		-- dump(self.p.targetCollisionBox)
		-- dump(selfCollisionBox)

		-- debug path --
		-- local parent = self.view.viewComponent:getParent()
		-- local selfZorder = self.view.viewComponent:getLocalZOrder()
		-- local pos = parent:convertToNodeSpace(cc.p(
		-- 	-- selfCollisionBox.x + selfCollisionBox.width * 0.5,
		-- 	-- selfCollisionBox.y + selfCollisionBox.height * 0.5
		-- 	selfCollisionBox.x,
		-- 	selfCollisionBox.y
		-- ))
		-- local testLayer = display.newLayer(pos.x, pos.y, {size = cc.size(50, 50)})
		-- testLayer:setBackgroundColor(cc.c4b(math.random(255), math.random(255), math.random(255), 255))
		-- parent:addChild(testLayer, selfZorder)
		-- debug path --

		-- 判断是否碰撞到 判断是否打到对面碰撞框中心点
		-- if cc.rectContainsPoint(
		-- 	selfCollisionBox,
		-- 	cc.p(self.p.targetCollisionBox.x + self.p.targetCollisionBox.width * 0.5, self.p.targetCollisionBox.y + self.p.targetCollisionBox.height * 0.5)
		-- ) then
		if cc.rectIntersectsRect(selfCollisionBox, self.p.targetCollisionBox) then
			-- print('here ufo bullet can attack<<<<<<<<<<', self.op.tag)
			return true
		else
			self:move(targetTag, dt)
		end
	end
	return false
end
--[[
攻击结束
@override
--]]
function SpineUFOBullet:attackEnd()
	local nextActionName = self.actionName .. '_end'
	if nil ~= self.view.avatar:getAnimationsData()[nextActionName] then
		self.view.avatar:setToSetupPose()
		self.view.avatar:setAnimation(0, nextActionName, false)
	else
		self:die()
	end
end
--[[
@override
跑路行为
@params target obj 目标
@params dt number delta time
--]]
function SpineUFOBullet:move(targetTag, dt)
	local targetCB = self.p.targetCollisionBox
	local targetCBCenter = cc.p(targetCB.x + targetCB.width * 0.5, targetCB.y + targetCB.height * 0.5)
	targetCBCenter = self.view.viewComponent:getParent():convertToNodeSpace(targetCBCenter)
	self.view.viewComponent:setPosition(cc.pLerp(self:getLocation().po, targetCBCenter, math.min(1, 0.2 * BMediator:GetTimeScale())))
	self:updateLocation()
end
--[[
所有动作是否完成
@return _ bool 
--]]
function SpineUFOBullet:isAllSpineAnimationOver()
	-- 该类型无法直接判断是否结束
	return false
end
--[[
@override
是否能进入下一波
@return result bool
--]]
function SpineUFOBullet:canEnterNextWave()
	return true
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
function SpineUFOBullet:spineEventCustomHandler(event)
	-- 该类型不处理事件
end
--[[
修正旋转
@params oriPos cc.p 原始坐标
@params targetPos cc.p 目标坐标
--]]
function SpineUFOBullet:fixRotate(oriPos, targetPos)
	local deltaVector = cc.pSub(targetPos, oriPos)
	local angle = math.deg(math.atan(math.abs(deltaVector.y) / math.abs(deltaVector.x)))
	if 0 < (deltaVector.x * deltaVector.y) then
		angle = -1 * angle
	end
	self.view.viewComponent.viewData.avatar:setRotation(angle)
end

return SpineUFOBullet
