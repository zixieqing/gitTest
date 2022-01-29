--[[
 * author : kaishiqi
 * descpt : 新游戏商店视图
]]
local GoodPurchaseNode = require('common.GoodPurchaseNode')
local GameStoresView   = class('GameStoresView', function()
    return display.newLayer(0, 0, {name = 'Game.views.stores.GameStoresView'})
end)

local RES_DICT = {
    COM_TITLE_BAR           = _res('ui/common/common_title.png'),
    COM_TIPS_ICON           = _res('ui/common/common_btn_tips.png'),
    COM_BACK_BTN            = _res('ui/common/common_btn_back.png'),
    MONEY_INFO_BAR          = _res('ui/home/nmain/main_bg_money.png'),
    BACK_FRAME_IMG          = _res('ui/stores/base/shop_bg_add.png'),
    TYPE_CELL_FRAME_SELECT  = _res('ui/stores/base/shop_btn_tab_select.png'),
    TYPE_CELL_FRAME_DEFAULT = _res('ui/stores/base/shop_btn_tab_default.png'),
    TYPE_CELL_FRAME_SEARCH  = _res('ui/stores/base/shop_btn_tab_search.png'),
    GOODS_SEARCH_ICON       = _res('ui/common/raid_boss_btn_search.png'),
    COMMON_ALPHA_IMG        = _res('ui/common/story_tranparent_bg.png'),
    TYPE_CELL_LOADING_SPN   = _spn('ui/common/activity_ico_load'),
}

local TYPE_CELL_DEFINES = {
    [GAME_STORE_TYPE.DIAMOND]   = {imgName = 'shop_btn_tab_default_img_1', name = __('幻晶石')},
    [GAME_STORE_TYPE.MONTH]     = {imgName = 'shop_btn_tab_default_img_2', name = __('月卡')},
    [GAME_STORE_TYPE.GIFTS]     = {imgName = 'shop_btn_tab_default_img_3', name = __('礼包')},
    [GAME_STORE_TYPE.PROPS]     = {imgName = 'shop_btn_tab_default_img_4', name = __('道具')},
    [GAME_STORE_TYPE.CARD_SKIN] = {imgName = 'shop_btn_tab_default_img_5', name = __('皮肤')},
    [GAME_STORE_TYPE.GROCERY]   = {imgName = 'shop_btn_tab_default_img_6', name = __('杂货铺')},
}

local CreateView     = nil
local CreateTypeCell = nil


function GameStoresView:ctor(args)
    -- create view
    self.viewData_ = CreateView()
    self:addChild(self.viewData_.view)

    -- init views
    local viewData = self:getViewData()
    viewData.topLayer:setPosition(viewData.topLayerHidePos)
    viewData.titleBtn:setPosition(viewData.titleBtnHidePos)
    viewData.centerLayer:setPosition(viewData.centerLayerHidePos)
    self:reloadMoneyBar()
end


CreateView = function()
    local view = display.newLayer()
    local size = view:getContentSize()

    -- block layer
    view:addChild(display.newLayer(0, 0, {color = cc.c4b(0,0,0,150), enable = true}))

    
    ------------------------------------------------- [center]
    -- center layer
    local centerLayer = display.newLayer()
    view:addChild(centerLayer)

    -- center bg
    local centerPos = cc.p(size.width/2 + 18, size.height/2 - 40)
    centerLayer:addChild(display.newImageView(RES_DICT.BACK_FRAME_IMG, centerPos.x, centerPos.y))

    -- store layer
    local storeSize  = cc.size(1080, 644)
    local storeLayer = display.newLayer(centerPos.x + 91, centerPos.y - 3, {size = storeSize, ap = display.CENTER, color1 = cc.r4b(150)})
    centerLayer:addChild(storeLayer)
    
    -- type pageView
    local typeListSize = cc.size(240, storeSize.height)
    local typeListView = CTableView:create(typeListSize)
    -- typeListView:setBackgroundColor(cc.r4b(150))
    typeListView:setSizeOfCell(cc.size(typeListSize.width, 114))
    typeListView:setDirection(eScrollViewDirectionVertical)
    typeListView:setAnchorPoint(display.RIGHT_CENTER)
    typeListView:setPositionX(storeLayer:getPositionX() - storeSize.width/2 - 3)
    typeListView:setPositionY(centerPos.y - 5)
    centerLayer:addChild(typeListView)


    ------------------------------------------------- [top]
    -- top layer
    local topLayer = display.newLayer()
    view:addChild(topLayer)

    -- back button
    local backBtn = display.newButton(display.SAFE_L + 75, size.height - 52, {n = RES_DICT.COM_BACK_BTN})
    topLayer:addChild(backBtn)

    -- title button
    local titleBtn = display.newButton(display.SAFE_L + 120, size.height, {n = RES_DICT.COM_TITLE_BAR, ap = display.LEFT_TOP})
    display.commonLabelParams(titleBtn, fontWithColor(1, {text = __('商城'), offset = cc.p(0,-10)}))
    topLayer:addChild(titleBtn)

    titleBtn:setEnabled(false)  -- 如果要下面的问号，就删除这句
    -- local titleSize = titleBtn:getContentSize()
    -- titleBtn:addChild(display.newImageView(RES_DICT.COM_TIPS_ICON, titleSize.width - 50, titleSize.height/2 - 10))

    -- money barBg
    local moneyBarBg = display.newImageView(_res(RES_DICT.MONEY_INFO_BAR), display.width, display.height, {ap = display.RIGHT_TOP, scale9 = true, size = cc.size(1, 54)})
    topLayer:addChild(moneyBarBg)

    -- money layer
    local moneyLayer = display.newLayer()
    topLayer:addChild(moneyLayer)

    return {
        view               = view,
        topLayer           = topLayer,
        topLayerHidePos    = cc.p(topLayer:getPositionX(), 100),
        topLayerShowPos    = cc.p(topLayer:getPosition()),
        titleBtn           = titleBtn,
        titleBtnHidePos    = cc.p(titleBtn:getPositionX(), titleBtn:getPositionY() + 190),
        titleBtnShowPos    = cc.p(titleBtn:getPosition()),
        backBtn            = backBtn,
        moneyBarBg         = moneyBarBg,
        moneyLayer         = moneyLayer,
        centerLayer        = centerLayer,
        centerLayerHidePos = cc.p(centerLayer:getPositionX(), -display.height),
        centerLayerShowPos = cc.p(centerLayer:getPosition()),
        storeLayer         = storeLayer,
        typeListView       = typeListView,
    }
end


CreateTypeCell = function(size)
    local view = CTableViewCell:new()
    view:setContentSize(size)
    
    -- block layer
    local centerPos  = cc.p(size.width/2, size.height/2)
    view:addChild(display.newLayer(0, 0, {size = size, color = cc.r4b(0), enable = true}))
    
    -- loading spine
    local loadingSpn = sp.SkeletonAnimation:create(RES_DICT.TYPE_CELL_LOADING_SPN.json, RES_DICT.TYPE_CELL_LOADING_SPN.atlas, 1)
    loadingSpn:setPosition(cc.p(centerPos.x, centerPos.y + 15))
    loadingSpn:setAnimation(0, 'idle', true)
    view:addChild(loadingSpn)

    -- image webSprite
    local imageSize    = cc.size(200, 100)
    local imgWebSprite = require('root.WebSprite').new({hpath = RES_DICT.COMMON_ALPHA_IMG, tsize = imageSize})
    imgWebSprite:setAnchorPoint(display.CENTER)
    imgWebSprite:setPosition(centerPos)
    view:addChild(imgWebSprite)

    -- image layer
    local imageLayer = display.newLayer(centerPos.x, centerPos.y, {ap = display.LEFT_BOTTOM, size = imageSize})
    view:addChild(imageLayer)

    -- normal frame
    local frameNormal = display.newImageView(RES_DICT.TYPE_CELL_FRAME_DEFAULT, centerPos.x, centerPos.y)
    view:addChild(frameNormal)

    -- normal frame
    local frameSearch = display.newImageView(RES_DICT.TYPE_CELL_FRAME_SEARCH, centerPos.x, centerPos.y)
    view:addChild(frameSearch)

    -- name label
    local typeNameLabel = display.newLabel(size.width/2, 24, fontWithColor(20, {fontSize = 22, outline = '#763805'}))
    view:addChild(typeNameLabel)

    -------------------------------------------------
    -- props info
    local propsInfoLayer = display.newLayer()
    view:addChild(propsInfoLayer)

    -- props iconNode
    local propIconNode = require('common.GoodNode').new()
    propIconNode:setPosition(size.width/2, size.height/2)
    propIconNode:setScale(0.8)
    propsInfoLayer:addChild(propIconNode)

    -- search icon
    local searchIcon = display.newImageView(RES_DICT.GOODS_SEARCH_ICON, propIconNode:getPositionX() + 45, propIconNode:getPositionY() - 20)
    propsInfoLayer:addChild(searchIcon)

    
    -- select frame
    local frameSelect = display.newImageView(RES_DICT.TYPE_CELL_FRAME_SELECT, centerPos.x, centerPos.y)
    view:addChild(frameSelect)
    
    -- click hostpot
    local clickHotspot = display.newLayer(0, 0, {size = size, color = cc.r4b(0), enable = true})
    view:addChild(clickHotspot)
    
    return {
        view           = view,
        loadingSpn     = loadingSpn,
        imgWebSprite   = imgWebSprite,
        imageLayer     = imageLayer,
        typeNameLabel  = typeNameLabel,
        frameNormal    = frameNormal,
        frameSearch    = frameSearch,
        propsInfoLayer = propsInfoLayer,
        propIconNode   = propIconNode,
        frameSelect    = frameSelect,
        clickHotspot   = clickHotspot,
    }
end


function GameStoresView:getViewData()
    return self.viewData_
end


function GameStoresView:showUI(endCB)
    local actTime  = 0.2
    local viewData = self:getViewData()
    self:runAction(cc.Sequence:create({
        cc.Spawn:create(
            cc.TargetedAction:create(viewData.topLayer, cc.MoveTo:create(actTime, viewData.topLayerShowPos)),
            cc.TargetedAction:create(viewData.centerLayer, cc.MoveTo:create(actTime, viewData.centerLayerShowPos))
        ),
        cc.CallFunc:create(function()
            if endCB then endCB() end
        end),
        cc.TargetedAction:create(viewData.titleBtn, cc.EaseBounceOut:create(cc.MoveTo:create(1, viewData.titleBtnShowPos)))
    }))
end


function GameStoresView:hideUI(endCB)
    local actTime  = 0.2
    local viewData = self:getViewData()
    self:runAction(cc.Sequence:create({
        cc.Spawn:create(
            cc.TargetedAction:create(viewData.topLayer, cc.MoveTo:create(actTime, viewData.topLayerHidePos)),
            cc.TargetedAction:create(viewData.centerLayer, cc.MoveTo:create(actTime, viewData.centerLayerHidePos))
        ),
        cc.CallFunc:create(function()
            if endCB then endCB() end
        end)
    }))
end


function GameStoresView:reloadMoneyBar(moneyIdMap, isDisableGain)
    -- filter money
    if moneyIdMap then
        moneyIdMap[tostring(GOLD_ID)]         = nil
        moneyIdMap[tostring(DIAMOND_ID)]      = nil
        moneyIdMap[tostring(PAID_DIAMOND_ID)] = nil
        moneyIdMap[tostring(FREE_DIAMOND_ID)] = nil
    end
    
    -- sort money data
    local moneyIdList = {
        {disable = true,  id = SKIN_COUPON_ID},
        {disable = false, id = GOLD_ID},
        {disable = true,  id = DIAMOND_ID},
    }
    for moneyId, _ in pairs(moneyIdMap or {}) do
        table.insert(moneyIdList, {id = checkint(moneyId), disable = false})
    end
    
    -- clean moneyLayer
    local moneyBarBg = self:getViewData().moneyBarBg
    local moneyLayer = self:getViewData().moneyLayer
    moneyLayer:removeAllChildren()
    
    -- update moneyLayer
    local MONEY_NODE_GAP = 16
    local moneyLayerSize = moneyLayer:getContentSize()
    local moneryBarSize  = cc.size(20, moneyBarBg:getContentSize().height)
    for i = #moneyIdList, 1, -1 do
        local moneyId   = checkint(moneyIdList[i].id)
        local isDisable = moneyIdList[i].disable == true
        local moneyNode = GoodPurchaseNode.new({id = moneyId, animate = true, disable = isDisable})
        moneyNode.viewData.touchBg:setTag(checkint(moneyId))
        moneyNode:setPosition(display.SAFE_R - moneryBarSize.width, moneyLayerSize.height - 26)
        moneyNode:setControllable(moneyId ~= DIAMOND_ID)
        moneyNode:setAnchorPoint(display.RIGHT_CENTER)
        moneyNode:setName(moneyId)
        moneyLayer:addChild(moneyNode)

        moneryBarSize.width = moneryBarSize.width + moneyNode:getContentSize().width + MONEY_NODE_GAP
    end

    -- update moneyBarBg
    moneryBarSize.width = 40 + moneryBarSize.width + (display.width - display.SAFE_R)
    moneyBarBg:setContentSize(moneryBarSize)

    -- update money value
    self:updateMoneyBar()
end


function GameStoresView:updateMoneyBar()
    for _, moneyNode in ipairs(self:getViewData().moneyLayer:getChildren()) do
        local moneyId = checkint(moneyNode:getName())
        moneyNode:updataUi(moneyId)
    end
end


-------------------------------------------------
-- type cell

function GameStoresView:createTypeCell(size, storeType)
    return CreateTypeCell(size, storeType)
end


function GameStoresView:updateTypeBaseInfo(cellViewData, storeType)
    if not cellViewData then return end
    
    local cellDefine = TYPE_CELL_DEFINES[checkint(storeType)] or {}
    display.commonLabelParams(cellViewData.typeNameLabel, {text = checkstr(cellDefine.name)})

    local isSearchCell =  storeType == GAME_STORE_TYPE.SEARCH_PROP
    cellViewData.frameNormal:setVisible(not isSearchCell)
    cellViewData.frameSearch:setVisible(isSearchCell)
end


function GameStoresView:updateTypeCellImage(cellViewData, storeType, activityData)
    if not cellViewData then return end
    
    local imgURL = activityData and checkstr(checktable(activityData.sidebarImage)[i18n:getLang()]) or ''
    local hasImg = string.len(imgURL) > 0
    cellViewData.imgWebSprite:setVisible(hasImg)
    cellViewData.imageLayer:setVisible(not hasImg)
    
    if hasImg then
        cellViewData.imgWebSprite:setWebURL(imgURL)
    else
        local cellDefine    = TYPE_CELL_DEFINES[checkint(storeType)] or {}
        local typeImagePath = _res(string.fmt('ui/stores/base/%1.jpg', tostring(cellDefine.imgName)))
        cellViewData.imageLayer:removeAllChildren()
        cellViewData.imageLayer:addChild(display.newImageView(typeImagePath))
    end
end


function GameStoresView:updateTypeCellSelectStatus(cellViewData, isSelected)
    if not cellViewData then return end
    cellViewData.frameSelect:setVisible(isSelected)
end


function GameStoresView:updateTypeCellPropsInfo(cellViewData, goodsId)
    if not cellViewData then return end

    local hasPropsInfo = goodsId ~= nil
    cellViewData.propsInfoLayer:setVisible(hasPropsInfo)

    if hasPropsInfo then
        cellViewData.propIconNode:RefreshSelf({goodsId = goodsId})
    end
end


return GameStoresView
