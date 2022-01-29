--[[
战斗总管理器 校验装置 负责校验真伪 回放管理器
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
	BaseBattleManager.InitValue(self)
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
@params resmapjson json 加载的资源表json
@params playerOperatejson json 玩家的操作信息json
--]]
function BattleManager:InitClientBasedData(resmapjson, playerOperatejson)
	self.recordLoadedSpineResources = resmapjson
	self.recordPlayerOperates = playerOperatejson
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- control begin --
---------------------------------------------------
--[[
开始进入游戏
--]]
function BattleManager:EnterBattle()
	-- 渲染层进入战斗
	G_BattleRenderMgr:EnterBattle()
	-- 逻辑层进入战斗
	G_BattleLogicMgr:EnterBattle()

	-- 设置一些录像用的数据
	G_BattleRenderMgr:SetLoadedResources(String2TableNoMeta(self.recordLoadedSpineResources))
	G_BattleLogicMgr:SetRecordPlayerOperate(String2TableNoMeta(self.recordPlayerOperates))

	-- 切场景开始加载
	self:SwitchSceneStartLoading()
end
---------------------------------------------------
-- control end --
---------------------------------------------------

---------------------------------------------------
-- res load begin --
---------------------------------------------------
--[[
加载完毕 开始初始化战斗逻辑
@params data table {
	battleScene  cc.Node 战斗场景实例
}
--]]
function BattleManager:LoadingOverAndInitBattleLogic(data)
	local battleScene = data.battleScene

	-- 设置战斗场景
	self:SetViewComponent(battleScene)

	-- 加载完毕
	self:SetBattleSceneLoadingOver(true)

	-- 设置不可触摸
	self:SetBattleTouchEnable(false)

	-- 通知渲染层加载结束
	G_BattleRenderMgr:LoadResourcesOver()

	-- 通知逻辑层加载结束
	G_BattleLogicMgr:LoadResourcesOver()

	-- 逻辑层初始化完毕 渲染层再初始化一些东西
	G_BattleRenderMgr:LogicInitOver()

	-- 注册主循环
	self:RegistMainUpdate()
end
---------------------------------------------------
-- res load end --
---------------------------------------------------

---------------------------------------------------
-- update begin --
---------------------------------------------------
--[[
调用逻辑帧的逻辑
--]]
function BattleManager:RunLogicUpdate(dt, cb)
	-- 获取运行的tick时间
	local deltaTime = dt

	-- 记录没有运行的逻辑帧时间
	self.logicUpdateInterval = self.logicUpdateInterval + deltaTime

	local render2logicInterval = G_BattleLogicMgr:GetRenderFrameInterval()
	local logicFrameInterval   = G_BattleLogicMgr:GetLogicFrameInterval()

	if (render2logicInterval <= self.logicUpdateInterval) then

		-- 跑逻辑帧
		for i = 1, G_BattleLogicMgr:GetCurrentTimeScale() do
			if G_BattleLogicMgr then
				G_BattleLogicMgr:ReplayMainUpdate(logicFrameInterval)
			end
			if cb then cb() end
		end

		self.logicUpdateInterval = self.logicUpdateInterval - render2logicInterval

	end
end
---------------------------------------------------
-- update end --
---------------------------------------------------

return BattleManager
