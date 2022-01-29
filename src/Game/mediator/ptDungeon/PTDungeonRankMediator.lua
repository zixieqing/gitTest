--[[
    pt本排行榜Mediator
--]]
local Mediator = mvc.Mediator

local PTDungeonRankMediator = class("PTDungeonRankMediator", Mediator)

local NAME = "PTDungeonRankMediator"

local shareFacade = AppFacade.GetInstance()
local uiMgr = app.uiMgr
local gameMgr = app.gameMgr

function PTDungeonRankMediator:ctor( params, viewComponent )
    self.super:ctor(NAME,viewComponent)
    self.rankData = params.data or {} -- 所有排行数据
    self.ptId = tostring(params.ptId) or '1'

    self.selectedRankType = 1
end

function PTDungeonRankMediator:InterestSignals()
    local signals = {
        COUNT_DOWN_ACTION,
    }
    return signals
end

function PTDungeonRankMediator:ProcessSignal( signal )
    local name = signal:GetName()
    local body = checktable(signal:GetBody())
    if name == COUNT_DOWN_ACTION then
        local timerName = body.timerName
        if timerName == 'PTDungeon' then
            local leftSeconds = body.countdown
            self:UpdateCountDown( checkint(leftSeconds) )
        end
    end
end

function PTDungeonRankMediator:Initial( key )
    self.super.Initial(self,key)
    local scene = uiMgr:GetCurrentScene()
    local viewComponent  = require( 'Game.views.ptDungeon.PTDungeonRankView' ).new()
    self:SetViewComponent(viewComponent)
    viewComponent:setPosition(display.center)
    scene:AddDialog(viewComponent)
    viewComponent.viewData.backBtn:setOnClickScriptHandler(function ()
        PlayAudioByClickClose()
        shareFacade:UnRegsitMediator(NAME)
    end)
    viewComponent.viewData.rewardBtn:setOnClickScriptHandler(handler(self, self.RewardButtonCallback))
    viewComponent.viewData.gridView:setDataSourceAdapterScriptHandler(handler(self, self.RankDataSource))

    self:CreateTypeTabs()
    self:RankTypeButtonCallback(self.selectedRankType)

    self:UpdateCountDown( checkint(gameMgr:GetUserInfo().PTDungeonTimerActivityTime) )
end

function PTDungeonRankMediator:UpdateCountDown( countdown )
    local viewData = self.viewComponent.viewData
    if countdown <= 0 then
        viewData.timeNum:setVisible(false)
        viewData.timeLabel:setString(__('已结束'))
        viewData.timeLabel:setVisible(true)
        viewData.timeLabel:setPositionX(viewData.timeNum:getPositionX() + 10)
    else
        if checkint(countdown) <= 86400 then
            viewData.timeNum:setString(string.formattedTime(checkint(countdown),'%02i:%02i:%02i'))
            viewData.timeLabel:setVisible(false)
        else
            local day = math.floor(checkint(countdown)/86400)
            viewData.timeNum:setString(string.fmt('_day_',{_day_ = day}))
            viewData.timeLabel:setVisible(true)
            viewData.timeLabel:setPositionX(viewData.timeNum:getPositionX() + viewData.timeNum:getContentSize().width + 10)
        end
    end
end

function PTDungeonRankMediator:RankDataSource( p_convertview, idx )
    local pCell = p_convertview
    local index = idx + 1
    local cSize = cc.size(1035, 112)

    if pCell == nil then
        pCell = require('home.RankPTDungeonCell').new(cSize)
    end
    xTry(function()
        local datas = self.rankListData[index]
        pCell.rankNum:setString(datas.rank)
        pCell.avatarIcon:RefreshSelf({level = datas.playerLevel, avatar = datas.playerAvatar, avatarFrame = datas.playerAvatarFrame})
        pCell.nameLabel:setString(datas.playerName)
        pCell.scoreNum:setString(datas.score)
        pCell.avatarIcon:setTag(index)
        pCell.avatarIcon:setOnClickScriptHandler(function ( sender )
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
--[[
查看奖励按钮点击回调
--]]
function PTDungeonRankMediator:RewardButtonCallback( sender )
    local scene = uiMgr:GetCurrentScene()
    local rewardsDatas
    local title = ''
    if 1 == self.selectedRankType then
        rewardsDatas = CommonUtils.GetConfigAllMess('pointRankRewards', 'pt')[self.ptId]
        title = __('pt点数排行榜奖励')
    else
        rewardsDatas = CommonUtils.GetConfigAllMess('damageRankRewards', 'pt')[self.ptId]
        title = __('累计伤害排行榜奖励')
    end
    local LobbyRewardListView  = require( 'Game.views.LobbyRewardListView' ).new({tag = 1200, rewardsDatas = rewardsDatas, title = title, showConfDefName = true})
    LobbyRewardListView:setTag(1200)
    LobbyRewardListView:setPosition(display.center)
    scene:AddDialog(LobbyRewardListView)
end

function PTDungeonRankMediator:CreateTypeTabs()
    local viewData = self:GetViewComponent().viewData
    viewData.expandableListView:removeAllExpandableNodes()
    local size = cc.size(212, 90)
    local expandableNode = require('home.PTDungeonRankTypeCell').new(size)
    expandableNode.buttonLayout:setOnClickScriptHandler(handler(self, self.RankTypeButtonCallback))
    display.commonLabelParams(expandableNode.nameLabel , {reqW = 200 ,text = __('pt点数排行榜')  })
    viewData.expandableListView:insertExpandableNodeAtLast(expandableNode)
    expandableNode.buttonLayout:setTag(1)

    local expandableDamageNode = require('home.PTDungeonRankTypeCell').new(size)
    expandableDamageNode.buttonLayout:setOnClickScriptHandler(handler(self, self.RankTypeButtonCallback))
    display.commonLabelParams(expandableDamageNode.nameLabel , { reqW = 200, text = __('累计伤害排行榜') })
    viewData.expandableListView:insertExpandableNodeAtLast(expandableDamageNode)
    expandableDamageNode.buttonLayout:setTag(2)

    viewData.expandableListView:reloadData()
end

function PTDungeonRankMediator:RankTypeButtonCallback( sender )
    if tolua.type(sender) == 'ccw.CButton' then
        PlayAudioByClickNormal()
    end
    local rankTypes = nil
    if type(sender) == 'number' then
        rankTypes = sender
    else
        rankTypes = sender:getTag()
        if rankTypes == self.selectedRankType then return end
    end
    self.selectedRankType = rankTypes
    local viewData = self:GetViewComponent().viewData
    for i = 1, 2 do
        local v = viewData.expandableListView:getExpandableNodeAtIndex(i-1)
        if i ~= self.selectedRankType then
            v.unselectedImg:setVisible(true)
            v.selectedImg:setVisible(false)
        else
            v.unselectedImg:setVisible(false)
            v.selectedImg:setVisible(true)
        end
    end
    
    local viewData = self:GetViewComponent().viewData
    if 1 == rankTypes then
        self.rankListData = self.rankData.pointRank
        self:ShowMyRank(self.rankData.myPointRank, self.rankData.myPoint)
    else
        self.rankListData = self.rankData.damageRank
        self:ShowMyRank(self.rankData.myDamageRank, self.rankData.myDamage)
    end
    viewData.gridView:setCountOfCell(#self.rankListData)
    viewData.gridView:reloadData()

    viewData.expandableListView:reloadData()
end

function PTDungeonRankMediator:ShowMyRank(myRank, myScore)
    local viewData = self:GetViewComponent().viewData

    local scoreNum = viewData.scoreNum
    local playerRankLabel = viewData.playerRankLabel
    local rankBg = viewData.rankBg
    local playerRankNum = viewData.playerRankNum
    if (not myRank and not myScore) or 0 == checkint(myRank) then
        playerRankLabel:setString(__('未入榜'))
        rankBg:setVisible(false)
        playerRankNum:setString('')
    else
        if checkint(myRank) >= 1 and checkint(myRank) <= 3 then
            rankBg:setVisible(true)
            rankBg:setTexture(_res('ui/home/rank/restaurant_info_bg_rank_num' .. tostring(myRank) .. '.png'))
        else
            rankBg:setVisible(false)
        end
        playerRankNum:setString(myRank)
        playerRankLabel:setString('')
    end
    scoreNum:setString(tostring(checkint(myScore)))
end

function PTDungeonRankMediator:OnRegist(  )
end

function PTDungeonRankMediator:OnUnRegist(  )
    local scene = uiMgr:GetCurrentScene()
    scene:RemoveDialog(self:GetViewComponent())
end

return PTDungeonRankMediator
