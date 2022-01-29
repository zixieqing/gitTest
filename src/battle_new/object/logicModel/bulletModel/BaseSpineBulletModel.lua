--[[
spine子弹基类
该类型子弹只是纯播一个spine动画
该类型因为直接加在avatar上面 所以不处理朝向
@params {
	objinfo ObjectSendBulletData 子弹的构造数据
}
--]]
local BaseBulletModel = __Require('battle.object.logicModel.bulletModel.BaseBulletModel')
local BaseSpineBulletModel = class('BaseSpineBulletModel', BaseBulletModel)

------------ import ------------
------------ import ------------

------------ define ------------
------------ define ------------

--[[
constructor
--]]
function BaseSpineBulletModel:ctor( ... )
	BaseBulletModel.ctor(self, ...)
end

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
@override
初始化
--]]
function BaseSpineBulletModel:Init()
	BaseBulletModel.Init(self)

	-- 子弹在类中创建渲染层模型
	self:CreateRenderView()
end
--[[
@override
初始化展示层模型
--]]
function BaseSpineBulletModel:InitViewModel()
	local spineDataStruct = BattleUtils.GetEffectSpineDataStructBySpineId(
		self:GetAnimationEffectId(),
		self:GetSpineLoadingScale()
	)

	local viewModel = __Require('battle.viewModel.SpineViewModel').new(
		ObjectViewModelConstructorStruct.New(
			G_BattleLogicMgr:GetBData():GetTagByTagType(BattleTags.BT_VIEW_MODEL),
			self:GetOTag(),
			self:GetAnimationScaleConfig(),
			spineDataStruct
		)
	)

	self:SetViewModel(viewModel)

	-- 注册spine事件
	self:RegistViewModelEventHandler()

	-- 向内存中添加一个展示层模型
	viewModel:Awake()
end
--[[
创建渲染层模型
--]]
function BaseSpineBulletModel:CreateRenderView()
	--***---------- 刷新渲染层 ----------***--
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'CreateABulletObjectView',
		self:GetViewModelTag(),
		self:GetObjInfo()
	)
	--***---------- 刷新渲染层 ----------***--
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
function BaseSpineBulletModel:AwakeObject()
	BaseBulletModel.AwakeObject(self)

	-- 修正一次初始transform
	self:FixBulletOriTransform()

	--***---------- 刷新渲染层 ----------***--
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'AwakeABulletObjectView',
		self:GetViewModelTag()
	)
	--***---------- 刷新渲染层 ----------***--

	self:StartDoBulletAnimation()
end
--[[
所有动作是否完成
@return _ bool 
--]]
function BaseSpineBulletModel:IsAllAnimationOver()
	return (nil == self:GetViewModel():GetRunningAnimationName())
end
---------------------------------------------------
-- state logic end --
---------------------------------------------------

---------------------------------------------------
-- logic begin --
---------------------------------------------------
--[[
自动行为逻辑
--]]
function BaseSpineBulletModel:AutoController(dt)
	-- 状态判断
	if OState.BATTLE == self:GetState() then

		-- 该类型不再update中处理是否能造成效果 而在spine的事件中处理
		if self:IsAllAnimationOver() then
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
@override
是否能攻击
@params targetTag int 攻击对象tag
@params dt number delta time
@return _ bool
--]]
function BaseSpineBulletModel:CanAttack(targetTag, dt)
	return false
end
--[[
@override
攻击
@params targetTag int 攻击对象 tag
@params percent number 分段百分比
@params phaseCounter int 分段计数
--]]
function BaseSpineBulletModel:Attack(targetTag, percent, phaseCounter)
	-- 走回调
	local cb = self:GetCauseEffectCallback()

	if nil ~= cb then

		cb(percent, phaseCounter)

	end

	-- 是否需要震屏
	if self:ShouldShakeWorld() then
		self:RenderShakeWorld()
	end
end
--[[
@override
攻击结束
--]]
function BaseSpineBulletModel:AttackEnd()

end
---------------------------------------------------
-- attack end --
---------------------------------------------------

---------------------------------------------------
-- die logic begin --
---------------------------------------------------
--[[
@override
杀死自己
--]]
function BaseSpineBulletModel:KillSelf()
	self:KillViewModel()

	BaseBulletModel.KillSelf(self)
end
--[[
杀死view model
--]]
function BaseSpineBulletModel:KillViewModel()
	if nil ~= self:GetViewModel() then
		self:GetViewModel():ClearSpineTracks()
		self:GetViewModel():Kill()
	end
end
--[[
@override
子弹死亡结束
--]]
function BaseSpineBulletModel:DieEnd()
	BaseBulletModel.DieEnd(self)
end
--[[
@override
子弹销毁
--]]
function BaseSpineBulletModel:Destroy()
	BaseBulletModel.Destroy(self)

	self:DestroyRender()
end
--[[
销毁渲染层
--]]
function BaseSpineBulletModel:DestroyRender()
	--***---------- 刷新渲染层 ----------***--
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'DestroyABulletObjectView',
		self:GetViewModelTag()
	)
	--***---------- 刷新渲染层 ----------***--
end
---------------------------------------------------
-- die logic end --
---------------------------------------------------

---------------------------------------------------
-- pause logic begin --
---------------------------------------------------
--[[
@override
暂停
--]]
function BaseSpineBulletModel:PauseLogic()
	BaseBulletModel.PauseLogic(self)

	local timeScale = self:GetAvatarTimeScale()

	self:SetAnimationTimeScale(timeScale)

	--***---------- 刷新渲染层 ----------***--
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'PauseAObjectView',
		self:GetViewModelTag(),
		timeScale
	)
	--***---------- 刷新渲染层 ----------***--
end
--[[
@override
恢复物体
--]]
function BaseSpineBulletModel:ResumeLogic()
	BaseBulletModel.ResumeLogic(self)

	local timeScale = self:GetAvatarTimeScale()

	self:SetAnimationTimeScale(timeScale)

	--***---------- 刷新渲染层 ----------***--
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'ResumeAObjectView',
		self:GetViewModelTag(),
		timeScale
	)
	--***---------- 刷新渲染层 ----------***--
end
---------------------------------------------------
-- pause logic end --
---------------------------------------------------

---------------------------------------------------
-- animation control begin --
---------------------------------------------------
--[[
开始做子弹的spine动画
--]]
function BaseSpineBulletModel:StartDoBulletAnimation()
	-- 判断是否存在xxx_end动作 如果存在在原本的动作上增加end动作 end动作中的事件不处理
	local endAnimationName = self:GetBulletEndAnimationName()

	if nil ~= endAnimationName then
		-- 判断展示层是否存在该动画
		if self:GetViewModel():HasAnimationByName(endAnimationName) then

			self:DoAnimation(
				true, nil,
				self:GetBulletActionAnimationName(), false,
				endAnimationName, false
			)

			--***---------- 刷新渲染层 ----------***--
			self:RefreshRenderAnimation(
				true, nil,
				self:GetBulletActionAnimationName(), false,
				endAnimationName, false
			)
			--***---------- 刷新渲染层 ----------***--

			return

		end
	end

	self:DoAnimation(
		true, nil,
		self:GetBulletActionAnimationName(), false
	)

	--***---------- 刷新渲染层 ----------***--
	self:RefreshRenderAnimation(
		true, nil,
		self:GetBulletActionAnimationName(), false
	)
	--***---------- 刷新渲染层 ----------***--
end
--[[
@override
让物体做一个动画动作
@params setToSetupPose bool 是否恢复第一帧
@params timeScale int 动画速度缩放
@params setAnimationName string set的动画名字
@params setAnimationLoop bool set的动画是否循环
@params addAnimationName string add的动画名字
@params addAnimationLoop bool add的动画是否循环
--]]
function BaseSpineBulletModel:DoAnimation(setToSetupPose, timeScale, setAnimationName, setAnimationLoop, addAnimationName, addAnimationLoop)
	if true == setToSetupPose then
		self:GetViewModel():SetSpineToSetupPose()
	end

	if nil ~= setAnimationName then
		self:GetViewModel():SetSpineAnimation(setAnimationName, setAnimationLoop)
	end

	if nil ~= addAnimationName then
		self:GetViewModel():AddSpineAnimation(addAnimationName, addAnimationLoop)
	end

	if nil ~= timeScale then
		self:SetAnimationTimeScale(timeScale)
	end
end
--[[
@override
清空一个物体的动画动作
--]]
function BaseSpineBulletModel:ClearAnimations()
	self:GetViewModel():ClearSpineTracks()
end
--[[
@override
设置动画的时间缩放
@params timeScale number 时间缩放
--]]
function BaseSpineBulletModel:SetAnimationTimeScale(timeScale)
	self:GetViewModel():SetAnimationTimeScale(timeScale)
end
--[[
@override
获取动画的时间缩放
@return _ number 动画时间缩放
--]]
function BaseSpineBulletModel:GetAnimationTimeScale()
	return self:GetViewModel():GetAnimationTimeScale()
end
--[[
@override
获取当前正在进行的动作动画名
@return _ sp.AnimationName 动作动画名
--]]
function BaseSpineBulletModel:GetCurrentAnimationName()
	return self:GetViewModel():GetRunningSpineAniName()
end
--[[
获取物体当前动画的速度缩放
@params o bool 是否获取原始速度
@return timeScale number 速度缩放
--]]
function BaseSpineBulletModel:GetAvatarTimeScale(o)
	-- 暂停或者冻结 默认返回0
	if self:IsPause() then
		return 0
	end

	local avatarTimeScale = 1

	if true == o then return avatarTimeScale end

	return avatarTimeScale
end
---------------------------------------------------
-- animation control end --
---------------------------------------------------

---------------------------------------------------
-- transform begin --
---------------------------------------------------
--[[
变化物体的坐标
@params p cc.p 坐标信息
--]]
function BaseSpineBulletModel:ChangePosition(p)
	self:GetViewModel():SetPositionX(p.x)
	self:GetViewModel():SetPositionY(p.y)

	BaseBulletModel.ChangePosition(self, p)
end
--[[
刷新一次逻辑物体的坐标信息
--]]
function BaseSpineBulletModel:UpdateLocation()
	BaseBulletModel.UpdateLocation(self)

	-- pos
	self.location.po.x = self:GetViewModel():GetPositionX()
	self.location.po.y = self:GetViewModel():GetPositionY()

	-- rc
	local rc = G_BattleLogicMgr:GetRowColByPos(self:GetViewModel():GetPosition())

	self.location.rc.r = rc.r
	self.location.rc.c = rc.c
end
--[[
设置朝向
@params towards BattleObjTowards
--]]
function BaseSpineBulletModel:SetOrientation(towards)
	self:GetViewModel():SetTowards(towards)
end
--[[
获取朝向
@return _ bool 是否朝向右
--]]
function BaseSpineBulletModel:GetOrientation()
	return BattleObjTowards.FORWARD == self:GetViewModel():GetTowards()
end
--[[
@override
获取物体的静态碰撞框信息
@return _ cc.rect 碰撞框信息
--]]
function BaseSpineBulletModel:GetStaticCollisionBox()
	return self:GetViewModel():GetStaticCollisionBox()
end
--[[
@override
获取物体静态碰撞框相对于 battle root 的rect信息
@return _ cc.rect 碰撞框信息
--]]
function BaseSpineBulletModel:GetStaticCollisionBoxInBattleRoot()
	local collisionBox = self:GetStaticCollisionBox()
	if nil ~= collisionBox then
		local location = self:GetLocation().po
		local fixedBox = cc.rect(
			location.x + collisionBox.x,
			location.y + collisionBox.y,
			collisionBox.width,
			collisionBox.height
		)
		return fixedBox
	else
		return nil
	end
end
--[[
@override
获取物体的静态ui框信息
@return _ cc.rect 碰撞框信息
--]]
function BaseSpineBulletModel:GetStaticViewBox()
	return self:GetViewModel():GetStaticViewBox()
end
--[[
修正一次初始的transform
--]]
function BaseSpineBulletModel:FixBulletOriTransform()
	-- 修正初始位置
	self:FixBulletOriLocation()
end
---------------------------------------------------
-- transform end --
---------------------------------------------------

---------------------------------------------------
-- event handler begin --
---------------------------------------------------
--[[
注册展示层的事件处理回调
--]]
function BaseSpineBulletModel:RegistViewModelEventHandler()
	if nil ~= self:GetViewModel() then
		-- 注册动作做完的回调
		self:GetViewModel():RegistEventListener(
			sp.EventType.ANIMATION_COMPLETE,
			handler(self, self.SpineEventCompleteHandler)
		)

		-- 注册自定义事件的回调
		self:GetViewModel():RegistEventListener(
			sp.EventType.ANIMATION_EVENT,
			handler(self, self.SpineEventCustomHandler)
		)
	end
end
--[[
注销展示层的事件处理回调
--]]
function BaseSpineBulletModel:UnregistViewModelEventHandler()

end
---------------------------------------------------
-- event handler end --
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
function BaseSpineBulletModel:SpineEventCompleteHandler(eventType, event)
	if GState.START ~= G_BattleLogicMgr:GetGState() or OState.DIE == self:GetState() then return end

	local animationName = event.animation

	if self:GetBulletActionAnimationName() == animationName then
		self:AttackEnd()
	end
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
function BaseSpineBulletModel:SpineEventCustomHandler(eventType, event)
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

	end

end
---------------------------------------------------
-- spine handler end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
获取spine子弹加载时的缩放比
--]]
function BaseSpineBulletModel:GetSpineLoadingScale()
	local owner = self:GetOwner()
	if owner then
		return G_BattleLogicMgr:GetSpineAvatarScaleByCardId(owner:GetObjectConfigId())
	end
	return CARD_DEFAULT_SCALE
end
--[[
获取spine动画做完动画后的衔接动画名
--]]
function BaseSpineBulletModel:GetBulletEndAnimationName()
	return string.format('%s_end', self:GetBulletActionAnimationName())
end
--[[
@override
获取展示层tag
--]]
function BaseSpineBulletModel:GetViewModelTag()
	return self:GetViewModel():GetViewModelTag()
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

---------------------------------------------------
-- base info get set begin --
---------------------------------------------------
--[[
@override
获取子弹特效的id
--]]
function BaseSpineBulletModel:GetAnimationEffectId()
	return self:GetObjInfo().spineId
end
--[[
@override
获取子弹特效的缩放
--]]
function BaseSpineBulletModel:GetAnimationScaleConfig()
	return self:GetObjInfo().bulletScale
end
---------------------------------------------------
-- base info get set end --
---------------------------------------------------

return BaseSpineBulletModel
