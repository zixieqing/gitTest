--[[
 * author : kaishiqi
 * descpt : 新天成演武 - 排行榜中介者
]]
local Mediator = mvc.Mediator
---@class NewKofArenaRankMediator :Mediator
local NewKofArenaRankMediator = class("NewKofArenaRankMediator", Mediator)
local NAME = "NewKofArenaRankMediator"
---@type UIManager
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
---@type GameManager
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
---@type RankKOFCell
local RankKOFCell = require("home.RankKOFCell")
function NewKofArenaRankMediator:ctor( viewComponent )
    self.super:ctor(NAME, viewComponent)
    self.rankData = {}  -- 排行数据
    self.leftSecond = 0 -- 本周的剩余时间
    self.oneKofArenaRank = {}  -- 其中一个阶段的排名
    self.selectIndex = 1
end

local BUTTON_TAG = {
    LAST_WEEK_RANK_BTN = 1001 , -- 查看上周排行
    LOOK_REWARDS       = 1002 , -- 查看排行奖励
    BACK_BTN           = 1003 , -- 返回按钮
}

function NewKofArenaRankMediator:InterestSignals()
    local signals = {
        POST.NEW_RANK_KOF_ARE_NARANK.sglName 
    }
    return signals
end

function NewKofArenaRankMediator:ProcessSignal( signal )
    local body = signal:GetBody()
    local name = signal:GetName()
    if name == POST.NEW_RANK_KOF_ARE_NARANK.sglName  then
        self.rankData  = body
        self.leftSecond = body.newKofArenaRankLeftSeconds
        local myKofArenaSegment = checkint(self:GetMyKofArenaSegment())
        myKofArenaSegment = myKofArenaSegment == 0 and 1 or myKofArenaSegment
        self:SwitchOtherStageById(myKofArenaSegment)
        self:CountDownTimes()
        self:ListCellRunAction()
        self:UpdateLeftTimeLabel()
        self:UpdateMySelfLayout()
    end
end
--[[
    获取到排行数据
--]]
function NewKofArenaRankMediator:GetRankData()
    return self.rankData
end
--[[
    获取到上周的排行数据
--]]
function NewKofArenaRankMediator:GetLastRankData()
    local rankData = self.rankData
    return rankData.lastNewKofArenaRank
end
--[[
    获取到当前所属的单元
--]]
function NewKofArenaRankMediator:GetMyKofArenaSegment()
    local rankData = self:GetRankData() or {}
    local myKofArenaRank = checkint(rankData.myNewKofArenaSegment)
    return myKofArenaRank

end

--[[
    获取初始化积分
--]]
function NewKofArenaRankMediator:getInitScore()
    return checkint(CONF.NEW_KOF.BASE_PARMS:GetValue('initIntegral'))
end

function NewKofArenaRankMediator:Initial( key )
    self.super.Initial(self, key)
    ---@type KofArenaRankScene
    local viewComponent = require("Game.views.tagMatchNew.NewKofArenaRankScene").new()
    viewComponent:setPosition(display.center)
    uiMgr:GetCurrentScene():AddDialog(viewComponent)
    self:SetViewComponent(viewComponent)
    local viewData        = viewComponent.viewData
    local gridView        = viewData.gridView
    -- local rewardBtn       = viewData.rewardBtn
    local lastWeekRankBtn = viewData.lastWeekRankBtn
    local backBtn = viewData.backBtn
    -- display.commonUIParams(rewardBtn, { cb = handler(self, self.ButtonAction)})
    display.commonUIParams(lastWeekRankBtn, { cb = handler(self, self.ButtonAction)})
    display.commonUIParams(backBtn, { cb = handler(self, self.ButtonAction)})
    gridView:setDataSourceAdapterScriptHandler(handler(self, self.OnDataSource))
    self:InsertListViewCell()

end
--[[
    更新倒计时时间的显示
--]]
function NewKofArenaRankMediator:UpdateLeftTimeLabel()
    local leftSecond = self.leftSecond
    local viewData = self.viewComponent.viewData
    local leftTimeLabel = viewData.leftTimeLabel
    if checkint(leftSecond) >= 86400  then
        local days = math.ceil(leftSecond/86400)
        local scoreNum = cc.Label:createWithBMFont('font/common_num_1.fnt', '0')
        scoreNum:setString(tostring(days))
        local scoreNumSize = scoreNum:getContentSize()

        scoreNum:setPosition(scoreNumSize.width/2 - 5   , scoreNumSize.height/2 -2)
        local scoreLayout = display.newLayer(scoreNumSize.width/2 , scoreNumSize.height/2 ,{ size = cc.size(scoreNumSize.width , scoreNumSize.height)  })
        scoreLayout:addChild(scoreNum)

        display.reloadRichLabel(leftTimeLabel ,{ c= {
            fontWithColor('16',{text = __('本赛季剩余时间：')}),
            {node = scoreLayout },
            fontWithColor('16',{text = __('天')})
        }})
    else
        leftSecond = leftSecond > 0 and leftSecond or 0
        local str = string.toMinutesSecondsMilliseconds(leftSecond)
        display.reloadRichLabel(leftTimeLabel ,{ c= {
            fontWithColor('10',{fontSize = 24 , text = __('本赛季剩余时间：')}),
            fontWithColor('10',{fontSize = 24 , text = str})
        }})
    end
end
--[[
    更新自己的成绩显示
--]]
function NewKofArenaRankMediator:UpdateMySelfLayout()
    local arenaSegment = self:GetMyKofArenaSegment()
    local viewData = self.viewComponent.viewData
    local mySelfLayout = viewData.mySelfLayout
    mySelfLayout:setVisible(false)
    if arenaSegment ~= 0 and ( checkint(self.selectIndex) == arenaSegment ) then
        mySelfLayout:setVisible(true)
        local rankData = self:GetRankData()
        local myKofArenaRank    = checkint(rankData.myNewKofArenaRank)
        local myKofArenaScore   = checkint(rankData.myNewKofArenaScore) + checkint(self:getInitScore())
        local playerName        = gameMgr:GetUserInfo().playerName
        local winTimesLabel     = viewData.winTimesLabel
        local rankLabel         = viewData.rankLabel
        local rankImage         = viewData.rankImage
        local notRankLabel      = viewData.notRankLabel
        local playerNameLabel   = viewData.playerName
        rankLabel:setVisible(false)
        rankImage:setVisible(false)
        notRankLabel:setVisible(false)
        display.commonLabelParams(playerNameLabel , {text = playerName} )
        display.commonLabelParams(winTimesLabel , {text = string.format(__('积分 %d')  , myKofArenaScore) } )
        if myKofArenaRank > 0  then
            rankLabel:setVisible(true)
            rankLabel:setString(myKofArenaRank)
            if myKofArenaRank <=  3 then
                rankImage:setVisible(true)
                rankImage:setTexture(_res( string.format('ui/home/rank/restaurant_info_bg_rank_num%d.png' , myKofArenaRank)))
            end
        else
            notRankLabel:setVisible(true)
        end

    end
end


--[[
插入listview 的子项
--]]
function NewKofArenaRankMediator:InsertListViewCell()
    local levelSegmentConfig = CONF.NEW_KOF.SEGMENT:GetAll()
    local listCellSize = cc.size(250, 92)
    local viewData = self.viewComponent.viewData
    local listView  = viewData.listView
    local levelKeys ={}
    for i, v in pairs(levelSegmentConfig) do
        levelKeys[#levelKeys+1] = v.id
    end
    table.sort(levelKeys, function(a, b )
        if checkint(a) >= checkint(b) then
            return false
        end
        return true
    end)
    for ii, vv in pairs(levelKeys) do
        local v = levelSegmentConfig[tostring(vv)]
        local cellLayout =  display.newLayer(0,0,{size = listCellSize })
        local btn = display.newButton(listCellSize.width/2 , listCellSize.height/2 , {
            n = _res("ui/home/rank/rank_btn_tab_default.png"),
            s = _res("ui/home/rank/rank_btn_tab_select.png"),
            d = _res("ui/home/rank/rank_btn_tab_select.png")
        })
        btn:setName("rankBtn")
        btn:setOpacity(0)
        btn:setTag( checkint(v.id))
        display.commonUIParams(btn , {cb = handler(self, self.SwitchBtnClick)})
        display.commonLabelParams(btn, fontWithColor('14' , {text = v.name }))
        cellLayout:addChild(btn)
        listView:insertNodeAtLast(cellLayout)
    end
    listView:reloadData()
end
--[[
    进入动画
]]
function NewKofArenaRankMediator:ListCellRunAction()
    local viewData = self.viewComponent.viewData
    local listView  = viewData.listView
    local cellLayout = listView:getNodeAtIndex(0)
    if cellLayout and ( not tolua.isnull(cellLayout))  then
        local myKofArenaSegment = self:GetMyKofArenaSegment()
        if myKofArenaSegment ~=0   then
            self:AddMeInCellFlags(myKofArenaSegment)
        end
        local rankBtn = cellLayout:getChildByName("rankBtn")
        local rankBtnPos = cc.p(rankBtn:getPosition())
        local movePos = cc.p(rankBtnPos.x - 200 , rankBtnPos.y)
        rankBtn:setPosition(movePos)
        local spawn = {}
        local nodes = listView:getNodes()
        for i, v in pairs(nodes) do
            local rankBtn =  v:getChildByName("rankBtn")
            rankBtn:setPosition(movePos)
            spawn[#spawn+1] = cc.TargetedAction:create( rankBtn  ,
                cc.Sequence:create(cc.DelayTime:create(0.05 * (i-1) ) ,
                   cc.Spawn:create(
                           cc.FadeIn:create(0.2) ,
                           cc.MoveTo:create(0.2 , rankBtnPos)
                   ), cc.DelayTime:create(0.05 * (#nodes -(i - 1)  ) )
                )

            )
        end
        rankBtn:runAction(cc.Spawn:create(spawn))
    end
end
--[[
    添加自己所属cell 的标志
--]]
function NewKofArenaRankMediator:AddMeInCellFlags(myKofArenaSegment)
    local viewData = self.viewComponent.viewData
    local listView  = viewData.listView
    local cellLayout = listView:getNodeAtIndex(myKofArenaSegment -1)
    if cellLayout and (not tolua.isnull(cellLayout)) then
        local cellSize = cellLayout:getContentSize()
        local myHeadBg = display.newImageView(_res('ui/home/rank/3v3_bg_me'))
        local myHeadBgSize = myHeadBg:getContentSize()
        myHeadBg:setPosition(cc.p(myHeadBgSize.width/2 ,myHeadBgSize.height/2))
        local myHeadLayout = display.newLayer(cellSize.width -35  , cellSize.height/2 , {ap = display.CENTER ,size =  myHeadBgSize })
        cellLayout:addChild(myHeadLayout)

        myHeadLayout:addChild(myHeadBg)

        local myHeader = require('common.FriendHeadNode').new({
                                                                   enable = true, scale = 0.6, showLevel = true
                                                               })
        myHeader:RefreshSelf({level = gameMgr:GetUserInfo().level, avatar = gameMgr:GetUserInfo().avatar, avatarFrame = gameMgr:GetUserInfo().avatarFrame})
        myHeadLayout:addChild(myHeader)
        myHeader:setPosition(cc.p(myHeadBgSize.width/2+3.5 ,myHeadBgSize.height/2+1))
        myHeader:setScale(0.3)
        myHeadLayout:setOpacity(0)
        myHeadLayout:runAction(
            cc.Sequence:create(
                cc.FadeIn:create(0.2) ,
                cc.CallFunc:create(
                    function()
                        myHeadLayout:stopAllActions()
                        myHeadLayout:runAction(
                            cc.RepeatForever:create(
                                cc.Sequence:create(
                                    cc.EaseSineIn:create(cc.MoveBy:create(0.2, cc.p(5,0))) ,
                                    cc.EaseSineOut:create(cc.MoveBy:create(0.2, cc.p(-5,0)))
                                )
                            )
                        )

                    end
                )

            )
        )

    end

end

function NewKofArenaRankMediator:ButtonAction(sender)
    PlayAudioByClickNormal()
    local tag = sender:getTag()
    if tag == BUTTON_TAG.LOOK_REWARDS then
        self:LookRankReward()
    elseif tag == BUTTON_TAG.LAST_WEEK_RANK_BTN then
        self:LookLastWeekRank()
    elseif tag == BUTTON_TAG.BACK_BTN then
        self:GetFacade():UnRegsitMediator(NAME)
    end
end
--[[
    查看上周的排行榜
--]]
function NewKofArenaRankMediator:LookLastWeekRank()
    local myKofArenaSegment = self.selectIndex or 1
    local lastRankData = self:GetLastRankOneDatabyId(myKofArenaSegment)
    for i, v in pairs(lastRankData) do
        v.score = v.integral
    end
    local LobbyLastRankingView  = require( 'Game.views.LobbyLastRankingView' ).new({tag = 1100, lastRank = lastRankData, iconStr = __('分'), title = __('上周天城演武排行榜')})
    LobbyLastRankingView:setTag(1100)
    LobbyLastRankingView:setPosition(display.center)
    uiMgr:GetCurrentScene():AddDialog(LobbyLastRankingView)
end
--[[
    查看排行奖励
--]]
function NewKofArenaRankMediator:LookRankReward()
    local scene = uiMgr:GetCurrentScene()
    local myKofArenaSegment = self.selectIndex or 1
    local rankRewards = CommonUtils.GetConfigAllMess('rankReward','kofArena')[tostring(myKofArenaSegment) ]
    local LobbyRewardListView  = require( 'Game.views.LobbyRewardListView' ).new({tag = 1200, showTips = true , msg = __('奖励发放时间：活动结束后两小时'), rewardsDatas =rankRewards})
    LobbyRewardListView:setTag(1200)
    LobbyRewardListView:setPosition(display.center)
    scene:AddDialog(LobbyRewardListView)

end

function NewKofArenaRankMediator:SwitchBtnClick(sender)
    PlayAudioByClickNormal()
    local tag = sender:getTag()
    self:SwitchOtherStageById(tag)
end
--[[
    获取当前周的当前的排行榜奖励
--]]
function NewKofArenaRankMediator:GetRankOneDatabyId(stageId)
    local rankData = self:GetRankData()  or {}
    local kofArenaRank =rankData.newKofArenaRank or {}
    local oneKofArenaRank = kofArenaRank[tostring(stageId)] or {}
    return oneKofArenaRank
end
--[[
    获取上一周的当前的排行榜奖励
--]]
function NewKofArenaRankMediator:GetLastRankOneDatabyId(stageId)
    local rankData = self:GetRankData()  or {}
    local kofArenaRank =rankData.lastNewKofArenaRank or {}
    local oneKofArenaRank = kofArenaRank[tostring(stageId)] or {}
    return oneKofArenaRank
end


--[[
    倒计时
--]]
function NewKofArenaRankMediator:CountDownTimes()
    local viewComponent =self:GetViewComponent()
    local lastTime = 0
    local currentTime  = os.time()
    viewComponent:runAction(
        cc.RepeatForever:create(
            cc.Sequence:create(
                cc.DelayTime:create(1),
                cc.CallFunc:create(function()
                    lastTime = currentTime
                    currentTime = os.time()
                    self.leftSecond = self.leftSecond - (currentTime - lastTime)
                    self:UpdateLeftTimeLabel()
                end)
            )
        )
    )
end
function NewKofArenaRankMediator:GetFightTeamCaptainByFightTeam(fightTeam)
    local captainTable = {}
    for i, v in pairs(fightTeam) do
        for ii, vv  in pairs(v.cards or {}) do
            if next(vv) ~= nil  then
                captainTable[tostring(i)] = vv
                break
            end
        end
    end
    return captainTable
end

--[[
    切换到其他阶段的排行榜
--]]
function NewKofArenaRankMediator:SwitchOtherStageById(stageId)
    local viewData = self.viewComponent.viewData
    local gridView = viewData.gridView
    local oneKofArenaRank = self:GetRankOneDatabyId(stageId)
    self.oneKofArenaRank = oneKofArenaRank
    gridView:setCountOfCell(#oneKofArenaRank)
    gridView:reloadData()
    local listView = viewData.listView
    -- 设置按钮的选中状态
    if self.selectIndex then
        local listCell = listView:getNodeAtIndex( self.selectIndex -1)
        if listCell and (not tolua.isnull(listCell)) then
            local rankBtn = listCell:getChildByName("rankBtn")
            rankBtn:setEnabled(true)
        end
    end
    local listCell = listView:getNodeAtIndex( stageId -1)
    if listCell and (not tolua.isnull(listCell)) then
        local rankBtn = listCell:getChildByName("rankBtn")
        rankBtn:setEnabled(false)
    end
    self.selectIndex = stageId
    -- 更新自己的显示内容
    self:UpdateMySelfLayout()
end

function NewKofArenaRankMediator:OnDataSource(cell, idx)
    local pCell = cell
    local index = idx +1
    if index >=1 and index <=  #self.oneKofArenaRank then
        if pCell == nil  then
            pCell = RankKOFCell.new(cc.size(1035, 112))
        end
    end
    xTry(function()
        local datas = self.oneKofArenaRank[index]
        pCell.rankNum:setString(checkint(datas.rank))
        pCell.avatarIcon:RefreshSelf({level = datas.playerLevel, avatar = datas.playerAvatar, avatarFrame = datas.playerAvatarFrame})
        pCell.nameLabel:setString(datas.playerName)
        pCell.avatarIcon:setOnClickScriptHandler(function ( sender )
            uiMgr:AddDialog('common.PlayerHeadPopup', {playerId = datas.playerId, type = CommonUtils.GetHeadPopupTypeByPlayerId(datas.playerId)})
        end)
        
        local integral = checkint(self:getInitScore()) + checkint(datas.integral)
        display.commonLabelParams(pCell.winLabel , {text = string.format(__('积分 %d') , integral)})
        if checkint(datas.rank) >= 1 and checkint(datas.rank) <= 3 then
            pCell.rankBg:setVisible(true)
            pCell.rankBg:setTexture(_res('ui/home/rank/restaurant_info_bg_rank_num' .. tostring(datas.rank) .. '.png'))
        else
            pCell.rankBg:setVisible(false)
        end
        pCell.eventNode:setTag(index)
        local captainTable = self:GetFightTeamCaptainByFightTeam(datas.fightTeam)
        for i, v in pairs(pCell.cardTable) do
            local cardDatas = captainTable[tostring(i)]
            if cardDatas and next(cardDatas) ~= nil then
                v:setVisible(true)
                v:RefreshUI({
                    cardData = {
                        cardId = cardDatas.cardId,
                        level = cardDatas.level,
                        breakLevel = cardDatas.breakLevel,
                        defaultSkinId = cardDatas.cardSkinId,
                        favorabilityLevel = cardDatas.favorabilityLevel
                    },
                    showBaseState = true,
                    showActionState = false,
                    showVigourState = false
                })
                display.commonUIParams(v, { animate = false ,  cb = function(sender) -- 此处添加查看队伍的界面
                    local tag = sender:getTag()
                    local teamData = datas.fightTeam[tostring(tag)]
                    teamData.battlePoint =  teamData.combatValue
                    self:CreateShowFightTeam(teamData ,tag,  sender )
                end})
            else
                v:setVisible(false)
            end
        end
    end,__G__TRACKBACK__)
    return pCell
end

function NewKofArenaRankMediator:CreateShowFightTeam(teamData, teamId , targetNode )
    local showTeamLayer = display.newLayer(display.cx , display.cy , { ap = display.CENTER })
    -- 关闭页面
    local closeLayer = display.newLayer(display.cx , display.cy , {ap =  display.CENTER , enable = true , color = cc.c4b(0,0,0,0) ,cb = function()
        showTeamLayer:runAction(cc.RemoveSelf:create())
    end})
    showTeamLayer:addChild(closeLayer)
    local nodePos = cc.p(targetNode:getPosition())
    local targetNodeParent = targetNode:getParent()
    local worldPos =  targetNodeParent:convertToWorldSpace(nodePos)
    local teamPos  = showTeamLayer:convertToNodeSpace(worldPos)
    local teamSize = cc.size(540,166)
    local distanceY = 0
    local ap = display.CENTER_BOTTOM
    local hornPoint = cc.p(teamSize.width/2 , 15)
    local scaleY = -1
    if (worldPos.y -50 ) -teamSize.height > 0  then
        distanceY = -50
        ap = display.CENTER_TOP
        hornPoint =  cc.p(teamSize.width/2 , teamSize.height-15)
        scaleY = 1
    end

    local teamLayout = display.newLayer(teamPos.x  ,teamPos.y +distanceY  , {ap = ap , size = teamSize  })
    showTeamLayer:addChild(teamLayout)

    local tipsHorn = display.newImageView(_res('ui/common/common_bg_tips_horn'),hornPoint.x , hornPoint.y , {ap = display.CENTER_BOTTOM })
    teamLayout:addChild(tipsHorn,2)
    tipsHorn:setScaleY(scaleY)
    local bgTeamImage = display.newImageView(_res('ui/common/common_bg_tips'),teamSize.width/2 ,teamSize.height/2 ,
        {ap = display.CENTER ,scale9 = true , size = teamSize })
    teamLayout:addChild(bgTeamImage)

    local teamView = require("Game.views.tagMatch.TagMatchDefensiveTeamView").new({teamId = teamId, teamDatas = teamData, teamMarkPosSign = -1 , isOppoentTeam = true })
    display.commonUIParams(teamView, {po = cc.p(teamSize.width / 2, teamSize.height / 2), ap = display.CENTER})
    teamLayout:addChild(teamView)
    uiMgr:GetCurrentScene():AddDialog(showTeamLayer)
end


function NewKofArenaRankMediator:EnterLayer(  )
    self:SendSignal(POST.NEW_RANK_KOF_ARE_NARANK.cmdName ,{})
end

function NewKofArenaRankMediator:OnRegist(  )
    regPost(POST.NEW_RANK_KOF_ARE_NARANK)
    self:EnterLayer()
end

function NewKofArenaRankMediator:OnUnRegist(  )
    unregPost(POST.NEW_RANK_KOF_ARE_NARANK)
    if self:GetViewComponent() and (not tolua.isnull(self:GetViewComponent())) then
        self:GetViewComponent():runAction(cc.RemoveSelf:create())
    end
end


return NewKofArenaRankMediator








