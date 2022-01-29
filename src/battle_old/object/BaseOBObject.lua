--[[
ob精灵
--]]
local BaseObject = __Require('battle.object.BaseObject')
local BaseOBOject = class('BaseOBOject', BaseObject)
--[[
@override
constructor
--]]
function BaseOBOject:ctor( ... )
	local args = unpack({...})

	------------ 初始化id信息 ------------
	self.idInfo = {
		tag = args.tag,
		oname = args.oname,
		battleElementType = args.battleElementType
	}
	------------ 初始化id信息 ------------

	------------ 初始化卡牌基本信息 ------------
	self.objInfo = args.objInfo
	------------ 初始化卡牌基本信息 ------------

	------------ 初始化ui信息 ------------
	self.view = {
		viewComponent = nil,
		avatar = nil,
		animationsData = nil,
		hpBar = nil,
		energyBar = nil,
	}
	------------ 初始化ui信息 ------------

	self:init()
	self:registerObjEventHandler()
end
---------------------------------------------------
-- init logic begin --
---------------------------------------------------
--[[
@override
初始化逻辑
--]]
function BaseOBOject:init()
	self:initValue()
	self:initDrivers()
end
--[[
@override
初始化行为驱动器
--]]
function BaseOBOject:initDrivers()
	
end
--[[
@override
注册战斗物体之间通信的回调函数
--]]
function BaseOBOject:registerObjEventHandler()
	if nil == self.objCastEventHandler_ then
		self.objCastEventHandler_ = handler(self, self.objCastEventHandler)
	end
	BMediator:AddObjEvent(ObjectEvent.OBJECT_CAST_ENTER, self, self.objCastEventHandler_)

	if nil == self.objChantEventHandler_ then
		self.objChantEventHandler_ = handler(self, self.objChantEventHandler)
	end
	BMediator:AddObjEvent(ObjectEvent.OBJECT_CHANT_ENTER, self, self.objChantEventHandler_)
end
--[[
设置引导模块
@params guideModuleId int 引导模块id
--]]
function BaseOBOject:setGuideModule(guideModuleId)
	-- 引导精灵只拥有一个引导驱动
	self.guideDriver = __Require('battle.objectDriver.BaseGuideDriver').new({
		owner = self,
		guideModuleId = guideModuleId
	})
end
---------------------------------------------------
-- init logic end --
---------------------------------------------------

---------------------------------------------------
-- update logic begin --
---------------------------------------------------
--[[
main update
--]]
function BaseOBOject:update(dt)
	-- 如果游戏结束直接跳过逻辑
	local gameState = BMediator:GetGState()
	if GState.TRANSITION == gameState or
		GState.OVER == gameState or 
		GState.SUCCESS == gameState or
		GState.FAIL == gameState  then

		return

	end

	-- 只在游戏进行时更新事件触发器
	if GState.START == BMediator:GetGState() then
		self.guideDriver:UpdateActionTrigger(ConfigBattleGuideStepTriggerType.TIME_AXIS, dt)
	end

	if self.guideDriver:GetIsInGuide() then
		self.guideDriver:OnActionUpdate(dt)
	else
		-- 判断是否能进行下一步引导
		local nextGuideStepId = self.guideDriver:CanDoAction()
		if nil ~= nextGuideStepId then
			-- 可以执行下一步引导
			self.guideDriver:OnActionEnter(nextGuideStepId)
		end	
	end
	
end
---------------------------------------------------
-- update logic end --
---------------------------------------------------

---------------------------------------------------
-- control begin --
---------------------------------------------------
--[[
销毁 不可逆！
--]]
function BaseOBOject:destroy()
	BaseObject.destroy(self)

	-- 移除触摸监听
	if nil ~= self.guideDriver then
		self.guideDriver:UnregistTouchListener()
	end
end
---------------------------------------------------
-- control end --
---------------------------------------------------

---------------------------------------------------
-- handler begin --
---------------------------------------------------
--[[
@override
物体施法回调
@params ...
	args table passed args
--]]
function BaseOBOject:objCastEventHandler( ... )
	local args = unpack({...})
	self.guideDriver:UpdateActionTrigger(ConfigBattleGuideStepTriggerType.CAST_SKILL, args.skillId)
end
--[[
物体读条回调
@params ...
	args table passed args
--]]
function BaseOBOject:objChantEventHandler( ... )
	local args = unpack({...})
	self.guideDriver:UpdateActionTrigger(ConfigBattleGuideStepTriggerType.CHANT, args.skillId)
end
---------------------------------------------------
-- handler end --
---------------------------------------------------

return BaseOBOject
