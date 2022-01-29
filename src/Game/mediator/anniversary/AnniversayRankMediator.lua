--[[
庆典排行榜Mediator
--]]
local Mediator = mvc.Mediator

local AnniversayRankMediator = class("AnniversayRankMediator", Mediator)

local NAME = "anniversary.AnniversayRankMediator"

local uiMgr     = app.uiMgr
local gameMgr   = app.gameMgr
local cardMgr   = app.cardMgr
local timerMgr  = app.timerMgr

local RankTabCell      = require('home.NewRankCell')
local RankTabChildCell = require('Game.views.summerActivity.carnie.CarnieRankChildCell')

local RankCell         = require('home.RankPopularityCell')

local ANNIVERSAY_RANK_TYPES = {
    MARKET           = -1,
    TOTAL_MARKET     = -2,
    DAILY_MARKET     = -3,
    YESTERDAY_MARKET = -4,
    CHALLENGE        = -5,
}
local RANK = {
	{name = app.anniversaryMgr:GetPoText(__('庆典积分榜')), rankTypes = ANNIVERSAY_RANK_TYPES.CHALLENGE},
	{name = app.anniversaryMgr:GetPoText(__('摊位排行榜')), rankTypes = ANNIVERSAY_RANK_TYPES.MARKET, child = {
        {name = app.anniversaryMgr:GetPoText(__('总排行榜')),   rankTypes = ANNIVERSAY_RANK_TYPES.TOTAL_MARKET},
        {name = app.anniversaryMgr:GetPoText(__('今日排行榜')), rankTypes = ANNIVERSAY_RANK_TYPES.DAILY_MARKET},
        {name = app.anniversaryMgr:GetPoText(__('昨日排行榜')), rankTypes = ANNIVERSAY_RANK_TYPES.YESTERDAY_MARKET},
    }},
}

local RES_DICT = {
    RANK_BTN_TAB_SELECT      = app.anniversaryMgr:GetResPath('ui/home/rank/rank_btn_tab_select.png'),
    RANK_BTN_TAB_DEFAULT     = app.anniversaryMgr:GetResPath('ui/home/rank/rank_btn_tab_default.png'),
    RANK_BTN_2_SELECT        = app.anniversaryMgr:GetResPath('ui/home/rank/rank_btn_2_select.png'),
    RANK_BTN_2_DEFAULT       = app.anniversaryMgr:GetResPath('ui/home/rank/rank_btn_2_default.png'),
    ANNIVERSARY_VOUCHER_ICON = app.anniversaryMgr:GetResPath(string.format('arts/goods/goods_icon_%s.png', tostring(app.anniversaryMgr:GetIncomeCurrencyID()))),
    ANNI_ICO_POINT           = app.anniversaryMgr:GetResPath('ui/anniversary/rewardPreview/anni_ico_point.png'),
}

local PLAYER_RANK_LIST_FIELD_NAME = {
    [ANNIVERSAY_RANK_TYPES.TOTAL_MARKET] = 'totalMarketRank',
    [ANNIVERSAY_RANK_TYPES.DAILY_MARKET] = 'dailyMarketRank',
    [ANNIVERSAY_RANK_TYPES.YESTERDAY_MARKET] = 'yesterdayRank',
    [ANNIVERSAY_RANK_TYPES.CHALLENGE] = 'challengeRank',
}

local MY_RANK_FIELD_NAME = {
    [ANNIVERSAY_RANK_TYPES.TOTAL_MARKET] = 'myTotalMarketRank',
    [ANNIVERSAY_RANK_TYPES.DAILY_MARKET] = 'myDailyMarketRank',
    [ANNIVERSAY_RANK_TYPES.YESTERDAY_MARKET] = 'myYesterdayMarketRank',
    [ANNIVERSAY_RANK_TYPES.CHALLENGE] = 'myChallengeRank',
}

local RANK_REWARDS_CONF_NAME = {
    [ANNIVERSAY_RANK_TYPES.TOTAL_MARKET]     = 'marketTotalRankRewards',
    [ANNIVERSAY_RANK_TYPES.DAILY_MARKET]     = 'marketDailyRankRewards',
    [ANNIVERSAY_RANK_TYPES.YESTERDAY_MARKET] = 'marketDailyRankRewards',
    [ANNIVERSAY_RANK_TYPES.CHALLENGE]        = 'challengeRankRewards',
}

local RANK_SCORE_ICON_PATH = {
    [ANNIVERSAY_RANK_TYPES.TOTAL_MARKET]     = RES_DICT.ANNIVERSARY_VOUCHER_ICON,
    [ANNIVERSAY_RANK_TYPES.DAILY_MARKET]     = RES_DICT.ANNIVERSARY_VOUCHER_ICON,
    [ANNIVERSAY_RANK_TYPES.YESTERDAY_MARKET] = RES_DICT.ANNIVERSARY_VOUCHER_ICON,
    [ANNIVERSAY_RANK_TYPES.CHALLENGE]        = RES_DICT.ANNI_ICO_POINT,
}

function AnniversayRankMediator:ctor(params, viewComponent)
	self.super:ctor(NAME,viewComponent)
    local params = params or {}
    self.selectedRankType = params.selectedRankType or ANNIVERSAY_RANK_TYPES.TOTAL_MARKET
    self.rankServerDatas = {}
    self.selectedRankData = {}
    self.rankAllDatas = {}
end

function AnniversayRankMediator:InterestSignals()
	local signals = {
        POST.ANNIVERSARY_RANK.sglName,

        COUNT_DOWN_ACTION,
	}
	return signals
end

function AnniversayRankMediator:ProcessSignal( signal )
	local name = signal:GetName()
    
    local data = signal:GetBody() or {}
    if name == POST.ANNIVERSARY_RANK.sglName then
        self.rankServerDatas = data
        self.rankAllDatas = {}
        self:OnClickTabButtonAction(self.selectedRankType)
    elseif name == COUNT_DOWN_ACTION then
        local timerName = data.timerName
		if timerName == 'COUNT_DOWN_TAG_ANNIVERSARY' then
            local countdown = data.countdown
            local viewData = self:GetViewData()
            local timeNum = viewData.timeNum
            local timeLabel = viewData.timeLabel
            local dayStr =  CommonUtils.getTimeFormatByType(countdown, 2)
            dayStr = string.match(dayStr ,  "%d+")
            timeNum:setString(dayStr)
            timeLabel:setVisible(countdown > 86400)
            timeLabel:setPositionX(50 + display.getLabelContentSize(viewData.endLabel).width + timeNum:getContentSize().width)
		end
	end
end

function AnniversayRankMediator:Initial( key )
	self.super.Initial(self,key)
    self.ownerScene_ = uiMgr:GetCurrentScene()
    
	local viewComponent  = require( 'Game.views.summerActivity.carnie.CarnieRankView' ).new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
    self:GetOwnerScene():AddDialog(viewComponent)

    self.viewData_ = viewComponent.viewData
    
    self:InitView()
end
--[[
根据rankType初始化排行榜签数据
--]]
function AnniversayRankMediator:InitRankDataByRankType(rankType)
    if self.rankAllDatas[rankType] then return end
    
    local rankDatas = self:GetRankListByRankType(rankType)
    if next(rankDatas) == nil then return end
    local playerId = checkint(gameMgr:GetUserInfo().playerId)

    local checkIsSelf = function (rankData)
        return checkint(rankData.playerId) == playerId
    end

    local priorityFunc = function (rankData)
        return checkIsSelf(rankData) and 1 or 0
    end


    local playerData = {}
    table.sort(rankDatas, function (a, b)
        if a == nil then return true end
        if b == nil then return false end

        local aRank = checkint(a.playerRank)
        local bRank = checkint(b.playerRank)
        
        if checkIsSelf(a) and next(playerData) == nil then
            playerData = a
        end

        if checkIsSelf(b) and next(playerData) == nil then
            playerData = b
        end

        if aRank == bRank then
            return priorityFunc(a) > priorityFunc(b)
        end
        return aRank < bRank
    end)

    self.rankAllDatas[rankType] = {
        rankDatas = rankDatas,
        myScore   = checkint(playerData.playerScore),
        myRank    = checkint(playerData.playerRank),
    }
end
-- --[[
-- 初始化每个排行榜的数据
-- --]]
-- function AnniversayRankMediator:InitAllRankData()

-- end

--[[
初始化页面
--]]
function AnniversayRankMediator:InitView()
    local viewData  = self:GetViewData()
    local tabNameLabel = viewData.tabNameLabel
    display.commonLabelParams(tabNameLabel, {text = app.anniversaryMgr:GetPoText(__('庆典排行榜'))})

    local backBtn   = viewData.backBtn
    display.commonUIParams(backBtn, {cb = handler(self, self.OnClickBackBtnAction)})

    local rewardBtn = viewData.rewardBtn
    display.commonUIParams(rewardBtn, {cb = handler(self, self.OnClickRewardBtnAction)})

    local gridView  = viewData.gridView
    gridView:setDataSourceAdapterScriptHandler(handler(self, self.RankDataSource))

    viewData.timeLabel:setVisible(false)

    local rankLayout = viewData.rankLayout
    local rankStageLabel = display.newLabel(300, 35, {fontSize = 22, color = '#ba5c5c', ap = display.LEFT_CENTER})
    rankLayout:addChild(rankStageLabel, 10)
    viewData.rankStageLabel = rankStageLabel
    rankStageLabel:setVisible(false)

    self:InitExpandableListView()
end

--[[
初始化expandableListView
--]]
function AnniversayRankMediator:InitExpandableListView()
	local viewData  = self:GetViewData()
    local expandableListView = viewData.expandableListView
	-- 添加类别
	for i,v in ipairs(RANK) do
		local size = cc.size(212, 90)
		local expandableNode = RankTabCell.new(size)
		expandableNode.button:setOnClickScriptHandler(handler(self, self.OnClickTabButtonAction))
		expandableNode.button:setUserTag(v.rankTypes)
		expandableNode.nameLabel:setString(v.name)
		-- 判断是否被选中
		if self.selectedRankType == v.rankTypes then
			self:UpdateRankTabCellBg(expandableNode, true)
			if v.child then
				self.selectedRankType = v.child[1].rankTypes
			end
		end
        expandableListView:insertExpandableNodeAtLast(expandableNode)
        if v.child and next(v.child) ~= nil then
            expandableNode.arrowIcon:setVisible(false)
            for _, childData in ipairs(v.child) do
                local childSize = cc.size(size.width, 64)
                local childNode = RankTabChildCell.new(childSize)
                childNode.bgBtn:setOnClickScriptHandler(handler(self, self.OnClickTabButtonAction))
                childNode.bgBtn:setUserTag(childData.rankTypes)
                display.commonLabelParams(childNode.bgBtn, fontWithColor(14, {text = childData.name}))
                expandableNode:insertItemNodeAtLast(childNode)
            end
        end
	end
    expandableListView:reloadData()
end

function AnniversayRankMediator:RefreshExpandableListView()
    local viewData = self:GetViewComponent().viewData
    local expandableListView = viewData.expandableListView
    for i,v in ipairs(RANK) do
        local expandableNode = expandableListView:getExpandableNodeAtIndex(i - 1)
        if expandableNode then
		    -- 判断是否被选中
		    if self.selectedRankType == v.rankTypes then
		    	self:UpdateRankTabCellBg(expandableNode, true)
            else
		    	self:UpdateRankTabCellBg(expandableNode, false)
		    end
		    -- 判断是否有子页签
            if v.child and next(v.child) ~= nil then
                local isSelected = false
		    	-- 判断子页签是否被选中
                for index, child in ipairs(v.child) do
                    local node = expandableNode:getItemNodeAtIndex(index - 1)
                    if child.rankTypes == self.selectedRankType then
                        self:UpdateTabNodeItemBg(node, true)
                        isSelected = true
                    else
                        self:UpdateTabNodeItemBg(node, false)
		    		end
                end
                if isSelected then
                    expandableNode:setExpanded(true)
                    self:UpdateRankTabCellBg(expandableNode, true)
                    -- expandableNode.arrowIcon:setRotation(0)
                else
                    expandableNode:setExpanded(false)
                    -- expandableNode.arrowIcon:setRotation(270)
                end
		    end
        end
    end
    expandableListView:reloadData()
end

function AnniversayRankMediator:RefreshPlayerRankInfo()
    local viewData        = self:GetViewData()
    
    local scoreIcon       = viewData.scoreIcon
    local iconPath        = RANK_SCORE_ICON_PATH[self.selectedRankType]
    scoreIcon:setTexture(iconPath)
    
    local myRankData      = self:GetMyRankDataByRankType(self.selectedRankType)
    local scoreNum        = viewData.scoreNum
    display.commonLabelParams(scoreNum, {text = checkint(myRankData.score)})

    local rank            = checkint(myRankData.rank)
    local playerRankLabel = viewData.playerRankLabel
    local rankBg          = viewData.rankBg
    local playerRankNum   = viewData.playerRankNum
    if rank == 0 then
        playerRankLabel:setVisible(true)
        rankBg:setVisible(false)
        playerRankNum:setVisible(false)
    else
        playerRankLabel:setVisible(false)
        playerRankNum:setVisible(true)
        display.commonLabelParams(playerRankNum, {text = rank})
        if rank >= 1 and rank <= 3 then
            rankBg:setVisible(true)
            rankBg:setTexture(app.anniversaryMgr:GetResPath('ui/home/rank/restaurant_info_bg_rank_num' .. tostring(rank) .. '.png'))
        else
            rankBg:setVisible(false)
        end
    end

    local rangeId         = checkint(myRankData.rangeId)
    local rankStageLabel  = viewData.rankStageLabel
    if rangeId > 0 then
        local playerName   = viewData.playerName
        local playerNameSize = display.getLabelContentSize(playerName)
        local rewardsDatas = self:GetRankConfDataByRankType(self.selectedRankType)
        local rewardsData = rewardsDatas[tostring(rangeId)] or {}
        display.commonLabelParams(rankStageLabel, {text = string.format(app.anniversaryMgr:GetPoText(__('当前阶段：%s')), tostring(rewardsData.name))})
        rankStageLabel:setPositionX(playerName:getPositionX() + playerNameSize.width + 20)
        rankStageLabel:setVisible(true)
    else
        rankStageLabel:setVisible(false)
    end
end

function AnniversayRankMediator:RefreshGridView()
    local selectedRankData = self:GetRankDataByRankType(self.selectedRankType)
    local gridView = self:GetViewData().gridView
    local rankDatas = selectedRankData.rankDatas or {}
    gridView:setCountOfCell(#rankDatas)
    gridView:reloadData()
end

function AnniversayRankMediator:UpdateRankTabCellBg(expandableNode, isSelect)
    local button = expandableNode.button
    local imgPath = self:GetTabNodeBg(isSelect)
    button:setNormalImage(imgPath)
    button:setSelectedImage(imgPath)
end

function AnniversayRankMediator:UpdateTabNodeItemBg(item, isSelect)
    local button = item.bgBtn
    local imgPath = self:GetTabNodeItemBg(isSelect)
    button:setNormalImage(imgPath)
    button:setSelectedImage(imgPath)
end

--[[
排行榜数据处理
--]]
function AnniversayRankMediator:RankDataSource( p_convertview, idx )
	local pCell = p_convertview
    local index = idx + 1
    local cSize = cc.size(1035, 112)
    if pCell == nil then
        pCell = RankCell.new(cSize)
        display.commonUIParams(pCell.avatarIcon, {cb = handler(self, self.OnClickPlayerHeadAction), animate = false})
    end
    xTry(function()
        local selectedRankData = self:GetRankDataByRankType(self.selectedRankType)
        local rankDatas = selectedRankData.rankDatas or {}
        local rankData  = rankDatas[index]
        if rankData then
            local iconPath = RANK_SCORE_ICON_PATH[self.selectedRankType]
            pCell.scoreIcon:setTexture(iconPath)
    
            pCell.avatarIcon:RefreshSelf({level = rankData.playerLevel, avatar = rankData.playerAvatar, avatarFrame = rankData.playerAvatarFrame})
            pCell.avatarIcon:setTag(index)

            display.commonLabelParams(pCell.nameLabel, {text = tostring(rankData.playerName)})
            display.commonLabelParams(pCell.scoreNum,  {text = tostring(rankData.playerScore)})

            local playerRank = checkint(rankData.playerRank)
            display.commonLabelParams(pCell.rankNum,  {text = playerRank})
            if playerRank >= 1 and playerRank <= 3 then
                pCell.rankBg:setVisible(true)
                pCell.rankBg:setTexture(app.anniversaryMgr:GetResPath('ui/home/rank/restaurant_info_bg_rank_num' .. tostring(playerRank) .. '.png'))
            else
                pCell.rankBg:setVisible(false)
            end
        end

	end,__G__TRACKBACK__)
    return pCell
end

function AnniversayRankMediator:OnClickTabButtonAction(sender)
    if tolua.type(sender) == 'ccw.CButton' then
        PlayAudioByClickNormal()
    end
	local rankTypes = nil
	if type(sender) == 'number' then
		rankTypes = sender
	else
		rankTypes = sender:getUserTag()
		if rankTypes == self.selectedRankType then return end
	end
	-- 判断此页签有没有子页签
	for i, v in ipairs(RANK) do
		if v.rankTypes == rankTypes then
			if v.child and next(v.child) ~= nil then
				rankTypes = v.child[1].rankTypes
			end
		end
	end
    self.selectedRankType = rankTypes
    self:InitRankDataByRankType(rankTypes)
    self:RefreshPlayerRankInfo()
    self:RefreshExpandableListView()
    self:RefreshGridView()
end

function AnniversayRankMediator:OnClickRewardBtnAction(sender)
    PlayAudioByClickNormal()

    local rewardsDatas = nil 
    local title = nil 
    if self.selectedRankType == ANNIVERSAY_RANK_TYPES.TOTAL_MARKET then
        title = app.anniversaryMgr:GetPoText(__('经营总排行奖励'))
    elseif self.selectedRankType == ANNIVERSAY_RANK_TYPES.DAILY_MARKET then
        title = app.anniversaryMgr:GetPoText(__('每日摊位排行奖励'))
    elseif self.selectedRankType == ANNIVERSAY_RANK_TYPES.YESTERDAY_MARKET then
        title = app.anniversaryMgr:GetPoText(__('昨日摊位排行奖励'))
    elseif self.selectedRankType == ANNIVERSAY_RANK_TYPES.CHALLENGE then
        title = app.anniversaryMgr:GetPoText(__('庆典积分排行奖励'))
    end
    rewardsDatas = self:GetRankConfDataByRankType(self.selectedRankType)
    
    local scene = self:GetOwnerScene()
    if not rewardsDatas or next(rewardsDatas) == nil or scene == nil then return end
    local rewardListView  = require( 'Game.views.LobbyRewardListView' ).new({tag = 1200, mediatorName = "CarnieRankMediator", showTips = true, showConfDefName = true, rewardsDatas = rewardsDatas, title = title})
    rewardListView:setPosition(display.center)
    rewardListView:setTag(1200)
    scene:AddDialog(rewardListView)
end

function AnniversayRankMediator:OnClickPlayerHeadAction(sender)
    local index = sender:getTag()
    local selectedRankData = self:GetRankDataByRankType(self.selectedRankType)
    local rankDatas = selectedRankData.rankDatas or {}
    local rankData  = rankDatas[index]
    if rankData then
        uiMgr:AddDialog('common.PlayerHeadPopup', {playerId = rankData.playerId, type = CommonUtils.GetHeadPopupTypeByPlayerId(rankData.playerId)})
    end
end

function AnniversayRankMediator:OnClickBackBtnAction()
    PlayAudioByClickClose()
    
    app:UnRegsitMediator(NAME)
end

function AnniversayRankMediator:GetTabNodeBg(isSelect)
    return isSelect and RES_DICT.RANK_BTN_TAB_SELECT or RES_DICT.RANK_BTN_TAB_DEFAULT
end

function AnniversayRankMediator:GetTabNodeItemBg(isSelect)
    return isSelect and RES_DICT.RANK_BTN_2_SELECT or RES_DICT.RANK_BTN_2_DEFAULT
end

function AnniversayRankMediator:GetRankListFieldNameByRankType(rankType)
    return PLAYER_RANK_LIST_FIELD_NAME[rankType]
end

function AnniversayRankMediator:GetMyRankFieldNameByRankType(rankType)
    return MY_RANK_FIELD_NAME[rankType]
end

function AnniversayRankMediator:GetRankListByRankType(rankType)
    return self.rankServerDatas[self:GetRankListFieldNameByRankType(rankType)] or {}
end

function AnniversayRankMediator:GetMyRankDataByRankType(rankType)
    return self.rankServerDatas[self:GetMyRankFieldNameByRankType(rankType)] or {}
end

function AnniversayRankMediator:GetRankDataByRankType(rankType)
    return self.rankAllDatas[rankType] or {}
end

function AnniversayRankMediator:GetRankConfNameByRankType(rankType)
    return RANK_REWARDS_CONF_NAME[rankType]
end

function AnniversayRankMediator:GetRankConfDataByRankType(rankType)
    return CommonUtils.GetConfigAllMess(self:GetRankConfNameByRankType(rankType), 'anniversary') or {}
end

function AnniversayRankMediator:GetViewData()
    return self.viewData_
end

function AnniversayRankMediator:GetOwnerScene()
    return self.ownerScene_
end

function AnniversayRankMediator:EnterLayer()
    self:SendSignal(POST.ANNIVERSARY_RANK.cmdName)
end

function AnniversayRankMediator:CleanupView()
    local viewComponent = self:GetViewComponent()
    local sence = self:GetOwnerScene()
    if sence and viewComponent and not tolua.isnull(viewComponent) then
        viewComponent:stopAllActions()
        sence:RemoveDialog(viewComponent)
        self.ownerScene_ = nil
    end
end

function AnniversayRankMediator:OnRegist(  )
    regPost(POST.ANNIVERSARY_RANK)
    self:EnterLayer()
end

function AnniversayRankMediator:OnUnRegist(  )
    unregPost(POST.ANNIVERSARY_RANK)
end
return AnniversayRankMediator
