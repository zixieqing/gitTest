--[[
 * descpt : 世界BOSS手册 界面
]]
local VIEW_SIZE = display.size
local WorldBossManualView = class('WorldBossManualView', function ()
	local node = CLayout:create(display.size)
	node.name = 'Game.views.union.WorldBossManualView'
	node:enableNodeEvents()
	return node
end)

local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local uiMgr   = AppFacade.GetInstance():GetManager('UIManager')

local CreateView = nil
local CreateRankRoleView = nil
local CreateListCell_ = nil
local CreateCardNode = nil

local getLabelColorByRank = nil
local getRankTextByRank = nil

local RES_DIR = {
    BACK                             = _res("ui/common/common_btn_back"),
    TITLE                            = _res('ui/common/common_title.png'),
    BTN_TIPS                         = _res('ui/common/common_btn_tips.png'),

    BOOSSTRATEGY_BG                  = _res('ui/worldboss/manual/boosstrategy_bg.png'),
    BOOSSTRATEGY_BG_1                = _res('ui/worldboss/manual/boosstrategy_bg_1.png'),
    SPLIT_LINE                       = _res('ui/home/commonShop/monthcard_tool_split_line.png'),
    ACHIEVEMENT_TITLE                = _res('ui/common/common_title_5.png'),
    BOOSSTRATEGY_TITLE_RANKING       = _res('ui/worldboss/manual/boosstrategy_title_ranking.png'),
    RANKS_NAME_BG                    = _res('ui/worldboss/manual/boosstrategy_ranks_name_bg_2.png'),
    RED_POINT_IMG                    = _res('ui/common/common_hint_circle_red_ico.png'),
    REWARD_BOX                       = _res('arts/goods/goods_icon_191006.png'),
    
    CELL_BG                          = _res('ui/raid/hall/raid_boss_list_frame_bg.png'),
    CELL_BG_D                        = _res('ui/raid/hall/raid_boss_list_frame_default.png'),
    CELL_SELECT                      = _res('ui/worldboss/manual/boosstrategy_btn_frame_select.png'),
    
}

local BUTTON_TAG = {
    BACK      = 100, 
    RULE      = 101,
}

local WORLD_BOSS_MANUAL_CLICK_PLAYER_HEAD = 'WORLD_BOSS_MANUAL_CLICK_PLAYER_HEAD'

function WorldBossManualView:ctor( ... )
    
    self.args = unpack({...})
    self:initialUI()
end

function WorldBossManualView:initialUI()
    xTry(function ( )
        self.viewData_ = CreateView()
        self:addChild(self.viewData_.view)
	end, __G__TRACKBACK__)
end

function WorldBossManualView:refreshUI(data)
    if data == nil then return end
    -- 更新boss信息
    self:updateBossInfo(data.manualConf)

    -- 更新我的成绩
    self:updateAchievement(data)

    -- 更新推荐卡牌
    self:updateRecommendCard(data.manualConf)

    -- 更新推荐堕神
    self:updateRecommendPet(data.manualConf)

    -- 更新全服排名
    self:updateFullServerTopRank(data)
    
    -- 更新红点
    self:updateRedPointImg(data.canReceiveCount)
end

--[[
    更新boss信息
    @params manualConf 手册配表数据
]]
function WorldBossManualView:updateBossInfo(manualConf)
    local viewData      = self:getViewData()
    
    local name          = manualConf.name
    local bossNameLabel = viewData.bossNameLabel
    display.commonLabelParams(bossNameLabel, {text = name})

    local showMonster  = checkint(manualConf.showMonster)
    local bossImg      = viewData.bossImg
    bossImg:setTexture(AssetsUtils.GetRaidBossPreviewDrawPath(showMonster))  
    -- FIXME 这里的 showMonster 应该是怪物id，那么为啥 monster 配表里不配一个对应的怪物？？
    -- 应该调用这个 CardUtils.GetRaidBossPreviewDrawPathByCardId 方法，但是 monster 中没有配对应的id，所以只能裸取资源
end

--[[
    更新我的成绩
    @params data 手册数据
]]
function WorldBossManualView:updateAchievement(data)
    local viewData         = self:getViewData()
    local myMaxDamage      = data.myMaxDamage
    local historyHurtLabel = viewData.historyHurtLabel
    display.commonLabelParams(historyHurtLabel, {  text = string.format(__('历史最高伤害:%s'), tostring(myMaxDamage))})

    local myRank           = 0
    if data.myRank then
        myRank           = tonumber(data.myRank)
    end
    -- myRank           = 2
    local totalNumbers     = 0
    if data.totalNumbers then
        totalNumbers     = tonumber(data.totalNumbers)
    end
    
    local rankTipLabel     = viewData.rankTipLabel
    local transcendNum     = totalNumbers - myRank
    
    local isShowTip = transcendNum ~= totalNumbers
    rankTipLabel:setVisible(isShowTip)
    if isShowTip then
        local text = nil
        if myRank == 0 then
            text = __('未入榜')
        else
            local probability = string.format('%.7f', transcendNum/ totalNumbers)
            text = string.fmt(__('超越全服_num_%的玩家'), {_num_ = tonumber(probability) * 100})
        end
        display.commonLabelParams(rankTipLabel, {text = text , w = 280})
    end
end

--[[
    更新推荐卡牌
    @params manualConf 手册配表数据
]]
function WorldBossManualView:updateRecommendCard(manualConf)
    local viewData         = self:getViewData()

    local recommendCards = manualConf.recommendCards or {}
    local cardLayer      = viewData.cardLayer
    local cardNodes      = viewData.cardNodes
    local cardLayerSize  = cardLayer:getContentSize()
    local singleCardW    = cardLayerSize.width / MAX_TEAM_MEMBER_AMOUNT
    local width = cardLayerSize.width/table.nums(recommendCards)
    for i = 1, MAX_TEAM_MEMBER_AMOUNT do
        local cardId = recommendCards[i]
        local cardNode_ = cardNodes[i]
        if cardId then
            local cardNodeData = {cardData = {cardId = cardId}, showBaseState = true, showActionState = false}
            if cardNode_ and not tolua.isnull(cardNode_) then
                cardNode_:setVisible(true)
                local cardNodeViewData = cardNode_.viewData
                local cardHeadNode     = cardNodeViewData.cardHeadNode

                cardHeadNode:RefreshUI(cardNodeData)
            else
                local cardNode = CreateCardNode(cardNodeData)
                cardLayer:addChild(cardNode)
                cardNodes[i] = cardNode
                cardNode_ = cardNode

                local cardNodeViewData = cardNode_.viewData
                local cardHeadTouchLayer = cardNodeViewData.cardHeadTouchLayer
                display.commonUIParams(cardHeadTouchLayer, {cb = handler(self, self.onClickCardHeadAction)})
                
            end
            display.commonUIParams(cardNode_, {po = cc.p(width * (i - 0.5), cardLayerSize.height / 2), ap = display.CENTER})
            local isOwnCard        = gameMgr:GetCardDataByCardId(cardId) ~= nil
            local cardNodeViewData = cardNode_.viewData

            local cardHeadNode     = cardNodeViewData.cardHeadNode
            cardHeadNode:SetGray(not isOwnCard)

            local grayTipLabel     = cardNodeViewData.grayTipLabel
            grayTipLabel:setVisible(not isOwnCard)

            local cardHeadTouchLayer = cardNodeViewData.cardHeadTouchLayer
            cardHeadTouchLayer:setTag(cardId)
            cardHeadTouchLayer:setVisible(not isOwnCard)
        else
            if cardNode_ and not tolua.isnull(cardNode_)  then
                cardNode_:setVisible(false)
            end
        end
    end
end

--[[
    更新推荐堕神
    @params manualConf 手册配表数据
]]
function WorldBossManualView:updateRecommendPet(manualConf)
    local viewData         = self:getViewData()

    local recommendPets    = manualConf.recommendPets
    local recommendPetTip  = viewData.recommendPetTip
    display.commonLabelParams(recommendPetTip, {text = tostring(recommendPets)})

    local recommendPetTipSize = display.getLabelContentSize(recommendPetTip)

    local descrContainer  = viewData.descrContainer
    local descrScrollTop = descrContainer:getViewSize().height - recommendPetTipSize.height
	descrContainer:setContentOffset(cc.p(0, descrScrollTop))
end

--[[
    更新全服排名
    @params data 手册数据
]]
function WorldBossManualView:updateFullServerTopRank(data)
    local viewData         = self:getViewData()

    local topRank          = data.topRank or {}
    local rankBgLayer      = viewData.rankBgLayer
    local rankEmptyTip     = viewData.rankEmptyTip
    local isShowEmptyTip   = next(topRank) == nil
    rankBgLayer:setVisible(not isShowEmptyTip)
    rankEmptyTip:setVisible(isShowEmptyTip)
    if next(topRank) == nil then
        return
    end

    local rankLayers       = viewData.rankLayers
    -- local rankLayerCount   = 

    for rank, rankLayer in ipairs(rankLayers) do
        local rankLayerViewData = rankLayer.viewData
        local playerHeadNode    = rankLayerViewData.playerHeadNode
        local nameLabel         = rankLayerViewData.nameLabel
        local nameBg            = rankLayerViewData.nameBg
        local emptyTip          = rankLayerViewData.emptyTip
        local rankData          = topRank[rank]
        
        rankLayer:setVisible(true)

        if rankData then
            playerHeadNode:setVisible(true)
            local callback = function ()
                AppFacade.GetInstance():DispatchObservers(WORLD_BOSS_MANUAL_CLICK_PLAYER_HEAD, {rankData = rankData})
            end
            playerHeadNode:RefreshUI({
                playerId    = rankData.playerId or rankData.id,
                avatar      = rankData.playerAvatar,
                avatarFrame = rankData.playerAvatarFrame,
                playerLevel = rankData.playerLevel,
                callback    = callback
            })
            playerHeadNode:setTag(rank)

            local playerName = rankData.playerName
            nameBg:setVisible(true)
            emptyTip:setVisible(false)
            display.commonLabelParams(nameLabel, {text = playerName})
        else
            playerHeadNode:setVisible(false)
            nameBg:setVisible(false)
            emptyTip:setVisible(true)
        end
    end
end

--[[
    更新红点
    @params canReceiveCount 能领取的奖励个数
]]
function WorldBossManualView:updateRedPointImg(canReceiveCount)
    local viewData         = self:getViewData()
    local redPointImg      = viewData.redPointImg
    local isShow = checkint(canReceiveCount) > 0
    redPointImg:setVisible(isShow)
end

--[[
    更新cell
    @params manualData 手册数据
]]
function WorldBossManualView:updateListCell(viewData, manualData)
    local headImg     = viewData.headImg
    local nameLabel   = viewData.nameLabel

    self:updateCellFrame(viewData, manualData.frameId)

    local manualConf  = manualData.manualConf
    -- logInfo.add(5, tableToString(manualData))
    display.commonLabelParams(nameLabel, {text = tostring(manualConf.name)})
    
    local showMonster = checkint(manualConf.showMonster)
    headImg:setTexture(AssetsUtils.GetCardHeadPath(showMonster))

end

function WorldBossManualView:updateCellFrame(viewData, frameId)
    local frameImg    = viewData.frameImg
    local isOwnFrame  = frameId ~= 0
    
    frameImg:setVisible(isOwnFrame)
    if isOwnFrame then
        frameImg:setTexture(string.format('ui/worldboss/manual/boosstrategy_btn_frame_%s.png', frameId))
    end
end

CreateView = function ()
    local view = display.newLayer()
    local size = view:getContentSize()
    
    view:addChild(display.newLayer(0, 0, {color = cc.c4b(0, 0, 0, 150), enable = true}))

    local actionBtns = {}
    -------------------------------------
    -- top
    local topUILayer = display.newLayer()
    view:addChild(topUILayer, 1)

    -- back button
    local backBtn = display.newButton(display.SAFE_L + 75, size.height - 52, {n = RES_DIR.BACK})
    topUILayer:addChild(backBtn)
    actionBtns[tostring(BUTTON_TAG.BACK)] = backBtn

    -- title button
    local titleBtn = display.newButton(display.SAFE_L + 120, size.height, {n = RES_DIR.TITLE, ap = display.LEFT_TOP})
    display.commonLabelParams(titleBtn, fontWithColor(1, {text = __('灾祸手册'), offset = cc.p(0, -10)}))
    topUILayer:addChild(titleBtn)

    -------------------------------------
    -- left

    local leftUILayer = display.newLayer()
    view:addChild(leftUILayer)

    local zoomSliderList = require("common.ZoomSliderList").new()
    leftUILayer:addChild(zoomSliderList)
    
    local cellSize = cc.size(214, 232)
    zoomSliderList:setBasePoint(cc.p(display.SAFE_L, display.cy))
    zoomSliderList:setCellSize(cellSize)
    zoomSliderList:setScaleMin(0.42)
    zoomSliderList:setAlphaMin(100)
    zoomSliderList:setCellSpace(165)
    zoomSliderList:setCenterIndex(1)
    zoomSliderList:setDirection(1)
    zoomSliderList:setAlignType(1)
    zoomSliderList:setSideCount(5)
    zoomSliderList:setSwallowTouches(false)

    -------------------------------------
    -- content
    local contentUILayer = display.newLayer()
    view:addChild(contentUILayer)

    ---------------------
    -- content left
    local manualBgLayer = display.newLayer(display.cx + 73, display.cy - 40, {ap = display.CENTER, bg = RES_DIR.BOOSSTRATEGY_BG})
    local manualBgLayerSize = manualBgLayer:getContentSize()
    contentUILayer:addChild(manualBgLayer)

    ----------------
    -- bossInfo
    local bossImg = AssetsUtils.GetRaidBossPreviewDrawNode(0, 270, 380, {ap = display.CENTER})
    bossImg:setScale(0.9)
    -- bossImg:setOpacity(100)
    manualBgLayer:addChild(bossImg)

    manualBgLayer:addChild(display.newImageView(RES_DIR.BOOSSTRATEGY_BG_1, 0, manualBgLayerSize.height / 2, {ap = display.LEFT_CENTER}))

    local bossNameLabel = display.newLabel(270, manualBgLayerSize.height - 50, {ap = display.CENTER, fontSize = 30, color = '#5b3c25', font = TTF_GAME_FONT, ttf = true})
    manualBgLayer:addChild(bossNameLabel)

    manualBgLayer:addChild(display.newImageView(RES_DIR.SPLIT_LINE, bossNameLabel:getPositionX(), manualBgLayerSize.height - 80, {ap = display.CENTER}))

    ----------------
    -- achievement
    local achievementTitle = display.newButton(0, 0, {n = RES_DIR.ACHIEVEMENT_TITLE, animation = false})
    display.commonUIParams(achievementTitle, {po = cc.p(200, 160)})
    display.commonLabelParams(achievementTitle, {text = __('我的成绩'), fontSize = 22, color = '#5b3c25'})
    manualBgLayer:addChild(achievementTitle)

    -- history Hurt
    local historyHurtLabel = display.newLabel(75, 110, fontWithColor(16, {ap = display.LEFT_CENTER }))
    manualBgLayer:addChild(historyHurtLabel)

    local rankTipLabel = display.newLabel(75, 90, fontWithColor(10, {ap = display.LEFT_TOP}))
    manualBgLayer:addChild(rankTipLabel)

    -- local rewardBox = sp.SkeletonAnimation:create("effects/baoxiang/baoxiang8.json","effects/baoxiang/baoxiang8.atlas", 1)
    -- rewardBox:setPosition(cc.p(430, 130))
    -- rewardBox:update(0)
    -- rewardBox:setAnimation(0, 'stop', true)
    -- manualBgLayer:addChild(rewardBox)

    local rewardBox = display.newButton(430, 138, {n = RES_DIR.REWARD_BOX, ap = display.CENTER})
    local rewardBoxSize = rewardBox:getContentSize()
    manualBgLayer:addChild(rewardBox)
    rewardBox:setScale(0.8)

    local redPointImg = display.newImageView(RES_DIR.RED_POINT_IMG, 0, 0)
    display.commonUIParams(redPointImg, {po = cc.p(rewardBoxSize.width * 0.8 + 13, rewardBoxSize.height * 0.8 - 5)})
    rewardBox:addChild(redPointImg)
    redPointImg:setVisible(false)

    manualBgLayer:addChild(display.newLabel(rewardBox:getPositionX() - 6, 75, {ap = display.CENTER, w = 160 , hAlign = display.TAC ,  text = __('狩猎奖励'), fontSize = 22, color = '#db6c00', font = TTF_GAME_FONT, ttf = true}))
    ---------------------
    -- content right
    local recommendCardTitle = display.newButton(0, 0, {n = RES_DIR.ACHIEVEMENT_TITLE,  scale9 = true , animation = false})

    display.commonUIParams(recommendCardTitle, {po = cc.p(manualBgLayerSize.width - 270, manualBgLayerSize.height - 60),ap = display.CENTER})
    display.commonLabelParams(recommendCardTitle, {text = __('推荐飨灵'), fontSize = 22, color = '#5b3c25' , paddingW =20 })
    manualBgLayer:addChild(recommendCardTitle)
    local recommendCardTitleSize = recommendCardTitle:getContentSize()
    local titleRuleBtn = display.newButton(recommendCardTitle:getPositionX() + recommendCardTitleSize.width / 2 + 20, recommendCardTitle:getPositionY(), {n = RES_DIR.BTN_TIPS})
    manualBgLayer:addChild(titleRuleBtn)
    actionBtns[tostring(BUTTON_TAG.RULE)] = titleRuleBtn

    local cardLayerSize = cc.size(450, 100)
    local cardLayer = display.newLayer(manualBgLayerSize.width - 270, manualBgLayerSize.height - 90, {ap = display.CENTER_TOP, size = cardLayerSize })
    manualBgLayer:addChild(cardLayer)

    ---------------------
    -- recommend pet
    local recommendPetTitle = display.newButton(0, 0, {n = RES_DIR.ACHIEVEMENT_TITLE, animation = false , scale9 = true })
    local recommendPetTitleSize = recommendPetTitle:getContentSize()
    display.commonUIParams(recommendPetTitle, {po = cc.p(manualBgLayerSize.width - 270, manualBgLayerSize.height - 230), ap = display.CENTER})
    display.commonLabelParams(recommendPetTitle, {text = __('推荐堕神'), fontSize = 22, color = '#5b3c25' , paddingW = 20})
    manualBgLayer:addChild(recommendPetTitle)

    -- local tempLayer = display.newLayer(manualBgLayerSize.width - 270, recommendPetTitle:getPositionY() - 30, {size = cc.size(400, 100), ap = display.CENTER_TOP, color = cc.c4b(0,0,0,150)})
    -- manualBgLayer:addChild(tempLayer)

    -- local recommendPetTip = display.newLabel(manualBgLayerSize.width - 465, recommendPetTitle:getPositionY() - 30, {ap = display.LEFT_TOP, fontSize = 22, w = 22 * 18 + 5, color = '#aa4d08'})
    -- manualBgLayer:addChild(recommendPetTip)
    -- recommendPetTip:setVisible(false)

    local descrViewSize  = cc.size(400, 88)
	local descrContainer = cc.ScrollView:create()
    descrContainer:setViewSize(descrViewSize)
	descrContainer:setAnchorPoint(display.CENTER_TOP)
	descrContainer:setDirection(eScrollViewDirectionVertical)
    descrContainer:setPosition(cc.p(manualBgLayerSize.width - 465, recommendPetTitle:getPositionY() - 120))
	manualBgLayer:addChild(descrContainer)

    local recommendPetTip = display.newLabel(0, 0, {ap = display.LEFT_TOP, fontSize = 22, w = descrViewSize.width, color = '#aa4d08'})
	descrContainer:setContainer(recommendPetTip)

    ---------------------
    -- rank
    local rankTitle = display.newImageView(RES_DIR.BOOSSTRATEGY_TITLE_RANKING, manualBgLayerSize.width / 2 - 2, 280, {ap = display.LEFT_TOP})
    manualBgLayer:addChild(rankTitle)

    rankTitle:addChild(display.newLabel(24, rankTitle:getContentSize().height / 2, {ap = display.LEFT_CENTER, fontSize = 22, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, text = __('全服排名')}))

    local rankBgLayerSize = cc.size(450, 180)
    local rankBgLayer = display.newLayer(manualBgLayerSize.width - 270, 150, {ap = display.CENTER, size = rankBgLayerSize})
    manualBgLayer:addChild(rankBgLayer)

    local rankPosConf = {
        [1] = cc.p(rankBgLayerSize.width / 2, rankBgLayerSize.height / 2),
        [2] = cc.p(70, rankBgLayerSize.height / 2),
        [3] = cc.p(380, rankBgLayerSize.height / 2),
    }

    local rankSize = cc.size(100, 150)
    local rankLayers = {}
    for rank, pos in ipairs(rankPosConf) do
        local layer = CreateRankRoleView(rank)
        display.commonUIParams(layer, {ap = display.CENTER, po = pos})
        rankBgLayer:addChild(layer)
        layer:setVisible(false)
        -- rankLayers[tostring(rank)] = layer
        table.insert(rankLayers, layer)
    end

    local rankEmptyTip = display.newLabel(manualBgLayerSize.width - 270, 150, fontWithColor(16, {ap = display.CENTER, text = __('暂无全服排名')}))
    manualBgLayer:addChild(rankEmptyTip)
    rankEmptyTip:setVisible(false)

    return {
        view               = view,
        actionBtns         = actionBtns,
        zoomSliderList     = zoomSliderList,
        bossNameLabel      = bossNameLabel,
        bossImg            = bossImg,
        historyHurtLabel   = historyHurtLabel,
        descrContainer     = descrContainer,
        rankTipLabel       = rankTipLabel,
        rewardBox          = rewardBox,
        redPointImg        = redPointImg,
        cardLayer          = cardLayer,
        recommendPetTip    = recommendPetTip,
        rankBgLayer        = rankBgLayer,
        rankLayers         = rankLayers,
        rankEmptyTip       = rankEmptyTip,

        cardNodes          = {},
    }
end

CreateRankRoleView = function (rank)
    local layerSize = cc.size(140, 170)
    local layer = display.newLayer(0, 0, {size = layerSize})

    local rankLabel = display.newLabel(layerSize.width / 2, layerSize.height - 20, {text = getRankTextByRank(rank), ap = display.CENTER, color = getLabelColorByRank(rank), fontSize = 24, font = TTF_GAME_FONT, ttf = true, outline = '#5b3c25', outlineSize = 1})
    layer:addChild(rankLabel)

    local playerHeadNode = require('common.PlayerHeadNode').new({showLevel = true})
    display.commonUIParams(playerHeadNode, {po = cc.p(layerSize.width / 2, layerSize.height - 78), ap = display.CENTER})
    playerHeadNode:setScale(0.5)
    layer:addChild(playerHeadNode, 1)
    playerHeadNode:setVisible(false)

    local imgPath = string.format('ui/worldboss/manual/boosstrategy_ico_ranking_%s.png', rank)
    local baseImg = display.newImageView(_res(imgPath), layerSize.width / 2, 50, {ap = display.CENTER})
    layer:addChild(baseImg)

    if rank == 1 then
        local avatarLight = display.newImageView(_res('ui/common/tower_prepare_bg_light.png'), 0, 0)
        display.commonUIParams(avatarLight, {po = cc.p(65, 15), ap = display.CENTER_BOTTOM})
        avatarLight:setScale(0.8)
		baseImg:addChild(avatarLight)
    end

    local nameBg = display.newImageView(RES_DIR.RANKS_NAME_BG, layerSize.width / 2, 28, {ap = display.CENTER_TOP})
    local nameBgSize = nameBg:getContentSize()
    layer:addChild(nameBg)

    local nameLabel = display.newLabel(nameBgSize.width / 2, nameBgSize.height / 2, {ap = display.CENTER, color = '#5b3c25', fontSize = 20})
    nameBg:addChild(nameLabel)
    nameBg:setVisible(false)

    local emptyTip = display.newLabel(layerSize.width / 2, 20, {text = __('暂无排名'), ap = display.CENTER, color = '#5b3c25', fontSize = 20})
    layer:addChild(emptyTip)
    emptyTip:setVisible(false)

    layer.viewData = {
        playerHeadNode = playerHeadNode,
        nameBg         = nameBg,
        nameLabel      = nameLabel,
        emptyTip       = emptyTip,
    }
    return layer
end

CreateListCell_ = function ()
    local layerSize = cc.size(214, 232)
    -- local layerSize = cc.size(192, 208)
    local layer = display.newLayer(0, 0, {size = layerSize})
    -- 
    local selectBg = display.newImageView(RES_DIR.CELL_SELECT, layerSize.width / 2, layerSize.height / 2, {ap = display.CENTER})
    layer:addChild(selectBg)
    selectBg:setVisible(false)

    -- 背景
    local bg = display.newImageView(_res('ui/raid/hall/raid_boss_list_frame_bg.png'), 0, 0)
    display.commonUIParams(bg, {po = cc.p(layerSize.width / 2, layerSize.height / 2)})
    bg:setScale(0.72)
    layer:addChild(bg)

    -- 前景
    local fg = display.newImageView(_res('ui/raid/hall/raid_boss_list_frame_default.png'), 0, 0)
    display.commonUIParams(fg, {po = cc.p(layerSize.width / 2, layerSize.height / 2)})
    fg:setScale(0.72)
    layer:addChild(fg)

    local frameImg = display.newImageView('', layerSize.width / 2 - 3, layerSize.height / 2, {ap = display.CENTER})
    layer:addChild(frameImg, 1)
    frameImg:setVisible(false)

    local headImg = display.newImageView('', layerSize.width / 2 , layerSize.height / 2 + 10, {ap = display.CENTER})
    headImg:setScale(0.55)
    layer:addChild(headImg)

    local nameLabel = display.newLabel(107, 63, {ap = display.CENTER, color = '#76534a', fontSize = 18})
    layer:addChild(nameLabel)

    layer.viewData = {
        selectBg = selectBg,
        frameImg = frameImg,
        headImg = headImg,
        nameLabel = nameLabel,
    }
    return layer
end

CreateCardNode = function (cardNodeData)
    local cardHeadLayerSize = cc.size(81, 81)
    local cardHeadLayer = display.newLayer(0, 0, {size = cardHeadLayerSize})

    local cardHeadNode = require('common.CardHeadNode').new(cardNodeData)
    local cardHeadNodeSize = cardHeadNode:getContentSize()
    cardHeadNode:setScale(0.4)
    cardHeadNode:setPosition(cc.p(cardHeadLayerSize.width / 2, cardHeadLayerSize.height / 2))
    cardHeadLayer:addChild(cardHeadNode)
    -- cardHeadNode:SetGray(true)

    local cardHeadTouchLayer = display.newLayer(cardHeadLayerSize.width / 2, cardHeadLayerSize.height / 2, {ap = display.CENTER, size = cc.size(cardHeadNodeSize.width * 0.4, cardHeadNodeSize.height * 0.4), enable = true, color = cc.c4b(0,0,0,0)})
    cardHeadLayer:addChild(cardHeadTouchLayer)

    local grayTipLabel = display.newLabel(cardHeadLayerSize.width / 2, cardHeadLayerSize.height -30 , {w = 90 , hAlign = display.TAC, text = __('未获得'), ap = display.CENTER_BOTTOM, color = '#fffcf3', font = TTF_GAME_FONT , ttf = true, fontSize = 19, outline = '#d23d35', outlineSize = 1})
    cardHeadLayer:addChild(grayTipLabel)
    grayTipLabel:setVisible(false)

    cardHeadLayer.viewData = {
        cardHeadNode = cardHeadNode,
        grayTipLabel = grayTipLabel,
        cardHeadTouchLayer = cardHeadTouchLayer,
    }
    return cardHeadLayer
end

getLabelColorByRank = function (rank)
    local color = nil
    if rank == 1 then
        color = '#f4af15'
    elseif rank == 2 then
        color = '#d7d7d7'
    else
        color = '#dab1a6'
    end
    return color
end

getRankTextByRank = function (rank)
    local text = nil
    if rank == 1 then
        text = __('第一名')
    elseif rank == 2 then
        text = __('第二名')
    else
        text = __('第三名')
    end
    return text
end

function WorldBossManualView:CreateListCell()
    return CreateListCell_()
end

function WorldBossManualView:getViewData()
	return self.viewData_
end

function WorldBossManualView:onClickPlayerHeadAction(sender)
    local rank = sender:getTag()
    AppFacade.GetInstance():DispatchObservers(WORLD_BOSS_MANUAL_CLICK_PLAYER_HEAD, {rank = rank})
end

function WorldBossManualView:onClickCardHeadAction(sender)
    local cardId = sender:getTag()
    local datas = CommonUtils.GetConfig('cards', 'card', cardId)
    if not  datas then
        uiMgr:ShowInformationTips(__('该飨灵暂未开放'))
    else
        uiMgr:AddDialog("common.GainPopup", {goodId = datas.fragmentId})
    end
end

return WorldBossManualView