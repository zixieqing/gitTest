--[[
组队本大厅
@params table {
	teamQuestType RaidQuestType 组队本类型
}
--]]
local Mediator = mvc.Mediator
---@class RaidHallMediator
local RaidHallMediator = class('RaidHallMediator', Mediator)

local NAME = 'RaidHallMediator'

------------ import ------------
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
------------ import ------------

------------ define ------------
RaidQuestDifficulty = {
	EASY 			= 1,
	NORMAL 			= 2,
	HARD 			= 3
}

RaidDifficultyDescrConfig = {
	[RaidQuestDifficulty.EASY] 		= __('简单'),
	[RaidQuestDifficulty.NORMAL] 	= __('普通'),
	[RaidQuestDifficulty.HARD] 		= __('困难')
}

local JoinTeamErrcode = {
	VALID 			= 0, -- 有效 可以加入
	INVAILD 		= 1, -- 无效
	NO_TEAM 		= 2, -- 房间不存在
	PLAYER_MAX 		= 3, -- 房间满员
	IN_BATTLE 		= 4  -- 正在战斗
}
local JoinTeamErrMsg = {
	[JoinTeamErrcode.VALID] 			= '',
	[JoinTeamErrcode.INVAILD] 			= __('队伍无效'),
	[JoinTeamErrcode.NO_TEAM] 			= __('队伍不存在'),
	[JoinTeamErrcode.PLAYER_MAX] 		= __('队伍满员'),
	[JoinTeamErrcode.IN_BATTLE] 		= __('队伍正在战斗中')
}
local RaidEnterTeamViewTag = 3801

------------ define ------------

--[[
constructor
--]]
function RaidHallMediator:ctor(params, viewComponent)
	Mediator.ctor(self, NAME,viewComponent)
	dump(params)
	self.raidData = params
	-- self.teamQuestType = checkint(params.teamQuestType)
	self.teamQuestType = RaidQuestType.TWO_PLAYERS_THREE_CARDS
	self.searchTeamResult = nil
end
---------------------------------------------------
-- mediator extend begin --
---------------------------------------------------
function RaidHallMediator:InterestSignals()
	local signals = {
		------------ server ------------
		SIGNALNAMES.RaidDetail_Bulid_Callback,
		SIGNALNAMES.RaidDetail_AutoMatching_Callback,
		SIGNALNAMES.RaidDetail_SearchTeam_Callback,
		SIGNALNAMES.RaidMain_BuyAttendTimes_Callback,
		------------ local ------------
		'RAID_CREATE_TEAM',
		'RAID_AUTO_MATCH',
		'RAID_SEARCH_TEAM',
		'RAID_JOIN_TEAM',
		'RAID_SHOW_BUY_CHALLENGE_TIMES',
		'EXIT_RAID_HALL'
	}
	return signals
end
function RaidHallMediator:ProcessSignal(signal)
	local name = signal:GetName()
	local data = signal:GetBody()

	if SIGNALNAMES.RaidDetail_Bulid_Callback == name then

		-- 创建队伍服务器返回
		self:RaidCreateTeamCallback(data)

	elseif SIGNALNAMES.RaidDetail_AutoMatching_Callback == name then

		-- 创建队伍服务器返回
		self:RaidAutoMatchCallback(data)

	elseif SIGNALNAMES.RaidDetail_SearchTeam_Callback == name then

		-- 搜索队伍服务器返回
		self:RaidSearchTeamCallback(data)

	elseif SIGNALNAMES.RaidMain_BuyAttendTimes_Callback == name then

		-- 搜索队伍服务器返回
		self:BuychallengeTimesCallback(data)

	elseif 'RAID_CREATE_TEAM' == name then

		-- 创建队伍
		self:RaidCreateTeam(data)

	elseif 'RAID_AUTO_MATCH' == name then

		-- 创建队伍
		self:RaidAutoMatch(data)

	elseif 'RAID_SEARCH_TEAM' == name then

		-- 创建队伍
		self:RaidSearchTeam(data)

	elseif 'RAID_JOIN_TEAM' == name then

		-- 创建队伍
		self:RaidJoinTeam(data)

	elseif 'RAID_SHOW_BUY_CHALLENGE_TIMES' == name then

		-- 创建队伍
		self:ShowBuyChallengeTimes(data)

	elseif 'EXIT_RAID_HALL' == name then

		-- 退出组队本大厅
		self:ExitRaidHall()

	end
end
function RaidHallMediator:OnRegist()
	-- 注册信号
	local RaidMainCommand = require( 'Game.command.RaidMainCommand')
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_RaidDetail_Bulid, RaidMainCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_RaidDetail_AutoMatching, RaidMainCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_RaidDetail_SearchTeam, RaidMainCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_RaidMain_BuyAttendTimes, RaidMainCommand)
end
function RaidHallMediator:OnUnRegist()
	-- 恢复顶部条
	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightShow")
	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "hide")

	-- 注销信号
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_RaidDetail_Bulid)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_RaidDetail_AutoMatching)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_RaidDetail_SearchTeam)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_RaidMain_BuyAttendTimes)
end
function RaidHallMediator:Initial(key)
	Mediator.Initial(self, key)

	self:InitScene()

	-- 隐藏顶部条
	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightHide")
	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "allhide")
end
---------------------------------------------------
-- mediator extend end --
---------------------------------------------------

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化场景
--]]
function RaidHallMediator:InitScene()
	local raidData = self:GetRaidDataByQuestType(self.teamQuestType)

	local scene = uiMgr:SwitchToTargetScene(
		"Game.views.raid.RaidHallScene",
		{raidQuestType = self.teamQuestType, pattern = 1}
	)
	self:SetViewComponent(scene)

	scene:RefreshUIByRaidQuestType(self.teamQuestType, checkint(gameMgr:GetUserInfo().level), raidData.bossRareReward)
	scene:JumpByGroupId(1)
	-- 刷新剩余次数
	scene:RefreshLeftChallengeTimes(checkint(raidData.leftAttendTimes))
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- logic begin --
---------------------------------------------------
--[[
创建队伍
@params data table {
	stageId int 关卡id
	password string 密码
}
--]]
function RaidHallMediator:RaidCreateTeam(data)
	local stageId = checkint(data.stageId)
	local stageConfig = CommonUtils.GetQuestConf(stageId)

	if checkint(stageConfig.unlockLevel) > checkint(gameMgr:GetUserInfo().level) then
		uiMgr:ShowInformationTips(__('等级不足!!!'))
		return
	end

	local password = data.password

	local requestData = {
		teamTypeId = self.teamQuestType,
		teamBossId = stageId,
		password = password
	}
	self:SendSignal(COMMANDS.COMMAND_RaidDetail_Bulid, requestData)
end
--[[
创建队伍服务器返回
@params responseData table 服务器返回信息
--]]
function RaidHallMediator:RaidCreateTeamCallback(responseData)
	local connectData = {
		ip 			= responseData.ip,
		port 		= responseData.port,
		teamId 		= responseData.questTeamId,
		password 	= responseData.requestData.password,
		bossId 		= responseData.requestData.teamBossId,
		typeId 		= responseData.requestData.teamTypeId,
		buyTimes 	= checkint(self:GetRaidDataByQuestType(self.teamQuestType).leftBuyTimes),
		bossRareReward = checktable(self:GetRaidDataByQuestType(self.teamQuestType).bossRareReward)
	}
	self:ConnectTeam(connectData)
end
function RaidHallMediator:DotLogEvent()
	local viewComponent = self:GetViewComponent()
	if checkint(viewComponent.currentSelectedRaidGroupIndex) > 0 then
		AppFacade.GetInstance():DispatchObservers("DOT_LOG_EVENT_SEND" , {eventId = string.fmt("46-M_num_-01" , {_num_ = viewComponent.currentSelectedRaidGroupIndex})} )
		AppFacade.GetInstance():DispatchObservers("DOT_SET_LOG_EVENT",{eventId =  string.fmt("46-M_num_-02" , {_num_ = viewComponent.currentSelectedRaidGroupIndex})})
	end
end
--[[
自动匹配
@params data table {
	stageId int 关卡id
}
--]]
function RaidHallMediator:RaidAutoMatch(data)
	local stageId = checkint(data.stageId)
	local stageConfig = CommonUtils.GetQuestConf(stageId)
	if checkint(stageConfig.unlockLevel) > checkint(gameMgr:GetUserInfo().level) then
		uiMgr:ShowInformationTips(__('等级不足!!!'))
		return
	end

	local requestData = {
		teamTypeId = self.teamQuestType,
		teamBossId = stageId
	}
	self:SendSignal(COMMANDS.COMMAND_RaidDetail_AutoMatching, requestData)
end
--[[
自动匹配服务器返回
@params responseData table 服务器返回信息
--]]
function RaidHallMediator:RaidAutoMatchCallback(responseData)
	local connectData = {
		ip 			= responseData.ip,
		port 		= responseData.port,
		teamId 		= checkint(responseData.id),
		-- password 	= responseData.requestData.password,
		password 	= '',
		bossId 		= responseData.requestData.teamBossId,
		typeId 		= responseData.requestData.teamTypeId,
		buyTimes 	= checkint(self:GetRaidDataByQuestType(self.teamQuestType).leftBuyTimes),
		bossRareReward = checktable(self:GetRaidDataByQuestType(self.teamQuestType).bossRareReward)
	}
	self:ConnectTeam(connectData)
end
--[[
搜索房间
@params data table {
	teamId int 队伍id
}
--]]
function RaidHallMediator:RaidSearchTeam(data)
	local teamId = checkint(data.teamId)
	if 0 == teamId then
		uiMgr:ShowInformationTips(__('请输入正确的队伍号!!!'))
		return
	end

	local requestData = {
		teamTypeId = self.teamQuestType,
		keyword = data.teamId
	}

	self:SendSignal(COMMANDS.COMMAND_RaidDetail_SearchTeam, requestData)
end
--[[
搜索队伍服务器返回
@params responseData table 服务器返回信息
--]]
function RaidHallMediator:RaidSearchTeamCallback(data)
	local questTeamData = data.questTeams[1]
	self.searchTeamResult = data.questTeams
	local teamErrcode = self:CheckCanJoinTeam(questTeamData)
	if JoinTeamErrcode.VALID == teamErrcode then
		local stageId = checkint(questTeamData.teamBossId)
		local stageConfig = CommonUtils.GetQuestConf(stageId)
		local groupId = checkint(stageConfig.group)
		local raidData = self:GetRaidDataByQuestType(self.teamQuestType)

		-- 房间有效
		local teamData = {
			stageId = stageId,
			gotRareReward = checkint(raidData[tostring(groupId)]),
			leftChallengeTimes = checkint(raidData.leftAttendTimes),
			teamId = checkint(questTeamData.id),
			rlData = {
				playerId 			= checkint(questTeamData.creatorId),
				playerName 			= tostring(questTeamData.creatorName),
				playerLevel 		= checkint(questTeamData.creatorLevel),
				playerAvatar 		= tostring(questTeamData.creatorAvatar),
				playerAvatarFrame 	= tostring(questTeamData.creatorAvatarFrame)
			}
		}
		local raidEnterTeamView = require('Game.views.raid.RaidEnterTeamView').new(teamData)
		display.commonUIParams(raidEnterTeamView, {ap = cc.p(0.5, 0.5), po = cc.p(
			display.cx, display.cy
		)})
		raidEnterTeamView:setTag(RaidEnterTeamViewTag)
		uiMgr:GetCurrentScene():AddDialog(raidEnterTeamView)
	else
		-- 房间无效
		uiMgr:ShowInformationTips(JoinTeamErrMsg[teamErrcode])
		return
	end
end
--[[
加入队伍
@params data table {
	teamId int 队伍id
	stageId int 关卡id
}
--]]
function RaidHallMediator:RaidJoinTeam(data)
	local stageId = checkint(data.stageId)
	local stageConfig = CommonUtils.GetQuestConf(stageId)

	if checkint(stageConfig.unlockLevel) > checkint(gameMgr:GetUserInfo().level) then
		uiMgr:ShowInformationTips(__('等级不足!!!'))
		return
	end

	local teamId = checkint(data.teamId)
	local questTeamData = self:GetSearchQuestTeamDataByTeamId(teamId)
	if nil == questTeamData then
		uiMgr:ShowInformationTips(JoinTeamErrMsg[JoinTeamErrcode.INVAILD])
		return
	end

	local password = string.gsub(tostring(questTeamData.password), ' ', '')
	local hasPassword = ('' ~= password)

	if not hasPassword then
		-- 移除详情界面
		uiMgr:GetCurrentScene():RemoveDialogByTag(RaidEnterTeamViewTag)

		-- 无密码 直接起长连接
		local connectData = {
			ip 			= questTeamData.ip,
			port 		= questTeamData.port,
			teamId 		= checkint(questTeamData.id),
			password 	= questTeamData.password,
			bossId 		= questTeamData.teamBossId,
			typeId 		= self.teamQuestType,
			buyTimes 	= checkint(self:GetRaidDataByQuestType(self.teamQuestType).leftBuyTimes),
			bossRareReward = checktable(self:GetRaidDataByQuestType(self.teamQuestType).bossRareReward)
		}
		self:ConnectTeam(connectData)
	else
		-- 显示输密码层
		uiMgr:ShowNumberKeyBoard({
			nums = 6,
			model = 2,
			callback = function (str)
				if questTeamData.password == str then
					-- 移除详情界面
					uiMgr:GetCurrentScene():RemoveDialogByTag(RaidEnterTeamViewTag)
					-- 密码正确 连接
					local connectData = {
						ip 			= questTeamData.ip,
						port 		= questTeamData.port,
						teamId 		= checkint(questTeamData.id),
						password 	= questTeamData.password,
						bossId 		= questTeamData.teamBossId,
						typeId 		= self.teamQuestType,
						buyTimes 	= checkint(self:GetRaidDataByQuestType(self.teamQuestType).leftBuyTimes),
						bossRareReward = checktable(self:GetRaidDataByQuestType(self.teamQuestType).bossRareReward)
					}
					self:ConnectTeam(connectData)
				else
					-- 密码错误
					uiMgr:ShowInformationTips(__('密码错误!!!'))
				end
			end,
			titleText = __('请输入六位数字密码'),
			defaultContent = self.passwordStr
		})
	end
end
--[[
根据连接数据加入组队副本
@params connectData table 连接信息 {
	ip 
	port
	teamId
	password
	bossId
	typeId
	buyTimes
}
--]]
function RaidHallMediator:ConnectTeam(connectData)
	self:DotLogEvent()
	local mediator = require('Game.mediator.TeamQuestMediator').new()
	AppFacade.GetInstance():RegistMediator(mediator)
	AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.TEAM_BOSS_SOCKET_CONNECT, connectData)
end
--[[
购买次数弹窗
--]]
function RaidHallMediator:ShowBuyChallengeTimes()

	local teamTypeConfig = CommonUtils.GetConfig('quest', 'teamType', self.teamQuestType)
	local costInfo = {
        goodsId = DIAMOND_ID,
        num = checkint(teamTypeConfig.buyTimesPrice)
    }
	local challengeTimes = checkint(CommonUtils.getVipTotalLimitByField('questTeamBuyNum'))

	local leftBuyTimes = checkint(self:GetRaidDataByQuestType(self.teamQuestType).leftBuyTimes)
	local textRich = {
		{text = __('确定要追加') },
		{text = tostring(challengeTimes), fontSize = 26, color = '#ff0000'},
		{text = __('次挑战次数吗?')}
	}
	local descrRich = {
		{text = __('当前还可以购买') },
		{text = tostring(leftBuyTimes), fontSize = fontWithColor('15').fontSize, color = '#ff0000'},
		{text = __('次\n挑战次数每日00:00重置')},
	}


	-- 显示购买弹窗
	local layer = require('common.CommonTip').new({
		textRich = textRich,
		descrRich = descrRich,
		defaultRichPattern = true,
		costInfo = costInfo,
		callback = function (sender)
			-- 可行性判断
			if 0 >= leftBuyTimes then
				uiMgr:ShowInformationTips(__('剩余购买次数已用完!!!'))
				return
			end

			local goodsAmount = gameMgr:GetAmountByIdForce(costInfo.goodsId)
			if costInfo.num > goodsAmount then
				if GAME_MODULE_OPEN.NEW_STORE and checkint(costInfo.goodsId) == DIAMOND_ID then
					app.uiMgr:showDiamonTips()
				else
					local goodsConfig = CommonUtils.GetConfig('goods', 'goods', costInfo.goodsId)
					uiMgr:ShowInformationTips(string.format(__('%s不足!!!'), goodsConfig.name))
				end
				return
			end

			self:SendSignal(COMMANDS.COMMAND_RaidMain_BuyAttendTimes, {teamTypeId = self.teamQuestType})
		end
	})
	layer:setPosition(display.center)
    uiMgr:GetCurrentScene():AddDialog(layer)
end
--[[
购买次数服务器回调
@params responseData table 服务器返回信息
--]]
function RaidHallMediator:BuychallengeTimesCallback(responseData)
	local challengeTimes = checkint(CommonUtils.getVipTotalLimitByField('questTeamBuyNum'))

	------------ data ------------
	self:GetRaidDataByQuestType(self.teamQuestType).leftBuyTimes = checkint(self:GetRaidDataByQuestType(self.teamQuestType).leftBuyTimes) - 1
	self:GetRaidDataByQuestType(self.teamQuestType).leftAttendTimes = checkint(self:GetRaidDataByQuestType(self.teamQuestType).leftAttendTimes) + challengeTimes

	-- 扣除消耗
	local diamondInfo = {
		{goodsId = DIAMOND_ID, num = checkint(responseData.diamond) - gameMgr:GetAmountByIdForce(DIAMOND_ID)}
	}
	CommonUtils.DrawRewards(diamondInfo)
	------------ data ------------

	------------ view ------------
	uiMgr:ShowInformationTips(__('购买挑战次数成功!!!'))
	self:GetViewComponent():RefreshLeftChallengeTimes(self:GetRaidDataByQuestType(self.teamQuestType).leftAttendTimes)

	-- 刷新一些全局界面
	AppFacade.GetInstance():DispatchObservers('RAID_REFRESH_LEFT_CHALLENGE_TIMES', {
		currentTimes = checkint(self:GetRaidDataByQuestType(self.teamQuestType).leftAttendTimes)
	})
	------------ view ------------
end
--[[
退出组队本大厅
--]]
function RaidHallMediator:ExitRaidHall()
	app.router:Dispatch({name = NAME}, {name = self:GetBackToMediator()})
end
---------------------------------------------------
-- logic end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------
--[[
根据组队类型获取玩家的组队数据
@params raidQuestType RaidQuestType 组队类型
@return result table 组队数据
--]]
function RaidHallMediator:GetRaidDataByQuestType(raidQuestType)
	for i,v in ipairs(self.raidData) do
		if raidQuestType == checkint(v.teamTypeId) then
			return v
		end
	end
end
--[[
检查是否可以加入房间
@params questTeamData table 队伍信息
@return errcode JoinTeamErrcode 错误编号
--]]
function RaidHallMediator:CheckCanJoinTeam(questTeamData)
	local errcode = JoinTeamErrcode.VALID

	-- 传参非法
	if nil == questTeamData then
		errcode = JoinTeamErrcode.NO_TEAM
		return errcode
	end

	-- 人满了
	if checkint(questTeamData.attendNum) >= checkint(questTeamData.maxNum) then
		-- 如果自己是创建者 无视满员直接进入
		if checkint(questTeamData.creatorId) ~= checkint(gameMgr:GetUserInfo().playerId) then
			errcode = JoinTeamErrcode.PLAYER_MAX
		end
	end

	-- 房间在战斗中
	if 4 == checkint(questTeamData.status) or 3 == checkint(questTeamData.status) then
		errcode = JoinTeamErrcode.IN_BATTLE
	end

	return errcode
end
--[[
根据队伍id获取搜索队伍信息
@params teamId int 队伍id
@return questTeamData table 队伍信息
--]]
function RaidHallMediator:GetSearchQuestTeamDataByTeamId(teamId)
	local questTeamData = nil
	for i,v in ipairs(self.searchTeamResult) do
		if checkint(v.id) == teamId then
			questTeamData = v
		end
	end
	return questTeamData
end
--[[
获取返回的mediator信息
@return name string 返回的mediator名字
--]]
function RaidHallMediator:GetBackToMediator()
	local name = 'HomeMediator'
	if nil ~= self.raidData.requestData and nil ~= self.raidData.requestData.backMediatorName then
		name = self.raidData.requestData.backMediatorName
	end
	return name
end
---------------------------------------------------
-- get set end --
---------------------------------------------------

return RaidHallMediator
