--[[
 * author : kaishiqi
 * descpt : 爬塔 - 单元契约界面
]]
local TowerQuestContractView = class('TowerQuestContractView', function ()
    return display.newLayer(0, 0, {name = 'Game.views.TowerQuestContractView'})
end)

local RES_DICT = {
    BG_IMG         = 'ui/tower/team/tower_prepare_bg_contract.png',
    LABER_BAR      = 'ui/tower/team/tower_prepare_label_chesttitle.png',
    PAPER_IMG      = 'ui/tower/team/tower_prepare_bg_contractpaper.png',
    CHEST_LV_BAR   = 'ui/tower/team/tower_prepare_bg_chest.png',
    CHEST_LV_S     = 'ui/tower/team/tower_ico_mark_active.png',
    CHEST_LV_D     = 'ui/tower/team/tower_ico_mark_unactive.png',
    PAPER_LINE_S   = 'ui/tower/team/tower_ico_line1.png',
    PAPER_LINE_B   = 'ui/tower/team/tower_ico_line2.png',
    TITLE_BAR      = 'ui/tower/ready/tower_label_title.png',
    PROPS_FRAME    = 'ui/common/common_bg_goods.png',
    CONTRACT_ICO_D = 'ui/tower/team/tower_ico_mark_empty.png',
    CONTRACT_ICO_S = 'ui/tower/team/tower_ico_mark_selected.png',
    CONTRACT_BG_S  = 'ui/tower/team/tower_prepare_bg_wordlight.png',
    GOODS_FRAME    = 'ui/common/common_frame_goods_1.png',
    GOODS_LINE     = 'ui/tower/team/tower_ico_line3.png',
}

local CreateView         = nil
local CreateContractCell = nil


function TowerQuestContractView:ctor(args)
    xTry(function()
        self.viewData_ = CreateView()
        self:addChild(self.viewData_.view)
        self:setContentSize(self.viewData_.view:getContentSize())
    end, __G__TRACKBACK__)
end


CreateView = function()
    local view = display.newLayer(0, 0, {bg = _res(RES_DICT.BG_IMG)})
    local size = view:getContentSize()

    -- paper image
    local paperImageY = size.height - 15
    view:addChild(display.newImageView(_res(RES_DICT.PAPER_IMG), size.width/2, paperImageY, {ap = display.CENTER_TOP}))
    view:addChild(display.newImageView(_res(RES_DICT.PAPER_LINE_B), size.width/2, paperImageY - 60))
    view:addChild(display.newImageView(_res(RES_DICT.PAPER_LINE_B), size.width/2, paperImageY - 370, {scaleY = -1}))

    -- title bar
    local titleBar = display.newButton(size.width/2, size.height - 34, {n = _res(RES_DICT.TITLE_BAR), enable = false , scale9 = true })
    display.commonLabelParams(titleBar, fontWithColor(1, {text = __('霸者契约'), fontSize = 24, color = '#745050' ,paddingW = 30}))
    view:addChild(titleBar)

    -- contract listview
    -- local contractList = CListView:create(cc.size(300, 300))
    -- contractList:setPosition(size.width/2, size.height/2 + 110)
    -- contractList:setDirection(eScrollViewDirectionVertical)
    -- contractList:setAnchorPoint(display.CENTER)
    -- view:addChild(contractList)
    local contractLayer = display.newLayer(size.width/2, paperImageY - 65, {size = cc.size(300, 300), ap = display.CENTER_TOP})
    view:addChild(contractLayer)

    -------------------------------------------------
    -- chest nameBar
    local chestNameBar = display.newButton(size.width/2, 225, {n = _res(RES_DICT.LABER_BAR), enable = false})
    display.commonLabelParams(chestNameBar, fontWithColor(14, {ap = display.LEFT_CENTER, offset = cc.p(-190, 0)}))
    view:addChild(chestNameBar)

    -- chest image layer
    local chestImageLayer = display.newLayer(size.width - 115, 270, {ap = display.CENTER})
    view:addChild(chestImageLayer)

    -- chest level bar
    local chestLevelHideList = {}
    local chestLevelShowList = {}
    view:addChild(display.newImageView(_res(RES_DICT.CHEST_LV_BAR), size.width - 25, chestImageLayer:getPositionY() - 75, {ap = display.RIGHT_BOTTOM}))

    for i=1,3 do
        local chestLevelIconPos  = cc.p(size.width - 136 + (i-1)*42, chestImageLayer:getPositionY() - 50)
        local chestLevelHideIcon = display.newImageView(_res(RES_DICT.CHEST_LV_D), chestLevelIconPos.x, chestLevelIconPos.y)
        local chestLevelShowIcon = display.newImageView(_res(RES_DICT.CHEST_LV_S), chestLevelIconPos.x, chestLevelIconPos.y)
        view:addChild(chestLevelHideIcon)
        view:addChild(chestLevelShowIcon)
        chestLevelHideList[i] = chestLevelHideIcon
        chestLevelShowList[i] = chestLevelShowIcon
    end

    -- chest effect spine
    local chestEffectPath  = 'ui/tower/team/spine/shengji'
    if not SpineCache(SpineCacheName.TOWER):hasSpineCacheData(chestEffectPath) then
        SpineCache(SpineCacheName.TOWER):addCacheData(chestEffectPath, chestEffectPath, 1)
    end
    local chestEffectSpine = SpineCache(SpineCacheName.TOWER):createWithName(chestEffectPath)
    chestEffectSpine:setPosition(cc.p(chestImageLayer:getPositionX(), chestImageLayer:getPositionY()))
    view:addChild(chestEffectSpine)

    -------------------------------------------------
    -- props frame
    local propsFrame = display.newImageView(_res(RES_DICT.PROPS_FRAME), size.width/2, 130, {scale9 = true, size = cc.size(size.width - 60, 140)})
    view:addChild(propsFrame)

    -- props listview
    local propsList = CListView:create(cc.size(propsFrame:getContentSize().width - 4, propsFrame:getContentSize().height - 35))
    propsList:setPosition(propsFrame:getPositionX(), propsFrame:getPositionY() - 18)
    propsList:setDirection(eScrollViewDirectionHorizontal)
    propsList:setAnchorPoint(display.CENTER)
    view:addChild(propsList)

    local tipsText = __('将会掉落以下物品：')
    propsFrame:addChild(display.newImageView(_res(RES_DICT.GOODS_LINE), propsFrame:getContentSize().width/2, propsFrame:getContentSize().height - 36))
    propsFrame:addChild(display.newLabel(12, propsFrame:getContentSize().height - 6, fontWithColor(5, {ap = display.LEFT_TOP, text = tipsText ,reqW = 390 })))

    return {
        view               = view,
        -- contractList       = contractList,
        contractLayer      = contractLayer,
        chestNameBar       = chestNameBar,
        chestImageLayer    = chestImageLayer,
        chestLevelHideList = chestLevelHideList,
        chestLevelShowList = chestLevelShowList,
        chestEffectSpine   = chestEffectSpine,
        propsList          = propsList,
    }
end


CreateContractCell = function(size)
    local view = display.newLayer(0, 0, {size = size, color = cc.r4b(0), enable = true})

    local footerLine = display.newImageView(_res(RES_DICT.PAPER_LINE_S), size.width/2, 0)
    view:addChild(footerLine)

    local selectBgImg = display.newImageView(_res(RES_DICT.CONTRACT_BG_S), size.width/2, size.height/2)
    view:addChild(selectBgImg)

    local textNormolLabel = display.newLabel(80, size.height/2, fontWithColor(1, {ap = display.LEFT_CENTER, w = size.width - 95, fontSize = 22, color = '#bc816b'}))
    local textSelectLabel = display.newLabel(80, size.height/2, fontWithColor(19, {ap = display.LEFT_CENTER, w = size.width - 95, fontSize = 22, color = '#f4ad6d', outline = '#646060', outlineSize = 1.5}))
    view:addChild(textNormolLabel)
    view:addChild(textSelectLabel)

    local normolIcon = display.newImageView(_res(RES_DICT.CONTRACT_ICO_D), 65+10, size.height/2, {ap = display.RIGHT_CENTER})
    local selectIcon = display.newImageView(_res(RES_DICT.CONTRACT_ICO_S), 70+10, size.height/2, {ap = display.RIGHT_CENTER})
    view:addChild(normolIcon)
    view:addChild(selectIcon)

    local checkboxPath  = 'ui/tower/team/spine/skeleton'
    if not SpineCache(SpineCacheName.TOWER):hasSpineCacheData(checkboxPath) then
        SpineCache(SpineCacheName.TOWER):addCacheData(checkboxPath, checkboxPath, 1)
    end
    local checkboxSpine = SpineCache(SpineCacheName.TOWER):createWithName(checkboxPath)
    checkboxSpine:setPosition(cc.p(textNormolLabel:getPositionX() - 40, textNormolLabel:getPositionY() + 5))
    view:addChild(checkboxSpine)

    return {
        view            = view,
        footerLine      = footerLine,
        selectBgImg     = selectBgImg,
        normolIcon      = normolIcon,
        selectIcon      = selectIcon,
        textNormolLabel = textNormolLabel,
        textSelectLabel = textSelectLabel,
        checkboxSpine   = checkboxSpine,
    }
end


function TowerQuestContractView:getViewData()
    return self.viewData_
end


function TowerQuestContractView:createContractCell()
    -- local contractListSize = self.viewData_.contractList:getContentSize()
    local contractListSize = self.viewData_.contractLayer:getContentSize()
    local contractCellSize = cc.size(contractListSize.width, 100)
    return CreateContractCell(contractCellSize)
end


function TowerQuestContractView:createEmptyGoodsCell()
    return display.newImageView(_res(RES_DICT.GOODS_FRAME))
end


return TowerQuestContractView