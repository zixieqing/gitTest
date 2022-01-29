--[[
 * descpt : PVP指南
]]
local VIEW_SIZE = cc.size(988, 645)
local GuideExploreSystemPage2 = class('GuideExploreSystemPage2', function ()
	local node = CLayout:create(VIEW_SIZE)
	node.name = 'Game.views.guide.GuideExploreSystemPage.GuideExploreSystemPage2'
	node:enableNodeEvents()
	return node
end)

local RES_DIR = {
    ORANGE_BTN        = _res('ui/common/common_btn_orange.png'),
    LINE_DOTTED_1     = _res('guide/guide_line_dotted_1.png'),
    ICO_HAND          = _res('guide/guide_ico_hand.png'),
    IMAGE_P2_1        = _res('guide/guide_explore_image_p2_1.png'),
    IMAGE_P2_2        = _res('guide/guide_explore_image_p2_2.png'),
    IMAGE_P2_3        = _res('guide/guide_explore_image_p2_3.png'),
}

local labelparser = require("Game.labelparser")

local CreateView = nil

function GuideExploreSystemPage2:ctor(...)
    local args = unpack({...}) or {}
    self:initialUI()
end

function GuideExploreSystemPage2:initialUI()
    xTry(function ( )
        -- logInfo.add(5, 'GuideExploreSystemPage2 --- >>>>')
        self.viewData_ = CreateView(VIEW_SIZE)
        self:addChild(self:getViewData().view)

        self:initView()
	end, __G__TRACKBACK__)
end

function GuideExploreSystemPage2:initView()
    
end

function GuideExploreSystemPage2:refreshUI(data)
    local viewData   = self:getViewData()
    local image1Label = viewData.image1Label
    display.commonLabelParams(image1Label, {text = tostring(data['4']), reqW = 115})

    local image1Label1 = viewData.image1Label1
    display.commonLabelParams(image1Label1, {text = tostring(data['5'])})

    local image1Label2 = viewData.image1Label2
    display.commonLabelParams(image1Label2, {text = tostring(data['6'])})

    local image1Label1Size = display.getLabelContentSize(image1Label1)
    local image1Label2Size = display.getLabelContentSize(image1Label2)
    
    display.commonUIParams(image1Label1, {po = cc.p(204 - image1Label2Size.width / 2, 0)})
    display.commonUIParams(image1Label2, {po = cc.p(204 + image1Label1Size.width / 2, 0)})

    local image2Label1 = viewData.image2Label1
    display.commonLabelParams(image2Label1, {text = tostring(data['3'])})

    local image2Label = viewData.image2Label
    display.commonLabelParams(image2Label, {text = tostring(data['7'])})
    
end

CreateView = function (size)
    local view = display.newLayer(0, 0, {size = size})

    ------------------------------
    -- left middle layer
    
    local dottedlineLayerSize = cc.size(420, 180)
    local leftMiddleLayer = display.newLayer(250, size.height / 2 - 10, {ap = display.CENTER, size = dottedlineLayerSize})
    view:addChild(leftMiddleLayer)

    local image1 = display.newImageView(RES_DIR.IMAGE_P2_1, dottedlineLayerSize.width / 2 + 10, dottedlineLayerSize.height / 2 - 10, {ap = display.CENTER})
    leftMiddleLayer:addChild(image1)

    local image1Label = display.newLabel(204, 106, fontWithColor('20', { fontSize = 46, ap = display.CENTER}))
    image1:addChild(image1Label)

    local image1Label1 = display.newLabel(0, 0, fontWithColor(5, {ap = display.CENTER_BOTTOM, color = '#ccb194'}))
    image1:addChild(image1Label1)

    local image1Label2 = display.newLabel(0, 0, fontWithColor(5, {ap = display.CENTER_BOTTOM, color = '#ffffff'}))
    image1:addChild(image1Label2)

    local headIcon = display.newImageView(RES_DIR.ICO_HAND, 296, 40, {ap = display.CENTER})
    headIcon:setScaleX(-1)
    image1:addChild(headIcon)
    ------------------------------
    -- left bottom layer

    ------------------------------
    -- right layer 
    local rightImgLayerSize = cc.size(size.width / 2 - 20, size.height - 60)
    local rightImgLayer = display.newLayer(size.width - 260, size.height / 2 - 15, {ap = display.CENTER, size = rightImgLayerSize})
    view:addChild(rightImgLayer)

    local image2 = display.newImageView(RES_DIR.IMAGE_P2_2, rightImgLayerSize.width / 2 + 10, rightImgLayerSize.height + 35, {ap = display.CENTER_TOP})
    rightImgLayer:addChild(image2)

    local image2Label = display.newLabel(490, 2, {ap = display.RIGHT_BOTTOM, w = 24 * 8, fontSize = 24, color = '#97766f'})
    image2:addChild(image2Label)

    rightImgLayer:addChild(display.newImageView(RES_DIR.LINE_DOTTED_1, rightImgLayerSize.width / 2, 240, {ap = display.CENTER_TOP}))

    local image2Label1 = display.newLabel(rightImgLayerSize.width / 2, 230, {ap = display.CENTER_TOP, w = 24 * 16, fontSize = 24, color = '#97766f'})
    rightImgLayer:addChild(image2Label1)

    rightImgLayer:addChild(display.newImageView(RES_DIR.IMAGE_P2_3, rightImgLayerSize.width / 2 + 10, -18, {ap = display.CENTER_BOTTOM}))

    local headIcon = display.newImageView(RES_DIR.ICO_HAND, 115, 30, {ap = display.CENTER})
    rightImgLayer:addChild(headIcon)

    return {
        view         = view,
        image1Label  = image1Label,
        image1Label1 = image1Label1,
        image1Label2 = image1Label2,
        image2Label  = image2Label,
        image2Label1  = image2Label1,
    }
end

function GuideExploreSystemPage2:getViewData()
    return self.viewData_
end

return GuideExploreSystemPage2