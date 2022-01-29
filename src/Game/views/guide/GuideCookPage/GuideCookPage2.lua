--[[
 * descpt : 烹饪指南
]]
local VIEW_SIZE = cc.size(988, 645)
local GuideCookPage2 = class('GuideCookPage2', function ()
	local node = CLayout:create(VIEW_SIZE)
	node.name = 'Game.views.guide.GuideCookPage.GuideCookPage2'
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
}


local CreateView = nil

function GuideCookPage2:ctor(...)
    local args = unpack({...}) or {}
    self:initialUI()
end

function GuideCookPage2:initialUI()
    xTry(function ( )
        self.viewData_ = CreateView(VIEW_SIZE)
        self:addChild(self:getViewData().view)

        self:initView()
	end, __G__TRACKBACK__)
end

function GuideCookPage2:initView()

end

function GuideCookPage2:refreshUI(data)
    local viewData   = self:getViewData()

    local searchLabel  = viewData.searchLabel
    display.commonLabelParams(searchLabel, {text = tostring(data['3']) , reqW =  95})

    local descLabel4  = viewData.descLabel4
    display.commonLabelParams(descLabel4, {text = CommonUtils.parserGuideDesc(data['4'])})

end

CreateView = function (size)
    local view = display.newLayer(0, 0, {size = size})

    ------------------------------
    -- dottedline layer
    local dottedlineLayerSize = cc.size(420, 180)
    local dottedlineLayer = display.newLayer(250, size.height / 2 - 10, {ap = display.CENTER, size = dottedlineLayerSize})
    view:addChild(dottedlineLayer)
    -- dottedlineLayer:setVisible(false)

    local dottedlineFrame = display.newImageView(RES_DIR.FRAME_DOTTEDLINE, dottedlineLayerSize.width / 2, dottedlineLayerSize.height / 2, {ap = display.CENTER})
    local dottedlineFrameSize = dottedlineFrame:getContentSize()
    dottedlineLayer:addChild(dottedlineFrame)

    local dottedlineInsideImg = display.newImageView(RES_DIR.FOODS_POKEDEX_IMG, dottedlineFrameSize.width / 2, dottedlineFrameSize.height / 2, {ap = display.CENTER})
    local dottedlineInsideImgSize = dottedlineInsideImg:getContentSize()
    dottedlineFrame:addChild(dottedlineInsideImg)

    local searchImage = display.newImageView(RES_DIR.SEARCHRECIPE, 10, dottedlineInsideImgSize.height / 2, {ap = display.LEFT_CENTER})
	local searchImageSize = searchImage:getContentSize()
	local searchLabel = display.newLabel(searchImage:getPositionX() + searchImageSize.width + 10, dottedlineInsideImgSize.height / 2, fontWithColor('10', {ap = display.LEFT_CENTER, color = "#ffffff" }))
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

    local rightDialogLayer = display.newLayer(size.width - 260, size.height / 2 - 15, {ap = display.CENTER, size = rightImgLayerSize})
    view:addChild(rightDialogLayer)

    local rightDialogImg = display.newImageView(_res('guide/guide_cood_image_p2.png'), rightImgLayerSize.width / 2, 0, {ap = display.CENTER_BOTTOM})
    rightDialogLayer:addChild(rightDialogImg)

    local dialogBoard = display.newImageView(RES_DIR.BOARD, rightImgLayerSize.width / 2, rightImgLayerSize.height - 222, {ap = display.CENTER_BOTTOM})
    local dialogBoardSize = dialogBoard:getContentSize()
    rightDialogLayer:addChild(dialogBoard)

    local arrow = display.newImageView(RES_DIR.ARROW, dialogBoardSize.width / 2, 3, {ap = display.CENTER})
    arrow:setRotation(180)
    dialogBoard:addChild(arrow)

    -- local descLabel4 = display.newRichLabel(dialogBoardSize.width / 2, 170, {ap = display.CENTER_TOP, w = 29})
    -- dialogBoard:addChild(descLabel4)
    local descLabel4 = display.newLabel(dialogBoardSize.width / 2, 170, {ap = display.CENTER_TOP, w = dialogBoardSize.width - 50, fontSize = 24, color = '#97766f'})
    dialogBoard:addChild(descLabel4)

    return {
        view        = view,
        searchLabel = searchLabel,
        descLabel4  = descLabel4,
    }
end

function GuideCookPage2:getViewData()
    return self.viewData_
end

return GuideCookPage2
