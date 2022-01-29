--[[
庆典排行榜Mediator
--]]
local Mediator = mvc.Mediator

local CastleRankMediator = class("CastleRankMediator", Mediator)

local NAME = "Game.mediator.castle.CastleRankMediator"

local uiMgr     = app.uiMgr
local gameMgr   = app.gameMgr
local cardMgr   = app.cardMgr
local timerMgr  = app.timerMgr

local RankTabCell      = require('home.NewRankCell')
local RankTabChildCell = require('Game.views.summerActivity.carnie.CarnieRankChildCell')
-- local RankCell         = require('home.RankPopularityCell')
local CarnieRankCell   = require('Game.views.summerActivity.carnie.CarnieRankCell')

local RANK_TYPES = {
    DAMAGE        = -5,
}
local PLAYER_RANK_LIST_FIELD_NAME = {
    [RANK_TYPES.DAMAGE] = 'rank',
}

local MY_RANK_FIELD_NAME = {
    [RANK_TYPES.DAMAGE] = 'myRank',
}

local RANK_REWARDS_CONF_NAME = {
    [RANK_TYPES.DAMAGE] = 'damageRankRewards',
}

local RANK = {
	{name = app.activityMgr:GetCastleText(__('累计伤害榜')), rankTypes = RANK_TYPES.DAMAGE},
}

local RES_DICT = {
    RANK_BTN_TAB_SELECT      = app.activityMgr:CastleResEx('ui/home/rank/rank_btn_tab_select.png'),
    RANK_BTN_TAB_DEFAULT     = app.activityMgr:CastleResEx('ui/home/rank/rank_btn_tab_default.png'),
    RANK_BTN_2_SELECT        = app.activityMgr:CastleResEx('ui/home/rank/rank_btn_2_select.png'),
    RANK_BTN_2_DEFAULT       = app.activityMgr:CastleResEx('ui/home/rank/rank_btn_2_default.png'),
    VOUCHER_ICON = app.activityMgr:CastleResEx('arts/goods/goods_icon_880164.png'),
    -- ANNI_ICO_POINT           = app.activityMgr:CastleResEx('ui/anniversary/rewardPreview/anni_ico_point.png'),
}

local RANK_SCORE_ICON_PATH = {
    -- [RANK_TYPES.DAMAGE]     = RES_DICT.VOUCHER_ICON,
}

function CastleRankMediator:ctor(params, viewComponent)
	self.super:ctor(NAME,viewComponent)
    self.ctorArgs_ = checktable(params)
    self.selectedRankType = params.selectedRankType or RANK_TYPES.DAMAGE
    self.rankServerDatas = {}
    self.selectedRankData = {}
    self.rankAllDatas = {}
end

function CastleRankMediator:InterestSignals()
	local signals = {
        -- POST.SPRING_ACTIVITY_RANK.sglName,

        COUNT_DOWN_ACTION,
	}
	return signals
end

function CastleRankMediator:ProcessSignal( signal )
	local name = signal:GetName()
    
    local data = signal:GetBody() or {}
    if name == POST.SPRING_ACTIVITY_RANK.sglName then
        self.rankServerDatas = data
        self.rankAllDatas = {}
        self:OnClickTabButtonAction(self.selectedRankType)
    elseif name == COUNT_DOWN_ACTION then
        local timerName = data.timerName
		if timerName == 'COUNT_DOWN_TAG_ANNIVERSARY' then
            -- local countdown = data.countdown
            -- local viewData = self:GetViewData()
            -- local timeNum = viewData.timeNum
            -- local timeLabel = viewData.timeLabel
            -- timeNum:setString(CommonUtils.getTimeFormatByType(countdown, 2))
            -- timeLabel:setVisible(countdown > 86400)
            -- timeLabel:setPositionX(50 + display.getLabelContentSize(viewData.endLabel).width + timeNum:getContentSize().width)
		end
	end
end

function CastleRankMediator:Initial( key )
	self.super.Initial(self,key)
    self.ownerScene_ = uiMgr:GetCurrentScene()
    
    local viewComponent  = require( 'Game.views.summerActivity.carnie.CarnieRankView' ).new()
	self:SetViewComponent(viewComponent)
    viewComponent:setPosition(display.center)
    viewComponent.viewData.scoreIcon:setVisible(false)

    self:GetOwnerScene():AddDialog(viewComponent)

    self.viewData_ = viewComponent.viewData
    
    self:InitDatas()
    self:InitView()
end

function CastleRankMediator:InitDatas()
    self.rankServerDatas = self.ctorArgs_.datas
    self.rankAllDatas = {}
    
end

--[[
根据rankType初始化排行榜签数据
--]]
function CastleRankMediator:InitRankDataByRankType(rankType)
    if self.rankAllDatas[rankType] then return end
    
    local rankDatas = self:GetRankListByRankType(rankType)
    if rankDatas == nil or next(rankDatas) == nil then return end
    
    for i, rankData in ipairs(rankDatas) do
        rankData.playerDamage = rankData.playerMaxDamage
        rankData.playerCards = table.values(rankData.playerCards) or {}
    end

    self.rankAllDatas[rankType] = {
        rankDatas = rankDatas,
    }
end
-- --[[
-- 初始化每个排行榜的数据
-- --]]
-- function CastleRankMediator:InitAllRankData()

-- end

--[[
初始化页面
--]]
function CastleRankMediator:InitView()
    local viewData  = self:GetViewData()
    local tabNameLabel = viewData.tabNameLabel
    display.commonLabelParams(tabNameLabel, {reqW =260,   text = app.activityMgr:GetCastleText(__('破败古堡排行榜'))})

    local backBtn   = viewData.backBtn
    display.commonUIParams(backBtn, {cb = handler(self, self.OnClickBackBtnAction), animate = false})

    local rewardBtn = viewData.rewardBtn
    display.commonUIParams(rewardBtn, {cb = handler(self, self.OnClickRewardBtnAction)})

    local gridView  = viewData.gridView
    gridView:setDataSourceAdapterScriptHandler(handler(self, self.RankDataSource))

    viewData.timeLabel:setVisible(false)

    -- local rankLayout = viewData.rankLayout
    -- local rankStageLabel = display.newLabel(300, 35, {fontSize = 22, color = '#ba5c5c', ap = display.LEFT_CENTER})
    -- rankLayout:addChild(rankStageLabel, 10)
    -- viewData.rankStageLabel = rankStageLabel
    -- rankStageLabel:setVisible(false)

    self:InitExpandableListView()

    self:OnClickTabButtonAction(self.selectedRankType)
end

--[[
初始化expandableListView
--]]
function CastleRankMediator:InitExpandableListView()
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


function CastleRankMediator:RefreshExpandableListView()
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

function CastleRankMediator:RefreshPlayerRankInfo()
    local viewData        = self:GetViewData()
    
    local scoreIcon       = viewData.scoreIcon
    local iconPath        = RANK_SCORE_ICON_PATH[self.selectedRankType]
    if iconPath then
        scoreIcon:setTexture(iconPath)
    end
    scoreIcon:setVisible(iconPath ~= nil)

    local myRankData      = self:GetMyRankDataByRankType(self.selectedRankType)
    local scoreNum        = viewData.scoreNum
    scoreNum:setPositionX(1000)
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
            rankBg:setTexture(app.activityMgr:CastleResEx('ui/home/rank/restaurant_info_bg_rank_num' .. tostring(rank) .. '.png'))
        else
            rankBg:setVisible(false)
        end
    end

    -- local rangeId         = checkint(myRankData.rangeId)
    -- local rankStageLabel  = viewData.rankStageLabel
    -- if rangeId > 0 then
    --     local playerName   = viewData.playerName
    --     local playerNameSize = display.getLabelContentSize(playerName)
    --     local rewardsDatas = self:GetRankConfDataByRankType(self.selectedRankType)
    --     local rewardsData = rewardsDatas[tostring(rangeId)] or {}
    --     display.commonLabelParams(rankStageLabel, {text = string.format(app.activityMgr:GetCastleText(__('当前阶段：%s')), tostring(rewardsData.name))})
    --     rankStageLabel:setPositionX(playerName:getPositionX() + playerNameSize.width + 20)
    --     rankStageLabel:setVisible(true)
    -- else
    --     rankStageLabel:setVisible(false)
    -- end
end

function CastleRankMediator:RefreshGridView()
    local selectedRankData = self:GetRankDataByRankType(self.selectedRankType)
    local gridView = self:GetViewData().gridView
    local rankDatas = selectedRankData.rankDatas or {}
    gridView:setCountOfCell(#rankDatas)
    gridView:reloadData()
end

--==============================--
--@desc: 更新排行榜一级tab背景
--@params expandableNode userdata 一级tab
--@params isSelect  bool  是否选择
--@return
--==============================--
function CastleRankMediator:UpdateRankTabCellBg(expandableNode, isSelect)
    local button = expandableNode.button
    local imgPath = self:GetTabNodeBg(isSelect)
    button:setNormalImage(imgPath)
    button:setSelectedImage(imgPath)
end

--==============================--
--@desc: 更新排行榜二级tab背景
--@params item      userdata 二级tab
--@params isSelect  bool  是否选择
--@return
--==============================--
function CastleRankMediator:UpdateTabNodeItemBg(item, isSelect)
    local button = item.bgBtn
    local imgPath = self:GetTabNodeItemBg(isSelect)
    button:setNormalImage(imgPath)
    button:setSelectedImage(imgPath)
end

--[[
排行榜数据处理
--]]
function CastleRankMediator:RankDataSource( p_convertview, idx )
	local pCell = p_convertview
    local index = idx + 1
    local cSize = cc.size(1035, 112)
    if pCell == nil then
        pCell = CarnieRankCell.new(cSize)
        pCell.scoreIcon:setVisible(false)
        display.commonUIParams(pCell.avatarIcon, {cb = handler(self, self.OnClickPlayerHeadAction), animate = false})
        display.commonUIParams(pCell.searchBtn, {cb = handler(self, self.OnClickSrarchButtonAction)})
    end
    xTry(function()
        local selectedRankData = self:GetRankDataByRankType(self.selectedRankType)
        local rankDatas = selectedRankData.rankDatas or {}
        local rankData  = rankDatas[index]
        if rankData then
            local scoreIcon = pCell.scoreIcon
            local iconPath = RANK_SCORE_ICON_PATH[self.selectedRankType]
            if iconPath then
                scoreIcon:setTexture(iconPath)
                pCell.scoreNum:setPositionX(cSize.width - 80)
            else
                pCell.scoreNum:setPositionX(cSize.width - 38)
            end
            scoreIcon:setVisible(iconPath ~= nil)

            pCell.avatarIcon:RefreshSelf({level = rankData.playerLevel, avatar = rankData.playerAvatar, avatarFrame = rankData.playerAvatarFrame})

            display.commonLabelParams(pCell.nameLabel, {text = tostring(rankData.playerName)})
            display.commonLabelParams(pCell.scoreNum,  {text = tostring(rankData.playerScore)})

            local playerRank = checkint(rankData.playerRank)
            display.commonLabelParams(pCell.rankNum,  {text = playerRank})
            if playerRank >= 1 and playerRank <= 3 then
                pCell.rankBg:setVisible(true)
                pCell.rankBg:setTexture(app.activityMgr:CastleResEx('ui/home/rank/restaurant_info_bg_rank_num' .. tostring(playerRank) .. '.png'))
            else
                pCell.rankBg:setVisible(false)
            end

            pCell.avatarIcon:setTag(index)
            pCell.searchBtn:setTag(index)
        end

	end,__G__TRACKBACK__)
    return pCell
end

function CastleRankMediator:OnClickTabButtonAction(sender)
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

function CastleRankMediator:OnClickRewardBtnAction(sender)
    PlayAudioByClickNormal()

    local rewardsDatas = nil 
    local title = nil 
    if self.selectedRankType == RANK_TYPES.DAMAGE then
        title = app.activityMgr:GetCastleText(__('累计伤害总排行奖励'))
    end
    rewardsDatas = self:GetRankConfDataByRankType(self.selectedRankType)
    local scene = self:GetOwnerScene()
    if not rewardsDatas or next(rewardsDatas) == nil or scene == nil then return end

    local rewardListView  = require( 'Game.views.LobbyRewardListView' ).new({tag = 1200, mediatorName = NAME, showTips = true, showConfDefName = false, rewardsDatas = rewardsDatas, title = title})
    rewardListView:setPosition(display.center)
    rewardListView:setTag(1200)
    scene:AddDialog(rewardListView)
end

function CastleRankMediator:OnClickPlayerHeadAction(sender)
    PlayAudioByClickNormal()
    local index = sender:getTag()
    local selectedRankData = self:GetRankDataByRankType(self.selectedRankType)
    local rankDatas = selectedRankData.rankDatas or {}
    local rankData  = rankDatas[index]
    if rankData then
        uiMgr:AddDialog('common.PlayerHeadPopup', {playerId = rankData.playerId, type = CommonUtils.GetHeadPopupTypeByPlayerId(rankData.playerId)})
    end
end

function CastleRankMediator:OnClickSrarchButtonAction(sender)
    PlayAudioByClickNormal()
    local tag = sender:getTag()
    local selectedRankData = self:GetRankDataByRankType(self.selectedRankType)
    local rankDatas = selectedRankData.rankDatas or {}
    local rankData = rankDatas[tag] or {}
    
    local view = require('Game.views.worldboss.WorldBossManualPlayerCardShowView').new({playerInfo = rankDatas[tag], title = app.activityMgr:GetCastleText(__('他（她）的阵容'))})
    display.commonUIParams(view,{po = display.center, ap = display.CENTER})
    self:GetOwnerScene():AddDialog(view)
end

function CastleRankMediator:OnClickBackBtnAction()
    PlayAudioByClickClose()
    
    app:UnRegsitMediator(NAME)
end

--==============================--
--@desc: 获得排行榜一级节点背景图
--@params isSelect  bool   是否选择
--@return imgPath string 背景图
--==============================--
function CastleRankMediator:GetTabNodeBg(isSelect)
    return isSelect and RES_DICT.RANK_BTN_TAB_SELECT or RES_DICT.RANK_BTN_TAB_DEFAULT
end

--==============================--
--@desc: 获得排行榜二级节点背景图
--@params isSelect  bool  是否选择
--@return imgPath string 背景图
--==============================--
function CastleRankMediator:GetTabNodeItemBg(isSelect)
    return isSelect and RES_DICT.RANK_BTN_2_SELECT or RES_DICT.RANK_BTN_2_DEFAULT
end

--==============================--
--@desc: 通过排行榜类型获取排行榜数据
--@params rankType  int  排行类型
--@return rankData  table 排行榜数据
--==============================--
function CastleRankMediator:GetRankListByRankType(rankType)
    return self.rankServerDatas[self:GetRankListFieldNameByRankType(rankType)] or {}
end

--==============================--
--@desc: 通过排行榜类型获取我的排行榜数据
--@params rankType    int   排行类型
--@return myRankData  table 我的排行榜数据
--==============================--
function CastleRankMediator:GetMyRankDataByRankType(rankType)
    return self.rankServerDatas[self:GetMyRankFieldNameByRankType(rankType)] or {}
end

--==============================--
--@desc: 通过排行榜类型获取排行榜配表数据
--@params rankType    int   排行类型
--@return rankConfData  table 排行榜配表数据
--==============================--
function CastleRankMediator:GetRankConfDataByRankType(rankType)
    return CommonUtils.GetConfigAllMess(self:GetRankConfNameByRankType(rankType), 'springActivity') or {}
end

--==============================--
--@desc: 通过排行榜类型获取排行榜配表名称
--@params rankType     int    排行类型
--@return rankConfName string 排行榜配表名称
--==============================--
function CastleRankMediator:GetRankConfNameByRankType(rankType)
    return RANK_REWARDS_CONF_NAME[rankType]
end

--==============================--
--@desc: 通过排行榜类型获取排行榜数据字段名称
--@params rankType          int    排行类型
--@return rankListFieldName string 排行榜数据字段名称
--==============================--
function CastleRankMediator:GetRankListFieldNameByRankType(rankType)
    return PLAYER_RANK_LIST_FIELD_NAME[rankType]
end

--==============================--
--@desc: 通过排行榜类型获取我的排行榜数据字段名称
--@params rankType          int    排行类型
--@return rankListFieldName string 我的排行榜数据字段名称
--==============================--
function CastleRankMediator:GetMyRankFieldNameByRankType(rankType)
    return MY_RANK_FIELD_NAME[rankType]
end


function CastleRankMediator:GetViewData()
    return self.viewData_
end

function CastleRankMediator:GetOwnerScene()
    return self.ownerScene_
end

--==============================--
--@desc: 通过排行榜类型获取排行榜数据
--@params rankType  int    排行类型
--@return rankData  table 排行榜数据
--==============================--
function CastleRankMediator:GetRankDataByRankType(rankType)
    return self.rankAllDatas[rankType] or {}
end

function CastleRankMediator:EnterLayer()
    -- self:SendSignal(POST.SPRING_ACTIVITY_RANK.cmdName)
end

function CastleRankMediator:cleanupView()
    local viewComponent = self:GetViewComponent()
    if self.ownerScene_ and viewComponent and not tolua.isnull(viewComponent) then
        viewComponent:stopAllActions()
        self.ownerScene_:RemoveDialog(viewComponent)
        self.ownerScene_ = nil
    end
end

function CastleRankMediator:OnRegist(  )
    -- regPost(POST.SPRING_ACTIVITY_RANK)
    self:EnterLayer()
end

function CastleRankMediator:OnUnRegist(  )
    -- unregPost(POST.SPRING_ACTIVITY_RANK)
    self:cleanupView()
end
return CastleRankMediator
