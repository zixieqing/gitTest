--[[
 * author : kaishiqi
 * descpt : 打牌游戏 - 牌册视图
]]
local TTGameAlbumView = class('TripleTriadGameAlbumView', function()
    return display.newLayer(0, 0, {name = 'TripleTriadGameAlbumView'})
end)

local RES_DICT = {
    COM_TITLE_BAR      = _res('ui/common/common_title.png'),
    COM_TIPS_ICON      = _res('ui/common/common_btn_tips.png'),
    COM_BACK_BTN       = _res('ui/common/common_btn_back.png'),
    BG_IMAGE           = _res('ui/cards/marry/card_contract_bg_memory'),
    RULE_BG_FRAME      = _res('ui/ttgame/common/cardgame_common_bg_1.png'),
    ALBUM_TITLE_BAR    = _res('ui/ttgame/album/cardgame_collection_label_group.png'),
    ALBUM_TITLE_NUM    = _res('ui/ttgame/album/cardgame_collection_label_num.png'),
    ALBUM_REWARDS_LINE = _res('ui/ttgame/album/cardgame_collection_line_1.png'),
    REWARDS_BAR_D      = _res('ui/ttgame/album/cardgame_collection_label_reward_active.png'),
    REWARDS_BAR_N      = _res('ui/ttgame/album/cardgame_collection_label_reward_default.png'),
    REWARDS_LIGHT      = _res('ui/home/commonShop/shop_recharge_light_blue.png'),
    REWARDS_DRAWED     = _res('ui/common/raid_room_ico_ready.png'),
    DECK_FRAME         = _res('ui/ttgame/album/cardgame_collection_bg_deck.png'),
    DECK_EMPTY_ICON    = _res('ui/common/maps_fight_btn_pet_add.png'),
    DECK_FILLED_ICON   = _res('ui/ttgame/album/cardgame_collection_ico_group.png'),
    DECK_NUM_BAR       = _res('ui/ttgame/album/cardgame_collection_label_groupnum.png'),
    DECK_CELL_FRAME    = _res('ui/ttgame/album/cardgame_collection_bg_deck_cell.png'),
}

local CreateView      = nil
local CreateDeckCell  = nil
local CreateAlbumCell = nil
local DECK_CELL_SIZE  = cc.size(88, 88)


function TTGameAlbumView:ctor(args)
    -- init vars
    self.deckList_ = {}

    -- create view
    self.viewData_ = CreateView()
    self:addChild(self.viewData_.view)

    -- update views
    local deckLayerSize = self:getViewData().deckLayer:getContentSize()
    for cellIndex = TTGAME_DEFINE.DECK_MAXIMUM, 1, -1 do
        local cellViewData = CreateDeckCell(DECK_CELL_SIZE)
        display.commonLabelParams(cellViewData.indexLabel, {text = tostring(cellIndex)})
        cellViewData.view:setPositionX(deckLayerSize.width - 20 - (DECK_CELL_SIZE.width + 6) * #self.deckList_)
        cellViewData.view:setPositionY(deckLayerSize.height/2)
        self:getViewData().deckLayer:addChild(cellViewData.view)
        table.insert(self.deckList_, 1, cellViewData)
    end
end


CreateView = function()
    local view = display.newLayer()
    local size = view:getContentSize()

    -- block layer
    view:addChild(display.newLayer(0, 0, {color = cc.c4b(150,100,50,255), enable = true}))
    view:addChild(display.newImageView(RES_DICT.BG_IMAGE, display.cx, display.cy, {isFull = true}))

    ------------------------------------------------- [top]
    local topLayer = display.newLayer()
    view:addChild(topLayer)

    -- back button
    local backBtn = display.newButton(display.SAFE_L + 75, size.height - 52, {n = RES_DICT.COM_BACK_BTN})
    topLayer:addChild(backBtn)

    -- title button
    local titleBtn = display.newButton(display.SAFE_L + 120, size.height, {n = RES_DICT.COM_TITLE_BAR, ap = display.LEFT_TOP})
    display.commonLabelParams(titleBtn, fontWithColor(1, {text = __('牌册'), offset = cc.p(0,-10)}))
    topLayer:addChild(titleBtn)

    local titleSize = titleBtn:getContentSize()
    titleBtn:addChild(display.newImageView(RES_DICT.COM_TIPS_ICON, titleSize.width - 50, titleSize.height/2 - 10))


    -- deck layer
    local deckSize  = cc.size(570, 154)
    local deckLayer = display.newLayer(display.cx + 50, size.height + 25, {ap = display.LEFT_TOP, bg = RES_DICT.DECK_FRAME, scale9 = true, size = deckSize})
    topLayer:addChild(deckLayer)

    local deckIntro = display.newLabel(170, 30, fontWithColor(20, {fontSize = 26,w = 150 ,hAlign = display.TAR, outline = '#7b3f33', text = __('编辑牌组'), ap = display.RIGHT_BOTTOM}))
    deckLayer:addChild(deckIntro)



    ------------------------------------------------- [center]
    local centerLayer = display.newLayer()
    view:addChild(centerLayer)

    
    local albumListPos  = cc.p(size.width/2, 0)
    local albumListSize = cc.size(1280, size.height - 125)
    local albumListView = CTableView:create(albumListSize)
    albumListView:setSizeOfCell(cc.size(albumListSize.width, 530))
    albumListView:setDirection(eScrollViewDirectionVertical)
    albumListView:setAnchorPoint(display.CENTER_BOTTOM)
    albumListView:setPosition(albumListPos)
    -- albumListView:setBackgroundColor(cc.r4b(250))
    centerLayer:addChild(display.newImageView(RES_DICT.RULE_BG_FRAME, albumListPos.x, albumListPos.y, {scale9 = true, size = albumListSize, ap = display.CENTER_BOTTOM}))
    centerLayer:addChild(albumListView)
    

    return {
        view            = view,
        topLayer        = topLayer,
        topLayerHidePos = cc.p(topLayer:getPositionX(), 100),
        topLayerShowPos = cc.p(topLayer:getPosition()),
        titleBtn        = titleBtn,
        titleBtnHidePos = cc.p(titleBtn:getPositionX(), titleBtn:getPositionY() + 190),
        titleBtnShowPos = cc.p(titleBtn:getPosition()),
        backBtn         = backBtn,
        deckLayer       = deckLayer,
        albumListView   = albumListView,
    }
end


CreateDeckCell = function(size)
    local view = display.newLayer(0, 0, {size = size, ap = display.RIGHT_CENTER})
    view:addChild(display.newImageView(RES_DICT.DECK_CELL_FRAME, size.width/2, size.height/2))

    -- has layer
    local hasLayer = display.newLayer()
    view:addChild(hasLayer)

    local deckIcon = display.newImageView(RES_DICT.DECK_FILLED_ICON, size.width/2, size.height/2)
    hasLayer:addChild(deckIcon)
    
    local indexFrame = display.newImageView(RES_DICT.DECK_NUM_BAR, size.width/2, 0, {ap = display.CENTER_BOTTOM})
    hasLayer:addChild(indexFrame)
    
    local indexLabel = display.newLabel(size.width/2, 12, fontWithColor(1, {color = '#FFFFFF'}))
    hasLayer:addChild(indexLabel)
    
    
    -- none layer
    local noneLayer = display.newLayer()
    view:addChild(noneLayer)
    
    local editIcon = display.newImageView(RES_DICT.DECK_EMPTY_ICON, size.width/2, size.height/2)
    noneLayer:addChild(editIcon)


    -- hostpot
    local hotspot = display.newLayer(size.width/2, size.height/2, {size = size, color = cc.r4b(0), ap = display.CENTER, enable = true})
    view:addChild(hotspot)

    return {
        view       = view,
        hasLayer   = hasLayer,
        noneLayer  = noneLayer,
        indexLabel = indexLabel,
        hotspot    = hotspot,
    }
end


CreateAlbumCell = function(size)
    local view = CTableViewCell:new()
    view:setContentSize(size)

    -- block layer
    local centerPos = cc.p(size.width/2, size.height/2)
    view:addChild(display.newLayer(0, 0, {size = size, color = cc.r4b(0), enable = true}))


    -- topInfo layer
    local topInfoLayer = display.newLayer(centerPos.x, size.height - 10, {bg = RES_DICT.ALBUM_TITLE_BAR, ap = display.CENTER_TOP})
    local topInfoSize  = topInfoLayer:getContentSize()
    view:addChild(topInfoLayer)

    local albumNameLabel = display.newLabel(40, topInfoSize.height/2, fontWithColor(7, {fontSize = 24, ap = display.LEFT_CENTER, text = '----'}))
    topInfoLayer:addChild(albumNameLabel)

    local collectNumLabel = display.newLabel(topInfoSize.width - 80, topInfoSize.height/2 - 5, fontWithColor(3, {ap = display.CENTER, text = '----'}))
    topInfoLayer:addChild(display.newImageView(RES_DICT.ALBUM_TITLE_NUM, collectNumLabel:getPositionX(), collectNumLabel:getPositionY() + 5))
    topInfoLayer:addChild(collectNumLabel)
    

    -- rewards layer
    local rewardsSize   = cc.size(180, 180)
    local rewardsPoint  = cc.p(rewardsSize.width/2 + 20, centerPos.y + 100)
    local disableLayer  = display.newLayer(rewardsPoint.x, rewardsPoint.y, {ap = display.CENTER, size = rewardsSize, color = cc.c4b(0,0,0,00), enable = true})
    local lockingLayer  = display.newLayer(rewardsPoint.x, rewardsPoint.y, {ap = display.CENTER, size = rewardsSize, color = cc.c4b(150,0,0,0), enable = true})
    local drawableLayer = display.newLayer(rewardsPoint.x, rewardsPoint.y, {ap = display.CENTER, size = rewardsSize, color = cc.c4b(0,150,0,0), enable = true})
    drawableLayer:addChild(display.newImageView(RES_DICT.REWARDS_BAR_N, rewardsSize.width/2, 15))
    lockingLayer:addChild(display.newImageView(RES_DICT.REWARDS_BAR_D, rewardsSize.width/2, 15))
    disableLayer:addChild(display.newImageView(RES_DICT.REWARDS_BAR_N, rewardsSize.width/2, 15))
    drawableLayer:addChild(display.newLabel(rewardsSize.width/2, 15, fontWithColor(3, {color = '#7adf68', text = __('可领取')})))
    lockingLayer:addChild(display.newLabel(rewardsSize.width/2, 15, fontWithColor(3, {reqW = 170 , color = '#e7cc92', text = __('收集奖励')})))
    disableLayer:addChild(display.newLabel(rewardsSize.width/2, 15, fontWithColor(3, {color = '#b6b6b6', text = __('已领取')})))
    view:addChild(display.newImageView(RES_DICT.ALBUM_REWARDS_LINE, rewardsPoint.x + 90, size.height/2 - 35))
    view:addChild(drawableLayer, 1)
    view:addChild(lockingLayer, 1)
    view:addChild(disableLayer, 1)

    local rewardsLightImg = display.newImageView(RES_DICT.REWARDS_LIGHT, rewardsPoint.x, rewardsPoint.y)
    view:addChild(rewardsLightImg)
    
    local rewardsIconLayer = display.newLayer(rewardsPoint.x, rewardsPoint.y)
    view:addChild(rewardsIconLayer)
    
    local rewardsGetIcon = display.newImageView(RES_DICT.REWARDS_DRAWED, rewardsPoint.x, rewardsPoint.y)
    view:addChild(rewardsGetIcon)
    

    -- cards layer
    local cardsSize  = cc.size(size.width - 250, size.height - 60)
    local cardsLayer = display.newLayer(size.width - 35, 0, {size = cardsSize, ap = display.RIGHT_BOTTOM, color1 = cc.r4b(150)})
    view:addChild(cardsLayer)

    local ROW_COUNT    = 2
    local COL_COUNT    = 5
    local ROW_SPACE    = checkint(cardsSize.height / ROW_COUNT)
    local COL_SPACE    = checkint(cardsSize.width / COL_COUNT)
    local cardNodeList = {}
    for row = 1, ROW_COUNT do
        for col = 1, COL_COUNT do
            local cardNode = TTGameUtils.GetBattleCardNode({showName = true})
            cardNode:setPositionY(cardsSize.height - (row-0.5) * ROW_SPACE)
            cardNode:setPositionX((col-0.5) * COL_SPACE)
            cardsLayer:addChild(cardNode)
            table.insert(cardNodeList, cardNode)
        end
    end

    return {
        view             = view,
        albumNameLabel   = albumNameLabel,
        collectNumLabel  = collectNumLabel,
        cardNodeList     = cardNodeList,
        lockingLayer     = lockingLayer,
        disableLayer     = disableLayer,
        drawableLayer    = drawableLayer,
        rewardsLightImg  = rewardsLightImg,
        rewardsIconLayer = rewardsIconLayer,
        rewardsGetIcon   = rewardsGetIcon,
    }
end


function TTGameAlbumView:getViewData()
    return self.viewData_
end


function TTGameAlbumView:getDeckList()
    return self.deckList_
end


function TTGameAlbumView.createAlbumCell(size)
    return CreateAlbumCell(size)
end


function TTGameAlbumView:updateDeckCellStatue(deckIndex, hasDeckList)
    local cellViewData = self:getDeckList()[checkint(deckIndex)]
    cellViewData.hasLayer:setVisible(hasDeckList == true)
    cellViewData.noneLayer:setVisible(hasDeckList ~= true)
end


function TTGameAlbumView:updateAlbumCellToLockingStatue(cellViewData)
    if not cellViewData then return end
    cellViewData.lockingLayer:setVisible(true)
    cellViewData.disableLayer:setVisible(false)
    cellViewData.drawableLayer:setVisible(false)
    cellViewData.rewardsLightImg:setVisible(false)
    cellViewData.rewardsGetIcon:setVisible(false)
    cellViewData.rewardsIconLayer:setColor(cc.c3b(255, 255, 255))
end


function TTGameAlbumView:updateAlbumCellToDrawbleStatue(cellViewData)
    if not cellViewData then return end
    cellViewData.lockingLayer:setVisible(false)
    cellViewData.disableLayer:setVisible(false)
    cellViewData.drawableLayer:setVisible(true)
    cellViewData.rewardsLightImg:setVisible(true)
    cellViewData.rewardsGetIcon:setVisible(false)
    cellViewData.rewardsIconLayer:setColor(cc.c3b(255, 255, 255))

    cellViewData.rewardsLightImg:stopAllActions()
    cellViewData.rewardsLightImg:runAction(cc.RepeatForever:create(cc.Spawn:create(
        cc.Sequence:create(
            cc.FadeTo:create(1, 55),
            cc.FadeTo:create(1, 255)
        ),
        cc.RotateBy:create(2, 90)
    )))
end


function TTGameAlbumView:updateAlbumCellTodisableStatue(cellViewData)
    if not cellViewData then return end
    cellViewData.lockingLayer:setVisible(false)
    cellViewData.disableLayer:setVisible(true)
    cellViewData.drawableLayer:setVisible(false)
    cellViewData.rewardsLightImg:setVisible(false)
    cellViewData.rewardsGetIcon:setVisible(true)
    cellViewData.rewardsIconLayer:setColor(cc.c3b(155, 155, 155))
end


function TTGameAlbumView:updateAlbumCellRewardIcon(cellViewData, rewardLevel)
    if not cellViewData then return end
    local rewardsIconPath = string.fmt('ui/ttgame/album/cardgame_collection_ico_reward_%1.png', checkint(rewardLevel))
    cellViewData.rewardsIconLayer:removeAllChildren()
    cellViewData.rewardsIconLayer:addChild(display.newImageView(_res(rewardsIconPath)))
end


return TTGameAlbumView
