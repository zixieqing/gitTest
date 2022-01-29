--[[
战斗总管理器 校验装置 负责校验真伪
@params _ table {
	battleConstructor BattleConstructor 战斗构造器
}
--]]
local BaseBattleManager = __Require('battle.manager.BattleManager')
local BattleManager = class('BattleManager', BaseBattleManager)

------------ import ------------
__Require('battle.defines.BattleImportDefine')
------------ import ------------

------------ define ------------
local NAME = 'BattleMediator'
------------ define ------------

--[[
construtor
--]]
function BattleManager:ctor( ... )
	BaseBattleManager.ctor(self, ...)
end

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
@override
初始化整个的逻辑
--]]
function BattleManager:Init()
	BaseBattleManager.Init(self)
end
--[[
@override
初始化数值
--]]
function BattleManager:InitValue()
	-- 记录的加载的资源数据
	self.recordLoadedSpineResources = nil
	-- 记录的玩家手操内容
	self.recordPlayerOperates = nil
end
--[[
@override
初始化逻辑管理器
@params battleConstructor BattleConstructor 战斗构造器
--]]
function BattleManager:InitLogicManager(battleConstructor)
	local logicManager = __Require('battle.manager.BattleLogicManager').new({
		battleConstructor = battleConstructor
	})

	-- 注册全局变量
	G_BattleLogicMgr = logicManager
end
--[[
@override
初始化渲染管理器
@params battleConstructor BattleConstructor 战斗构造器
--]]
function BattleManager:InitRenderManager(battleConstructor)
	local renderManager = __Require('battle.manager.BattleRenderManager_Server').new({
		battleConstructor = battleConstructor
	})

	-- 注册全局变量
	G_BattleRenderMgr = renderManager
end
--[[
初始化基于客户端决定的信息
@params resmap map 加载的资源表
@params playerOperate map 玩家的操作信息
--]]
function BattleManager:InitClientBasedData(resmap, playerOperate)
	-- 设置资源表
	G_BattleRenderMgr:SetLoadedResources(resmap)
	-- 设置玩家手操信息
	G_BattleLogicMgr:SetRecordPlayerOperate(playerOperate)
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- control begin --
---------------------------------------------------
--[[
@override
开始进入游戏
--]]
function BattleManager:EnterBattle()
	-- 逻辑层进入战斗
	G_BattleLogicMgr:EnterBattle()
end
--[[
开始校验
@return battleResult, fightData PassedBattle 战斗结果, string 战斗过程数据
--]]
function BattleManager:StartCheckRecord()
	-- 通知逻辑层加载结束
	G_BattleLogicMgr:LoadResourcesOver()

	-- 分析一次0帧的玩家操作
	G_BattleLogicMgr:AnalyzeRecordPlayerOperate()

	-- 开始主循环
	local battleResult = nil
	while nil == battleResult do
		battleResult = G_BattleLogicMgr:CheckerMainUpdate(G_BattleLogicMgr:GetLogicFrameInterval())
	end
	print('here checker run over and get battle result !!!', battleResult)

	local fightData = G_BattleLogicMgr:GetRecordFightDataStr()
	return battleResult, fightData
end
--[[
伤害统计
]]
function BattleManager:StartCheckSkada()
	local skadaData = {}
	if G_BattleLogicMgr:GetBattleDriver(BattleDriverType.SKADA_DRIVER) then
		skadaData = G_BattleLogicMgr:GetBattleDriver(BattleDriverType.SKADA_DRIVER):DumpSkadaData()
	end
	return skadaData
end
---------------------------------------------------
-- control end --
---------------------------------------------------

---------------------------------------------------
-- update begin --
---------------------------------------------------
--[[
@override
解析渲染层操作
@params operates list<RenderOperateStruct>
--]]
function BattleManager:AnalyzeRenderOperate(operates)
	-- 校验器不走这个逻辑
end
---------------------------------------------------
-- update end --
---------------------------------------------------

return BattleManager
