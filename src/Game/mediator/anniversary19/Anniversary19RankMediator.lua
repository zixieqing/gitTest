--[[
 * descpt : 19周年庆 排行榜Mediator
--]]
local Mediator = mvc.Mediator

local Anniversary19RankMediator = class("Anniversary19RankMediator", Mediator)

local NAME = "anniversary19.Anniversary19RankMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance('AppFacade'):GetManager("GameManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
local timerMgr = AppFacade.GetInstance():GetManager("TimerManager")

local RankCell = require('home.NewRankCell')
local CarnieRankCell = require('Game.views.summerActivity.carnie.CarnieRankCell')
local CarnieRankChildCell = require('Game.views.summerActivity.carnie.CarnieRankChildCell')

function Anniversary19RankMediator:ctor( params, viewComponent )
	self.super:ctor(NAME,viewComponent)
    
	self.rankData = {} -- 所有排行数据
	self.allRankData = {} -- 转换后的排行榜数据
    self.selectedRankData = {} -- 选中的排行榜数据
end

function Anniversary19RankMediator:InterestSignals()
	local signals = {
        POST.ANNIVERSARY2_RANK.sglName,
	}
	return signals
end

function Anniversary19RankMediator:ProcessSignal( signal )
	local name = signal:GetName()
    local data = checktable(signal:GetBody())
    if name == POST.ANNIVERSARY2_RANK.sglName then
		self:InitAllRankData(data)
		self:InitExpandableListView()
		self:TabButtonCallback(self.selectedRank)
	end
end

function Anniversary19RankMediator:Initial( key )
	self.super.Initial(self,key)
	local scene = uiMgr:GetCurrentScene()
	local viewComponent  = require( 'Game.views.anniversary19.Anniversary19RankView' ).new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	scene:AddDialog(viewComponent)
	viewComponent.viewData.backBtn:setOnClickScriptHandler(function ()
        PlayAudioByClickClose()
        AppFacade.GetInstance():UnRegsitMediator(NAME)
    end)
    viewComponent.viewData.rewardBtn:setOnClickScriptHandler(handler(self, self.RewardButtonCallback))
    viewComponent.viewData.gridView:setDataSourceAdapterScriptHandler(handler(self, self.RankDataSource))
    -- if self.leftSeconds > 0 then
    --     timerMgr:AddTimer({name = NAME, countdown = self.leftSeconds, callback = handler(self, self.LeftScheduleCallback)})
    -- end
    self:InitRankData()
    -- self:InitView()
end
--[[
初始化排行榜页签数据
--]]
function Anniversary19RankMediator:InitRankData()
    
    local chapterConf =  CommonUtils.GetConfigAllMess('chapter', 'anniversary2') or {}
    local rankConf = {}
    for index, value in orderedPairs(chapterConf) do
        table.insert(rankConf, {
            name = value.bossName,
            rankTypes = value.id,
        })
    end

    self.rankConf = rankConf
    self.selectedRank = rankConf[1].rankTypes
end

--[[
初始化每个排行榜的数据
--]]
function Anniversary19RankMediator:InitAllRankData(data)
    local chapterData = data.chapter or {}
    for index, value in ipairs(self.rankConf) do
        local rankTypes = tostring(value.rankTypes)
        local chapterRankData = chapterData[rankTypes] or {}
        local rankData = chapterRankData.rank or {}

        self.allRankData[rankTypes] = {
			myScore = checkint(chapterRankData.myScore),
			myRank = checkint(chapterRankData.myRank),
			rankData = rankData
		}
    end
end
--[[
初始化页面
--]]
function Anniversary19RankMediator:InitView()
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
function Anniversary19RankMediator:refreshUi()
    local viewData = self:GetViewComponent().viewData
    self:RefreshExpandableListView()
    self:RefreshRankingList(self.selectedRank)
    self:RefreshOwnRank()
end
--[[
初始化expandableListView
--]]
function Anniversary19RankMediator:InitExpandableListView()
	local viewData = self:GetViewComponent().viewData
    local expandableListView = viewData.expandableListView
	-- 添加类别
	for i,v in ipairs(self.rankConf) do
		local size = cc.size(212, 90)
		local expandableNode = RankCell.new(size)
		expandableNode.button:setOnClickScriptHandler(handler(self, self.TabButtonCallback))
		expandableNode.button:setUserTag(v.rankTypes)
		expandableNode.nameLabel:setString(v.name)
		-- 判断是否被选中
		if self.selectedRank == v.rankTypes then
			expandableNode.button:setNormalImage(app.anniversary2019Mgr:GetResPath('ui/home/rank/rank_btn_tab_select.png'))
			expandableNode.button:setSelectedImage(app.anniversary2019Mgr:GetResPath('ui/home/rank/rank_btn_tab_select.png'))
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
function Anniversary19RankMediator:RefreshExpandableListView()
	local viewData = self:GetViewComponent().viewData
    local expandableListView = viewData.expandableListView
    for i,v in ipairs(self.rankConf) do
        local expandableNode = expandableListView:getExpandableNodeAtIndex(i - 1)
        if expandableNode then
		    -- 判断是否被选中
		    if self.selectedRank == v.rankTypes then
		    	expandableNode.button:setNormalImage(app.anniversary2019Mgr:GetResPath('ui/home/rank/rank_btn_tab_select.png'))
                expandableNode.button:setSelectedImage(app.anniversary2019Mgr:GetResPath('ui/home/rank/rank_btn_tab_select.png'))
            else
		    	expandableNode.button:setNormalImage(app.anniversary2019Mgr:GetResPath('ui/home/rank/rank_btn_tab_default.png'))
                expandableNode.button:setSelectedImage(app.anniversary2019Mgr:GetResPath('ui/home/rank/rank_btn_tab_default.png'))
		    end
		    -- 判断是否有子页签
            if v.child and next(v.child) ~= nil then
                local isSelected = false
		    	-- 判断子页签是否被选中
                for index, child in ipairs(v.child) do
                    local node = expandableNode:getItemNodeAtIndex(index - 1)
                    if child.rankTypes == self.selectedRank then
                        node.bgBtn:setNormalImage(app.anniversary2019Mgr:GetResPath('ui/home/rank/rank_btn_2_select.png'))
                        node.bgBtn:setSelectedImage(app.anniversary2019Mgr:GetResPath('ui/home/rank/rank_btn_2_select.png'))
                        isSelected = true
                    else
                        node.bgBtn:setNormalImage(app.anniversary2019Mgr:GetResPath('ui/home/rank/rank_btn_2_default.png'))
                        node.bgBtn:setSelectedImage(app.anniversary2019Mgr:GetResPath('ui/home/rank/rank_btn_2_default.png'))
		    		end
                end
                if isSelected then
                    expandableNode:setExpanded(true)
                    expandableNode.button:setNormalImage(app.anniversary2019Mgr:GetResPath('ui/home/rank/rank_btn_tab_select.png'))
                    expandableNode.button:setSelectedImage(app.anniversary2019Mgr:GetResPath('ui/home/rank/rank_btn_tab_select.png'))
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
function Anniversary19RankMediator:UpdateSelectedRankData()
	self.selectedRankData = self.allRankData[tostring(self.selectedRank)] or {}
end
--[[
刷新自己的排行
--]]
function Anniversary19RankMediator:RefreshOwnRank()
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
            viewData.rankBg:setTexture(app.anniversary2019Mgr:GetResPath(table.concat({'ui/home/rank/restaurant_info_bg_rank_num', tostring(myRank), '.png'})))
        else
            viewData.rankBg:setVisible(false)
        end
    end
    viewData.scoreNum:setString(tostring(myScore))
    viewData.scoreNum:setPositionX(955)
    -- viewData.scoreIcon:setVisible(true)
    -- viewData.scoreIcon:setTexture(CommonUtils.GetGoodsIconPathById(app.anniversary2019Mgr:GetIntegralGoodsId()))

end
--[[
刷新排行榜页面
@params int rankType 排行榜类型
--]]
function Anniversary19RankMediator:RefreshRankingList( rankType )
	if rankType then
		rankType = checkint(rankType)
	else
		return
	end
    local viewData = self:GetViewComponent().viewData
    local gridView = viewData.gridView
    gridView:setCountOfCell(#self.selectedRankData.rankData)
    gridView:reloadData()
    
end
--[[
排行榜数据处理
--]]
function Anniversary19RankMediator:RankDataSource( p_convertview, idx )
	local pCell = p_convertview
    local index = idx + 1
    local cSize = cc.size(1035, 112)
    if pCell == nil then
        pCell = CarnieRankCell.new(cSize)
        pCell.searchBtn:setOnClickScriptHandler(handler(self, self.SrarchButtonCallback))
        pCell.scoreIcon:setVisible(false)
    end
    xTry(function()
        local data = self.selectedRankData.rankData[index]
        local rank = data.rank
		pCell.rankNum:setString(rank)
		pCell.avatarIcon:RefreshSelf({level = data.playerLevel, avatar = data.playerAvatar, avatarFrame = data.playerAvatarFrame})
		pCell.nameLabel:setString(data.playerName)
		pCell.scoreNum:setString(data.score)
		pCell.avatarIcon:setTag(index)
		pCell.avatarIcon:setOnClickScriptHandler(function ( sender )
			local tag = sender:getTag()
			uiMgr:AddDialog('common.PlayerHeadPopup', {playerId = data.playerId, type = CommonUtils.GetHeadPopupTypeByPlayerId(data.playerId)})
		end)
		if checkint(rank) >= 1 and checkint(rank) <= 3 then
			pCell.rankBg:setVisible(true)
			pCell.rankBg:setTexture(app.anniversary2019Mgr:GetResPath(table.concat({'ui/home/rank/restaurant_info_bg_rank_num', tostring(data.playerRank), '.png'})))
		else
			pCell.rankBg:setVisible(false)
        end
        pCell.searchBtn:setVisible(false)
        -- pCell.scoreIcon:setTexture(CommonUtils.GetGoodsIconPathById(app.anniversary2019Mgr:GetIntegralGoodsId()))
        -- pCell.scoreIcon:setVisible(true)
        pCell.scoreNum:setPositionX(955)
	end,__G__TRACKBACK__)
    return pCell
end
--[[
查看奖励按钮点击回调
--]]
function Anniversary19RankMediator:RewardButtonCallback( sender )
    PlayAudioByClickNormal()
    local scene = uiMgr:GetCurrentScene()
    local rewardsDatas = nil 
    local title = nil 

    rewardsDatas = CommonUtils.GetConfigAllMess('rankRewards', 'anniversary2')[tostring(self.selectedRank)]
    title = app.anniversary2019Mgr:GetPoText(__('点数排行榜奖励'))

    if not rewardsDatas or next(rewardsDatas) == nil then return end
    local rewardListView  = require( 'Game.views.LobbyRewardListView' ).new({tag = 1200, mediatorName = "Anniversary19RankMediator", showTips = true, rewardsDatas = rewardsDatas, title = title})
    rewardListView:setPosition(display.center)
    rewardListView:setTag(1200)
    scene:AddDialog(rewardListView)
end
--[[
搜索按钮点击回调
--]]
function Anniversary19RankMediator:SrarchButtonCallback( sender )
    PlayAudioByClickNormal()
    local tag = sender:getTag()
    local view = require('Game.views.worldboss.WorldBossManualPlayerCardShowView').new({playerInfo = self.selectedRankData.rankData[tag], title = app.anniversary2019Mgr:GetPoText(__('他（她）的游玩阵容'))})
    display.commonUIParams(view,{po = display.center, ap = display.CENTER})
    uiMgr:GetCurrentScene():AddDialog(view)
end
--[[
改变时间格式
@params seconds int 剩余秒数
--]]
function Anniversary19RankMediator:ChangeTimeFormat( seconds )
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
function Anniversary19RankMediator:TabButtonCallback( sender )

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
	for i, v in ipairs(self.rankConf) do
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
function Anniversary19RankMediator:TabChildButtonCallback( sender )
end
--[[
定时器回调
--]]
function Anniversary19RankMediator:LeftScheduleCallback( leftSeconds )
    if leftSeconds > 0 then
        local viewData = self:GetViewComponent().viewData
        local str, showLabel = self:ChangeTimeFormat(leftSeconds)
		viewData.timeNum:setString(str)
		if showLabel then
			viewData.timeLabel:setVisible(true)
			viewData.timeLabel:setPositionX(220 + viewData.timeNum:getContentSize().width*1.2)
		else
			viewData.timeLabel:setVisible(false)
        end
    else
        AppFacade.GetInstance():UnRegsitMediator("Anniversary19RankMediator")
    end
end
--[[
根据排行榜类型获取index
--]]
function Anniversary19RankMediator:GetIndexByCarnieRankType( rankType )
	local index = 1
	for i,v in ipairs(self.rankConf) do
		if checkint(v.rankTypes) == checkint(rankType) then
			index = i
		end
	end
	return index
end

function Anniversary19RankMediator:EnterLayer()
    self:SendSignal(POST.ANNIVERSARY2_RANK.cmdName)
end
function Anniversary19RankMediator:OnRegist(  )
    regPost(POST.ANNIVERSARY2_RANK)
    self:EnterLayer()
end

function Anniversary19RankMediator:OnUnRegist(  )
    unregPost(POST.ANNIVERSARY2_RANK)

	local scene = uiMgr:GetCurrentScene()
	scene:RemoveDialog(self:GetViewComponent())
    -- timerMgr:RemoveTimer(NAME)
end
return Anniversary19RankMediator
