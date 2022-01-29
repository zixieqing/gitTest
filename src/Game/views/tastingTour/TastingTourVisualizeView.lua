--[[
 * descpt : 品鉴之旅 小本本 界面
]]
local VIEW_SIZE = display.size
local TastingTourVisualizeView = class('TastingTourVisualizeView', function ()
	local node = CLayout:create(display.size)
	node.name = 'Game.views.tastingTour.TastingTourVisualizeView'
	node:enableNodeEvents()
	return node
end)
---@type TastingTourManager
local tastingTourMgr = AppFacade.GetInstance():GetManager("TastingTourManager")
local questConfig = tastingTourMgr:GetConfigDataByName(tastingTourMgr:GetConfigParse().TYPE.QUEST)
local menuConfig = tastingTourMgr:GetConfigDataByName(tastingTourMgr:GetConfigParse().TYPE.MENU_TAG)
local CreateView = nil
local CreateCell = nil

local uiMgr    = AppFacade.GetInstance():GetManager('UIManager')

local RES_DIR = {
    BG                     = _res('ui/common/common_bg_5.png'),
    TITLE                  = _res('ui/common/common_bg_title_1.png'),
    CELL_BG                = _res("ui/tastingTour/visualize/fish_travel_mark_bg.png"),
    CELL_TITLE             = _res('ui/common/common_title_5.png')
}


function TastingTourVisualizeView:ctor( ... )
    self.args = unpack({...})
    self.questId = self.args.questId
    self.isClose = false
    self.attrNameTable = {
        __('味道') ,
        __('口感') ,
        __('香味') ,
        __('外观')
    }
    self:initialUI()
end

function TastingTourVisualizeView:initialUI()
    xTry(function ( )
        self.viewData_ = CreateView()
        self:addChild(self.viewData_.view)
        
        self:initData()
        self:initView()
	end, __G__TRACKBACK__)
end

function TastingTourVisualizeView:initData()
    local questData = tastingTourMgr:GetQuestOneDataByQuestId(self.questId)
    local secretFoods = questData.secretFoods or {}
    self.secretFoods = secretFoods
    self.foodsAttr = questConfig[tostring(self.questId)].foodsAttr
end

function TastingTourVisualizeView:initView()
    local viewData = self:getViewData()
    local shallowLayer = viewData.shallowLayer
    display.commonUIParams(shallowLayer, {cb = handler(self, self.onClickShallowAction)})

    local contentLayer = viewData.contentLayer
    local contentLayerSize = contentLayer:getContentSize()
    local len = #self.secretFoods
    local maxCol = 4
    local col = (len > maxCol) and maxCol or len
    for index = 1, len do
        local goodsData = CommonUtils.GetConfig('goods','goods',self.secretFoods[index]) or {}
        local menuOneConfig = menuConfig[tostring(self.foodsAttr[index].foodTagMainType)] or {}

        local cell = CreateCell()
        self:updateCell(cell, index)

        local pos = CommonUtils.getGoodPos({
            index = index, 
            goodNodeSize = cell:getContentSize(), 
            midPointX =  contentLayerSize.width / 2,
            midPointY = contentLayerSize.height / 2,
            col = col,
            maxCol = maxCol,
            goodGap = 15
        })
        display.commonUIParams(cell, {po = pos, ap = display.CENTER})
        contentLayer:addChild(cell)
    end
end

function TastingTourVisualizeView:updateCell(cell, index)
    print("index = " , index)
    local viewData       = cell.viewData
    local title          = viewData.title
    local goodTypeLabel  = viewData.goodTypeLabel
    local goodNode       = viewData.goodNode
    local nameLabel      = viewData.nameLabel
    local attrNumLabel   = viewData.attrNumLabel
    local attrLabel      = viewData.attrLabel
    local attr = self.foodsAttr[index].maxFoodAttrId
    local goodsData = CommonUtils.GetConfig('goods','goods',self.secretFoods[index]) or {}
    local menuOneConfig = menuConfig[tostring(self.foodsAttr[index].foodTagMainType)] or {}
    display.commonLabelParams(title, {text = string.format(__('菜位：%s' ) , index)})
    display.commonLabelParams(attrLabel , {text  = self.attrNameTable[checkint(attr)]})
    display.commonLabelParams(attrNumLabel , {text  = checkint(self.foodsAttr[index].foodAttrMax) })
    display.commonLabelParams(nameLabel , {text  = goodsData.name })
    display.commonLabelParams(goodTypeLabel , {text = menuOneConfig.name or ""})
    goodNode:RefreshSelf({goodsId = self.secretFoods[index] })
end

function TastingTourVisualizeView:onClickShallowAction(sender)
    if not  self.isClose then
        self.isClose = true
        uiMgr:GetCurrentScene():RemoveDialog(self)
    end
end

function TastingTourVisualizeView:onEnter()

end

CreateView = function ()
    local view = display.newLayer()
    local size = view:getContentSize()
    
    local shallowLayer = display.newLayer(0, 0, {color = cc.c4b(0, 0, 0, 150), enable = true})
    view:addChild(shallowLayer)

    local bgLayer = display.newLayer(size.width / 2, size.height / 2, {ap = display.CENTER, bg = RES_DIR.BG})
	local bgSize = bgLayer:getContentSize()
    view:addChild(bgLayer)

    local touchLayer = display.newLayer(bgSize.width, bgSize.height / 2, {color = cc.c4b(0, 0, 0, 0), enable = true})
    bgLayer:addChild(touchLayer)

    local titleBg = display.newButton(0, 0, {n = RES_DIR.TITLE, animation = false})
    display.commonUIParams(titleBg, {po = cc.p(bgSize.width * 0.5, bgSize.height - titleBg:getContentSize().height * 0.5)})
    display.commonLabelParams(titleBg,
        {text = __('美食家的愿望'),
        fontSize = fontWithColor('3').fontSize, color = fontWithColor('3').color,
        offset = cc.p(0, -2)})
    bgLayer:addChild(titleBg)
    
    local tipLabel = display.newLabel(bgSize.width / 2, bgSize.height - 100, {ap = display.CENTER, fontSize = 20, color = '#a88c76', text = __('Tips:美食家期望的菜品')})
    bgLayer:addChild(tipLabel)
    
    local contentLayerSize = cc.size(bgSize.width - 50, bgSize.height - 150)
    local contentLayer = display.newLayer(bgSize.width / 2, bgSize.height - 140, {size = contentLayerSize, ap = display.CENTER_TOP})
    bgLayer:addChild(contentLayer)

    return {
        view              = view,
        shallowLayer      = shallowLayer,
        contentLayer      = contentLayer
    }
end

CreateCell = function (data)
    local size = cc.size(270, 480)
    local cell = display.newLayer()
    cell:setContentSize(size)

    local title = display.newButton(size.width / 2, size.height, {ap = display.CENTER_TOP, n = RES_DIR.CELL_TITLE})
    display.commonLabelParams(title, {fontSize = 24, color = '#a88c76'})
    cell:addChild(title)
    
    local bgLayer = display.newLayer(size.width / 2, size.height, {ap = display.CENTER_TOP, bg = RES_DIR.CELL_BG})
    cell:addChild(bgLayer)
    
    local bgLayerSize = bgLayer:getContentSize()
    local goodTypeLabel = display.newLabel(bgLayerSize.width / 2 + 8, bgLayerSize.height - 98, {ap = display.CENTER, fontSize = 26, color = '#FF6700'})
    bgLayer:addChild(goodTypeLabel)

    local goodNode = require('common.GoodNode').new({id = 150061, showAmount = false})
    display.commonUIParams(goodNode,{po = cc.p(goodTypeLabel:getPositionX(), goodTypeLabel:getPositionY() - 65), ap = display.CENTER})
    goodNode.fragmentImg:setVisible(false)
    goodNode.bg:setVisible(false)
    goodNode:setScale(1.5)
    bgLayer:addChild(goodNode)

    local nameLabel = display.newLabel(bgLayerSize.width / 2 + 8, bgLayerSize.height - 240, {ap = display.CENTER, fontSize = 24, color = '#e2a4ac'})
    bgLayer:addChild(nameLabel)
    
    local attrRequirementLabel = display.newLabel(bgLayerSize.width / 2 + 8, bgLayerSize.height - 305, fontWithColor(5, {text = __('属性要求')}))
    bgLayer:addChild(attrRequirementLabel)

    local attrLabel = display.newLabel(94, bgLayerSize.height - 338, {ap = display.LEFT_CENTER, fontSize = 20, color = '#e2a4ac', text = '味道'})
    bgLayer:addChild(attrLabel)

    local attrNumLabel = display.newLabel(bgLayerSize.width / 2 + 40, bgLayerSize.height - 338, {ap = display.CENTER, fontSize = 20, color = '#ffffff', text = '110', font = TTF_GAME_FONT, ttf = true, outline = '#000000', outlineSize = 1})
    bgLayer:addChild(attrNumLabel)

    cell.viewData = {
        title          = title,
        goodTypeLabel  = goodTypeLabel,
        goodNode       = goodNode,
        nameLabel      = nameLabel,
        attrNumLabel   = attrNumLabel,
        attrLabel      = attrLabel
    }
    return cell
end

function TastingTourVisualizeView:getViewData()
	return self.viewData_
end

return TastingTourVisualizeView
