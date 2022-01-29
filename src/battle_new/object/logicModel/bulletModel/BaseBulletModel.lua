--[[
子弹的基类 没有渲染层实例
@params {
	objinfo ObjectSendBulletData 子弹的构造数据
}
--]]
local BaseLogicModel = __Require('battle.object.logicModel.BaseLogicModel')
local BaseBulletModel = class('BaseBulletModel', BaseLogicModel)

------------ import ------------
------------ import ------------

------------ define ------------
------------ define ------------

--[[
constructor
--]]
function BaseBulletModel:ctor( ... )
	BaseLogicModel.ctor(self, ...)
end

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
@override
初始化
--]]
function BaseBulletModel:Init()
	BaseLogicModel.Init(self)

	------------ 初始化展示层模型 ------------
	self:InitViewModel()
	------------ 初始化展示层模型 ------------
end
--[[
@override
初始化固有属性
--]]
function BaseBulletModel:InitInnateProperty()
	BaseLogicModel.InitInnateProperty(self)

	------------ state info ------------
	-- 普通状态
	self.state = {
		cur = OState.SLEEP,
		pre = OState.SLEEP,
		pause = false,
		towards = BattleObjTowards.FORWARD
	}
	------------ state info ------------
end
--[[
初始化特有属性
--]]
function BaseBulletModel:InitUnitProperty()
	-- 攻击分段计数器
	self.phaseCounter = 0

	------------ location info ------------
	self.location = ObjectLocation.New(0, 0, 0, 0)
	self.zorderInBattle = 0
	------------ location info ------------
end
--[[
初始化展示层模型
--]]
function BaseBulletModel:InitViewModel()

end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- state logic begin --
---------------------------------------------------
--[[
唤醒物体
--]]
function BaseBulletModel:AwakeObject()
	self:SetState(OState.BATTLE)
	self:UpdateLocation()
end
--[[
沉睡物体
--]]
function BaseBulletModel:SleepObject()
	self:SetState(OState.SLEEP)
end
--[[
@override
是否被暂停
@return _ bool
--]]
function BaseBulletModel:IsPause()
	return self.state.pause
end
--[[
@override
暂停
--]]
function BaseBulletModel:PauseLogic()
	self.state.pause = true
end
--[[
@override
恢复物体
--]]
function BaseBulletModel:ResumeLogic()
	self.state.pause = false
end
--[[
获取状态
@params i int -1返回上一个状态
--]]
function BaseBulletModel:GetState(i)
	if -1 == i then
		return self.state.pre
	else
		return self.state.cur
	end
end
--[[
设置状态
@params s OState 状态
@params i int -1设置上一个状态
--]]
function BaseBulletModel:SetState(s, i)
	if -1 == i then
		self.state.pre = s
	else
		self.state.pre = self.state.cur
		self.state.cur = s
	end
end
--[[
所有动作是否完成
@return _ bool 
--]]
function BaseBulletModel:IsAllAnimationOver()
	return true
end
--[[
是否能进入下一波
@return result bool
--]]
function BaseBulletModel:CanEnterNextWave()
	return self:IsAllAnimationOver()
end
---------------------------------------------------
-- state logic end --
---------------------------------------------------

---------------------------------------------------
-- logic begin --
---------------------------------------------------
--[[
@override
主循环逻辑
--]]
function BaseBulletModel:Update(dt)
	-- 暂停直接返回
	if self:IsPause() then return end

	-- 自动行为逻辑
	self:AutoController(dt)
end
--[[
自动行为逻辑
--]]
function BaseBulletModel:AutoController(dt)
	-- 状态判断
	if OState.BATTLE == self:GetState() then

		if self:CanAttack() then

			-- 分段计数器增加
			self:SetPhaseCounter(self:GetPhaseCounter() + 1)
			-- 走攻击逻辑
			self:Attack(self:GetAttackTargetTag(), 1, self:GetPhaseCounter())

		elseif self:IsAllAnimationOver() then

			-- 杀死自己
			self:Die()
			return

		end

	end
end
---------------------------------------------------
-- logic end --
---------------------------------------------------

---------------------------------------------------
-- attack begin --
---------------------------------------------------
--[[
是否能攻击
@params targetTag int 攻击对象tag
@params dt number delta time
@return _ bool
--]]
function BaseBulletModel:CanAttack(targetTag, dt)
	return true
end
--[[
攻击
@params targetTag int 攻击对象 tag
@params percent number 分段百分比
@params phaseCounter int 分段计数
--]]
function BaseBulletModel:Attack(targetTag, percent, phaseCounter)
	-- 走回调
	local cb = self:GetCauseEffectCallback()

	if nil ~= cb then

		cb(percent, phaseCounter)

	end

	-- 是否需要震屏
	if self:ShouldShakeWorld() then
		self:RenderShakeWorld()
	end

	self:AttackEnd()
end
--[[
攻击结束
--]]
function BaseBulletModel:AttackEnd()
	self:Die()
end
---------------------------------------------------
-- attack end --
---------------------------------------------------

---------------------------------------------------
-- die logic begin --
---------------------------------------------------
--[[
子弹死亡
--]]
function BaseBulletModel:Die()
	self:KillSelf()
	self:DieEnd()
end
--[[
杀死自己
--]]
function BaseBulletModel:KillSelf()
	-- 变更状态
	self:SetState(OState.DIE)

	-- 注销事件监听
	self:UnregistObjectEventHandler()

	-- 移除缓存对象
	G_BattleLogicMgr:GetBData():RemoveABulletModel(self)
end
--[[
子弹死亡结束
--]]
function BaseBulletModel:DieEnd()
	self:Destroy()
end
--[[
子弹销毁
--]]
function BaseBulletModel:Destroy()
	if OState.DIE ~= self:GetState() then
		self:KillSelf()
	end
end
---------------------------------------------------
-- die logic end --
---------------------------------------------------

---------------------------------------------------
-- transform begin --
---------------------------------------------------
--[[
变化物体的坐标
@params p cc.p 坐标信息
--]]
function BaseBulletModel:ChangePosition(p)
	self:UpdateLocation()
end
--[[
刷新一次逻辑物体的坐标信息
--]]
function BaseBulletModel:UpdateLocation()
	
end
--[[
获取逻辑物体坐标信息
@return _ ObjectLocation
--]]
function BaseBulletModel:GetLocation()
	return self.location
end
--[[
获取旋转
--]]
function BaseBulletModel:GetRotate()

end
--[[
设置旋转
--]]
function BaseBulletModel:SetRotate(angle)
	
end
--[[
设置是否朝向x正方向
@params towards BattleObjTowards
--]]
function BaseBulletModel:SetOrientation(towards)

end
--[[
获取是否朝向x正方向
@return _ bool 是否朝向右
--]]
function BaseBulletModel:GetOrientation()
	return true
end
--[[
获取朝向
--]]
function BaseBulletModel:GetTowards()
	return self:GetOrientation() and BattleObjTowards.FORWARD or BattleObjTowards.NEGATIVE
end
--[[
zorder
--]]
function BaseBulletModel:GetZOrder()
	return self.zorderInBattle
end
function BaseBulletModel:SetZOrder(zorder)
	self.zorderInBattle = zorder
end
function BaseBulletModel:GetDefaultZOrder()
	return self:GetObjInfo().bulletZOrder
end
--[[
获取物体的静态碰撞框信息
@return _ cc.rect 碰撞框信息
--]]
function BaseBulletModel:GetStaticCollisionBox()
	return nil
end
--[[
获取物体静态碰撞框相对于 battle root 的rect信息
@return _ cc.rect 碰撞框信息
--]]
function BaseBulletModel:GetStaticCollisionBoxInBattleRoot()
	return nil
end
--[[
获取物体的静态ui框信息
@return _ cc.rect 碰撞框信息
--]]
function BaseBulletModel:GetStaticViewBox()
	return nil
end
--[[
修正一次子弹的初始位置
--]]
function BaseBulletModel:FixBulletOriLocation()
	local causeType = self:GetBulletCauseType()
	if ConfigEffectCauseType.POINT == causeType then

		-- 贴到物体身上的特效 逻辑层不做修正
		self:FixPointBulletOriLocation()

	elseif ConfigEffectCauseType.SINGLE == causeType then

		self:FixSingleBulletOriLocation()

	elseif ConfigEffectCauseType.SCREEN == causeType then

		self:FixScreenBulletOriLocation()

	end
end
--[[
修正指向性子弹的位置
--]]
function BaseBulletModel:FixPointBulletOriLocation()

end
--[[
修正中点连线的子弹位置
--]]
function BaseBulletModel:FixSingleBulletOriLocation()
	-- 贴在战斗root上的屏幕特效 逻辑层修正位置
	-- 坐标
	local targetPos = self:GetObjInfo().targetLocation
	-- zorder
	local zorder = self:GetDefaultZOrder() < 0 and 1 or BATTLE_E_ZORDER.BULLET
	if self:GetObjInfo().needHighlight then
		zorder = zorder + G_BattleLogicMgr:GetFixedHighlightZOrder()
	end

	-- 设置位置
	self:ChangePosition(targetPos)
	-- 设置zorder
	self:SetZOrder(zorder)

	--***---------- 刷新渲染层 ----------***--
	self:RefreshRenderViewPosition()
	--***---------- 刷新渲染层 ----------***--
end
--[[
修正全屏子弹的位置
--]]
function BaseBulletModel:FixScreenBulletOriLocation()
	-- 贴在战斗root上的屏幕特效 逻辑层修正位置
	local targetPos = self:GetObjInfo().targetLocation
	-- 坐标
	local targetPos = self:GetObjInfo().targetLocation
	-- zorder
	local zorder = self:GetDefaultZOrder() < 0 and 1 or BATTLE_E_ZORDER.BULLET
	if self:GetObjInfo().needHighlight then
		zorder = zorder + G_BattleLogicMgr:GetFixedHighlightZOrder()
	end

	-- 设置位置
	self:ChangePosition(targetPos)
	-- 设置zorder
	self:SetZOrder(zorder)

	--***---------- 刷新渲染层 ----------***--
	self:RefreshRenderViewPosition()
	--***---------- 刷新渲染层 ----------***--
end
---------------------------------------------------
-- transform end --
---------------------------------------------------

---------------------------------------------------
-- event handler begin --
---------------------------------------------------
--[[
注册物体监听事件
--]]
function BaseBulletModel:RegisterObjectEventHandler()
	local eventHandlerInfo = {
		{member = 'objDieEventHandler_', 		eventType = ObjectEvent.OBJECT_DIE, 		handler = handler(self, self.ObjectEventDieHandler)}
	}

	for _,v in ipairs(eventHandlerInfo) do
		if nil == self[v.member] then
			self[v.member] = v.handler
		end
		G_BattleLogicMgr:AddObjEvent(v.eventType, self, self[v.member])
	end
end
--[[
注销物体监听事件
--]]
function BaseBulletModel:UnregistObjectEventHandler()
	local eventHandlerInfo = {
		{member = self.objDieEventHandler_, 		eventType = ObjectEvent.OBJECT_DIE, 		handler = handler(self, self.ObjectEventDieHandler)}
	}

	for _,v in ipairs(eventHandlerInfo) do
		G_BattleLogicMgr:RemoveObjEvent(v.eventType, self)
	end
end
--[[
注册展示层的事件处理回调
--]]
function BaseBulletModel:RegistViewModelEventHandler()
	
end
--[[
注销展示层的事件处理回调
--]]
function BaseBulletModel:UnregistViewModelEventHandler()

end
--[[
物体死亡事件
@params ... 
	args table passed args
--]]
function BaseBulletModel:ObjectEventDieHandler( ... )

end
---------------------------------------------------
-- event handler end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
获取攻击对象tag
@return _ int
--]]
function BaseBulletModel:GetAttackTargetTag()
	return self:GetObjInfo().targetTag
end
--[[
获取攻击对象objmodel
@return _ BaseLogicModel
--]]
function BaseBulletModel:GetAttackTarget()
	return G_BattleLogicMgr:IsObjAliveByTag(self:GetAttackTargetTag())
end
--[[
获取分段计数器
--]]
function BaseBulletModel:GetPhaseCounter()
	return self.phaseCounter
end
function BaseBulletModel:SetPhaseCounter(value)
	self.phaseCounter = value
end
--[[
获取攻击事件回调
@return _ function 攻击事件回调
--]]
function BaseBulletModel:GetCauseEffectCallback()
	return self:GetObjInfo().causeEffectCallback
end
--[[
获取展示层tag
--]]
function BaseBulletModel:GetViewModelTag()
	return nil
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

---------------------------------------------------
-- base info get set begin --
---------------------------------------------------
--[[
获取子弹类型
@return _ ConfigEffectBulletType
--]]
function BaseBulletModel:GetBulletType()
	return self:GetObjInfo().otype
end
--[[
获取子弹的作用类型
@return _ ConfigEffectCauseType
--]]
function BaseBulletModel:GetBulletCauseType()
	return self:GetObjInfo().causeType
end
--[[
获取子弹特效的id
--]]
function BaseBulletModel:GetAnimationEffectId()
	return nil
end
--[[
获取子弹特效的缩放
--]]
function BaseBulletModel:GetAnimationScaleConfig()
	return self:GetObjInfo().bulletScale
end
--[[
获取施法者tag
--]]
function BaseBulletModel:GetOwnerTag()
	return self:GetObjInfo().ownerTag
end
--[[
获取施法者
--]]
function BaseBulletModel:GetOwner()
	return G_BattleLogicMgr:IsObjAliveByTag(self:GetOwnerTag())
end
--[[
获取子弹的动画名字
--]]
function BaseBulletModel:GetBulletActionAnimationName()
	return self:GetObjInfo().actionName
end
--[[
获取是否需要震屏
--]]
function BaseBulletModel:ShouldShakeWorld()
	return self:GetObjInfo().shouldShakeWorld
end
---------------------------------------------------
-- base info get set end --
---------------------------------------------------

---------------------------------------------------
-- render refresh begin --
---------------------------------------------------
--[[
@override
做spine动画
@params setToSetupPose bool 是否恢复第一帧
@params timeScale int 动画速度缩放
@params setAnimationName string set的动画名字
@params setAnimationLoop bool set的动画是否循环
@params addAnimationName string add的动画名字
@params addAnimationLoop bool add的动画是否循环
--]]
function BaseBulletModel:RefreshRenderAnimation(setToSetupPose, timeScale, setAnimationName, setAnimationLoop, addAnimationName, addAnimationLoop)
	--***---------- 刷新渲染层 ----------***--
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'ObjectViewDoAnimation',
		self:GetViewModelTag(),
		setToSetupPose, timeScale, setAnimationName, setAnimationLoop, addAnimationName, addAnimationLoop
	)
	--***---------- 刷新渲染层 ----------***--
end
--[[
@override
设置动画的时间缩放
@params timeScale number 时间缩放
--]]
function BaseBulletModel:RefreshRenderAnimationTimeScale(timeScale)
	--***---------- 刷新渲染层 ----------***--
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'ObjectViewSetAnimationTimeScale',
		self:GetViewModelTag(),
		timeScale
	)
	--***---------- 刷新渲染层 ----------***--
end
--[[
@override
同步一次坐标
--]]
function BaseBulletModel:RefreshRenderViewPosition()
	--***---------- 刷新渲染层 ----------***--
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'SetObjectViewPosition',
		self:GetViewModelTag(),
		self:GetLocation().po.x,
		self:GetLocation().po.y
	)

	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'SetObjectViewZOrder',
		self:GetViewModelTag(),
		self:GetZOrder()
	)
	--***---------- 刷新渲染层 ----------***--
end
--[[
@override
同步一次朝向
--]]
function BaseBulletModel:RefreshRenderViewTowards()
	--***---------- 刷新渲染层 ----------***--
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'SetObjectViewTowards',
		self:GetViewModelTag(),
		self:GetTowards()
	)
	--***---------- 刷新渲染层 ----------***--
end
--[[
@override
同步一次旋转
--]]
function BaseBulletModel:RefreshRenderViewRotate()
	--***---------- 刷新渲染层 ----------***--
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'SetObjectViewRotate',
		self:GetViewModelTag(),
		self:GetRotate()
	)
	--***---------- 刷新渲染层 ----------***--
end
--[[
震屏
--]]
function BaseBulletModel:RenderShakeWorld()
	--***---------- 刷新渲染层 ----------***--
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'ShakeWorld'
	)
	--***---------- 刷新渲染层 ----------***--
end
---------------------------------------------------
-- render refresh end --
---------------------------------------------------

return BaseBulletModel
