local LobbyFestivalActivityView = class('LobbyFestivalActivityView',
    function ()
        local node = CLayout:create(display.size)
        node.name = 'Game.views.LobbyFestivalActivityView'
        node:enableNodeEvents()
        return node
    end
)

local RES_DIR = {
    BG                       = _res('ui/common/common_bg_2.png'),
    TITLE_FIRST              = _res('ui/common/common_bg_title_2.png'),
    TITLE_SECOND             = _res('ui/common/common_title_5.png'),
    COUNTDOWN_TRAILER        = _res('avatar/ui/festival_bg_countdown.png'),
    COUNTDOWN_OVER           = _res('avatar/ui/festival_bg_countdown_over.png'),
    GOOD_BG                  = _res('avatar/ui/festival_bg_prize.png'),
    LSIT_BG                  = _res('ui/common/common_bg_goods.png'),
    LSIT_CELL_BG             = _res('avatar/ui/common_bg_list.png'),
    LSIT_CELL_UNLOCK_BG      = _res('avatar/ui/common_bg_list_unlock.png'),
    LINE                     = _res('ui/pet/pet_info_ico_attribute_line.png'),
    LSIT_CELL_GOOD_BG        = _res("ui/airship/ship_ico_label_goods_tag.png"), 
    ATTR_BG                  = _res('ui/home/market/market_buy_bg_info.png'),
}

local FESTIVAL_ACTIVITY_STATE = {
    PREVIEW = 1,    -- 活动预览装填 
    OPEN    = 2,    -- 活动开始状态
}

local CreateView  = nil
local CreateCell_ = nil
local CreateAttr_ = nil

local ATTR_NAME_CONFIG = {
    ['1'] = '味道',
    ['2'] = '口感',
    ['3'] = '香味',
    ['4'] = '外观'
}

function LobbyFestivalActivityView:ctor( ... )
    self.args = unpack({...})
    self:initUi()
end

function LobbyFestivalActivityView:initUi()
    self.viewData = CreateView()
    self:addChild(self.viewData.view)
    display.commonUIParams(self.viewData.touchLayer, {cb = handler(self, self.CloseHandler)})
end

function LobbyFestivalActivityView:updateViewState(state, data)
    local viewData             = self.viewData
    local descLabel            = viewData.descLabel
    local title                = viewData.title
    local goodBgLayer          = viewData.goodBgLayer
    local requirementLayer     = viewData.requirementLayer
    local titleSecond          = viewData.titleSecond
    local listLayer            = viewData.listLayer
    local listBg               = viewData.listBg
    local gridView             = viewData.gridView

    local titleSecondSize      = viewData.titleSecondSize
    local layerSize            = viewData.layerSize
    local goodBgSize           = viewData.goodBgSize

    goodBgLayer:setVisible(state == RemindTag.LOBBY_FESTIVAL_ACTIVITY)

    local requirementLayerPosY = nil
    local descLabelSize = display.getLabelContentSize(descLabel)
    if state == RemindTag.LOBBY_FESTIVAL_ACTIVITY then
        local rewards = {}
        local temp = {} 
        for i,v in pairs(data.content.recipes) do
            for ii,vv in ipairs(v.rewards) do
                if vv.goodsId and temp[vv.goodsId] == nil then
                    temp[vv.goodsId] = vv.goodsId
                    table.insert( rewards, vv )
                end
            end
        end
        local params = {parent = goodBgLayer, midPointX = goodBgSize.width * 0.5, midPointY = goodBgSize.height * 0.5, maxCol= 4, scale = 0.8, rewards = rewards, hideCustomizeLabel = true, hideAmount = false}
        CommonUtils.createPropList(params)

        -- goodBgLayer
        goodBgLayer:setPositionY(descLabel:getPositionY() - descLabelSize.height - 10)
        requirementLayerPosY = goodBgLayer:getPositionY() - goodBgSize.height - 5

    else
        requirementLayerPosY = descLabel:getPositionY() - descLabelSize.height - 10
    end
    
    local requirementLayerSize = cc.size(layerSize.width - 60, requirementLayerPosY - 12)
    local listSize = cc.size(requirementLayerSize.width, requirementLayerSize.height - titleSecondSize.height - 5)

    requirementLayer:setContentSize(requirementLayerSize)
    listLayer:setContentSize(listSize)
    gridView:setContentSize(listSize)
    listBg:setContentSize(listSize)
    
    display.commonUIParams(requirementLayer, {po = cc.p(title:getPositionX(), requirementLayerPosY)})
    display.commonUIParams(titleSecond,      {po = cc.p(requirementLayerSize.width / 2, requirementLayerSize.height-2)})
    display.commonUIParams(listLayer,        {po = cc.p(titleSecond:getPositionX(), listSize.height)})
    display.commonUIParams(gridView,         {po = cc.p(listSize.width / 2, listSize.height)})

end

function LobbyFestivalActivityView:getArgs()
    return self.args
end

function LobbyFestivalActivityView:CreateCell( ... )
    return CreateCell_()
end

function LobbyFestivalActivityView:CreateAttr(attrLayer, i, attr)
    return CreateAttr_(attrLayer, i, attr)
end

function LobbyFestivalActivityView:CloseHandler()
	local args = self:getArgs()
	-- local tag = args.tag
	local mediatorName = args.mediatorName
	
	local mediator = AppFacade.GetInstance():RetrieveMediator(mediatorName)
	if mediator then
		AppFacade.GetInstance():UnRegsitMediator(mediatorName)
	end
	
end

CreateView = function ()
    local view = display.newLayer(0, 0, {size = display.size, ap = display.LEFT_BOTTOM})
    local touchLayer = display.newLayer(0, 0, {size = display.size, color = cc.c4b(0,0,0,156), enable = true, ap = display.LEFT_BOTTOM})
    
    view:addChild(touchLayer)

    local layer = display.newLayer(display.cx, display.cy, {ap = display.CENTER, bg = RES_DIR.BG})
    local layerSize = layer:getContentSize()
    local shadowLayer = display.newLayer(0, 0, {ap = display.LEFT_BOTTOM, color = cc.c4b(0, 0, 0, 0), enable = true, size = layerSize})
    layer:addChild(shadowLayer)
    view:addChild(layer)

    local title = display.newButton(layerSize.width / 2, layerSize.height-2, {animate = false, enable = false, n = RES_DIR.TITLE_FIRST, ap = display.CENTER_TOP})
    display.commonLabelParams(title, fontWithColor(3, {text = __('宝宝吃货节'), offset = cc.p(0,-2)}))
    layer:addChild(title)
    
    local countDownBgSize = cc.size(layerSize.width - 60, 30)
    local countDownBg = display.newImageView(RES_DIR.COUNTDOWN_TRAILER, title:getPositionX(), layerSize.height - 50, {scale9 = true, size = countDownBgSize, ap = display.CENTER_TOP})
    countDownBg:setVisible(false)
    layer:addChild(countDownBg)

	local countDownLabel = display.newRichLabel(countDownBgSize.width / 2, countDownBgSize.height / 2,
        {ap = display.CENTER, c = {
            {text = __('离开始还有: '), fontSize = 22, color = '#5b3c25'},
            {text = '11', fontSize = 22, color = '#ffffff'},
            {text = __('小时'), fontSize = 22, color = '#5b3c25'},
            {text = '11', fontSize = 22, color = '#ffffff'},
            {text = __('分钟'), fontSize = 22, color = '#5b3c25'},
        }
    })
    countDownLabel:reloadData()
    countDownBg:addChild(countDownLabel)

    local text = '神说要有光离开始还有神说要有光离开始还有神说要有光离开始还有神说要有光离开始还有神说要有光离开始还有神说要有光离开始还有'
    local descLabel = display.newLabel(36, countDownBg:getPositionY() - countDownBgSize.height - 5, fontWithColor(6, {ap = display.LEFT_TOP, w = layerSize.width - 72, text = text}))
    local descLabelSize = display.getLabelContentSize(descLabel)
    layer:addChild(descLabel)
    
    -- local rewards = {
    --      {["goodsId"]=200031, ["num"]=11},
    --      {["goodsId"]=900002, ["num"]=200000},
    --      {["goodsId"]=180001, ["num"]=50}
    -- }
    local goodBg      = display.newImageView(RES_DIR.GOOD_BG, 0, 0, {ap = display.LEFT_BOTTOM})
    local goodBgSize  = goodBg:getContentSize()
    local goodBgLayer = display.newLayer(title:getPositionX(), descLabel:getPositionY() - descLabelSize.height - 10, {ap = display.CENTER_TOP, size = goodBgSize})
    goodBgLayer:addChild(goodBg)
    layer:addChild(goodBgLayer)

    -- local params = {parent = goodBgLayer, midPointX = goodBgSize.width * 0.5, midPointY = goodBgSize.height * 0.5, maxCol= 4, scale = 0.8, rewards = rewards, hideCustomizeLabel = true}
    -- CommonUtils.createPropList(params)

    -- 菜品要求 layer
    local requirementLayerPosY = goodBgLayer:getPositionY() - goodBgSize.height - 5
    local requirementLayerSize = cc.size(layerSize.width - 60, requirementLayerPosY - 12)
    local requirementLayer = display.newLayer(0, 0, {ap = display.CENTER_TOP, size = requirementLayerSize})
    display.commonUIParams(requirementLayer, {po = cc.p(title:getPositionX(), requirementLayerPosY)})
    layer:addChild(requirementLayer)

    local titleSecond = display.newButton(0, 0, {animate = false, enable = false, n = RES_DIR.TITLE_SECOND, ap = display.CENTER_TOP , scale9 = true })
    local titleSecondSize = titleSecond:getContentSize()
    display.commonUIParams(titleSecond, {po = cc.p(requirementLayerSize.width / 2, requirementLayerSize.height-2)})
    display.commonLabelParams(titleSecond, fontWithColor(4, {text = __('菜品要求'), paddingW = 30 ,  offset = cc.p(0,-2)}))
    requirementLayer:addChild(titleSecond)

    local listSize = cc.size(requirementLayerSize.width, requirementLayerSize.height - titleSecondSize.height - 5)
    local listLayer = display.newLayer(0, 0, {ap = display.CENTER_TOP, size = listSize})
    display.commonUIParams(listLayer, {po = cc.p(titleSecond:getPositionX(), listSize.height)})
    requirementLayer:addChild(listLayer)

    local listBg = display.newImageView(RES_DIR.LSIT_BG, 0, 0, {ap = display.LEFT_BOTTOM, size = listSize, scale9 = true})
    listLayer:addChild(listBg)

    local listCellSize = cc.size(listSize.width / 2, 186)

    local gridView = CGridView:create(listSize)
    gridView:setSizeOfCell(listCellSize)
    gridView:setColumns(2)
    -- gridView:setAutoRelocate(true)
    -- gridView:setBounceable(false)
    -- gridView:setBackgroundColor(cc.c3b(100,100,200))
    listLayer:addChild(gridView)
    gridView:setAnchorPoint(display.CENTER_TOP)
    gridView:setPosition(cc.p(listSize.width / 2, listSize.height))

    -- local img =  _res('ui/iceroom/common_bg_list.png') or RES_DIR.LSIT_CELL_BG
    
    return {
        view                 = view,
        touchLayer           = touchLayer,
        layer                = layer,
        title                = title,
        countDownBg          = countDownBg,
        countDownLabel       = countDownLabel,
        descLabel            = descLabel,
        goodBgLayer          = goodBgLayer,
        titleSecond          = titleSecond,
        requirementLayer     = requirementLayer,
        listLayer            = listLayer,
        listBg               = listBg,
        gridView             = gridView,

        titleSecondSize      = titleSecondSize,
        goodBgSize           = goodBgSize,
        layerSize            = layerSize,
    }
end

CreateCell_ = function ()
    local cell = CGridViewCell:new()
    -- cell:setBackgroundColor(cc.c3b(100,100,200))

    local bg = display.newImageView(RES_DIR.LSIT_CELL_BG, 0, 0, {ap = display.LEFT_BOTTOM})
    bg:setVisible(false)
    local bgSize = bg:getContentSize()
    local layer = display.newLayer(341 / 2, bgSize.height / 2, {size = bgSize, ap = display.CENTER})
    layer:addChild(bg)
    cell:addChild(layer)

    local unlockBg = display.newImageView(RES_DIR.LSIT_CELL_UNLOCK_BG, 0, 0, {ap = display.LEFT_BOTTOM, scale9 = true, size = bgSize})
    unlockBg:setVisible(false)
    layer:addChild(unlockBg)
    
    local nameLabel = display.newLabel(10, bgSize.height - 22, {fontSize = 22, color = '#ba5c5c', ap = display.LEFT_CENTER})
    layer:addChild(nameLabel)

    local qualityLayerSize = cc.size(bgSize.width / 2, 40)
    local qualityLayer = display.newLayer(bgSize.width, bgSize.height, {ap = display.RIGHT_TOP, size = cc.size(bgSize.width / 2, 40)})
    layer:addChild(qualityLayer)

    local qualityImg = display.newImageView(_res('ui/home/kitchen/cooking_grade_ico_5.png'), qualityLayerSize.width + 4, qualityLayerSize.height / 2, {ap = display.RIGHT_CENTER})
    local qualityImgSize = qualityImg:getContentSize()
    qualityLayer:addChild(qualityImg)
    
    local qualityLabel = display.newLabel(qualityImg:getPositionX() - 45, 2, {fontSize = 22, color = '#a19b85', text = __('评级'), ap = display.RIGHT_BOTTOM})
    qualityLayer:addChild(qualityLabel)
    
    local lineImg = display.newImageView(RES_DIR.LINE, bgSize.width / 2, 143, {ap = display.CENTER})
    layer:addChild(lineImg)

    -- LSIT_CELL_GOOD_BG
    local goodBg = display.newImageView(RES_DIR.LSIT_CELL_GOOD_BG, 0, 0, {ap = display.CENTER})
    local goodBgSize = goodBg:getContentSize()
    local goodBgLayer = display.newLayer(70, 75, {size = goodBgSize, ap = display.CENTER})
    display.commonUIParams(goodBg, {po = cc.p(goodBgSize.width / 2, goodBgSize.height / 2)})
    goodBgLayer:addChild(goodBg)
    layer:addChild(goodBgLayer)
    
    local goodNode = require('common.GoodNode').new({id = 150061, showAmount = false})
    goodNode.fragmentImg:setVisible(false)
    goodNode.bg:setVisible(false)
    display.commonUIParams(goodNode,{po = cc.p(goodBgSize.width / 2, goodBgSize.height / 2), ap = display.CENTER})
    goodBgLayer:addChild(goodNode)
    
    local attrLayerSize = cc.size(bgSize.width * 0.53, 142)
    local attrLayer = display.newLayer(bgSize.width * 0.43, 142, {ap = display.LEFT_TOP, size = attrLayerSize})
    attrLayer:setVisible(false)
    layer:addChild(attrLayer)

    -- local config = {'味道','口感','香味','外观'}
    -- local attrNumberLabels = {}
    -- local attrBgSize = cc.size(attrLayerSize.width, 31)
    -- for i,v in ipairs(config) do
    --     local attrBg = display.newImageView(RES_DIR.ATTR_BG, 0, attrLayerSize.height - 5 - 34 * (i - 1), {scale9 = true, size = attrBgSize, ap = display.LEFT_TOP})
    --     attrLayer:addChild(attrBg)
        
    --     local attrLabel = display.newLabel(5, attrBg:getPositionY() - attrBgSize.height / 2, fontWithColor(6, {text = v, ap = display.LEFT_CENTER}))
    --     attrLayer:addChild(attrLabel)

    --     local attrNumberLabel = display.newLabel(attrBgSize.width - 5, attrBg:getPositionY() - attrBgSize.height / 2, fontWithColor(6, {text = 5, ap = display.RIGHT_CENTER, color = '#c52d02'}))
    --     attrLayer:addChild(attrNumberLabel)
    --     table.insert(attrNumberLabels, attrNumberLabel)
    -- end

    local cuisineTipLabel = display.newLabel(bgSize.width / 2, 70, fontWithColor(6, {text = __('暂未获得该菜谱'), ap = display.LEFT_CENTER, w = 22 * 5}))
    cuisineTipLabel:setVisible(false)
    layer:addChild(cuisineTipLabel)

    cell.viewData = {
        bg                  = bg,
        unlockBg            = unlockBg,
        attrLayer           = attrLayer,
        nameLabel           = nameLabel,
        qualityLayer        = qualityLayer,
        qualityImg          = qualityImg,
        qualityLabel        = qualityLabel,
        goodNode            = goodNode,
        -- attrNumberLabels    = attrNumberLabels,
        cuisineTipLabel     = cuisineTipLabel,
    }
    return cell
end

-- @params attr {attrName = attrName, num = attrNum, color = color}
CreateAttr_ = function (attrLayer, i, attr)
    local attrLayerSize = attrLayer:getContentSize()
    local attrBgSize = cc.size(attrLayerSize.width, 31)

    local attrBg = display.newImageView(RES_DIR.ATTR_BG, 0, attrLayerSize.height - 5 - 34 * (i - 1), {scale9 = true, size = attrBgSize, ap = display.LEFT_TOP})
    attrLayer:addChild(attrBg)
    
    local attrLabel = display.newLabel(5, attrBg:getPositionY() - attrBgSize.height / 2, fontWithColor(6, {text = tostring(attr.attrName), ap = display.LEFT_CENTER}))
    attrLayer:addChild(attrLabel)

    local attrNumberLabel = display.newLabel(attrBgSize.width - 5, attrBg:getPositionY() - attrBgSize.height / 2, fontWithColor(6, {text = tostring(attr.num), ap = display.RIGHT_CENTER, color = attr.color}))
    attrLayer:addChild(attrNumberLabel)
end

return LobbyFestivalActivityView