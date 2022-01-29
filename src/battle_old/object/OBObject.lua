--[[
2号ob物体
--]]
local BaseOBOject = __Require('battle.object.BaseObject')
local OBObject = class('OBObject', BaseOBOject)

------------ import ------------
------------ import ------------

------------ define ------------
local CCCountdownMin = 5
local CCCountdownMax = 10
------------ define ------------

--[[
@override
constructor
--]]
function OBObject:ctor( ... )
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

end
---------------------------------------------------
-- init logic begin --
---------------------------------------------------
--[[
@override
初始化逻辑
--]]
function OBObject:init()
	self:initValue()
	self:initCC()
end
--[[
初始化倒计时
--]]
function OBObject:initCC()
	self.cccountdown = 0
	self:resetCCCountdown()
end
---------------------------------------------------
-- init logic end --
---------------------------------------------------

---------------------------------------------------
-- control begin --
---------------------------------------------------
--[[
记录一次所有物体的属性
--]]
function OBObject:recordAllFriendObjPStr()
	if nil ~= BMediator and nil ~= BMediator:GetBData() then
		local pstr = BMediator:GetBData():convertAllFriendObjPStr()

		print('ccp----------->>>>>>>', pstr)

		BMediator:GetBData():AddObjPStr(pstr)
	end
end
---------------------------------------------------
-- control end --
---------------------------------------------------

---------------------------------------------------
-- update logic begin --
---------------------------------------------------
--[[
main update
--]]
function OBObject:update(dt)
	-- 主逻辑
	local countdown = math.max(0, self:getCCCountdown() - dt)
	if 0 >= countdown then
		-- record and reset
		self:recordAllFriendObjPStr()
		self:resetCCCountdown()
	else
		self:setCCCountdown(countdown)
	end
end
---------------------------------------------------
-- update logic end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
倒计时
--]]
function OBObject:getCCCountdown()
	return self.cccountdown
end
function OBObject:setCCCountdown(countdown)
	self.cccountdown = countdown
end
--[[
重置倒计时
--]]
function OBObject:resetCCCountdown()
	self:setCCCountdown(math.random(CCCountdownMin, CCCountdownMax))
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return OBObject
