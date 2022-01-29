--[[
 * descpt : 外卖指南
]]
local VIEW_SIZE = cc.size(988, 645)
local GuideCardPage1 = class('GuideCardPage1', function ()
	local node = CLayout:create(VIEW_SIZE)
	node.name = 'Game.views.guide.GuideCardPage.GuideCardPage1'
	node:enableNodeEvents()
	return node
end)

local RES_DIR = {
    ARROW             = _res('ui/common/common_bg_tips_horn.png'),
    BOARD             = _res('ui/common/common_bg_tips.png'),
    SEARCHRECIPE      = _res('ui/home/kitchen/cooking_btn_pokedex.png'),
    FOODS_POKEDEX_IMG = _res('ui/home/kitchen/kitchen_btn_foods_pokedex.png'),
    FRAME_DOTTEDLINE  = _res('guide/guide_frame_dottedline.png'),
    ICO_HAND          = _res('guide/guide_ico_hand.png'),
    LINE_DOTTED_1     = _res('guide/guide_line_dotted_1.png'),
    ORANGE_BTN        = _res('ui/common/common_btn_orange.png'),

    IMAGE_P1_1        = _res('guide/guide_card_image_p1_1.png'),
    IMAGE_P1_2        = _res('guide/guide_card_image_p1_2.png'),
}

local CreateView = nil

function GuideCardPage1:ctor(...)
    local args = unpack({...}) or {}
    self:initialUI()
end

function GuideCardPage1:initialUI()
    xTry(function ( )
        self.viewData_ = CreateView(VIEW_SIZE)
        self:addChild(self:getViewData().view)

        self:initView()
	end, __G__TRACKBACK__)
end

function GuideCardPage1:initView()
    
end

function GuideCardPage1:refreshUI(data)
    local viewData   = self:getViewData()

    local tipLabel  = viewData.tipLabel
    display.commonLabelParams(tipLabel, {text = tostring(data['3'])})
end

CreateView = function (size)
    local view = display.newLayer(0, 0, {size = size})

    ------------------------------
    -- dottedline layer
    local leftMiddleLayerSize = cc.size(420, 180)
    local leftMiddleLayer = display.newLayer(250, size.height / 2 - 10, {ap = display.CENTER, size = leftMiddleLayerSize})
    view:addChild(leftMiddleLayer)

    local image1 = display.newImageView(RES_DIR.IMAGE_P1_1, leftMiddleLayerSize.width / 2 + 20, leftMiddleLayerSize.height / 2 + 10, {ap = display.CENTER})
    leftMiddleLayer:addChild(image1)

    local dottedlineFrame = display.newImageView(RES_DIR.FRAME_DOTTEDLINE, 100, leftMiddleLayerSize.height / 2 + 5, {ap = display.CENTER})
    local dottedlineFrameSize = dottedlineFrame:getContentSize()
    leftMiddleLayer:addChild(dottedlineFrame)

	local tipLabel = display.newLabel(dottedlineFrameSize.width / 2, dottedlineFrameSize.height / 2, fontWithColor(14, {fontSize = 20, ap = display.CENTER, color = "#ffffff" }))
    dottedlineFrame:addChild(tipLabel)

    local headIcon = display.newImageView(RES_DIR.ICO_HAND, dottedlineFrameSize.width / 2, 14, {ap = display.RIGHT_TOP})
    dottedlineFrame:addChild(headIcon)
    ------------------------------
    -- left bottom layer

    ------------------------------
    -- right layer 
    local rightImgLayerSize = cc.size(size.width / 2 - 20, size.height - 60)
    local rightImgLayer = display.newLayer(size.width - 260, size.height / 2 - 15, {ap = display.CENTER, size = rightImgLayerSize})
    view:addChild(rightImgLayer)

    local rightImg = display.newImageView(RES_DIR.IMAGE_P1_2, rightImgLayerSize.width / 2, rightImgLayerSize.height / 2, {ap = display.CENTER})
    rightImgLayer:addChild(rightImg)

    return {
        view        = view,
        tipLabel    = tipLabel,
    }
end

function GuideCardPage1:getViewData()
    return self.viewData_
end

return GuideCardPage1