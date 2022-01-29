--[[
 * descpt : PVP指南
]]
local VIEW_SIZE = cc.size(988, 645)
local GuidePVPPage1 = class('GuidePVPPage1', function ()
	local node = CLayout:create(VIEW_SIZE)
	node.name = 'Game.views.guide.GuidePVPPage.GuidePVPPage1'
	node:enableNodeEvents()
	return node
end)

local RES_DIR = {
    ORANGE_BTN        = _res('ui/common/common_btn_orange.png'),
    LINE_DOTTED_1     = _res('guide/guide_line_dotted_1.png'),
    ICO_HAND          = _res('guide/guide_ico_hand.png'),
    IMAGE_P3_1        = _res('guide/guide_pvp_image_p3_1.png'),
    IMAGE_P3_2        = _res('guide/guide_pvp_image_p3_2.png'),
    IMAGE_P3_3        = _res('guide/guide_pvp_image_p3_3.png'),
}

local labelparser = require("Game.labelparser")

local CreateView = nil

function GuidePVPPage1:ctor(...)
    local args = unpack({...}) or {}
    self:initialUI()
end

function GuidePVPPage1:initialUI()
    xTry(function ( )
        self.viewData_ = CreateView(VIEW_SIZE)
        self:addChild(self:getViewData().view)

        self:initView()
	end, __G__TRACKBACK__)
end

function GuidePVPPage1:initView()
    
end

function GuidePVPPage1:refreshUI(data)
    local viewData   = self:getViewData()
    
    local tipLabel1  = viewData.tipLabel1
    display.commonLabelParams(tipLabel1, {text = tostring(data['3'])})
    local tipLabel2  = viewData.tipLabel2
    display.commonLabelParams(tipLabel2, {text = tostring(data['4'])})
    
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

    local image1 = display.newImageView(RES_DIR.IMAGE_P3_1, dottedlineLayerSize.width / 2, dottedlineLayerSize.height / 2, {ap = display.CENTER})
    leftMiddleLayer:addChild(image1)

    local tipLabel1 = display.newLabel(120, 20, {ap = display.CENTER, fontSize = 22, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#5c201d', outlineSize = 2})
    leftMiddleLayer:addChild(tipLabel1)

    local tipLabel2 = display.newLabel(296, 20, {ap = display.CENTER, fontSize = 22, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#5c201d', outlineSize = 2})
    leftMiddleLayer:addChild(tipLabel2)

    ------------------------------
    -- left bottom layer

    ------------------------------
    -- right layer 
    local rightImgLayerSize = cc.size(size.width / 2 - 20, size.height - 60)
    local rightImgLayer = display.newLayer(size.width - 260, size.height / 2 - 15, {ap = display.CENTER, size = rightImgLayerSize})
    view:addChild(rightImgLayer)

    local image2 = display.newImageView(RES_DIR.IMAGE_P3_2, rightImgLayerSize.width / 2, rightImgLayerSize.height * 0.75, {ap = display.CENTER})
    rightImgLayer:addChild(image2)

    local line1 = display.newImageView(RES_DIR.LINE_DOTTED_1, rightImgLayerSize.width / 2, rightImgLayerSize.height / 2 - 10, {ap = display.CENTER})
    rightImgLayer:addChild(line1)

    local image2 = display.newImageView(RES_DIR.IMAGE_P3_3, rightImgLayerSize.width / 2, rightImgLayerSize.height * 0.25, {ap = display.CENTER})
    rightImgLayer:addChild(image2)


    return {
        view       = view,
        tipLabel1  = tipLabel1,
        tipLabel2  = tipLabel2,
    }
end

function GuidePVPPage1:getViewData()
    return self.viewData_
end

return GuidePVPPage1
