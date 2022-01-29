---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by xingweihao.
--- DateTime: 2018/8/7 2:29 PM
---
---@class FishingWishView
local FishingWishView = class('FishingWishView', function()
    local node = CLayout:create(display.size)
    node:setAnchorPoint(display.CENTER)
    node.name = 'home.LimitChestGiftView1'
    node:enableNodeEvents()
    return node
end)
---@type UIManager
local uiMgr             = AppFacade.GetInstance():GetManager("UIManager")
---@type FishConfigParser
local fishConfigParser = require('Game.Datas.Parser.FishConfigParser')
local RES_DICT          = {
    BG_LIGHT       = _res('ui/home/fishing/fishing_buff_bg_light.png'),
    BG_IMAGE       = _res('ui/home/fishing/fishing_buff_bg.png'),
    ORIGIN_BIG_BTN = _res('ui/common/common_btn_big_orange.png')
}
function FishingWishView:ctor(...)
    -- 关闭layer
    local closeLayer = CButton:create()
    closeLayer:setContentSize(display.size)
    closeLayer:setPosition(display.center)
    local blackLayer = display.newLayer(display.width / 2, display.height / 2, { ap = display.CENTER, size = display.size, color = cc.c4b(0, 0, 0, 175), enable = true})
    closeLayer:addChild(blackLayer)
    self:addChild(closeLayer)
    closeLayer:setCascadeOpacityEnabled(true)
    local wishLabel = display.newLabel(display.width / 2, display.height / 2 + 250, fontWithColor('14', { fontSize = 36, color = 'fff7d6' , text = __('选择天气效果') }))
    self:addChild(wishLabel)
    wishLabel:setOpacity(0)
    -- 购买按钮
    local buyBtn = display.newButton(display.width / 2, display.height / 2 - 250, { n = RES_DICT.ORIGIN_BIG_BTN ,scale9 = true , size = cc.size(200, 64) })
    self:addChild(buyBtn)
    local buyBtnSize = buyBtn:getContentSize()
    local freeLabel  = display.newLabel(buyBtnSize.width / 2, -20 , fontWithColor(14, { hAlign = display.TAC, text = "" }))
    buyBtn:addChild(freeLabel)
    local richLabel = display.newRichLabel(buyBtnSize.width / 2, buyBtnSize.height / 2, { c = { fontWithColor('14', { text = '' }) } })
    buyBtn:addChild(richLabel)
    buyBtn:setOpacity(0)

    local prayConfig = CommonUtils.GetConfigAllMess(fishConfigParser.TYPE.PRAY, 'fish')
    local count      = table.nums(prayConfig)
    local cellSize   = cc.size(320, 450)
    local width      = count * cellSize.width
    if width > display.width then
        width = display.width
    end
    local gridViewSize = cc.size(width, cellSize.height)
    local gridView     = CTableView:create(gridViewSize)
    gridView:setAnchorPoint(display.CENTER)
    gridView:setDirection(eScrollViewDirectionHorizontal)
    gridView:setSizeOfCell(cellSize)
    gridView:setPosition(display.center)
    --gridView:setBounceable(false)
    --gridView:setAutoRelocate(true)
    self:addChild(gridView, 10)

    self.viewData = {
        closeLayer = closeLayer,
        buyBtn     = buyBtn,
        richLabel  = richLabel,
        freeLabel  = freeLabel,
        gridView   = gridView,
        wishLabel  = wishLabel,
        blackLayer  = blackLayer
    }
end

function FishingWishView:CreateWishkindsCell()
    local cellOneSize = cc.size(340, 450)
    local cell = CTableViewCell:new()
    cell:setCascadeOpacityEnabled(true )
    cell:setContentSize(cellOneSize)
    local cellSize = cc.size(300, 400)
    local cellLayout = display.newLayer(cellOneSize.width/2 , cellOneSize.height/2 ,{size = cellSize , ap = display.CENTER } )
    cell:addChild(cellLayout)
    cellLayout:setName("cellLayout")

    local bgLight = display.newImageView(RES_DICT.BG_LIGHT , cellSize.width/2 , cellSize.height/2)
    cellLayout:addChild(bgLight)
    bgLight:setName("bgLight")
    bgLight:setVisible(false)
    -- 背景图片
    local bgImage =  display.newButton( cellSize.width/2 , cellSize.height/2 , { n = RES_DICT.BG_IMAGE})
    cellLayout:addChild(bgImage)
    bgImage:setName("bgImage")
    -- 效果的名称
    local nameLabel = display.newLabel(cellSize.width/2 , cellSize.height - 60 , fontWithColor(10,{text = "", fontSize = 24, color = '#5b3c25'} ))
    cellLayout:addChild(nameLabel)
    nameLabel:setName("nameLabel")
    -- 图片的名称
    local iconImage = display.newImageView(CommonUtils.GetGoodsIconPathById(GOLD_ID) ,cellSize.width/2  ,cellSize.height -140  )
    cellLayout:addChild(iconImage)
    iconImage:setName("iconImage")
    -- 条件的label
    local weatherLabel = display.newLabel(cellSize.width/2 , cellSize.height - 210, fontWithColor(6,{ap = display.CENTER_TOP , hAlign= display.TAL ,  fontSize = 20 , color = "#a3735d" , text = "" , w = 250} ))
    cellLayout:addChild(weatherLabel)
    weatherLabel:setName("weatherLabel")

    -- 条件的label
    local effectLabel = display.newLabel(cellSize.width/2 ,60 , fontWithColor(14,{fontSize = 22 , color = "#d23d3d" , text = ""  , w = 260,outline = false , hAlign = display.TAC} ))
    cellLayout:addChild(effectLabel)
    effectLabel:setName("effectLabel")
    cellLayout:setOpacity(0)
    return cell
end



return FishingWishView
