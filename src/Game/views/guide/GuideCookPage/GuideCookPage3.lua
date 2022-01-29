--[[
 * descpt : 烹饪指南
]]
local VIEW_SIZE = cc.size(988, 645)
local GuideCookPage3 = class('GuideCookPage3', function ()
	local node = CLayout:create(VIEW_SIZE)
	node.name = 'Game.views.guide.GuideCookPage.GuideCookPage3'
	node:enableNodeEvents()
	return node
end)

local RES_DIR = {
    SEARCHRECIPE      = _res('ui/home/kitchen/cooking_btn_pokedex.png'),
    FOODS_POKEDEX_IMG = _res('ui/home/kitchen/kitchen_btn_foods_pokedex.png'),
    FRAME_DOTTEDLINE  = _res('guide/guide_frame_dottedline.png'),
    ICO_HAND          = _res('guide/guide_ico_hand.png'),
    LABEL_TITLE       = _res('guide/guide_label_title.png'),
    LINE_DOTTED_1     = _res('guide/guide_line_dotted_1.png'),
}


local CreateView = nil

function GuideCookPage3:ctor(...)
    local args = unpack({...}) or {}
    self:initialUI()
end

function GuideCookPage3:initialUI()
    xTry(function ( )
        self.viewData_ = CreateView(VIEW_SIZE)
        self:addChild(self:getViewData().view)

        self:initView()
	end, __G__TRACKBACK__)
end

function GuideCookPage3:initView()
    
end

function GuideCookPage3:refreshUI(data)
    local viewData   = self:getViewData()
    
    local searchLabel  = viewData.searchLabel
    display.commonLabelParams(searchLabel, {text = tostring(data['3']) , reqW =95})

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

    local dottedlineInsideImg = display.newImageView(RES_DIR.FOODS_POKEDEX_IMG, dottedlineFrameSize.width / 2, dottedlineFrameSize.height / 2, {ap = display.CENTER})
    local dottedlineInsideImgSize = dottedlineInsideImg:getContentSize()
    dottedlineFrame:addChild(dottedlineInsideImg)

    local searchImage = display.newImageView(RES_DIR.SEARCHRECIPE, 10, dottedlineInsideImgSize.height / 2, {ap = display.LEFT_CENTER})
	local searchImageSize = searchImage:getContentSize()
	local searchLabel = display.newLabel(searchImage:getPositionX() + searchImageSize.width + 2, dottedlineInsideImgSize.height / 2, fontWithColor('10', {ap = display.LEFT_CENTER, color = "#ffffff" }))
	local searchLabelSize = display.getLabelContentSize(searchLabel)
    dottedlineInsideImg:addChild(searchImage)
    dottedlineInsideImg:addChild(searchLabel)

    local headIcon = display.newImageView(RES_DIR.ICO_HAND, 12, 14, {ap = display.RIGHT_TOP})
    dottedlineFrame:addChild(headIcon)

    ------------------------------
    -- left bottom layer


    ------------------------------
    -- right layer 
    local rightImgLayerSize = cc.size(size.width / 2 - 20, size.height - 60)
    local rightImgLayer = display.newLayer(size.width - 260, size.height / 2 - 15, {ap = display.CENTER, size = rightImgLayerSize})
    view:addChild(rightImgLayer)

    local rightImg = display.newImageView(_res('guide/guide_cood_image_p3.png'), rightImgLayerSize.width / 2, rightImgLayerSize.height / 2, {ap = display.CENTER})
    rightImgLayer:addChild(rightImg)


    return {
        view = view,
        searchLabel = searchLabel,
    }
end

function GuideCookPage3:getViewData()
    return self.viewData_
end

return GuideCookPage3
