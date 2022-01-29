--[[
 * descpt : PVP指南
]]
local VIEW_SIZE = cc.size(988, 645)
local GuidePVPPage2 = class('GuidePVPPage2', function ()
	local node = CLayout:create(VIEW_SIZE)
	node.name = 'Game.views.guide.GuideTowerPage.GuidePVPPage2'
	node:enableNodeEvents()
	return node
end)

local RES_DIR = {
    ORANGE_BTN        = _res('ui/common/common_btn_orange.png'),
    LINE_DOTTED_1     = _res('guide/guide_line_dotted_1.png'),
    ICO_HAND          = _res('guide/guide_ico_hand.png'),
    IMAGE_P1_1        = _res('guide/guide_tower_image_p1_1.png'),
    IMAGE_P1_2        = _res('guide/guide_tower_image_p1_2.png'),
}

local CreateView = nil

function GuidePVPPage2:ctor(...)
    local args = unpack({...}) or {}
    self:initialUI()
end

function GuidePVPPage2:initialUI()
    xTry(function ( )
        self.viewData_ = CreateView(VIEW_SIZE)
        self:addChild(self:getViewData().view)

        self:initView()
	end, __G__TRACKBACK__)
end

function GuidePVPPage2:initView()
    
end

function GuidePVPPage2:refreshUI(data)
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

    local image1 = display.newImageView(RES_DIR.IMAGE_P1_1, dottedlineLayerSize.width / 2 + 10, dottedlineLayerSize.height / 2 - 10, {ap = display.CENTER})
    local image1Size = image1:getContentSize()
    leftMiddleLayer:addChild(image1)

    local tipLabel1 = display.newLabel(dottedlineLayerSize.width / 2 + 26, 40, {ap = display.CENTER, fontSize = 20, color = '#ffffff'})
    leftMiddleLayer:addChild(tipLabel1)

    local headIcon = display.newImageView(RES_DIR.ICO_HAND, 270, 83, {ap = display.RIGHT_CENTER})
    headIcon:setScaleX(-1)
    leftMiddleLayer:addChild(headIcon) 

    ------------------------------
    -- left bottom layer

    ------------------------------
    -- right layer 
    local rightImgLayerSize = cc.size(size.width / 2 - 20, size.height - 60)
    local rightImgLayer = display.newLayer(size.width - 260, size.height / 2 - 15, {ap = display.CENTER, size = rightImgLayerSize})
    view:addChild(rightImgLayer)

    local image2 = display.newImageView(RES_DIR.IMAGE_P1_2, rightImgLayerSize.width / 2, rightImgLayerSize.height / 2, {ap = display.CENTER})
    rightImgLayer:addChild(image2)

    local tipLabel2 = display.newLabel(rightImgLayerSize.width - 167, 103, {ap = display.CENTER, fontSize = 32, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#5c201d', outlineSize = 1})
    rightImgLayer:addChild(tipLabel2)

    return {
        view       = view,
        tipLabel1  = tipLabel1,
        tipLabel2  = tipLabel2,
    }
end

function GuidePVPPage2:getViewData()
    return self.viewData_
end

return GuidePVPPage2
