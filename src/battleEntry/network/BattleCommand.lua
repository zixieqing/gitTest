local SimpleCommand = mvc.SimpleCommand

local BattleCommand = class('BattleCommand', SimpleCommand)
local httpManager = AppFacade.GetInstance():GetManager("HttpManager")

-- 战斗短连接配置
-- 此处写这么麻烦绕一圈为了和代码方便
local CMDInfo = {
	-- 地图战斗
	{cmd = POST.QUEST_AT},
	{cmd = POST.QUEST_GRADE},
	{cmd = POST.QUEST_PURCHASE_CHALLENGE_TIME},
	{cmd = POST.QUEST_SWEEP},
	-- 霸王餐
	{cmd = POST.RESTAURANT_QUEST_AT},
	{cmd = POST.RESTAURANT_QUEST_GRADE},
	-- 帮打霸王餐
	{cmd = POST.RESTAURANT_HELP_QUEST_AT},
	{cmd = POST.RESTAURANT_HELP_QUEST_GRADE},
	-- 主线剧情任务战斗
	{cmd = POST.PLOT_TASK_QUEST_AT},
	{cmd = POST.PLOT_TASK_QUEST_GRADE},
	-- 支线剧情任务战斗
	{cmd = POST.BRANCH_QUEST_AT},
	{cmd = POST.BRANCH_QUEST_GRADE},
	-- 外卖打劫
	{cmd = POST.TAKEAWAY_ROBBERY_QUEST_AT},
	{cmd = POST.TAKEAWAY_ROBBERY_QUEST_GRADE},
	{cmd = POST.TAKEAWAY_ROBBERY_RIDICULE},
	-- 探索
	{cmd = POST.EXPLORATION_QUEST_AT},
	{cmd = POST.EXPLORATION_QUEST_GRADE},
	-- 爬塔
	{cmd = POST.TOWER_QUEST_AT},
	{cmd = POST.TOWER_QUEST_GRADE},
	{cmd = POST.TOWER_QUEST_BUY_LIVE},
	-- 竞技场
	{cmd = POST.PVC_QUEST_AT},
	{cmd = POST.PVC_QUEST_GRADE},
	-- 材料副本
	{cmd = POST.MATERIAL_QUEST_AT},
	{cmd = POST.MATERIAL_QUEST_GRADE},
	-- 季活
	{cmd = POST.SEASON_ACTIVITY_QUEST_AT},
	{cmd = POST.SEASON_ACTIVITY_QUEST_GRADE},
	{cmd = POST.SPRING_ACTIVITY_QUEST_AT},
	{cmd = POST.SPRING_ACTIVITY_QUEST_GRADE},
	{cmd = POST.SUMMER_ACTIVITY_QUESTAT},
	{cmd = POST.SUMMER_ACTIVITY_QUESTGRADE},
	-- 周年庆
	{cmd = POST.ANNIVERSARY_QUEST_AT},
	{cmd = POST.ANNIVERSARY_QUEST_GRADE},
	-- 神器
	{cmd = POST.ARTIFACT_QUESTAT},
	{cmd = POST.ARTIFACT_QUESTGRADE},
	-- 工会狩猎神兽
	{cmd = POST.UNION_HUNTING_QUEST_AT},
	{cmd = POST.UNION_HUNTING_QUEST_GRADE},
	{cmd = POST.UNION_HUNTING_BUY_LIVE, hasParameter = false},
	-- 工会派对打堕神
	{cmd = POST.UNION_PARTY_BOSS_QUEST_AT},
	{cmd = POST.UNION_PARTY_BOSS_QUEST_GRADE},
	-- 世界boss战
	{cmd = POST.WORLD_BOSS_QUESTAT},
	{cmd = POST.WORLD_BOSS_QUESTGRADE},
	{cmd = POST.WORLD_BOSS_BUYLIVE},
	-- 活动副本
	{cmd = POST.ACTIVITY_QUEST_QUESTAT},
	{cmd = POST.ACTIVITY_QUEST_QUESTGRADE},
	-- 天城演武
	{cmd = POST.TAG_MATCH_QUEST_AT},
	{cmd = POST.TAG_MATCH_QUEST_GRADE},
	-- 新天成演武
	{cmd = POST.NEW_TAG_MATCH_QUEST_AT},
	{cmd = POST.NEW_TAG_MATCH_QUEST_GRADE},
	-- 燃战
	{cmd = POST.SAIMOE_QUEST_AT},
	{cmd = POST.SAIMOE_QUEST_GRADE},
	{cmd = POST.SAIMOE_BOSS_QUEST_AT},
	{cmd = POST.SAIMOE_BOSS_QUEST_GRADE},
	-- 神器之路
	{cmd = POST.ACTIVITY_ARTIFACT_ROAD_QUEST_AT},
	{cmd = POST.ACTIVITY_ARTIFACT_ROAD_QUEST_GRADE},
	-- pt本
	{cmd = POST.PT_QUEST_AT},
	{cmd = POST.PT_QUEST_GRADE},
	{cmd = POST.PT_BUY_LIVE},
	-- 工会战
	{cmd = POST.UNION_WARS_ENEMY_QUEST_AT},
	{cmd = POST.UNION_WARS_ENEMY_QUEST_GRADE},
	{cmd = POST.UNION_WARS_BOSS_QUEST_AT},
	{cmd = POST.UNION_WARS_BOSS_QUEST_GRADE},
	-- 杀人案（19夏活）
	{cmd = POST.MURDER_QUEST_AT},
	{cmd = POST.MURDER_QUEST_GRADE},
	-- 木人桩
	{cmd = POST.PLAYER_DUMMY_QUEST_AT},
	{cmd = POST.PLAYER_DUMMY},
	-- 巅峰对决
	{cmd = POST.ACTIVITY_ULTIMATE_BATTLE_QUEST_AT},
	{cmd = POST.ACTIVITY_ULTIMATE_BATTLE_QUEST_GRADE},
	-- 皮肤嘉年华
	{cmd = POST.SKIN_CARNIVAL_CHALLENGE_QUEST_AT},
	{cmd = POST.SKIN_CARNIVAL_CHALLENGE_QUEST_GRADE},
	-- 童话世界/2019周年庆
	{cmd = POST.ANNIVERSARY2_BOSS_QUEST_AT},
	{cmd = POST.ANNIVERSARY2_BOSS_QUEST_GRADE},
	-- 周年庆探索小怪
	{cmd = POST.ANNIVERSARY2_EXPLORE_SECTION_MONSTER_QUEST_AT},
	{cmd = POST.ANNIVERSARY2_EXPLORE_SECTION_MONSTER_QUEST_GRADE},

	-- 2020周年庆探索小怪
	{cmd = POST.ANNIV2020_EXPLORE_QUEST_AT},
	{cmd = POST.ANNIV2020_EXPLORE_QUEST_GRADE},


	-- luna塔
	{cmd = POST.LUNA_TOWER_QUEST_AT},
	{cmd = POST.LUNA_TOWER_QUEST_GRADE},
	-- 好友切磋
	{cmd = POST.FRIEND_BATTLE_QUEST_AT},
	{cmd = POST.FRIEND_BATTLE_QUEST_GRADE},
	-- 20春活
	{cmd = POST.SPRING_ACTIVITY_20_QUEST_AT},
	{cmd = POST.SPRING_ACTIVITY_20_QUEST_GUADE},
	-- 武道会-评选赛
	{cmd = POST.CHAMPIONSHIP_QUEST_AT},
	{cmd = POST.CHAMPIONSHIP_QUEST_GRADE},
	-- 联动本（pop子）
	{cmd = POST.POP_TEAM_QUEST_AT},
	{cmd = POST.POP_TEAM_QUEST_GRADE},
	-- 联动本（pop子 boss）
	{cmd = POST.POP_FARM_BOSS_QUEST_AT},
	{cmd = POST.POP_FARM_BOSS_QUEST_GRADE},
}

local CMDConfig = {}
for _, cmdInfo in ipairs(CMDInfo) do
	if nil ~= cmdInfo.cmd then
		CMDConfig[cmdInfo.cmd.cmdName] = {cmd = cmdInfo.cmd, hasParameter = cmdInfo.hasParameter}
	end
end

function BattleCommand:ctor( )
	SimpleCommand.ctor(self)
	self.executed = false
end


function BattleCommand:Execute( signal )
	self.executed = true
	-- 发送网络请求
	local name = signal:GetName()
	local data = signal:GetBody()

	local cmdInfo = CMDConfig[name]

	if nil ~= cmdInfo then

		local data_ = data
		if false == cmdInfo.hasParameter then
			data_ = nil
		end

		httpManager:Post(cmdInfo.cmd.postUrl, cmdInfo.cmd.sglName, data_)

	end
end


return BattleCommand
