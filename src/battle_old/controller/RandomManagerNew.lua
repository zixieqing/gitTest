--[[
伪随机算法 线性同余法
x = (ax' + b) % m
--]]
local RandomManager = class('RandomManager')

------------ import ------------
------------ import ------------

------------ define ------------
local default_a = 4 * 79 + 1
local default_b = 2 * 23 + 1
local default_m = 2 ^ 20
------------ define ------------

--[[
constructor
--]]
function RandomManager:ctor( ... )
	self:Init()
end

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化随机数
--]]
function RandomManager:Init()
	-- 随机种子
	self.randomseed = nil
	-- 伪随机乘数
	self.random_a = default_a
	-- 伪随机增量
	self.random_b = default_b
	-- 伪随机模数
	self.random_m = default_m
	-- 伪随机上一次的基数
	self.random_x = nil
	-- 伪随机第一次传入的x0
	self.x_ = nil
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- control begin --
---------------------------------------------------
--[[
设置一次随机种子
@params randomseed string 随机种子
--]]
function RandomManager:SetRandomseed(randomseed)
	-- 设置随机种子
	self.randomseed = randomseed
	-- 刷新x_
	self.x_ = checkint(randomseed) % default_m
	-- 刷新当前随机数的基数
	self.random_x = self.x_
end
--[[
获取一次随机数
@return _ number
--]]
function RandomManager:GetRandomValue_()
	local x = (self.random_a * self.random_x + self.random_b) % self.random_m
	self.random_x = x
	return x
end
--[[
获取一次随机数
[0, 1]
--]]
function RandomManager:GetRandomValue()
	local x = self:GetRandomValue_() + 1
	return x / self.random_m
end
--[[
获取一次随机整数
[0, upper]
--]]
function RandomManager:GetRandomInt(upper)
	return math.round(self:GetRandomValue() * upper)
end
---------------------------------------------------
-- control end --
---------------------------------------------------

return RandomManager
