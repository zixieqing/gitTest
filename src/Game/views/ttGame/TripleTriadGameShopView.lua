--[[
 * author : kaishiqi
 * descpt : 打牌游戏 - 牌店视图
]]
local GoodPurchaseNode = require('common.GoodPurchaseNode')
local TTGameShopView   = class('TripleTriadGameShopView', function()
    return display.newLayer(0, 0, {name = 'TripleTriadGameShopView'})
end)

local RES_DICT = {
    COM_TITLE_BAR           = _res('ui/common/common_title.png'),
    COM_TIPS_ICON           = _res('ui/common/common_btn_tips.png'),
    COM_BACK_BTN            = _res('ui/common/common_btn_back.png'),
    MONEY_INFO_BAR          = _res('ui/home/nmain/main_bg_money.png'),
    BACK_FRAME_IMG          = _res('ui/stores/base/shop_bg_add.png'),
    TYPE_CELL_FRAME_SELECT  = _res('ui/stores/base/shop_btn_tab_select.png'),
    TYPE_CELL_FRAME_DEFAULT = _res('ui/stores/base/shop_btn_tab_default.png'),
    STAR_CUTTING_LING       = _res('ui/ttgame/deck/cardgame_deck_tab_line.png'),
    CARD_STAR_N             = _res('ui/ttgame/deck/cardgame_deck_ico_star.png'),
    CARD_STAR_D             = _res('ui/ttgame/deck/cardgame_deck_ico_star_grey.png'),
    FILTER_STAR_S           = _res('ui/ttgame/deck/cardgame_deck_tab_btn_active.png'),
    FILTER_STAR_N           = _res('ui/ttgame/deck/cardgame_deck_tab_btn_default.png'),
    CARD_LIST_FRAME         = _res('ui/ttgame/deck/cardgame_deck_bg_cards.png'),
}

local TYPE_CELL_DEFINES = {
    {image = 'cardgame_shop_btn_tab_img_1', name = __('购买卡包'), moneyIdMap = {[TTGAME_DEFINE.CURRENCY_ID] = true}},
    {image = 'cardgame_shop_btn_tab_img_2', name = __('兑换战牌'), moneyIdMap = {[TTGAME_DEFINE.EXCHANGE_ID] = true}},
}

local CreateView     = nil
local CreateTypeCell = nil
local CreateStarCell = nil
local TYPE_CELL_SIZE = cc.size(240, 114)
local STAR_CELL_SIZE = cc.size(TYPE_CELL_SIZE.width - 70, 64)


function TTGameShopView:ctor(args)
    -- create view
    self.viewData_ = CreateView()
    self:addChild(self.viewData_.view)

    -- init views
    self.typeCellVDList_ = {}
    local typeLayerSize = self:getViewData().typeCellLayer:getContentSize()
    for cellIndex, typeCellDefine in ipairs(TYPE_CELL_DEFINES) do
        local cellViewData = CreateTypeCell(TYPE_CELL_SIZE)
        self:initTypeCellBaseInfo_(cellViewData, typeCellDefine)
        cellViewData.view:setPositionX(typeLayerSize.width/2)
        cellViewData.view:setPositionY(typeLayerSize.height - (cellIndex-1) * TYPE_CELL_SIZE.height)
        cellViewData.view:setTag(cellIndex)
        cellViewData.hotspot:setTag(cellIndex)
        self:getViewData().typeCellLayer:addChild(cellViewData.view)
        table.insert(self.typeCellVDList_, cellViewData)
    end

    self.starCellVDList_ = {}
    local STAR_SPACE_H   = 0
    local STAR_BORDER_W  = 5
    local STAR_BORDER_H  = 10
    local starLayerSizeW = STAR_BORDER_W*2 + STAR_CELL_SIZE.width
    local starLayerSizeH = STAR_BORDER_H*2 + (STAR_CELL_SIZE.height + STAR_SPACE_H) * TTGAME_DEFINE.STAR_MAXIMUM - STAR_SPACE_H
    self:getViewData().starCellLayer:setPositionY(typeLayerSize.height - #TYPE_CELL_DEFINES * TYPE_CELL_SIZE.height - 5)
    self:getViewData().starCellLayer:setContentSize(cc.size(starLayerSizeW, starLayerSizeH))
    self:getViewData().starCellBgImg:setContentSize(cc.size(starLayerSizeW, starLayerSizeH))
    
    for starNum = 1, TTGAME_DEFINE.STAR_MAXIMUM do
        local cellViewData = CreateStarCell(STAR_CELL_SIZE)
        self:initStarCellBaseInfo_(cellViewData, starNum)
        cellViewData.view:setPositionX(starLayerSizeW / 2)
        cellViewData.view:setPositionY(starLayerSizeH - STAR_BORDER_H - (starNum-0.5) * (STAR_CELL_SIZE.height + STAR_SPACE_H))
        cellViewData.view:setTag(starNum)
        cellViewData.hotspot:setTag(starNum)
        self:getViewData().starCellLayer:addChild(cellViewData.view)
        table.insert(self.starCellVDList_, cellViewData)

        local starCuttingLine = display.newImageView(RES_DICT.STAR_CUTTING_LING, cellViewData.view:getPositionX(), cellViewData.view:getPositionY() + STAR_CELL_SIZE.height/2)
        self:getViewData().starCellLayer:addChild(starCuttingLine)
        if starNum == TTGAME_DEFINE.STAR_MAXIMUM then
            local starCuttingLine = display.newImageView(RES_DICT.STAR_CUTTING_LING, cellViewData.view:getPositionX(), cellViewData.view:getPositionY() - STAR_CELL_SIZE.height/2)
            self:getViewData().starCellLayer:addChild(starCuttingLine)
        end
    end

    self:reloadMoneyBar()
end


CreateView = function()
    local view = display.newLayer()
    local size = view:getContentSize()

    -- block layer
    view:addChild(display.newLayer(0, 0, {color = cc.c4b(0,0,0,150), enable = true}))


    ------------------------------------------------- [center]
    -- center layer
    local centerLayer = display.newLayer()
    view:addChild(centerLayer)

    -- center bg
    local centerPos = cc.p(size.width/2 + 18, size.height/2 - 40)
    centerLayer:addChild(display.newImageView(RES_DICT.BACK_FRAME_IMG, centerPos.x, centerPos.y))

    -- store layer
    local storeSize  = cc.size(1072, 638)
    local storeLayer = display.newLayer(centerPos.x + 94, centerPos.y - 5, {size = storeSize, ap = display.CENTER, color1 = cc.r4b(150)})
    centerLayer:addChild(storeLayer)
    
    -- typeCell layer
    local typeLayerSize = cc.size(TYPE_CELL_SIZE.width, storeSize.height)
    local typeCellLayer = display.newLayer(0, 0, {size = typeLayerSize})
    typeCellLayer:setAnchorPoint(display.RIGHT_CENTER)
    typeCellLayer:setPositionX(storeLayer:getPositionX() - storeSize.width/2 - 3)
    typeCellLayer:setPositionY(centerPos.y - 5)
    centerLayer:addChild(typeCellLayer)

    -- starCell layer 
    local starCellLayer = display.newLayer(typeLayerSize.width/2, 0, {ap = display.CENTER_TOP})
    -- starCellLayer:setBackgroundColor(cc.c4b(50,30,50,200))
    typeCellLayer:addChild(starCellLayer)
    
    local starCellBgImg = display.newImageView(RES_DICT.CARD_LIST_FRAME, 0, 0, {ap = display.LEFT_BOTTOM, scale9 = true})
    starCellLayer:addChild(starCellBgImg)


    ------------------------------------------------- [top]
    -- top layer
    local topLayer = display.newLayer()
    view:addChild(topLayer)

    -- back button
    local backBtn = display.newButton(display.SAFE_L + 75, size.height - 52, {n = RES_DICT.COM_BACK_BTN})
    topLayer:addChild(backBtn)

    -- title button
    local titleBtn = display.newButton(display.SAFE_L + 120, size.height, {n = RES_DICT.COM_TITLE_BAR, ap = display.LEFT_TOP})
    display.commonLabelParams(titleBtn, fontWithColor(1, {text = __('牌店'), offset = cc.p(0,-10)}))
    topLayer:addChild(titleBtn)

    local titleSize = titleBtn:getContentSize()
    titleBtn:addChild(display.newImageView(RES_DICT.COM_TIPS_ICON, titleSize.width - 50, titleSize.height/2 - 10))

    -- money barBg
    local moneyBarBg = display.newImageView(_res(RES_DICT.MONEY_INFO_BAR), display.width, display.height, {ap = display.RIGHT_TOP, scale9 = true, size = cc.size(1, 54)})
    topLayer:addChild(moneyBarBg)

    -- money layer
    local moneyLayer = display.newLayer()
    topLayer:addChild(moneyLayer)

    return {
        view               = view,
        topLayer           = topLayer,
        topLayerHidePos    = cc.p(topLayer:getPositionX(), 100),
        topLayerShowPos    = cc.p(topLayer:getPosition()),
        titleBtn           = titleBtn,
        titleBtnHidePos    = cc.p(titleBtn:getPositionX(), titleBtn:getPositionY() + 190),
        titleBtnShowPos    = cc.p(titleBtn:getPosition()),
        backBtn            = backBtn,
        moneyBarBg         = moneyBarBg,
        moneyLayer         = moneyLayer,
        centerLayer        = centerLayer,
        centerLayerHidePos = cc.p(centerLayer:getPositionX(), -display.height),
        centerLayerShowPos = cc.p(centerLayer:getPosition()),
        storeLayer         = storeLayer,
        typeCellLayer      = typeCellLayer,
        starCellLayer      = starCellLayer,
        starCellBgImg      = starCellBgImg,
    }
end


CreateTypeCell = function(size)
    local view = display.newLayer(0, 0, {size = size, ap = display.CENTER_TOP})
    
    -- block layer
    local centerPos  = cc.p(size.width/2, size.height/2)
    view:addChild(display.newLayer(0, 0, {size = size, color = cc.r4b(0), enable = true}))
    
    -- image layer
    local imageLayer = display.newLayer(centerPos.x, centerPos.y, {ap = display.LEFT_BOTTOM, size = imageSize})
    view:addChild(imageLayer)

    -- normal frame
    local frameNormal = display.newImageView(RES_DICT.TYPE_CELL_FRAME_DEFAULT, centerPos.x, centerPos.y)
    view:addChild(frameNormal)

    -- name label
    local nameLabel = display.newLabel(size.width/2, 24, fontWithColor(20, {fontSize = 22, outline = '#763805'}))
    view:addChild(nameLabel)

    -- select frame
    local frameSelect = display.newImageView(RES_DICT.TYPE_CELL_FRAME_SELECT, centerPos.x, centerPos.y)
    view:addChild(frameSelect)
    
    -- click hostpot
    local hotspot = display.newLayer(0, 0, {size = size, color = cc.r4b(0), enable = true})
    view:addChild(hotspot)
    
    return {
        view        = view,
        hotspot     = hotspot,
        imageLayer  = imageLayer,
        nameLabel   = nameLabel,
        frameNormal = frameNormal,
        frameSelect = frameSelect,
    }
end


CreateStarCell = function(size)
    local view = display.newLayer(0, 0, {size = size, color1 = cc.r4b(100), ap = display.CENTER})
    local cPos = cc.p(size.width/2, size.height/2)

    local nFrameImg = display.newImageView(RES_DICT.FILTER_STAR_N, cPos.x, cPos.y, {scale9 = true, size = size})
    local sFrameImg = display.newImageView(RES_DICT.FILTER_STAR_S, cPos.x, cPos.y, {scale9 = true, size = size})
    view:addChild(nFrameImg)
    view:addChild(sFrameImg)

    local nStarIcon = display.newImageView(RES_DICT.CARD_STAR_N, cPos.x, cPos.y, {scale = 0.9})
    local dStarIcon = display.newImageView(RES_DICT.CARD_STAR_D, cPos.x, cPos.y, {scale = 0.9})
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


function TTGameShopView:getViewData()
    return self.viewData_
end


function TTGameShopView:reloadMoneyBar(moneyIdMap, isDisableGain)
    -- filter money
    if moneyIdMap then
        moneyIdMap[tostring(GOLD_ID)]         = nil
        moneyIdMap[tostring(DIAMOND_ID)]      = nil
        moneyIdMap[tostring(PAID_DIAMOND_ID)] = nil
        moneyIdMap[tostring(FREE_DIAMOND_ID)] = nil
    end
    
    -- sort money data
    local moneyIdList = {
        {disable = false, id = GOLD_ID},
        {disable = true,  id = DIAMOND_ID},
    }
    for moneyId, _ in pairs(moneyIdMap or {}) do
        table.insert(moneyIdList, 1, {id = checkint(moneyId), disable = true})
    end
    
    -- clean moneyLayer
    local moneyBarBg = self:getViewData().moneyBarBg
    local moneyLayer = self:getViewData().moneyLayer
    moneyLayer:removeAllChildren()
    
    -- update moneyLayer
    local MONEY_NODE_GAP = 16
    local moneyLayerSize = moneyLayer:getContentSize()
    local moneryBarSize  = cc.size(20, moneyBarBg:getContentSize().height)
    for i = #moneyIdList, 1, -1 do
        local moneyId   = checkint(moneyIdList[i].id)
        local isDisable = moneyIdList[i].disable == true
        local moneyNode = GoodPurchaseNode.new({id = moneyId, animate = true, disable = isDisable})
        moneyNode.viewData.touchBg:setTag(checkint(moneyId))
        moneyNode:setPosition(display.SAFE_R - moneryBarSize.width, moneyLayerSize.height - 26)
        moneyNode:setControllable(moneyId ~= DIAMOND_ID)
        moneyNode:setAnchorPoint(display.RIGHT_CENTER)
        moneyNode:setName(moneyId)
        moneyLayer:addChild(moneyNode)

        moneryBarSize.width = moneryBarSize.width + moneyNode:getContentSize().width + MONEY_NODE_GAP
    end

    -- update moneyBarBg
    moneryBarSize.width = 40 + moneryBarSize.width + (display.width - display.SAFE_R)
    moneyBarBg:setContentSize(moneryBarSize)

    -- update money value
    self:updateMoneyBar()
end


function TTGameShopView:updateMoneyBar()
    for _, moneyNode in ipairs(self:getViewData().moneyLayer:getChildren()) do
        local moneyId = checkint(moneyNode:getName())
        moneyNode:updataUi(moneyId)
    end
end


-------------------------------------------------
-- type cell

function TTGameShopView:getTypeCellViewDataList()
    return self.typeCellVDList_
end


function TTGameShopView:initTypeCellBaseInfo_(cellViewData, typeCellDefine)
    local cellDefine = typeCellDefine or {}
    display.commonLabelParams(cellViewData.nameLabel, {text = checkstr(cellDefine.name)})

    local typeImagePath = _res(string.fmt('ui/ttgame/shop/%1.jpg', tostring(cellDefine.image)))
    cellViewData.imageLayer:addChild(display.newImageView(typeImagePath))
end


function TTGameShopView:updateSelectTypeIndex(selectTypeIndex, isNeedStarFilter)
    for cellIndex, cellViewData in ipairs(self:getTypeCellViewDataList()) do
        local isSelected = checkint(selectTypeIndex) == cellIndex
        cellViewData.frameSelect:setVisible(isSelected)
    end

    local typeCellDefine = TYPE_CELL_DEFINES[checkint(selectTypeIndex)] or {}
    self:reloadMoneyBar(typeCellDefine.moneyIdMap)

    self:getViewData().starCellLayer:setVisible(isNeedStarFilter == true)
end


-------------------------------------------------
-- star cell

function TTGameShopView:getStarCellViewDataList()
    return self.starCellVDList_
end


function TTGameShopView:initStarCellBaseInfo_(cellViewData, starNum)
    display.commonLabelParams(cellViewData.nStarLabel, {text = TTGameUtils.GetCardLevelText(starNum)})
    display.commonLabelParams(cellViewData.dStarLabel, {text = TTGameUtils.GetCardLevelText(starNum)})
end


function TTGameShopView:updateFilterStarStatus(selectStartNum, starCardNumMap)
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


return TTGameShopView
