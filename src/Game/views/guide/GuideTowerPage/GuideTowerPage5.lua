--[[
 * descpt : 烹饪指南
]]
local VIEW_SIZE = cc.size(988, 645)
local GuideTowerPage5 = class('GuideTowerPage5', function ()
	local node = CLayout:create(VIEW_SIZE)
	node.name = 'Game.views.guide.GuideTowerPage.GuideTowerPage5'
	node:enableNodeEvents()
	return node
end)

local RES_DIR = {
    SEARCHRECIPE      = _res('ui/home/kitchen/cooking_btn_pokedex.png'),
    FOODS_POKEDEX_IMG = _res('ui/common/tower_btn_quit.png'),
    FRAME_DOTTEDLINE  = _res('guide/guide_frame_dottedline.png'),
    ICO_HAND          = _res('guide/guide_ico_hand.png'),
    LABEL_TITLE       = _res('guide/guide_label_title.png'),
    LINE_DOTTED_1     = _res('guide/guide_line_dotted_1.png'),

    IMAGE_P5_1        = _res('guide/guide_tower_image_p5.png'),
    FAIL_TITLE        = _res('ui/battle/result_fail_title.png'),
    
}


local CreateView = nil

function GuideTowerPage5:ctor(...)
    local args = unpack({...}) or {}
    self:initialUI()
end

function GuideTowerPage5:initialUI()
    xTry(function ( )
        self.viewData_ = CreateView(VIEW_SIZE)
        self:addChild(self:getViewData().view)

        self:initView()
	end, __G__TRACKBACK__)
end

function GuideTowerPage5:initView()
    
end

function GuideTowerPage5:refreshUI(data)
    local viewData   = self:getViewData()
    
    local tipLabel1  = viewData.tipLabel1
    display.commonLabelParams(tipLabel1, {text = tostring(data['3'])})

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
    
    local tipLabel1 = display.newLabel(dottedlineInsideImgSize.width / 2 - 2, dottedlineInsideImgSize.height / 2, {fontSize = 22, color = '#ffffff'})
    dottedlineInsideImg:addChild(tipLabel1)

    local headIcon = display.newImageView(RES_DIR.ICO_HAND, 12, 14, {ap = display.RIGHT_TOP})
    dottedlineFrame:addChild(headIcon)

    ------------------------------
    -- left bottom layer


    ------------------------------
    -- right layer 
    local rightImgLayerSize = cc.size(size.width / 2 - 20, size.height - 60)
    local rightImgLayer = display.newLayer(size.width - 260, size.height / 2 - 15, {ap = display.CENTER, size = rightImgLayerSize})
    view:addChild(rightImgLayer)

    local rightImg = display.newImageView(RES_DIR.IMAGE_P5_1, rightImgLayerSize.width / 2 + 10, rightImgLayerSize.height / 2, {ap = display.CENTER})
    rightImgLayer:addChild(rightImg)

    local conf = {
        {po = cc.p(48, rightImgLayerSize.height - 60), scale = 0.8},
        {po = cc.p(rightImgLayerSize.width / 2, rightImgLayerSize.height / 2), scale = 0.6},
        {po = cc.p(56, 130), scale = 0.5},
    }
    for i, v in ipairs(conf) do
        local img = display.newImageView(RES_DIR.FAIL_TITLE, v.po.x, v.po.y, {ap = display.LEFT_CENTER})
        img:setScale(v.scale)
        rightImgLayer:addChild(img)
    end

    return {
        view = view,
        tipLabel1 = tipLabel1,
    }
end

function GuideTowerPage5:getViewData()
    return self.viewData_
end

return GuideTowerPage5