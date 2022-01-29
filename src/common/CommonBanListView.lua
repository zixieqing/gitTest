--[[
 * author : liuzhipeng
 * descpt : 通用 编队飨灵不可出战view
--]]
local CommonBanListView = class('CommonBanListView', function ()
    local node = CLayout:create(display.size)
    node.name = 'common.CommonBanListView'
    node:enableNodeEvents()
    return node
end)
local RES_DICT = {
    BG               = _res('ui/common/common_bg_2.png'), 
    TITLE_BG         = _res('ui/common/common_bg_title_2.png'),
}
function CommonBanListView:ctor( ... )
    local args = unpack({...})
    self.banListData = {}
    self.banList = args.banList or {}
    self:ConvertBanList()
    self:InitUI()
end
--[[
init ui
--]]
function CommonBanListView:InitUI()
    local banList = self.banList
    local function CreateView()
        local bg = display.newImageView(RES_DICT.BG, 0, 0)
        local size = bg:getContentSize()
        local view = CLayout:create(size)
        bg:setPosition(cc.p(size.width / 2, size.height / 2))
        view:addChild(bg, 1)
        -- mask
        local mask = CColorView:create(cc.c4b(0, 0, 0, 0))
        mask:setTouchEnabled(true)
        mask:setContentSize(size)
        mask:setPosition(cc.p(size.width / 2, size.height / 2))
        view:addChild(mask, -1)
        -- title
		local titleBg = display.newButton(0, 0, {n = RES_DICT.TITLE_BG, animation = false})
		display.commonUIParams(titleBg, {po = cc.p(size.width * 0.5, size.height - titleBg:getContentSize().height * 0.5)})
		display.commonLabelParams(titleBg,
			{text = __('不可出战'),
			fontSize = fontWithColor('SPX').fontSize, color = fontWithColor('BC').color,
			offset = cc.p(0, -2)})
        bg:addChild(titleBg)
        -- gridView
        local gridViewSize = cc.size(510, 570)
        local gridViewCellSize = cc.size(gridViewSize.width / 4, 140)
		local gridView = CGridView:create(gridViewSize)
		gridView:setSizeOfCell(gridViewCellSize)
		gridView:setColumns(4)
        gridView:setBounceable(false)
		view:addChild(gridView, 10)
        gridView:setPosition(cc.p(size.width / 2, size.height / 2 - 15))

        return {
            view             = view,
            gridView         = gridView,
            gridViewCellSize = gridViewCellSize,
        }
    end
    -- eaterLayer
    local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 255 * 0.6))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setPosition(cc.p(display.cx, display.cy))
    eaterLayer:setOnClickScriptHandler(function()
        self:runAction(cc.RemoveSelf:create())
    end)
    self:addChild(eaterLayer, -1)
    xTry(function ( )
        self.viewData = CreateView( )
        self:addChild(self.viewData.view)
        self.viewData.view:setPosition(display.center)
        self.viewData.gridView:setDataSourceAdapterScriptHandler(handler(self, self.OnDataSourceAdapter))
        self.viewData.gridView:setCountOfCell(#self.banListData)
        self.viewData.gridView:reloadData()
    end, __G__TRACKBACK__)
end
--[[
转换禁用列表
--]]
function CommonBanListView:ConvertBanList()
    local banList = self.banList
    local banCardDict = {}
    for i, v in ipairs(checktable(banList.card)) do
        banCardDict[tostring(v)] = v
    end
    local banCareerDict = {}
    for i, v in ipairs(checktable(banList.career)) do
        banCareerDict[tostring(v)] = v
    end
    local banQualityDict = {}
    for i, v in ipairs(checktable(banList.quality)) do
        banQualityDict[tostring(v)] = v
    end

    local banListData = {}
    local config = CommonUtils.GetConfigAllMess('card','card')
    local resourceConfig = CommonUtils.GetConfigAllMess('onlineResourceTrigger', 'cards')
    for i, v in pairs(config) do
        if banCardDict[tostring(v.id)] or banQualityDict[tostring(v.qualityId)] or banCareerDict[tostring(v.career)] then
            if isChinaSdk() then
                if resourceConfig[tostring(v.id)] then
                    table.insert(banListData, {cardId = checkint(v.id), qualityId = checkint(v.qualityId), career = checkint(v.career)})
                end
            else
                table.insert(banListData, {cardId = checkint(v.id), qualityId = checkint(v.qualityId), career = checkint(v.career)})
            end
        end
    end
    table.sort(banListData, function (a, b)
        return a.qualityId > b.qualityId
    end)
    self.banListData = banListData
end
--[[
列表处理
--]]
function CommonBanListView:OnDataSourceAdapter( p_convertview, idx )
    local pCell = p_convertview
    local index = idx + 1
    local cSize = self.viewData.gridViewCellSize

    if pCell == nil then
        pCell = CGridViewCell:new()
        pCell:setContentSize(cSize)
		local cardHeadNode = require('common.CardHeadNode').new({cardData = {cardId = 200001}, showActionState = false})
		cardHeadNode:setPosition(cc.p(cSize.width / 2, cSize.height / 2))
		cardHeadNode:setScale(0.65)
        pCell:addChild(cardHeadNode, 10)
        pCell.cardHeadNode = cardHeadNode
    end
    xTry(function()
        pCell.cardHeadNode:RefreshUI({cardData = {cardId = self.banListData[index].cardId}})
        
    end,__G__TRACKBACK__)
    return pCell
end
--[[
获取viewData
--]]
function CommonBanListView:GetViewData()
    return self.viewData
end
return CommonBanListView