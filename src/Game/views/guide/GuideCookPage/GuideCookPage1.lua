--[[
 * descpt : 烹饪指南
]]
local VIEW_SIZE = cc.size(988, 645)
local GuideCookPage1 = class('GuideCookPage1', function ()
	local node = CLayout:create(VIEW_SIZE)
	node.name = 'Game.views.guide.GuideCookPage.GuideCookPage1'
	node:enableNodeEvents()
	return node
end)

local RES_DIR = {
    ORANGE_BTN        = _res('ui/common/common_btn_orange.png'),
    LINE_DOTTED_1     = _res('guide/guide_line_dotted_1.png'),
}

local labelparser = require("Game.labelparser")

local CreateView = nil

function GuideCookPage1:ctor(...)
    local args = unpack({...}) or {}
    self:initialUI()
end

function GuideCookPage1:initialUI()
    xTry(function ( )
        self.viewData_ = CreateView(VIEW_SIZE)
        self:addChild(self:getViewData().view)

        self:initView()
	end, __G__TRACKBACK__)
end

function GuideCookPage1:initView()
    
end

function GuideCookPage1:refreshUI(data)
    local viewData   = self:getViewData()
    
    local orangeBtn  = viewData.orangeBtn
    display.commonLabelParams(orangeBtn, {text = tostring(data['3'])})
    
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

    local image1 = display.newImageView(_res('guide/guide_cook_image_p1_1.png'), dottedlineLayerSize.width / 2, dottedlineLayerSize.height / 2, {ap = display.CENTER})
    leftMiddleLayer:addChild(image1)

    local orangeBtn = display.newButton(dottedlineLayerSize.width / 2 - 10, 40, {ap = display.CENTER, n = RES_DIR.ORANGE_BTN})
    display.commonLabelParams(orangeBtn, fontWithColor(14, {fontSize = 20, text = __('开发')}))
    leftMiddleLayer:addChild(orangeBtn)

    ------------------------------
    -- left bottom layer

    ------------------------------
    -- right layer 
    local rightImgLayerSize = cc.size(size.width / 2 - 20, size.height - 60)
    local rightImgLayer = display.newLayer(size.width - 260, size.height / 2 - 15, {ap = display.CENTER, size = rightImgLayerSize})
    view:addChild(rightImgLayer)

    local rightImg = display.newImageView(_res('guide/guide_cook_image_p1_2.png'), rightImgLayerSize.width / 2, rightImgLayerSize.height / 2, {ap = display.CENTER})
    rightImgLayer:addChild(rightImg)


    return {
        view = view,
        orangeBtn = orangeBtn,
        descLabel2 = descLabel2,
    }
end

function GuideCookPage1:getViewData()
    return self.viewData_
end

return GuideCookPage1