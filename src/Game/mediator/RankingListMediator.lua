--[[
排行榜Mediator
--]]
local Mediator = mvc.Mediator

local RankingListMediator = class("RankingListMediator", Mediator)

local NAME = "RankingListMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance('AppFacade'):GetManager("GameManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
local unionMgr = AppFacade.GetInstance():GetManager("UnionManager")
local scheduler = require('cocos.framework.scheduler')
local RankCell = require('home.RankCell')
local RankPopularityCell = require('home.RankPopularityCell')
local RankTowerCell = require('home.RankTowerCell')
local RankPVCCell = require('home.RankPVCCell')
local RankUnionContributionCell = require('home.RankUnionContributionCell')
local RankUnionGodBeastCell = require('home.RankUnionGodBeastCell')
local RankUnionWarsCell = require('home.RankUnionWarsCell')

local RANK = {
	{name = __('知名度排行榜'), rankTypes = RankTypes.RESTAURANT_COMPREHENSIVENESS,	switch = MODULE_SWITCH.RESTAURANT},
	{name = __('营收排行榜'), rankTypes = RankTypes.RESTAURANT_REVENUE,				switch = MODULE_SWITCH.RESTAURANT},
	{name = __('遗迹排行榜'), rankTypes = RankTypes.TOWER,							switch = MODULE_SWITCH.TOWER, child = {
		{name = __('本周排行榜'), rankTypes = RankTypes.TOWER_WEEKLY}, 
		{name = __('历史排行榜'), rankTypes = RankTypes.TOWER_HISTORY}
	}},
	{name = __('皇家对决排行榜')  , rankTypes = RankTypes.PVC_WEEKLY,    			 switch = MODULE_SWITCH.PVC_ROYAL_BATTLE},
	{name = __('空运排行榜'), rankTypes = RankTypes.AIRSHIP,						switch = MODULE_SWITCH.AIR_TRANSPORTATION},
	{name = __('工会排行榜'), rankTypes = RankTypes.UNION, 							switch = MODULE_SWITCH.GUILD, child = {
		{name = __('本周贡献排行'), rankTypes = RankTypes.UNION_CONTRIBUTIONPOINT},
		--{name = __('工会竞赛排行榜'), rankTypes = RankTypes.UNION_WARS,			     switch = MODULE_SWITCH.UNION_WARS, moduleState = GAME_MODULE_OPEN.UNION_WARS},
		{name = __('历史贡献排行'), rankTypes = RankTypes.UNION_CONTRIBUTIONPOINT_HISTORY},
		{name = __('神兽战力排行榜'), rankTypes = RankTypes.UNION_GODBEAST,			switch = MODULE_SWITCH.UNION_HUNT}
	}},
	{name = __('灾祸战斗排行'), rankTypes = RankTypes.BOSS,							switch = MODULE_SWITCH.WORLD_BOSS, child = {
		{name = __('个人榜'), rankTypes = RankTypes.BOSS_PERSON},
		{name = __('工会榜'), rankTypes = RankTypes.BOSS_UNION,						switch = MODULE_SWITCH.GUILD},
	}},
}
local PROLONG_TIME = 2
function RankingListMediator:ctor( params, viewComponent )
	local datas = params or {}
	self.super:ctor(NAME,viewComponent)
	-- self.selectedRank = datas.rankTypes or RankTypes.RESTAURANT_COMPREHENSIVENESS
	self.showLayer = {}
	self.rankLayerDatas = {}
	self.rankDatas = {}
	self.leftTimeScheduler = scheduler.scheduleGlobal(handler(self, self.LeftScheduleCallback), 1)
	local checkOpenFunc = function(rankDefine)
		if not rankDefine then return false end
		local isCloseModule = rankDefine.moduleState == false
		return isCloseModule and rankDefine.switch and CommonUtils.GetModuleAvailable(rankDefine.switch)
	end
	for i=table.nums(RANK),1,-1 do
		if RANK[i].child then
			for j=table.nums(RANK[i].child),1,-1 do
				if checkOpenFunc(RANK[i].child[j]) then
					table.remove( RANK[i].child, j )
				end
			end
			-- check child is remove all
			if not next(RANK[i].child) then
				table.remove( RANK, i )
			elseif checkOpenFunc(RANK[i]) then
				table.remove( RANK, i )
			end
		elseif checkOpenFunc(RANK[i]) then
			table.remove( RANK, i )
		end
	end
	if next(RANK) then
		self.selectedRank = datas.rankTypes or RANK[1].rankTypes
	else
		self.selectedRank = datas.rankTypes or nil
	end
end

function RankingListMediator:InterestSignals()
	local signals = {
		SIGNALNAMES.Rank_Restaurant_Callback,
		SIGNALNAMES.Rank_RestaurantRevenue_Callback,
		SIGNALNAMES.Rank_Tower_Callback,
		SIGNALNAMES.Rank_TowerHistory_Callback,
		SIGNALNAMES.Rank_ArenaRank_Callback,
		SIGNALNAMES.Rank_Airship_Callback,
		SIGNALNAMES.Rank_Union_Contribution_Callback,
		SIGNALNAMES.Rank_Union_ContributionHistory_Callback,
		SIGNALNAMES.Rank_Union_GodBeast_Callback,
		SIGNALNAMES.Rank_BOSS_Person_Callback,
		SIGNALNAMES.Rank_BOSS_Union_Callback,
		POST.RANK_UNION_WARS.sglName,
	}
	return signals
end

function RankingListMediator:ProcessSignal( signal )
	local name = signal:GetName()
	print(name)
	if name == SIGNALNAMES.Rank_Restaurant_Callback then
		local datas = checktable(signal:GetBody())
		datas.rankList = datas.popularityRank
		datas.myRank = datas.myPopularityRank
		datas.myScore = datas.myPopularityScore
		datas.lastRank = datas.lastPopularityRank
		datas.leftSeconds = checkint(datas.popularityRankLeftSeconds) + PROLONG_TIME
		for i,v in ipairs(datas.lastRank or {}) do
			datas.lastRank[i].score = v.popularity
		end
		self.rankDatas[tostring(RankTypes.RESTAURANT_COMPREHENSIVENESS)] = datas
		self:refreshUi()
	elseif name == SIGNALNAMES.Rank_RestaurantRevenue_Callback then
		local datas = checktable(signal:GetBody())
		datas.rankList = datas.goldRank
		datas.myRank = datas.myGoldRank
		datas.myScore = datas.myGoldScore
		datas.lastRank = datas.lastGoldRank
		datas.leftSeconds = checkint(datas.goldRankLeftSeconds) + PROLONG_TIME
		for i,v in ipairs(datas.lastRank) do
			datas.lastRank[i].score = v.gold
		end
		self.rankDatas[tostring(RankTypes.RESTAURANT_REVENUE)] = datas
		self:refreshUi()
	elseif name == SIGNALNAMES.Rank_Tower_Callback then
		local datas = checktable(signal:GetBody())
		datas.rankList = datas.towerRank
		datas.myRank = datas.myTowerRank
		datas.myScore = datas.myTowerScore
		datas.lastRank = datas.lastTowerRank
		datas.leftSeconds = checkint(datas.towerRankLeftSeconds) + PROLONG_TIME
		self.rankDatas[tostring(RankTypes.TOWER_WEEKLY)] = datas
		for i,v in ipairs(datas.lastRank or {}) do
			datas.lastRank[i].score = v.maxTowerFloor
		end
		self:refreshUi()
	elseif name == SIGNALNAMES.Rank_TowerHistory_Callback then
		local datas = checktable(signal:GetBody())
		datas.rankList = datas.towerHistoryRank
		datas.myRank = datas.myHistoryTowerRank
		datas.myScore = datas.myHistoryTowerScore
		self.rankDatas[tostring(RankTypes.TOWER_HISTORY)] = datas
		self:refreshUi()
	elseif name == SIGNALNAMES.Rank_ArenaRank_Callback then
		local datas = checktable(signal:GetBody())
		datas.rankList = datas.arenaRank
		datas.myRank = datas.myArenaRank
		datas.myScore = datas.myArenaScore
		datas.lastRank = datas.lastArenaRank
		datas.leftSeconds = checkint(datas.arenaRankLeftSeconds) + PROLONG_TIME
		for i,v in ipairs(datas.lastRank or {}) do
			datas.lastRank[i].score = v.integral
		end
		self.rankDatas[tostring(RankTypes.PVC_WEEKLY)] = datas
		self:refreshUi()
	elseif name == SIGNALNAMES.Rank_Airship_Callback then
		local datas = checktable(signal:GetBody())
		datas.rankList = datas.airshipRank
		datas.myRank = datas.myAirshipRank
		datas.myScore = datas.myAirshipScore
		datas.lastRank = datas.lastAirshipRank
		datas.leftSeconds = checkint(datas.airshipRankLeftSeconds) + PROLONG_TIME
		for i,v in ipairs(datas.lastRank or {}) do
			datas.lastRank[i].score = v.airshipPoint
		end
		self.rankDatas[tostring(RankTypes.AIRSHIP)] = datas
		self:refreshUi()
	elseif name == SIGNALNAMES.Rank_Union_Contribution_Callback then
		local datas = checktable(signal:GetBody())
		datas.rankList = datas.unionRank
		datas.myRank = datas.myUnionRank
		datas.myScore = datas.myUnionScore
		datas.lastRank = datas.lastUnionRank
		datas.leftSeconds = checkint(datas.unionRankLeftSeconds) + PROLONG_TIME
		for i,v in ipairs(datas.lastRank or {}) do
			datas.lastRank[i].score = v.contributionPoint
			datas.lastRank[i].playerName = v.unionName
		end
		self.rankDatas[tostring(RankTypes.UNION_CONTRIBUTIONPOINT)] = datas
		self:refreshUi()
	elseif name == SIGNALNAMES.Rank_Union_ContributionHistory_Callback then
		local datas = checktable(signal:GetBody())
		datas.rankList = datas.unionHistoryRank
		datas.myRank = datas.myHistoryUnionRank
		datas.myScore = datas.myHistoryUnionScore
		self.rankDatas[tostring(RankTypes.UNION_CONTRIBUTIONPOINT_HISTORY)] = datas
		self:refreshUi()
	elseif name == SIGNALNAMES.Rank_Union_GodBeast_Callback then
		local datas = checktable(signal:GetBody())
		datas.rankList = datas.godBeastRank
		datas.myRank = datas.myGodBeastRank
		datas.myScore = datas.myGodBeastScore
		self.rankDatas[tostring(RankTypes.UNION_GODBEAST)] = datas
		self:refreshUi()
	elseif name == SIGNALNAMES.Rank_BOSS_Union_Callback then	
		local datas = checktable(signal:GetBody())
		datas.rankList = datas.unionBossRank
		datas.myRank = datas.myUnionRank
		datas.myScore = datas.myUnionDamage
		datas.lastRank = datas.lastUnionRank
		datas.leftSeconds = checkint(datas.leftTimes) + PROLONG_TIME
		for i,v in ipairs(datas.lastRank or {}) do
			datas.lastRank[i].score = v.damage
			datas.lastRank[i].playerName = v.unionName
		end
		self.rankDatas[tostring(RankTypes.BOSS_UNION)] = datas
		self:refreshUi()
	elseif name == SIGNALNAMES.Rank_BOSS_Person_Callback then	
		local datas = checktable(signal:GetBody())
		datas.rankList = datas.personalBossRank
		datas.myRank = datas.myRank
		datas.myScore = datas.myDamage
		datas.lastRank = datas.lastPersonalRank
		datas.leftSeconds = checkint(datas.leftTimes) + PROLONG_TIME
		for i,v in ipairs(datas.lastRank or {}) do
			datas.lastRank[i].score = v.damage
		end
		self.rankDatas[tostring(RankTypes.BOSS_PERSON)] = datas
		self:refreshUi()
	elseif name == POST.RANK_UNION_WARS.sglName then
		local datas = checktable(signal:GetBody())
		datas.rankList = datas.unionRank
		datas.myRank = datas.myUnionRank
		datas.myScore = datas.myUnionWarsScore
		datas.lastRank = datas.lastUnionRank
		datas.leftSeconds = checkint(datas.unionWarsRankLeftSeconds) + PROLONG_TIME
		for i,v in ipairs(datas.lastRank or {}) do
			datas.lastRank[i].score = v.unionWarsPoint
			datas.lastRank[i].playerName = v.unionName
		end
		self.rankDatas[tostring(RankTypes.UNION_WARS)] = datas
		self:refreshUi()
	end
end

function RankingListMediator:Initial( key )
	self.super.Initial(self,key)
	-- local RankingListScene = require("Game.views.RankingListScene").new()
	-- uiMgr:AddDialog(RankingListScene)
	local scene = uiMgr:GetCurrentScene()
	local viewComponent  = require( 'Game.views.RankingListScene' ).new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	scene:AddDialog(viewComponent)
	viewComponent.viewData.backBtn:setOnClickScriptHandler(function ()
        PlayAudioByClickClose()
        AppFacade.GetInstance():UnRegsitMediator("RankingListMediator")
	end)
end
function RankingListMediator:refreshUi()
	local viewData = self:GetViewComponent().viewData
	viewData.listView:removeAllNodes()
	for i,v in ipairs(RANK) do
		local cSize = cc.size(212, 90)
		local cell = RankCell.new(cSize)
		cell.button:setOnClickScriptHandler(handler(self, self.TabButtonCallback))
		cell.button:setUserTag(v.rankTypes)
		--cell.nameLabel:setString(v.name)
		display.commonLabelParams(cell.nameLabel , { text = v.name , w =180 ,reqW = 150  , hAlign= display.TAC})
		-- 判断是否被选中
		if self.selectedRank == v.rankTypes then
			cell.button:setNormalImage(_res('ui/home/rank/rank_btn_tab_select.png'))
			cell.button:setSelectedImage(_res('ui/home/rank/rank_btn_tab_select.png'))
			if v.child then
				self.selectedRank = v.child[1].rankTypes
			end
		end
		-- 判断是否有子页签
		if v.child then
			cell.arrowIcon:setVisible(true)
			-- 判断子页签是否被选中
			for _, child in ipairs(v.child) do
				if child.rankTypes == self.selectedRank then
					cell.arrowIcon:setRotation(0)
					cell.button:setNormalImage(_res('ui/home/rank/rank_btn_tab_select.png'))
					cell.button:setSelectedImage(_res('ui/home/rank/rank_btn_tab_select.png'))
					self:AddChildNode(cell, v.child)
				end
			end
		end
		viewData.listView:insertNodeAtLast(cell)
	end
	viewData.listView:reloadData()
	if self.showLayer[tostring(self.selectedRank)] then
		self.showLayer[tostring(self.selectedRank)]:setVisible(true)
		if 0 >= table.nums(self.rankDatas[tostring(self.selectedRank)].rankList) then
			viewData.emptyView:setVisible(true)
		else
			viewData.emptyView:setVisible(false)
		end
	else
		self:RefreshRankingList(self.selectedRank)
	end

end
--[[
添加子页签
--]]
function RankingListMediator:AddChildNode( cell, childData )
	local size = cell:getContentSize()
	cell:setContentSize(cc.size(size.width, size.height + 87 * #childData))
	cell.buttonLayout:setPosition(cc.p(size.width/2, cell:getContentSize().height - 50))
	local layout = CLayout:create(cc.size(size.width, 20 + 87 * #childData))
	layout:setPosition(cc.p(size.width/2, -15))
	layout:setAnchorPoint(cc.p(0.5, 0))
	cell:addChild(layout, 5)
	cell.childNode = layout
	local bg = display.newImageView(_res('ui/home/rank/rank_tab_bg_2.png'), layout:getContentSize().width/2, layout:getContentSize().height/2, {scale9 = true, size = cc.size(180, layout:getContentSize().height), capInsets = cc.rect(5, 5, 170, 165)})
	layout:addChild(bg)
	-- 子页签按钮
	for i,v in ipairs(childData) do
		local img = nil
		if self.selectedRank == v.rankTypes then
			img = _res('ui/home/rank/rank_btn_2_select.png')
		else
			img = _res('ui/home/rank/rank_btn_2_default.png')
		end
		local button = display.newButton(layout:getContentSize().width/2, layout:getContentSize().height - 50 - 87 * (i-1), {n = img, scale9 = true, size = cc.size(155, 80)})
		layout:addChild(button, 10)
		button:setUserTag(v.rankTypes)
		button:setOnClickScriptHandler(handler(self, self.TabButtonCallback))
		if isJapanSdk() then
			local nameLabel = display.newLabel(	button:getContentSize().width/2, button:getContentSize().height/2, {text = v.name, fontSize = 24, color = '#ffffff',ttf = true, font = TTF_GAME_FONT, reqW = 140 , outline = '#734441'})
			nameLabel:setAlignment(cc.TEXT_ALIGNMENT_CENTER)
			button:addChild(nameLabel)
		else
			local nameLabel = display.newLabel(	button:getContentSize().width/2, button:getContentSize().height/2, {text = v.name, fontSize = 24, color = '#ffffff',ttf = true, font = TTF_GAME_FONT, w = 140,reqH = 70 , outline = '#734441'})
			nameLabel:setAlignment(cc.TEXT_ALIGNMENT_CENTER)
			button:addChild(nameLabel)
		end
	end
end
--[[
刷新排行榜页面
@params int rankTypes 排行榜类型
--]]
function RankingListMediator:RefreshRankingList( rankTypes )
	if checkint(rankTypes) == RankTypes.RESTAURANT_COMPREHENSIVENESS then
		-- 餐厅知名度排行榜
		local temp = {
			showLeftTime = true,
			showUpdateInterval = true,
			showLastRank = true,
			rewardsDatas = CommonUtils.GetConfigAllMess('popularityRankReward', 'restaurant'),
			rankType = rankTypes,
			rankDataSource = self.PopularityRankDataSource,
			showRewardTips = true,
			largeScoreBg = true,
			rewardTips = __('奖励发放时间：每周一 02:00'),
			iconPath = _res('ui/common/common_ico_fame.png'),
		}
		self:InitRankView(temp)
	elseif checkint(rankTypes) == RankTypes.RESTAURANT_REVENUE then
		-- 餐厅营收排行榜
		local temp = {
			showLeftTime = true,
			showUpdateInterval = true, 
			showLastRank = true,
			rewardsDatas = CommonUtils.GetConfigAllMess('goldRankReward', 'restaurant'),  
			rankType = rankTypes,
			rankDataSource = self.GoldRankDataSource, 
			showRewardTips = true,
			largeScoreBg = true,
			rewardTips = __('奖励发放时间：每周一 02:00'),
			iconPath = CommonUtils.GetGoodsIconPathById(GOLD_ID),			
		}
		self:InitRankView(temp)
	elseif checkint(rankTypes) == RankTypes.TOWER_WEEKLY then
		-- 爬塔排行榜
		local temp = {
			showLeftTime = true,
			showLastRank = true,
			rewardsDatas = CommonUtils.GetConfigAllMess('towerRankReward', 'tower'),
			rankType = rankTypes,
			rankDataSource = self.TowerRankDataSource,
			showRewardTips = true,
			largeScoreBg = isJapanSdk(),
			rewardTips = __('奖励发放时间：每周一 02:00'),
			iconStr = __('层'),
		}
		self:InitRankView(temp)
	elseif checkint(rankTypes) == RankTypes.TOWER_HISTORY then
		-- 爬塔历史排行榜
		local temp = {
			rankType = rankTypes,
			largeScoreBg = isJapanSdk(),
			iconStr = __('层'),
			rankDataSource = self.TowerRankDataSource,
		}
		self:InitRankView(temp)
	elseif checkint(rankTypes) == RankTypes.PVC_WEEKLY then
		-- 皇家试炼
		local temp = {
			showLeftTime = true,
			showLastRank = true,
			rewardsDatas = CommonUtils.GetConfigAllMess('rankReward', 'arena'),
			rankType = rankTypes,
			rankDataSource = self.PVCRankDataSource,
			showRewardTips = true,
			rewardTips = __('奖励发放时间：每周一 02:00'),
			iconPath = _res('ui/pvc/pvp_ico_point.png')
		}
		self:InitRankView(temp)
	elseif checkint(rankTypes) == RankTypes.AIRSHIP then
		-- 空艇
		local temp = {
			showLeftTime = true,
			showLastRank = true,
			rewardsDatas = CommonUtils.GetConfigAllMess('rankReward', 'airship'),
			rankType = rankTypes,
			rankDataSource = self.AirshipRankDataSource,
			showRewardTips = true,
			rewardTips = __('奖励发放时间：每周一 00:00'),
			iconPath = _res('ui/common/ship_order_ico_point.png')
		}
		self:InitRankView(temp)
	elseif checkint(rankTypes) == RankTypes.UNION_CONTRIBUTIONPOINT then
		-- 工会贡献周榜

		local temp = {
			showLeftTime = true,
			showLastRank = true,
			rankType = rankTypes,
			rankDataSource = self.UnionContributionRankDataSource,
			iconPath = _res('ui/union/guild_ico_CTBpoint.png'),
			largeScoreBg = true,
			showUnionName = true,	
		}
		if not gameMgr:IsJoinUnion() then
			temp.hideMyScore = true
		end
		self:InitRankView(temp)
	elseif checkint(rankTypes) == RankTypes.UNION_WARS then
		-- 工会竞赛排行榜
		local temp = {
			showLeftTime = true,
			showLastRank = true,
			rankType = rankTypes,
			rankDataSource = self.UnionWarsRankDataSource, 
			iconPath = _res('ui/union/guild_ico_CTBpoint.png'),
			largeScoreBg = true,
			showUnionName = true,	
		}
		if not gameMgr:IsJoinUnion() then
			temp.hideMyScore = true
		end
		self:InitRankView(temp)
	elseif checkint(rankTypes) == RankTypes.UNION_WARS then
		-- 工会竞赛排行榜
		local temp = {
			showLeftTime = true,
			showLastRank = true,
			rankType = rankTypes,
			rankDataSource = self.UnionWarsRankDataSource,
			iconPath = _res('ui/union/guild_ico_CTBpoint.png'),
			largeScoreBg = true,
			showUnionName = true,
		}
		if not gameMgr:IsJoinUnion() then
			temp.hideMyScore = true
		end
		self:InitRankView(temp)
	elseif checkint(rankTypes) == RankTypes.UNION_CONTRIBUTIONPOINT_HISTORY then
		-- 工会贡献总榜
		local temp = {
			rankType = rankTypes,
			rankDataSource = self.UnionContributionRankDataSource,
			iconPath = _res('ui/union/guild_ico_CTBpoint.png'),
			largeScoreBg = true,
			showUnionName = true	
		}
		if not gameMgr:IsJoinUnion() then
			temp.hideMyScore = true
		end
		self:InitRankView(temp)
	elseif checkint(rankTypes) == RankTypes.UNION_GODBEAST then
		-- 工会神兽排行榜
		local temp = {
			rankType = rankTypes,
			rankDataSource = self.UnionGodBeastRankDataSource,
			showUnionName = true
		}
		if not gameMgr:IsJoinUnion() then
			temp.hideMyScore = true
		end
		self:InitRankView(temp)
	elseif checkint(rankTypes) == RankTypes.BOSS_UNION then
		-- 世界BOSS工会排行榜
		local temp = {
			showLeftTime = true,
			showLastRank = true,
			largeScoreBg = true,
			lastRankName = __('昨日排行榜'),
			rewardViewTitle	= __('每日排行榜奖励'),
			rewardsDatas = CommonUtils.GetConfigAllMess('unionRewards', 'worldBossQuest'),
			rankType = rankTypes,
			rankDataSource = self.BossUnionRankDataSource,
			showUnionName = true
			-- showRewardTips = true,
		}
		if not gameMgr:IsJoinUnion() then
			temp.hideMyScore = true
		end
		self:InitRankView(temp)
	elseif checkint(rankTypes) == RankTypes.BOSS_UNION then
		-- 世界BOSS工会排行榜
		local temp = {
			showLeftTime = true,
			showLastRank = true,
			largeScoreBg = true, 
			lastRankName = __('昨日排行榜'),
			rewardViewTitle	= __('每日排行榜奖励'),
			rewardsDatas = CommonUtils.GetConfigAllMess('unionRewards', 'worldBossQuest'),  
			rankType = rankTypes,
			rankDataSource = self.BossUnionRankDataSource, 
			showUnionName = true
			-- showRewardTips = true,
		}
		if not gameMgr:IsJoinUnion() then
			temp.hideMyScore = true
		end
		self:InitRankView(temp)
	elseif checkint(rankTypes) == RankTypes.BOSS_PERSON then
		-- 世界BOSS个人排行榜
		local temp = {
			showLeftTime = true,
			showLastRank = true,
			largeScoreBg = true, 
			lastRankName = __('昨日排行榜'),
			rewardViewTitle	= __('每日排行榜奖励'),
			rewardsDatas = CommonUtils.GetConfigAllMess('personalRewards', 'worldBossQuest'),  
			rankType = rankTypes,
			rankDataSource = self.BossPersonalRankDataSource, 
			-- showRewardTips = true,
		}
		self:InitRankView(temp)
	end
end
--[[
初始化排行榜页面
@params datas {
	showLeftTime       bool     是否显示剩余时间
	showUpdateInterval bool     是否显示更新间隔
	showLastRank       bool     是否显示上周排行榜
	lastRankName       string   上周排行榜名称
	rewardsDatas       string   奖励
	rankType           int      排行榜类型
	rankDataSource     function 列表处理方法
	showRewardTips     bool     查看奖励页面是否显示tips
	rewardTips         string   查看奖励页面提示文字
	rewardViewTitle    string   查看奖励页面名称
	iconPath           string   分数icon路径
	iconStr            string   分数文字展示
	largeScoreBg       bool     放大分数背景
	hideMyScore        bool     是否隐藏自己的排行
	showUnionName      bool     是否展示工会名称
}
--]]
function RankingListMediator:InitRankView( datas )
	local viewData = self:GetViewComponent().viewData
	local rankDatas = self.rankDatas[tostring(datas.rankType)] or {}
	local size = cc.size(1035, 637)
	local layout = CLayout:create(size)
	self.showLayer[tostring(datas.rankType)] = layout
	layout:setPosition(cc.p(utils.getLocalCenter(viewData.rankLayout)))
	layout:setTag(datas.rankType)
	viewData.rankLayout:addChild(layout, 10)
	local endLabel = nil
	local timeLabel = nil
	local timeNum = nil
	if datas.showLeftTime then -- 剩余时间
		endLabel = display.newLabel(28, 585, fontWithColor(16, {text = __('本赛季剩余时间：'), ap = cc.p(0, 0.5)}))
		layout:addChild(endLabel, 10)
		timeNum = cc.Label:createWithBMFont('font/common_num_1.fnt', '')
		timeNum:setHorizontalAlignment(display.TAR)
		timeNum:setPosition(display.getLabelContentSize(endLabel).width + 33, 590)
		timeNum:setAnchorPoint(cc.p(0, 0.5))
		timeNum:setScale(1.2)
		local str, showLabel = self:ChangeTimeFormat(checkint(rankDatas.leftSeconds))
		timeNum:setString(str)
		layout:addChild(timeNum, 10)

		timeLabel = display.newLabel(display.getLabelContentSize(endLabel).width + 38 + timeNum:getContentSize().width*1.2, 585, fontWithColor(16, {ap = cc.p(0, 0.5), text = __('天')}))
		layout:addChild(timeLabel, 10)
		if showLabel then
			timeLabel:setVisible(true)
		else
			timeLabel:setVisible(false)
		end
		if datas.showUpdateInterval then -- 更新间隔
			local tipsLabel = display.newLabel(28, 565, fontWithColor(6, {text = __('排行榜每小时更新一次排名'), ap = cc.p(0, 0.5)}))
			layout:addChild(tipsLabel, 10)
			local  devY = 15
			endLabel:setPositionY(endLabel:getPositionY() + devY)
			timeNum:setPositionY(timeNum:getPositionY() + devY)
			timeLabel:setPositionY(timeLabel:getPositionY() + devY)
		end
	end

	-- 查看奖励
	if datas.rewardsDatas then
		local rewardBtn = display.newButton(955, 585, {tag = 1002, n = _res('ui/common/common_btn_orange.png')})
		layout:addChild(rewardBtn, 10)
		rewardBtn:setOnClickScriptHandler(function (sender)
			local scene = uiMgr:GetCurrentScene()
			local LobbyRewardListView  = require( 'Game.views.LobbyRewardListView' ).new({tag = 1200, mediatorName = "RankingListMediator", showTips = datas.showRewardTips, msg = datas.rewardTips, rewardsDatas = datas.rewardsDatas, title = datas.rewardViewTitle})
			LobbyRewardListView:setTag(1200)
			LobbyRewardListView:setPosition(display.center)
			scene:AddDialog(LobbyRewardListView)
		end)
		display.commonLabelParams(rewardBtn, {fontSize = 20, color = 'ffffff', font = TTF_GAME_FONT, ttf = true, outline = '734441', text = __('查看奖励')})
    end
	-- 上周排行榜
	if datas.showLastRank then
		local lastWeekRankBtn = display.newButton(810, 585, {tag = 1001, n = _res('ui/common/common_btn_white_default.png')})
		layout:addChild(lastWeekRankBtn, 10)
		lastWeekRankBtn:setOnClickScriptHandler(function (sender)
			local scene = uiMgr:GetCurrentScene()
			local LobbyLastRankingView  = require( 'Game.views.LobbyLastRankingView' ).new({tag = 1100, mediatorName = "RankingListMediator", lastRank = checktable(rankDatas.lastRank), iconPath = datas.iconPath, iconStr = datas.iconStr, title = datas.lastRankName})
			LobbyLastRankingView:setTag(1100)
			LobbyLastRankingView:setPosition(display.center)
			scene:AddDialog(LobbyLastRankingView)
		end)
		display.commonLabelParams(lastWeekRankBtn, {fontSize = 20, color = 'ffffff', font = TTF_GAME_FONT, ttf = true, outline = '734441', text = datas.lastRankName or __('上周排行榜') , reqW = 110})
		-- 判断是否向右偏移
		if not datas.rewardsDatas then
			lastWeekRankBtn:setPositionX(lastWeekRankBtn:getPositionX() + 145)
		end
	end
    -- 列表
    local gridViewSize = cc.size(size.width, 486)
    if datas.hideMyScore then
    	gridViewSize = cc.size(size.width, 538)
    end
    local gridViewCellSize = cc.size(size.width, 112)
    local gridView = CGridView:create(gridViewSize)
    gridView:setSizeOfCell(gridViewCellSize)
    gridView:setAnchorPoint(cc.p(0.5, 1))
    gridView:setColumns(1)
    -- gridView:setAutoRelocate(true)
    layout:addChild(gridView, 10)
    gridView:setPosition(cc.p(size.width/2, 544))
	gridView:setDataSourceAdapterScriptHandler(handler(self, datas.rankDataSource))
	gridView:setCountOfCell(table.nums(checktable(rankDatas.rankList)))
	gridView:reloadData()
	if 0 >= table.nums(rankDatas.rankList) then
		viewData.emptyView:setVisible(true)
	else
		viewData.emptyView:setVisible(false)
	end
	-- 更新自己的排名
	if not datas.hideMyScore then -- 是否隐藏自己的排名
        local myRankBg = display.newImageView(_res('ui/home/rank/restaurant_info_bg_rank_mine.png'), size.width/2, 35)
		layout:addChild(myRankBg, 1)
		local playerName = nil
		if isJapanSdk() then
			playerName = display.newLabel(144 + 16, 35, {ap = cc.p(0, 0.5), text = gameMgr:GetUserInfo().playerName, fontSize = 22, color = '#a87543'})
		else
			playerName = display.newLabel(340, 35, {ap = cc.p(0, 0.5), text = gameMgr:GetUserInfo().playerName, fontSize = 22, reqW = 170, color = '#a87543'})
		end
		layout:addChild(playerName, 10)
		-- 是否显示为工会名称
		if datas.showUnionName and unionMgr:getUnionData() then
			playerName:setString(tostring(unionMgr:getUnionData().name))
		end
		if datas.largeScoreBg then
			local scoreBg = display.newImageView(_res('ui/home/lobby/information/restaurant_info_bg_rank_awareness.png'), 880, 35, {scale9 = true, size = cc.size(260, 31)})
			layout:addChild(scoreBg, 5)
		else
			local scoreBg = display.newImageView(_res('ui/home/lobby/information/restaurant_info_bg_rank_awareness.png'), 940, 35)
			layout:addChild(scoreBg, 5)
		end
		if datas.iconPath then
			local scoreIcon = display.newImageView(datas.iconPath, 950, 37)
			layout:addChild(scoreIcon, 10)
			scoreIcon:setScale(0.25)
		end
		local iconLabel = nil
		if datas.iconStr then
			if isJapanSdk() then
				iconLabel = display.newLabel(1004, 35, fontWithColor(14, {ap = display.RIGHT_CENTER, text = datas.iconStr}))
			else
				iconLabel = display.newLabel(954, 35, fontWithColor(14, {ap = display.LEFT_CENTER, text = __('层')}))
			end
			layout:addChild(iconLabel, 10)
		end
		local scoreNum = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '0')
		scoreNum:setHorizontalAlignment(display.TAR)
		scoreNum:setPosition(920, 35)
		scoreNum:setAnchorPoint(cc.p(1, 0.5))
		layout:addChild(scoreNum, 10)
		if (not rankDatas.myRank and not rankDatas.myScore) or
			0 == checkint(rankDatas.myRank) then
			if isJapanSdk() then
				local playerRankLabel = display.newLabel(88, 35, {text = __('未入榜'), fontSize = 22, color = '#ba5c5c'})
				layout:addChild(playerRankLabel, 10)
			else
				local playerRankLabel = display.newLabel(110, 35, {text = __('未入榜'),  fontSize = 22, reqW = 140 ,  color = '#ba5c5c'})
				layout:addChild(playerRankLabel, 10)
			end
		else
			if checkint(rankDatas.myRank) >= 1 and checkint(rankDatas.myRank) <= 3 then
				local rankBg = display.newImageView('ui/home/rank/restaurant_info_bg_rank_num' .. tostring(rankDatas.myRank) ..'.png', 88, 35)
   				layout:addChild(rankBg, 5)
   				rankBg:setScale(0.7)
			end
			local playerRankNum = cc.Label:createWithBMFont('font/small/common_text_num.fnt', tostring(rankDatas.myRank))
			playerRankNum:setHorizontalAlignment(display.TAR)
			playerRankNum:setPosition(86, 34)
			layout:addChild(playerRankNum, 10)
		end

		if not datas.iconPath and not datas.iconStr then
			scoreNum:setPositionX(scoreNum:getPositionX() + 30)
		end
		scoreNum:setString(tostring(checkint(rankDatas.myScore)))
		if datas.iconStr then
			scoreNum:setPositionX(iconLabel:getPositionX() - display.getLabelContentSize(iconLabel).width - 4)
		end
	end
	self.rankLayerDatas[tostring(datas.rankType)] = {
		timeLabel = timeLabel,
		timeNum   = timeNum,
		endLabel  = endLabel
	}
	return layout
end
--[[
改变时间格式
@params seconds int 剩余秒数
--]]
function RankingListMediator:ChangeTimeFormat( seconds )
	local time = nil
	local showDays = nil
	if seconds >= 86400 then
		time = math.floor(seconds/86400)
		showDays = true
	else
		local hour   = math.floor(seconds / 3600)
		local minute = math.floor((seconds - hour*3600) / 60)
		local sec    = (seconds - hour*3600 - minute*60)
		time = string.format("%.2d:%.2d:%.2d", hour, minute, sec)
		showDays = false
	end
	return time, showDays
end
--[[
左侧页签点击回调
--]]
function RankingListMediator:TabButtonCallback( sender )
    if tolua.type(sender) == 'ccw.CButton' then
        PlayAudioByClickNormal()
    end
	local rankTypes = nil
	if type(sender) == 'number' then
		rankTypes = sender
	else
		rankTypes = sender:getUserTag()
		if rankTypes == self.selectedRank then return end
		if self.showLayer[tostring(self.selectedRank)] then
			self.showLayer[tostring(self.selectedRank)]:setVisible(false)
		end
	end

	-- 判断此页签有没有子页签
	for i, v in ipairs(RANK) do
		if v.rankTypes == rankTypes then
			if v.child then
				rankTypes = v.child[1].rankTypes
			end
		end
	end
	self.selectedRank = rankTypes
	if self.rankDatas[tostring(self.selectedRank)] then
		self:refreshUi()
	else
		if self.selectedRank == RankTypes.RESTAURANT_COMPREHENSIVENESS then
			self:SendSignal(COMMANDS.COMMAND_Rank_Restaurant)
		elseif self.selectedRank == RankTypes.RESTAURANT_REVENUE then
			self:SendSignal(COMMANDS.COMMAND_Rank_RestaurantRevenue)
		elseif self.selectedRank == RankTypes.TOWER_WEEKLY then
			self:SendSignal(COMMANDS.COMMAND_Rank_Tower)
		elseif self.selectedRank == RankTypes.TOWER_HISTORY then
			self:SendSignal(COMMANDS.COMMAND_Rank_TowerHistory)
		elseif self.selectedRank == RankTypes.PVC_WEEKLY then
			self:SendSignal(COMMANDS.COMMAND_Rank_ArenaRank)
		elseif self.selectedRank == RankTypes.AIRSHIP then
			self:SendSignal(COMMANDS.COMMAND_Rank_Airship)
		elseif self.selectedRank == RankTypes.UNION_CONTRIBUTIONPOINT then
			self:SendSignal(COMMANDS.COMMAND_Rank_Union_Contribution)
		elseif self.selectedRank == RankTypes.UNION_WARS then
			self:SendSignal(POST.RANK_UNION_WARS.cmdName)
		elseif self.selectedRank == RankTypes.UNION_CONTRIBUTIONPOINT_HISTORY then
			self:SendSignal(COMMANDS.COMMAND_Rank_Union_ContributionHistory)
		elseif self.selectedRank == RankTypes.UNION_GODBEAST then
			self:SendSignal(COMMANDS.COMMAND_Rank_Union_GodBeast)
		elseif self.selectedRank == RankTypes.BOSS_UNION then
			self:SendSignal(COMMANDS.COMMAND_Rank_BOSS_Union)
		elseif self.selectedRank == RankTypes.BOSS_PERSON then
			self:SendSignal(COMMANDS.COMMAND_Rank_BOSS_Person)
		end
	end
end
--[[
定时器回调
--]]
function RankingListMediator:LeftScheduleCallback()
	for k, v in pairs(self.rankDatas) do
		if v.leftSeconds then
			local layer = self.showLayer[tostring(k)]

			local rankLayerDatas = self.rankLayerDatas[k]
			if checkint(v.leftSeconds) > 0 then
				self.rankDatas[tostring(k)].leftSeconds = checkint(v.leftSeconds) - 1
				if layer and rankLayerDatas then
					local str, showLabel = self:ChangeTimeFormat(v.leftSeconds)
					rankLayerDatas.timeNum:setString(str)
					if showLabel then
						rankLayerDatas.timeLabel:setVisible(true)
						rankLayerDatas.timeLabel:setPositionX(display.getLabelContentSize(rankLayerDatas.endLabel).width + 38 + rankLayerDatas.timeNum:getContentSize().width*1.2)
					else
						rankLayerDatas.timeLabel:setVisible(false)
					end
				end
			else
				if layer then
					layer:removeFromParent()
					self.rankDatas[tostring(k)] = nil
					self.showLayer[tostring(k)] = nil
				end
				if checkint(self.selectedRank) == checkint(k) then
					self:TabButtonCallback(self.selectedRank)
				end
			end
		end
	end
end

function RankingListMediator:PopularityRankDataSource( p_convertview, idx )
	local pCell = p_convertview
    local index = idx + 1
    local cSize = cc.size(1035, 112)

    if pCell == nil then
        pCell = RankPopularityCell.new(cSize)
    end
	xTry(function()
		local datas = self.rankDatas[tostring(RankTypes.RESTAURANT_COMPREHENSIVENESS)].popularityRank[index]
		pCell.rankNum:setString(datas.rank)
		pCell.avatarIcon:RefreshSelf({level = datas.playerLevel, avatar = datas.playerAvatar, avatarFrame = datas.playerAvatarFrame})
		pCell.nameLabel:setString(datas.playerName)
		pCell.scoreNum:setString(datas.popularity)
		pCell.avatarIcon:setTag(index)
		pCell.avatarIcon:setOnClickScriptHandler(function ( sender )
			local tag = sender:getTag()
			uiMgr:AddDialog('common.PlayerHeadPopup', {playerId = datas.playerId, type = CommonUtils.GetHeadPopupTypeByPlayerId(datas.playerId)})
		end)
		if pCell.scoreNum:getContentSize().width >= 200 then
			local scale = 200/pCell.scoreNum:getContentSize().width
			pCell.scoreNum:setScale(scale)
		end
		if checkint(datas.rank) >= 1 and checkint(datas.rank) <= 3 then
			pCell.rankBg:setVisible(true)
			pCell.rankBg:setTexture(_res('ui/home/rank/restaurant_info_bg_rank_num' .. tostring(datas.rank) .. '.png'))
		else
			pCell.rankBg:setVisible(false)
		end

	end,__G__TRACKBACK__)
    return pCell
end
--------------------------------------------
----------------餐厅营收排行榜----------------
function RankingListMediator:GoldRankDataSource( p_convertview, idx )
	local pCell = p_convertview
    local index = idx + 1
    local cSize = cc.size(1035, 112)

    if pCell == nil then
        pCell = RankPopularityCell.new(cSize)
    end
	xTry(function()
		local datas = self.rankDatas[tostring(RankTypes.RESTAURANT_REVENUE)].goldRank[index]
		pCell.scoreIcon:setTexture(CommonUtils.GetGoodsIconPathById(GOLD_ID))
		pCell.rankNum:setString(datas.rank)
		pCell.avatarIcon:RefreshSelf({level = datas.playerLevel, avatar = datas.playerAvatar, avatarFrame = datas.playerAvatarFrame})
		pCell.nameLabel:setString(datas.playerName)
		pCell.scoreNum:setString(datas.gold)
		pCell.avatarIcon:setTag(index)
		pCell.avatarIcon:setOnClickScriptHandler(function ( sender )
			local tag = sender:getTag()
			uiMgr:AddDialog('common.PlayerHeadPopup', {playerId = datas.playerId, type = CommonUtils.GetHeadPopupTypeByPlayerId(datas.playerId)})
		end)
		if pCell.scoreNum:getContentSize().width >= 200 then
			local scale = 200/pCell.scoreNum:getContentSize().width
			pCell.scoreNum:setScale(scale)
		end
		if checkint(datas.rank) >= 1 and checkint(datas.rank) <= 3 then
			pCell.rankBg:setVisible(true)
			pCell.rankBg:setTexture(_res('ui/home/rank/restaurant_info_bg_rank_num' .. tostring(datas.rank) .. '.png'))
		else
			pCell.rankBg:setVisible(false)
		end

	end,__G__TRACKBACK__)
    return pCell
end
----------------餐厅营收排行榜----------------
--------------------------------------------

--------------------------------------------
------------------爬塔排行榜-----------------
function RankingListMediator:TowerRankDataSource( p_convertview, idx )
	local pCell = p_convertview
    local index = idx + 1
    local cSize = cc.size(1035, 112)

    if pCell == nil then
        pCell = RankTowerCell.new(cSize)
    else

    end
	xTry(function()
		local datas = checktable(checktable(self.rankDatas[tostring(self.selectedRank)]).rankList)[index] or {}
		pCell.rankNum:setString(datas.rank)
		pCell.avatarIcon:RefreshSelf({level = datas.playerLevel, avatar = datas.playerAvatar, avatarFrame = datas.playerAvatarFrame})
		pCell.nameLabel:setString(datas.playerName)
		pCell.scoreNum:setString(datas.maxTowerFloor)
		pCell.avatarIcon:setTag(index)
		pCell.avatarIcon:setOnClickScriptHandler(function ( sender )
			local tag = sender:getTag()
			uiMgr:AddDialog('common.PlayerHeadPopup', {playerId = datas.playerId, type = CommonUtils.GetHeadPopupTypeByPlayerId(datas.playerId)})
		end)

		if pCell.scoreNum:getContentSize().width >= 90 then
			local scale = 90/pCell.scoreNum:getContentSize().width
			pCell.scoreNum:setScale(scale)
		end

		if checkint(datas.rank) >= 1 and checkint(datas.rank) <= 3 then
			pCell.rankBg:setVisible(true)
			pCell.rankBg:setTexture(_res('ui/home/rank/restaurant_info_bg_rank_num' .. tostring(datas.rank) .. '.png'))
		else
			pCell.rankBg:setVisible(false)
		end

	end,__G__TRACKBACK__)
    return pCell
end
------------------爬塔排行榜-----------------
--------------------------------------------

--------------------------------------------
------------------皇家试炼排行榜-----------------
function RankingListMediator:PVCRankDataSource(c, i)
	local pCell = c
	local index = i + 1
	local cSize = cc.size(1035, 112)

	if nil == pCell then
		pCell = RankPVCCell.new(cSize)
	else

	end
	xTry(function()
		local datas = self.rankDatas[tostring(RankTypes.PVC_WEEKLY)].arenaRank[index]
		pCell.avatarIcon:RefreshSelf({level = datas.playerLevel, avatar = datas.playerAvatar, avatarFrame = datas.playerAvatarFrame})
		pCell.rankNum:setString(datas.rank)
		pCell.nameLabel:setString(datas.playerName)
		pCell.scoreNum:setString(datas.integral)
		pCell.avatarIcon:setTag(index)
		pCell.avatarIcon:setOnClickScriptHandler(function ( sender )
			local tag = sender:getTag()
			uiMgr:AddDialog('common.PlayerHeadPopup', {playerId = datas.playerId, type = CommonUtils.GetHeadPopupTypeByPlayerId(datas.playerId)})
		end)
		local cardIndex = 0
		for i,v in ipairs(pCell.cardTable) do
			local cardDatas = nil
			for i = cardIndex+1, 5, 1 do
				cardDatas = datas.fightTeam[i]
				if cardDatas and next(cardDatas) ~= nil then
					cardIndex = i
					break
				end
			end
			if cardDatas and next(cardDatas) ~= nil then
				v:setVisible(true)
				v:RefreshUI({
					cardData = {
						cardId = cardDatas.cardId,
						level = cardDatas.level,
						breakLevel = cardDatas.breakLevel,
						defaultSkinId = cardDatas.defaultSkinId,
						favorabilityLevel = cardDatas.favorabilityLevel,
					},
					showBaseState = true,
					showActionState = false,
					showVigourState = false
				})
			else
				v:setVisible(false)
			end
		end
		if pCell.scoreNum:getContentSize().width >= 90 then
			local scale = 90/pCell.scoreNum:getContentSize().width
			pCell.scoreNum:setScale(scale)
		end

		if datas.rank >= 1 and datas.rank <= 3 then
			pCell.rankBg:setVisible(true)
			pCell.rankBg:setTexture(_res('ui/home/rank/restaurant_info_bg_rank_num' .. tostring(datas.rank) .. '.png'))
		else
			pCell.rankBg:setVisible(false)
		end
	end,__G__TRACKBACK__)

	pCell:setTag(index)

	return pCell
end
------------------皇家试炼排行榜-----------------
--------------------------------------------

--------------------------------------------
------------------飞艇排行榜-----------------
function RankingListMediator:AirshipRankDataSource(c, i)
	local pCell = c
	local index = i + 1
	local cSize = cc.size(1035, 112)

	if nil == pCell then
		pCell = RankPopularityCell.new(cSize)
	else

	end
	xTry(function()
		local datas = checktable(checktable(self.rankDatas[tostring(self.selectedRank)]).rankList)[index] or {}
		pCell.scoreIcon:setTexture(_res('ui/common/ship_order_ico_point.png'))
		pCell.scoreBg:setContentSize(cc.size(153, 98))
		pCell.scoreBg:setPositionX(940)
		pCell.rankNum:setString(datas.rank)
		pCell.nameLabel:setString(datas.playerName)
		pCell.scoreNum:setString(datas.airshipPoint)
		pCell.avatarIcon:RefreshSelf({level = datas.playerLevel, avatar = datas.playerAvatar, avatarFrame = datas.playerAvatarFrame})
		pCell.avatarIcon:setTag(index)
		pCell.avatarIcon:setOnClickScriptHandler(function ( sender )
			local tag = sender:getTag()
			uiMgr:AddDialog('common.PlayerHeadPopup', {playerId = datas.playerId, type = CommonUtils.GetHeadPopupTypeByPlayerId(datas.playerId)})
		end)
		if pCell.scoreNum:getContentSize().width >= 90 then
			local scale = 90/pCell.scoreNum:getContentSize().width
			pCell.scoreNum:setScale(scale)
		end

		if checkint(datas.rank) >= 1 and checkint(datas.rank) <= 3 then
			pCell.rankBg:setVisible(true)
			pCell.rankBg:setTexture(_res('ui/home/rank/restaurant_info_bg_rank_num' .. tostring(datas.rank) .. '.png'))
		else
			pCell.rankBg:setVisible(false)
		end

	end,__G__TRACKBACK__)

	pCell:setTag(index)
	return pCell
end
------------------飞艇排行榜-----------------
--------------------------------------------

--------------------------------------------
------------------工会排行榜-----------------
--[[
工会贡献度排行榜列表处理
--]]
function RankingListMediator:UnionContributionRankDataSource( p_convertview, idx )
	local pCell = p_convertview
    local index = idx + 1
    local cSize = cc.size(1035, 112)

    if pCell == nil then
        pCell = RankUnionContributionCell.new(cSize)
    end
	xTry(function()
		local datas = checktable(checktable(self.rankDatas[tostring(self.selectedRank)]).rankList)[index] or {}
		pCell.rankNum:setString(datas.rank)
		pCell.nameLabel:setString(datas.unionName)
		pCell.levelLabel:setString(string.fmt(__('_num_级'), {['_num_'] = datas.unionLevel}))
		pCell.scoreNum:setString(datas.contributionPoint)
		pCell.headImage:setTexture(CommonUtils.GetGoodsIconPathById(datas.unionAvatar))
		pCell.memberLabel:setString(string.format('%d/%d', checkint(datas.unionMemberNumber), checkint(unionMgr:GetUnionMemberLimitNumByLevel(datas.unionLevel))))
		if pCell.scoreNum:getContentSize().width >= 200 then
			local scale = 200/pCell.scoreNum:getContentSize().width
			pCell.scoreNum:setScale(scale)
		end

		if checkint(datas.rank) >= 1 and checkint(datas.rank) <= 3 then
			pCell.rankBg:setVisible(true)
			pCell.rankBg:setTexture(_res('ui/home/rank/restaurant_info_bg_rank_num' .. tostring(datas.rank) .. '.png'))
		else
			pCell.rankBg:setVisible(false)
		end

	end,__G__TRACKBACK__)
    return pCell
end
--[[
工会竞赛排行榜列表处理
--]]
function RankingListMediator:UnionWarsRankDataSource( p_convertview, idx )
	local pCell = p_convertview
    local index = idx + 1
    local cSize = cc.size(1035, 112)

    if pCell == nil then
		pCell = RankUnionWarsCell.new(cSize)
    end
	xTry(function()
		local datas = checktable(checktable(self.rankDatas[tostring(self.selectedRank)]).rankList)[index] or {}
		pCell.rankNum:setString(datas.rank)
		pCell.nameLabel:setString(datas.unionName)
		pCell.levelLabel:setString(string.fmt(__('_num_级'), {['_num_'] = datas.unionLevel}))
		pCell.scoreNum:setString(datas.unionWarsPoint)
		pCell.headImage:setTexture(CommonUtils.GetGoodsIconPathById(datas.unionAvatar))
		display.commonLabelParams(pCell.attackSuccessTimesLabel, {text = tostring(datas.attackSuccessTimes)})
		display.commonLabelParams(pCell.defendSuccessTimesLabel, {text = tostring(datas.defendSuccessTimes)})
		if pCell.scoreNum:getContentSize().width >= 200 then
			local scale = 200/pCell.scoreNum:getContentSize().width
			pCell.scoreNum:setScale(scale)
		end

		if checkint(datas.rank) >= 1 and checkint(datas.rank) <= 3 then
			pCell.rankBg:setVisible(true)
			pCell.rankBg:setTexture(_res('ui/home/rank/restaurant_info_bg_rank_num' .. tostring(datas.rank) .. '.png'))
		else
			pCell.rankBg:setVisible(false)
		end

	end,__G__TRACKBACK__)
    return pCell
end

--[[
工会神兽战力排行榜
--]]
function RankingListMediator:UnionGodBeastRankDataSource( p_convertview, idx )
	local pCell = p_convertview
    local index = idx + 1
    local cSize = cc.size(1035, 112)

    if pCell == nil then
        pCell = RankUnionGodBeastCell.new(cSize)
    end
	xTry(function()
		local datas = checktable(checktable(self.rankDatas[tostring(self.selectedRank)]).rankList)[index] or {}
		pCell.rankNum:setString(datas.rank)
		pCell.nameLabel:setString(datas.unionName)
		pCell.levelLabel:setString(string.fmt(__('_num_级'), {['_num_'] = datas.unionLevel}))
		pCell.scoreNum:setString(checkint(datas.godBeastCombatValue))
		pCell.headImage:setTexture(CommonUtils.GetGoodsIconPathById(datas.unionAvatar))
		if pCell.scoreNum:getContentSize().width >= 90 then
			local scale = 90/pCell.scoreNum:getContentSize().width
			pCell.scoreNum:setScale(scale)
		end

		if checkint(datas.rank) >= 1 and checkint(datas.rank) <= 3 then
			pCell.rankBg:setVisible(true)
			pCell.rankBg:setTexture(_res('ui/home/rank/restaurant_info_bg_rank_num' .. tostring(datas.rank) .. '.png'))
		else
			pCell.rankBg:setVisible(false)
		end

	end,__G__TRACKBACK__)
    return pCell
end
------------------工会排行榜-----------------
--------------------------------------------

--------------------------------------------
----------------世界BOSS排行榜---------------
--[[
世界BOSS工会排行榜列表处理
--]]
function RankingListMediator:BossUnionRankDataSource( p_convertview, idx )
	local pCell = p_convertview
    local index = idx + 1
    local cSize = cc.size(1035, 112)

    if pCell == nil then
        pCell = RankUnionContributionCell.new(cSize)
    end
	xTry(function()
		local datas = checktable(checktable(self.rankDatas[tostring(self.selectedRank)]).rankList)[index] or {}
		pCell.rankNum:setString(datas.rank)
		pCell.nameLabel:setString(datas.unionName)
		pCell.levelLabel:setString(string.fmt(__('_num_级'), {['_num_'] = datas.unionLevel}))
		pCell.scoreNum:setString(datas.damage)
		pCell.scoreIcon:setVisible(false)
		pCell.scoreNum:setPositionX(1000)
		pCell.headImage:setTexture(CommonUtils.GetGoodsIconPathById(datas.unionAvatar))
		pCell.memberLabel:setString(string.format('%d/%d', checkint(datas.unionMemberNumber), checkint(unionMgr:GetUnionMemberLimitNumByLevel(datas.unionLevel))))
		if pCell.scoreNum:getContentSize().width >= 200 then
			local scale = 200/pCell.scoreNum:getContentSize().width
			pCell.scoreNum:setScale(scale)
		end

		if checkint(datas.rank) >= 1 and checkint(datas.rank) <= 3 then
			pCell.rankBg:setVisible(true)
			pCell.rankBg:setTexture(_res('ui/home/rank/restaurant_info_bg_rank_num' .. tostring(datas.rank) .. '.png'))
		else
			pCell.rankBg:setVisible(false)
		end

	end,__G__TRACKBACK__)
    return pCell
end
--[[
世界BOSS个人排行榜列表处理
--]]
function RankingListMediator:BossPersonalRankDataSource( p_convertview, idx )
	local pCell = p_convertview
    local index = idx + 1
    local cSize = cc.size(1035, 112)

    if pCell == nil then
        pCell = RankPopularityCell.new(cSize)
    end
	xTry(function()
		local datas = checktable(checktable(self.rankDatas[tostring(self.selectedRank)]).rankList)[index] or {}
		pCell.scoreIcon:setVisible(false)
		pCell.rankNum:setString(datas.rank)
		pCell.avatarIcon:RefreshSelf({level = datas.playerLevel, avatar = datas.playerAvatar, avatarFrame = datas.playerAvatarFrame})
		pCell.nameLabel:setString(datas.playerName)
		pCell.scoreNum:setString(datas.damage)
		pCell.scoreIcon:setVisible(false)
		pCell.scoreNum:setPositionX(1000)
		pCell.avatarIcon:setTag(index)
		pCell.avatarIcon:setOnClickScriptHandler(function ( sender )
			local tag = sender:getTag()
			uiMgr:AddDialog('common.PlayerHeadPopup', {playerId = datas.playerId, type = CommonUtils.GetHeadPopupTypeByPlayerId(datas.playerId)})
		end)
		if pCell.scoreNum:getContentSize().width >= 200 then
			local scale = 200/pCell.scoreNum:getContentSize().width
			pCell.scoreNum:setScale(scale)
		end
		if checkint(datas.rank) >= 1 and checkint(datas.rank) <= 3 then
			pCell.rankBg:setVisible(true)
			pCell.rankBg:setTexture(_res('ui/home/rank/restaurant_info_bg_rank_num' .. tostring(datas.rank) .. '.png'))
		else
			pCell.rankBg:setVisible(false)
		end
	end,__G__TRACKBACK__)
    return pCell
end
----------------世界BOSS排行榜---------------
--------------------------------------------

--[[
根据排行榜奖励配置获取名次描述
@params rewardConfig 排行榜奖励配置
@return str string 名次描述
--]]
function RankingListMediator:GetRankRewardDescrByConfig(rewardConfig)
	local str = '???'

	if nil == rewardConfig then return str end

	local upperLimit = checkint(rewardConfig.upperLimit)
	local lowerLimit = checkint(rewardConfig.lowerLimit)

	if upperLimit == lowerLimit then
		-- 前三名
		str = string.fmt(__('第_num_名'), {['_num_'] = upperLimit})
	elseif -1 == lowerLimit then
		-- 上限-1代表无穷大
		-- str = string.fmt(__('_num_以后'), {['_num_'] = upperLimit})
		str = __('其他')
	else
		-- 正常区间
		str = tostring(upperLimit) .. '~' .. tostring(lowerLimit)
	end

	return str
end

function RankingListMediator:EnterLayer()
	if self.selectedRank then
		self:TabButtonCallback(self.selectedRank)
	end
end
function RankingListMediator:OnRegist(  )
	-- self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "show")
	-- self:GetFacade():UnRegsitMediator("HomeMediator")
	local RankingListCommand = require( 'Game.command.RankingListCommand' )
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Rank_Restaurant, RankingListCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Rank_RestaurantRevenue, RankingListCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Rank_Tower, RankingListCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Rank_TowerHistory, RankingListCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Rank_ArenaRank, RankingListCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Rank_Airship, RankingListCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Rank_Union_Contribution, RankingListCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Rank_Union_ContributionHistory, RankingListCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Rank_Union_GodBeast, RankingListCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Rank_BOSS_Person, RankingListCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Rank_BOSS_Union, RankingListCommand)
	regPost(POST.RANK_UNION_WARS)
	self:EnterLayer()
end

function RankingListMediator:OnUnRegist(  )
	print( "OnUnRegist" )
	local scene = uiMgr:GetCurrentScene()
	scene:RemoveDialog(self:GetViewComponent())
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Rank_Restaurant)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Rank_RestaurantRevenue)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Rank_Tower)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Rank_TowerHistory)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Rank_ArenaRank)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Rank_Airship)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Rank_Union_Contribution)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Rank_Union_ContributionHistory)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Rank_Union_GodBeast)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Rank_BOSS_Person)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Rank_BOSS_Union)
	unregPost(POST.RANK_UNION_WARS)
	if self.leftTimeScheduler then
		scheduler.unscheduleGlobal(self.leftTimeScheduler)
	end
end
return RankingListMediator
