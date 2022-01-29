--[[
随机数驱动器 搭载在obj身上的随机驱动器
管理obj的随机规则
@params table {
	ownerTag int 搭载者tag
}
--]]
local RandomDriver = class('RandomDriver')

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
consturctor
--]]
function RandomDriver:ctor( ... )
	local args = unpack({...})

	self.ownerTag = args.ownerTag

	self:InitValue()
end
--[[
初始化数据
--]]
function RandomDriver:InitValue()
	------------ 初始化随机数据结构 ------------
	-- 弱点随机配置 按照弱点序号做假随机
	self.weekEffectRandomConf = {
		['1'] = {noEffect = 0.33, halfEffect = 0.33, breakEffect = 0.33},
		['2'] = {noEffect = 0.17, halfEffect = 0.25, breakEffect = 0.5},
		['3'] = {noEffect = 0.5, halfEffect = 0.33, breakEffect = 0.17}
	}
	self.weekEffectOverlayConf = {
		overlayMin = 0.1,
		overlayMax = 0.25
	}
	self.weekEffectFixedValue = 0
	self.weekEffectCounter = 0
	------------ 初始化随机数据结构 ------------
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- control begin --
---------------------------------------------------
--[[
获取随机弱点结果
@params skillId int 技能id
@params weakPoints array 弱点信息有序配置
@params weakPointIdx int 点击的弱点序号
@return weakId, weakValue ConfigWeakPointId, number 弱点id, 弱点效果值
--]]
function RandomDriver:RandomWeakEffect(skillId, weakPoints, weekPointIdx)
	local randomConf = self.weekEffectRandomConf[tostring(weekPointIdx)]

	local fixedRange = 100
	local r = BMediator:GetRandomManager():GetRandomInt(fixedRange)

	-- 如果上一次是无效果 为打断随机一个叠加几率 无效果几率相对减少
	if self.weekEffectCounter > 0 then
		self.weekEffectFixedValue = self.weekEffectFixedValue +
		BMediator:GetRandomManager():GetRandomInt(self.weekEffectOverlayConf.overlayMin * fixedRange, self.weekEffectOverlayConf.overlayMax * fixedRange)
	end

	-- 计算修正后的概率
	local noEffect = math.max(0, randomConf.noEffect * fixedRange - self.weekEffectFixedValue)
	local halfEffect = randomConf.halfEffect * fixedRange
	local breakEffect = randomConf.breakEffect * fixedRange + self.weekEffectFixedValue

	if nil == weakPoints or 0 >= #weakPoints then
		return ConfigWeakPointId.NONE, 0
	end

	local weakPointIdMap = {}
	for i,v in ipairs(weakPoints) do
		if nil == weakPointIdMap[tostring(v.effectId)] then
			weakPointIdMap[tostring(v.effectId)] = {}
		end
		table.insert(weakPointIdMap[tostring(v.effectId)], i)
	end
	dump(weakPointIdMap)

	if nil ~= weakPointIdMap[tostring(ConfigWeakPointId.NONE)] and
		r <= noEffect then

		-- 无效果 累加修正
		self.weekEffectCounter = self.weekEffectCounter + 1
		return ConfigWeakPointId.NONE, 0

	elseif nil ~= weakPointIdMap[tostring(ConfigWeakPointId.HALF_EFFECT)] and
		r > noEffect and r <= (noEffect + halfEffect) then

		-- 减半 不会修正
		-- 减半需要取一次效果值
		local randomIdx = weakPointIdMap[tostring(ConfigWeakPointId.HALF_EFFECT)][BMediator:GetRandomManager():GetRandomInt(#weakPointIdMap[tostring(ConfigWeakPointId.HALF_EFFECT)])]
		local weakValue = weakPoints[randomIdx].effectValue
		return ConfigWeakPointId.HALF_EFFECT, weakValue

	elseif nil ~= weakPointIdMap[tostring(ConfigWeakPointId.BREAK)] and
		r > (noEffect + halfEffect) and r <= (noEffect + halfEffect + breakEffect) then

		-- 打断 重置修正
		self.weekEffectFixedValue = 0
		self.weekEffectCounter = 0
		return ConfigWeakPointId.BREAK, 0

	else

		-- 二次随机
		local randomFloat = BMediator:GetRandomManager():GetRandomFloat(1)
		local index = math.ceil(randomFloat * #weakPoints)
		return weakPoints[index].effectId, weakPoints[index].effectValue

	end

end
--[[
重置随机种子
--]]
function RandomDriver:ResetRandomSeed()
	local timeStr = tostring(os.time())
	-- math.randomseed(string.reverse(timeStr))
end
---------------------------------------------------
-- control end --
---------------------------------------------------

return RandomDriver
