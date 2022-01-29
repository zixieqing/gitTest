--[[
 * descpt : 卡牌指南
]]
local VIEW_SIZE = cc.size(988, 645)
local GuideExploreSystemPage3 = class('GuideExploreSystemPage3', function ()
	local node = CLayout:create(VIEW_SIZE)
	node.name = 'Game.views.guide.GuideExploreSystemPage.GuideExploreSystemPage3'
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

    IMAGE_P3_1          = _res('guide/guide_explore_image_p3_1.png'),
    IMAGE_P3_2          = _res('guide/guide_explore_image_p3_2.png'),
}

local CreateView = nil

function GuideExploreSystemPage3:ctor(...)
    local args = unpack({...}) or {}
    self:initialUI()
end

function GuideExploreSystemPage3:initialUI()
    xTry(function ( )
        self.viewData_ = CreateView(VIEW_SIZE)
        self:addChild(self:getViewData().view)

        self:initView()
	end, __G__TRACKBACK__)
end

function GuideExploreSystemPage3:initView()
    
end

function GuideExploreSystemPage3:refreshUI(data)
    local viewData   = self:getViewData()
    
    local orangeBtn  = viewData.orangeBtn
    display.commonLabelParams(orangeBtn, {text = tostring(data['4']), reqW = 103})

    local label1 = viewData.label1
    display.commonLabelParams(label1, {text = tostring(data['3'])})
    
end

CreateView = function (size)
    local view = display.newLayer(0, 0, {size = size})

    local img1 = display.newImageView(RES_DIR.IMAGE_P3_1, 250, size.height / 2 + 46, {ap = display.CENTER})
    view:addChild(img1)

    local label1 = display.newLabel(330, 26, fontWithColor(5, {ap = display.RIGHT_CENTER, color = '#e65f15'}))
    img1:addChild(label1)
    ------------------------------
    -- dottedline layer
    local dottedlineLayerSize = cc.size(420, 180)
    local dottedlineLayer = display.newLayer(250, size.height / 2 - 80, {ap = display.CENTER, size = dottedlineLayerSize})
    view:addChild(dottedlineLayer)

    local dottedlineFrame = display.newImageView(RES_DIR.FRAME_DOTTEDLINE, dottedlineLayerSize.width / 2, dottedlineLayerSize.height / 2, {ap = display.CENTER})
    local dottedlineFrameSize = dottedlineFrame:getContentSize()
    dottedlineLayer:addChild(dottedlineFrame)

    local orangeBtn = display.newButton(dottedlineFrameSize.width / 2, dottedlineFrameSize.height / 2, {ap = display.CENTER, n = RES_DIR.ORANGE_BTN})
    display.commonLabelParams(orangeBtn, fontWithColor(14, {fontSize = 20}))
    dottedlineFrame:addChild(orangeBtn)

    local headIcon = display.newImageView(RES_DIR.ICO_HAND, 20, 55, {ap = display.RIGHT_TOP})
    dottedlineFrame:addChild(headIcon)
    
    ------------------------------
    -- left bottom layer


    ------------------------------
    -- right layer 
    local rightImgLayerSize = cc.size(size.width / 2 - 20, size.height - 60)
    local rightImgLayer = display.newLayer(size.width - 260, size.height / 2 - 15, {ap = display.CENTER, size = rightImgLayerSize})
    view:addChild(rightImgLayer)

    local rightImg = display.newImageView(RES_DIR.IMAGE_P3_2, rightImgLayerSize.width / 2, rightImgLayerSize.height / 2, {ap = display.CENTER})
    rightImgLayer:addChild(rightImg)

    return {
        view        = view,
        orangeBtn   = orangeBtn,
        label1      = label1,
    }
end

function GuideExploreSystemPage3:getViewData()
    return self.viewData_
end

return GuideExploreSystemPage3