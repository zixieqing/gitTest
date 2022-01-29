--[[
 * author : kaishiqi
 * descpt : 新抽卡视图
]]
local GoodPurchaseNode = require('common.GoodPurchaseNode')
local CapsuleNewView   = class('CapsuleNewView', function()
    return display.newLayer(0, 0, {name = 'Game.views.drawCards.CapsuleNewView'})
end)

local RES_DICT = {
    TITLE_BAR              = _res('ui/common/common_title.png'),
    COMMON_TIPS_ICON       = _res('ui/common/common_btn_tips.png'),
    COMMON_ALPHA_IMG       = _res('ui/common/story_tranparent_bg.png'),
    MONEY_INFO_BAR         = _res('ui/home/nmain/main_bg_money.png'),
    TYPE_LIST_BG           = _res('ui/home/capsuleNew/home/summon_list_bg.png'),
    TYPE_CELL_BG_BASIC     = _res('ui/home/capsuleNew/bgImgs/summon_notice_bg_base.jpg'),
    TYPE_CELL_BG_NEWBIE    = _res('ui/home/capsuleNew/bgImgs/summon_notice_bg_newplayer.jpg'),
    TYPE_CELL_BG_BASIC_SKIN = _res('ui/home/capsuleNew/bgImgs/notice_activity_20newskin_1.jpg'),
    TYPE_CELL_BG_FREE_NEW  = _res('ui/home/capsuleNew/bgImgs/summon_notice_bg_newgift.jpg'),
    TYPE_CELL_LOADING_SPN  = _spn('ui/common/activity_ico_load'),
    TYPE_CELL_ARROW_SELECT = _res('ui/home/capsuleNew/home/summon_ico_arrow_selected.png'),
    TYPE_CELL_FRAME_SELECT = _res('ui/mail/common_bg_list_selected.png'),
    TYPE_CELL_FRAME_NORMAL = _res('ui/home/capsuleNew/home/summon_list_img_frame.png'),
    TYPE_CELL_FRAME_IMAGE  = _res('ui/home/capsuleNew/home/summon_list_bg_frame.png'),
    DRAW_CELL_BG_BASIC     = _res('ui/home/capsuleNew/bgImgs/summon_basic_bg.jpg'),
    DRAW_CELL_BG_NEWBIE    = _res('ui/home/capsuleNew/bgImgs/summon_newplayer_bg.jpg'),
    DRAW_CELL_BG_FREE_NEW  = _res("ui/home/capsuleNew/bgImgs/summon_newgift_bg.jpg"),
    DRAW_CELL_BG_IMAGE     = _res('ui/home/capsuleNew/home/anni_activity_common_bg.jpg'),
    DRAW_CELL_TIME_FRAME   = _res('ui/home/capsuleNew/home/anni_activity_bg_time.png'),
    DRAW_CELL_INFO_FRAME   = _res('ui/home/capsuleNew/home/summon_common_bg_detail.png'),
    DRAW_CELL_PREVIEW_BTN  = _res('ui/home/capsuleNew/home/summon_btn_preview.png'),
    SUMMON_CHOICE_BG_1     = _res("ui/home/capsuleNew/cardChoose/summon_choice_bg_1.jpg"),
    ZH_LIZI                = _spn('ui/home/capsuleNew/zh_lizi'),
}

local CreateView     = nil
local CreateTypeCell = nil
local CreateDrawCell = nil


function CapsuleNewView:ctor(args)
    -- create view
    self.viewData_ = CreateView()
    self:addChild(self.viewData_.view)

    -- create drawCell
    local drawCellLayer    = self:getViewData().drawCellLayer
    self.drawCellViewData_ = self:createDrawCell(drawCellLayer:getContentSize())
    drawCellLayer:addChild(self.drawCellViewData_.view)

    -- init views
    self:getViewData().titleBtn:setPositionY(display.height + 190)
    self:getViewData().topUILayer:setPositionY(190)
    self:reloadMoneyBar()
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
    -- title button
    local titleBtn = display.newButton(display.SAFE_L + 120, size.height, {n = RES_DICT.TITLE_BAR, ap = display.LEFT_TOP, enable = false})
    display.commonLabelParams(titleBtn, fontWithColor(1, {text = __('召唤'), offset = cc.p(0,-10)}))
    view:addChild(titleBtn)

    -- top ui layer
    local topUILayer = display.newLayer()
    view:addChild(topUILayer)

    -- money barBg
    local moneyBarBg = display.newImageView(_res(RES_DICT.MONEY_INFO_BAR), display.width, display.height, {ap = display.RIGHT_TOP, scale9 = true, size = cc.size(1, 54)})
    topUILayer:addChild(moneyBarBg)

    -- money layer
    local moneyLayer = display.newLayer()
    topUILayer:addChild(moneyLayer)


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
        titleBtn      = titleBtn,
        titleBtnX     = titleBtn:getPositionX(),
        typeListView  = typeListView,
        drawCellLayer = drawCellLayer,
        moneyBarBg    = moneyBarBg,
        moneyLayer    = moneyLayer,
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
    -- ruleInfo button
    local ruleInfoBtn  = display.newButton(display.SAFE_L + contentOffX + 40, size.height - 110, {n = RES_DICT.DRAW_CELL_INFO_FRAME, ap = display.LEFT_TOP, scale9 = true})
    local ruleInfoSize = ruleInfoBtn:getContentSize()
    display.commonLabelParams(ruleInfoBtn, fontWithColor(18, {text = __('规则说明'), paddingW = 30, offset1 = cc.p(2, 0)}))
    ruleInfoBtn:addChild(display.newImageView(RES_DICT.COMMON_TIPS_ICON, 0, ruleInfoSize.height/2))
    view:addChild(ruleInfoBtn)

    -- preview button
    local previewBtn  = display.newButton(display.SAFE_R - 0, size.height - 60, {n = RES_DICT.DRAW_CELL_PREVIEW_BTN, ap = display.RIGHT_TOP})
    local previewSize = previewBtn:getContentSize()
    display.commonLabelParams(previewBtn, fontWithColor(19, {text = __('内容一览'), w = 270 ,  ap = display.RIGHT_CENTER, offset = cc.p(previewSize.width/2 - 100, 0)}))
    previewBtn:addChild(display.newImageView(RES_DICT.COMMON_TIPS_ICON, previewSize.width - 60, previewSize.height/2))
    view:addChild(previewBtn)

    local particleSpine = sp.SkeletonAnimation:create(
        RES_DICT.ZH_LIZI.json,
        RES_DICT.ZH_LIZI.atlas,
        1)
    previewBtn:addChild(particleSpine,11)
    particleSpine:setAnimation(0, 'idle', true)
    particleSpine:update(0)
    particleSpine:setPosition(utils.getLocalCenter(previewBtn))
    particleSpine:setToSetupPose()

    -- timeLeft layer
    local timeLeftLayer = display.newLayer(0, 0, {size = size})
    view:addChild(timeLeftLayer)

    -- timeLeft image
    local timeLeftImage = display.newImageView(RES_DICT.DRAW_CELL_TIME_FRAME, display.SAFE_R - 15, previewBtn:getPositionY() - 105, {ap = display.RIGHT_CENTER, scale9 = true, capInsets = cc.rect(40,1,200,30)})
    timeLeftLayer:addChild(timeLeftImage)

    -- timeLeft label
    local timeLeftLabel = display.newLabel(timeLeftImage:getPositionX(), timeLeftImage:getPositionY(), fontWithColor(18, {ap = display.LEFT_CENTER, color = '#FFB43F'}))
    local timeLeftBrand = display.newLabel(timeLeftImage:getPositionX(), timeLeftImage:getPositionY(), fontWithColor(18, {ap = display.LEFT_CENTER, text = __('剩余时间：')}))
    timeLeftLayer:addChild(timeLeftLabel)
    timeLeftLayer:addChild(timeLeftBrand)

    return {
        view           = view,
        imgWebSprite   = imgWebSprite,
        imageLayer     = imageLayer,
        contentLayer   = contentLayer,
        ruleInfoBtn    = ruleInfoBtn,
        previewBtn     = previewBtn,
        particleSpine  = particleSpine,
        timeLeftLayer  = timeLeftLayer,
        timeLeftImage  = timeLeftImage,
        timeLeftImageH = timeLeftImage:getContentSize().height,
        timeLeftLabel  = timeLeftLabel,
        timeLeftBrand  = timeLeftBrand,
    }
end


-------------------------------------------------
-- self view

function CapsuleNewView:getViewData()
    return self.viewData_
end


function CapsuleNewView:getDrawCellViewData()
    return self.drawCellViewData_
end


function CapsuleNewView:showUI(endCB)
    self:runAction(cc.Sequence:create(
        cc.Spawn:create(
            cc.TargetedAction:create(self.viewData_.topUILayer, cc.MoveTo:create(0.4, cc.p(0, 0))),
            cc.TargetedAction:create(self.viewData_.titleBtn, cc.EaseBounceOut:create(cc.MoveTo:create(1, cc.p(self.viewData_.titleBtnX, display.height + 2))) )
        ),
        cc.CallFunc:create(function()
            if endCB then endCB() end
        end)
    ))
end


function CapsuleNewView:reloadMoneyBar(moneyIdMap, isDisableGain)
    if moneyIdMap then
        moneyIdMap[tostring(GOLD_ID)]         = nil
        moneyIdMap[tostring(DIAMOND_ID)]      = nil
        moneyIdMap[tostring(PAID_DIAMOND_ID)] = nil
        moneyIdMap[tostring(FREE_DIAMOND_ID)] = nil
    end

    -- money data
    local moneyIdList = table.keys(moneyIdMap or {})
    table.insert(moneyIdList, GOLD_ID)
    table.insert(moneyIdList, DIAMOND_ID)

    -- clean moneyLayer
    local moneyBarBg = self:getViewData().moneyBarBg
    local moneyLayer = self:getViewData().moneyLayer
    moneyLayer:removeAllChildren()

    -- update moneyLayer
    local MONEY_NODE_GAP = 16
    local moneyLayerSize = moneyLayer:getContentSize()
    local moneryBarSize  = cc.size(20, moneyBarBg:getContentSize().height)
    for i = #moneyIdList, 1, -1 do
        local moneyId = checkint(moneyIdList[i])
        local isDisable = moneyId ~= GOLD_ID and moneyId ~= DIAMOND_ID and isDisableGain
        local moneyNode = GoodPurchaseNode.new({id = moneyId, animate = true, disable = isDisable, isEnableGain = not isDisableGain})
        moneyNode.viewData.touchBg:setTag(checkint(moneyId))
        moneyNode:setPosition(display.SAFE_R - moneryBarSize.width, moneyLayerSize.height - 26)
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


function CapsuleNewView:updateMoneyBar()
    for _, moneyNode in ipairs(self:getViewData().moneyLayer:getChildren()) do
        local moneyId = checkint(moneyNode:getName())
        moneyNode:updataUi(moneyId)
    end
end


-------------------------------------------------
-- type cell

function CapsuleNewView:createTypeCell(size)
    return CreateTypeCell(size)
end


function CapsuleNewView:updateTypeCellSelectStatus(cellViewData, isSelected)
    if not cellViewData then return end
    cellViewData.selectArrow:setVisible(isSelected)
    cellViewData.frameSelect:setVisible(isSelected)
    cellViewData.frameNormal:setVisible(not isSelected)
end


function CapsuleNewView:updateTypeCellImage(cellViewData, drawType, typeData)
    if not cellViewData then return end
    cellViewData.imageLayer:setVisible(false)
    cellViewData.imgWebSprite:setVisible(false)

    if drawType == ACTIVITY_TYPE.DRAW_BASIC_GET then
        cellViewData.imageLayer:setVisible(true)
        cellViewData.imageLayer:removeAllChildren()
        cellViewData.imageLayer:addChild(display.newImageView(RES_DICT.TYPE_CELL_BG_BASIC))

    elseif drawType == ACTIVITY_TYPE.DRAW_NEWBIE_GET then
        cellViewData.imageLayer:setVisible(true)
        cellViewData.imageLayer:removeAllChildren()
        cellViewData.imageLayer:addChild(display.newImageView(RES_DICT.TYPE_CELL_BG_NEWBIE))
    elseif drawType == ACTIVITY_TYPE.BASIC_SKIN_CAPSULE then
        cellViewData.imageLayer:setVisible(true)
        cellViewData.imageLayer:removeAllChildren()
        cellViewData.imageLayer:addChild(display.newImageView(RES_DICT.TYPE_CELL_BG_BASIC_SKIN))
    elseif drawType == ACTIVITY_TYPE.FREE_NEWBIE_CAPSULE then
        cellViewData.imageLayer:setVisible(true)
        cellViewData.imageLayer:removeAllChildren()
        cellViewData.imageLayer:addChild(display.newImageView(RES_DICT.TYPE_CELL_BG_FREE_NEW))
    else
        local imgURL = typeData and checkstr(typeData.sidebarImage) or ''
        cellViewData.imgWebSprite:setVisible(string.len(imgURL) > 0)
        cellViewData.imgWebSprite:setWebURL(imgURL)
    end
end


-------------------------------------------------
-- draw cell

function CapsuleNewView:createDrawCell(size)
    return CreateDrawCell(size)
end


function CapsuleNewView:updateDrawCellRuleInfoStatus(cellViewData, hasRule)
    if not cellViewData then return end
    cellViewData.ruleInfoBtn:setVisible(hasRule)
end


function CapsuleNewView:updateDrawCellImage(cellViewData, drawType, typeData)
    if not cellViewData then return end
    cellViewData.imageLayer:setVisible(false)
    cellViewData.imgWebSprite:setVisible(false)

    if drawType == ACTIVITY_TYPE.DRAW_BASIC_GET then
        cellViewData.imageLayer:setVisible(true)
        cellViewData.imageLayer:removeAllChildren()
        cellViewData.imageLayer:addChild(display.newImageView(RES_DICT.DRAW_CELL_BG_BASIC))
    elseif drawType == ACTIVITY_TYPE.DRAW_NEWBIE_GET then
        cellViewData.imageLayer:setVisible(true)
        cellViewData.imageLayer:removeAllChildren()
        cellViewData.imageLayer:addChild(display.newImageView(RES_DICT.DRAW_CELL_BG_NEWBIE))
    elseif drawType == ACTIVITY_TYPE.DRAW_CARD_CHOOSE then
        cellViewData.imageLayer:setVisible(true)
        cellViewData.imageLayer:removeAllChildren()
        cellViewData.imageLayer:addChild(display.newImageView(RES_DICT.SUMMON_CHOICE_BG_1))
    elseif drawType == ACTIVITY_TYPE.FREE_NEWBIE_CAPSULE then
        cellViewData.imageLayer:setVisible(true)
        cellViewData.imageLayer:removeAllChildren()
        cellViewData.imageLayer:addChild(display.newImageView(RES_DICT.DRAW_CELL_BG_FREE_NEW))
    else
        local imgURL = typeData and checkstr(typeData.backgroundImage) or ''
        cellViewData.imgWebSprite:setVisible(string.len(imgURL) > 0)
        cellViewData.imgWebSprite:setWebURL(imgURL)
    end
end

function CapsuleNewView:updateDrawCellTimeLeftInfo(cellViewData, drawType, seconds)
    if not cellViewData then return end
    cellViewData.timeLeftLayer:setVisible(true)

    if drawType == ACTIVITY_TYPE.DRAW_BASIC_GET then
        cellViewData.timeLeftLayer:setVisible(false)
    elseif drawType == ACTIVITY_TYPE.BASIC_SKIN_CAPSULE then
        cellViewData.timeLeftLayer:setVisible(false)
    elseif drawType == ACTIVITY_TYPE.FREE_NEWBIE_CAPSULE then
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

function CapsuleNewView:updatePreviewBtnShowState(cellViewData, isShow)
    local previewBtn = cellViewData.previewBtn
    local timeLeftLayer = cellViewData.timeLeftLayer

    if isShow then
        previewBtn:setVisible(true)
        timeLeftLayer:setPositionY(0)
    else
        previewBtn:setVisible(false)
        timeLeftLayer:setPositionY(35)
    end
end

function CapsuleNewView:updatePreviewBtnName(cellViewData, name)
    local previewBtn = cellViewData.previewBtn
    display.commonLabelParams(previewBtn, {text = name    or __('内容一览') , hAlign = display.TAR ,   w = 270 })
    if display.getLabelContentSize(previewBtn:getLabel()).height > 60   then
        display.commonLabelParams(previewBtn, {text = name    or __('内容一览') , hAlign = display.TAR ,   w = 330 , reqW = 270   })
    end
end

return CapsuleNewView
