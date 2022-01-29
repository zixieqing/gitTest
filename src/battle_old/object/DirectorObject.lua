--[[
导演物体
--]]
local BaseObject = __Require('battle.object.BaseObject')
local DirectorObject = class('DirectorObject', BaseObject)

--[[
@override
constructor
--]]
function DirectorObject:ctor( ... )
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
function DirectorObject:init()
	self:initValue()
	self:initDrivers()
end
--[[
@override
初始化行为驱动器
--]]
function DirectorObject:initDrivers()
	self.cameraDriver = __Require('battle.objectDriver.CameraControlDriver').new({
		owner = self
	})
end
--[[
@override
注册战斗物体之间通信的回调函数
--]]
function DirectorObject:registerObjEventHandler()
	if nil == self.objCastEventHandler_ then
		self.objCastEventHandler_ = handler(self, self.ObjCastEventHandler)
	end
	BMediator:AddObjEvent(ObjectEvent.OBJECT_CAST_ENTER, self, self.objCastEventHandler_)

	if nil == self.objPhaseChangeEventHandler_ then
		self.objPhaseChangeEventHandler_ = handler(self, self.ObjPhaseChangeEventHandler)
	end
	BMediator:AddObjEvent(ObjectEvent.OBJECT_PHASE_CHANGE, self, self.objPhaseChangeEventHandler_)
end
---------------------------------------------------
-- init logic end --
---------------------------------------------------

---------------------------------------------------
-- handler begin --
---------------------------------------------------
--[[
main update
--]]
function DirectorObject:update(dt)
	self.cameraDriver:OnActionUpdate(dt)
end
--[[
游戏开始
--]]
function DirectorObject:OnGameStart()
	self:HandleBgDefaultScale()
end
--[[
对背景图进行缩放
--]]
function DirectorObject:HandleBgDefaultScale()
	local bgInfo = BMediator:GetBData():getBattleBgInfo(1)
	local defaultBgScale = bgInfo.defaultBgScale

	-- 前景和背景
	local nodes = {
		BMediator:GetViewComponent().viewData.fgLayer,
		BMediator:GetViewComponent().viewData.bgLayer,
		BMediator:GetViewComponent().viewData.mainMapLayer
	}
	
	for i,v in ipairs(nodes) do
		v:setScale(v:getScale() * defaultBgScale)
	end
end
--[[
物体施法回调
@params ...
	args table passed args
--]]
--]]
function DirectorObject:ObjCastEventHandler( ... )
	local args = unpack({...})

	local obj = BMediator:IsObjAliveByTag(args.tag)
	if nil ~= obj then
		local cardId = obj.getOCardId and obj:getOCardId() or nil
		local isEnemy = args.isEnemy
		local skillId = args.skillId

		local params = {
			cardId = cardId,
			isEnemy = isEnemy,
			skillId = skillId
		}

		self.cameraDriver:CanDoAction(ConfigCameraTriggerType.OBJ_SKILL, params)
	end
end
--[[
转阶段的回调
@params ...
	args table passed args
--]]
function DirectorObject:ObjPhaseChangeEventHandler( ... )
	local args = unpack({...})
	
	local params = {
		tag = args.triggerPhaseNpcTag,
		phaseId = args.phaseId
	}

	self.cameraDriver:CanDoAction(ConfigCameraTriggerType.PHASE_CHANGE, params)
end
---------------------------------------------------
-- handler end --
---------------------------------------------------

return DirectorObject
