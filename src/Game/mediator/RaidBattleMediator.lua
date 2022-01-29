--[[
战斗控制器
@params battleConstructor BattleConstructor 战斗构造器
}
--]]
local Mediator = mvc.Mediator
local BattleMediator = require('Game.mediator.BattleMediator')
local RaidBattleMediator = class('RaidBattleMediator', BattleMediator)
local NAME = "RaidBattleMediator"

--[[
@override
constructor
--]]
function RaidBattleMediator:ctor( params, viewComponent )
	Mediator.ctor(self, NAME, viewComponent)

	self.battleConstructor = params
end

---------------------------------------------------
-- mediator extend begin --
---------------------------------------------------
function RaidBattleMediator:InterestSignals()
	local signals = {
		-- 战斗场景创建完毕
		'BATTLE_SCENE_CREATE_OVER',
		-- 战斗场景完成设置开局的等待队友倒计时
		'RAID_BATTLE_SET_START_COUNTDOWN',
		-- 战斗结束
		'BATTLE_GAME_OVER',
		-- 队友选择奖励
		'RAID_MEMBER_CHOOSE_REWARDS',
		-- 退出战斗界面
		'BATTLE_BACK_TO_PREVIOUS',
		-- 强制退出战斗
		'FORCE_EXIT_BATTLE',
		-- 强制杀掉战斗
		'BATTLE_FORCE_BREAK',
		-- 强制跳转 退出战斗
		'EVENT_RAID_BATTLE_EXIT_TO_TEAM_FORCE',
		-- 全员准备开始战斗
		EVENT_RAID_ALL_MEMBER_READY_START_FIGHT,
		-- 发送组队战斗结束的请求回调
		EVENT_RAID_BATTLE_OVER_AND_WAIT_TEAMMATE,
		-- 战斗结束获取到战斗结果的回调
		EVENT_RAID_BATTLE_RESULT,
		-- 队友获得了奖励
		EVENT_RAID_MEMBER_GET_REWARDS,
		-- 房间解散
		EVENT_RAID_TEAM_DISSOLVE,
		-- 所有成员都完成了战斗
		EVENT_RAID_BATTLE_ALL_MEMBER_OVER
	}
	return signals
end

function RaidBattleMediator:Initial( key )
	self.super.Initial(self, key)
	-- 是否可以直接开始战斗 -> 当队友全部加载完毕时置为true
	self.canDirectStartBattle = false
	-- 是否需要等待队友结束 -> 当队友全部全部结束战斗时置为false
	self.needWaitTeammateForResult = true

	BattleMediator.Initial(self, key)
end
function RaidBattleMediator:OnRegist()
    BattleMediator.OnRegist(self)
end
function RaidBattleMediator:OnUnRegist()
	BattleMediator.OnUnRegist(self)
end
---------------------------------------------------
-- mediator extend end --
---------------------------------------------------

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
@override
初始化战斗管理器
--]]
function RaidBattleMediator:InitBattleManager()
	if nil == self.battleManager then
		self.battleManager = __Require('battle.manager.RaidBattleManager').new({battleConstructor = self.battleConstructor})
	end
end
--[[
@override
初始化网络管理器
--]]
function RaidBattleMediator:InitBattleNetworkMediator()

end
--[[
@override
获取网络管理器
--]]
function RaidBattleMediator:GetNetworkMdt()
	
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- logic control begin --
---------------------------------------------------
--[[
@override
处理信号
--]]
function RaidBattleMediator:ProcessSignal(signal)
	local name = signal:GetName()
	local data = signal:GetBody()

	if 'BATTLE_SCENE_CREATE_OVER' == name then

		self:BattleSceneCreateOverAndStart(data)

	elseif 'RAID_BATTLE_SET_START_COUNTDOWN' == name then

		self:SetStartCountdown(data)

	elseif 'BATTLE_GAME_OVER' == name then

		self:GameOver(data)

	elseif 'RAID_MEMBER_CHOOSE_REWARDS' == name then

		self:MemberChooseRewardsCallback(data)

	elseif 'BATTLE_BACK_TO_PREVIOUS' == name then

		self:BackToPrevious(data.questBattleType, data.isPassed, data.battleConstructor)

	elseif 'FORCE_EXIT_BATTLE' == name then

		-- 强制退出战斗 !!! 强制 !!! 不讲道理的那种
		self:ForceExitBattle()

	elseif 'BATTLE_FORCE_BREAK' == name then

		-- 强制杀掉战斗 不带跳转 只是杀掉逻辑
		self:KillBattle()

	elseif 'EVENT_RAID_BATTLE_EXIT_TO_TEAM_FORCE' == name then

		-- 强制退出战斗跳转 !!! 强制 !!! 不讲道理的那种
		self:BackToPreviousForce()

	elseif EVENT_RAID_ALL_MEMBER_READY_START_FIGHT == name then

		self:AllMemberLoadingOver()

	elseif EVENT_RAID_BATTLE_OVER_AND_WAIT_TEAMMATE == name then

		-- 组队战斗结束等待队友的信号
		self:RaidBattleOverAndWaitTeammate(data)

	elseif EVENT_RAID_BATTLE_RESULT == name then

		-- 战斗结果的信号
		self:HandleBattleResult(data)

	elseif EVENT_RAID_MEMBER_GET_REWARDS == name then

		-- 战斗结果的信号
		self:MemberGetRewardsCallback(data)

	elseif EVENT_RAID_TEAM_DISSOLVE == name then

		-- 房间解散的信号
		self:TeamDissolveCallback()

	elseif EVENT_RAID_BATTLE_ALL_MEMBER_OVER == name then

		-- 组队战斗全员结束开始请求结算
		self:RaidBattleAllOver()

	end
end
--[[
场景创建完毕 开始战斗
@params data table {
	battleScene  cc.Node 战斗场景实例
}
--]]
function RaidBattleMediator:BattleSceneCreateOverAndStart(data)
	local battleScene = data.battleScene

	------------ 初始化战斗逻辑 ------------
	self.battleManager:LoadingOverAndInitBattleLogic(data)
	------------ 初始化战斗逻辑 ------------

	------------ 处理开始游戏的逻辑 ------------
	if self:CanDirectStartBattle() then
		-- 加载超时 直接开始游戏
		self.battleManager:RemoveReadyStateAndStart()
	else
		-- 正常逻辑 开始等待
		self.battleManager:ShowWaitingOtherMember()	
	end
	------------ 处理开始游戏的逻辑 ------------

	------------ 向外部发送加载完成的消息 ------------
	-- 发送一条通知 加载完毕 一切就绪
	AppFacade.GetInstance():DispatchObservers(EVENT_RAID_BATTLE_SCENE_LOADING_OVER, {battleScene = self})
	------------ 向外部发送加载完成的消息 ------------

end
--[[
全员准备完毕 开始战斗
--]]
function RaidBattleMediator:AllMemberLoadingOver()
	if self.battleManager:CanRemoveCountdownAndStartGame() then

		-- 加载完毕后收到开始游戏的长连接 则开始游戏
		self.battleManager:RemoveReadyStateAndStart()

	else

		-- 未加载完毕时收到开始游戏的长连接 保留此长连接
		self:SetCanDirectStartBattle(true)
		
	end
end
--[[
战斗结束 -> 胜利
@params data {
	requestData = nil 请求的信息
}
--]]
function RaidBattleMediator:GameOver(data)
	AppFacade.GetInstance():DispatchObservers(EVENT_RAID_BATTLE_OVER, data.requestData)
end
--[[
处理战斗结果
@params responseData table 服务器返回信息
--]]
function RaidBattleMediator:HandleBattleResult(responseData)
	self.battleManager:HandleBattleResult(responseData)
end
--[[
退出战斗 返回上一个界面
@params questBattleType QuestBattleType 战斗类型
@params isPassed PassedBattle 是否通过了战斗
@params battleConstructor BattleConstructor 战斗构造器
--]]
function RaidBattleMediator:BackToPrevious(questBattleType, isPassed, battleConstructor)
	-- 发送一次战斗结果数据
	self:BroadcastBattleResult(battleConstructor:GetStageId(), questBattleType, isPassed)
end
--[[
强制退出战斗 返回一个可能订制的界面
@params questBattleType QuestBattleType 战斗类型
@params isPassed PassedBattle 是否通过了战斗
@params battleConstructor BattleConstructor 战斗构造器
--]]
function RaidBattleMediator:BackToPreviousForce(questBattleType, isPassed, battleConstructor)
	AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch(
		{name = NAME},
		{name = "RaidHallMediator"}
	)
end
--[[
其他玩家获得奖励回调
@params responseData table 服务器返回信息
--]]
function RaidBattleMediator:MemberGetRewardsCallback(responseData)
	self.battleManager:AddMemberRewards(responseData)
end
--[[
房间解散信号回调
--]]
function RaidBattleMediator:TeamDissolveCallback()
	self:SetCanDirectStartBattle(true)
end
--[[
设置战斗开始倒计时
@params data table 
--]]
function RaidBattleMediator:SetStartCountdown(data)
	if not self:CanDirectStartBattle() then
		local countdown = checkint(data.countdown)
		self.battleManager:BeginStartRaidBattleCountdown(countdown)
	end
end
--[[
设置战斗结束倒计时
@params data table 
--]]
function RaidBattleMediator:SetOverCountdown(data)
	if self:NeedWaitTeammateForResult() then
		local countdown = checkint(data.countdown)
		self.battleManager:BeginOverRaidBattleCountdown(countdown)
	end
end
--[[
组队战斗结束等待队友
@params data table {
	waitTime int 等待队友的倒计时
}
--]]
function RaidBattleMediator:RaidBattleOverAndWaitTeammate(data)
	if self:NeedWaitTeammateForResult() then
		-- 显示等待界面
		self.battleManager:ShowWaitingOtherMemberOver()
		-- 开始倒计时
		self:SetOverCountdown(data)
	end
end
--[[
组队战斗结束开始请求战斗结果
--]]
function RaidBattleMediator:RaidBattleAllOver()
	-- 如果战斗还未结束 直接无视这个4038
	if PassedBattle.NO_RESULT ~= self.battleManager:IsRaidBattleOver() then
		self:SetNeedWaitTeammateForResult(false)
		self.battleManager:RaidBattleAllOver()
	end
end
--[[
队友选择奖励回调
@params responseData table 服务器返回信息
--]]
function RaidBattleMediator:MemberChooseRewardsCallback(responseData)
	self.battleManager:AddMemberChooseRewards(responseData)
end
---------------------------------------------------
-- logic control end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
获取是否可以直接开始游戏
--]]
function RaidBattleMediator:CanDirectStartBattle()
	return self.canDirectStartBattle
end
function RaidBattleMediator:SetCanDirectStartBattle(can)
	self.canDirectStartBattle = can
end
--[[
是否需要等待队友的战斗结果
--]]
function RaidBattleMediator:NeedWaitTeammateForResult()
	return self.needWaitTeammateForResult
end
function RaidBattleMediator:SetNeedWaitTeammateForResult(need)
	self.needWaitTeammateForResult = need
end
---------------------------------------------------
-- get set end --
---------------------------------------------------


return RaidBattleMediator
