--[[
 * descpt : 外卖指南
]]
local VIEW_SIZE = cc.size(988, 645)
local GuideTakeoutPage1 = class('GuideTakeoutPage1', function ()
	local node = CLayout:create(VIEW_SIZE)
	node.name = 'Game.views.guide.GuideTakeoutPage.GuideTakeoutPage1'
	node:enableNodeEvents()
	return node
end)

local RES_DIR = {
    ORANGE_BTN        = _res('ui/common/common_btn_orange.png'),
    LINE_DOTTED_1     = _res('guide/guide_line_dotted_1.png'),
    ICO_HAND          = _res('guide/guide_ico_hand.png'),
    IMAGE_P1_1        = _res('guide/guide_takeout_image_p1_1.png'),
    IMAGE_P1_2        = _res('guide/guide_takeout_image_p1_2.png'),
    IMAGE_P1_3        = _res('guide/guide_takeout_image_p1_3.png'),
}

local labelparser = require("Game.labelparser")

local CreateView = nil

function GuideTakeoutPage1:ctor(...)
    local args = unpack({...}) or {}
    self:initialUI()
end

function GuideTakeoutPage1:initialUI()
    xTry(function ( )
        self.viewData_ = CreateView(VIEW_SIZE)
        self:addChild(self:getViewData().view)

        self:initView()
	end, __G__TRACKBACK__)
end

function GuideTakeoutPage1:initView()
    
end

function GuideTakeoutPage1:refreshUI(data)
    local viewData   = self:getViewData()

    local orangeBtn1  = viewData.orangeBtn1
    display.commonLabelParams(orangeBtn1, {text = tostring(data['3'])})
    local orangeBtn2  = viewData.orangeBtn2
    display.commonLabelParams(orangeBtn2, {text = tostring(data['4'])})
    
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

    local image1 = display.newImageView(RES_DIR.IMAGE_P1_1, dottedlineLayerSize.width / 2 + 30, dottedlineLayerSize.height / 2, {ap = display.CENTER})
    leftMiddleLayer:addChild(image1)

    local headIcon = display.newImageView(RES_DIR.ICO_HAND, 16, 33, {ap = display.LEFT_TOP})
    leftMiddleLayer:addChild(headIcon) 

    ------------------------------
    -- left bottom layer

    ------------------------------
    -- right layer 
    local rightImgLayerSize = cc.size(size.width / 2 - 20, size.height - 60)
    local rightImgLayer = display.newLayer(size.width - 260, size.height / 2 - 15, {ap = display.CENTER, size = rightImgLayerSize})
    view:addChild(rightImgLayer)

    local image2 = display.newImageView(RES_DIR.IMAGE_P1_2, rightImgLayerSize.width / 2, rightImgLayerSize.height * 0.75, {ap = display.CENTER})
    rightImgLayer:addChild(image2)

    local orangeBtn1 = display.newButton(30, rightImgLayerSize.height / 2 + 10, {ap = display.LEFT_BOTTOM, n = RES_DIR.ORANGE_BTN, animate = false, enable = false})
    display.commonLabelParams(orangeBtn1, fontWithColor(14, {fontSize = 20}))
    rightImgLayer:addChild(orangeBtn1)

    local line1 = display.newImageView(RES_DIR.LINE_DOTTED_1, rightImgLayerSize.width / 2, rightImgLayerSize.height / 2, {ap = display.CENTER})
    rightImgLayer:addChild(line1)

    local image2 = display.newImageView(RES_DIR.IMAGE_P1_3, rightImgLayerSize.width / 2, rightImgLayerSize.height * 0.25, {ap = display.CENTER})
    rightImgLayer:addChild(image2)

    local orangeBtn2 = display.newButton(30, rightImgLayerSize.height / 2 - 10, {ap = display.LEFT_TOP, n = RES_DIR.ORANGE_BTN, animate = false, enable = false})
    display.commonLabelParams(orangeBtn2, fontWithColor(14, {fontSize = 20}))
    rightImgLayer:addChild(orangeBtn2)

    return {
        view       = view,
        orangeBtn1 = orangeBtn1,
        orangeBtn2 = orangeBtn2,
    }
end

function GuideTakeoutPage1:getViewData()
    return self.viewData_
end

return GuideTakeoutPage1