--[[
 * author : liuzhipeng
 * descpt : 好友 好友切磋Mediator
--]]
local Mediator = mvc.Mediator

local FriendBattleMediator = class("FriendBattleMediator", Mediator)

local NAME = "FriendBattleMediator"
local FRIEND_BATTLE_TEAM_CHANGE_NOTICE = 'FRIEND_BATTLE_TEAM_CHANGE_NOTICE'
--[[
@param enemyPlayerId int 敌方玩家id 传入这个参数界面将以弹出层形式显示，并且不可以切换对手
--]]
function FriendBattleMediator:ctor( params, viewComponent )
	self.super:ctor(NAME,viewComponent)
	local args = checktable(params)
	self.enemyPlayerId = args.enemyPlayerId
	self.playerData = {} -- 玩家信息
	self.enemyData = {}  -- 敌方信息
end
-------------------------------------------------
------------------ inheritance ------------------
function FriendBattleMediator:Initial( key )
	self.super.Initial(self,key)
	local viewComponent  = require( 'Game.views.friend.FriendBattleView' ).new()
	self:SetViewComponent(viewComponent)
	viewComponent.viewData.tipsBtn:setOnClickScriptHandler(handler(self, self.TipsButtonCallback))
	viewComponent.viewData.reportBtn:setOnClickScriptHandler(handler(self, self.ReportButtonCallback))
	viewComponent.viewData.enemyTeamBtn:setOnClickScriptHandler(handler(self, self.EnemyTeamButtonCallback))
	viewComponent.viewData.battleBtn:SetClickCallback(handler(self, self.BattleButtonCallback))
	for i, v in ipairs(viewComponent.viewData.cardHeadBtnlist) do
		v:setOnClickScriptHandler(handler(self,self.CardHeadButtonCallback))
	end

	-- 初始化页面
	self:InitView()
end

function FriendBattleMediator:InterestSignals()
	local signals = { 
		POST.FRIEND_BATTLE_TEAM.sglName,
		POST.FRIEND_SAVE_BATTLE_TEAM.sglName,
		POST.FRIEND_BATTLE_HISTORY.sglName,
		POST.FRIEND_BATTLE_HISTORY.sglName,
		FRIEND_BATTLE_TEAM_CHANGE_NOTICE, 
		FRIEND_BATTLE_CHOOSE_ENEMY,
	}
	return signals
end

function FriendBattleMediator:ProcessSignal( signal )
	local name = signal:GetName() 
	local body = signal:GetBody()
	print(name)
	if name == POST.FRIEND_BATTLE_TEAM.sglName then -- 获取编队
		if body.requestData.friendId == app.gameMgr:GetPlayerId() then
			-- 刷新己方编队
			self:RefreshTeam(checktable(body))

			if self:IsPopupPattern() then
				-- 获取敌方编队信息
				self:SendSignal(POST.FRIEND_BATTLE_TEAM.cmdName, {friendId = self.enemyPlayerId})
			end
		else
			-- 刷新并锁定敌方编队
			self:RefreshAndLockEnemyTeam(checktable(body))
		end
	elseif name == POST.FRIEND_SAVE_BATTLE_TEAM.sglName then -- 保存己方编队
	elseif name == POST.FRIEND_BATTLE_HISTORY.sglName then -- 回放
		self:ShowReportPopup(checktable(body.studyList))
	elseif name == FRIEND_BATTLE_TEAM_CHANGE_NOTICE then -- 编队改变信号
		self:UpdateTeamData(body.teamData)
	elseif name == FRIEND_BATTLE_CHOOSE_ENEMY then -- 好友切磋选择对手
		self:RefreshEnemyInformation(body)
	end
end

function FriendBattleMediator:OnRegist(  )
	regPost(POST.FRIEND_BATTLE_TEAM)
	regPost(POST.FRIEND_BATTLE_HISTORY)
	regPost(POST.FRIEND_SAVE_BATTLE_TEAM)
	-- 获取己方编队
	self:SendSignal(POST.FRIEND_BATTLE_TEAM.cmdName, {friendId = app.gameMgr:GetPlayerId()})
end

function FriendBattleMediator:OnUnRegist(  )
	print( "OnUnRegist" )
	unregPost(POST.FRIEND_BATTLE_TEAM)
	unregPost(POST.FRIEND_BATTLE_HISTORY)
	unregPost(POST.FRIEND_SAVE_BATTLE_TEAM)
	if self:IsPopupPattern() then
		local scene = app.uiMgr:GetCurrentScene()
		scene:RemoveDialog(self.viewComponent)
	end
end
------------------ inheritance ------------------
-------------------------------------------------

-------------------------------------------------
-------------------- handler --------------------
--[[
提示按钮点击回调
--]]
function FriendBattleMediator:TipsButtonCallback( sender )
	PlayAudioByClickNormal()
	app.uiMgr:ShowIntroPopup({moduleId = '-60'})
end
--[[
战报按钮点击回调
--]]
function FriendBattleMediator:ReportButtonCallback( sender )
	PlayAudioByClickNormal()
	self:SendSignal(POST.FRIEND_BATTLE_HISTORY.cmdName)
end
--[[
敌人选择按钮点击回调
--]]
function FriendBattleMediator:EnemyTeamButtonCallback( sender )
	PlayAudioByClickNormal()
	local friendBattlrChooseEnemyMediator = require('Game.mediator.friend.FriendBattleChooseEnemyMediator').new()
	app:RegistMediator(friendBattlrChooseEnemyMediator)
end
--[[
战斗按钮点击回调
--]]
function FriendBattleMediator:BattleButtonCallback( sender )
	PlayAudioByClickNormal()
	local enemyData = self:GetEnemyData()
	if enemyData and self:IsTeamDataValid(enemyData.team) then
		self:EnterBattle()
	else
		app.uiMgr:ShowInformationTips(__('请先选择对手'))
	end
end
--[[
卡牌头像背景点击回调
--]]
function FriendBattleMediator:CardHeadButtonCallback( sender )
	PlayAudioByClickNormal()
	local layer = require('Game.views.pvc.PVCChangeTeamScene').new({
        teamDatas = clone({[1] = self:GetPlayerData().team}),
        title = __('编辑队伍'),
        teamTowards = -1,
        avatarTowards = 1,
        teamChangeSingalName = FRIEND_BATTLE_TEAM_CHANGE_NOTICE,
        limitCardsCareers =  {},
        limitCardsQualities =  {},
        isDisableHomeTopSignal = true,
        battleType  = 1
    })
    layer:setAnchorPoint(cc.p(0.5, 0.5))
    layer:setPosition(display.center)
    layer:setTag(4001)
	app.uiMgr:GetCurrentScene():AddDialog(layer)
	self:SetChangeTeamScene(layer)
end

-------------------- handler --------------------
-------------------------------------------------

-------------------------------------------------
-------------------- private --------------------
--[[
初始化页面
--]]
function FriendBattleMediator:InitView()
	if self:IsPopupPattern() then
		local viewComponent = self:GetViewComponent()
		viewComponent:PopupPattern()
	end
end
--[[
更新编队信息
--]]
function FriendBattleMediator:UpdateTeamData( teamData )
	if self:IsTeamDataValid(teamData) then
		-- 更新本地编队数据
		local playerData = self:GetPlayerData()
		playerData.team = checktable(teamData)
		self:RefreshTeam(playerData)
		self:SaveTeam(playerData.team)
		self:RemoveChangeTeamScene()
	else
		app.uiMgr:ShowInformationTips(__('编队不能为空'))
	end
end
--[[
移除编队页面
--]]
function FriendBattleMediator:RemoveChangeTeamScene()
	local changeTeamScene = self:GetChangeTeamScene()
	if changeTeamScene and not tolua.isnull(changeTeamScene) then
		-- 移除编队界面
		changeTeamScene:runAction( cc.RemoveSelf:create()) 
		self.ChangeTeamScene = nil
	end
end
--[[
刷新己方编队
@params playerData map 编队数据 {
	avatar      string 头像id
	avatarFrame string 头像框id
	level       string 等级
	name        string 名称
	team        list   编队信息
}
--]]
function FriendBattleMediator:RefreshTeam( playerData )
	local viewComponent = self:GetViewComponent()
	viewComponent:RefreshTeam(checktable(playerData.team))
	self:SetPlayerData(playerData)
end
--[[
刷新并锁定敌方编队
@params playerData map 编队数据 {
	avatar      string 头像id
	avatarFrame string 头像框id
	level       string 等级
	name        string 名称
	team        list   编队信息
}
--]]
function FriendBattleMediator:RefreshAndLockEnemyTeam( playerData )
	local viewComponent = self:GetViewComponent()
	playerData.friendId = checkint(self.enemyPlayerId)
	viewComponent:RefreshEnemyInformation(playerData)
	self:SetEnemyData(playerData)
end
--[[
刷新敌方编队
@params playerData map 编队数据 {
	avatar      string 头像id
	avatarFrame string 头像框id
	level       string 等级
	name        string 名称
	friendId    int    玩家Id
	team        list   编队信息
}
--]]
function FriendBattleMediator:RefreshEnemyInformation( playerData )
	local viewComponent = self:GetViewComponent()
	viewComponent:RefreshEnemyInformation(playerData)
	self:SetEnemyData(playerData)
end
--[[
保存己方好友切磋编队
@params team list 己方编队信息
--]]
function FriendBattleMediator:SaveTeam( team )
	local cards = ''
	for i, v in ipairs(team) do
		if i ~= #team then
			cards = cards .. (v.id or '').. ','
		else
			cards = cards .. (v.id or '')
		end
	end
	self:SendSignal(POST.FRIEND_SAVE_BATTLE_TEAM.cmdName, {cards = cards})
end
--[[
判断编队信息是否合法
@teamData list 编队信息
@return valid bool 数据是否合法
--]]
function FriendBattleMediator:IsTeamDataValid( teamData )
	local valid = false 
	for i, v in ipairs(checktable(teamData)) do
		if v.id or v.cardId then
			valid = true
			break
		end
	end
	return valid
end
--[[
进入战斗
--]]
function FriendBattleMediator:EnterBattle()
	local playerData = self:GetPlayerData()
	local enemyData = self:GetEnemyData()
	local teamData = {}

	for i, v in ipairs(checktable(playerData.team)) do
		if v.id and 0 ~= checkint(v.id) then
			table.insert(teamData, checkint(v.id))
		end
	end

	if #teamData == 0 then -- 判空
		app.uiMgr:ShowInformationTips(__('队伍不能为空'))
		return
	end

	local serverCommand = BattleNetworkCommandStruct.New(
		POST.FRIEND_BATTLE_QUEST_AT.cmdName ,
		{friendId = enemyData.friendId},
		POST.FRIEND_BATTLE_QUEST_AT.sglName,

		POST.FRIEND_BATTLE_QUEST_GRADE.cmdName ,
		{friendId = enemyData.friendId},
		POST.FRIEND_BATTLE_QUEST_GRADE.sglName,

		nil,
		nil,
		nil
	)
	local fromToStruct = BattleMediatorsConnectStruct.New(
		"FriendBattleMediator",
		"HomeMediator"
	)
	local battleConstructor = require('battleEntry.BattleConstructor').new()
    battleConstructor:InitByCommonPVCSingleTeam(
			QuestBattleType.FRIEND_BATTLE,
            ConfigBattleResultType.ONLY_RESULT,
            teamData,
            enemyData.team,
            {},
            {},
            nil,
            nil ,
            serverCommand,
            fromToStruct
    )
	battleConstructor:OpenBattle()
end
--[[
显示回放Popup
@params list reportList
--]]
function FriendBattleMediator:ShowReportPopup( reportList )
	app.uiMgr:AddDialog('Game.views.friend.FriendBattleReportPopup', {reportList = reportList})
end
--[[
是否为弹窗样式
--]]
function FriendBattleMediator:IsPopupPattern()
	return self.enemyPlayerId and true or false
end
-------------------- private --------------------
-------------------------------------------------

-------------------------------------------------
------------------- get / set -------------------
--[[
设置编队页面
--]]
function FriendBattleMediator:SetChangeTeamScene( ChangeTeamScene )
	self.ChangeTeamScene = ChangeTeamScene
end
--[[
获取编队页面
--]]
function FriendBattleMediator:GetChangeTeamScene( )
	return self.ChangeTeamScene
end
--[[
设置编队信息
@params playerData map 编队数据 {
	avatar      string 头像id
	avatarFrame string 头像框id
	level       string 等级
	name        string 名称
	team        list 编队信息
}
--]]
function FriendBattleMediator:SetPlayerData( playerData )
	self.playerData = checktable(playerData)
end
--[[
获取编队信息
--]]
function FriendBattleMediator:GetPlayerData()
	return self.playerData or {}
end
--[[
设置敌人信息
@params playerData map 编队数据 {
	avatar      string 头像id
	avatarFrame string 头像框id
	level       string 等级
	name        string 名称
	team        list 编队信息
}
--]]
function FriendBattleMediator:SetEnemyData( playerData )
	self.enemyData = playerData
end
--[[
获取敌人信息
--]]
function FriendBattleMediator:GetEnemyData()
	return self.enemyData or {}
end
------------------- get / set -------------------
-------------------------------------------------
return FriendBattleMediator
