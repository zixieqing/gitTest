--[[
回响 连续施法buff
@params args ObjectBuffConstructorStruct
--]]
local BaseBuff = __Require('battle.buff.BaseBuff')
local MarkingBuff = class('MarkingBuff', BaseBuff)

------------ import ------------
------------ import ------------

------------ define ------------
------------ define ------------

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
@override
初始化
--]]
function MarkingBuff:Init()
	BaseBuff.Init(self)
	self:AddView()
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- logic begin --
---------------------------------------------------
--[[
@override
造成效果
@return result number 造成效果以后的结果
--]]
function InstantBuff:CauseEffect()

end
---------------------------------------------------
-- logic end --
---------------------------------------------------

return MarkingBuff
