--[[
 * descpt : 创建工会 home 界面
]]

local UnionCreateHomeView = class('UnionCreateHomeView', function ()
	local node = CLayout:create(display.size)
	node.name = 'Game.views.UnionCreateHomeView'
	node:enableNodeEvents()
	return node
end)

local CreateView = nil

local RES_DIR = {
    BG                  = _res("ui/common/common_bg_7.png"),
    TITLE               = _res('ui/common/common_bg_title_2.png'),
    TAB_NORMAL 			= "ui/common/common_btn_sidebar_common.png",
	TAB_PRESSED 		= "ui/common/common_btn_sidebar_selected.png",
}

local TAB_TAG = {
    TAB_LOOKUP_LABOUR_UNION = 1001,     -- 查找工会
    TAB_CREATE_LABOUR_UNION = 1002,     -- 创建工会
}

local BTN_TAG = {
    -- tab  tag
    

    CREATE_LABOUR_UNION     = 2001,
}

local GUILD_TAB_CONFIG = {
	{name = __('查找工会'), tag = TAB_TAG.TAB_LOOKUP_LABOUR_UNION},
	{name = __('创建工会'), tag = TAB_TAG.TAB_CREATE_LABOUR_UNION},
}

function UnionCreateHomeView:ctor( ... )
    self.args = unpack({...})
    self:initialUI()
end

function UnionCreateHomeView:initialUI()
    xTry(function ( )
        self.viewData_ = CreateView()
        dump(self.viewData_, 'dddddddddd')
	end, __G__TRACKBACK__)
end

CreateView = function ()
    local view = display.newLayer()
    local size = view:getContentSize()
    
    local blackBg = display.newLayer(0, 0, {color = cc.c4b(0, 0, 0, 150), enable = true})
    view:addChild(blackBg)

    local layerSize = cc.size(1230 + 45, 635)
    
    local layer = display.newLayer(display.cx, display.cy, {ap = display.CENTER, size = layerSize})
    view:addChild(layer)

    local bgSize = cc.size(1082 + 45, 635)
    local bgLayer = display.newLayer(0, layerSize.height / 2, {ap = display.LEFT_CENTER, size = bgSize})
    layer:addChild(bgLayer)

    local bg = display.newImageView(RES_DIR.BG, 0, 0, {ap = display.LEFT_BOTTOM, size = bgSize, scale9 = true})
    bgLayer:addChild(bg)
    
    -- local titleBg = display.newImageView(_res('ui/common/common_bg_title_2.png'), 0, 0, {ap = display.CENTER})
	-- local titleBgSize = titleBg:getContentSize()
	-- local titleLabel = display.newLabel(0, 0, fontWithColor(7,{text = 'title', ap = display.CENTER}))
	-- display.commonUIParams(titleBg,    {po = cc.p(bgSize.width / 2, bgSize.height - 20)})
	-- display.commonUIParams(titleLabel, {po = cc.p(titleBgSize.width / 2, titleBgSize.height / 2)})
    -- bgLayer:addChild(titleBg)
    local titleBg = display.newButton(bgSize.width / 2, bgSize.height - 20, {n = RES_DIR.TITLE, ap = display.CENTER, enable = false})
    display.commonLabelParams(titleBg, fontWithColor(7, {fontSize = 24, offset = isJapanSdk() and cc.p(0, -1) or cc.p(0, -3)}))
    bgLayer:addChild(titleBg)

    local touchView = display.newLayer(0, 0, {ap = display.LEFT_BOTTOM, size = bgSize, enable = true, color = cc.c4b(0, 0, 0, 0)})
    bgLayer:addChild(touchView)
    
    local tabLayerSize = cc.size(143, layerSize.height - 50)
    local tabLayer = display.newLayer(bgSize.width - 18, tabLayerSize.height, {ap = display.LEFT_TOP, size = tabLayerSize})
    layer:addChild(tabLayer)

    local tabButtons = {}
    for i,v in ipairs(GUILD_TAB_CONFIG) do
        local tabButton = display.newCheckBox(0, 0, {n = RES_DIR.TAB_NORMAL, s = RES_DIR.TAB_PRESSED,})
        local tabButtonSize = tabButton:getContentSize()
        display.commonUIParams(tabButton, {ap = display.LEFT_TOP, po = cc.p(0, tabLayerSize.height - 10 - (i - 1) * tabButtonSize.height)})
        tabLayer:addChild(tabButton)
        tabButton:setTag(v.tag)
        tabButtons[tostring(v.tag)] = tabButton

        local tabNameLabel1 = display.newLabel(utils.getLocalCenter(tabButton).x - 5 , utils.getLocalCenter(tabButton).y - (isJapanSdk() and 0 or 10),
            fontWithColor(2,{text = v.name,ap = cc.p(0.5, 0), color = '3c3c3c', fontSize = 24 , w = 130 ,reqH = 60 , hAlign = display.TAC }))
        tabButton:addChild(tabNameLabel1)
        tabNameLabel1:setTag(3)

    end


    return {
        view          = view,
        blackBg       = blackBg,
        bgLayer       = bgLayer,
        titleBg    = titleBg,
        tabButtons    = tabButtons,
    }
end

function UnionCreateHomeView:getViewData()
	return self.viewData_
end

return UnionCreateHomeView