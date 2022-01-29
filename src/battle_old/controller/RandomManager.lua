--[[
随机数工具
--]]
RandomManager = class('RandomManager')

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
初始化随机数管理器
--]]
function RandomManager:Init()
	------------ random config ------------
	self.randomValuesAmount = 0
	self.curRandomValueIdx = 0
	self.randomAccuracy = 0

	self.randomAccuracyMin = 0
	self.randomAccuracyMax = 0
	------------ random config ------------

	------------ random data ------------
	self.randomseed = 0
	self.randomValues = {}
	------------ random data ------------
end
--[[
设置随机数结构
@params randomConfig BattleRandomConfigStruct 战斗随机数配置
--]]
function RandomManager:RefreshRandomConfig(randomConfig)
	local randomvalues = randomConfig.randomvalues
	if randomConfig:HasRandomvalues() then

		-- 存在随机数序列配置
		self.randomValues = randomConfig.randomvalues
		self.randomValuesAmount = randomConfig.randomvalueamount
		self.randomAccuracyMin = randomConfig.randomvaluemin
		self.randomAccuracyMax = randomConfig.randomvaluemax

	elseif randomConfig:HasRandomseed() then

		-- 存在随机种子 根据随机种子刷新随机数配置
		self:SetRandomseedAndRefreshRandomValues(randomConfig.randomseed)

	else

		-- 什么都没有 生成一个随机种子
		local randomseed = string.reverse(tostring(os.time()))
		self:SetRandomseedAndRefreshRandomValues(randomseed)		

	end

	self.curRandomValueIdx = 1

	self.randomAccuracy = self.randomAccuracyMax - self.randomAccuracyMin + 1

	print('check random value table ??????>>>>>>>>>>>>>>>>>>>', self.randomseed, self.randomAccuracy)
	dump(self.randomValues)
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- logic begin --
---------------------------------------------------
--[[
设置随机种子并刷新随机数列表
@params randomseed string 随机种子
--]]
function RandomManager:SetRandomseedAndRefreshRandomValues(randomseed)

	self.randomseed = randomseed
	self.randomValuesAmount = 100
	self.randomAccuracyMin = 1
	self.randomAccuracyMax = 1000

	math.randomseed(self.randomseed)
	self.randomValues = {}
	for i = 1, self.randomValuesAmount do
		table.insert(self.randomValues, math.random(self.randomAccuracyMin, self.randomAccuracyMax))
	end

	self.curRandomValueIdx = 1
end
--[[
获取模拟的随机数
--]]
function RandomManager:GetRandomValue()
	local v = self.randomValues[self.curRandomValueIdx]
	self.curRandomValueIdx = (self.curRandomValueIdx % self.randomValuesAmount) + 1
	return v
end
--[[
获取随机整数 [1, iupper]
@params iupper int 整数上限
--]]
function RandomManager:GetRandomInt(iupper)
	local r = math.ceil(self:GetRandomValue() / self.randomAccuracy * iupper)
	print('random int --->', r)
	return r
end
--[[
获取随级整数[ilower, iupper]
@params ilower int 整数下限
@params iupper int 整数上限
--]]
function RandomManager:GetRandomIntByRange(ilower, iupper)
	local r = ilower - 1 + math.ceil(self:GetRandomValue() / self.randomAccuracy * iupper)
	print('random int range --->', r)
	return r
end
--[[
获取随机浮点数[0, fupper]
@params fupper number 上限
--]]
function RandomManager:GetRandomFloat(fupper)
	local r = math.ceil(self:GetRandomValue() / self.randomAccuracy * fupper * 100) * 0.01
	print('random float --->', r)
	return r
end
--[[
获取随机浮点数[flower, fupper]
@params flower number 下限
@params fupper number 上限
--]]
function RandomManager:GetRandomFloatByRange(flower, fupper)
	local r = flower - 1 + math.ceil(self:GetRandomValue() / self.randomAccuracy * fupper * 100) * 0.01
	print('random float range --->', r)
	return r
end
---------------------------------------------------
-- logic end --
---------------------------------------------------

return RandomManager
