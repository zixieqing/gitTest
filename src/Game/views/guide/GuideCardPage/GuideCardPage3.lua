--[[
 * descpt : 外卖指南
]]
local VIEW_SIZE = cc.size(988, 645)
local GuideCardPage3 = class('GuideCardPage3', function ()
	local node = CLayout:create(VIEW_SIZE)
	node.name = 'Game.views.guide.GuideCardPage.GuideCardPage3'
	node:enableNodeEvents()
	return node
end)

local RES_DIR = {
    ORANGE_BTN        = _res('ui/common/common_btn_orange.png'),
    LINE_DOTTED_1     = _res('guide/guide_line_dotted_1.png'),
    FRAME_DOTTEDLINE  = _res('guide/guide_frame_dottedline.png'),
    ICO_HAND          = _res('guide/guide_ico_hand.png'),
    IMAGE_P3_1        = _res('guide/guide_card_image_p3_1.png'),
    IMAGE_P3_2        = _res('guide/guide_card_image_p3_2.png'),
    IMAGE_P3_3        = _res('guide/guide_card_image_p3_3.png'),

    MANAGE_SELECTED   = _res('ui/cards/skillNew/card_skill_btn_manage_selected.png'),
    MANAGE_UNACTIVE   = _res('ui/cards/skillNew/card_skill_btn_manage_unactive.png'),
}

local labelparser = require("Game.labelparser")

local CreateView = nil

function GuideCardPage3:ctor(...)
    local args = unpack({...}) or {}
    self:initialUI()
end

function GuideCardPage3:initialUI()
    xTry(function ( )
        self.viewData_ = CreateView(VIEW_SIZE)
        self:addChild(self:getViewData().view)

        self:initView()
	end, __G__TRACKBACK__)
end

function GuideCardPage3:initView()
    
end

function GuideCardPage3:refreshUI(data)
    local viewData   = self:getViewData()
    
    local orangeBtn  = viewData.orangeBtn
    display.commonLabelParams(orangeBtn, {text = tostring(data['3'])})
    local titleLabel = viewData.titleLabel
    display.commonLabelParams(titleLabel, {text = tostring(data['4']) , w  = 140 , hAlign = display.TAC})
    
end

CreateView = function (size)
    local view = display.newLayer(0, 0, {size = size})

    ------------------------------
    -- dottedline layer
    local dottedlineLayerSize = cc.size(420, 180)
    
    ------------------------------
    -- left middle layer

    local leftMiddleLayer = display.newLayer(250, size.height / 2 - 10, {ap = display.CENTER, size = dottedlineLayerSize})
    view:addChild(leftMiddleLayer)

    local image1 = display.newImageView(RES_DIR.IMAGE_P3_1, dottedlineLayerSize.width / 2 + 30, dottedlineLayerSize.height / 2, {ap = display.CENTER})
    leftMiddleLayer:addChild(image1)

    ------------------------------
    -- left bottom layer

    ------------------------------
    -- right layer 
    local rightImgLayerSize = cc.size(size.width / 2 - 20, size.height - 60)
    local rightImgLayer = display.newLayer(size.width - 260, size.height / 2 - 15, {ap = display.CENTER, size = rightImgLayerSize})
    view:addChild(rightImgLayer)

    local image2 = display.newImageView(RES_DIR.IMAGE_P3_2, rightImgLayerSize.width / 2 + 27, rightImgLayerSize.height * 0.75, {ap = display.CENTER})
    rightImgLayer:addChild(image2)

    local dottedlineFrame = display.newImageView(RES_DIR.FRAME_DOTTEDLINE, 130, rightImgLayerSize.height / 2 - 46, {ap = display.CENTER})
    local dottedlineFrameSize = dottedlineFrame:getContentSize()
    rightImgLayer:addChild(dottedlineFrame)

    local orangeBtn = display.newButton(dottedlineFrameSize.width / 2, dottedlineFrameSize.height / 2, {ap = display.CENTER, n = RES_DIR.ORANGE_BTN, animate = false})
    display.commonLabelParams(orangeBtn, fontWithColor(14, {fontSize = 20, text = __('开发')}))
    dottedlineFrame:addChild(orangeBtn)

    local headIcon = display.newImageView(RES_DIR.ICO_HAND, dottedlineFrameSize.width / 2 + 45, dottedlineFrameSize.height / 2 - 10, {ap = display.RIGHT_TOP})
    headIcon:setScaleX(-1)
    dottedlineFrame:addChild(headIcon) 

    local line1 = display.newImageView(RES_DIR.LINE_DOTTED_1, rightImgLayerSize.width / 2, 135, {ap = display.CENTER})
    rightImgLayer:addChild(line1)

    local image3 = display.newImageView(RES_DIR.IMAGE_P3_3, rightImgLayerSize.width + 10, 115, {ap = display.RIGHT_CENTER})
    rightImgLayer:addChild(image3)

    local unactiveImg = display.newImageView(RES_DIR.MANAGE_UNACTIVE, 160, 88, {ap = display.CENTER})
    rightImgLayer:addChild(unactiveImg)

    local selectImg = display.newImageView(RES_DIR.MANAGE_SELECTED, rightImgLayerSize.width / 2 + 5, 78, {ap = display.CENTER})
    local selectImgSize = selectImg:getContentSize()
    rightImgLayer:addChild(selectImg)

    local titleLabel = display.newLabel(selectImgSize.width / 2, 22, {fontSize = 20, color = '#97766f'})
    selectImg:addChild(titleLabel)

    return {
        view       = view,
        titleLabel = titleLabel,
        orangeBtn  = orangeBtn,
    }
end

function GuideCardPage3:getViewData()
    return self.viewData_
end

return GuideCardPage3