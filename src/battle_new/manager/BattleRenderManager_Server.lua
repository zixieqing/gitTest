--[[
战斗渲染管理器
@params _ table {
	battleConstructor BattleConstructor 战斗构造器
}
--]]
local BaseBattleRenderManager = __Require('battle.manager.BattleRenderManager')
local BattleRenderManager = class('BattleRenderManager', BaseBattleRenderManager)

------------ import ------------
------------ import ------------

------------ define ------------
local PAUSE_SCENE_TAG = 1001
local WAVE_TRANSITION_SCENE_TAG = 1201

local GAME_RESULT_LAYER_TAG = 2321
------------ define ------------

--[[
construtor
--]]
function BattleRenderManager:ctor( ... )
	BaseBattleRenderManager.ctor(self, ...)
end

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
@override
初始化整个的逻辑
--]]
function BattleRenderManager:Init()
	BaseBattleRenderManager.Init(self)

	-- 初始化驱动
	self:InitBattleDrivers()
end
--[[
@override
初始化数据
--]]
function BattleRenderManager:InitValue()
	BaseBattleRenderManager.InitValue(self)

	-- 加载的spine资源
	self.recordLoadedSpineResources = nil
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- spine begin --
---------------------------------------------------
--[[
@override
获取内存中是否存在对应的spine资源
@params spineId int spine动画id
@params spineType SpineType spine动画的类型
@params wave int 波数
@return _ bool 该资源是否在内存中
--]]
function BattleRenderManager:SpineInCache(spineId, spineType, wave)
	local loadedRes = self:GetLoadedResources()
	if nil == loadedRes then return false end

	local spineCacheName = BattleUtils.GetCacheAniNameById(spineId, spineType)
	-- /***********************************************************************************************************************************\
	--  * 此处wave+1是因为默认调用此方法时处于波数+1之前
	-- 	* 如果在波数+1之后出现调用(BaseCastDriver:AddASkill(skillId, level) -> 战中增加一个临时的技能)会导致逻辑错误
	-- \***********************************************************************************************************************************/
	local wave_ = wave + 1
	-- /***********************************************************************************************************************************\
	--  * 此处wave+1是因为默认调用此方法时处于波数+1之前
	-- 	* 如果在波数+1之后出现调用(BaseCastDriver:AddASkill(skillId, level) -> 战中增加一个临时的技能)会导致逻辑错误
	-- \***********************************************************************************************************************************/
	if nil ~= loadedRes[wave_] then
		return loadedRes[wave_][tostring(spineCacheName)] and loadedRes[wave_][tostring(spineCacheName)] or false
	else
		return loadedRes[1][tostring(spineCacheName)] and loadedRes[1][tostring(spineCacheName)] or false
	end
end
---------------------------------------------------
-- spine end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
获取加载的spine资源
@return _ map 加载的spine资源
--]]
function BattleRenderManager:GetLoadedResources()
	return self.recordLoadedSpineResources
end
function BattleRenderManager:SetLoadedResources(resmap)
	self.recordLoadedSpineResources = resmap
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return BattleRenderManager
