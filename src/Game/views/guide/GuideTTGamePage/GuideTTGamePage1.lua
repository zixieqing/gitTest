--[[
 * descpt : PVP指南
]]
local VIEW_SIZE = cc.size(988, 645)
local GuideTTGamePage1 = class('GuideTTGamePage1', function ()
	local node = CLayout:create(VIEW_SIZE)
	node.name = 'Game.views.guide.GuideTTGamePage.GuideTTGamePage1'
	node:enableNodeEvents()
	return node
end)

local RES_DIR = {
    LINE_DOTTED_1 = _res('guide/guide_line_dotted_1.png'),
    IMAGE_1       = _res('guide/guide_cardgame_image_p1_1.png'),
    IMAGE_2       = _res('guide/guide_cardgame_image_p1_2.png'),
}

local labelparser = require("Game.labelparser")

local CreateView = nil

function GuideTTGamePage1:ctor(...)
    local args = unpack({...}) or {}
    self:initialUI()
end

function GuideTTGamePage1:initialUI()
    xTry(function ( )
        -- logInfo.add(5, 'GuideTTGamePage1 --- >>>>')
        self.viewData_ = CreateView(VIEW_SIZE)
        self:addChild(self:getViewData().view)

        self:initView()
	end, __G__TRACKBACK__)
end

function GuideTTGamePage1:initView()
    
end

function GuideTTGamePage1:refreshUI(data)
    local viewData   = self:getViewData()
    local image1Label = viewData.image1Label
    display.commonLabelParams(image1Label, {text = tostring(data['4']), reqW = 115})

    local image1Label1 = viewData.image1Label1
    display.commonLabelParams(image1Label1, {text = tostring(data['5'])})

    local image1Label2 = viewData.image1Label2
    display.commonLabelParams(image1Label2, {text = tostring(data['6'])})

    local image1Label1Size = display.getLabelContentSize(image1Label1)
    local image1Label2Size = display.getLabelContentSize(image1Label2)
    
    display.commonUIParams(image1Label1, {po = cc.p(204 - image1Label2Size.width * 0.5, 0)})
    display.commonUIParams(image1Label2, {po = cc.p(204 + image1Label1Size.width * 0.5, 0)})

    local image2Label1 = viewData.image2Label1
    display.commonLabelParams(image2Label1, {text = tostring(data['3'])})

    local image2Label = viewData.image2Label
    display.commonLabelParams(image2Label, {text = tostring(data['7'])})
    viewData.image2Label:setVisible(false)
    
end

CreateView = function (size)
    local view = display.newLayer(0, 0, {size = size})

    ------------------------------
    -- left middle layer
    
    local dottedlineLayerSize = cc.size(420, 180)
    local leftMiddleLayer = display.newLayer(250, size.height * 0.5 - 10, {ap = display.CENTER, size = dottedlineLayerSize})
    view:addChild(leftMiddleLayer)

    local image1 = display.newImageView(RES_DIR.IMAGE_1, dottedlineLayerSize.width * 0.5 + 10, dottedlineLayerSize.height * 0.5 - 10, {ap = display.CENTER})
    leftMiddleLayer:addChild(image1)

    local image1Label = display.newLabel(204, 106, fontWithColor('20', { fontSize = 46, ap = display.CENTER}))
    image1:addChild(image1Label)

    local image1Label1 = display.newLabel(0, 0, fontWithColor(5, {ap = display.CENTER_BOTTOM, color = '#ccb194'}))
    image1:addChild(image1Label1)

    local image1Label2 = display.newLabel(0, 0, fontWithColor(5, {ap = display.CENTER_BOTTOM, color = '#ffffff'}))
    image1:addChild(image1Label2)

    ------------------------------
    -- left bottom layer

    ------------------------------
    -- right layer 
    local rightImgLayerSize = cc.size(size.width * 0.5 - 20, size.height - 60)
    local rightImgLayer = display.newLayer(size.width - 260, size.height * 0.5 - 15, {ap = display.CENTER, size = rightImgLayerSize})
    view:addChild(rightImgLayer)

    local image2 = display.newImageView(RES_DIR.IMAGE_2, rightImgLayerSize.width * 0.5, rightImgLayerSize.height, {ap = display.CENTER_TOP})
    rightImgLayer:addChild(image2)

    local image2Label = display.newLabel(490, 2, {ap = display.RIGHT_BOTTOM, w = 24 * 8, fontSize = 24, color = '#97766f'})
    image2:addChild(image2Label)

    rightImgLayer:addChild(display.newImageView(RES_DIR.LINE_DOTTED_1, rightImgLayerSize.width * 0.5, 165, {ap = display.CENTER_TOP}))

    local image2Label1 = display.newLabel(rightImgLayerSize.width * 0.5, 155, {ap = display.CENTER_TOP, w = 400, fontSize = 22, color = '#97766f'})
    rightImgLayer:addChild(image2Label1)

    -- local headIcon = display.newImageView(RES_DIR.ICO_HAND, 115, 30, {ap = display.CENTER})
    -- rightImgLayer:addChild(headIcon)

    return {
        view         = view,
        image1Label  = image1Label,
        image1Label1 = image1Label1,
        image1Label2 = image1Label2,
        image2Label  = image2Label,
        image2Label1  = image2Label1,
    }
end

function GuideTTGamePage1:getViewData()
    return self.viewData_
end

return GuideTTGamePage1