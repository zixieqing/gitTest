--[[
木桩
--]]
local BaseObj = __Require('battle.object.CardObject')
local BaseScarecrowObj = class('BaseScarecrowObj', BaseObj)
--[[
@override
constructor
--]]
function BaseScarecrowObj:ctor( ... )
	BaseObj.ctor(self, ...)
end

return BaseScarecrowObj
