--[[
卡池选择页面view
--]]
local CapsuleCardChooseSelectCardView = class('CapsuleCardChooseSelectCardView', function ()
    local node = CLayout:create()
    node.name = 'Game.views.drawCards.CapsuleCardChooseSelectCardView'
    node:enableNodeEvents()
    return node
end)


local RES_DICT = {
    SUMMON_CHOICE_BG_1 = _res("ui/home/capsuleNew/cardChoose/summon_choice_bg_1.jpg"),
    NEWLAND_BG_BELOW = _res("ui/home/capsuleNew/skinCapsule/summon_activity_bg_bottom.png"),
    NEWLAND_BG_COUNT = _res("ui/home/capsuleNew/skinCapsule/summon_newhand_bg_count.png"),
    NEWLAND_BG_PREVIEW = _res("ui/home/capsuleNew/skinCapsule/summon_newhand_label_preview.png"),
    ORANGE_BTN_N = _res('ui/common/common_btn_big_orange_2.png'),
    ORANGE_BTN_D = _res('ui/common/common_btn_big_orange_disabled_2.png'),
    SELECT_TITLE_BG = _res('ui/home/capsuleNew/skinCapsule/summon_skin_bg_title_choice_skin.png'),
    LIST_CELL_FLAG = _res('ui/home/capsuleNew/skinCapsule/summon_choice_bg_get_text.png'),
    LIST_SELECT_IMAGE = _res("ui/home/capsuleNew/skinCapsule/summon_skin_bg_text_choosed.png"),
}

local uiMgr   = app.uiMgr
local cardMgr = app.cardMgr

local EntryNode = require("common.CardPreviewEntranceNode")

local NewPlayerRewardCell = require("Game.views.drawCards.NewPlayerRewardCell")

local CreateView = nil

function CapsuleCardChooseSelectCardView:ctor( ... )
    local args = unpack({...}) or {}
    local size = args.size
    self:setContentSize(size)
    
    self:initUI(size)
end

function CapsuleCardChooseSelectCardView:initUI(size)
    xTry(function ( )
		self.viewData_ = CreateView(size)
        self:addChild(self.viewData_.view)
        self:initView()
	end, __G__TRACKBACK__)
end

function CapsuleCardChooseSelectCardView:initView()
    
end

function CapsuleCardChooseSelectCardView:updateConsumeGood(consumeNum, goodsId)
    local viewData = self:getViewData()
    local consumeGoodLayer = viewData.consumeGoodLayer
    consumeGoodLayer:setVisible(consumeNum ~= nil)
    if consumeNum then
        local consumeGoodNumLabel = viewData.consumeGoodNumLabel
        display.commonLabelParams(consumeGoodNumLabel, {text = string.format( __('消耗 %s'), consumeNum)})
        local consumeGoodImg      = viewData.consumeGoodImg
        if goodsId then
            consumeGoodImg:setTexture(CommonUtils.GetGoodsIconPathById(goodsId))
        end

        local consumeGoodLayerSize = consumeGoodLayer:getContentSize()

        local consumeGoodNumLabelSize = display.getLabelContentSize(consumeGoodNumLabel)
        local consumeGoodImgSize = consumeGoodImg:getContentSize()
        consumeGoodNumLabel:setPositionX(consumeGoodLayerSize.width / 2 - consumeGoodImgSize.width / 2 * consumeGoodImg:getScale())
        consumeGoodImg:setPositionX(consumeGoodLayerSize.width / 2 + consumeGoodNumLabelSize.width / 2)
    end
end

CreateView = function (size)
    local view = display.newLayer(0, 0, {size = size})

    -- selectCardView:setVisible(false)
    local taskListSize = cc.size(510, 560)
    local gridView = CTableView:create(taskListSize)
    gridView:setSizeOfCell(cc.size(230, 560))
    gridView:setAutoRelocate(true)
    gridView:setDirection(eScrollViewDirectionHorizontal)
    view:addChild(gridView, 2)
    gridView:setAnchorPoint(display.CENTER)
    gridView:setDragable(false)
    gridView:setPosition(cc.p(size.width * 0.5 - 20, size.height / 2 - 20))
    -- gridView:setBackgroundColor(cc.c4b(178, 63, 88, 100))

    local topTitleBg = display.newButton(size.width * 0.5 - 20, size.height, {
            n = RES_DICT.SELECT_TITLE_BG, ap = display.CENTER_TOP
        })
    topTitleBg:setEnabled(false)
    display.commonLabelParams(topTitleBg, fontWithColor(2,{text = __('请选择心仪的飨灵加入卡池'), ap =  display.CENTER, w = 400 , hAlign = display.TAC,  fontSize = 22, color = "#ffffff", offset = cc.p(0, 0)}))
    view:addChild(topTitleBg, 10)

    local selectButton = display.newButton(0, 0, {n = _res('ui/common/common_btn_orange.png'),
            d = _res("ui/common/common_btn_orange_disable.png")})
    display.commonUIParams(selectButton, {po = cc.p(size.width * 0.5 + 340, size.height / 2 - 238)})
    display.commonLabelParams(selectButton, fontWithColor(14, {text = __('确认')}))
    selectButton:setVisible(false)
    view:addChild(selectButton)

    local consumeGoodLayerSize = cc.size(100, 30)
    local consumeGoodLayer = display.newLayer(selectButton:getPositionX(), size.height / 2 - 282, {size = consumeGoodLayerSize, ap = display.CENTER})
    view:addChild(consumeGoodLayer)
    consumeGoodLayer:setVisible(false)

    local consumeGoodNumLabel = display.newLabel(consumeGoodLayerSize.width / 2, consumeGoodLayerSize.height / 2, fontWithColor(3, {text = __('消耗'), ap = display.CENTER}))
    consumeGoodLayer:addChild(consumeGoodNumLabel)
    
    local consumeGoodImg = display.newNSprite(_res('arts/goods/goods_icon_900002.png'), consumeGoodLayerSize.width / 2, consumeGoodLayerSize.height / 2, {ap = display.CENTER})
    consumeGoodImg:setScale(0.2)
    consumeGoodLayer:addChild(consumeGoodImg)

    return {
        view                = view,
        gridView            = gridView,
        topTitleBg          = topTitleBg,
        selectButton        = selectButton,
        consumeGoodLayer    = consumeGoodLayer,
        consumeGoodNumLabel = consumeGoodNumLabel,
        consumeGoodImg      = consumeGoodImg,
    }
end


function CapsuleCardChooseSelectCardView:getViewData()
    return self.viewData_
end

return CapsuleCardChooseSelectCardView
