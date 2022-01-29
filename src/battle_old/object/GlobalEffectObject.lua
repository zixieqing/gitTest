--[[
全局buff管理抽象对象
--]]
local BaseObject = __Require('battle.object.BaseObject')
local GlobalEffectObject = class('GlobalEffectObject', BaseObject)
--[[
@override
constructor
--]]
function GlobalEffectObject:ctor( ... )
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
function GlobalEffectObject:init()
	self:initValue()
	self:initDrivers()
end
--[[
@override
初始化行为驱动器
--]]
function GlobalEffectObject:initDrivers()
	self.castDriver = __Require('battle.objectDriver.GlobalEffectCastDriver').new({
		owner = self
	})
end
--[[
@override
注册战斗物体之间通信的回调函数
--]]
function GlobalEffectObject:registerObjEventHandler()
	if nil == self.objCreatedEventHandler_ then
		self.objCreatedEventHandler_ = handler(self, self.objCreatedEventHandler)
	end
	BMediator:AddObjEvent(ObjectEvent.OBJECT_CREATED, self, self.objCreatedEventHandler_)
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
function GlobalEffectObject:update(dt)
	
end
--[[
施放所有光环
--]]
function GlobalEffectObject:castAllHalos()
	self.castDriver:CastAllHalos()
end
--[[
全局物体搭载情景buff逻辑
@params buffInfo table buff信息
@return _ bool 是否成功加上了该buff
--]]
function GlobalEffectObject:beCasted(buffInfo)
	if ConfigBuffType.LIVE_CHEAT_FREE == buffInfo.btype then
		-- 免费买活buff
		local buff = self:getBuffByBuffId(buffInfo.bid)
		if nil == buff then
			buff = __Require(buffInfo.className).new(buffInfo)
			self:addBuff(buff)
		else
			buff:OnRefreshBuffEnter(buffInfo)
		end
		return true
	end
	
	return false
end
---------------------------------------------------
-- update logic end --
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
function GlobalEffectObject:objCreatedEventHandler( ... )
	local args = unpack({...})
	self.castDriver:OnActionEnter(args.tag)
end
---------------------------------------------------
-- handler end --
---------------------------------------------------

return GlobalEffectObject
