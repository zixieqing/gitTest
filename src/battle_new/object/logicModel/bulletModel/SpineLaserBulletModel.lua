--[[
spine激光基类
激光最多由三部分组成
	激光头 附加在受法者身上的部位 可以不存在
	激光束 连接头尾的部位 本体 必须存在
	激光尾 附加在施法者身上的部位 可以不存在
激光束是必须的
@params {
	objinfo ObjectSendBulletData 子弹的构造数据
}
--]]
local BaseSpineBulletModel = __Require('battle.object.logicModel.bulletModel.BaseSpineBulletModel')
local SpineLaserBulletModel = class('SpineLaserBulletModel', BaseSpineBulletModel)

------------ import ------------
------------ import ------------

------------ define ------------
------------ define ------------

--[[
constructor
--]]
function SpineLaserBulletModel:ctor( ... )
	BaseSpineBulletModel.ctor(self, ...)
end

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化特有属性
--]]
function SpineLaserBulletModel:InitUnitProperty()
	BaseSpineBulletModel.InitUnitProperty(self)

	self.laserHeadViewModel = nil
	self.laserEndViewModel = nil

	-- 目标位置
	self.targetLocation = cc.p(self:GetObjInfo().targetLocation.x, self:GetObjInfo().targetLocation.y)
	-- 施法者位置
	self.ownerLocation = cc.p(self:GetObjInfo().oriLocation.x, self:GetObjInfo().oriLocation.y)
end
--[[
@override
初始化展示层模型
--]]
function SpineLaserBulletModel:InitViewModel()
	self:InitLaserBodyViewModel()
	self:InitLaserHeadViewModel()
	self:InitLaserEndViewModel()

	-- 注册spine事件
	self:RegistViewModelEventHandler()
end
--[[
初始化激光束
--]]
function SpineLaserBulletModel:InitLaserBodyViewModel()
	-- 初始化激光束的view model
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

	-- 向内存中添加一个展示层模型
	viewModel:Awake()
end
--[[
初始化激光头
--]]
function SpineLaserBulletModel:InitLaserHeadViewModel()
	local effectId = self:GetAnimationEffectId()
	if BattleUtils.SpineHasAnimationByName(effectId, SpineType.EFFECT, self:GetLaserPartAnimationName(sp.LaserAnimationName.laserHead)) then
		-- 初始化激光头的view model
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

		self:SetLaserHeadViewModel(viewModel)

		-- 向内存中添加一个展示层模型
		viewModel:Awake()
	end
end
--[[
初始化激光尾
--]]
function SpineLaserBulletModel:InitLaserEndViewModel()
	local effectId = self:GetAnimationEffectId()
	if BattleUtils.SpineHasAnimationByName(effectId, SpineType.EFFECT, self:GetLaserPartAnimationName(sp.LaserAnimationName.laserEnd)) then
		-- 初始化激光头的view model
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

		self:SetLaserEndViewModel(viewModel)

		-- 向内存中添加一个展示层模型
		viewModel:Awake()
	end
end
--[[
创建渲染层模型
--]]
function SpineLaserBulletModel:CreateRenderView()
	-- 创建激光束
	--***---------- 刷新渲染层 ----------***--
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'CreateABulletObjectView',
		self:GetLaserBodyViewModel():GetViewModelTag(),
		self:GetObjInfo()
	)
	--***---------- 刷新渲染层 ----------***--

	--***---------- 刷新渲染层 ----------***--
	G_BattleLogicMgr:AddRenderOperate(
		'G_BattleRenderMgr',
		'SetLaserPart',
		self:GetLaserBodyViewModel():GetViewModelTag(),
		sp.LaserAnimationName.laserBody
	)
	--***---------- 刷新渲染层 ----------***--

	-- 创建激光头
	if nil ~= self:GetLaserHeadViewModel() then
		--***---------- 刷新渲染层 ----------***--
		G_BattleLogicMgr:AddRenderOperate(
			'G_BattleRenderMgr',
			'CreateABulletObjectView',
			self:GetLaserHeadViewModel():GetViewModelTag(),
			self:GetObjInfo()
		)
		--***---------- 刷新渲染层 ----------***--

		--***---------- 刷新渲染层 ----------***--
		G_BattleLogicMgr:AddRenderOperate(
			'G_BattleRenderMgr',
			'SetLaserPart',
			self:GetLaserHeadViewModel():GetViewModelTag(),
			sp.LaserAnimationName.laserHead
		)
		--***---------- 刷新渲染层 ----------***--
	end

	-- 创建激光尾
	if nil ~= self:GetLaserEndViewModel() then
		--***---------- 刷新渲染层 ----------***--
		G_BattleLogicMgr:AddRenderOperate(
			'G_BattleRenderMgr',
			'CreateABulletObjectView',
			self:GetLaserEndViewModel():GetViewModelTag(),
			self:GetObjInfo()
		)
		--***---------- 刷新渲染层 ----------***--

		--***---------- 刷新渲染层 ----------***--
		G_BattleLogicMgr:AddRenderOperate(
			'G_BattleRenderMgr',
			'SetLaserPart',
			self:GetLaserEndViewModel():GetViewModelTag(),
			sp.LaserAnimationName.laserEnd
		)
		--***---------- 刷新渲染层 ----------***--
	end
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
function SpineLaserBulletModel:AwakeObject()
	self:SetState(OState.BATTLE)

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
---------------------------------------------------
-- state logic end --
---------------------------------------------------

---------------------------------------------------
-- die logic begin --
---------------------------------------------------
--[[
@override
杀死view model
--]]
function SpineLaserBulletModel:KillViewModel()
	-- 杀死三个部位的view model
	if nil ~= self:GetLaserHeadViewModel() then
		self:GetLaserHeadViewModel():ClearSpineTracks()
		self:GetLaserHeadViewModel():Kill()
	end

	if nil ~= self:GetLaserBodyViewModel() then
		self:GetLaserBodyViewModel():ClearSpineTracks()
		self:GetLaserBodyViewModel():Kill()
	end

	if nil ~= self:GetLaserEndViewModel() then
		self:GetLaserEndViewModel():ClearSpineTracks()
		self:GetLaserEndViewModel():Kill()
	end
end
--[[
@override
销毁渲染层
--]]
function SpineLaserBulletModel:DestroyRender()
	if nil ~= self:GetLaserHeadViewModel() then
		--***---------- 刷新渲染层 ----------***--
		G_BattleLogicMgr:AddRenderOperate(
			'G_BattleRenderMgr',
			'DestroyABulletObjectView',
			self:GetLaserHeadViewModel():GetViewModelTag()
		)
		--***---------- 刷新渲染层 ----------***--
	end

	if nil ~= self:GetLaserBodyViewModel() then
		--***---------- 刷新渲染层 ----------***--
		G_BattleLogicMgr:AddRenderOperate(
			'G_BattleRenderMgr',
			'DestroyABulletObjectView',
			self:GetLaserBodyViewModel():GetViewModelTag()
		)
		--***---------- 刷新渲染层 ----------***--
	end

	if nil ~= self:GetLaserEndViewModel() then
		--***---------- 刷新渲染层 ----------***--
		G_BattleLogicMgr:AddRenderOperate(
			'G_BattleRenderMgr',
			'DestroyABulletObjectView',
			self:GetLaserEndViewModel():GetViewModelTag()
		)
		--***---------- 刷新渲染层 ----------***--
	end
	
end
---------------------------------------------------
-- die logic end --
---------------------------------------------------

---------------------------------------------------
-- animation control begin --
---------------------------------------------------
--[[
开始做子弹的spine动画
--]]
function SpineLaserBulletModel:StartDoBulletAnimation()
		-- 激光束
	local laserBodyViewModel = self:GetLaserBodyViewModel()
	if nil ~= laserBodyViewModel then

		local laserBodyAnimationName = self:GetLaserPartAnimationName(sp.LaserAnimationName.laserBody)

		--***---------- 刷新渲染层 ----------***--
		G_BattleLogicMgr:AddRenderOperate(
			'G_BattleRenderMgr',
			'AwakeABulletObjectView',
			laserBodyViewModel:GetViewModelTag()
		)
		--***---------- 刷新渲染层 ----------***--

		self:DoAnimation(
			laserBodyViewModel,
			true, nil,
			laserBodyAnimationName, false,
			endAnimationName, false
		)

		--***---------- 刷新渲染层 ----------***--
		G_BattleLogicMgr:AddRenderOperate(
			'G_BattleRenderMgr',
			'ObjectViewDoAnimation',
			laserBodyViewModel:GetViewModelTag(),
			true, nil,
			laserBodyAnimationName, false,
			endAnimationName, false
		)
		--***---------- 刷新渲染层 ----------***--

	end

	-- 激光尾
	local laserEndViewModel = self:GetLaserEndViewModel()
	if nil ~= laserEndViewModel then

		local laserEndAnimationName = self:GetLaserPartAnimationName(sp.LaserAnimationName.laserEnd)

		--***---------- 刷新渲染层 ----------***--
		G_BattleLogicMgr:AddRenderOperate(
			'G_BattleRenderMgr',
			'AwakeABulletObjectView',
			laserEndViewModel:GetViewModelTag()
		)
		--***---------- 刷新渲染层 ----------***--

		self:DoAnimation(
			laserEndViewModel,
			true, nil,
			laserEndAnimationName, false,
			endAnimationName, false
		)

		--***---------- 刷新渲染层 ----------***--
		G_BattleLogicMgr:AddRenderOperate(
			'G_BattleRenderMgr',
			'ObjectViewDoAnimation',
			laserEndViewModel:GetViewModelTag(),
			true, nil,
			laserEndAnimationName, false,
			endAnimationName, false
		)
		--***---------- 刷新渲染层 ----------***--

	end
end
--[[
@override
让物体做一个动画动作
@params viewModel BaseViewModel 展示层模型
@params setToSetupPose bool 是否恢复第一帧
@params timeScale int 动画速度缩放
@params setAnimationName string set的动画名字
@params setAnimationLoop bool set的动画是否循环
@params addAnimationName string add的动画名字
@params addAnimationLoop bool add的动画是否循环
--]]
function SpineLaserBulletModel:DoAnimation(viewModel, setToSetupPose, timeScale, setAnimationName, setAnimationLoop, addAnimationName, addAnimationLoop)
	if true == setToSetupPose then
		viewModel:SetSpineToSetupPose()
	end

	if nil ~= setAnimationName then
		viewModel:SetSpineAnimation(setAnimationName, setAnimationLoop)
	end

	if nil ~= addAnimationName then
		viewModel:AddSpineAnimation(addAnimationName, addAnimationLoop)
	end

	if nil ~= timeScale then
		viewModel:SetAnimationTimeScale(timeScale)
	end
end
---------------------------------------------------
-- animation control end --
---------------------------------------------------

---------------------------------------------------
-- transform begin --
---------------------------------------------------
--[[
@override
修正一次初始的transform
--]]
function SpineLaserBulletModel:FixBulletOriTransform()
	self:FixLaserTransform()
end
--[[
修正激光的transform
--]]
function SpineLaserBulletModel:FixLaserTransform()
	self:FixLaserHeadTransform()
	self:FixLaserBodyTransform()
	self:FixLaserEndTransform()
end
--[[
修正激光头的transform
--]]
function SpineLaserBulletModel:FixLaserHeadTransform()
	local laserHeadViewModel = self:GetLaserHeadViewModel()

	if nil ~= laserHeadViewModel then

		-- 激光头只设置一次位置
		local targetLocation = self:GetTargetLocation()
		laserHeadViewModel:SetPosition(targetLocation)

		--***---------- 刷新渲染层 ----------***--
		G_BattleLogicMgr:AddRenderOperate(
			'G_BattleRenderMgr',
			'SetObjectViewPosition',
			laserHeadViewModel:GetViewModelTag(), laserHeadViewModel:GetPositionX(), laserHeadViewModel:GetPositionY()
		)
		--***---------- 刷新渲染层 ----------***--

		local zorder = BATTLE_E_ZORDER.BULLET
		if self:GetObjInfo().needHighlight then
			zorder = zorder + G_BattleLogicMgr:GetFixedHighlightZOrder()
		end

		--***---------- 刷新渲染层 ----------***--
		G_BattleLogicMgr:AddRenderOperate(
			'G_BattleRenderMgr',
			'SetObjectViewZOrder',
			laserHeadViewModel:GetViewModelTag(), zorder
		)
		--***---------- 刷新渲染层 ----------***--

	end
end
--[[
修正激光束的transform
--]]
function SpineLaserBulletModel:FixLaserBodyTransform()
	local laserBodyViewModel = self:GetLaserBodyViewModel()

	if nil ~= laserBodyViewModel then

		local ownerLocation = self:GetOwnerLocation()
		local targetLocation = self:GetTargetLocation()

		-- 设置激光束位置
		laserBodyViewModel:SetPosition(ownerLocation)
		--***---------- 刷新渲染层 ----------***--
		G_BattleLogicMgr:AddRenderOperate(
			'G_BattleRenderMgr',
			'SetObjectViewPosition',
			laserBodyViewModel:GetViewModelTag(), laserBodyViewModel:GetPositionX(), laserBodyViewModel:GetPositionY()
		)
		--***---------- 刷新渲染层 ----------***--

		local zorder = BATTLE_E_ZORDER.BULLET
		if self:GetObjInfo().needHighlight then
			zorder = zorder + G_BattleLogicMgr:GetFixedHighlightZOrder()
		end

		--***---------- 刷新渲染层 ----------***--
		G_BattleLogicMgr:AddRenderOperate(
			'G_BattleRenderMgr',
			'SetObjectViewZOrder',
			laserBodyViewModel:GetViewModelTag(), zorder
		)
		--***---------- 刷新渲染层 ----------***--

		-- 激光长度
		local laserLength = cc.pGetDistance(targetLocation, ownerLocation)

		--***---------- 刷新渲染层 ----------***--
		G_BattleLogicMgr:AddRenderOperate(
			'G_BattleRenderMgr',
			'FixLaserBodyLength',
			laserBodyViewModel:GetViewModelTag(), laserLength
		)
		--***---------- 刷新渲染层 ----------***--

		-- 激光角度
		local angle = BattleUtils.GetAngleByPoints(ownerLocation, targetLocation)
		--***---------- 刷新渲染层 ----------***--
		G_BattleLogicMgr:AddRenderOperate(
			'G_BattleRenderMgr',
			'SetObjectViewRotate',
			laserBodyViewModel:GetViewModelTag(), angle
		)
		--***---------- 刷新渲染层 ----------***--

		-- 激光朝向
		if targetLocation.x < ownerLocation.x then
			-- 反方向
			laserBodyViewModel:SetTowards(BattleObjTowards.NEGATIVE)
		else
			-- 正方向
			laserBodyViewModel:SetTowards(BattleObjTowards.FORWARD)
		end
		--***---------- 刷新渲染层 ----------***--
		G_BattleLogicMgr:AddRenderOperate(
			'G_BattleRenderMgr',
			'SetObjectViewTowards',
			laserBodyViewModel:GetViewModelTag(), laserBodyViewModel:GetTowards()
		)
		--***---------- 刷新渲染层 ----------***--

	end
end
--[[
修正激光尾的transform
--]]
function SpineLaserBulletModel:FixLaserEndTransform()
	local laserEndViewModel = self:GetLaserEndViewModel()

	if nil ~= laserEndViewModel then

		local ownerLocation = self:GetOwnerLocation()
		local targetLocation = self:GetTargetLocation()

		-- 设置激光尾位置
		laserEndViewModel:SetPosition(ownerLocation)
		--***---------- 刷新渲染层 ----------***--
		G_BattleLogicMgr:AddRenderOperate(
			'G_BattleRenderMgr',
			'SetObjectViewPosition',
			laserEndViewModel:GetViewModelTag(), laserEndViewModel:GetPositionX(), laserEndViewModel:GetPositionY()
		)
		--***---------- 刷新渲染层 ----------***--

		local zorder = BATTLE_E_ZORDER.BULLET
		if self:GetObjInfo().needHighlight then
			zorder = zorder + G_BattleLogicMgr:GetFixedHighlightZOrder()
		end

		--***---------- 刷新渲染层 ----------***--
		G_BattleLogicMgr:AddRenderOperate(
			'G_BattleRenderMgr',
			'SetObjectViewZOrder',
			laserEndViewModel:GetViewModelTag(), zorder
		)
		--***---------- 刷新渲染层 ----------***--

		-- 设置激光尾朝向
		if targetLocation.x < ownerLocation.x then
			-- 反方向
			laserEndViewModel:SetTowards(BattleObjTowards.NEGATIVE)
		else
			-- 正方向
			laserEndViewModel:SetTowards(BattleObjTowards.FORWARD)
		end
		--***---------- 刷新渲染层 ----------***--
		G_BattleLogicMgr:AddRenderOperate(
			'G_BattleRenderMgr',
			'SetObjectViewTowards',
			laserEndViewModel:GetViewModelTag(), laserEndViewModel:GetTowards()
		)
		--***---------- 刷新渲染层 ----------***--

	end
end
---------------------------------------------------
-- transform end --
---------------------------------------------------

---------------------------------------------------
-- spine handler begin --
---------------------------------------------------
--[[
注册展示层的事件处理回调
--]]
function SpineLaserBulletModel:RegistViewModelEventHandler()
	------------ 激光束 ------------
	local laserBodyViewModel = self:GetLaserBodyViewModel()
	laserBodyViewModel:RegistEventListener(
		sp.EventType.ANIMATION_COMPLETE,
		handler(self, self.SpineEventCompleteHandler)
	)
	laserBodyViewModel:RegistEventListener(
		sp.EventType.ANIMATION_EVENT,
		handler(self, self.SpineEventCustomHandler)
	)
	------------ 激光束 ------------

	------------ 激光头 ------------
	local laserHeadViewModel = self:GetLaserHeadViewModel()
	if nil ~= laserHeadViewModel then
		laserHeadViewModel:RegistEventListener(
			sp.EventType.ANIMATION_COMPLETE,
			handler(self, self.SpineEventCompleteHandler)
		)
		laserHeadViewModel:RegistEventListener(
			sp.EventType.ANIMATION_EVENT,
			handler(self, self.SpineEventCustomHandler)
		)
	end
	------------ 激光头 ------------
end
--[[
注销展示层的事件处理回调
--]]
function SpineLaserBulletModel:UnregistViewModelEventHandler()

end
--[[
展示层模拟的spine动画事件处理 [sp.EventType.ANIMATION_COMPLETE]
@params eventType 事件类型
@params event 事件数据 {
	animation string 动画名
}
--]]
function SpineLaserBulletModel:SpineEventCompleteHandler(eventType, event)

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
function SpineLaserBulletModel:SpineEventCustomHandler(eventType, event)
	if GState.START ~= G_BattleLogicMgr:GetGState() or OState.DIE == self:GetState() then return end

	if self:GetLaserPartAnimationName(sp.LaserAnimationName.laserBody) == event.animation then

		self:LaserBodySpineEventCustomHandler(event)

	elseif self:GetLaserPartAnimationName(sp.LaserAnimationName.laserHead) == event.animation then

		self:LaserHeadSpineEventCustomHandler(event)

	end
end
--[[
激光束事件回调处理
--]]
function SpineLaserBulletModel:LaserBodySpineEventCustomHandler(event)
	if nil ~= self:GetLaserHeadViewModel() then
		-- 如果存在激光头 则跑激光头的逻辑
		local laserHeadViewModel = self:GetLaserHeadViewModel()
		local laserHeadAnimationName = self:GetLaserPartAnimationName(sp.LaserAnimationName.laserHead)

		--***---------- 刷新渲染层 ----------***--
		G_BattleLogicMgr:AddRenderOperate(
			'G_BattleRenderMgr',
			'AwakeABulletObjectView',
			laserHeadViewModel:GetViewModelTag()
		)
		--***---------- 刷新渲染层 ----------***--

		self:DoAnimation(
			laserHeadViewModel,
			true, nil,
			laserHeadAnimationName, false,
			endAnimationName, false
		)

		--***---------- 刷新渲染层 ----------***--
		G_BattleLogicMgr:AddRenderOperate(
			'G_BattleRenderMgr',
			'ObjectViewDoAnimation',
			laserHeadViewModel:GetViewModelTag(),
			true, nil,
			laserHeadAnimationName, false,
			endAnimationName, false
		)
		--***---------- 刷新渲染层 ----------***--
	else
		-- 如果不存在激光头 则直接造成效果
		local eventName = event.eventData.name

		if sp.CustomEvent.cause_effect == eventName then

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
end
--[[
激光头事件回调处理
--]]
function SpineLaserBulletModel:LaserHeadSpineEventCustomHandler(event)
	local eventName = event.eventData.name

	if sp.CustomEvent.cause_effect == eventName then

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
获取激光束view model
--]]
function SpineLaserBulletModel:GetLaserBodyViewModel()
	return self:GetViewModel()
end
function SpineLaserBulletModel:SetLaserBodyViewModel(viewModel)
	self:SetViewModel(viewModel)
end
--[[
获取激光头view model
--]]
function SpineLaserBulletModel:GetLaserHeadViewModel()
	return self.laserHeadViewModel
end
function SpineLaserBulletModel:SetLaserHeadViewModel(viewModel)
	self.laserHeadViewModel = viewModel
end
--[[
获取激光尾view model
--]]
function SpineLaserBulletModel:GetLaserEndViewModel()
	return self.laserEndViewModel
end
function SpineLaserBulletModel:SetLaserEndViewModel(viewModel)
	self.laserEndViewModel = viewModel
end
--[[
获取目标location
@return _ cc.p
--]]
function SpineLaserBulletModel:GetTargetLocation()
	return self.targetLocation
end
function SpineLaserBulletModel:SetTargetLocation(location)
	self.targetLocation.x = location.x
	self.targetLocation.y = location.y
end
--[[
获取施法者location
--]]
function SpineLaserBulletModel:GetOwnerLocation()
	return self.ownerLocation
end
function SpineLaserBulletModel:SetOwnerLocation(location)
	self.ownerLocation.x = location.x
	self.ownerLocation.y = location.y
end
--[[
获取激光的动作名
@params part sp.LaserAnimationName
@return _ string 动作名
--]]
function SpineLaserBulletModel:GetLaserPartAnimationName(part)
	return self:GetBulletActionAnimationName() .. part
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return SpineLaserBulletModel
