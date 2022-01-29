--[[
高级米饭心意活动view
--]]
local VIEW_SIZE = cc.size(1035, 637)
local ActivityLevelAdvanceChestView = class('ActivityLevelAdvanceChestView', function ()
    local node = CLayout:create(VIEW_SIZE)
    node.name = 'home.view.activity.levelAdvanceChest.ActivityLevelAdvanceChestView'
    node:enableNodeEvents()
    return node
end)

local CreateView = nil
local CreateBoxRewardLayer = nil

local RES_DIR = {
    GOOD_FRAME      = _res('ui/common/common_frame_goods_6.png'),
    BTN_TIPS        = _res('ui/common/common_btn_tips.png'),
    BTN_BG          = _res('ui/common/activity_mifan_by_ico.png'),
    BTN_ORANGE      = _res('ui/common/common_btn_orange.png'),
    BTN_DISABLE     = _res('ui/common/common_btn_orange_disable.png'),
    LINE            = _res('ui/home/commonShop/shop_sale_line.png'),
    BG_BOX          = _res('ui/home/activity/levelAdvanceChest/activity_bg_box.png'),
    BG_DOWN_BTN     = _res('ui/home/activity/levelAdvanceChest/activity_box_bg_down_btn.png'),
    BG_HH           = _res('ui/home/activity/levelAdvanceChest/activity_box_bg_hh.png'),
    BG_PT           = _res('ui/home/activity/levelAdvanceChest/activity_box_bg_hh_unlock.png'),
    BG_RULE         = _res('ui/home/activity/levelAdvanceChest/activity_box_bg_rule.png'),
    BG              = _res('ui/home/activity/levelAdvanceChest/activity_box_bg.jpg'),
    BTN_BOX_BUY     = _res('ui/home/activity/levelAdvanceChest/activity_box_btn_box_buy.png'),
    BTN_BOX_DEFAULT = _res('ui/home/activity/levelAdvanceChest/activity_box_btn_box_default.png'),
    BTN_BOX_UNLOCK  = _res('ui/home/activity/levelAdvanceChest/activity_box_btn_box_unlock.png'),
    BTN_BOX         = _res('ui/home/activity/levelAdvanceChest/activity_box_btn_box.png'),
    BOX_NAME_LV     = _res('ui/home/activity/levelAdvanceChest/activity_box_name_lv.png'),
    BOX_TITLE       = _res('ui/home/activity/levelAdvanceChest/activity_box_title.png'),
    BOX_UNLOCK      = _res('ui/home/activity/levelAdvanceChest/activity_box_unlock.png'),
    BOX_WORDS_LIGHT = _res('ui/home/activity/levelAdvanceChest/activity_box_words_light.png'),
    BOX_WORDS       = _res('ui/home/activity/levelAdvanceChest/activity_box_words.png'),
    BOX_FUTEJIA     = _res('ui/home/activity/levelAdvanceChest/activity_box_futejia.png'),

    -- spine
    SPINE_BG        = _spn('ui/home/activity/levelAdvanceChest/spine/bg'),
    SPINE_EFFECT    = _spn('ui/home/activity/levelAdvanceChest/spine/effect'),
    SPINE_XIANGZI   = _spn('ui/home/activity/levelAdvanceChest/spine/xiangzi'),
}

local BOX_STATE = {
	LOCK      = 0,
	NORMAL    = 1,
	PURCHASED = 2,
}

function ActivityLevelAdvanceChestView:ctor( ... )
    self.args = unpack({...})
    self:InitUI()
end
--[[
init ui
--]]
function ActivityLevelAdvanceChestView:InitUI()
    xTry(function ( )
        self.viewData_ = CreateView(VIEW_SIZE)
        self:addChild(self.viewData_.view)
	end, __G__TRACKBACK__)
end

function ActivityLevelAdvanceChestView:updateList(activityData, curSelectBoxIndex)
    local listLen = #activityData
    local viewData = self:getViewData()
    local gridView = viewData.gridView
    gridView:setCountOfCell(listLen)
    gridView:reloadData()

    local cellWidth = gridView:getSizeOfCell().width
    local offset = 0
    local listTotalW = curSelectBoxIndex * cellWidth

    if gridView:getContentSize().width < listTotalW then
        offset = gridView:getContentSize().width - listTotalW
    end
    gridView:setContentOffset(cc.p(offset, 0))
end

function ActivityLevelAdvanceChestView:updateBoxRewardLayer(boxRewardLayer, data)
    local viewData      = boxRewardLayer.viewData
    local name          = data.name
    if name then
        local titleLabel    = viewData.titleLabel
        display.commonLabelParams(titleLabel, {text = tostring(name)})
    end

    local rewards      = data.rewards
    local goodList     = viewData.goodList
    goodList:setRewards(rewards)


    local hasPurchased = checkint(data.hasPurchased)
    
    local btn           = viewData.btn
    local btnLabel      = viewData.btnLabel
    local priceLayer    = viewData.priceLayer
    local grayLayer     = viewData.grayLayer
    
    -- 如果已购买
    if hasPurchased > 0 then
        btnLabel:setVisible(true)
        display.commonLabelParams(btnLabel, {text = __('已购买'), color = '#ffe4b9'})

        priceLayer:setVisible(false)

        btn:setNormalImage(RES_DIR.BTN_BG)
        btn:setSelectedImage(RES_DIR.BTN_BG)
        btn:setScale(0.85)
        btn:setEnabled(false)

        grayLayer:setVisible(false)

    else
        local curLv = app.gameMgr:GetUserInfo().level
        local openLevel = checkint(data.openLevel)

        local isCanBuy      = checkint(data.status) <= 0 and curLv >= openLevel
        btn:setNormalImage(isCanBuy and RES_DIR.BTN_ORANGE or RES_DIR.BTN_DISABLE)
        btn:setSelectedImage(isCanBuy and RES_DIR.BTN_ORANGE or RES_DIR.BTN_DISABLE)
        btn:setScale(1)
        grayLayer:setVisible(not isCanBuy)
        btn:setEnabled(true)

        local price          = data.price
        local showPrice      = data.showPrice
        local discount       = data.discount
        local isShowDiscount = discount and checkint(discount) < 100
        priceLayer:setVisible(isShowDiscount)
        btnLabel:setVisible(not isShowDiscount)
        dump(data)
        local price , showPrice =  CommonUtils.GetCurrentAndOriginPriceDByPriceData({ channelProductId = data.channelProductId,  originalPrice = showPrice , price =  price })
        if isShowDiscount then
            -- 如果有折扣
            local priceLabel    = viewData.priceLabel
            local discountLabel = viewData.discountLabel
            display.commonLabelParams(priceLabel,    {color = "ffffff", fontSize= 20,  text =showPrice })
            display.commonLabelParams(discountLabel, {text = price})
        else
            display.commonLabelParams(btnLabel, {text = price })
        end
    end
end

function ActivityLevelAdvanceChestView:updateCell(viewData, data, isSelect)
    local nameLabel = viewData.nameLabel
    local openLevel = data.openLevel
    display.commonLabelParams(nameLabel, {text = string.format(__('%s级'), tostring(openLevel))})

    local boxState = data.boxState
    self:updateCellState(viewData, boxState, isSelect)
end

function ActivityLevelAdvanceChestView:updateCellState(viewData, boxState, isSelect)
    local boxImg    = viewData.boxImg
    -- local nameImg   = viewData.nameImg
    
    local unlockImg = viewData.unlockImg
    unlockImg:setVisible(BOX_STATE.LOCK == boxState)

    local purchasedBgLayer = viewData.purchasedBgLayer
    purchasedBgLayer:setVisible(BOX_STATE.PURCHASED == boxState)

    local img = nil
    if BOX_STATE.NORMAL == boxState then
        img = isSelect and RES_DIR.BTN_BOX or RES_DIR.BTN_BOX_DEFAULT
    else
        if BOX_STATE.LOCK == boxState then
            img = RES_DIR.BTN_BOX_UNLOCK
        elseif BOX_STATE.PURCHASED == boxState then
            img = RES_DIR.BTN_BOX_BUY
        end
    end
    img = img or RES_DIR.BTN_BOX_UNLOCK
    boxImg:setNormalImage(img)
    boxImg:setSelectedImage(img)
end

function ActivityLevelAdvanceChestView:CreateCell(size)
    local cell = CTableViewCell:new()
    
    local view  = display.newLayer(size.width / 2, size.height / 2, {ap = display.CENTER, size = size})
    cell:addChild(view)

    local boxImg = display.newButton(size.width / 2, 0, {ap = display.CENTER_BOTTOM, n = RES_DIR.BTN_BOX_UNLOCK})
    view:addChild(boxImg)

    local unlockImg = display.newImageView(RES_DIR.BOX_UNLOCK, size.width / 2, 54, {ap = display.CENTER})
    view:addChild(unlockImg)    

    local nameImg = display.newImageView(RES_DIR.BOX_NAME_LV, size.width / 2, 0, {ap = display.CENTER_BOTTOM})
    view:addChild(nameImg)

    local nameLabel = display.newLabel(60, 15, fontWithColor(16))
    nameImg:addChild(nameLabel)

    -- 已购买
    local purchasedBgLayerSize = cc.size(78.3, 38.4)
    local purchasedBgLayer = display.newLayer(size.width / 2, 54, {size = purchasedBgLayerSize, ap = display.CENTER})
    view:addChild(purchasedBgLayer)

    local purchasedBg = display.newImageView(RES_DIR.BTN_BG, purchasedBgLayerSize.width / 2, purchasedBgLayerSize.height / 2, {ap = display.CENTER})
    purchasedBg:setScale(0.58)
    purchasedBgLayer:addChild(purchasedBg)

    local purchasedLabel = display.newLabel(purchasedBg:getPositionX(), purchasedBg:getPositionY(), 
        fontWithColor(9, {text = __('已购买')}))
    purchasedBgLayer:addChild(purchasedLabel)

    purchasedBgLayer:setVisible(false)

    cell.viewData = {
        boxImg = boxImg,
        unlockImg = unlockImg,
        nameImg = nameImg,
        nameLabel = nameLabel,
        purchasedBgLayer = purchasedBgLayer,
    }
    return cell
end

CreateView = function (size)
    local view = display.newLayer(size.width / 2, size.height / 2, {size = size, ap = display.CENTER})

    view:addChild(display.newImageView(RES_DIR.BG, size.width / 2, size.height / 2, {ap = display.CENTER}))
    
    -- bg spine ani
    local spineJson = RES_DIR.SPINE_BG.json
    local spineAtlas = RES_DIR.SPINE_BG.atlas
    local paradiseLayer = display.newLayer(size.width / 2, size.height / 2, {size = size, ap = display.CENTER})
    view:addChild(paradiseLayer)
    if CommonUtils.checkIsExistsSpine(spineJson,spineAtlas) then
        local clipper = cc.ClippingNode:create()
        clipper:setContentSize(size)
        clipper:setStencil(display.newImageView(RES_DIR.BG, size.width / 2, size.height / 2, {ap = display.CENTER}))
        clipper:setInverted(false)

        display.commonUIParams(clipper, {ap = display.CENTER, po = cc.p(size.width / 2, size.height / 2)})
        paradiseLayer:addChild(clipper)

        local spine = sp.SkeletonAnimation:create(spineJson, spineAtlas, 1)
        spine:update(0)
        spine:addAnimation(0, 'idle', true)
        spine:setPosition(cc.p(size.width / 2 - 125, size.height / 2))
        clipper:addChild(spine)

    end

    -- role img
    local roleImg = display.newImageView(RES_DIR.BOX_FUTEJIA, 5, 4, {ap = display.LEFT_BOTTOM})
    view:addChild(roleImg)
    roleImg:setVisible(false)

    local roleSpine = nil
    local roleSpineJson = RES_DIR.SPINE_EFFECT.json
    local roleSpineAtlas = RES_DIR.SPINE_EFFECT.atlas
    if CommonUtils.checkIsExistsSpine(roleSpineJson,roleSpineAtlas) then
        roleSpine = sp.SkeletonAnimation:create(roleSpineJson, roleSpineAtlas, 1)
        roleSpine:update(0)
        roleSpine:setPosition(cc.p(size.width / 2, size.height / 2))
        
        view:addChild(roleSpine)
    end

    -- rule
    local ruleBg = display.newImageView(RES_DIR.BG_RULE, size.width / 2, size.height - 2, {ap = display.CENTER_TOP})
    view:addChild(ruleBg)
    local ruleBtn = display.newButton(7, size.height - 20.5, {n = RES_DIR.BTN_TIPS, ap = display.LEFT_CENTER})
    view:addChild(ruleBtn)

    local ruleTipLabel = display.newLabel(60, size.height - 8, fontWithColor(9, {w = 970, ap  = display.LEFT_TOP, text = __('想知道藏在手提箱中的秘密吗？御侍每次只能选购其中一个手提箱，且无法重来。请慎重选择哦！')}))
    view:addChild(ruleTipLabel)

    local boxWordLight = display.newImageView(RES_DIR.BOX_WORDS_LIGHT, 183, 200, {ap = display.CENTER})
    view:addChild(boxWordLight)

    local boxWord = display.newImageView(RES_DIR.BOX_WORDS, 183, 200, {ap = display.CENTER})
    view:addChild(boxWord)

    -- box spine ani
    local spineJson = RES_DIR.SPINE_XIANGZI.json
    local spineAtlas = RES_DIR.SPINE_XIANGZI.atlas
    local boxSpine = nil
    if CommonUtils.checkIsExistsSpine(spineJson,spineAtlas) then
        boxSpine = sp.SkeletonAnimation:create(spineJson, spineAtlas, 1)
        boxSpine:update(0)
        
        boxSpine:setPosition(cc.p(size.width / 2, size.height / 2))
        view:addChild(boxSpine)
    end

    local boxBgLayerSize = cc.size(693, 480)
    local boxBgLayer = display.newLayer(size.width - 352 - 10, size.height / 2 + 30, 
        {size = boxBgLayerSize, ap = display.CENTER})
    -- boxBgLayer:setVisible(false)
    view:addChild(boxBgLayer)

    local boxTipBg = display.newImageView(RES_DIR.BOX_TITLE, boxBgLayerSize.width / 2 + 8, boxBgLayerSize.height - 29, {ap = display.CENTER})
    boxBgLayer:addChild(boxTipBg, 1)
    boxTipBg:setVisible(false)

    local boxTipLabel = display.newLabel(boxBgLayerSize.width / 2 + 9, boxBgLayerSize.height - 28, 
        fontWithColor(6, {text = __('只能选择一种档位奖励') , color = '#ffba27', ap = display.CENTER}))
    boxBgLayer:addChild(boxTipLabel, 1)
    boxTipLabel:setVisible(false)

    local boxRewardLayerPosConf = {
        cc.p(198, boxBgLayerSize.height / 2 - 5),
        cc.p(516, boxBgLayerSize.height / 2 - 5)
    }
    local boxRewardLayers = {}
    for i, pos in ipairs(boxRewardLayerPosConf) do
        local boxRewardLayer = CreateBoxRewardLayer()
        display.commonUIParams(boxRewardLayer, {po = pos})
        boxBgLayer:addChild(boxRewardLayer)
        boxRewardLayer:setVisible(false)

        table.insert(boxRewardLayers, boxRewardLayer)
    end
    
    view:addChild(display.newImageView(RES_DIR.BG_DOWN_BTN, size.width / 2, 4, {ap = display.CENTER_BOTTOM}))

    local gridViewSize = cc.size(size.width - 10, 118)
    local gridViewCellSize = cc.size(152, 188)
    local gridView = CTableView:create(gridViewSize)
    gridView:setDirection(eScrollViewDirectionHorizontal)
    gridView:setSizeOfCell(gridViewCellSize)
    display.commonUIParams(gridView, {ap = display.LEFT_BOTTOM, po = cc.p(5, 12)})
	-- gridView:setBackgroundColor(cc.c4b(178, 63, 88, 100))
    view:addChild(gridView, 10)
    gridView:setVisible(false)

    return {
        view                    = view,
        ruleBtn                 = ruleBtn,
        boxTipBg                = boxTipBg,
        boxTipLabel             = boxTipLabel,
        boxRewardLayers         = boxRewardLayers,
        gridView                = gridView,
        roleImg                 = roleImg,
        roleSpine               = roleSpine,
        boxSpine                = boxSpine,
    }

end

CreateBoxRewardLayer = function ()
    local layerSize = cc.size(262 + 36, 380 + 36)
    local layer = display.newLayer(0, 0, {size = layerSize, ap = display.CENTER})

    local grayLayerSize = cc.size(292, 333)
    local grayLayer = display.newLayer(layerSize.width / 2 - 1, layerSize.height - 333 / 2, {size = grayLayerSize, ap = display.CENTER})
    layer:addChild(grayLayer, 10)
    local garyBg = display.newImageView(RES_DIR.BG_PT, grayLayerSize.width / 2, grayLayerSize.height / 2, {ap = display.CENTER, scale9 = true})
    grayLayer:addChild(garyBg)
    grayLayer:setVisible(false)

    local titleLabel = display.newLabel(layerSize.width / 2, layerSize.height - 30, 
        fontWithColor(2, {ap = display.CENTER, color = '#b12a06', fontSize = 22}))
    layer:addChild(titleLabel)

    local goodListLayerSize = cc.size(278, 272)

    local goodList = require('common.CommonGoodList').new({
        size = goodListLayerSize,
        cellSize = cc.size(goodListLayerSize.width / 3, goodListLayerSize.height / 3),
        col = 3,
        goodScale = 0.75,
        scrollCondition = 9,
        showAmount = true,
        notRefresh = true,
        isDisableFilter = true
    })
    display.commonUIParams(goodList, {ap = display.CENTER_TOP, po = cc.p(layerSize.width / 2, layerSize.height - 50)})
    -- goodList:setBackgroundColor(cc.c4b(23, 67, 128, 128))
    layer:addChild(goodList)

    local btn = display.newButton(layerSize.width / 2, 50, {ap = display.CENTER, n = RES_DIR.BTN_ORANGE})
    display.commonLabelParams(btn, fontWithColor(7, {fontSize = 22, color = '#ffe4b9', text = __('已购买')}))
    layer:addChild(btn)

    local btnLabel = btn:getLabel()
    btnLabel:setVisible(false)
    
    local priceLayerSize = cc.size(123, 59)
    local priceLayer = display.newLayer(btn:getPositionX(), btn:getPositionY(), {size = priceLayerSize, ap = display.CENTER})
    priceLayer:setCascadeOpacityEnabled(true)
    priceLayer:setVisible(false)
    layer:addChild(priceLayer)

    local priceLabel = display.newLabel(priceLayerSize.width / 2, 42, fontWithColor(7, {fontSize = 20, ap = display.CENTER, outline = '#5b3c25', outlineSize = 1}))
    priceLayer:addChild(priceLabel)

    local priceLine = display.newImageView(RES_DIR.LINE, priceLayerSize.width / 2, priceLabel:getPositionY(), {ap = display.CENTER, outline = '#5b3c25', outlineSize = 1})
    priceLayer:addChild(priceLine)

    local discountLabel = display.newLabel(priceLayerSize.width / 2, 20, fontWithColor(7, {fontSize = 22, ap = display.CENTER, outline = '#5b3c25', outlineSize = 1}))
    priceLayer:addChild(discountLabel)

    layer.viewData = {
        grayLayer     = grayLayer,
        titleLabel    = titleLabel,
        goodList      = goodList,
        btn           = btn,
        btnLabel      = btnLabel,
        priceLayer    = priceLayer,
        priceLabel    = priceLabel,
        discountLabel = discountLabel,
    }
    return layer
end

function ActivityLevelAdvanceChestView:getViewData()
    return self.viewData_
end

--[[
创建手提箱奖励动画列表
--]]
function ActivityLevelAdvanceChestView:createBoxRewardLayerAniList()
    local anis = {}
    local viewData = self:getViewData()
    local boxRewardLayers = viewData.boxRewardLayers
    for i, boxRewardLayer in ipairs(boxRewardLayers) do
        local layerViewData = boxRewardLayer.viewData
        local titleLabel    = layerViewData.titleLabel
        local btn           = layerViewData.btn
        local priceLayer    = layerViewData.priceLayer
        boxRewardLayer:setVisible(false)
        titleLabel:setOpacity(0)
        btn:setOpacity(0)
        priceLayer:setOpacity(0)

        local goodList = layerViewData.goodList
        local cellActionList = goodList:getCellsActionList()

        table.insert(cellActionList, cc.Sequence:create({
            cc.DelayTime:create(6 / 30),
            cc.Spawn:create({
                cc.TargetedAction:create(titleLabel, cc.EaseOut:create(cc.FadeIn:create(5 / 30), 5 / 30)),
                cc.TargetedAction:create(btn, cc.EaseOut:create(cc.FadeIn:create(5 / 30), 5 / 30)),
                cc.TargetedAction:create(priceLayer, cc.EaseOut:create(cc.FadeIn:create(5 / 30), 5 / 30)),
            })
        }))

        local ac = cc.TargetedAction:create(boxRewardLayer, cc.Sequence:create({
            cc.DelayTime:create(10 / 30),
            cc.CallFunc:create(function ()
                boxRewardLayer:setVisible(true)
                -- goodList:showCellsAction()
            end),
            cc.Spawn:create(cellActionList)
            -- cc.DelayTime:create(6 / 30),
            -- cc.Spawn:create({
            --     cc.TargetedAction:create(titleLabel, cc.EaseOut:create(cc.FadeIn:create(5 / 30), 5 / 30)),
            --     cc.TargetedAction:create(btn, cc.EaseOut:create(cc.FadeIn:create(5 / 30), 5 / 30)),
            --     cc.TargetedAction:create(priceLayer, cc.EaseOut:create(cc.FadeIn:create(5 / 30), 5 / 30)),
            -- })
        }))

        table.insert(anis, ac)
    end
    return anis
end

--[[
创建打开手提箱动画列表
--]]
function ActivityLevelAdvanceChestView:createOpenBoxAniList()
    local viewData    = self:getViewData()
    local boxTipLabel = viewData.boxTipLabel
    boxTipLabel:setVisible(false)
    local boxSpine    = viewData.boxSpine
    if boxSpine then
        boxSpine:update(0)
        boxSpine:setToSetupPose()
    end
    display.commonUIParams(boxTipLabel, {po = cc.p(boxTipLabel:getPositionX() + 40, boxTipLabel:getPositionY() + 50)})

    local boxTipBg    = viewData.boxTipBg
    boxTipBg:setVisible(true)
    boxTipBg:setScale(0.2)
    local acitonList = {
        cc.CallFunc:create(function ()
            if boxSpine then
                boxSpine:setAnimation(0, 'idle', false)
            end
        end),
        cc.TargetedAction:create(boxTipBg, cc.Sequence:create({
            cc.EaseOut:create(cc.ScaleTo:create(6 / 30, 1.2, 1.2), 6/ 30),
            cc.EaseIn:create(cc.ScaleTo:create(4 / 30, 1, 1), 4/ 30),
            
        })),
        cc.TargetedAction:create(boxTipLabel, cc.Sequence:create({
            cc.DelayTime:create(6 / 30),
            cc.CallFunc:create(function ()
                boxTipLabel:setVisible(true)
            end),
            cc.TargetedAction:create(boxTipLabel, cc.EaseOut:create(cc.MoveBy:create(4 / 30, cc.p(-40, -50)), 4 / 30)),
        })),
    }

    local boxBgLayer = viewData.boxBgLayer

    local boxRewardLayerAniList = self:createBoxRewardLayerAniList()
    for i, v in ipairs(boxRewardLayerAniList) do
        table.insert(acitonList, v)
    end

    return acitonList
end

--[[
创建底部手提箱列表动画列表
--]]
function ActivityLevelAdvanceChestView:createListAniList()
    local viewData = self:getViewData()
    local gridView = viewData.gridView
    local cells    = gridView:getCells()
    local size     = gridView:getContentSize()
    gridView:setVisible(true)

    local actionList = {}

    for i, cell in ipairs(cells) do
        display.commonUIParams(cell, {po = cc.p(cell:getPositionX() + size.width, cell:getPositionY())})

        table.insert(actionList, cc.TargetedAction:create(cell, cc.Sequence:create({
            cc.DelayTime:create((i - 1) * 2 / 30),
            cc.MoveBy:create(20 / 30, cc.p(size.width * -1, 0))
        })))
    end

    return actionList
end

function ActivityLevelAdvanceChestView:showEnterAction(cb)
    local viewData    = self:getViewData()
    local roleImg     = viewData.roleImg
    roleImg:setVisible(true)
    roleImg:setOpacity(0)
    -- local gridView = viewData.gridView
    -- gridView:setVisible(true)
    -- gridView:setOpacity(0)

    local roleSpine   = viewData.roleSpine
    local acitonList = {} or self:createOpenBoxAniList()
    table.insert(acitonList, cc.TargetedAction:create(roleImg, cc.FadeIn:create(10 / 30)))
    -- table.insert(acitonList, cc.TargetedAction:create(gridView, cc.FadeIn:create(10 / 30)))
    table.insert(acitonList, cc.CallFunc:create(function ()
        roleSpine:addAnimation(0, 'idle', true)
    end))

    self:runAction(cc.Sequence:create({
        cc.Spawn:create(acitonList),
        cc.DelayTime:create(10 / 30),
        cc.CallFunc:create(function ()
            if cb then
                cb()
            end
        end)
    }))
end

function ActivityLevelAdvanceChestView:showUIAction(cb, isInit)

    local acitonList = self:createOpenBoxAniList()
    if isInit then
        local aniList = self:createListAniList()
        for i, v in ipairs(aniList) do
            table.insert(acitonList, v)
        end
    end
   
    self:runAction(cc.Sequence:create({
        cc.Spawn:create(acitonList),
        cc.CallFunc:create(function ()
            if cb then
                cb()
            end
        end)
    }))
end

return ActivityLevelAdvanceChestView