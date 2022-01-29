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
    IMAGE_P4_1        = _res('guide/guide_tower_image_p4_1.png'),
    IMAGE_P4_2        = _res('guide/guide_tower_image_p4_2.png'),
}

local labelparser = require("Game.labelparser")

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

    local image1 = display.newImageView(RES_DIR.IMAGE_P4_1, dottedlineLayerSize.width / 2 + 10, dottedlineLayerSize.height / 2 - 10, {ap = display.CENTER})
    leftMiddleLayer:addChild(image1)

    ------------------------------
    -- left bottom layer

    ------------------------------
    -- right layer 
    local rightImgLayerSize = cc.size(size.width / 2 - 20, size.height - 60)
    local rightImgLayer = display.newLayer(size.width - 260, size.height / 2 - 15, {ap = display.CENTER, size = rightImgLayerSize})
    view:addChild(rightImgLayer)

    local image2 = display.newImageView(RES_DIR.IMAGE_P4_2, rightImgLayerSize.width / 2, rightImgLayerSize.height / 2, {ap = display.CENTER})
    rightImgLayer:addChild(image2)

    return {
        view       = view,
        tipLabel1  = tipLabel1,
    }
end

function GuidePVPPage2:getViewData()
    return self.viewData_
end

return GuidePVPPage2