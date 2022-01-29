--[[
全局buff基类
@params buffInfo GlobalBuffConstructStruct 构造全局buff需要的数据结构
--]]
local BaseGlobalBuff = class('BaseGlobalBuff')
--[[
constructor
--]]
function BaseGlobalBuff:ctor( ... )
	local args = unpack({...})

	self.buffInfo = nil

	self:InitValue(args)
end
---------------------------------------------------
-- init logic beign --
---------------------------------------------------
--[[
初始化数据
--]]
function BaseGlobalBuff:InitValue(args)
	self:SetBuffInfo(args)

	self.value = checknumber(self:GetBuffInfo().value[1])
end
---------------------------------------------------
-- init logic end --
---------------------------------------------------

---------------------------------------------------
-- control logic begin --
---------------------------------------------------
--[[
产生效果
--]]
function BaseGlobalBuff:CauseEffect()

end
--[[
恢复效果
--]]
function BaseGlobalBuff:RecoverEffect()

end
---------------------------------------------------
-- control logic end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------


------------ buff信息 ------------
function BaseGlobalBuff:GetBuffInfo()
	return self.buffInfo
end
function BaseGlobalBuff:SetBuffInfo(buffInfo)
	self.buffInfo = buffInfo
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return BaseGlobalBuff
