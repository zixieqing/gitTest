--[[
 * descpt : 卡牌指南
]]
local VIEW_SIZE = cc.size(988, 645)
local GuideCardPage2 = class('GuideCardPage2', function ()
	local node = CLayout:create(VIEW_SIZE)
	node.name = 'Game.views.guide.GuideCardPage.GuideCardPage2'
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

    IMAGE_P2          = _res('guide/guide_card_image_p2.png'),
}

local CreateView = nil

function GuideCardPage2:ctor(...)
    local args = unpack({...}) or {}
    self:initialUI()
end

function GuideCardPage2:initialUI()
    xTry(function ( )
        self.viewData_ = CreateView(VIEW_SIZE)
        self:addChild(self:getViewData().view)

        self:initView()
	end, __G__TRACKBACK__)
end

function GuideCardPage2:initView()
    
end

function GuideCardPage2:refreshUI(data)
    local viewData   = self:getViewData()
    
    local orangeBtn  = viewData.orangeBtn
    display.commonLabelParams(orangeBtn, {text = tostring(data['3'])})
    
end

CreateView = function (size)
    local view = display.newLayer(0, 0, {size = size})

    ------------------------------
    -- dottedline layer
    local dottedlineLayerSize = cc.size(420, 180)
    local dottedlineLayer = display.newLayer(250, size.height / 2 - 10, {ap = display.CENTER, size = dottedlineLayerSize})
    view:addChild(dottedlineLayer)

    local dottedlineFrame = display.newImageView(RES_DIR.FRAME_DOTTEDLINE, dottedlineLayerSize.width / 2, dottedlineLayerSize.height / 2, {ap = display.CENTER})
    local dottedlineFrameSize = dottedlineFrame:getContentSize()
    dottedlineLayer:addChild(dottedlineFrame)

    local orangeBtn = display.newButton(dottedlineFrameSize.width / 2, dottedlineFrameSize.height / 2, {ap = display.CENTER, n = RES_DIR.ORANGE_BTN})
    display.commonLabelParams(orangeBtn, fontWithColor(14, {fontSize = 20}))
    dottedlineFrame:addChild(orangeBtn)

    local headIcon = display.newImageView(RES_DIR.ICO_HAND, 12, 14, {ap = display.RIGHT_TOP})
    dottedlineFrame:addChild(headIcon)
    
    ------------------------------
    -- left bottom layer


    ------------------------------
    -- right layer 
    local rightImgLayerSize = cc.size(size.width / 2 - 20, size.height - 60)
    local rightImgLayer = display.newLayer(size.width - 260, size.height / 2 - 15, {ap = display.CENTER, size = rightImgLayerSize})
    view:addChild(rightImgLayer)

    local rightImg = display.newImageView(RES_DIR.IMAGE_P2, rightImgLayerSize.width / 2, rightImgLayerSize.height / 2, {ap = display.CENTER})
    rightImgLayer:addChild(rightImg)

    return {
        view        = view,
        orangeBtn   = orangeBtn,
    }
end

function GuideCardPage2:getViewData()
    return self.viewData_
end

return GuideCardPage2