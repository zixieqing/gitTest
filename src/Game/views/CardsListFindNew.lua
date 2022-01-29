--[[
 * author : kaishiqi
 * descpt : 飨灵列表 - 查找界面
]]
local CardsListFindNew = class('CardsListFindNew', function()
    return ui.layer({name = 'Game.views.CardsListFindNew', ap = ui.cc, enableEvent = true})
end)

local RES_DICT = {
    VIEW_FRAME   = _res('ui/home/kitchen/cooking_bg_make.png'),
    TITLE_BAR    = _res('ui/common/common_bg_title_3.png'),
    CHARS_BTN    = _res('ui/common/mb.png'),
    COUNT_ICON   = _res('ui/common/common_bg_hend_frame_blue.png'),
    SEARCH_BG    = _res('ui/collection/skinCollection/pokedex_monster_list_bg_1.png'),
    SEARCH_BTN   = _res('ui/collection/skinCollection/pokedex_monster_btn_search.png'),
    RESET_BTN    = _res('ui/collection/skinCollection/pokedex_monster_btn_back.png'),
    EDIT_BG      = _res('ui/collection/skinCollection/raid_boss_btn_search.png'),
    --           = find result view
    HEAD_FRAME   = _res('ui/collection/skinCollection/shop_btn_skin_default_1.png'),
    HEAD_NAME_BG = _res('ui/home/teamformation/choosehero/team_kapai_bg_name.png'),
    HEAD_BG      = _res('ui/cards/head/kapai_frame_bg.png'),
    GRID_BG      = _res('ui/collection/skinCollection/common_bg_goods.png'),
    
}

CardsListFindNew.DISPLAY_TYPE = {
    NORMAL_VIEW = 1,
    RESULT_VIEW = 2,
}

function CardsListFindNew:ctor(args)
    self:setPosition(display.center)

    -- init vars
    self.cardNameMap_  = {}
    self.findCardData_ = {}
    
    -- create view
    self.viewData_ = CardsListFindNew.CreateView()
    self:addChild(self.viewData_.view)
    
    -- add listener
    ui.bindClick(self:getViewData().blockLayer, handler(self, self.onClickCloseButtonHandler_))
    self:getViewData().indexGridView:setCellUpdateHandler(handler(CardsListFindNew.DISPLAY_TYPE.NORMAL_VIEW, handler(self, self.updateCellHandler_)))
    self:getViewData().indexGridView:setCellInitHandler(function(cellViewData)
        ui.bindClick(cellViewData.indexBtn, handler(self, self.onClickNormalCellHandler_), false)
    end)
    
    self:getViewData().commonEditView:registerScriptEditBoxHandler(handler(self, self.onEditBoxStateChangeHandler_))
    ui.bindClick(self:getViewData().searchBtn, handler(self, self.onClickSearchBtnHandler_))
    ui.bindClick(self:getViewData().resetBtn, handler(self, self.onClickResetBtnHandler_))
    
    self:getViewData().resultView:setCellUpdateHandler(handler(CardsListFindNew.DISPLAY_TYPE.RESULT_VIEW, handler(self, self.updateCellHandler_)))
    self:getViewData().resultView:setCellInitHandler(function(cellViewData)
        ui.bindClick(cellViewData.cellNode, handler(self, self.onClickResultCellHandler_), false)
    end)
    
    -- udpate data
    self:initCardConf(args.cardsMap)
    self:setCountMap(args.charsCountMap)
    self:setCharsArray(args.firstCharsList)
    self:setClickCellCB(args.clickCellCB)
    self:setResultCellClickCB(args.clickResultCB)
    self:updateEmptySkinViewVisible(false)
    self:setDisplayType(CardsListFindNew.DISPLAY_TYPE.NORMAL_VIEW)
end

function CardsListFindNew:initCardConf(cardsMap)
    self.cardNameMap_ = {}
    for k, cardInfo in pairs(cardsMap) do
        local cardId = cardInfo.cardId
        local cardConf = checktable(CONF.CARD.CARD_INFO:GetValue(cardId))
        local cardData = {
            cardId     = checkint(cardId),
            cardName   = CommonUtils.GetCardNameById(cardInfo.id)
        }
        self.cardNameMap_[k] = cardData
    end
end


-------------------------------------------------------------------------------
-- get / set
-------------------------------------------------------------------------------

function CardsListFindNew:getCardNameMap()
    return self.cardNameMap_ or {}
end


function CardsListFindNew:getViewData()
    return self.viewData_
end


function CardsListFindNew:getCountMap()
    return self.countMap_ or {}
end
function CardsListFindNew:setCountMap(map)
    self.countMap_ = checktable(map)
end


function CardsListFindNew:getCharsArray()
    return self.charsArray_ or {}
end
function CardsListFindNew:setCharsArray(array)
    self.charsArray_ = checktable(array)
end


function CardsListFindNew:getClickCellCB()
    return self.clickCellCB_
end
function CardsListFindNew:setClickCellCB(callback)
    self.clickCellCB_ = callback
end


function CardsListFindNew:getResultCellClickCB()
    return self.clickResultCB_
end
function CardsListFindNew:setResultCellClickCB(callback)
    self.clickResultCB_ = callback
end


function CardsListFindNew:getSearchCardName()
    return self.searchCardName_
end
function CardsListFindNew:setSearchCardName(cardName)
    self.searchCardName_ = checkstr(cardName)
    self:setSeachNameBoxText(self:getSearchCardName())
    if cardName == "" then 
        self:setDisplayType(CardsListFindNew.DISPLAY_TYPE.NORMAL_VIEW)
        self:updateEmptySkinViewVisible(false)
    else
        self:setDisplayType(CardsListFindNew.DISPLAY_TYPE.RESULT_VIEW)
        self:updateSelectedSkinCondition_()
    end
end


function CardsListFindNew:setSeachNameBoxText(text)
    self:getViewData().commonEditView:getViewData().descBox:setText(tostring(text))
end
function CardsListFindNew:getSeachNameBoxText()
    return self:getViewData().commonEditView:getViewData().descBox:getText()
end


function CardsListFindNew:getCardDataByRequireMent_(cardName)
    local resultCardData = {}
    if checkstr(cardName) == "" then
        resultCardData = self:getCharsArray()
    else
        for _, cardInfo in ipairs(self:getCardNameMap()) do
            if string.find(cardInfo.cardName, cardName) then
                table.insert(resultCardData, cardInfo)
            end
        end
    end
    return resultCardData
end


function CardsListFindNew:getCardDataByCardId(cardId)
    local cardData = nil
    for _,cardInfo in ipairs(self:getCardNameMap()) do
        if cardInfo.cardId == cardId then
            cardData = cardInfo
        end
    end
    return cardData
end


function CardsListFindNew:getKeyIdByCardId(id)
    local keyId = nil
    for _k, value in ipairs(self:getCardNameMap()) do
        if value.cardId == id then
            keyId = _k
        end
    end
    return keyId
end


function CardsListFindNew:getDisplayType()
    return self.displayType_
end
function CardsListFindNew:setDisplayType(displayType)
    self.displayType_ = displayType
    self:updateDisplaySkinCellType_(self:getDisplayType())

    if next(checktable(self:getCardNameMap())) ~= nil then
        if self:getDisplayType() == CardsListFindNew.DISPLAY_TYPE.NORMAL_VIEW then
            self:getViewData().indexGridView:resetCellCount(#self:getCharsArray())
        else
            self:getViewData().resultView:resetCellCount(#self:getCardNameMap())
        end
    end
end


-------------------------------------------------
-- public

function CardsListFindNew:close()
    self:runAction(cc.RemoveSelf:create())
end


-------------------------------------------------
-- private 

function CardsListFindNew:updateCellHandler_(displayType, cellIndex, cellViewData)
    if displayType == CardsListFindNew.DISPLAY_TYPE.RESULT_VIEW then
        if self.findCardData_ and self.findCardData_[checkint(cellIndex)] then
            local cardId   = checkint(self.findCardData_[checkint(cellIndex)].cardId)
            local cardData = self:getCardDataByCardId(cardId)
            self:onUpdateResultCell(cellIndex, cellViewData, cardData)
        end
    else
        self:onUpdateNormalCell(cellIndex, cellViewData)
    end
end


-- update cell info
function CardsListFindNew:onUpdateNormalCell(cellIndex, cellViewData)
    if cellViewData == nil then return end

    local charsText = tostring(self:getCharsArray()[cellIndex])
    cellViewData.indexBtn:updateLabel({text = charsText})
    cellViewData.indexBtn:setTag(cellIndex)

    local indexArray = checktable(self:getCountMap()[charsText])
    cellViewData.countBar:updateLabel{text = #indexArray}
    cellViewData.countBar:setVisible(#indexArray > 1)
end


function CardsListFindNew:onUpdateResultCell(cellIndex, cellViewData, cardData)
    if cellViewData == nil then return end

    cellViewData.nameTitle:updateLabel({text = tostring(cardData.cardName), reqW = 140})

    local skinPath = CardUtils.GetCardHeadPathByCardId(checkint(cardData.cardId))
    cellViewData.headIcon:setTexture(skinPath)

    cellViewData.cellNode:setTag(cardData.cardId)
end


function CardsListFindNew:updateEmptySkinViewVisible(visible)
    self:getViewData().emptySkinView:setVisible(visible)
end


function CardsListFindNew:updateSelectedSkinCondition_()
    local cardName = self:getSearchCardName()
    self.findCardData_ = self:getCardDataByRequireMent_(cardName)
    self:getViewData().resultView:resetCellCount(#self.findCardData_)
    self:updateEmptySkinViewVisible(#self.findCardData_ <= 0)
end


function CardsListFindNew:updateDisplaySkinCellType_(displayType)
    self:getViewData().indexGridView:setVisible(displayType == CardsListFindNew.DISPLAY_TYPE.NORMAL_VIEW)
    self:getViewData().resultView:setVisible(displayType == CardsListFindNew.DISPLAY_TYPE.RESULT_VIEW)
    self:getViewData().gridViewBg:setVisible(displayType == CardsListFindNew.DISPLAY_TYPE.RESULT_VIEW)
end


-------------------------------------------------
-- handler

function CardsListFindNew:onClickCloseButtonHandler_(sender)
    PlayAudioByClickClose()
    self:close()
end


function CardsListFindNew:onClickNormalCellHandler_(sender)
    PlayAudioByClickNormal()

    local cellIndex = checkint(sender:getTag())
    if self:getClickCellCB() then
        self:getClickCellCB()(cellIndex)
    end
end


function CardsListFindNew:onClickResultCellHandler_(sender)
    PlayAudioByClickNormal()

    local cellIndex = checkint(sender:getTag())
    local cellKeyId = self:getKeyIdByCardId(cellIndex)
    if self:getResultCellClickCB() then
        self:getResultCellClickCB()(cellKeyId)
    end
end


function CardsListFindNew:onEditBoxStateChangeHandler_(eventType, sender)
    if eventType == "return" then
        local text = string.trim(sender:getText())
        sender:setText(tostring(text))
    end
end


function CardsListFindNew:onClickSearchBtnHandler_(sender)
    PlayAudioByClickNormal()
    
    self:setSearchCardName(self:getSeachNameBoxText())
end


function CardsListFindNew:onClickResetBtnHandler_(sender)
    PlayAudioByClickNormal()

    self:setSearchCardName('')
end


-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------

function CardsListFindNew.CreateView()
    local view = ui.layer()
    local size = view:getContentSize()
    local cpos = cc.sizep(size, ui.cc)

    -- black / block layer
    local backGroundGroup = view:addList({
        ui.layer({color = cc.c4b(0,0,0,50)}),
        ui.layer({color = cc.r4b(0), enable = true}),
    })


    ------------------------------------------------- [center]
    local centerLayer = ui.layer()
    view:add(centerLayer)

    -- view frame
    local viewFrameSize = cc.size(740, 580)
    local viewFrameNode = ui.layer({p = cpos, size = viewFrameSize, bg = RES_DICT.VIEW_FRAME, ap = ui.cc, scale9 = true, enable = true})
    viewFrameNode:setPositionX(viewFrameNode:getPositionX() - 250)
    centerLayer:add(viewFrameNode)


    -- title bar
    local titleBar = ui.title({img = RES_DICT.TITLE_BAR}):updateLabel({fnt = FONT.D16, text = __('检索飨灵'), paddingW = 60, safeW = 120, offset = cc.p(0,-2)})
    viewFrameNode:addList(titleBar):alignTo(nil, ui.ct, {offsetY = -13})

    -- grid view
    local indexGridSzie = cc.resize(viewFrameSize, -40, -180)
    local indexGridView = ui.gridView({size = indexGridSzie, dir = display.SDIR_V, cols = 7, csizeH = 95})
    viewFrameNode:addList(indexGridView):alignTo(nil, ui.cb, {offsetY = 20})
    indexGridView:setCellCreateHandler(CardsListFindNew.CreateIndexCell)


    --------------------------------------  add createSearchNode
    local searchLayer = ui.layer({bg = RES_DICT.SEARCH_BG, ap = ui.rb, scale9 = true, size = cc.size(viewFrameSize.width - 40, 66)})
    centerLayer:addList(searchLayer):alignTo(viewFrameNode, ui.ct, {offsetX = 0, offsetY = -130})

    local debugLabel   = ui.label({text = __('请输入飨灵的名字'), fontSize = 20})
    local editViewSize = cc.size(math.max(218, debugLabel:getContentSize().width / 2 + 20), 40)
    local searchGroup  = searchLayer:addList({
        require('common.CommonEditView').new({placeHolder = debugLabel:getString(), maxLength = 50, bg = RES_DICT.EDIT_BG, isScale9 = true, bgSize = editViewSize, placeholderFontColor = "#ffffff", placeholderFontSize = 20, boxFontColor = "#ffffff", boxFontSize = 20}), 
        ui.button({n = RES_DICT.SEARCH_BTN}),
        ui.button({n = RES_DICT.RESET_BTN}),
    })
    ui.flowLayout(cc.rep(cc.sizep(searchLayer, ui.rc), -10, 0), searchGroup, {type = ui.flowH, ap = ui.rc, gapW = 10})
    searchGroup[1]:getViewData().descBox:setVisible(true)

    --------------------------------result card new head list
    local GRIDW = indexGridSzie.width
    local GRIDH = indexGridSzie.height
    local GRIDCELLW = 173
    local GRID_COL = math.floor(GRIDW / GRIDCELLW)

    local gridViewGroup = viewFrameNode:addList({
        ui.image({img = RES_DICT.GRID_BG, scale9 = true, size = indexGridSzie, mr = 5}),
        ui.gridView({cols = GRID_COL, size = indexGridSzie, csizeH = 210,dir = display.SDIR_V}),
    })
    ui.flowLayout(cc.rep(cc.sizep(viewFrameNode, ui.rc), -15, -60), gridViewGroup, {type = ui.flowC, ap = ui.rc})
    gridViewGroup[2]:setCellCreateHandler(CardsListFindNew.CreateHeadSkinCell)
    -- gridViewGroup[2]:setVisible(false)

    ------------------------------ empty skin View
    local bgWidth = indexGridSzie.width
    local emptySkinView = ui.layer({size = cc.size(bgWidth, 540)})
    viewFrameNode:addList(emptySkinView):alignTo(nil, ui.cc, {offsetY = -50})
    
    local emptySkinGroup = emptySkinView:addList({
        ui.label({text = __("当前暂无该飨灵"), fnt = FONT.D7, fontSize = 30, color = "#9d3b3b"}),
        AssetsUtils.GetCartoonNode(3, 0, 0, {scale = 0.6}),
    })
    ui.flowLayout(cc.sizep(emptySkinView, ui.cc), emptySkinGroup, {type = ui.flowH, ap = ui.cc})

    return {
        view            = view,
        blackLayer      = backGroundGroup[1],
        blockLayer      = backGroundGroup[2],
        --search component
        commonEditView  = searchGroup[1],
        searchBtn       = searchGroup[2],
        resetBtn        = searchGroup[3],
        emptySkinView   = emptySkinView,
        indexGridView   = indexGridView,
        --search result view
        gridViewBg      = gridViewGroup[1],
        resultView      = gridViewGroup[2]
        
    }
end


function CardsListFindNew.CreateHeadSkinCell(cellParent)
    local view = cellParent

    local bg        = ui.image({img = RES_DICT.HEAD_BG})
    local nameTitle = ui.title({n = RES_DICT.HEAD_NAME_BG}):updateLabel({fnt = FONT.D19, fontSize = 24, outline = "#000000", reqW = 200})
    local layerSize = cc.size(bg:getContentSize().width, bg:getContentSize().height + nameTitle:getContentSize().height)

    --- 解决头像点击后，回不到原来的缩放比例的问题
    local blockLayer = ui.layer({size = layerSize, scale = 0.9})
    view:addList(blockLayer)

    local cellNode = ui.layer({size = layerSize, color = cc.r4b(0), enable = true})
    blockLayer:addList(cellNode):alignTo(nil, ui.cc)

    --[bg | nameTitle]
    local cellGroup = cellNode:addList({
        ui.layer({size = bg:getContentSize()}),
        nameTitle,
    })
    ui.flowLayout(cc.rep(cc.sizep(cellNode, ui.cc), 10, 10), cellGroup, {type = ui.flowV, ap = ui.cc})

    local bgView = cellGroup[1]:addList({
        bg,
        CardsListFindNew.GetFilterImg(),
        CardsListFindNew.GetFilterImg(RES_DICT.HEAD_FRAME, 1.1),
    })
    ui.flowLayout(cc.rep(cc.sizep(cellGroup[1], ui.cc), 0, -15), bgView, {type = ui.flowC, ap = ui.cc})

    bgView[3]:setPosition(cc.rep(cc.p(bgView[3]:getPosition()), 7, 1))

    return {
        view      = view,
        nameTitle = nameTitle,
        headIcon  = bgView[2],
        cellNode  = cellNode,
        frame     = bgView[3],
    }
end


function CardsListFindNew.GetFilterImg(imgPath, scale)
    local node = FilteredSpriteWithOne:create()
    if imgPath then
        node:setTexture(imgPath)
    end
    if scale then
        node:setScale(scale)
    end
    return node
end


function CardsListFindNew.CreateIndexCell(cellParent)
    local view = cellParent
    local size = view:getContentSize()
    local cpos = cc.sizep(size, ui.cc)
    -- view:add(ui.layer({size = size, color = cc.r4b(150)}))

    local indexBtn = ui.button({n = RES_DICT.CHARS_BTN, p = cpos}):updateLabel({fnt = FONT.D16, fontSize = 30/0.6})
    indexBtn:setScale(0.6)
    view:add(indexBtn)
    
    local countBar = ui.title({img = RES_DICT.COUNT_ICON, size = cc.size(30, 30), cut = cc.dir(12,12,12,12), p = cc.rep(cpos, 30, -30)})
    countBar:updateLabel({fnt = FONT.D3, fontSize = 22, text = '8'})
    view:add(countBar)

    return {
        view     = view,
        indexBtn = indexBtn,
        countBar = countBar,
    }
end


return CardsListFindNew
