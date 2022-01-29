--[[
 * descpt : 外卖指南
]]
local VIEW_SIZE = cc.size(988, 645)
local GuideTakeoutPage3 = class('GuideTakeoutPage3', function ()
	local node = CLayout:create(VIEW_SIZE)
	node.name = 'Game.views.guide.GuideTakeoutPage.GuideTakeoutPage3'
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

    IMAGE_P3_1        = _res('guide/guide_takeout_image_p3_1.png'),
    IMAGE_P3_2        = _res('guide/guide_takeout_image_p3_2.png'),
    
}

local CreateView = nil

function GuideTakeoutPage3:ctor(...)
    local args = unpack({...}) or {}
    self:initialUI()
end

function GuideTakeoutPage3:initialUI()
    xTry(function ( )
        self.viewData_ = CreateView(VIEW_SIZE)
        self:addChild(self:getViewData().view)

        self:initView()
	end, __G__TRACKBACK__)
end

function GuideTakeoutPage3:initView()
    
end

function GuideTakeoutPage3:refreshUI(data)
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

    local image1 = display.newImageView(RES_DIR.IMAGE_P3_1, leftMiddleLayerSize.width / 2, leftMiddleLayerSize.height / 2, {ap = display.CENTER})
    leftMiddleLayer:addChild(image1)
    
    ------------------------------
    -- left bottom layer

    ------------------------------
    -- right layer 
    local rightImgLayerSize = cc.size(size.width / 2 - 20, size.height - 60)
    local rightImgLayer = display.newLayer(size.width - 260, size.height / 2 - 15, {ap = display.CENTER, size = rightImgLayerSize})
    view:addChild(rightImgLayer)

    local rightImg = display.newImageView(RES_DIR.IMAGE_P3_2, rightImgLayerSize.width / 2, rightImgLayerSize.height / 2, {ap = display.CENTER})
    rightImgLayer:addChild(rightImg)

    local headIcon = display.newImageView(RES_DIR.ICO_HAND, rightImgLayerSize.width  / 2 - 30, 50, {ap = display.CENTER})
    rightImgLayer:addChild(headIcon)

    local tipLabel = display.newLabel(rightImgLayerSize.width  / 2 + 63, 41, fontWithColor(14, {ap = display.CENTER}))
    rightImgLayer:addChild(tipLabel)

    return {
        view        = view,
        tipLabel    = tipLabel,
    }
end

function GuideTakeoutPage3:getViewData()
    return self.viewData_
end

return GuideTakeoutPage3