--[[
登录弹窗
--]]
local PlotCollectView = class('PlotCollectView', function ()
	local node = CLayout:create(display.size)
	node.name = 'Game.views.plotCollect.PlotCollectView'
	node:enableNodeEvents()
	return node
end)

local RES_DICT = {
    COMMON_BTN_BACK      = _res('ui/common/common_btn_back.png'),
    COMMON_TITLE         = _res('ui/common/common_title_new.png'),
    COMMON_BTN_TIPS      = _res('ui/common/common_btn_tips.png'),
    PLOT_COLLECT_BG      = _res('ui/home/plotCollect/plot_collect_bg.jpg'),
    PLOT_COLLECT_NAME_BG = _res('ui/home/plotCollect/plot_collect_name_bg.png'),

    DOT                  = _res('ui/home/plotCollect/effects/dian.plist')
}

local CreateView     = nil
local CreatePlotNode = nil

function PlotCollectView:ctor( ... )
    self.args = unpack({...})

	xTry(function ( )
        self.viewData = CreateView()
        self:addChild(self.viewData.view)
	end, __G__TRACKBACK__)
end

CreateView = function ()
    local view = display.newLayer()
    local size = view:getContentSize()

    local shallowLayer = display.newLayer(0, 0, {size = size, color = cc.c4b(0,0,0,0), enable = true})
    view:addChild(shallowLayer)

    local middlePosX, middlePosY = size.width * 0.5, size.height * 0.5
    local bg = display.newNSprite(RES_DICT.PLOT_COLLECT_BG, middlePosX, middlePosY)
    view:addChild(bg)

    local backBtn = display.newButton(display.SAFE_L + 57, display.height - 55,
    {
        ap = display.CENTER,
        n = RES_DICT.COMMON_BTN_BACK,
        enable = true,
    })
    view:addChild(backBtn)

    local titleBtn = display.newButton(display.SAFE_L + 130, display.height, {n = RES_DICT.COMMON_TITLE, enable = true, ap = display.LEFT_TOP})
    display.commonLabelParams(titleBtn, {ttf = true, font = TTF_GAME_FONT, text = __('剧情收集'), fontSize = 30, color = '#473227',offset = cc.p(0,-8)})
    view:addChild(titleBtn)

    local tipsImg = display.newNSprite(RES_DICT.COMMON_BTN_TIPS, 250, 30,
    {
        ap = display.CENTER,
    })
    titleBtn:addChild(tipsImg)

    local plotLayerSize = cc.size(1624, 1002)
    local plotLayer = display.newLayer(middlePosX, middlePosY, {size = cc.size(1624, 1002), ap = display.CENTER})
    view:addChild(plotLayer)

    local plotNodes   = {}
    local coordinates = CommonUtils.GetConfigAllMess('collectCoordinate', 'plot') or {}
    if next(coordinates) then
        for key, value in pairs(coordinates) do
            local plotNode = CreatePlotNode(value.name)
            local position = checktable(value.pos)
            local pos = cc.p(checkint(position[1]), checkint(position[2]))
            pos.y = plotLayerSize.height - pos.y
            display.commonUIParams(plotNode, {po = pos})
            plotLayer:addChild(plotNode)
            
            plotNode:setTag(value.id)
            table.insert(plotNodes, plotNode)
        end
    end

    return {
        view      = view,
        backBtn   = backBtn,
        titleBtn  = titleBtn,
        plotNodes = plotNodes,
    }
end

CreatePlotNode = function (text)
    local size = cc.size(131, 131)
    local node = display.newLayer(0, 0, {ap = display.CENTER_BOTTOM, size = size, color = cc.c4b(0,0,0,0), enable = true})

    local name = display.newButton(size.width * 0.5, 0, {n = RES_DICT.PLOT_COLLECT_NAME_BG, ap = display.CENTER_BOTTOM})
    display.commonLabelParams(name, fontWithColor(16, {text = tostring(text)}))
    node:addChild(name)
    name:setVisible(false)

    local particle = cc.ParticleSystemQuad:create(RES_DICT.DOT)
    particle:setAutoRemoveOnFinish(true)
    particle:setPosition(cc.p(size.width * 0.5 + 30, 30))
    name:addChild(particle)

    node.viewData = {
        name = name
    }
    return node
end

function PlotCollectView:GetViewData()
	return self.viewData
end

return PlotCollectView
