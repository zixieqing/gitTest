--[[
描述一个卡牌物体的通用展示层模型
@params viewModelInfo ObjectViewModelConstructorStruct 卡牌展示层构造数据
--]]
local BaseViewModel = __Require('battle.viewModel.BaseViewModel')
local SpineViewModel = class('SpineViewModel', BaseViewModel)

------------ import ------------
------------ import ------------

------------ define ------------
------------ define ------------

--[[
constructor
--]]
function SpineViewModel:ctor( ... )
	BaseViewModel.ctor(self, ...)

	local args = unpack({...})

	self.viewInfo = args
end

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
@override
初始化特有属性
--]]
function SpineViewModel:InitUnitValue()
	-- 当前正在运行的spine动画信息 [RunSpineAnimationStruct]
	self.runningSpineAniInfo = nil

	-- 正在运行的spine动画计时器 [number]
	self.runningSpineAniLeftTime = nil

	-- 接下去即将要运行的spine动画信息 [list<RunSpineAnimationStruct>]
	self.nextSpineAniInfos = {}

	-- 动画速度的缩放参数
	self.spineTimeScale = 1
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- logic begin --
---------------------------------------------------

---------------------------------------------------
-- logic end --
---------------------------------------------------

---------------------------------------------------
-- spine animation control begin --
---------------------------------------------------
--[[
设置一个spine动画
@params spineAniName string spine动作名称
@params loop bool 是否循环该动画
--]]
function SpineViewModel:SetSpineAnimation(spineAniName, loop)
	if not self:HasSpineAnimationByName(spineAniName) then return end

	-- 停掉当前正在运行的spine动画
	self:StopRunningSpineAnimation()
	local spineAniInfo = RunSpineAnimationStruct.New(spineAniName, loop)
	self:SetRunningSpineAniInfo(spineAniInfo)

	-- 开始跑动画
	self:OnSpineAniEnter(self:GetRunningSpineAniInfo())
end
--[[
在当前spine动画之后添加一个spine动画
@params spineAniName string spine动作名称
@params loop bool 是否循环该动画
--]]
function SpineViewModel:AddSpineAnimation(spineAniName, loop)
	if not self:HasSpineAnimationByName(spineAniName) then return end

	local spineAniInfo = RunSpineAnimationStruct.New(spineAniName, loop)
	self:PushANextSpineAniInfo(spineAniInfo)
end
--[[
停止当前正在运行的spine动画
--]]
function SpineViewModel:StopRunningSpineAnimation()
	self:OnSpineAniBreak()
	self:SetRunningSpineAniInfo(nil)
	self:SetRunningSpineAniLeftTime(nil)
	self:ClearNextSpineAniInfos()
end
--[[
重置spine动画动作
--]]
function SpineViewModel:SetSpineToSetupPose()

end
--[[
清空所有正要进行的spine动画
--]]
function SpineViewModel:ClearSpineTracks()
	self:StopRunningSpineAnimation()
end
--[[
开始做一个spine动画
@params spineAniInfo RunSpineAnimationStruct spine动画信息
--]]
function SpineViewModel:OnSpineAniEnter(spineAniInfo)
	local spineAniName = spineAniInfo.animationName
	local spineAniData = self:GetSpineAnimationDataByName(spineAniName)

	------------ 发送一次动画开始的事件 ------------
	local event = {
		animation = spineAniName,
	}
	self:SendEvent(sp.EventType.ANIMATION_START, event)
	------------ 发送一次动画开始的事件 ------------

	-- 初始化一次当前动画的时间
	self:SetRunningSpineAniLeftTime(spineAniData.animationDuration)
end
--[[
@override
逻辑更新
--]]
function SpineViewModel:Update(dt)
	BaseViewModel:Update(dt)

	if self:IsDie() then return end

	self:OnSpineAniUpdate(dt)
end
--[[
当前spine动画进行中
@params dt number delta time
--]]
function SpineViewModel:OnSpineAniUpdate(dt)
	-- 修正一次delta time
	local dt_ = dt * self:GetSpineTimeScale()

	if nil ~= self:GetRunningSpineAniInfo() then		

		-- 刷一次逻辑
		self:RunningSpineAniUpdateOnce(dt_)
		-- 刷一次时间
		self:AddRunningSpineAniLeftTime(-1 * dt_)

		------------ 判断是否要自然结束当前动作 ------------
		if 0 >= self:GetRunningSpineAniLeftTime() then

			-- 结束当前动作
			self:OnSpineAniExit()

			-- /***********************************************************************************************************************************\
			--  * 为了规避隐藏的递归风险 这里不用剩余的时间再去刷一次下一帧
			-- \***********************************************************************************************************************************/			

		end
		------------ 判断是否要自然结束当前动作 ------------
	else

		-- 当前为空 判断下一个动画
		local nextSpineAniInfo = self:PopANextASpineAniInfo()
		if nil ~= nextSpineAniInfo then

			self:SetRunningSpineAniInfo(nextSpineAniInfo)
			-- 开始跑动画
			self:OnSpineAniEnter(self:GetRunningSpineAniInfo())

		end

	end
end
--[[
走一次逻辑
@params dt number delta time
@params spineAniName string spine动画名称
--]]
function SpineViewModel:RunningSpineAniUpdateOnce(dt)
	local runningSpineAniName = self:GetRunningSpineAniName()
	local curLeftTime = self:GetRunningSpineAniLeftTime()
	local curRunnedTime = self:GetSpineAniDurationByName(runningSpineAniName) - curLeftTime
	local nextRunnedTime = curRunnedTime + dt

	------------ 检测自定义spine事件 ------------
	local events = self:GetSpineAnimationEventsByName(runningSpineAniName)
	if nil ~= events then
		for eventName, eventInfos in pairs(events) do

			for _, eventInfo in ipairs(eventInfos) do

				-- /***********************************************************************************************************************************\
				--  * <del>两边闭区间 此处从逻辑上不存在一个事件会在不同的两帧里发送两次的情况</del>
				--  * 上面的一句话是错的 真就存在发送两次的情况
				-- \***********************************************************************************************************************************/
				if curRunnedTime <= eventInfo.time and nextRunnedTime > eventInfo.time then

					-- 发送自定义事件
					local event = {
						animation = runningSpineAniName,
						eventData = {
							name = eventName,
							intValue = eventInfo.intValue,
							floatValue = eventInfo.floatValue,
							stringValue = eventInfo.stringValue
						}
					}
					self:SendEvent(sp.EventType.ANIMATION_EVENT, event)

				end

			end

		end
	end
	------------ 检测自定义spine事件 ------------
end
--[[
当前spine动画结束
--]]
function SpineViewModel:OnSpineAniExit()
	-- 判断下一个动画
	local runningSpineAniInfo = self:GetRunningSpineAniInfo()
	if nil ~= runningSpineAniInfo then

		------------ 发送一次动画结束的事件 ------------
		local event = {
			animation = runningSpineAniInfo.animationName,
		}
		self:SendEvent(sp.EventType.ANIMATION_COMPLETE, event)
		------------ 发送一次动画结束的事件 ------------

		if true == runningSpineAniInfo.loop then

			-- 当前动画需要循环 再开始一次动画
			self:OnSpineAniEnter(runningSpineAniInfo)

			return
		end

	end

	-- 当前动画不需要循环 检测下一个动画
	local nextSpineAniInfo = self:PopANextASpineAniInfo()
	if nil ~= nextSpineAniInfo then

		self:SetRunningSpineAniInfo(nextSpineAniInfo)
		-- 开始跑动画
		self:OnSpineAniEnter(self:GetRunningSpineAniInfo())

		return

	end

	-- 不存在下一个动画 清空当前动画信息
	self:SetRunningSpineAniInfo(nil)
	self:SetRunningSpineAniLeftTime(nil)
end
--[[
当前spine动画被打断
--]]
function SpineViewModel:OnSpineAniBreak()
	if nil ~= self:GetRunningSpineAniInfo() then
		------------ 发送一次动画被打断的事件 ------------
		local event = {
			animation = self:GetRunningSpineAniInfo().animationName,
		}
		self:SendEvent(sp.EventType.ANIMATION_END, event)
		------------ 发送一次动画被打断的事件 ------------
	end
end
---------------------------------------------------
-- spine animation control end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
获取展示层信息
@return _ ObjectViewModelConstructorStruct
--]]
function SpineViewModel:GetViewInfo()
	return self.viewInfo
end
--[[
@override
获取当前展示层对应的逻辑层tag
@return _ int 逻辑层tag
--]]
function SpineViewModel:GetLogicOwnerTag()
	return self:GetViewInfo().tag
end
--[[
@override
获取当前展示层对应的逻辑层模型
@return _ BaseObject
--]]
function SpineViewModel:GetLogicOwner()
	return BMediator:GetObjByTagForce(self:GetLogicOwnerTag())
end
--[[
获取spine信息
@return _ ObjectSpineDataStruct
--]]
function SpineViewModel:GetSpineData()
	return self.viewInfo.spineData
end
--[[
获取spine id
--]]
function SpineViewModel:GetSpineId()
	return self:GetSpineData().spineId
end
--[[
获取avatar缩放比 cocos2dx
@return _ number
--]]
function SpineViewModel:GetAvatarScale()
	return self:GetViewInfo().avatarScale
end
--[[
获取spine内置的缩放比 创建时传入的缩放比参数
@return _ number
--]]
function SpineViewModel:GetSpineAvatarScale()
	return self:GetSpineData().spineCreateScale
end
--[[
获取卡牌修正后的碰撞框信息
@params borderBox string 边界框名字
@return box cc.rect 边界框信息
--]]
function SpineViewModel:GetSpineStaticCollisionBox()
	if nil == self:GetSpineData().staticCollisionBox then return nil end

	return self:CalcFixedBorderBox(self:GetSpineData().staticCollisionBox)
end
--[[
获取卡牌修正后的ui框信息
@params borderBox string 边界框名字
@return box cc.rect 边界框信息
--]]
function SpineViewModel:GetSpineStaticCollisionBox()
	if nil == self:GetSpineData().staticViewBox then return nil end

	return self:CalcFixedBorderBox(self:GetSpineData().staticViewBox)
end
--[[
根据初始的边界框信息计算由外部信息修正后的边界框信息
@params borderBox cc.rect 初始的边界框信息
@return box cc.rect 边界框信息
--]]
function SpineViewModel:CalcFixedBorderBox(borderBox)
	local box = cc.rect(
		borderBox.x,
		borderBox.y,
		borderBox.width,
		borderBox.height
	)

	-- 相比源文件缩放的总和
	local scale_ = self:GetSpineAvatarScale() * self:GetAvatarScale()

	-- 根据外部信息修正边界框的大小
	box.x = box.x * scale_
	box.y = box.y * scale_
	box.width = box.width * scale_
	box.height = box.height * scale_

	-- 修正边界框的朝向
	if BattleObjTowards.BACKWARD == self:GetTowards() then
		box.x = -1 * (box.x + box.width)
	end

	return box
end
--[[
设置当前正在运行的spine动画名称
@params runningSpineAniInfo RunSpineAnimationStruct 正在运行的动画名称
--]]
function SpineViewModel:SetRunningSpineAniInfo(runningSpineAniInfo)
	self.runningSpineAniInfo = runningSpineAniInfo
end
--[[
获取当前正在运行的spine动画名称
@return _ RunSpineAnimationStruct 正在运行的动画名称
--]]
function SpineViewModel:GetRunningSpineAniInfo()
	return self.runningSpineAniInfo
end
--[[
获取当前正在运行的spine动画名称
@return runningSpineAniName string 正在运行的spine动画名称
--]]
function SpineViewModel:GetRunningSpineAniName()
	local runningSpineAniName = nil
	if nil ~= self:GetRunningSpineAniInfo() then
		runningSpineAniName = self:GetRunningSpineAniInfo().animationName
	end
	return runningSpineAniName
end
--[[
压栈一个下一个运行的spine动画
@params spineAniInfo RunSpineAnimationStruct spine动画信息
--]]
function SpineViewModel:PushANextSpineAniInfo(spineAniInfo)
	table.insert(self.nextSpineAniInfos, 1, spineAniInfo)
end
--[[
出栈一个下一个运行的spine动画
@return _ RunSpineAnimationStruct spine动画信息
--]]
function SpineViewModel:PopANextASpineAniInfo()
	if BattleUtils.IsTableEmpty(self.nextSpineAniInfos) then
		return nil
	else
		local nextSpineAniInfo = self.nextSpineAniInfos[#self.nextSpineAniInfos]
		table.remove(self.nextSpineAniInfos, #self.nextSpineAniInfos)
		return nextSpineAniInfo
	end
end
--[[
清空所有的下一个动画堆栈
--]]
function SpineViewModel:ClearNextSpineAniInfos()
	self.nextSpineAniInfos = {}
end
--[[
根据spine动作名获取spine动作信息
@params spineAnimationName string spine动作名
@return _ ObjectSpineAnimationDataStruct
--]]
function SpineViewModel:GetSpineAnimationDataByName(spineAnimationName)
	return self:GetSpineData().animationsData[tostring(spineAnimationName)]
end
--[[
根据spine动画名称判断是否存在该动画
@params spineAnimationName string spine动作名
--]]
function SpineViewModel:HasSpineAnimationByName(spineAnimationName)
	return nil ~= self:GetSpineAnimationDataByName(spineAnimationName)
end
--[[
获取当前动画剩余时间
@return _ number
--]]
function SpineViewModel:GetRunningSpineAniLeftTime()
	return self.runningSpineAniLeftTime
end
--[[
设置当前动画剩余时间
@params time number
--]]
function SpineViewModel:SetRunningSpineAniLeftTime(time)
	self.runningSpineAniLeftTime = time
end
--[[
为当前动画剩余时间添加一个增量
@params dt number delta time
--]]
function SpineViewModel:AddRunningSpineAniLeftTime(dt)
	self:SetRunningSpineAniLeftTime(self:GetRunningSpineAniLeftTime() + dt)
end
--[[
根据spine动作名获取该动作的事件信息
@params spineAnimationName string spine动作名
@return _ map 事件信息
--]]
function SpineViewModel:GetSpineAnimationEventsByName(spineAnimationName)
	if nil ~= self:GetSpineAnimationDataByName(spineAnimationName) then
		return self:GetSpineAnimationDataByName(spineAnimationName).animationEvents
	else
		return nil
	end
end
--[[
根据spine动作名获取该动作的持续时间
@params spineAnimationName string spine动作名
@return _ map 事件信息
--]]
function SpineViewModel:GetSpineAniDurationByName(spineAnimationName)
	if nil ~= self:GetSpineAnimationDataByName(spineAnimationName) then
		return self:GetSpineAnimationDataByName(spineAnimationName).animationDuration
	else
		return 0
	end
end
--[[
获取动画的速度缩放
@return _ number 速度缩放
--]]
function SpineViewModel:GetSpineTimeScale()
	return self.spineTimeScale
end
--[[
设置动画的速度缩放
@params timeScale number
--]]
function SpineViewModel:SetSpineTimeScale(timeScale)
	self.spineTimeScale = timeScale
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return SpineViewModel
