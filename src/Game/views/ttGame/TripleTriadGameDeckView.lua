--[[
 * author : kaishiqi
 * descpt : 打牌游戏 - 卡组视图
]]
local TTGameDeckView = class('TripleTriadGameDeckView', function()
    return display.newLayer(0, 0, {name = 'TripleTriadGameDeckView'})
end)

local RES_DICT = {
    COM_TIPS_ICON     = _res('ui/common/common_btn_tips.png'),
    COM_BACK_BTN      = _res('ui/common/common_btn_back.png'),
    BG_IMAGE          = _res('ui/ttgame/deck/cardgame_deck_bg.jpg'),
    CUTTING_LINE      = _res('ui/ttgame/deck/cardgame_deck_line_bg.png'),
    UNLOCK_FRAME      = _res('ui/ttgame/deck/cardgame_deck_label_LVlock.png'),
    --                = deck
    BTN_SAVE_N        = _res('ui/common/common_btn_orange.png'),
    DECK_FRAME        = _res('ui/ttgame/deck/cardgame_deck_bg_group.png'),
    DECK_SLOT         = _res('ui/ttgame/deck/cardgame_deck_group_slot.png'),
    DECK_SIDE         = _res('ui/ttgame/deck/cardgame_deck_label_groupnum.png'),
    CARD_LIST_FRAME   = _res('ui/ttgame/deck/cardgame_deck_bg_cards.png'),
    --                = type
    CARD_STAR_N       = _res('ui/ttgame/deck/cardgame_deck_ico_star.png'),
    CARD_STAR_D       = _res('ui/ttgame/deck/cardgame_deck_ico_star_grey.png'),
    FILTER_STAR_S     = _res('ui/ttgame/deck/cardgame_deck_tab_btn_active.png'),
    FILTER_STAR_N     = _res('ui/ttgame/deck/cardgame_deck_tab_btn_default.png'),
    STAR_CUTTING_LING = _res('ui/ttgame/deck/cardgame_deck_tab_line.png'),
    FILTER_TYPE_BTN_N = _res('ui/home/teamformation/choosehero/team_btn_selection_unused.png'),
    FILTER_TYPE_BTN_S = _res('ui/home/teamformation/choosehero/team_btn_selection_choosed.png'),
    FILTER_TYPE_ARROW = _res('ui/home/cardslistNew/card_ico_direction.png'),
}

local CreateView     = nil
local CreateDeckCell = nil
local CreateCardCell = nil
local CreateStarCell = nil
local DECK_CARD_SIZE = cc.size(122, 120)
local STAR_CELL_SIZE = cc.size(180, 72)


function TTGameDeckView:ctor(args)
    -- create view
    self.viewData_ = CreateView()
    self:addChild(self.viewData_.view)

    self.deckCardViewDataList_ = {}
    local deckLayerSize = self:getViewData().deckLayer:getContentSize()
    for cardIndex = 1, TTGAME_DEFINE.DECK_CARD_NUM do
        local deckCardViewData = CreateDeckCell(DECK_CARD_SIZE)
        deckCardViewData.view:setPositionX(15 + (DECK_CARD_SIZE.width+2) * (cardIndex-0.5))
        deckCardViewData.view:setPositionY(deckLayerSize.height/2 + 5)
        deckCardViewData.view:setTag(cardIndex)
        deckCardViewData.hotspot:setTag(cardIndex)
        self:getViewData().deckLayer:addChild(deckCardViewData.view)
        table.insert(self.deckCardViewDataList_, deckCardViewData)
    end

    self.starCellViewDataList_ = {}
    local starFilterLayerSize  = self:getViewData().starFilterLayer:getContentSize()
    for starNum = 1, TTGAME_DEFINE.STAR_MAXIMUM do
        local starCellViewData = CreateStarCell(STAR_CELL_SIZE)
        starCellViewData.view:setPositionX(starFilterLayerSize.width / 2)
        starCellViewData.view:setPositionY(starFilterLayerSize.height - STAR_CELL_SIZE.height * (starNum-0.5))
        starCellViewData.view:setTag(starNum)
        starCellViewData.hotspot:setTag(starNum)
        self:updateFilterStarNumAt(starCellViewData, starNum)
        self:getViewData().starFilterLayer:addChild(starCellViewData.view)
        table.insert(self.starCellViewDataList_, starCellViewData)

        local starCuttingLine = display.newImageView(RES_DICT.STAR_CUTTING_LING, starCellViewData.view:getPositionX(), starCellViewData.view:getPositionY() + STAR_CELL_SIZE.height/2)
        self:getViewData().starFilterLayer:addChild(starCuttingLine)
        if starNum == TTGAME_DEFINE.STAR_MAXIMUM then
            local starCuttingLine = display.newImageView(RES_DICT.STAR_CUTTING_LING, starCellViewData.view:getPositionX(), starCellViewData.view:getPositionY() - STAR_CELL_SIZE.height/2)
            self:getViewData().starFilterLayer:addChild(starCuttingLine)
        end
    end

    self:updateFilterButtonLabel()
end


CreateView = function()
    local view = display.newLayer()
    local size = view:getContentSize()

    -- block layer
    view:addChild(display.newLayer(0, 0, {color = cc.c4b(100,50,100,255), enable = true}))
    view:addChild(display.newImageView(RES_DICT.BG_IMAGE, size.width/2, size.height/2))
    view:addChild(display.newImageView(RES_DICT.CUTTING_LINE, size.width/2, size.height - 178))

    ------------------------------------------------- [top]
    local topLayer = display.newLayer()
    view:addChild(topLayer)

    -- back button
    local backBtn = display.newButton(display.SAFE_L + 75, size.height - 52, {n = RES_DICT.COM_BACK_BTN})
    topLayer:addChild(backBtn)
    
    -- unlock info
    local unlockSize  = cc.size(250 + display.SAFE_L, 100)
    local unlockLayer = display.newImageView(RES_DICT.UNLOCK_FRAME, display.width, display.height - 20, {size = unlockSize, enable = true, ap = display.RIGHT_TOP})
    topLayer:addChild(unlockLayer)

    unlockLayer:addChild(display.newImageView(RES_DICT.COM_TIPS_ICON, unlockSize.width - display.SAFE_L - 25, unlockSize.height - 15))
    unlockLayer:addChild(display.newLabel(unlockSize.width - display.SAFE_L - 50, unlockSize.height - 15, fontWithColor(8, {color = '#ffc400', text = __('卡组解锁等级'), ap = display.RIGHT_CENTER})))

    local unlockLable = display.newLabel((unlockSize.width - display.SAFE_L)/2 + 30, unlockSize.height/2 - 20, fontWithColor(20, {fontSize = 26, outline = '#a7894c', text = '--'}))
    unlockLayer:addChild(display.newImageView(RES_DICT.CARD_STAR_N, unlockLable:getPositionX(), unlockLable:getPositionY()))
    unlockLayer:addChild(unlockLable)


    -- deck layer
    local deckLayer = display.newLayer(size.width/2 - 40, size.height - 25, {size = deckSize, ap = display.CENTER_TOP, bg = RES_DICT.DECK_FRAME})
    local deckSize  = deckLayer:getContentSize()
    topLayer:addChild(deckLayer)

    local deckIndexBar = display.newButton(15, deckSize.height - 10, {n = RES_DICT.DECK_SIDE, ap = display.RIGHT_TOP, enable = false})
    display.commonLabelParams(deckIndexBar, fontWithColor(2, {color = '#FFFFFF', text = '-'}))
    deckLayer:addChild(deckIndexBar)

    local saveBtn = display.newButton(deckSize.width - 35, deckSize.height/2 - 25, {n = RES_DICT.BTN_SAVE_N, ap = display.RIGHT_CENTER})
    display.commonLabelParams(saveBtn, fontWithColor(14, {text = __('保存')}))
    deckLayer:addChild(saveBtn)


    ------------------------------------------------- [center]
    local centerLayer = display.newLayer()
    view:addChild(centerLayer)

    -- card grid
    local gridFrameSize = cc.size(1070, size.height - 200)
    local cardGridFrame = display.newImageView(RES_DICT.CARD_LIST_FRAME, display.cx - 450, 0, {size = gridFrameSize, scale9 = true, ap = display.LEFT_BOTTOM}) 
    centerLayer:addChild(cardGridFrame)

    local CARD_COLUMNS = 6
    local cardGridSize = cc.size(gridFrameSize.width - 6, gridFrameSize.height - 3)
    local cardGridView = CGridView:create(cardGridSize)
    cardGridView:setSizeOfCell(cc.size(math.floor(cardGridSize.width / CARD_COLUMNS), 205))
    cardGridView:setPosition(cardGridFrame:getPositionX() + gridFrameSize.width/2, cardGridFrame:getPositionY())
    cardGridView:setAnchorPoint(display.CENTER_BOTTOM)
    cardGridView:setColumns(CARD_COLUMNS)
    -- cardGridView:setBackgroundColor(cc.c4b(100,100,50,255))
    centerLayer:addChild(cardGridView)
    
    -- star filter
    local starFilterSize  = cc.size(STAR_CELL_SIZE.width, cardGridSize.height - 80)
    local starFilterLayer = display.newLayer(display.cx - 455, 0, {size = starFilterSize, color1 = cc.c4b(50), ap = display.RIGHT_BOTTOM})
    centerLayer:addChild(starFilterLayer)
    
    -- type filter button
    local typeFilterBtn  = display.newToggleView(0, 0, {n = RES_DICT.FILTER_TYPE_BTN_N, s = RES_DICT.FILTER_TYPE_BTN_S, scale9 = true, size = cc.size(STAR_CELL_SIZE.width - 20, 50)})
    local typeFilterSize = typeFilterBtn:getContentSize()
    typeFilterBtn:setPositionX(starFilterLayer:getPositionX() - starFilterSize.width/2)
    typeFilterBtn:setPositionY(starFilterLayer:getPositionY() + starFilterSize.height + 45)
    centerLayer:addChild(typeFilterBtn)
    
    local typeFilterNLabel = display.newLabel(typeFilterSize.width/2, typeFilterSize.height/2, fontWithColor(18, {color = '#FFFFFF'}))
    local typeFilterSLabel = display.newLabel(typeFilterSize.width/2, typeFilterSize.height/2, fontWithColor(18, {color = '#ffcf96'}))
    typeFilterBtn:addChild(display.newImageView(RES_DICT.FILTER_TYPE_ARROW, typeFilterSize.width - 22, typeFilterSize.height/2))
    typeFilterBtn:getNormalImage():addChild(typeFilterNLabel)
    typeFilterBtn:getSelectedImage():addChild(typeFilterSLabel)

    return {
        view             = view,
        topLayer         = topLayer,
        backBtn          = backBtn,
        unlockLayer      = unlockLayer,
        unlockLable      = unlockLable,
        deckIndexBar     = deckIndexBar,
        saveBtn          = saveBtn,
        deckLayer        = deckLayer,
        cardGridView     = cardGridView,
        starFilterLayer  = starFilterLayer,
        typeFilterBtn    = typeFilterBtn,
        typeFilterNLabel = typeFilterNLabel,
        typeFilterSLabel = typeFilterSLabel,
    }
end


CreateDeckCell = function(size)
    local view = display.newLayer(0, 0, {size = size, ap = display.CENTER})
    view:addChild(display.newImageView(RES_DICT.DECK_SLOT, size.width/2, size.height/2))

    local cardLayer = display.newLayer(size.width/2, size.height/2 + 8)
    view:addChild(cardLayer)

    local cardNode = TTGameUtils.GetBattleCardNode({zoomModel = 's'})
    cardLayer:addChild(cardNode)
    cardNode:setVisible(false)

    local hotspot = display.newLayer(0, 0, {size = size, color = cc.r4b(0), enable = true})
    view:addChild(hotspot)

    return {
        view      = view,
        hotspot   = hotspot,
        cardNode  = cardNode,
    }
end


CreateCardCell = function(size)
    local view = CGridViewCell:new()
    view:setContentSize(size)

    local cardLayer = display.newLayer(size.width/2, size.height/2)
    view:addChild(cardLayer)

    local cardNode = TTGameUtils.GetBattleCardNode({zoomModel = 'm'})
    cardLayer:addChild(cardNode)

    local hotspot = display.newLayer(0, 0, {size = size, color = cc.r4b(0), enable = true})
    view:addChild(hotspot)

    return {
        view      = view,
        hotspot   = hotspot,
        cardNode  = cardNode,
    }
end


CreateStarCell = function(size)
    local view = display.newLayer(0, 0, {size = size, color1 = cc.r4b(100), ap = display.CENTER})
    local cPos = cc.p(size.width/2, size.height/2)

    local nFrameImg = display.newImageView(RES_DICT.FILTER_STAR_N, cPos.x, cPos.y)
    local sFrameImg = display.newImageView(RES_DICT.FILTER_STAR_S, cPos.x, cPos.y)
    view:addChild(nFrameImg)
    view:addChild(sFrameImg)
    
    local nStarIcon = display.newImageView(RES_DICT.CARD_STAR_N, cPos.x, cPos.y)
    local dStarIcon = display.newImageView(RES_DICT.CARD_STAR_D, cPos.x, cPos.y)
    nStarIcon:setPosition(utils.getLocalCenter(nFrameImg))
    dStarIcon:setPosition(utils.getLocalCenter(sFrameImg))
    view:addChild(nStarIcon)
    view:addChild(dStarIcon)
    
    local nStarLabel = display.newLabel(0, 0, fontWithColor(20, {fontSize = 26, outline = '#a7894c', text = '--'}))
    local dStarLabel = display.newLabel(0, 0, fontWithColor(20, {fontSize = 26, outline = '#aaaaaa', text = '--'}))
    nStarLabel:setPosition(utils.getLocalCenter(nStarIcon))
    dStarLabel:setPosition(utils.getLocalCenter(dStarIcon))
    nStarIcon:addChild(nStarLabel)
    dStarIcon:addChild(dStarLabel)

    local hotspot = display.newLayer(0, 0, {size = size, color = cc.r4b(0), enable = true})
    view:addChild(hotspot)

    return {
        view       = view,
        hotspot    = hotspot,
        nStarIcon  = nStarIcon,
        dStarIcon  = dStarIcon,
        nFrameImg  = nFrameImg,
        sFrameImg  = sFrameImg,
        nStarLabel = nStarLabel,
        dStarLabel = dStarLabel,
    }
end


function TTGameDeckView:getViewData()
    return self.viewData_
end


function TTGameDeckView:getDeckCardViewDataList()
    return self.deckCardViewDataList_
end


function TTGameDeckView:getStarCellViewDataList()
    return self.starCellViewDataList_
end


function TTGameDeckView.CreateLibraryCardCell(size)
    return CreateCardCell(size)
end


-------------------------------------------------

function TTGameDeckView:updateUnlockLevel(level)
    display.commonLabelParams(self:getViewData().unlockLable, {text = TTGameUtils.GetCardLevelText(level)})
end


function TTGameDeckView:updateDeckIndex(index)
    display.commonLabelParams(self:getViewData().deckIndexBar, {text = tostring(index)})
end


function TTGameDeckView:updateFilterStarNumAt(cellViewData, starNum)
    display.commonLabelParams(cellViewData.nStarLabel, {text = TTGameUtils.GetCardLevelText(starNum)})
    display.commonLabelParams(cellViewData.dStarLabel, {text = TTGameUtils.GetCardLevelText(starNum)})
end


function TTGameDeckView:updateFilterStarStatus(selectStartNum, starCardNumMap)
    for _, cellViewData in ipairs(self:getStarCellViewDataList()) do
        local startCellNum = checkint(cellViewData.view:getTag())
        local isSelectStar = checkint(selectStartNum) == startCellNum
        local starCardNum  = checkint(starCardNumMap[tostring(startCellNum)])
        local hasStarCard  = starCardNum > 0
        cellViewData.sFrameImg:setVisible(isSelectStar)
        cellViewData.nFrameImg:setVisible(not isSelectStar)
        cellViewData.nStarIcon:setVisible(hasStarCard)
        cellViewData.dStarIcon:setVisible(not hasStarCard)
    end
end


function TTGameDeckView:updateFilterButtonLabel(buttonName)
    display.commonLabelParams(self:getViewData().typeFilterSLabel, {text = buttonName or __('组别')})
    display.commonLabelParams(self:getViewData().typeFilterNLabel, {text = buttonName or __('组别')})
end


return TTGameDeckView
