--[[
 * author : liuzhipeng
 * descpt : 巅峰对决 排行榜Mediator
--]]
local Mediator = mvc.Mediator

local ActivityUltimateBattleRankMediator = class("ActivityUltimateBattleRankMediator", Mediator)

local NAME = "activity.ultimateBattle.ActivityUltimateBattleRankMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance('AppFacade'):GetManager("GameManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
local timerMgr = AppFacade.GetInstance():GetManager("TimerManager")

local RankCell = require('home.NewRankCell')
local RankPVCCell = require('home.RankPVCCell')
local CarnieRankChildCell = require('Game.views.summerActivity.carnie.CarnieRankChildCell')
local RANK = {}
local PROLONG_TIME = 2
function ActivityUltimateBattleRankMediator:ctor( params, viewComponent )
	self.super:ctor(NAME,viewComponent)
    self.selectedRank = 1
    self.leftSeconds = checkint(params.leftSeconds) -- 活动剩余时间
	self.rankData = {} -- 所有排行数据
	self.allRankData = {} -- 转换后的排行榜数据
    self.selectedRankData = {} -- 选中的排行榜数据
end

function ActivityUltimateBattleRankMediator:InterestSignals()
	local signals = {
        POST.ACTIVITY_ULTIMATE_BATTLE_QUEST_RANK.sglName,
	}
	return signals
end

function ActivityUltimateBattleRankMediator:ProcessSignal( signal )
	local name = signal:GetName()
    print(name)
    local data = checktable(signal:GetBody())
    if name == POST.ACTIVITY_ULTIMATE_BATTLE_QUEST_RANK.sglName then
        local rankData = {}
        for k, v in orderedPairs(checktable(data.ultimateBattle)) do
            v.groupId = checkint(k)
            table.insert(rankData, v)
        end
        self.rankData = rankData
        self:InitRankData()
		self:InitAllRankData()
		self:InitExpandableListView()
		self:TabButtonCallback(self.selectedRank)
	end
end

function ActivityUltimateBattleRankMediator:Initial( key )
	self.super.Initial(self,key)
	local scene = uiMgr:GetCurrentScene()
	local viewComponent  = require( 'Game.views.activity.ultimateBattle.ActivityUltimateBattleRankView' ).new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	scene:AddDialog(viewComponent)
	viewComponent.viewData.backBtn:setOnClickScriptHandler(function ()
        PlayAudioByClickClose()
        AppFacade.GetInstance():UnRegsitMediator("activity.ultimateBattle.ActivityUltimateBattleRankMediator")
    end)
    viewComponent.viewData.rewardBtn:setOnClickScriptHandler(handler(self, self.RewardButtonCallback))
    viewComponent.viewData.gridView:setDataSourceAdapterScriptHandler(handler(self, self.RankDataSource))
    if self.leftSeconds > 0 then
        timerMgr:AddTimer({name = NAME, countdown = self.leftSeconds, callback = handler(self, self.LeftScheduleCallback)})
    end
    -- self:InitRankData()
    self:InitView()
end
--[[
初始化排行榜页签数据
--]]
function ActivityUltimateBattleRankMediator:InitRankData()
	-- local index = self:GetIndexByCarnieRankType(CarnieRankTypes.POINT)
	-- if index then 
	-- 	RANK[index].child = {}
	-- 	local chapterDatas = CommonUtils.GetConfigAllMess('bossSchedule', 'newSummerActivity')
	-- 	for k,v in orderedPairs(chapterDatas) do
	-- 		local temp = {
	-- 			name = string.fmt(__('嫌疑人_name_'), {['_name_'] = string.char(64 + checkint(k))}),
	-- 			rankTypes = checkint(k),
	-- 		}
	-- 		table.insert(RANK[index].child, temp)
	-- 	end
	-- 	if next(RANK[index].child) == nil then
	-- 		RANK[index] = nil 
	-- 	end
    -- end
    RANK = {}
    for i, v in ipairs(self.rankData) do
        local config = CommonUtils.GetConfig('ultimateBattle', 'group', v.groupId)
        table.insert(RANK, {name = config.name[1], rankTypes = v.groupId})
    end 
    self.selectedRank = RANK[1].rankTypes
end
--[[
初始化每个排行榜的数据
--]]
function ActivityUltimateBattleRankMediator:InitAllRankData()
    -- local index = self:GetIndexByCarnieRankType(CarnieRankTypes.POINT)
	-- for i,v in ipairs(RANK[index].child) do
    --     if not self.rankData.damageRank or not self.rankData.damageRank[tostring(v.rankTypes)] then break end
    --     local damageRankData = self.rankData.damageRank[tostring(v.rankTypes)]   
    --     for i,v in ipairs(damageRankData.damagePointRanks) do
    --         v.point = v.playerScore
	-- 	end
	-- 	self.allRankData[tostring(v.rankTypes)] = {
	-- 		myScore = checkint(damageRankData.myScore),
	-- 		myRank = checkint(damageRankData.myRank),
	-- 		rankData = damageRankData.damagePointRanks
	-- 	}
    -- end
    for i, v in ipairs(RANK) do
        local rankData = self.rankData[i]
        self.allRankData[tostring(v.rankTypes)] = {
			myScore = tonumber(rankData.myUltimateBattleScore),
			myRank = checkint(rankData.myUltimateBattleRank),
			rankData = rankData.rank
		}
    end
end
--[[
初始化页面
--]]
function ActivityUltimateBattleRankMediator:InitView()
    -- 更新时间
    local viewData = self:GetViewComponent().viewData
    local str, showLabel = self:ChangeTimeFormat(self.leftSeconds)
    viewData.timeNum:setString(str)
    if showLabel then
        viewData.timeLabel:setVisible(true)
        viewData.timeLabel:setPositionX(220 + viewData.timeNum:getContentSize().width*1.2)
    else
        viewData.timeLabel:setVisible(false)
    end
end
--[[
刷新Ui
--]]
function ActivityUltimateBattleRankMediator:refreshUi()
    local viewData = self:GetViewComponent().viewData
    self:RefreshExpandableListView()
    self:RefreshRankingList(self.selectedRank)
    self:RefreshOwnRank()
end
--[[
初始化expandableListView
--]]
function ActivityUltimateBattleRankMediator:InitExpandableListView()
	local viewData = self:GetViewComponent().viewData
    local expandableListView = viewData.expandableListView
	-- 添加类别
	for i,v in ipairs(RANK) do
		local size = cc.size(212, 90)
		local expandableNode = RankCell.new(size)
		expandableNode.button:setOnClickScriptHandler(handler(self, self.TabButtonCallback))
		expandableNode.button:setUserTag(v.rankTypes)
		expandableNode.nameLabel:setString(v.name)
		-- 判断是否被选中
		if self.selectedRank == v.rankTypes then
			expandableNode.button:setNormalImage(_res('ui/home/rank/rank_btn_tab_select.png'))
			expandableNode.button:setSelectedImage(_res('ui/home/rank/rank_btn_tab_select.png'))
			if v.child then
				self.selectedRank = v.child[1].rankTypes
			end
		end
        expandableListView:insertExpandableNodeAtLast(expandableNode)
        if v.child and next(v.child) ~= nil then
            expandableNode.arrowIcon:setVisible(true)
            for _, childData in ipairs(v.child) do
                local childSize = cc.size(size.width, 64)
                local childNode = CarnieRankChildCell.new(childSize)
                childNode.bgBtn:setOnClickScriptHandler(handler(self, self.TabButtonCallback))
                childNode.bgBtn:setUserTag(childData.rankTypes)
                display.commonLabelParams(childNode.bgBtn, fontWithColor(14, {text = childData.name}))
                expandableNode:insertItemNodeAtLast(childNode)
            end
        end
	end
    expandableListView:reloadData()
end
--[[
更新expandableListView状态
--]]
function ActivityUltimateBattleRankMediator:RefreshExpandableListView()
	local viewData = self:GetViewComponent().viewData
    local expandableListView = viewData.expandableListView
    for i,v in ipairs(RANK) do
        local expandableNode = expandableListView:getExpandableNodeAtIndex(i - 1)
        if expandableNode then
		    -- 判断是否被选中
		    if self.selectedRank == v.rankTypes then
		    	expandableNode.button:setNormalImage(_res('ui/home/rank/rank_btn_tab_select.png'))
                expandableNode.button:setSelectedImage(_res('ui/home/rank/rank_btn_tab_select.png'))
            else
		    	expandableNode.button:setNormalImage(_res('ui/home/rank/rank_btn_tab_default.png'))
                expandableNode.button:setSelectedImage(_res('ui/home/rank/rank_btn_tab_default.png'))
		    end
		    -- 判断是否有子页签
            if v.child and next(v.child) ~= nil then
                local isSelected = false
		    	-- 判断子页签是否被选中
                for index, child in ipairs(v.child) do
                    local node = expandableNode:getItemNodeAtIndex(index - 1)
                    if child.rankTypes == self.selectedRank then
                        node.bgBtn:setNormalImage(_res('ui/home/rank/rank_btn_2_select.png'))
                        node.bgBtn:setSelectedImage(_res('ui/home/rank/rank_btn_2_select.png'))
                        isSelected = true
                    else
                        node.bgBtn:setNormalImage(_res('ui/home/rank/rank_btn_2_default.png'))
                        node.bgBtn:setSelectedImage(_res('ui/home/rank/rank_btn_2_default.png'))
		    		end
                end
                if isSelected then
                    expandableNode:setExpanded(true)
                    expandableNode.button:setNormalImage(_res('ui/home/rank/rank_btn_tab_select.png'))
                    expandableNode.button:setSelectedImage(_res('ui/home/rank/rank_btn_tab_select.png'))
                    expandableNode.arrowIcon:setRotation(0)
                else
                    expandableNode:setExpanded(false)
                    expandableNode.arrowIcon:setRotation(270)
                end
		    end
        end
    end
    expandableListView:reloadData()
end
--[[
更新所选择的排行榜数据
--]]
function ActivityUltimateBattleRankMediator:UpdateSelectedRankData()
	self.selectedRankData = self.allRankData[tostring(self.selectedRank)] or {}
end
--[[
刷新自己的排行
--]]
function ActivityUltimateBattleRankMediator:RefreshOwnRank()
    local myScore = self.selectedRankData.myScore -- 自己的得分
    local myRank = self.selectedRankData.myRank  -- 自己的排名
    local rankData = self.selectedRankData.rankData -- 排行榜数据
    local viewData = self:GetViewComponent().viewData
    if myRank == 0 then
        viewData.playerRankLabel:setVisible(true)
        viewData.rankBg:setVisible(false)
        viewData.playerRankNum:setVisible(false)
        viewData.scoreNum:setVisible(false)
        viewData.scoreTextLabel:setVisible(false)
    else
        viewData.playerRankLabel:setVisible(false)
        viewData.playerRankNum:setVisible(true)
        viewData.scoreNum:setVisible(true)
        viewData.scoreTextLabel:setVisible(true)
        viewData.playerRankNum:setString(myRank)
        if myRank >= 1 and myRank <= 3 then
            viewData.rankBg:setVisible(true)
            viewData.rankBg:setTexture(_res('ui/home/rank/restaurant_info_bg_rank_num' .. tostring(myRank) .. '.png'))
        else
            viewData.rankBg:setVisible(false)
        end
    end
    viewData.scoreNum:setString(tostring(myScore))
    viewData.scoreNum:setPositionX(955)

end
--[[
刷新排行榜页面
@params int carnieRankType 排行榜类型
--]]
function ActivityUltimateBattleRankMediator:RefreshRankingList( carnieRankType )
	if carnieRankType then
		carnieRankType = checkint(carnieRankType)
	else
		return
	end
    local viewData = self:GetViewComponent().viewData
    viewData.gridView:setCountOfCell(#self.selectedRankData.rankData)
    viewData.gridView:reloadData()	
end
--[[
排行榜数据处理
--]]
function ActivityUltimateBattleRankMediator:RankDataSource( p_convertview, idx )
	local pCell = p_convertview
    local index = idx + 1
    local cSize = cc.size(1035, 112)
    if pCell == nil then
        pCell = RankPVCCell.new(cSize)
        pCell.scoreIcon:setVisible(false)
        --local scoreTextlabel = display.newLabel(pCell.scoreIcon:getPositionX(), pCell.scoreIcon:getPositionY() - 4, {text = "s", fontSize = 30, color = '#5c5c5c'})
        --pCell.eventNode:addChild(scoreTextlabel, 10)
    end
    xTry(function()
        local datas = self.selectedRankData.rankData[index]
		pCell.avatarIcon:RefreshSelf({level = datas.playerLevel, avatar = datas.playerAvatar, avatarFrame = datas.playerAvatarFrame})
		pCell.rankNum:setString(datas.rank)
		pCell.nameLabel:setString(datas.playerName)
		pCell.scoreNum:setString(datas.passTime)
		pCell.avatarIcon:setTag(index)
		pCell.avatarIcon:setOnClickScriptHandler(function ( sender )
			local tag = sender:getTag()
			uiMgr:AddDialog('common.PlayerHeadPopup', {playerId = datas.playerId, type = CommonUtils.GetHeadPopupTypeByPlayerId(datas.playerId)})
		end)
        local cardIndex = 0
		for i,v in ipairs(pCell.cardTable) do
			local cardDatas = nil
			for i = cardIndex+1, 5, 1 do
				cardDatas = checktable(datas.fightTeam.cards)[i]
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
    return pCell
end
--[[
查看奖励按钮点击回调
--]]
function ActivityUltimateBattleRankMediator:RewardButtonCallback( sender )
    PlayAudioByClickNormal()
    local scene = uiMgr:GetCurrentScene()
    local rewardsDatas = nil 
    local title = nil 

    rewardsDatas = CommonUtils.GetConfig('ultimateBattle', 'rankReward', self.selectedRank)
    title = __('巅峰对决排行榜奖励')
    if not rewardsDatas or next(rewardsDatas) == nil then return end
    local convertRewardData = {}
    local index = 1
    -- 把key变为从1开始
    for i, v in orderedPairs(rewardsDatas) do
        convertRewardData[tostring(index)] = v
        index = index + 1
    end
    local rewardListView  = require( 'Game.views.LobbyRewardListView' ).new({tag = 1200, mediatorName = "ActivityUltimateBattleRankMediator", showTips = true, rewardsDatas = convertRewardData, title = title})
    rewardListView:setPosition(display.center)
    rewardListView:setTag(1200)
    scene:AddDialog(rewardListView)
end
--[[
搜索按钮点击回调
--]]
function ActivityUltimateBattleRankMediator:SrarchButtonCallback( sender )
    PlayAudioByClickNormal()
    local tag = sender:getTag()
    local view = require('Game.views.worldboss.WorldBossManualPlayerCardShowView').new({playerInfo = self.selectedRankData.rankData[tag], title = __('他（她）的游玩阵容')})
    display.commonUIParams(view,{po = display.center, ap = display.CENTER})
    uiMgr:GetCurrentScene():AddDialog(view)
end
--[[
改变时间格式
@params seconds int 剩余秒数
--]]
function ActivityUltimateBattleRankMediator:ChangeTimeFormat( seconds )
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
function ActivityUltimateBattleRankMediator:TabButtonCallback( sender )

    if tolua.type(sender) == 'ccw.CButton' then
        PlayAudioByClickNormal()
    end
	local rankTypes = nil
	if type(sender) == 'number' then
		rankTypes = sender
	else
		rankTypes = sender:getUserTag()
		if rankTypes == self.selectedRank then return end
	end
	-- 判断此页签有没有子页签
	for i, v in ipairs(RANK) do
		if v.rankTypes == rankTypes then
			if v.child and next(v.child) ~= nil then
				rankTypes = v.child[1].rankTypes
			end
		end
	end
    self.selectedRank = rankTypes
    self:UpdateSelectedRankData()
	self:refreshUi()
end
--[[
左侧页签子页签点击回调
--]]
function ActivityUltimateBattleRankMediator:TabChildButtonCallback( sender )
end
--[[
定时器回调
--]]
function ActivityUltimateBattleRankMediator:LeftScheduleCallback( leftSeconds )
    if leftSeconds > 0 then
        local viewData = self:GetViewComponent().viewData
        local str, showLabel = self:ChangeTimeFormat(leftSeconds)
		viewData.timeNum:setString(str)
		if showLabel then
			viewData.timeLabel:setVisible(true)
			local timeLabelPosX = viewData.timeNum:getPositionX()
			viewData.timeLabel:setPositionX(viewData.timeNum:getContentSize().width  +  timeLabelPosX + 10  )
		else
			viewData.timeLabel:setVisible(false)
        end
    else
        AppFacade.GetInstance():UnRegsitMediator("ActivityUltimateBattleRankMediator")
    end
end
--[[
根据排行榜类型获取index
--]]
function ActivityUltimateBattleRankMediator:GetIndexByCarnieRankType( carnieRankType )
	local index = 1
	for i,v in ipairs(RANK) do
		if checkint(v.rankTypes) == checkint(carnieRankType) then
			index = i
		end
	end
	return index
end

function ActivityUltimateBattleRankMediator:EnterLayer()
    self:SendSignal(POST.ACTIVITY_ULTIMATE_BATTLE_QUEST_RANK.cmdName)
end
function ActivityUltimateBattleRankMediator:OnRegist(  )
    regPost(POST.ACTIVITY_ULTIMATE_BATTLE_QUEST_RANK)
    self:EnterLayer()
end

function ActivityUltimateBattleRankMediator:OnUnRegist(  )
    print( "OnUnRegist" )
    unregPost(POST.ACTIVITY_ULTIMATE_BATTLE_QUEST_RANK)
	local scene = uiMgr:GetCurrentScene()
	scene:RemoveDialog(self:GetViewComponent())
    timerMgr:RemoveTimer(NAME)
end
return ActivityUltimateBattleRankMediator
