--[[
 * descpt : pass ticket 购买弹窗 界面
]]
local VIEW_SIZE = display.size
---@class PassTicketPurchasePopup :CLayout
local PassTicketPurchasePopup = class("PassTicketPurchasePopup", function ()
	local node = CLayout:create(VIEW_SIZE)
	node.name = 'passTicket.PassTicketPurchasePopup'
	node:enableNodeEvents()
	return node
end)

local GoodNode = require('common.GoodNode')

local CreateView = nil

local RES_DICT = {
    COMMON_BTN_ORANGE               = _res('ui/common/common_btn_orange.png'),
    COMMON_BTN_GREEN                = _res('ui/common/common_btn_green.png'),
    COMMON_BTN_DRAWN                = _res('ui/common/activity_mifan_by_ico.png'),
    ACTIVITY_DIARY_BTN_LOCK         = _res('ui/common/activity_diary_btn_lock.png'),
    ACTIVITY_DIARY_MAIN_BG          = _res('ui/home/activity/passTicket/activity_diary_main_bg.png'),
    ACTIVITY_DIARY_REWORD_BG        = _res('ui/home/activity/passTicket/activity_diary_reword_bg.png'),
    ACTIVITY_DIARY_AD               = _res('ui/home/activity/passTicket/activity_diary_ad.png'),
    ACTIVITY_DIARY_RECHANGE_BTN_BG  = _res('ui/home/activity/passTicket/activity_diary_rechange_btn_bg.png'),
    ACTIVITY_DIARY_BOUNS_2          = _res('ui/home/activity/passTicket/activity_diary_bouns_2.png'),

    SPINE_PASS                      = _spn('ui/home/activity/passTicket/spine/pass'),
}

function PassTicketPurchasePopup:ctor( ... ) 
    self.args = unpack({...}) or {}
    self:initialUI()
end

function PassTicketPurchasePopup:initialUI()
    xTry(function ( )
        self.viewData_ = CreateView()
        self:addChild(self.viewData_.view)

        self:initView()
	end, __G__TRACKBACK__)
end

function PassTicketPurchasePopup:initView()
    local viewData = self:getViewData()
    display.commonUIParams(viewData.shadowLayer, {cb = handler(self, self.onClickShadowLayerAction)})

    display.commonUIParams(viewData.rewardPreviewBtn, {cb = handler(self, self.onClickRewardPreviewBtnAction), animate = false})
    
    self:updateRechangeBtn()
    self:updateAdBg(app.passTicketMgr:GetPassTickeCardId())

    local homeData = app.passTicketMgr:GetHomeData()
    local levelList = homeData.level or {}
    local levelDataCount = #levelList
    if levelDataCount > 1 then
        local num = 1
        local rewardCells = viewData.rewardCells
        for i = levelDataCount - 1, levelDataCount do
            local levelData = levelList[i]
            local rewardCell = rewardCells[num]
            display.commonLabelParams(rewardCell.cellLv, {text = tostring(levelData.level)})
            rewardCell:updateBaseReward(levelData)
            rewardCell:updateAdditionalReward(levelData.additionalRewards)
            
            local drawBtn = rewardCell.drawBtn
            drawBtn:setTouchEnabled(false)
            
            local receivedLabel = rewardCell.receivedLabel
            local drawBtnLabel = drawBtn:getLabel()
            local isDrawn = levelData.hasDrawn > 1
            receivedLabel:setVisible(isDrawn)
            drawBtnLabel:setVisible(not isDrawn)
            
            local img = isDrawn and RES_DICT.COMMON_BTN_DRAWN or RES_DICT.ACTIVITY_DIARY_BTN_LOCK
            drawBtn:setNormalImage(img)
            drawBtn:setSelectedImage(img)

            num = num + 1
        end
    end
end

function PassTicketPurchasePopup:updateRechangeBtn()
    local viewData = self:getViewData()
    local homeData = app.passTicketMgr:GetHomeData()
    local rechangeBtn = viewData.rechangeBtn
    local isHasPurchasePassTicket = app.passTicketMgr:GetHasPurchasePassTicket() > 0
    local price 
    if isElexSdk() then
        local sdkInstance = require("root.AppSDK").GetInstance()
        if sdkInstance.loadedProducts[tostring(homeData.channelProductId)] then
            price = sdkInstance.loadedProducts[tostring(homeData.channelProductId)].priceLocale
            price  = isHasPurchasePassTicket and __('已购买') or price
        else
            price = homeData.price
            price = isHasPurchasePassTicket and __('已购买') or string.fmt( __('￥_num1_'),{_num1_ = tostring(price)})
        end
    else
        price = homeData.price
        price =  isHasPurchasePassTicket and __('已购买') or string.fmt( __('￥_num1_'),{_num1_ = tostring(price)} )
    end
    display.commonLabelParams(rechangeBtn, {text = price})
    display.commonUIParams(rechangeBtn, {cb = handler(self, self.onClickRechangeBtnAction)})
    local img = isHasPurchasePassTicket and RES_DICT.COMMON_BTN_DRAWN or RES_DICT.COMMON_BTN_GREEN
    rechangeBtn:setNormalImage(img)
    rechangeBtn:setSelectedImage(img)
    rechangeBtn:setEnabled(not isHasPurchasePassTicket)
end

function PassTicketPurchasePopup:updateAdBg(cardId)
    if cardId then
        self:getViewData().adBg:setVisible(true)
        local path = string.format( "ui/home/activity/passTicket/activity_diary_ad_%s.png", cardId)
        if not utils.isExistent(path) then
            path = RES_DICT.ACTIVITY_DIARY_AD
        end
        self:getViewData().adBg:setTexture(_res(path))
    else
        self:getViewData().adBg:setVisible(false)
    end
end

CreateView = function ()
    local view = display.newLayer()
    local size = view:getContentSize()

    local shadowLayer = display.newLayer(0, 0, {color = cc.c4b(0, 0, 0, 150), enable = true})
    view:addChild(shadowLayer)

    ------------------mainView start------------------
    local mainViewSize = cc.size(668, 704)
    local mainView = display.newLayer(display.cx, display.cy,
    {
        ap = display.CENTER,
        size = mainViewSize,
    })
    view:addChild(mainView)

    mainView:addChild(display.newLayer(0, 0, { ap = display.LEFT_BOTTOM, size = mainViewSize, enable = true, color = cc.c4b(0,0,0,0)}))

    local mainBg = display.newNSprite(RES_DICT.ACTIVITY_DIARY_MAIN_BG, mainViewSize.width / 2, mainViewSize.height / 2,
    {
        ap = display.CENTER,
    })
    mainView:addChild(mainBg)

    -- local labelparser = require('Game.labelparser')
    -- local parsedtable = labelparser.parse(__('购买<highlight>豪华</highlight>pass卡'))
    -- local richList = {}
    -- for i, v in ipairs(parsedtable) do
    --     local temp = fontWithColor(20, {fontSize = 42, text = v.content})
    --     if v.labelname == 'highlight' then
    --         temp.color = '#ffcd21'
    --     end
    --     table.insert(richList, temp)
    -- end
    -- local richLabel = display.newRichLabel(60, mainViewSize.height - 70, {ap = display.LEFT_CENTER, r = true ,  c = richList})
    -- CommonUtils.AddRichLabelTraceEffect(richLabel, '#5b3c25', 2)
    -- mainView:addChild(richLabel)

    local titleLabel = display.newLabel(60, mainViewSize.height - 70, fontWithColor(20, {ap = display.LEFT_CENTER, outline = '#5b3c25', text = __('购买书签')}))
    mainView:addChild(titleLabel)

    local rewardPreviewBtn = display.newButton(mainViewSize.width - 24, mainViewSize.height - 70,
    {
        ap = display.RIGHT_CENTER,
        n = RES_DICT.COMMON_BTN_ORANGE,
        scale9 = true, size = cc.size(123, 62),
        enable = true,
    })
    display.commonLabelParams(rewardPreviewBtn, fontWithColor(14, {text = __('奖励预览')}))
    rewardPreviewBtn:setScale(0.9)
    mainView:addChild(rewardPreviewBtn)

    local descrViewSize  = cc.size(525, 150)
	local descrContainer = cc.ScrollView:create()
    descrContainer:setPosition(cc.p(60, mainViewSize.height - 265))
	descrContainer:setDirection(eScrollViewDirectionVertical)
	descrContainer:setAnchorPoint(display.LEFT_TOP)
    descrContainer:setViewSize(descrViewSize)
    mainView:addChild(descrContainer)

    local moduleExplainConf = checktable(CommonUtils.GetConfigAllMess('moduleExplain'))['-25'] or {}
    local ruleLabel = display.newLabel(0, 0, fontWithColor(16, {w = descrViewSize.width, text = tostring(moduleExplainConf.descr)}))
    descrContainer:setContainer(ruleLabel)
    local descrScrollTop = descrViewSize.height - display.getLabelContentSize(ruleLabel).height
	descrContainer:setContentOffset(cc.p(0, descrScrollTop))


    local rewardBg = display.newNSprite(RES_DICT.ACTIVITY_DIARY_REWORD_BG, mainViewSize.width / 2, 28, {ap = display.CENTER_BOTTOM})
    mainView:addChild(rewardBg)

    local rewardCells = {}
    for i = 1, 2 do
        local cell = require('Game.views.passTicket.PassTicketListCell').new({size = cc.size(620, 104)})
        display.commonUIParams(cell, {ap = display.CENTER_TOP, po = cc.p(mainViewSize.width / 2, 398 - (i-1) * 104)})
        mainView:addChild(cell)
        table.insert(rewardCells, cell)
    end

    local passTicketFrame = display.newNSprite(RES_DICT.ACTIVITY_DIARY_BOUNS_2, mainViewSize.width / 2 + 25, 416, {ap = display.CENTER_TOP})
    mainView:addChild(passTicketFrame)

    local spine = sp.SkeletonAnimation:create(RES_DICT.SPINE_PASS.json, RES_DICT.SPINE_PASS.atlas, 1)
    spine:update(0)
    spine:addAnimation(0, 'idle', true)
    spine:setPosition(utils.getLocalCenter(passTicketFrame))
    passTicketFrame:addChild(spine, 5)

    local passTicketTipLabel = display.newLabel(141, 240, fontWithColor(20, {text = __('超级奖励'), fontSize = 24, color = '#ffcd21', outline = '#980000'}))
    passTicketFrame:addChild(passTicketTipLabel)

    local adBg = display.newNSprite(RES_DICT.ACTIVITY_DIARY_AD, mainViewSize.width / 2, 28, {ap = display.CENTER_BOTTOM})
    mainView:addChild(adBg)
    adBg:setVisible(false)
    
    local rechangeBtnBg = display.newNSprite(RES_DICT.ACTIVITY_DIARY_RECHANGE_BTN_BG, mainViewSize.width / 2, 91, {ap = display.CENTER})
    mainView:addChild(rechangeBtnBg)

    local rechangeBtn = display.newButton(mainViewSize.width / 2, 91, {ap = display.CENTER, n = RES_DICT.COMMON_BTN_GREEN})
    display.commonLabelParams(rechangeBtn, fontWithColor(14))
    mainView:addChild(rechangeBtn)
    
   return {
        view = view,
        adBg        = adBg,
        shadowLayer = shadowLayer,
        rewardCells = rewardCells,
        rechangeBtn = rechangeBtn,
        rewardPreviewBtn = rewardPreviewBtn,
   }
end

function PassTicketPurchasePopup:onClickRechangeBtnAction()
    local homeData = app.passTicketMgr:GetHomeData()
    local hasPurchasePassTicket = checkint(homeData.hasPurchasePassTicket)
    if hasPurchasePassTicket > 0 then
        
        app.uiMgr:ShowInformationTips(__('已购买'))
        return 
    end
    app:DispatchObservers('PASS_TICKET_GET_PAY_ORDER')
    
end

function PassTicketPurchasePopup:onClickRewardPreviewBtnAction()
    local levelList = app.passTicketMgr:GetLevelList()
    local tempDataMap = {}
    
    local getGoodsPriority = function (goodsId)
        local goodsType = CommonUtils.GetGoodTypeById(goodsId)
        local priority = 0
        if goodsType == GoodsType.TYPE_CARD then
            priority = 99
        elseif goodsType == GoodsType.TYPE_CARD_FRAGMENT then
            priority = 98
        elseif goodsType == GoodsType.TYPE_CARD_SKIN then
            priority = 97
        elseif checkint(goodsId) == DIAMOND_ID then
            priority = 96
        elseif checkint(goodsId) == CAPSULE_VOUCHER_ID then
            priority = 95
        end
        return priority
    end

    for i, v in ipairs(levelList) do
        local baseRewards = v.baseRewards or {}
        for _, baseReward in ipairs(baseRewards) do
            local goodsId = baseReward.goodsId
            local num = baseReward.num
            if tempDataMap[goodsId] == nil then
                local goodsConfig = CommonUtils.GetConfig('goods', 'goods', goodsId) or {}
                tempDataMap[goodsId] = {goodsId = goodsId, num = num, quality = goodsConfig.quality, priority = getGoodsPriority(goodsId)}
            else
                tempDataMap[goodsId].num = tempDataMap[goodsId].num + num
            end
        end
        local additionalRewards = v.additionalRewards or {}
        for _, additionalReward in ipairs(additionalRewards) do
            local goodsId = additionalReward.goodsId
            local num = additionalReward.num
            if tempDataMap[goodsId] == nil then
                local goodsConfig = CommonUtils.GetConfig('goods', 'goods', goodsId) or {}
                tempDataMap[goodsId] = {goodsId = goodsId, num = num, quality = goodsConfig.quality, priority = getGoodsPriority(goodsId)}
            else
                tempDataMap[goodsId].num = tempDataMap[goodsId].num + num
            end
        end
    end

    local rewards = table.values(tempDataMap)

    if next(rewards) == nil then
        return
    end

    table.sort(rewards, function (a, b)
        local apriority = a.priority
        local bpriority = b.priority
        if apriority ~= bpriority then
            return apriority > bpriority
        end
        return a.quality > b.quality
    end)

    local tempData = {name = __('奖励一览'), rewards = rewards}
	local ShowRewardsLayer  = require( 'Game.views.ShowRewardsLayer' ).new(tempData)
    ShowRewardsLayer:setPosition(display.center)
    local cancelBtn = ShowRewardsLayer.viewData_.cancelBtn
    cancelBtn:setNormalImage(RES_DICT.COMMON_BTN_ORANGE)
    cancelBtn:setSelectedImage(RES_DICT.COMMON_BTN_ORANGE)
    cancelBtn:setPositionX(cancelBtn:getPositionX() / 3 * 5)
    display.commonLabelParams(cancelBtn, {text = __('确定')})
    ShowRewardsLayer.viewData_.buyBtn:setVisible(false)
	app.uiMgr:GetCurrentScene():AddDialog(ShowRewardsLayer)
end

function PassTicketPurchasePopup:onClickShadowLayerAction()
    self:setVisible(false)
    self:runAction(cc.RemoveSelf:create())
end

function PassTicketPurchasePopup:getViewData()
	return self.viewData_
end

return PassTicketPurchasePopup