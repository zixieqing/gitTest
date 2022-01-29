--[[
服务端的rbq number 去掉混淆
--]]
RBQNumber = {}

------------ import ------------
------------ import ------------

------------ define ------------
local VAL_KEY = 'rbq_val_'
------------ define ------------

--[[
constructor
--]]
function RBQNumber.New(val)
	local rbqNum = {}

	setmetatable(rbqNum, {__index = RBQNumber})

	-- 重载运算符
	rbqNum:OverloadMetaFunction()
	
	-- 初始化rbq num
	rbqNum:Init(val)

	return rbqNum
end

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化rbq number
--]]
function RBQNumber:Init(val)
	------------ value ------------
	self.ori_val = nil
	local __val__ = nil
	if nil ~= tonumber(val) then
		__val__ = val
	else
		__val__ = val:CalcVal()
	end
	self:SetRBQV(__val__)
	------------ value ------------
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- value control begin --
---------------------------------------------------
--[[
设置值
@params val number 值
--]]
function RBQNumber:SetRBQV(val)
	self:SetOriVal(val)
end
--[[
根据哈希值和val计算rbqv
--]]
function RBQNumber:CalcRBQV(vhash, v)
	return self:GetOriVal()
end
--[[
获取val
--]]
function RBQNumber:GetRBQV()
	return self:GetOriVal()
end
--[[
计算源数据
--]]
function RBQNumber:CalcVal()
	return self:GetOriVal()
end
--[[
获取源数据
--]]
function RBQNumber:GetOriVal()
	return self.ori_val
end
function RBQNumber:SetOriVal(val)
	self.ori_val = val
end
--[[
刷新一次rbqv
--]]
function RBQNumber:ShuffleRBQV()

end
--[[
获取值
--]]
function RBQNumber:ObtainVal()
	return self:GetOriVal()
end
---------------------------------------------------
-- value control end --
---------------------------------------------------

---------------------------------------------------
-- operator begin --
---------------------------------------------------
--[[
重载运算符
--]]
function RBQNumber:OverloadMetaFunction()
	local metaFunctions = {
		'__add',
		'__sub',
		'__mul',
		'__div',
		'__mod',
		'__pow',
		'__unm',
		'__eq',
		'__lt',
		'__le'
	}

	local metatable_ = getmetatable(self)
	for _, f in ipairs(metaFunctions) do
		metatable_[f] = RBQNumber[f]
	end
end


--[[
[ + ]
--]]
function RBQNumber.__add(a, b)
	local a_ = nil
	if nil == tonumber(a) then
		a_ = a:CalcVal()
	else
		a_ = a
	end
	if nil == tonumber(b) then
		b_ = b:CalcVal()
	else
		b_ = b
	end
	return a_ + b_
end


--[[
[ - ]
--]]
function RBQNumber.__sub(a, b)
	local a_ = nil
	if nil == tonumber(a) then
		a_ = a:CalcVal()
	else
		a_ = a
	end
	if nil == tonumber(b) then
		b_ = b:CalcVal()
	else
		b_ = b
	end
	return a_ - b_
end


--[[
[ * ]
--]]
function RBQNumber.__mul(a, b)
	local a_ = nil
	if nil == tonumber(a) then
		a_ = a:CalcVal()
	else
		a_ = a
	end
	if nil == tonumber(b) then
		b_ = b:CalcVal()
	else
		b_ = b
	end
	return a_ * b_
end


--[[
[ / ]
--]]
function RBQNumber.__div(a, b)
	local a_ = nil
	if nil == tonumber(a) then
		a_ = a:CalcVal()
	else
		a_ = a
	end
	if nil == tonumber(b) then
		b_ = b:CalcVal()
	else
		b_ = b
	end
	return a_ / b_
end


--[[
[ % ]
--]]
function RBQNumber.__mod(a, b)
	local a_ = nil
	if nil == tonumber(a) then
		a_ = a:CalcVal()
	else
		a_ = a
	end
	if nil == tonumber(b) then
		b_ = b:CalcVal()
	else
		b_ = b
	end
	return a_ % b_
end


--[[
[ ^ ]
--]]
function RBQNumber.__pow(a, b)
	local a_ = nil
	if nil == tonumber(a) then
		a_ = a:CalcVal()
	else
		a_ = a
	end
	if nil == tonumber(b) then
		b_ = b:CalcVal()
	else
		b_ = b
	end
	return a_ ^ b_
end


--[[
[ -1 * ... ]
--]]
function RBQNumber.__unm(a)
	local a_ = nil
	if nil == tonumber(a) then
		a_ = a:CalcVal()
	else
		a_ = a
	end
	return -1 * a_
end


--[[
[ = ]
--]]
function RBQNumber.__eq(a, b)
	local a_ = nil
	if nil == tonumber(a) then
		a_ = a:CalcVal()
	else
		a_ = a
	end
	if nil == tonumber(b) then
		b_ = b:CalcVal()
	else
		b_ = b
	end
	return a_ == b_
end


--[[
[ < ]
--]]
function RBQNumber.__lt(a, b)
	local a_ = nil
	if nil == tonumber(a) then
		a_ = a:CalcVal()
	else
		a_ = a
	end
	if nil == tonumber(b) then
		b_ = b:CalcVal()
	else
		b_ = b
	end
	return a_ < b_
end


--[[
[ <= ]
--]]
function RBQNumber.__le(a, b)
	local a_ = nil
	if nil == tonumber(a) then
		a_ = a:CalcVal()
	else
		a_ = a
	end
	if nil == tonumber(b) then
		b_ = b:CalcVal()
	else
		b_ = b
	end
	return a_ <= b_
end


--[[
[ == ]
--]]
function RBQNumber:EQ(val)
	self:ShuffleRBQV()
	return self:CalcVal() == val
end
--[[
[ < ]
--]]
function RBQNumber:LT(val)
	self:ShuffleRBQV()
	return self:CalcVal() < val
end
--[[
[ > ]
--]]
function RBQNumber:GRT(val)
	return not self:LessThan(val)
end
--[[
[ <= ]
--]]
function RBQNumber:LET(val)
	self:ShuffleRBQV()
	return self:CalcVal() <= val
end
--[[
[ >= ]
--]]
function RBQNumber:GRET(val)
	self:ShuffleRBQV()
	return self:CalcVal() >= val
end
---------------------------------------------------
-- operator end --
---------------------------------------------------

return RBQNumber
