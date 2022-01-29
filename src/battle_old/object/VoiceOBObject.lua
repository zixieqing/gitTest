--[[
语音ob物体
--]]
local BaseOBObject = __Require('battle.object.BaseOBObject')
local VoiceOBObject = class('VoiceOBObject', BaseOBObject)
--[[
@override
constructor
--]]
function VoiceOBObject:ctor( ... )
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
设置语音驱动器
@params voiceModuleId int 语音模块id
--]]
function VoiceOBObject:setVoiceModule(voiceModuleId)
	self.voiceDriver = __Require('battle.objectDriver.BaseVoiceDriver').new({
		owner = self,
		voiceModuleId = voiceModuleId
	})
end
---------------------------------------------------
-- init logic end --
---------------------------------------------------

---------------------------------------------------
-- update logic begin --
---------------------------------------------------
--[[
@override
main update
--]]
function VoiceOBObject:update(dt)
	self.voiceDriver:UpdateActionTrigger(ActionTriggerType.CD, dt)
end
---------------------------------------------------
-- update logic end --
---------------------------------------------------


return VoiceOBObject
