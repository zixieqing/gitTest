--[[
让你妈个老逼搞事 打扰老子玩鬼泣5
--]]
RBQNumber = {}

------------ import ------------
------------ import ------------

------------ define ------------
local VAL_KEY = 'rbq_val_'
local ACCR = 0.0000000001
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
	------------ hash ------------
	-- 让value成为rbq的哈希key
	self.rbq_val_hash = nil
	------------ hash ------------

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
-- hash control begin --
---------------------------------------------------
--[[
更换一次hash值
--]]
function RBQNumber:ShuffleHash()
	local timeStamp = string.reverse(math.abs(tonumber(os.clock())))
	local timeStampNumber = tonumber(timeStamp)
	local timeStampInt = checkint(timeStamp)
	local fixMark = checkint((timeStampNumber - timeStampInt) * 0xf7)
	local fixNumber = fixMark % tonumber(string.sub(tostring(timeStampInt), 1, 1))
	local fixedHash = timeStampInt + fixNumber * 0x7f

	self.rbq_val_hash = fixedHash
end
--[[
获取哈希key
--]]
function RBQNumber:GetHash()
	return self.rbq_val_hash
end
---------------------------------------------------
-- hash control end --
---------------------------------------------------

---------------------------------------------------
-- value control begin --
---------------------------------------------------
--[[
设置值
@params val number 值
--]]
function RBQNumber:SetRBQV(val)
	if nil ~= self:GetOriVal() and true == self:IsRBQ() then
		if app and app.uiMgr then
			app.uiMgr:ShowInformationTips(':D')
		end
	end
	local preKey = self:GetRBQVKey()
	self[preKey] = nil
	self:ShuffleHash()
	local valKey = self:GetRBQVKey()
	local rbqv = self:CalcRBQV(self:GetHash(), val)
	self[valKey] = rbqv
	self:SetOriVal(val)
end
--[[
根据哈希值和val计算rbqv
--]]
function RBQNumber:CalcRBQV(vhash, v)
	return v * vhash + vhash % 0x7f + 1
end
--[[
获取val
--]]
function RBQNumber:GetRBQV()
	local rbqv = self[self:GetRBQVKey()]
	return rbqv
end
--[[
获取val修正后的key
--]]
function RBQNumber:GetRBQVKey()
	return VAL_KEY .. string.sub(tostring(self:GetHash()), 1, 1)
end
--[[
检查数据
--]]
function RBQNumber:IsRBQ()
	local value = self:CalcRBQV(self:GetHash(), self:GetOriVal())
	if value ~= self:GetRBQV() then
		return true
	end
	return false
end
--[[
计算源数据
--]]
function RBQNumber:CalcVal()
	local hash = self:GetHash()
	local val = (self:GetRBQV() - hash % 0x7f - 1) / hash
	return val
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
	local __val__ = self:CalcVal()
	self:SetRBQV(__val__)
end
--[[
获取值
--]]
function RBQNumber:ObtainVal()
	self:ShuffleRBQV()
	return self:CalcVal()
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
		a:ShuffleRBQV()
		a_ = a:CalcVal()
	else
		a_ = a
	end
	local b_ = nil
	if nil == tonumber(b) then
		b:ShuffleRBQV()
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
		a:ShuffleRBQV()
		a_ = a:CalcVal()
	else
		a_ = a
	end
	local b_ = nil
	if nil == tonumber(b) then
		b:ShuffleRBQV()
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
		a:ShuffleRBQV()
		a_ = a:CalcVal()
	else
		a_ = a
	end
	local b_ = nil
	if nil == tonumber(b) then
		b:ShuffleRBQV()
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
		a:ShuffleRBQV()
		a_ = a:CalcVal()
	else
		a_ = a
	end
	local b_ = nil
	if nil == tonumber(b) then
		b:ShuffleRBQV()
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
		a:ShuffleRBQV()
		a_ = a:CalcVal()
	else
		a_ = a
	end
	local b_ = nil
	if nil == tonumber(b) then
		b:ShuffleRBQV()
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
		a:ShuffleRBQV()
		a_ = a:CalcVal()
	else
		a_ = a
	end
	local b_ = nil
	if nil == tonumber(b) then
		b:ShuffleRBQV()
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
		a:ShuffleRBQV()
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
		a:ShuffleRBQV()
		a_ = a:CalcVal()
	else
		a_ = a
	end
	local b_ = nil
	if nil == tonumber(b) then
		b:ShuffleRBQV()
		b_ = b:CalcVal()
	else
		b_ = b
	end
	return math.abs(a_ - b_) <= ACCR
end


--[[
[ < ]
--]]
function RBQNumber.__lt(a, b)
	local a_ = nil
	if nil == tonumber(a) then
		a:ShuffleRBQV()
		a_ = a:CalcVal()
	else
		a_ = a
	end
	local b_ = nil
	if nil == tonumber(b) then
		b:ShuffleRBQV()
		b_ = b:CalcVal()
	else
		b_ = b
	end
	return a_ - b_ < ACCR
end


--[[
[ <= ]
--]]
function RBQNumber.__le(a, b)
	local a_ = nil
	if nil == tonumber(a) then
		a:ShuffleRBQV()
		a_ = a:CalcVal()
	else
		a_ = a
	end
	local b_ = nil
	if nil == tonumber(b) then
		b:ShuffleRBQV()
		b_ = b:CalcVal()
	else
		b_ = b
	end
	return a_ - b_ <= ACCR
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
