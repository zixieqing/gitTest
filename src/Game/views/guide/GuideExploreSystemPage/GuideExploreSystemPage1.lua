--[[
 * descpt : 卡牌指南
]]
local VIEW_SIZE = cc.size(988, 645)
local GuideExploreSystemPage1 = class('GuideExploreSystemPage1', function ()
	local node = CLayout:create(VIEW_SIZE)
	node.name = 'Game.views.guide.GuideExploreSystemPage.GuideExploreSystemPage1'
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
    ORANGE_BTN        = _res('ui/common/common_btn_orange.png'),

    IMAGE_P1          = _res('guide/guide_explore_image_p1_1.png'),
    BG_CELL_ACTIVE    = _res('ui/exploreSystem/explor_edit_bg_conditiong_list_active.png'),
    ICO_MARK_EMPTY    = _res('ui/tower/team/tower_ico_mark_empty.png'),
}

local CreateView = nil
local CreateDottedlineLayer = nil

function GuideExploreSystemPage1:ctor(...)
    local args = unpack({...}) or {}
    self:initialUI()
end

function GuideExploreSystemPage1:initialUI()
    xTry(function ( )
        self.viewData_ = CreateView(VIEW_SIZE)
        self:addChild(self:getViewData().view)

        self:initView()
	end, __G__TRACKBACK__)
end

function GuideExploreSystemPage1:initView()
    
end

function GuideExploreSystemPage1:refreshUI(data)
    local viewData   = self:getViewData()
    
    local label3 = viewData.label3
    display.commonLabelParams(label3, {text = tostring(data['3'])})

    local label4 = viewData.label4
    display.commonLabelParams(label4, {text = tostring(data['4'])})

    local orangeBtn  = viewData.orangeBtn
    display.commonLabelParams(orangeBtn, {text = tostring(data['5']), reqW = 103})

    local descLabel = viewData.descLabel
    display.commonLabelParams(descLabel, {text = tostring(data['6'])})

    local orangeBtn1  = viewData.orangeBtn1
    display.commonLabelParams(orangeBtn1, {text = tostring(data['7']), reqW = 103})
    
end

CreateView = function (size)
    local view = display.newLayer(0, 0, {size = size})

    ------------------------------
    -- dottedline layer
    
    local dottedlineLayer, orangeBtn = CreateDottedlineLayer()
    display.commonUIParams(dottedlineLayer, {po = cc.p(250, size.height / 2 - 10)})
    view:addChild(dottedlineLayer)

    ------------------------------
    -- left bottom layer


    ------------------------------
    -- right layer 
    local rightImgLayerSize = cc.size(size.width / 2 - 20, size.height - 60)
    local rightImgLayer = display.newLayer(size.width - 260, size.height / 2 - 15, {ap = display.CENTER, size = rightImgLayerSize})
    view:addChild(rightImgLayer)

    rightImgLayer:addChild(display.newImageView(RES_DIR.IMAGE_P1, rightImgLayerSize.width / 2, rightImgLayerSize.height, {ap = display.CENTER_TOP}))
    
    local cellBgImg = display.newImageView(RES_DIR.BG_CELL_ACTIVE, rightImgLayerSize.width / 2, rightImgLayerSize.height - 150, {ap = display.CENTER_TOP})
    rightImgLayer:addChild(cellBgImg)

    cellBgImg:addChild(display.newImageView(_res('ui/exploreSystem/icon/explor_term_grade_3.png'), 34, 45))

    local descLabel = display.newLabel(67, 45, fontWithColor(5, {hAlign = display.TAL, ap = display.LEFT_CENTER, w = 265}))
    cellBgImg:addChild(descLabel)

    local conditionSatisfyImg = display.newImageView(RES_DIR.ICO_MARK_EMPTY, 360, 50, {ap = display.CENTER})
    cellBgImg:addChild(conditionSatisfyImg)

    local headIcon2 = display.newImageView(RES_DIR.ICO_HAND, 392, 14, {ap = display.CENTER})
    headIcon2:setScaleX(-1)
    cellBgImg:addChild(headIcon2)
    
    rightImgLayer:addChild(display.newImageView(RES_DIR.LINE_DOTTED_1, rightImgLayerSize.width / 2, rightImgLayerSize.height - 260, {ap = display.CENTER_TOP}))

    local label3 = display.newLabel(40, rightImgLayerSize.height - 270, {ap = display.LEFT_TOP, w = 24 * 16, fontSize = 24, color = '#97766f'})
    rightImgLayer:addChild(label3)


    local dottedlineLayer1, orangeBtn1, headIcon1 = CreateDottedlineLayer()
    display.commonUIParams(dottedlineLayer1, {po = cc.p(rightImgLayerSize.width / 2, 160)})
    headIcon1:setScaleX(-1)
    display.commonUIParams(headIcon1, {po = cc.p(150, 68)})
    -- display.commonUIParams(headIcon1, params)
    rightImgLayer:addChild(dottedlineLayer1)


    rightImgLayer:addChild(display.newImageView(RES_DIR.LINE_DOTTED_1, rightImgLayerSize.width / 2, 110, {ap = display.CENTER_TOP}))
    local label4 = display.newLabel(40, 100, {ap = display.LEFT_TOP, w = 24 * 16, fontSize = 24, color = '#97766f'})
    rightImgLayer:addChild(label4)

    return {
        view        = view,
        orangeBtn   = orangeBtn,
        label3      = label3,
        label4      = label4,
        descLabel   = descLabel,
        orangeBtn1  = orangeBtn1,
    }
end

CreateDottedlineLayer = function()
    local dottedlineLayerSize = cc.size(420, 180)
    local dottedlineLayer = display.newLayer(0, 0, {ap = display.CENTER, size = dottedlineLayerSize})

    local dottedlineFrameSize = cc.size(195, 88)
    local dottedlineFrame = display.newImageView(RES_DIR.FRAME_DOTTEDLINE, dottedlineLayerSize.width / 2, dottedlineLayerSize.height / 2, {ap = display.CENTER, scale9 = true, size = dottedlineFrameSize})
    dottedlineLayer:addChild(dottedlineFrame)

    local orangeBtn = display.newButton(dottedlineFrameSize.width / 2, dottedlineFrameSize.height / 2, {ap = display.CENTER, n = RES_DIR.ORANGE_BTN})
    display.commonLabelParams(orangeBtn, fontWithColor(14, {fontSize = 20}))
    dottedlineFrame:addChild(orangeBtn)

    local headIcon = display.newImageView(RES_DIR.ICO_HAND, 12, 14, {ap = display.RIGHT_TOP})
    dottedlineFrame:addChild(headIcon)

    return dottedlineLayer, orangeBtn, headIcon
end

function GuideExploreSystemPage1:getViewData()
    return self.viewData_
end

return GuideExploreSystemPage1