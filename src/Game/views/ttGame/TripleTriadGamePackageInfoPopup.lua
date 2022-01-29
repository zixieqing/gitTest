--[[
 * author : kaishiqi
 * descpt : 打牌游戏 - 卡包详情弹窗
]]
local CommonDialog           = require('common.CommonDialog')
local TTGamePackageInfoPopup = class('TripleTriadGamePackageInfoPopup', CommonDialog)

local RES_DICT = {
    BG_FRAME   = _res('ui/common/common_bg_4.png'),
    COM_TITLE  = _res('ui/common/common_bg_title_3.png'),
    GOODS_LINE = _res('ui/ttgame/shop/cardgame_shop_line_pr.png'),
    TITLE_LINE = _res('ui/ttgame/shop/cardgame_shop_line_title.png'),
}

local CreateView     = nil
local CreateCardCell = nil


function TTGamePackageInfoPopup:InitialUI()
    -- init vars
    self.cardCellDict_  = {}
    self.cardListData_  = {}
    self.packTotalRate_ = 0

    -- create view
    self.viewData = CreateView()

    -- add listener
    self:getViewData().cardGridView:setDataSourceAdapterScriptHandler(handler(self, self.onCardGridDataAdapterHandler_))

    -- update view
    local cardListData = {}
    local packConfInfo = TTGameUtils.GetConfAt(TTGAME_DEFINE.CONF_TYPE.CARD_PACK, self.args.cardPackId)
    for index, cardId in ipairs(packConfInfo.cards or {}) do
        local cardRate = checkint(checktable(packConfInfo.rate)[index])
        table.insert(cardListData, {
            cardId   = checkint(cardId),
            hasCard  = app.ttGameMgr:hasBattleCardId(cardId),
            cardRate = cardRate,
        })
        self.packTotalRate_ = self.packTotalRate_ + cardRate
    end
    self:setCardListData(cardListData)
end


CreateView = function()
    local size = cc.size(880, 600)
    local view = display.newLayer(0, 0, {size = size, bg = RES_DICT.BG_FRAME, scale9 = true})

    local titleBar = display.newButton(size.width/2, size.height - 30, {n = RES_DICT.COM_TITLE, enable = false})
    display.commonLabelParams(titleBar, fontWithColor(4, {text = __('卡包详情'), offset = cc.p(0, -4)}))
    view:addChild(titleBar)

    view:addChild(display.newImageView(RES_DICT.TITLE_LINE, size.width/2, titleBar:getPositionY() - 30))

    local CARD_COLUMNS = 6
    local cardGridSize = cc.size(size.width - 40, size.height - 75)
    local cardGridView = CGridView:create(cardGridSize)
    cardGridView:setSizeOfCell(cc.size(math.floor(cardGridSize.width / CARD_COLUMNS), 200))
    cardGridView:setAnchorPoint(display.CENTER_BOTTOM)
    cardGridView:setPosition(size.width/2, 5)
    cardGridView:setColumns(CARD_COLUMNS)
    -- cardGridView:setBackgroundColor(cc.r4b(150))
    view:addChild(cardGridView)
    
    return {
        view         = view,
        cardGridView = cardGridView,
    }
end


CreateCardCell = function(size)
    local view = CTableViewCell:new()
    view:setContentSize(size)

    -- view:addChild(display.newLayer(0,0,{size = size, color = cc.r4b(150)}))

    local cardLayer = display.newLayer(size.width/2, size.height/2 + 25)
    view:addChild(cardLayer)

    local cardNode = TTGameUtils.GetBattleCardNode({zoomModel = 's'})
    cardLayer:addChild(cardNode)

    local rateLabel = display.newLabel(size.width/2, 20, fontWithColor(6, {fontSize = 24, text = '----'}))
    view:addChild(rateLabel)
    
    view:addChild(display.newImageView(RES_DICT.GOODS_LINE, size.width/2, rateLabel:getPositionY() + 15))

    return {
        view      = view,
        cardNode  = cardNode,
        rateLabel = rateLabel,
    }
end


function TTGamePackageInfoPopup:getViewData()
    return self.viewData
end


function TTGamePackageInfoPopup:getCardListData()
    return self.cardListData_
end
function TTGamePackageInfoPopup:setCardListData(data)
    self.cardListData_ = data or {}
    self:getViewData().cardGridView:setCountOfCell(#self:getCardListData())
    self:getViewData().cardGridView:reloadData()
end


function TTGamePackageInfoPopup:initCardCell_(viewData)
end
function TTGamePackageInfoPopup:updatCardCell_(cellIndex, viewData)
    local cardGridView = self:getViewData().cardGridView
    local cellViewData = viewData or self.cardCellDict_[cardGridView:cellAtIndex(cellIndex - 1)]
    local cellListData = self:getCardListData()[cellIndex] or {}

    if cellViewData then
        -- update cardNode
        cellViewData.cardNode:setCardId(cellListData.cardId)
        
        -- update haveIcon
        if cellListData.hasCard then
            cellViewData.cardNode:showHaveCardMark()
        else
            cellViewData.cardNode:hideHaveCardMark()
        end
        
        -- update rateLabel
        local rateNum = math.ceil(cellListData.cardRate / self.packTotalRate_ * 10000) / 100
        display.commonLabelParams(cellViewData.rateLabel, {text = tostring(rateNum) .. '%'})
    end
end


function TTGamePackageInfoPopup:onCardGridDataAdapterHandler_(cell, idx)
    local pCell = cell
    local index = idx + 1
    
    if pCell == nil then
        local cellNodeSize = self:getViewData().cardGridView:getSizeOfCell()
        local cellViewData = CreateCardCell(cellNodeSize)
        self.cardCellDict_[cellViewData.view] = cellViewData
        self:initCardCell_(cellViewData)
        pCell = cellViewData.view
    end
    
    local cellViewData = self.cardCellDict_[pCell]
    self:updatCardCell_(index, cellViewData)
    return pCell
end


return TTGamePackageInfoPopup
