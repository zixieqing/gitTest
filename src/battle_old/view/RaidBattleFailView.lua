--[[
新组队本战斗失败结算界面
@params table {
	viewType ConfigBattleResultType 结算界面类型
	cleanCondition table 需要展示的三星特殊条件
	showMessage bool 是否显示给对手的留言
	canRepeatChallenge bool 是否可以重打
	teamData table 阵容信息
	trophyData table 战斗奖励信息
}
--]]
local BattleFailView = __Require('battle.view.BattleFailView')
local RaidBattleFailView = class('RaidBattleFailView', BattleFailView)

------------ import ------------
local gameMgr = AppFacade.GetInstance('AppFacade'):GetManager("GameManager")
local cardMgr = AppFacade.GetInstance('AppFacade'):GetManager("CardManager")
------------ import ------------

------------ define ------------
------------ define ------------

--[[
constructor
--]]
function RaidBattleFailView:ctor( ... )
	BattleFailView.ctor(self, ...)
end

---------------------------------------------------
-- data control begin --
---------------------------------------------------
--[[
更新本地数据
--]]
function RaidBattleFailView:UpdateLocalData()
	-- 给一个空方法 组队本失败不会更新任何数据
end
---------------------------------------------------
-- data control end --
---------------------------------------------------

return RaidBattleFailView
