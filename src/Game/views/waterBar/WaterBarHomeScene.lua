--[[
 * author : kaishiqi
 * descpt : 水吧 - 主页场景
]]
local RemindIcon        = require('common.RemindIcon')
local WaterBarHomeScene = class('WaterBarHomeScene', require('Frame.GameScene'))

local RES_DICT = {
    --             = top
    COM_BACK_BTN   = _res('ui/common/common_btn_back.png'),
    COM_TITLE_BAR  = _res('ui/common/common_title.png'),
    COM_TIPS_ICON  = _res('ui/common/common_btn_tips.png'),
    BTN_CUSTOMERS  = _res('ui/waterBar/home/bar_icon_frequenter.png'),
    BTN_STORE      = _res('ui/waterBar/home/bar_icon_suppliers.png'),
    TOP_BOARD      = _res('ui/waterBar/home/restaurant_bg_board.png'),
    --             = center
    BG_IMAGE_1     = _res('ui/waterBar/home/bar_bg_1.png'),
    BG_IMAGE_2     = _res('ui/waterBar/home/bar_bg_2.jpg'),
    BG_IMAGE_3     = _res('ui/waterBar/home/bar_bg_3.jpg'),
    DRINK_SHADOW   = _res('ui/waterBar/home/bar_shadows_bg.png'),
    NEW_STORY_ICON = _res('ui/waterBar/home/bar_facial_1.png'),
    OLD_STORY_ICON = _res('ui/waterBar/home/bar_facial_2.png'),
    --             = bottom
    NAME_FRAME     = _res('ui/cards/propertyNew/card_bar_bg.png'),
    BTN_MARKET     = _res('ui/waterBar/home/bar_icon_markets.png'),
    BTN_PUTAWAY    = _res('ui/waterBar/home/bar_icon_list.png'),
    BTN_INFO       = _res('ui/waterBar/home/bar_icon_Inf.png'),
    BTN_BREW       = _res('ui/waterBar/home/bar_icon_bartending.png'),
    BTN_MAKE       = _res('ui/waterBar/home/bar_icon_formula.png'),
    BTN_RESEARCH   = _res('ui/waterBar/home/bar_icon_freedom.png'),
    BTN_BAG        = _res('ui/waterBar/home/bar_icon_bag.png'),
    ICON_LOCK      = _res('ui/common/common_ico_lock.png'),
    --             = other
    CLOSING_CLINE  = _res('ui/waterBar/home/bar_img_feng.png'),
    CLOSING_FRAME  = _res('ui/waterBar/home/bar_reserve_bg.png'),
    WAITING_FRAME  = _res('ui/waterBar/home/bar_reserve_bg1.png'),
    WAITING_SPINE  = _spn('ui/waterBar/home/bar_reserve_none'),
    CLOSING_SPINE  = _spn('ui/waterBar/home/bar_reserve_preparations'),
    OPENING_SPINE  = _spn('ui/waterBar/home/bar_reserve_start'),
    OPENING_FRAME  = _res('ui/common/common_btn_tab_selected.png'),
}

local CreateView        = nil
local CreateBrewView    = nil
local CreateOpeningView = nil
local CreateClosingView = nil
local CreateWaitingView = nil


function WaterBarHomeScene:ctor(args)
    self.super.ctor(self, 'Game.views.waterBar.WaterBarHomeScene')

    -- create view
    self.viewData_ = CreateView()
    self:addChild(self.viewData_.view)

    self.closingViewData_ = CreateClosingView()
    self:addChild(self.closingViewData_.view)
    self.closingViewData_.view:setVisible(false)
    
    self.waitingViewData_ = CreateWaitingView()
    self:addChild(self.waitingViewData_.view)
    self.waitingViewData_.view:setVisible(false)
    
    self.openingViewData_ = CreateOpeningView()
    self:addChild(self.openingViewData_.view)
    self.openingViewData_.view:setVisible(false)

    self.brewViewData_ = CreateBrewView(self:getViewData().brewBtn)
    self:addChild(self.brewViewData_.view)
    self.brewViewData_.view:setVisible(false)
end


CreateView = function()
    local view = display.newLayer()
    local size = view:getContentSize()
    local cpos = cc.p(size.width/2, size.height/2)

    -- block layer
    view:addChild(display.newLayer(0, 0, {color = cc.c4b(0,0,0,100), enable = true}))

    -- bg image
    local openingBgImg = display.newImageView(RES_DICT.BG_IMAGE_2, cpos.x, cpos.y)
    local closingBgImg = display.newImageView(RES_DICT.BG_IMAGE_3, cpos.x, cpos.y)
    view:addChild(closingBgImg)
    view:addChild(openingBgImg)
    openingBgImg:setVisible(false)


    ------------------------------------------------- [center]
    local centerLayer = display.newLayer()
    view:addChild(centerLayer)

    -- counter postion
    local CUSTOMER_GAP_W   = 240
    local CUSTOMER_BAR_MAX = FOOD.WATER_BAR.DEFINE.CUSTOMER_BAR_MAX
    local CUSTOMER_OFFSETX = (CUSTOMER_BAR_MAX/2-0.5) * CUSTOMER_GAP_W
    local counterBasePos   = cc.p(cpos.x - CUSTOMER_OFFSETX, cpos.y - 100)
    local drinkCellList    = {}
    local drinkShadowList  = {}
    local customerCellList = {}
    local halfCustomerIndex = math.ceil(CUSTOMER_BAR_MAX/2)
    for i = 1, CUSTOMER_BAR_MAX do
        local customerCellPos  = cc.p(counterBasePos.x + (i-1)*CUSTOMER_GAP_W, counterBasePos.y)
        local drinkCellNode    = display.newLayer(customerCellPos.x, customerCellPos.y - 95, {size = cc.size(144, 144), ap = display.CENTER, color1 = cc.r4b(50)})
        local drinkShadowNode  = display.newImageView(RES_DICT.DRINK_SHADOW, customerCellPos.x, customerCellPos.y - 135)
        local customerCellNode = display.newLayer(customerCellPos.x, customerCellPos.y + 0, {size = cc.size(230, 320), ap = display.CENTER, color = cc.r4b(0), enable = true})
        centerLayer:addChild(customerCellNode)
        centerLayer:addChild(drinkCellNode, 10)
        centerLayer:addChild(drinkShadowNode, 1)

        -- 按照 {5,3,1,2,4} 从中间劈开左右各一个的顺序排序
        local targetIndex = i
        local offsetIndex = 0
        if halfCustomerIndex - i >= 0 then
            offsetIndex = halfCustomerIndex-(i-1)
        else
            offsetIndex = i-halfCustomerIndex
        end
        targetIndex = math.abs(halfCustomerIndex - i) + offsetIndex
        drinkCellList[targetIndex] = drinkCellNode
        drinkShadowList[targetIndex] = drinkShadowNode
        customerCellList[targetIndex] = customerCellNode
    end

    -- fg image
    local openingFgImg = display.newImageView(RES_DICT.BG_IMAGE_1, cpos.x, cpos.y)
    local closingFgImg = display.newLayer(0, 0, {color = cc.c4b(0,0,0,150)})
    centerLayer:addChild(openingFgImg)
    centerLayer:addChild(closingFgImg)
    openingFgImg:setVisible(false)


    ------------------------------------------------- [top]
    local topLayer = display.newLayer()
    view:addChild(topLayer)

    -- back button
    local backBtn = display.newButton(display.SAFE_L + 75, size.height - 52, {n = RES_DICT.COM_BACK_BTN})
    topLayer:addChild(backBtn)

    -- title button
    local titleBtn = display.newButton(display.SAFE_L + 120, size.height + 2, {n = RES_DICT.COM_TITLE_BAR, ap = display.LEFT_TOP})
    display.commonLabelParams(titleBtn, fontWithColor(1, {text = __('水吧'), offset = cc.p(0,-10)}))
    titleBtn:addList(ui.image({img = RES_DICT.COM_TIPS_ICON})):alignTo(nil, ui.rc, {offsetX = -20, offsetY = -10})
    topLayer:addChild(titleBtn)


    -- top board
    local topBoardLayer = display.newLayer(display.SAFE_R - 20, size.height, {bg = RES_DICT.TOP_BOARD, ap = display.RIGHT_TOP})
    local topBoardSize  = topBoardLayer:getContentSize()
    topLayer:addChild(topBoardLayer)

    local customersBtn = display.newButton(topBoardSize.width/2 - 50, topBoardSize.height/2 + 10, {n = RES_DICT.BTN_CUSTOMERS})
    display.commonLabelParams(customersBtn, fontWithColor(14, {text = __('回头客'), offset = cc.p(0, -55)}))
    RemindIcon.addRemindIcon({parent = customersBtn , tag = RemindTag.WARTER_BAR_FRE_POINT_REWARD , po = cc.p(90, 90)})
    topBoardLayer:addChild(customersBtn)

    local storeBtn = display.newButton(topBoardSize.width/2 + 50, customersBtn:getPositionY(), {n = RES_DICT.BTN_STORE})
    display.commonLabelParams(storeBtn, fontWithColor(14, {text = __('商店'), offset = cc.p(0, -55)}))
    topBoardLayer:addChild(storeBtn)


    ------------------------------------------------- [bottom]
    local bottomLayer = display.newLayer()
    view:addChild(bottomLayer)

    local funcBtnDefines = {
        {name = __('调制'), icon = RES_DICT.BTN_BREW},
        {name = __('市场'), icon = RES_DICT.BTN_MARKET},
        {name = __('清单'), icon = RES_DICT.BTN_PUTAWAY},
        {name = __('信息'), icon = RES_DICT.BTN_INFO},
        {name = __('背包'), icon = RES_DICT.BTN_BAG},
    }

    local funcBtnList = {}
    for index, btnDefine in ipairs(funcBtnDefines) do
        local funcBtn = display.newButton(display.SAFE_R - 75 - (index-1) * 130, 70, {n = btnDefine.icon})
        local nameBar = display.newButton(0, 0, {n = RES_DICT.NAME_FRAME, enable = false, scale9 = true, capInsets = cc.rect(55,5,12,18)})
        display.commonLabelParams(nameBar, fontWithColor(14, {text = btnDefine.name, paddingW = 40}))
        nameBar:setPosition(cc.pAdd(utils.getLocalCenter(funcBtn), cc.p(0, -42)))
        funcBtn:addChild(nameBar)
        bottomLayer:addChild(funcBtn)
        funcBtnList[index] = funcBtn
    end

    
    return {
        view               = view,
        topLayer           = topLayer,
        topLayerHidePos    = cc.p(topLayer:getPositionX(), 100),
        topLayerShowPos    = cc.p(topLayer:getPosition()),
        titleBtn           = titleBtn,
        titleBtnHidePos    = cc.p(titleBtn:getPositionX(), titleBtn:getPositionY() + 190),
        titleBtnShowPos    = cc.p(titleBtn:getPosition()),
        backBtn            = backBtn,
        topBoardLayer      = topBoardLayer,
        topBoardHidePos    = cc.p(topBoardLayer:getPositionX(), topBoardLayer:getPositionY() + topBoardSize.height),
        topBoardShowPos    = cc.p(topBoardLayer:getPosition()),
        customersBtn       = customersBtn,
        storeBtn           = storeBtn,
        --                 = center
        openingBgImg       = openingBgImg,
        closingBgImg       = closingBgImg,
        openingFgImg       = openingFgImg,
        closingFgImg       = closingFgImg,
        drinkCellList      = drinkCellList,
        drinkShadowList    = drinkShadowList,
        customerCellList   = customerCellList,
        --                 = bottom
        bottomLayer        = bottomLayer,
        bottomLayerHidePos = cc.p(bottomLayer:getPositionX(), bottomLayer:getPositionY() - 120),
        bottomLayerShowPos = cc.p(bottomLayer:getPosition()),
        brewBtn            = funcBtnList[1],
        marketBtn          = funcBtnList[2],
        putawayBtn         = funcBtnList[3],
        infoBtn            = funcBtnList[4],
        bagBtn             = funcBtnList[5],
    }
end


CreateBrewView = function(baseNode)
    local view    = display.newLayer()
    local size    = view:getContentSize()
    local basePos = cc.p(baseNode:getPosition())

    local blockLayer = display.newLayer(0, 0, {color = cc.r4b(0), enable = true})
    view:addChild(blockLayer)
    
    local bgLayer = display.newLayer(0, 0, {color = cc.c4b(0,0,0,100)})
    view:addChild(bgLayer)

    local makeBtn = display.newButton(basePos.x, basePos.y + 135, {n = RES_DICT.BTN_MAKE})
    display.commonLabelParams(makeBtn, fontWithColor(14, {text = __('配方调制'), offset = cc.p(0, -40)}))
    view:addChild(makeBtn)
    
    local researchBtn = display.newButton(basePos.x - 120, makeBtn:getPositionY(), {n = RES_DICT.BTN_RESEARCH})
    display.commonLabelParams(researchBtn, fontWithColor(14, {text = __('自由调制'), offset = cc.p(0, -40)}))
    view:addChild(researchBtn)

    local researchLock = display.newImageView(RES_DICT.ICON_LOCK)
    researchLock:setPosition(utils.getLocalCenter(researchBtn))
    researchBtn:addChild(researchLock)

    return {
        view               = view,
        blockLayer         = blockLayer,
        bgLayer            = bgLayer,
        bgLayerShowAlpha   = 100,
        bgLayerHideAlpha   = 0,
        makeBtn            = makeBtn,
        makeBtnShowPos     = cc.p(makeBtn:getPosition()),
        makeBtnHidePos     = basePos,
        researchBtn        = researchBtn,
        researchLock       = researchLock,
        researchBtnShowPos = cc.p(researchBtn:getPosition()),
        researchBtnHidePos = basePos,
    }
end


CreateOpeningView = function()
    local view = display.newLayer()
    local size = view:getContentSize()
    local cpos = cc.p(size.width/2, size.height/2)

    local openingSpine = display.newPathSpine(RES_DICT.OPENING_SPINE)
    openingSpine:setPosition(cc.p(cpos.x, cpos.y))
    -- openingSpine:setAnimation(0, 'play', false)
    view:addChild(openingSpine)

    local closingIntro = display.newLabel(cpos.x, cpos.y - 30, fontWithColor(1, {fontSize = 90, color = '#b85428', text = __('开 始 营 业')}))
    view:addChild(closingIntro)

    local countDownSize  = cc.size(display.SAFE_L + 250, 80)
    local countDownFrame = display.newImageView(RES_DICT.OPENING_FRAME, display.width, 70, {scale9 = true, size = countDownSize, ap = display.LEFT_CENTER, scaleX = -1})
    view:addChild(countDownFrame)

    local countdownInfoY = countDownFrame:getPositionY()
    local countdownInfoX = countDownFrame:getPositionX() - countDownSize.width/2
    local countdownIntro = display.newLabel(countdownInfoX, countdownInfoY + 15, fontWithColor(5, {fontSize = 24, color = '#b58575', text = __('距离打烊剩余')}))
    view:addChild(countdownIntro)

    local countdownLabel = display.newLabel(countdownInfoX, countdownInfoY - 15, fontWithColor(1, {fontSize = 24, color = '#572c1b', text = '--:--:--'}))
    view:addChild(countdownLabel)

    return {
        view           = view,
        closingIntro   = closingIntro,
        countdownLabel = countdownLabel,
        showSpine = function()
            view:stopAllActions()
            closingIntro:setOpacity(0)
            closingIntro:setVisible(true)
            openingSpine:setVisible(true)
            openingSpine:setAnimation(0, 'play', false)
            view:runAction(cc.Sequence:create(
                cc.DelayTime:create(0.2),
                cc.TargetedAction:create(closingIntro, cc.FadeIn:create(0.2)),
                cc.DelayTime:create(0.8),
                cc.TargetedAction:create(closingIntro, cc.FadeOut:create(0.2)),
                cc.TargetedAction:create(closingIntro, cc.Hide:create()),
                cc.TargetedAction:create(openingSpine, cc.Hide:create())
            ))
        end,
        hideSpine = function()
            view:stopAllActions()
            closingIntro:setVisible(false)
            openingSpine:setVisible(false)
        end
    }
end


CreateClosingView = function()
    local view = display.newLayer()
    local size = view:getContentSize()
    local cpos = cc.p(size.width/2, size.height/2)

    view:addChild(display.newImageView(RES_DICT.CLOSING_FRAME, cpos.x, cpos.y))
    view:addChild(display.newImageView(RES_DICT.CLOSING_CLINE, cpos.x, cpos.y - 25))
    view:add(ui.label({p = cc.rep(cpos, 0, -175), fnt = FONT.D3, text = __('请在开业前完成饮品【调制】，并在【清单】上架')}))

    local closingSpine = display.newPathSpine(RES_DICT.CLOSING_SPINE)
    closingSpine:setPosition(cc.p(cpos.x, cpos.y))
    closingSpine:setAnimation(0, 'idle', true)
    view:addChild(closingSpine)

    local closingIntro = display.newLabel(cpos.x, cpos.y + 5, fontWithColor(1, {fontSize = 36, color = '#572c1b', text = __('水吧打扫整备中…')}))
    view:addChild(closingIntro)

    local countdownIntro = display.newLabel(cpos.x, cpos.y - 50, fontWithColor(5, {fontSize = 24, color = '#b58575', text = __('距离开业剩余')}))
    view:addChild(countdownIntro)

    local countdownLabel = display.newLabel(cpos.x, cpos.y - 80, fontWithColor(1, {fontSize = 24, color = '#572c1b', text = '--:--:--'}))
    view:addChild(countdownLabel)

    return {
        view           = view,
        countdownLabel = countdownLabel,
    }
end


CreateWaitingView = function()
    local view = display.newLayer()
    local size = view:getContentSize()
    local cpos = cc.p(size.width/2, size.height/2)

    view:addChild(display.newImageView(RES_DICT.WAITING_FRAME, cpos.x, cpos.y))
    view:addChild(display.newImageView(RES_DICT.CLOSING_CLINE, cpos.x, cpos.y - 25))

    local waitingSpine = display.newPathSpine(RES_DICT.WAITING_SPINE)
    waitingSpine:setPosition(cc.p(cpos.x, cpos.y))
    waitingSpine:setAnimation(0, 'idle', true)
    view:addChild(waitingSpine)

    local waitingIntro = display.newLabel(cpos.x, cpos.y + 5, fontWithColor(1, {fontSize = 36, color = '#572c1b', text = __('今日无商品上架')}))
    view:addChild(waitingIntro)

    local waitingTipsIntro = display.newLabel(cpos.x, cpos.y - 65, fontWithColor(5, {fontSize = 24, color = '#b58575', text = __('错过营业时间啦，等下次筹备的时候再回来看看吧'), w = 350, hAlign = display.TAC}))
    view:addChild(waitingTipsIntro)

    local countDownSize  = cc.size(display.SAFE_L + 250, 80)
    local countDownFrame = display.newImageView(RES_DICT.OPENING_FRAME, display.width, 70, {scale9 = true, size = countDownSize, ap = display.LEFT_CENTER, scaleX = -1})
    view:addChild(countDownFrame)

    local countdownInfoY = countDownFrame:getPositionY()
    local countdownInfoX = countDownFrame:getPositionX() - countDownSize.width/2
    local countdownIntro = display.newLabel(countdownInfoX, countdownInfoY + 15, fontWithColor(5, {fontSize = 24, color = '#b58575', text = __('距离筹备剩余')}))
    view:addChild(countdownIntro)

    local countdownLabel = display.newLabel(countdownInfoX, countdownInfoY - 15, fontWithColor(1, {fontSize = 24, color = '#572c1b', text = '--:--:--'}))
    view:addChild(countdownLabel)

    return {
        view           = view,
        countdownLabel = countdownLabel,
    }
end


function WaterBarHomeScene:getViewData()
    return self.viewData_
end


function WaterBarHomeScene:getBrewViewData()
    return self.brewViewData_
end


function WaterBarHomeScene:showUI(endCB)
    local viewData = self:getViewData()
    viewData.topLayer:setPosition(viewData.topLayerHidePos)
    viewData.titleBtn:setPosition(viewData.titleBtnHidePos)
    viewData.topBoardLayer:setPosition(viewData.topBoardHidePos)
    viewData.bottomLayer:setPosition(viewData.bottomLayerHidePos)
    viewData.titleBtn:runAction(cc.EaseBounceOut:create(cc.MoveTo:create(1, viewData.titleBtnShowPos)))
    viewData.topBoardLayer:runAction(cc.EaseBounceOut:create(cc.MoveTo:create(1, viewData.topBoardShowPos)))
    
    local actTime = 0.2
    self:runAction(cc.Sequence:create({
        cc.Spawn:create(
            cc.TargetedAction:create(viewData.topLayer, cc.MoveTo:create(actTime, viewData.topLayerShowPos)),
            cc.TargetedAction:create(viewData.bottomLayer, cc.MoveTo:create(actTime, viewData.bottomLayerShowPos))
        ),
        cc.CallFunc:create(function()
            if endCB then endCB() end
        end)
    }))
end


function WaterBarHomeScene:showBrewView(endCB)
    local brewViewData = self:getBrewViewData()
    brewViewData.view:setVisible(true)
    brewViewData.bgLayer:setOpacity(brewViewData.bgLayerHideAlpha)
    brewViewData.makeBtn:setScale(0)
    brewViewData.makeBtn:setPosition(brewViewData.makeBtnHidePos)
    brewViewData.researchBtn:setScale(0)
    brewViewData.researchBtn:setPosition(brewViewData.researchBtnHidePos)
    brewViewData.researchLock:setVisible(not app.waterBarMgr:GetIsUnLockFreeDev())
    
    local showBrewTime = 0.2
    brewViewData.view:stopAllActions()
    brewViewData.view:runAction(cc.Sequence:create(
        cc.Spawn:create(
            cc.TargetedAction:create(brewViewData.makeBtn, cc.Spawn:create(
                cc.EaseQuarticActionOut:create(cc.MoveTo:create(showBrewTime, brewViewData.makeBtnShowPos)),
                cc.EaseQuarticActionOut:create(cc.ScaleTo:create(showBrewTime, 1))
            )),
            cc.TargetedAction:create(brewViewData.researchBtn, cc.Spawn:create(
                cc.EaseQuarticActionOut:create(cc.MoveTo:create(showBrewTime, brewViewData.researchBtnShowPos)),
                cc.EaseQuarticActionOut:create(cc.ScaleTo:create(showBrewTime, 1))
            )),
            cc.TargetedAction:create(brewViewData.bgLayer, cc.FadeTo:create(showBrewTime, brewViewData.bgLayerShowAlpha))
        ),
        cc.CallFunc:create(function()
            if endCB then endCB() end
        end)
    ))
end
function WaterBarHomeScene:hideBrewView(endCB)
    local brewViewData = self:getBrewViewData()
    brewViewData.view:setVisible(true)
    brewViewData.bgLayer:setOpacity(brewViewData.bgLayerShowAlpha)
    brewViewData.makeBtn:setScale(1)
    brewViewData.makeBtn:setPosition(brewViewData.makeBtnShowPos)
    brewViewData.researchBtn:setScale(1)
    brewViewData.researchBtn:setPosition(brewViewData.researchBtnShowPos)

    local hideBrewTime = 0.2
    brewViewData.view:stopAllActions()
    brewViewData.view:runAction(cc.Sequence:create(
        cc.Spawn:create(
            cc.TargetedAction:create(brewViewData.makeBtn, cc.Spawn:create(
                cc.EaseQuarticActionOut:create(cc.MoveTo:create(hideBrewTime, brewViewData.makeBtnHidePos)),
                cc.EaseQuarticActionOut:create(cc.ScaleTo:create(hideBrewTime, 0))
            )),
            cc.TargetedAction:create(brewViewData.researchBtn, cc.Spawn:create(
                cc.EaseQuarticActionOut:create(cc.MoveTo:create(hideBrewTime, brewViewData.researchBtnHidePos)),
                cc.EaseQuarticActionOut:create(cc.ScaleTo:create(hideBrewTime, 0))
            )),
            cc.TargetedAction:create(brewViewData.bgLayer, cc.FadeTo:create(hideBrewTime, brewViewData.bgLayerHideAlpha))
        ),
        cc.Hide:create(),
        cc.CallFunc:create(function()
            if endCB then endCB() end
        end)
    ))
end


function WaterBarHomeScene:updateLeftSeconds(leftSeconds)
    local timeFormat = CommonUtils.getTimeFormatByType(leftSeconds)
    display.commonLabelParams(self.closingViewData_.countdownLabel, {text = timeFormat})
    display.commonLabelParams(self.waitingViewData_.countdownLabel, {text = timeFormat})
    display.commonLabelParams(self.openingViewData_.countdownLabel, {text = timeFormat})
end


function WaterBarHomeScene:updateStatus()
    if app.waterBarMgr:isHomeClosing() then
        self.closingViewData_.view:setVisible(true)
        self.waitingViewData_.view:setVisible(false)
        self.openingViewData_.view:setVisible(false)
        self:getViewData().closingBgImg:setVisible(true)
        self:getViewData().closingFgImg:setVisible(true)
        self:getViewData().openingBgImg:setVisible(false)
        self:getViewData().openingFgImg:setVisible(false)
        self:getViewData().brewBtn:setVisible(true)
        self:getViewData().marketBtn:setVisible(true)

    elseif app.waterBarMgr:isHomeOpening() then
        self.closingViewData_.view:setVisible(false)
        self:getViewData().closingBgImg:setVisible(false)
        self:getViewData().closingFgImg:setVisible(false)
        self:getViewData().openingBgImg:setVisible(true)
        self:getViewData().openingFgImg:setVisible(true)
        self:getViewData().brewBtn:setVisible(false)
        self:getViewData().marketBtn:setVisible(false)

        if next(app.waterBarMgr:getAllPutaways()) == nil then
            self.waitingViewData_.view:setVisible(true)
            self.openingViewData_.view:setVisible(false)
            self:getViewData().closingFgImg:setVisible(true)
        else
            self.waitingViewData_.view:setVisible(false)
            self.openingViewData_.view:setVisible(true)
            
            if app.waterBarMgr:isUserOpeningToday() then
                self.openingViewData_.hideSpine()
            else
                app.waterBarMgr:saveUserOpeningToday()
                self.openingViewData_.showSpine()
            end
        end
    end
end


function WaterBarHomeScene:updateServeCustomer(serveIndex, customerId, drinkId, storyId)
    local drinkCell = self:getViewData().drinkCellList[serveIndex]
    local drinkShadow = self:getViewData().drinkShadowList[serveIndex]
    local customerCell = self:getViewData().customerCellList[serveIndex]
    drinkCell:removeAllChildren()
    drinkShadow:setVisible(false)
    customerCell:removeAllChildren()
    customerCell:setTag(checkint(storyId))
    
    if checkint(customerId) > 0 then
        -- customer spine
        local customerConf  = CONF.BAR.CUSTOMER:GetValue(customerId)
        local cardSpineNode = AssetsUtils.GetCardSpineNode({confId = customerConf.cardId, scale = 0.75})
        cardSpineNode:setPositionX(customerCell:getContentSize().width/2)
        cardSpineNode:setAnimation(0, 'idle', true)
        customerCell:addChild(cardSpineNode)

        -- sotry icon
        if checkint(storyId) > 0 then
            local isTrigger = app.waterBarMgr:isUserStoryTrigger(storyId)
            local storyIcon = display.newImageView(isTrigger and RES_DICT.OLD_STORY_ICON or RES_DICT.NEW_STORY_ICON)
            storyIcon:setPositionX(customerCell:getContentSize().width/2)
            storyIcon:setPositionY(customerCell:getContentSize().height)
            customerCell:addChild(storyIcon)
            storyIcon:setName('storyIcon')
        end

        -- drink image
        if checkint(drinkId) > 0 then
            drinkShadow:setVisible(true)
            local drinkImgPos = cc.p(drinkCell:getContentSize().width/2, 22)
            drinkCell:addChild(CommonUtils.GetGoodsIconNodeById(drinkId, drinkImgPos.x, drinkImgPos.y, {ap = display.CENTER_BOTTOM, scale = 0.8}))
        end
    end
end


function WaterBarHomeScene:updateServeCustomerStoryIcon(customerCell)
    local storyIcon = customerCell:getChildByName('storyIcon')
    if storyIcon then
        local storyId   = checkint(customerCell:getTag())
        local isTrigger = app.waterBarMgr:isUserStoryTrigger(storyId)
        local iconPath  = isTrigger and RES_DICT.OLD_STORY_ICON or RES_DICT.NEW_STORY_ICON
        storyIcon:setTexture(iconPath)
    end
end


return WaterBarHomeScene
