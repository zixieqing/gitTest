--[[
游乐园（夏活）排行榜Mediator
--]]
local Mediator = mvc.Mediator

local CarnieRankMediator = class("CarnieRankMediator", Mediator)

local NAME = "CarnieRankMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance('AppFacade'):GetManager("GameManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
local timerMgr = AppFacade.GetInstance():GetManager("TimerManager")
local summerActMgr = app.summerActMgr

local RankCell = require('home.NewRankCell')
local CarnieRankCell = require('Game.views.summerActivity.carnie.CarnieRankCell')
local CarnieRankChildCell = require('Game.views.summerActivity.carnie.CarnieRankChildCell')
CarnieRankTypes = {
    POINT = -1,
    DAMAGE = -2
}
local RANK = {
	{name = summerActMgr:getThemeTextByText(__('点数排行榜')), rankTypes = CarnieRankTypes.POINT},
	{name = summerActMgr:getThemeTextByText(__('小丑伤害排行')), rankTypes = CarnieRankTypes.DAMAGE, child = {}},
}
local PROLONG_TIME = 2
function CarnieRankMediator:ctor( params, viewComponent )
	self.super:ctor(NAME,viewComponent)
    self.selectedRank = CarnieRankTypes.POINT
    self.leftSeconds = checkint(gameMgr:GetUserInfo().summerActivity) -- 活动剩余时间
	self.rankData = {} -- 所有排行数据
	self.allRankData = {} -- 转换后的排行榜数据
    self.selectedRankData = {} -- 选中的排行榜数据
end

function CarnieRankMediator:InterestSignals()
	local signals = {
        POST.CARNIE_RANK_HOME.sglName,
	}
	return signals
end

function CarnieRankMediator:ProcessSignal( signal )
	local name = signal:GetName()
    print(name)
    local data = checktable(signal:GetBody())
    if name == POST.CARNIE_RANK_HOME.sglName then
		self.rankData = data
		self:InitAllRankData()
		self:InitExpandableListView()
		self:TabButtonCallback(self.selectedRank)
	end
end

function CarnieRankMediator:Initial( key )
	self.super.Initial(self,key)
	local scene = uiMgr:GetCurrentScene()
	local viewComponent  = require( 'Game.views.summerActivity.carnie.CarnieRankView' ).new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	scene:AddDialog(viewComponent)
	viewComponent.viewData.backBtn:setOnClickScriptHandler(function ()
        PlayAudioByClickClose()
        AppFacade.GetInstance():UnRegsitMediator("CarnieRankMediator")
    end)
    viewComponent.viewData.rewardBtn:setOnClickScriptHandler(handler(self, self.RewardButtonCallback))
    viewComponent.viewData.gridView:setDataSourceAdapterScriptHandler(handler(self, self.RankDataSource))
    if self.leftSeconds > 0 then
        timerMgr:AddTimer({name = NAME, countdown = self.leftSeconds, callback = handler(self, self.LeftScheduleCallback)})
    end
    self:InitRankData()
    self:InitView()
end
--[[
初始化排行榜页签数据
--]]
function CarnieRankMediator:InitRankData()
	local index = self:GetIndexByCarnieRankType(CarnieRankTypes.DAMAGE)
	if index then 
		RANK[index].child = {}
		local chapterDatas = CommonUtils.GetConfigAllMess('chapter', 'summerActivity')
		for k,v in orderedPairs(chapterDatas) do
			local temp = {
				name = v.name,
				rankTypes = checkint(k),
			}
			table.insert(RANK[index].child, temp)
		end
		if next(RANK[index].child) == nil then
			RANK[index] = nil 
		end
	end
end
--[[
初始化每个排行榜的数据
--]]
function CarnieRankMediator:InitAllRankData()
	-- 点数榜单
	if self.rankData.summerPointRank then
		for i,v in ipairs(self.rankData.summerPointRank) do
    	    v.point = v.playerSummerPoint
    	end
		self.allRankData[tostring(CarnieRankTypes.POINT)] = {
			myScore = checkint(self.rankData.mySummerPoint),
    	    myRank = checkint(self.rankData.mySummerPointRank),
    	    rankData = self.rankData.summerPointRank,
		}
	end
	-- 伤害榜
	local index = self:GetIndexByCarnieRankType(CarnieRankTypes.DAMAGE)
	for i,v in ipairs(RANK[index].child) do
        if not self.rankData.damageRank or not self.rankData.damageRank[tostring(v.rankTypes)] then break end
        local damageRankData = self.rankData.damageRank[tostring(v.rankTypes)]   
        for i,v in ipairs(damageRankData.ServerDamageRank) do
            v.point = v.playerDamage
		end
		self.allRankData[tostring(v.rankTypes)] = {
			myScore = checkint(damageRankData.myDamage),
			myRank = checkint(damageRankData.myDamageRank),
			rankData = damageRankData.ServerDamageRank
		}
	end
end
--[[
初始化页面
--]]
function CarnieRankMediator:InitView()
    -- 更新时间
    local viewData = self:GetViewComponent().viewData
    local str, showLabel = self:ChangeTimeFormat(self.leftSeconds)
    viewData.timeNum:setString(str)
    if showLabel then
        viewData.timeLabel:setVisible(true)
        viewData.timeLabel:setPositionX(50 + display.getLabelContentSize(viewData.endLabel).width + viewData.timeNum:getContentSize().width*1.2)
    else
        viewData.timeLabel:setVisible(false)
    end
end
--[[
刷新Ui
--]]
function CarnieRankMediator:refreshUi()
    local viewData = self:GetViewComponent().viewData
    self:RefreshExpandableListView()
    self:RefreshRankingList(self.selectedRank)
    self:RefreshOwnRank()
end
--[[
初始化expandableListView
--]]
function CarnieRankMediator:InitExpandableListView()
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
                display.commonLabelParams(childNode.bgBtn, fontWithColor(14, {fontSize =20 ,  text = childData.name, w = 130, hAlign = cc.TEXT_ALIGNMENT_CENTER}))
                expandableNode:insertItemNodeAtLast(childNode)
            end
        end
	end
    expandableListView:reloadData()
end
--[[
更新expandableListView状态
--]]
function CarnieRankMediator:RefreshExpandableListView()
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
function CarnieRankMediator:UpdateSelectedRankData()
    -- local myScore = 0 -- 自己的得分
    -- local myRank = 0  -- 自己的排名
    -- local rankData = {} -- 排行榜数据
    -- if self.selectedRank == CarnieRankTypes.POINT then
    --     myScore = checkint(self.rankData.mySummerPoint)
    --     myRank = checkint(self.rankData.mySummerPointRank)
    --     rankData = self.rankData.summerPointRank
    --     for i,v in ipairs(rankData) do
    --         v.point = v.playerSummerPoint
    --     end
    -- else
    --     if not self.rankData.damageRank or not self.rankData.damageRank[tostring(self.selectedRank)] then return end
    --     local damageRankData = self.rankData.damageRank[tostring(self.selectedRank)]
    --     myScore = checkint(damageRankData.myDamage)
    --     myRank = checkint(damageRankData.myDamageRank)
    --     rankData = damageRankData.ServerDamageRank    
    --     for i,v in ipairs(rankData) do
    --         v.point = v.playerDamage
    --     end
    -- end
    -- self.selectedRankData = {
    --     myScore = myScore,
    --     myRank  = myRank,
    --     rankData = rankData,
	-- }
	self.selectedRankData = self.allRankData[tostring(self.selectedRank)] or {}
end
--[[
刷新自己的排行
--]]
function CarnieRankMediator:RefreshOwnRank()
    local myScore = self.selectedRankData.myScore -- 自己的得分
    local myRank = self.selectedRankData.myRank  -- 自己的排名
    local rankData = self.selectedRankData.rankData -- 排行榜数据
    local viewData = self:GetViewComponent().viewData
    if myRank == 0 then
        viewData.playerRankLabel:setVisible(true)
        viewData.rankBg:setVisible(false)
        viewData.playerRankNum:setVisible(false)
    else
        viewData.playerRankLabel:setVisible(false)
        viewData.playerRankNum:setVisible(true)
        viewData.playerRankNum:setString(myRank)
        if myRank >= 1 and myRank <= 3 then
            viewData.rankBg:setVisible(true)
            viewData.rankBg:setTexture(_res('ui/home/rank/restaurant_info_bg_rank_num' .. tostring(myRank) .. '.png'))
        else
            viewData.rankBg:setVisible(false)
        end
    end
    viewData.scoreNum:setString(tostring(myScore))
    if self.selectedRank == CarnieRankTypes.POINT then
        viewData.scoreIcon:setVisible(true)
        viewData.scoreNum:setPositionX(955)
    else
        viewData.scoreIcon:setVisible(false)
        viewData.scoreNum:setPositionX(955 + 40)
    end
end
--[[
刷新排行榜页面
@params int carnieRankType 排行榜类型
--]]
function CarnieRankMediator:RefreshRankingList( carnieRankType )
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
function CarnieRankMediator:RankDataSource( p_convertview, idx )
	local pCell = p_convertview
    local index = idx + 1
    local cSize = cc.size(1035, 112)
    if pCell == nil then
        pCell = CarnieRankCell.new(cSize)
        pCell.searchBtn:setOnClickScriptHandler(handler(self, self.SrarchButtonCallback))
    end
    xTry(function()
		local data = self.selectedRankData.rankData[index]
		pCell.rankNum:setString(data.playerRank)
		pCell.avatarIcon:RefreshSelf({level = data.playerLevel, avatar = data.playerAvatar, avatarFrame = data.playerAvatarFrame})
		pCell.nameLabel:setString(data.playerName)
		pCell.scoreNum:setString(data.point)
		pCell.avatarIcon:setTag(index)
		pCell.avatarIcon:setOnClickScriptHandler(function ( sender )
			local tag = sender:getTag()
			uiMgr:AddDialog('common.PlayerHeadPopup', {playerId = data.playerId, type = CommonUtils.GetHeadPopupTypeByPlayerId(data.playerId)})
		end)
		if checkint(data.playerRank) >= 1 and checkint(data.playerRank) <= 3 then
			pCell.rankBg:setVisible(true)
			pCell.rankBg:setTexture(_res('ui/home/rank/restaurant_info_bg_rank_num' .. tostring(data.playerRank) .. '.png'))
		else
			pCell.rankBg:setVisible(false)
        end
        if self.selectedRank == CarnieRankTypes.POINT then
            pCell.searchBtn:setVisible(false)
            pCell.scoreIcon:setVisible(true)
            pCell.scoreNum:setPositionX(955)
        else
            pCell.searchBtn:setVisible(true)
            pCell.scoreIcon:setVisible(false)
            pCell.scoreNum:setPositionX(955 + 40)
            pCell.searchBtn:setTag(index)
        end
	end,__G__TRACKBACK__)
    return pCell
end
--[[
查看奖励按钮点击回调
--]]
function CarnieRankMediator:RewardButtonCallback( sender )
    PlayAudioByClickNormal()
    local scene = uiMgr:GetCurrentScene()
    local rewardsDatas = nil 
    local title = nil 
    if self.selectedRank == CarnieRankTypes.POINT then
        rewardsDatas = CommonUtils.GetConfigAllMess('summerPointRankRewards', 'summerActivity')
        title = summerActMgr:getThemeTextByText(__('点数排行榜奖励'))
    else
        rewardsDatas = CommonUtils.GetConfigAllMess('damageRankRewards', 'summerActivity')[tostring(self.selectedRank)]
        title = summerActMgr:getThemeTextByText(__('伤害排行榜奖励'))
    end
    if not rewardsDatas or next(rewardsDatas) == nil then return end
    local rewardListView  = require( 'Game.views.LobbyRewardListView' ).new({tag = 1200, mediatorName = "CarnieRankMediator", showTips = true, rewardsDatas = rewardsDatas, title = title})
    rewardListView:setPosition(display.center)
    rewardListView:setTag(1200)
    scene:AddDialog(rewardListView)
end
--[[
搜索按钮点击回调
--]]
function CarnieRankMediator:SrarchButtonCallback( sender )
    PlayAudioByClickNormal()
    local tag = sender:getTag()
    local view = require('Game.views.worldboss.WorldBossManualPlayerCardShowView').new({playerInfo = self.selectedRankData.rankData[tag], title = summerActMgr:getThemeTextByText(__('他（她）的游玩阵容'))})
    display.commonUIParams(view,{po = display.center, ap = display.CENTER})
    uiMgr:GetCurrentScene():AddDialog(view)
end
--[[
改变时间格式
@params seconds int 剩余秒数
--]]
function CarnieRankMediator:ChangeTimeFormat( seconds )
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
function CarnieRankMediator:TabButtonCallback( sender )

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
function CarnieRankMediator:TabChildButtonCallback( sender )
end
--[[
定时器回调
--]]
function CarnieRankMediator:LeftScheduleCallback( leftSeconds )
    if leftSeconds > 0 then
        local viewData = self:GetViewComponent().viewData
        local str, showLabel = self:ChangeTimeFormat(leftSeconds)
		viewData.timeNum:setString(str)
		if showLabel then
			viewData.timeLabel:setVisible(true)
			viewData.timeLabel:setPositionX(50 + display.getLabelContentSize(viewData.endLabel).width + viewData.timeNum:getContentSize().width*1.2)
		else
			viewData.timeLabel:setVisible(false)
        end
    else
        AppFacade.GetInstance():UnRegsitMediator("CarnieRankMediator")
    end
end
--[[
根据排行榜类型获取index
--]]
function CarnieRankMediator:GetIndexByCarnieRankType( carnieRankType )
	local index = 1
	for i,v in ipairs(RANK) do
		if checkint(v.rankTypes) == checkint(carnieRankType) then
			index = i
		end
	end
	return index
end

function CarnieRankMediator:EnterLayer()
    self:SendSignal(POST.CARNIE_RANK_HOME.cmdName)
end
function CarnieRankMediator:OnRegist(  )
    regPost(POST.CARNIE_RANK_HOME)
    self:EnterLayer()
end

function CarnieRankMediator:OnUnRegist(  )
    print( "OnUnRegist" )
    unregPost(POST.CARNIE_RANK_HOME)
	local scene = uiMgr:GetCurrentScene()
	scene:RemoveDialog(self:GetViewComponent())
    timerMgr:RemoveTimer(NAME)
end
return CarnieRankMediator
