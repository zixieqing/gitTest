--[[
 * descpt : 外卖指南
]]
local VIEW_SIZE = cc.size(988, 645)
local GuideTakeoutPage2 = class('GuideTakeoutPage2', function ()
	local node = CLayout:create(VIEW_SIZE)
	node.name = 'Game.views.guide.GuideTakeoutPage.GuideTakeoutPage2'
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

    IMAGE_P2_1        = _res('guide/guide_takeout_image_p2_1.png'),
    IMAGE_P2_2        = _res('guide/guide_takeout_image_p2_2.png'),
}

local CreateView = nil

function GuideTakeoutPage2:ctor(...)
    local args = unpack({...}) or {}
    self:initialUI()
end

function GuideTakeoutPage2:initialUI()
    xTry(function ( )
        self.viewData_ = CreateView(VIEW_SIZE)
        self:addChild(self:getViewData().view)

        self:initView()
	end, __G__TRACKBACK__)
end

function GuideTakeoutPage2:initView()
    
end

function GuideTakeoutPage2:refreshUI(data)
    local viewData   = self:getViewData()

    local orangeBtn  = viewData.orangeBtn
    display.commonLabelParams(orangeBtn, {text = tostring(data['3'])})
    
end

CreateView = function (size)
    local view = display.newLayer(0, 0, {size = size})

    ------------------------------
    -- dottedline layer
    local leftMiddleLayerSize = cc.size(420, 180)
    local leftMiddleLayer = display.newLayer(250, size.height / 2 - 10, {ap = display.CENTER, size = leftMiddleLayerSize})
    view:addChild(leftMiddleLayer)

    local image1 = display.newImageView(RES_DIR.IMAGE_P2_1, leftMiddleLayerSize.width / 2, leftMiddleLayerSize.height / 2, {ap = display.CENTER})
    leftMiddleLayer:addChild(image1)
    
    leftMiddleLayer:addChild(display.newImageView(RES_DIR.LINE_DOTTED_1, leftMiddleLayerSize.width / 2, leftMiddleLayerSize.height / 2 + 10, {ap = display.CENTER}))
    ------------------------------
    -- left bottom layer

    ------------------------------
    -- right layer 
    local rightImgLayerSize = cc.size(size.width / 2 - 20, size.height - 60)

    local rightDialogLayer = display.newLayer(size.width - 260, size.height / 2 - 15, {ap = display.CENTER, size = rightImgLayerSize})
    view:addChild(rightDialogLayer)

    local rightDialogImg = display.newImageView(RES_DIR.IMAGE_P2_2, rightImgLayerSize.width / 2, 20, {ap = display.CENTER_BOTTOM})
    rightDialogLayer:addChild(rightDialogImg)

    local dottedlineFrame = display.newImageView(RES_DIR.FRAME_DOTTEDLINE, 180, rightImgLayerSize.height - 80, {ap = display.CENTER})
    local dottedlineFrameSize = dottedlineFrame:getContentSize()
    rightDialogLayer:addChild(dottedlineFrame)

    local orangeBtn = display.newButton(dottedlineFrameSize.width / 2, dottedlineFrameSize.height / 2, {ap = display.CENTER, n = RES_DIR.ORANGE_BTN, enable = false})
    display.commonLabelParams(orangeBtn, fontWithColor(14, {fontSize = 20}))
    dottedlineFrame:addChild(orangeBtn)

    local headIcon = display.newImageView(RES_DIR.ICO_HAND, dottedlineFrameSize.width - 12, dottedlineFrameSize.height / 2, {ap = display.RIGHT_TOP})
    headIcon:setScaleX(-1)
    dottedlineFrame:addChild(headIcon) 

    return {
        view        = view,
        descLabel2  = descLabel2,
        orangeBtn   = orangeBtn,
    }
end

function GuideTakeoutPage2:getViewData()
    return self.viewData_
end

return GuideTakeoutPage2