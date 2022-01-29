--[[
堕神模型
--]]
local BaseObject = __Require('battle.object.BaseObject')
local PetObject = class('PetObject', BaseObject)

--[[
@override
constructor
--]]
function PetObject:ctor( ... )
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
		energyBar = nil
	}
	------------ 初始化ui信息 ------------

	self:init()

end

return PetObject
