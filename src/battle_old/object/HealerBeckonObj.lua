--[[
治疗单位召唤 无法攻击 只会刷血
--]]
local BaseBeckonObj = __Require('battle.object.BaseBeckonObj')
local HealerBeckonObj = class('HealerBeckonObj', BaseBeckonObj)

return HealerBeckonObj