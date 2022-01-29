--[[
 * author : kaishiqi
 * descpt : 打牌游戏 - 类型过滤图层
]]
local TTGameTypeLayer = class('TripleTriadGameTypeFilterLayer', function()
    return display.newLayer(0, 0, {name = 'TripleTriadGameTypeFilterLayer'})
end)

local RES_DICT = {
    TYPE_FRAME_BG = _res('ui/home/cardslistNew/tujian_selection_frame_1.png'),
    CUTTING_LINE  = _res('ui/common/tujian_selection_line.png'),
    SELECT_FRAME  = _res('ui/home/cardslistNew/tujian_selection_select_btn_filter_selected.png'),
}

local CreateView      = nil
local CreateTypeCell  = nil
local TYPE_CELL_SIZE  = cc.size(160, 56)
local FILTER_TYPE_ALL = TTGAME_DEFINE.FILTER_TYPE_ALL


function TTGameTypeLayer:ctor(args)
    -- init vars
    local initArgs       = args or {}
    self.closeCallback_  = initArgs.closeCB
    self.isControllable_ = true

    -- create view
    self.viewData_ = CreateView()
    self:addChild(self:getViewData().view)
    
    self.typeCellViewDataList_ = {}
    local filterTypeCellMaxW   = TYPE_CELL_SIZE.width
    local insertFilterTypeCell = function(typeId, typeName)
        local cellViewData = CreateTypeCell()
        self:getTypeCellLayer():addChild(cellViewData.view)
        table.insert(self.typeCellViewDataList_, cellViewData)
        cellViewData.hotspot:setTag(typeId)
        cellViewData.view:setTag(typeId)
        
        if FILTER_TYPE_ALL ~= typeId then
            local typeIconNode = TTGameUtils.GetTypeIconNode(typeId)
            typeIconNode:setAnchorPoint(display.LEFT_CENTER)
            cellViewData.iconLayer:addChild(typeIconNode)
        end
        display.commonLabelParams(cellViewData.nameLabel, {text = tostring(typeName)})
        display.commonUIParams(cellViewData.hotspot, {cb = handler(self, self.onClickTypeCellHandler_)})

        filterTypeCellMaxW = math.max(filterTypeCellMaxW, display.getLabelContentSize(cellViewData.nameLabel).width + 80)
    end
    insertFilterTypeCell(FILTER_TYPE_ALL, __('全部'))
    
    -- other type
    local typeConfFile = TTGameUtils.GetConf(TTGAME_DEFINE.CONF_TYPE.CARD_CAMP)
    for typeId = 1, table.nums(typeConfFile) do
        local typeConfInfo = typeConfFile[tostring(typeId)] or {}
        insertFilterTypeCell(typeId, typeConfInfo.name)
    end

    -- add listener
    display.commonUIParams(self:getViewData().blockLayer, {cb = handler(self, self.onClickBlockLayerHandler_), animate = false})

    -- update views
    local TYPE_LAYER_SPACE_H    = 0
    local TYPE_LAYER_BORDER_W   = 10
    local TYPE_LAYER_BORDER_T   = 5
    local TYPE_LAYER_BORDER_B   = 5
    local TYPE_CELL_DISTANCE_H  = TYPE_LAYER_SPACE_H + TYPE_CELL_SIZE.height
    local allFilterTypeCellSize = cc.size(filterTypeCellMaxW, #self:getTypeCellViewDataList() * TYPE_CELL_DISTANCE_H - TYPE_LAYER_SPACE_H)
    local fullTypeCellLayerSize = cc.size(allFilterTypeCellSize.width + TYPE_LAYER_BORDER_W*2, allFilterTypeCellSize.height + TYPE_LAYER_BORDER_T+TYPE_LAYER_BORDER_B)
    self:getViewData().typeCellLayer:setContentSize(fullTypeCellLayerSize)
    self:getViewData().typeCellBgImg:setContentSize(fullTypeCellLayerSize)

    for cellIndex, cellViewData in ipairs(self:getTypeCellViewDataList()) do
        cellViewData.updateSize(cc.size(filterTypeCellMaxW, TYPE_CELL_SIZE.height))
        cellViewData.view:setPositionX(fullTypeCellLayerSize.width/2)
        cellViewData.view:setPositionY(fullTypeCellLayerSize.height - TYPE_LAYER_BORDER_T - (cellIndex-1) * TYPE_CELL_DISTANCE_H)

        if cellIndex > 1 then
            local splitLine = display.newImageView(RES_DICT.CUTTING_LINE, cellViewData.view:getPositionX(), cellViewData.view:getPositionY(), {scale9 = true, size = cc.size(filterTypeCellMaxW - 20, 4)})
            self:getTypeCellLayer():addChild(splitLine)
        end
    end
end


CreateView = function(size)
    local view = display.newLayer()

    -- block layer
    local blockLayer = display.newLayer(0, 0, {color = cc.c4b(0,0,0,0), enable = true})
    view:addChild(blockLayer)
    
    local typeCellLayer = display.newLayer(0, 0, {ap = display.LEFT_BOTTOM, color1 = cc.c4b(100)})
    view:addChild(typeCellLayer)

    local typeCellBgImg = display.newImageView(RES_DICT.TYPE_FRAME_BG, 0, 0, {scale9 = true, ap = display.LEFT_BOTTOM})
    typeCellLayer:addChild(typeCellBgImg)

    return {
        view          = view,
        blockLayer    = blockLayer,
        typeCellLayer = typeCellLayer,
        typeCellBgImg = typeCellBgImg,
    }
end


CreateTypeCell = function()
    local size = TYPE_CELL_SIZE
    local view = display.newLayer(0, 0, {size = size, ap = display.CENTER_TOP, color1 = cc.r4b(50)})

    local selectImg = display.newImageView(RES_DICT.SELECT_FRAME, size.width/2, size.height/2, {scale9 = true, size = size})
    view:addChild(selectImg)

    local iconLayer = display.newLayer(0, 0)
    view:addChild(iconLayer)

    local nameLabel = display.newLabel(0, 0, fontWithColor(5, {ap = display.LEFT_CENTER}))
    view:addChild(nameLabel)

    local hotspot = display.newLayer(0, 0, {size = size, color = cc.r4b(0), enable = true})
    view:addChild(hotspot)

    return {
        view       = view,
        hotspot    = hotspot,
        selectImg  = selectImg,
        iconLayer  = iconLayer,
        nameLabel  = nameLabel,
        updateSize = function(newSize)
            view:setContentSize(newSize)
            hotspot:setContentSize(newSize)
            selectImg:setContentSize(newSize)
            iconLayer:setPosition(5, newSize.height/2)
            nameLabel:setPosition(60, newSize.height/2)
        end,
    }
end


-------------------------------------------------
-- get / set

function TTGameTypeLayer:getViewData()
    return self.viewData_
end


function TTGameTypeLayer:getTypeCellLayer()
    return self:getViewData().typeCellLayer
end


function TTGameTypeLayer:getTypeCellViewDataList()
    return self.typeCellViewDataList_
end


function TTGameTypeLayer:getClickTypeCellCB()
    return self.onClickTypeCellCB_
end
function TTGameTypeLayer:setClickTypeCellCB(callback)
    self.onClickTypeCellCB_ = callback
end


function TTGameTypeLayer:getSelectFilterType()
    return self.selectFilterTypeId_
end
function TTGameTypeLayer:setSelectFilterType(typeId)
    self.selectFilterTypeId_ = checkint(typeId)
    self:updateSelectedFilterType_()
end


-------------------------------------------------
-- public

function TTGameTypeLayer:close()
    self:runAction(cc.RemoveSelf:create())
end


function TTGameTypeLayer:showTypeFilterView()
    self:getViewData().view:setVisible(true)
end


function TTGameTypeLayer:closeTypeFilterView()
    self:getViewData().view:setVisible(false)
    if self.closeCallback_ then
        self.closeCallback_()
    end
end



-------------------------------------------------
-- private

function TTGameTypeLayer:updateSelectedFilterType_()
    for _, cellViewData in ipairs(self:getTypeCellViewDataList()) do
        local isSelectedSelf = self:getSelectFilterType() == cellViewData.hotspot:getTag()
        cellViewData.selectImg:setVisible(isSelectedSelf)
    end
end


-------------------------------------------------
-- private

function TTGameTypeLayer:onClickBlockLayerHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    self:closeTypeFilterView()
end


function TTGameTypeLayer:onClickTypeCellHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    if self:getClickTypeCellCB() then
        self:getClickTypeCellCB()(sender:getTag())
    end
end



return TTGameTypeLayer
