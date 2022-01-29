--[[
 * author : liuzhipeng
 * descpt : 特殊活动scene
]]
local GameScene = require( "Frame.GameScene" )
local SpActivityScene = class('SpActivityScene', GameScene)
local SpActivityCurrencyNode = require('Game.views.specialActivity.SpActivityCurrencyNode')
local RES_DICT = {
    TITLE_BG               = _res('ui/home/specialActivity/anni_activity_bg_title.png'),
    COMMON_TIPS_ICON       = _res('ui/common/common_btn_tips.png'),
    COMMON_ALPHA_IMG       = _res('ui/common/story_tranparent_bg.png'),
    MONEY_INFO_BAR         = _res('ui/home/nmain/main_bg_money.png'),
    TYPE_LIST_BG           = _res('ui/home/capsuleNew/home/summon_list_bg.png'),
    TYPE_CELL_BG_BASIC     = _res('ui/home/capsuleNew/bgImgs/summon_notice_bg_base.jpg'),
    TYPE_CELL_BG_NEWBIE    = _res('ui/home/capsuleNew/bgImgs/summon_notice_bg_newplayer.jpg'),
    TYPE_CELL_LOADING_SPN  = _spn('ui/common/activity_ico_load'),
    TYPE_CELL_ARROW_SELECT = _res('ui/home/capsuleNew/home/summon_ico_arrow_selected.png'),
    TYPE_CELL_FRAME_SELECT = _res('ui/mail/common_bg_list_selected.png'),
    TYPE_CELL_FRAME_NORMAL = _res('ui/home/capsuleNew/home/summon_list_img_frame.png'),
    TYPE_CELL_FRAME_IMAGE  = _res('ui/home/capsuleNew/home/summon_list_bg_frame.png'),
    DRAW_CELL_BG_BASIC     = _res('ui/home/capsuleNew/bgImgs/summon_basic_bg.jpg'),
    DRAW_CELL_BG_NEWBIE    = _res('ui/home/capsuleNew/bgImgs/summon_newplayer_bg.jpg'),
    DRAW_CELL_BG_IMAGE     = _res('ui/home/capsuleNew/home/anni_activity_common_bg.jpg'),
    DRAW_CELL_TIME_FRAME   = _res('ui/home/capsuleNew/home/anni_activity_bg_time.png'),
    DRAW_CELL_INFO_FRAME   = _res('ui/home/capsuleNew/home/summon_common_bg_detail.png'),
    DRAW_CELL_PREVIEW_BTN  = _res('ui/home/capsuleNew/home/summon_btn_preview.png'),
}

local CreateView     = nil
local CreateTypeCell = nil
local CreateDrawCell = nil


function SpActivityScene:ctor(args)
    self.super.ctor(self,'views.specialActivity.SpActivityScene')
    -- create view
    self.viewData_ = CreateView()
    self:addChild(self.viewData_.view)

    -- create drawCell
    local drawCellLayer    = self:getViewData().drawCellLayer
    self.drawCellViewData_ = self:createDrawCell(drawCellLayer:getContentSize())
    drawCellLayer:addChild(self.drawCellViewData_.view) 
end


CreateView = function()
    local view = display.newLayer()
    local size = view:getContentSize()

    -- block layer
    view:addChild(display.newLayer(0, 0, {color = cc.r4b(255), enable = true}))

    ------------------------------------------------- [center]
    -- drawCell layer
    local drawCellLayer = display.newLayer()
    view:addChild(drawCellLayer)

    
    ------------------------------------------------- [top]
    
    -- top ui layer
    local topBg = display.newImageView(RES_DICT.TITLE_BG, 0, 0)
    local topUILayerSize = cc.size(size.width, topBg:getContentSize().height)
    local topUILayer = display.newLayer(size.width / 2, size.height, {size = topUILayerSize, ap = display.CENTER_TOP})
    view:addChild(topUILayer, 10)
    topBg:setPosition(topUILayerSize.width / 2, topUILayerSize.height / 2)
    topUILayer:addChild(topBg, 1)
    local title = display.newLabel(topUILayerSize.width / 2, topUILayerSize.height / 2, {text = '一周年庆', fontSize = 46, color = '#fcfec9', ttf = true, font = TTF_GAME_FONT, outline = '#3f3d24', outlineSize = 3})
    topUILayer:addChild(title, 3)
    -- currencyNode 
    local currencyNodes = {}
    local currencyGoods = {
        DIAMOND_ID,
        GOLD_ID,
    }
    for i, v in ipairs(currencyGoods) do
        local currencyNode = SpActivityCurrencyNode.new({goodsId = currencyGoods[i]})
        display.commonUIParams(currencyNode, {ap = cc.p(1, 0.5), po = cc.p(topUILayerSize.width - 40 - (i - 1) * 200 - display.SAFE_L, topUILayerSize.height / 2)})
        topUILayer:addChild(currencyNode, 5)
        table.insert(currencyNodes, currencyNode)
    end

    ------------------------------------------------- [left]
    -- type BgBar
    local typeBgSize = cc.size(300, size.height - 80)
    view:addChild(display.newImageView(RES_DICT.TYPE_LIST_BG, display.SAFE_L + typeBgSize.width/2, 0, {scale9 = true, size = typeBgSize, ap = display.CENTER_BOTTOM}))
    -- type pageView
    local typeListGapW = 8
    local typeListGapH = 10
    local typeListSize = cc.size(typeBgSize.width - typeListGapW*2, typeBgSize.height - typeListGapH*2)
    local typeListView = CTableView:create(typeListSize)
    typeListView:setSizeOfCell(cc.size(typeListSize.width, 136))
    typeListView:setDirection(eScrollViewDirectionVertical)
    typeListView:setAnchorPoint(display.CENTER_BOTTOM)
    typeListView:setPositionX(display.SAFE_L + typeBgSize.width/2)
    typeListView:setPositionY(typeListGapH)
    view:addChild(typeListView)

    return {
        view          = view,
        topUILayer    = topUILayer,
        typeListView  = typeListView,
        drawCellLayer = drawCellLayer,
        currencyNodes = currencyNodes,
        title         = title,
    }
end


CreateTypeCell = function(size)
    local view = CTableViewCell:new()
    view:setContentSize(size)

    -- block layer
    view:addChild(display.newLayer(0, 0, {size = size, color = cc.r4b(0), enable = true}))
    
    -- bg image
    local centerPos = cc.p(size.width/2, size.height/2)
    view:addChild(display.newImageView(RES_DICT.TYPE_CELL_FRAME_IMAGE, centerPos.x, centerPos.y))

    -- loading spine
    local loadingSpn = sp.SkeletonAnimation:create(RES_DICT.TYPE_CELL_LOADING_SPN.json, RES_DICT.TYPE_CELL_LOADING_SPN.atlas, 1)
    loadingSpn:setAnimation(0, 'idle', true)
    loadingSpn:setPosition(centerPos)
    view:addChild(loadingSpn)

    -- image webSprite
    local imageSize    = cc.size(240, 120)
    local imgWebSprite = require('root.WebSprite').new({hpath = RES_DICT.COMMON_ALPHA_IMG, tsize = imageSize})
    imgWebSprite:setAnchorPoint(display.CENTER)
    imgWebSprite:setPosition(centerPos)
    view:addChild(imgWebSprite)

    -- image layer
    local imageLayer = display.newLayer(centerPos.x, centerPos.y, {ap = display.LEFT_BOTTOM, size = imageSize})
    view:addChild(imageLayer)

    -- normal frame
    local frameNormal = display.newImageView(RES_DICT.TYPE_CELL_FRAME_NORMAL, centerPos.x, centerPos.y)
    view:addChild(frameNormal)

    -- select frame
    local frameSelect = display.newImageView(RES_DICT.TYPE_CELL_FRAME_SELECT, centerPos.x, centerPos.y, {scale9 = true, size = cc.size(252, 128)})
    view:addChild(frameSelect)

    -- select arraw
    local selectArrow = display.newImageView(RES_DICT.TYPE_CELL_ARROW_SELECT, 0, centerPos.y, {ap = display.LEFT_CENTER})
    view:addChild(selectArrow)
    
    -- click hostpot
    local clickHotspot = display.newLayer(0, 0, {size = size, color = cc.r4b(0), enable = true})
    view:addChild(clickHotspot)
    
    return {
        view         = view,
        loadingSpn   = loadingSpn,
        imageLayer   = imageLayer,
        imgWebSprite = imgWebSprite,
        frameNormal  = frameNormal,
        frameSelect  = frameSelect,
        selectArrow  = selectArrow,
        clickHotspot = clickHotspot,
    }
end


CreateDrawCell = function(size)
    local view = display.newLayer(0, 0, {size = size})

    -- block layer
    view:addChild(display.newLayer(0, 0, {size = size, color = cc.r4b(150), enable = true}))

    -- bg clippingNode
    local bgSafeSize     = size
    local bgCenterPos    = cc.p(bgSafeSize.width/2, bgSafeSize.height/2)
    local bgClippingNode = cc.ClippingNode:create()
    bgClippingNode:setPosition(size.width/2, size.height/2)
    bgClippingNode:setAnchorPoint(display.CENTER)
    bgClippingNode:setContentSize(bgSafeSize)
    view:addChild(bgClippingNode)

    local bgImgMaskNode = display.newImageView(RES_DICT.COMMON_ALPHA_IMG, 0, 0, {size = bgSafeSize, scale9 = true, ap = display.LEFT_BOTTOM})
    bgClippingNode:setStencil(bgImgMaskNode)

    -- bg containerNode
    local bgContainerNode = display.newLayer(0, 0, {size = bgSafeSize})
    bgClippingNode:addChild(bgContainerNode)
    bgContainerNode:addChild(display.newImageView(RES_DICT.DRAW_CELL_BG_IMAGE, bgCenterPos.x, bgCenterPos.y))

    -- loading layer
    local loadingLayer = display.newLayer()
    loadingLayer:addChild(AssetsUtils.GetCartoonNode(1, bgCenterPos.x + 50, bgCenterPos.y, {ap = display.RIGHT_CENTER, scale = 0.6}))
    loadingLayer:addChild(display.newLabel(bgCenterPos.x + 80, bgCenterPos.y, fontWithColor(1, {ap = display.LEFT_CENTER, fontSize = 36, text = __('图片加载中。。。')})))
    bgContainerNode:addChild(loadingLayer)

    -- image webSprite
    local imgWebSprite = require('root.WebSprite').new({hpath = RES_DICT.COMMON_ALPHA_IMG})
    imgWebSprite:setAnchorPoint(display.CENTER)
    imgWebSprite:setPosition(bgCenterPos)
    bgContainerNode:addChild(imgWebSprite)

    -- image layer
    local imageLayer = display.newLayer(bgCenterPos.x, bgCenterPos.y, {ap = display.LEFT_BOTTOM, size = bgSafeSize})
    bgContainerNode:addChild(imageLayer)
    
    -------------------------------------------------
    -- content layer
    local contentOffX  = 290
    local contentOffY  = 85
    local contentSize  = cc.size(display.SAFE_RECT.width - contentOffX, display.SAFE_RECT.height - contentOffY)
    local contentLayer = display.newLayer(display.SAFE_L + contentOffX, 0, {size = contentSize})
    view:addChild(contentLayer)

    -------------------------------------------------
    -- timeLeft layer
    local timeLeftLayer = display.newLayer(0, 0, {size = size})
    view:addChild(timeLeftLayer)
    
    -- timeLeft image
    local timeLeftImage = display.newImageView(RES_DICT.DRAW_CELL_TIME_FRAME, display.SAFE_R - 15, size.height - 120, {ap = display.RIGHT_CENTER, scale9 = true, capInsets = cc.rect(40,1,200,30)})
    timeLeftLayer:addChild(timeLeftImage)

    -- timeLeft label
    local timeLeftLabel = display.newLabel(timeLeftImage:getPositionX(), timeLeftImage:getPositionY(), fontWithColor(18, {ap = display.LEFT_CENTER, color = '#FFB43F'}))
    local timeLeftBrand = display.newLabel(timeLeftImage:getPositionX(), timeLeftImage:getPositionY(), fontWithColor(18, {ap = display.LEFT_CENTER, text = __('剩余时间:')}))
    timeLeftLayer:addChild(timeLeftLabel)
    timeLeftLayer:addChild(timeLeftBrand)
    -- ruleInfo Button
    local ruleInfoBtn  = display.newButton(timeLeftImage:getPositionX() - 50, timeLeftImage:getPositionY(), {n = RES_DICT.COMMON_TIPS_ICON, ap = display.LEFT_CENTER})
    timeLeftLayer:addChild(ruleInfoBtn)

    return {
        view           = view,
        imgWebSprite   = imgWebSprite,
        imageLayer     = imageLayer,
        contentLayer   = contentLayer,
        ruleInfoBtn    = ruleInfoBtn,
        timeLeftLayer  = timeLeftLayer,
        timeLeftImage  = timeLeftImage,
        timeLeftImageH = timeLeftImage:getContentSize().height,
        timeLeftLabel  = timeLeftLabel,
        timeLeftBrand  = timeLeftBrand,
    }
end


-------------------------------------------------
-- self view

function SpActivityScene:getViewData()
    return self.viewData_
end


function SpActivityScene:getDrawCellViewData()
    return self.drawCellViewData_
end

function SpActivityScene:showUI(endCB)
    self:runAction(cc.Sequence:create(
        cc.CallFunc:create(function()
            if endCB then endCB() end
        end)
    ))
end
function SpActivityScene:RefreshCurrencyBar()
    for i, v in ipairs(self.viewData_.currencyNodes) do
        v:RefreshUI()
    end
end
--[[
刷新标题
@params title string 标题
--]]
function SpActivityScene:RefreshTitleLabel( title )
    local viewData = self.viewData_
    viewData.title:setString(title)
end
-------------------------------------------------
-- type cell

function SpActivityScene:createTypeCell(size)
    return CreateTypeCell(size)
end


function SpActivityScene:updateTypeCellSelectStatus(cellViewData, isSelected)
    if not cellViewData then return end
    cellViewData.selectArrow:setVisible(isSelected)
    cellViewData.frameSelect:setVisible(isSelected)
    cellViewData.frameNormal:setVisible(not isSelected)
end


function SpActivityScene:updateTypeCellImage(cellViewData, drawType, typeData)
    if not cellViewData then return end
    cellViewData.imageLayer:setVisible(false)
    cellViewData.imgWebSprite:setVisible(false)
    local imgURL = typeData and checkstr(typeData.sidebarImage[i18n:getLang()]) or ''
    cellViewData.imgWebSprite:setVisible(string.len(imgURL) > 0)
    cellViewData.imgWebSprite:setWebURL(imgURL)
end


-------------------------------------------------
-- draw cell

function SpActivityScene:createDrawCell(size)
    return CreateDrawCell(size)
end
function SpActivityScene:updateDrawCellRuleInfoStatus(cellViewData, hasRule)
    if not cellViewData then return end
    cellViewData.ruleInfoBtn:setVisible(hasRule)
end
function SpActivityScene:updateDrawCellImage(cellViewData, drawType, typeData)
    if not cellViewData then return end
    cellViewData.imageLayer:setVisible(false)
    cellViewData.imgWebSprite:setVisible(false)

    local imgURL = typeData.backgroundImage and checkstr(typeData.backgroundImage[i18n.getLang()]) or ''
    cellViewData.imgWebSprite:setVisible(string.len(imgURL) > 0)
    cellViewData.imgWebSprite:setWebURL(imgURL)
end

function SpActivityScene:updateDrawCellTimeLeftInfo(cellViewData, drawType, seconds)
    if not cellViewData then return end
    cellViewData.timeLeftLayer:setVisible(true)

    if drawType == ACTIVITY_TYPE.ACTIVITY_PREVIEW then
        cellViewData.timeLeftLayer:setVisible(false)

    else
        local leftSeconds = checkint(seconds)
        local isToOpening = leftSeconds > 0

        -- update timeLabel
        if isToOpening then
            display.commonLabelParams(cellViewData.timeLeftLabel, {text = CommonUtils.getTimeFormatByType(leftSeconds)})
        else
            display.commonLabelParams(cellViewData.timeLeftLabel, {text = __('活动已结束')})
        end
        
        -------------------------------------------------
        local timeLabelSize = display.getLabelContentSize(cellViewData.timeLeftLabel)
        local timeBrandSize = display.getLabelContentSize(cellViewData.timeLeftBrand)
        
        -- update timeLabel
        local timeImageWidth = 40 + timeLabelSize.width
        local timeImagePoint = cc.p(cellViewData.timeLeftImage:getPosition())
        cellViewData.timeLeftLabel:setPositionX(timeImagePoint.x - timeImageWidth)
        
        -- update timeBrand
        if isToOpening then
            timeImageWidth = timeImageWidth + 10 + timeBrandSize.width
            cellViewData.timeLeftBrand:setPositionX(timeImagePoint.x - timeImageWidth)
        end
        cellViewData.timeLeftBrand:setVisible(isToOpening)
        
        -- update timeImage
        timeImageWidth = timeImageWidth + 30
        cellViewData.timeLeftImage:setContentSize(cc.size(timeImageWidth, cellViewData.timeLeftImageH))
    end
end


return SpActivityScene
