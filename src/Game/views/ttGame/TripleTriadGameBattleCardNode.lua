--[[
 * author : kaishiqi
 * descpt : 打牌游戏 - 卡牌视图节点
]]
local TTGameCardNode = class('TripleTriadGameBattleCardNode', function()
    return display.newLayer(0, 0, {name = 'TripleTriadGameBattleCardNode'})
end)

local RES_DICT = {
    SELECT_IMAGE      = _res('ui/ttgame/common/cardgame_deck_frame_selected.png'),
    DESABLE_IMAGE     = _res('ui/ttgame/common/cardgame_card_cover.png'),
    FRONT_FRAME_N     = _res('ui/ttgame/common/cardgame_card_frame_default.png'),
    FRONT_FRAME_SP    = _res('ui/ttgame/common/cardgame_card_frame_sp.png'),
    BACK_FRAME_N      = _res('ui/ttgame/common/cardgame_card_board_default.png'),
    BACK_FRAME_SP     = _res('ui/ttgame/common/cardgame_card_board_sp.png'),
    BACK_OPERATOR     = _res('ui/ttgame/common/cardgame_card_board_blue.png'),
    BACK_OPPONENT     = _res('ui/ttgame/common/cardgame_card_board_red.png'),
    CARD_STAR_ICON    = _res('ui/ttgame/common/cardgame_card_ico_star.png'),
    CARD_HAVE_ICON    = _res('ui/ttgame/common/cardgame_card_corner_get.png'),
    CARD_ATTR_FRAME   = _res('ui/ttgame/common/cardgame_card_label_num.png'),
    CARD_BACK_IMAGE   = _res('ui/ttgame/common/cardgame_card_back_default.png'),
    CARD_NAME_FRAME   = _res('ui/ttgame/common/cardgame_collection_label_cardname.png'),
    REVEAL_MARK_ICON  = _res('ui/ttgame/common/cardgame_battle_ico_visible.png'),
    CARD_STAR_TIPS    = _res('ui/ttgame/common/cardgame_card_warning.png'),
    ARRT_CHANGE_SPINE = _spn('ui/ttgame/common/cardgame_battle_num'),
    CARD_SHADOW       = _res('ui/ttgame/common/cardgame_battle_bg_selected_shadow.png'),
}

local CreateView   = nil
local DEFAULT_SIZE = cc.size(200, 230)

local ZOOM_DEFINES = {
    ['l']  = {name = 'l',  size = DEFAULT_SIZE,      scale = 1.00, attrPos = cc.p(-10,-10)},
    ['m']  = {name = 'm',  size = cc.size(180, 208), scale = 0.90, attrPos = cc.p(-10,-10)},
    ['s']  = {name = 's',  size = cc.size(120, 138), scale = 0.60, attrPos = cc.p(-25,-20)},
    ['ss'] = {name = 'ss', size = cc.size(116, 134), scale = 0.58, attrPos = cc.p(-20,-20)},
}


function TTGameCardNode:ctor(args)
    self:setAnchorPoint(display.CENTER)
    self:setContentSize(DEFAULT_SIZE)
    
    -- init vars
    local initArgs   = args or {}
    local isShowName = initArgs.showName == true
    self.zoomModel_  = initArgs.zoomModel or 'l'
    
    -- create view
    local zoomDefine = ZOOM_DEFINES[self.zoomModel_]
    self.viewData_   = CreateView(zoomDefine)
    self:setContentSize(zoomDefine.size)
    self:addChild(self:getViewData().view)
    
    -- update views
    self:getViewData().nameBar:setVisible(isShowName)
    self:setCardId(checkint(initArgs.cardId))
    self:hideOperatorUnderFrame()
    self:hideOpponentUnderFrame()
    self:hideHaveCardMark()
    self:hideRevealMark()
    self:hideCardShadow()
    self:toNormalStatus()
end


local CreateImageNode = function(imgPath, x, y, args)
    local imageNode = FilteredSpriteWithOne:create()
    imageNode:setPosition(cc.p(checkint(x), checkint(y)))
    imageNode:setCascadeOpacityEnabled(true)
    imageNode:setAnchorPoint(display.CENTER)
    imageNode:setTexture(imgPath)
    if args then
        if args.ap then imageNode:setAnchorPoint(args.ap) end
    end
    return imageNode
end


CreateView = function(define)
    local view = display.newLayer()
    local size = define.size

    -- scale layer
    local scaleLayer = display.newLayer(0, 0, {size = size})
    scaleLayer:setScale(define.scale)
    view:addChild(scaleLayer)

    -- back frame
    local cardShadow   = CreateImageNode(RES_DICT.CARD_SHADOW, size.width/2/define.scale, size.height/2/define.scale)
    local backFrameN   = CreateImageNode(RES_DICT.BACK_FRAME_N, cardShadow:getPositionX(), cardShadow:getPositionY())
    local backFrameSP  = CreateImageNode(RES_DICT.BACK_FRAME_SP, cardShadow:getPositionX(), cardShadow:getPositionY())
    local backOperator = CreateImageNode(RES_DICT.BACK_OPERATOR, cardShadow:getPositionX(), cardShadow:getPositionY())
    local backOpponent = CreateImageNode(RES_DICT.BACK_OPPONENT, cardShadow:getPositionX(), cardShadow:getPositionY())
    scaleLayer:addChild(cardShadow)
    scaleLayer:addChild(backFrameN)
    scaleLayer:addChild(backFrameSP)
    scaleLayer:addChild(backOperator)
    scaleLayer:addChild(backOpponent)

    -- image layer
    local imageLayer = display.newLayer(size.width/2/define.scale, size.height/2/define.scale)
    scaleLayer:addChild(imageLayer)

    -- front frame
    local frontFrameN  = CreateImageNode(RES_DICT.FRONT_FRAME_N, size.width/2/define.scale, size.height/2/define.scale)
    local frontFrameSP = CreateImageNode(RES_DICT.FRONT_FRAME_SP, frontFrameN:getPositionX(), frontFrameN:getPositionY())
    scaleLayer:addChild(frontFrameSP)
    scaleLayer:addChild(frontFrameN)

    -- name bar
    local nameBar = display.newButton(size.width/define.scale - 5, 5, {n = RES_DICT.CARD_NAME_FRAME, scale9 = true, ap = display.RIGHT_BOTTOM, enable = false})
    display.commonLabelParams(nameBar, fontWithColor(8, {hAlign = display.TAR}))
    scaleLayer:addChild(nameBar)

    -- card star
    local starIcon = CreateImageNode(RES_DICT.CARD_STAR_ICON, size.width/2/define.scale, size.height/define.scale-3, {ap = display.CENTER_TOP})
    scaleLayer:addChild(starIcon)

    local starLabel = display.newLabel(starIcon:getPositionX(), starIcon:getPositionY() - starIcon:getContentSize().height/2, fontWithColor(20))
    scaleLayer:addChild(starLabel)

    -- desable image
    local disableImg = display.newImageView(RES_DICT.DESABLE_IMAGE, size.width/2/define.scale, size.height/2/define.scale)
    scaleLayer:addChild(disableImg)
    
    -- have icon
    local haveIcon = display.newImageView(RES_DICT.CARD_HAVE_ICON, size.width/define.scale - 4, 4, {ap = display.RIGHT_BOTTOM})
    scaleLayer:addChild(haveIcon)
    

    -- starTips Layer
    local starTipsImg = display.newImageView(RES_DICT.CARD_STAR_TIPS, size.width/2, size.height/2)
    starTipsImg:setScale(define.scale)
    starTipsImg:setVisible(false)
    view:addChild(starTipsImg)
    
    
    -------------------------------------------------
    -- attar layer
    local attrLayer = display.newLayer()
    attrLayer:setPosition(define.attrPos)
    view:addChild(attrLayer)

    local attrFrame = CreateImageNode(RES_DICT.CARD_ATTR_FRAME, 0, 0, {ap = display.LEFT_BOTTOM})
    local attrSize  = attrFrame:getContentSize()
    attrLayer:addChild(attrFrame)
    
    local typeLayer = display.newLayer(attrSize.width/2, attrSize.height/2)
    attrLayer:addChild(typeLayer)
    
    local attrTLabel = display.newLabel(attrSize.width/2, attrSize.height*0.69, fontWithColor(7, {fontSize = 26}))
    local attrBLabel = display.newLabel(attrSize.width/2, attrSize.height*0.31, fontWithColor(7, {fontSize = 26}))
    local attrLLabel = display.newLabel(attrSize.width*0.31, attrSize.height/2, fontWithColor(7, {fontSize = 26}))
    local attrRLabel = display.newLabel(attrSize.width*0.71, attrSize.height/2, fontWithColor(7, {fontSize = 26}))
    attrLayer:addChild(attrTLabel)
    attrLayer:addChild(attrBLabel)
    attrLayer:addChild(attrLLabel)
    attrLayer:addChild(attrRLabel)

    local attrChangeSpine = TTGameUtils.CreateSpine(RES_DICT.ARRT_CHANGE_SPINE)
    attrChangeSpine:setPositionX(attrSize.width/2)
    attrChangeSpine:setPositionY(attrSize.height/2)
    attrChangeSpine:setAnimation(0, 'idle', false)
    attrLayer:addChild(attrChangeSpine)


    -------------------------------------------------

    -- back image
    local cardBackImage = display.newImageView(RES_DICT.CARD_BACK_IMAGE, size.width/2, size.height/2)
    cardBackImage:setScale(define.scale)
    cardBackImage:setVisible(false)
    view:addChild(cardBackImage)

    -- select disable
    local selectImg  = display.newImageView(RES_DICT.SELECT_IMAGE, size.width/2, size.height/2, {scale9 = true, size = size, capInsets = cc.rect(20,20,140,170)})
    view:addChild(selectImg)
    
    -- reveal icon
    local revealIcon = display.newImageView(RES_DICT.REVEAL_MARK_ICON, size.width/2, size.height - 5, {ap = display.CENTER})
    view:addChild(revealIcon)

    -- view:addChild(display.newLayer(0,0,{size = size, color = cc.r4b(100)})) -- debug use
    return {
        view            = view,
        scaleLayer      = scaleLayer,
        cardShadow      = cardShadow,
        backFrameN      = backFrameN,
        backFrameSP     = backFrameSP,
        backOperator    = backOperator,
        backOpponent    = backOpponent,
        frontFrameN     = frontFrameN,
        frontFrameSP    = frontFrameSP,
        imageLayer      = imageLayer,
        starLabel       = starLabel,
        starIcon        = starIcon,
        nameBar         = nameBar,
        --              = 
        attrLayer       = attrLayer,
        attrFrame       = attrFrame,
        attrTLabel      = attrTLabel,
        attrBLabel      = attrBLabel,
        attrLLabel      = attrLLabel,
        attrRLabel      = attrRLabel,
        typeLayer       = typeLayer,
        attrChangeSpine = attrChangeSpine,
        --              = 
        cardBackImage   = cardBackImage,
        selectImg       = selectImg,
        disableImg      = disableImg,
        starTipsImg     = starTipsImg,
        haveIcon        = haveIcon,
        revealIcon      = revealIcon,
    }
end


-------------------------------------------------
-- get / set

function TTGameCardNode:getViewData()
    return self.viewData_
end


function TTGameCardNode:getCardId()
    return self.cardId_
end
function TTGameCardNode:setCardId(cardId)
    if self.cardId_ ~= checkint(cardId) then
        self.cardId_ = checkint(cardId)
        local cardConf  = TTGameUtils.GetConfAt(TTGAME_DEFINE.CONF_TYPE.CARD_DEFINE, self:getCardId())
        self.cardStar_  = checkint(cardConf.star)
        self.cardName_  = tostring(cardConf.name)
        self.cardType_  = checkint(cardConf.type)
        self.initAttrs_ = checktable(cardConf.attr)
        self.lastAttrs_ = clone(self.initAttrs_)
        self.isSpCard_  = TTGameUtils.IsSpCard(self:getCardId())
        self:updateCardImage_()
        self:updateCardName_()
        self:updateCardStar_()
        self:updateCardType_()
        self:updateCardAttr_()
    end
end


function TTGameCardNode:isQualitySP()
    return self.isSpCard_ == true
end


function TTGameCardNode:getCardName()
    return self.cardName_
end


function TTGameCardNode:getCardType()
    return self.cardType_
end


function TTGameCardNode:getCardStar()
    return self.cardStar_
end


function TTGameCardNode:getInitAttrList()
    return self.initAttrs_
end
function TTGameCardNode:getAttrList()
    return self.lastAttrs_
end
function TTGameCardNode:isAttrChangedAt(attrIndex)
    return checkint(self.lastAttrs_[attrIndex]) ~= checkint(self.initAttrs_[attrIndex])
end

function TTGameCardNode:getAttrTop()
    return checkint(self:getAttrList()[1])
end
function TTGameCardNode:getAttrBottom()
    return checkint(self:getAttrList()[3])
end
function TTGameCardNode:getAttrLeft()
    return checkint(self:getAttrList()[4])
end
function TTGameCardNode:getAttrRight()
    return checkint(self:getAttrList()[2])
end

function TTGameCardNode:isAttrTopChanged()
    return self:isAttrChangedAt(1)
end
function TTGameCardNode:isAttrBottomChanged()
    return self:isAttrChangedAt(3)
end
function TTGameCardNode:isAttrLeftChanged()
    return self:isAttrChangedAt(4)
end
function TTGameCardNode:isAttrRightChanged()
    return self:isAttrChangedAt(2)
end


function TTGameCardNode:updateAttrs(attrMap, isSkeepAnimate)
    local isChangeAttr = false
    local newLastAttrs = {}
    local oldLastAttrs = checktable(self.lastAttrs_)
    local lastAttrsMap = checktable(attrMap)
    for i = 1, #self.initAttrs_ do
        local newAttrNum = checkint(lastAttrsMap[tostring(i)])
        if lastAttrsMap[tostring(i)] and lastAttrsMap[tostring(i)] == '' then
            newAttrNum = self.initAttrs_[i]
        end
        table.insert(newLastAttrs, newAttrNum)
    end

    -- check change attrs
    if #oldLastAttrs == #newLastAttrs then
        for i = 1, #self.initAttrs_ do
            local oldAttr = checkint(oldLastAttrs[i])
            local newAttr = checkint(newLastAttrs[i])
            if oldAttr ~= newAttr then
                isChangeAttr = true
                break
            end
        end
    else
        isChangeAttr = true
    end

    -- update attrs
    if isChangeAttr then
        self.lastAttrs_ = newLastAttrs
        self:updateCardAttr_()

        if isSkeepAnimate ~= true then
            self:getViewData().attrChangeSpine:setToSetupPose()
            self:getViewData().attrChangeSpine:setAnimation(0, 'play', false)
        end
    end
end


-------------------------------------------------
-- public

function TTGameCardNode:toNormalStatus()
    self:getViewData().disableImg:setVisible(false)
    self:getViewData().selectImg:setVisible(false)
    self:updateGrayFilter_(false)
end
function TTGameCardNode:toSelectStatus()
    self:getViewData().disableImg:setVisible(false)
    self:getViewData().selectImg:setVisible(true)
    self:updateGrayFilter_(false)
end
function TTGameCardNode:toDisableStatus()
    self:getViewData().selectImg:setVisible(false)
    self:getViewData().disableImg:setVisible(true)
    self:updateGrayFilter_(false)
end
function TTGameCardNode:toBlockedStatus()
    self:getViewData().selectImg:setVisible(false)
    self:getViewData().disableImg:setVisible(false)
    self:updateGrayFilter_(true)
end


-- starLimit tips
function TTGameCardNode:showStarLimitTips()
    self:getViewData().starTipsImg:setColor(cc.c3b(255,255,255))
    self:getViewData().starTipsImg:setVisible(true)
    self:getViewData().starTipsImg:stopAllActions()
    self:getViewData().starTipsImg:runAction(cc.Sequence:create(
        cc.Blink:create(1, 4),
        cc.Hide:create()
    ))
end

-- score tips
function TTGameCardNode:showScoreTips()
    self:getViewData().starTipsImg:setColor(cc.c3b(0,0,0))
    self:getViewData().starTipsImg:setVisible(true)
    self:getViewData().starTipsImg:stopAllActions()
    self:getViewData().starTipsImg:runAction(cc.Sequence:create(
        cc.Blink:create(0.5, 2),
        cc.Hide:create()
    ))
end


-- have icon
function TTGameCardNode:showHaveCardMark()
    self:getViewData().haveIcon:setVisible(true)
end
function TTGameCardNode:hideHaveCardMark()
    self:getViewData().haveIcon:setVisible(false)
end


-- reveal icon
function TTGameCardNode:showRevealMark()
    self:getViewData().revealIcon:setVisible(true)
end
function TTGameCardNode:hideRevealMark()
    self:getViewData().revealIcon:setVisible(false)
end


-- back image
function TTGameCardNode:toCardBackStatus()
    self:getViewData().frontFrameN:setOpacity(0)
    self:getViewData().frontFrameSP:setOpacity(0)
    self:getViewData().starIcon:setVisible(false)
    self:getViewData().attrLayer:setVisible(false)
    self:getViewData().cardBackImage:setVisible(true)
    self:getViewData().attrChangeSpine:setVisible(false)
end
function TTGameCardNode:toCardFrontStatus()
    self:getViewData().frontFrameN:setOpacity(255)
    self:getViewData().frontFrameSP:setOpacity(255)
    self:getViewData().starIcon:setVisible(true)
    self:getViewData().attrLayer:setVisible(true)
    self:getViewData().cardBackImage:setVisible(false)
    self:getViewData().attrChangeSpine:setVisible(true)
end


function TTGameCardNode:showOperatorUnderFrame()
    self:getViewData().backOperator:setVisible(true)
    self:hideOpponentUnderFrame()
end
function TTGameCardNode:hideOperatorUnderFrame()
    self:getViewData().backOperator:setVisible(false)
end
function TTGameCardNode:showOpponentUnderFrame()
    self:getViewData().backOpponent:setVisible(true)
    self:hideOperatorUnderFrame()
end
function TTGameCardNode:hideOpponentUnderFrame()
    self:getViewData().backOpponent:setVisible(false)
end


-- card shadow
function TTGameCardNode:showCardShadow()
    self:getViewData().cardShadow:setVisible(true)
end
function TTGameCardNode:hideCardShadow()
    self:getViewData().cardShadow:setVisible(false)
end


-------------------------------------------------
-- private

function TTGameCardNode:updateCardName_()
    local nameColor = self.isBlockedStatus_ and '#cccccc' or '#f3d088'
    display.commonLabelParams(self:getViewData().nameBar, {color = nameColor, text = tostring(self:getCardName()), w = 95, hAlign = display.TAR, ap = display.RIGHT_CENTER, paddingH = 5})
    self:getViewData().nameBar:getLabel():setPositionX(self:getViewData().nameBar:getContentSize().width - 5)
end


function TTGameCardNode:updateCardStar_()
    local starOutline = self.isBlockedStatus_ and '#7c7c7c' or '##a7894c'
    display.commonLabelParams(self:getViewData().starLabel, fontWithColor(20, {outline = starOutline, fontSize = 22, text = TTGameUtils.GetCardLevelText(self:getCardStar())}))
end


function TTGameCardNode:updateCardType_()
    self:getViewData().typeLayer:removeAllChildren()
    if self:getCardType() > 0 then
        local typeIconPath = TTGameUtils.GetTypeIconPath(self:getCardType())
        local typeIconNode = CreateImageNode(typeIconPath)
        typeIconNode:setName('typeNode')
        self:getViewData().typeLayer:addChild(typeIconNode)
    end
end


function TTGameCardNode:updateCardImage_()
    self:getViewData().imageLayer:removeAllChildren()
    if self:getCardId() > 0 then
        local cardDrawPath = TTGameUtils.GetCardDrawPath(self:getCardId())
        local cardDrawNode = CreateImageNode(cardDrawPath)
        cardDrawNode:setName('drawNode')
        self:getViewData().imageLayer:addChild(cardDrawNode)
    end

    self:getViewData().backFrameN:setVisible(not self:isQualitySP())
    self:getViewData().backFrameSP:setVisible(self:isQualitySP())
    self:getViewData().frontFrameN:setVisible(not self:isQualitySP())
    self:getViewData().frontFrameSP:setVisible(self:isQualitySP())
end


function TTGameCardNode:updateCardAttr_()
    local changedColor = '#FFD001'
    local initialColor = '#FFFFFF'
    local getColorFunc = function(changed)
        if self.isBlockedStatus_ then
            return initialColor
        else
            return changed and changedColor or initialColor
        end
    end
    local getAttrStrFunc = function(attrNum)
        return checkint(attrNum) > 9 and 'A' or tostring(attrNum)
    end
    display.commonLabelParams(self:getViewData().attrTLabel, {text = getAttrStrFunc(self:getAttrTop()),    color = getColorFunc(self:isAttrTopChanged())})
    display.commonLabelParams(self:getViewData().attrBLabel, {text = getAttrStrFunc(self:getAttrBottom()), color = getColorFunc(self:isAttrBottomChanged())})
    display.commonLabelParams(self:getViewData().attrLLabel, {text = getAttrStrFunc(self:getAttrLeft()),   color = getColorFunc(self:isAttrLeftChanged())})
    display.commonLabelParams(self:getViewData().attrRLabel, {text = getAttrStrFunc(self:getAttrRight()),  color = getColorFunc(self:isAttrRightChanged())})
end


function TTGameCardNode:updateGrayFilter_(isOpenFilter)
    self.isBlockedStatus_ = isOpenFilter == true
    local drawNode = self:getViewData().imageLayer:getChildByName('drawNode')
    local typeNode = self:getViewData().typeLayer:getChildByName('typeNode')
    if isOpenFilter then
        local grayFilter = GrayFilter:create()
        self:getViewData().backFrameN:setFilter(grayFilter)
        self:getViewData().backFrameSP:setFilter(grayFilter)
        self:getViewData().frontFrameN:setFilter(grayFilter)
        self:getViewData().frontFrameSP:setFilter(grayFilter)
        self:getViewData().attrFrame:setFilter(grayFilter)
        self:getViewData().starIcon:setFilter(grayFilter)
        if drawNode then drawNode:setFilter(grayFilter) end
        if typeNode then typeNode:setFilter(grayFilter) end
    else
        self:getViewData().backFrameN:clearFilter()
        self:getViewData().backFrameSP:clearFilter()
        self:getViewData().frontFrameN:clearFilter()
        self:getViewData().frontFrameSP:clearFilter()
        self:getViewData().attrFrame:clearFilter()
        self:getViewData().starIcon:clearFilter()
        if drawNode then drawNode:clearFilter() end
        if typeNode then typeNode:clearFilter() end
    end
    self:updateCardStar_()
    self:updateCardName_()
    self:updateCardAttr_()
end


return TTGameCardNode
