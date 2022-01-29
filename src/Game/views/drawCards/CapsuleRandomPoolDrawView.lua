--[[
铸池抽卡领奖view
--]]
local CapsuleRandomPoolDrawView = class('CapsuleRandomPoolDrawView', function ()
    local node = CLayout:create(display.size)
    node.name = 'home.CapsuleRandomPoolDrawView'
    node:enableNodeEvents()
    return node
end)
local GoodPurchaseNode = require('common.GoodPurchaseNode')
local RES_DICT = {
    BACK_BTN               = _res('ui/common/common_btn_back.png'),
    COMMON_TIPS_ICON       = _res('ui/common/common_btn_tips.png'),
    DRAW_CELL_PREVIEW_BTN  = _res('ui/home/capsuleNew/home/summon_btn_preview.png'),
    REFRESH_BTN            = _res('ui/home/commonShop/shop_btn_refresh.png'),
    BOTTOM_BG              = _res('ui/home/capsuleNew/common/summon_activity_bg_.png'),
    COMMON_BTN             = _res('ui/common/common_btn_orange_big.png'),
    MONEY_INFO_BAR         = _res('ui/home/nmain/main_bg_money.png'),

    ZH_LIZI                = _spn('ui/home/capsuleNew/zh_lizi'),
}
function CapsuleRandomPoolDrawView:ctor( ... )
    self:InitUI()
end
--[[
init ui
--]]
function CapsuleRandomPoolDrawView:InitUI()
    local function CreateView()
        local size = display.size
        local view = CLayout:create(size)
        -- 卡池名称
        local titleLabel = display.newLabel(display.SAFE_R - 90, size.height - 100, {text = '', ap = cc.p(1, 0.5), fontSize = 34, color = '#ffffff', ttf = true, outline = '#5c1919', outlineSize = 2, font = TTF_GAME_FONT})
        view:addChild(titleLabel, 1)
        -- 内容一览
        local previewBtn  = display.newButton(display.SAFE_R - 75, size.height - 110, {n = RES_DICT.DRAW_CELL_PREVIEW_BTN, ap = display.RIGHT_TOP})
        local previewSize = previewBtn:getContentSize()
        display.commonLabelParams(previewBtn, fontWithColor(19, {text = __('内容一览'), ap = display.RIGHT_CENTER, offset = cc.p(previewSize.width/2 - 100, 0)}))
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
        -- 刷新卡池
        local refreshBtn = display.newButton(size.width - 120 - display.SAFE_L, 260, {n = RES_DICT.REFRESH_BTN})
        view:addChild(refreshBtn, 1)
        local refreshLabel = display.newLabel(size.width - 154 - display.SAFE_L, 270, {text = __('重铸卡池'), fontSize = 22, ap = cc.p(1, 0.5), color = '#ffffff', ttf = true, outline = '#000000', outlineSize = 1, font = TTF_GAME_FONT})
        view:addChild(refreshLabel, 1) 
        local refreshTimesLabel = display.newLabel(size.width - 154 - display.SAFE_L, 240, {text = '', fontSize = 22, ap = cc.p(1, 0.5), color = '#ffffff', ttf = true, outline = '#000000', outlineSize = 1, font = TTF_GAME_FONT})
        view:addChild(refreshTimesLabel, 1) 
        -- 底部背景
        local bottomBg = display.newImageView(RES_DICT.BOTTOM_BG, size.width / 2, 40, {ap = cc.p(0.5, 0)})
        view:addChild(bottomBg, 1)
        -- 购买按钮
        local drawBtn = display.newButton(size.width / 2, 150, {n = RES_DICT.COMMON_BTN})
        view:addChild(drawBtn, 1)
        display.commonLabelParams(drawBtn, fontWithColor(14, {text = __('购买')}))
        -- 消耗
        local costRichLabel = display.newRichLabel(size.width / 2, 90)
        view:addChild(costRichLabel, 10)
        -- 返回按钮
		local backBtn = display.newButton(0, 0, {n = _res("ui/common/common_btn_back.png")})
		display.commonUIParams(backBtn, {po = cc.p(display.SAFE_L + backBtn:getContentSize().width * 0.5 + 30, display.height - 18 - backBtn:getContentSize().height * 0.5)})
		self:addChild(backBtn, 20)
        -- top ui layer
        local topUILayer = display.newLayer()
        view:addChild(topUILayer)

        -- money barBg
        local moneyBarBg = display.newImageView(_res(RES_DICT.MONEY_INFO_BAR), display.width, display.height, {ap = display.RIGHT_TOP, scale9 = true, size = cc.size(1, 54)})
        topUILayer:addChild(moneyBarBg)

        -- money layer
        local moneyLayer = display.newLayer()
        topUILayer:addChild(moneyLayer)
        return {
            view              = view,
            size              = size,
            refreshBtn        = refreshBtn,
            refreshTimesLabel = refreshTimesLabel,
            previewBtn        = previewBtn,
            drawBtn           = drawBtn,
            costRichLabel     = costRichLabel,
            backBtn           = backBtn,
            titleLabel        = titleLabel,
            moneyBarBg        = moneyBarBg,
            moneyLayer        = moneyLayer,
        }
    end
    xTry(function ( )
        local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 255 * 0.6))
        eaterLayer:setContentSize(display.size)
        eaterLayer:setTouchEnabled(true)
        eaterLayer:setPosition(utils.getLocalCenter(self))
        self.eaterLayer = eaterLayer
        self:addChild(eaterLayer, -1)
        self.viewData = CreateView( )
        self:addChild(self.viewData.view)
        self.viewData.view:setPosition(display.center)
    end, __G__TRACKBACK__)
end
--[[
刷新剩余刷新次数
--]]
function CapsuleRandomPoolDrawView:RefreshLeftRefreshTimes( isRefresh )
    local viewData = self:GetViewData()
    if checkint(isRefresh) == 1 then
        -- 已刷新
        viewData.refreshTimesLabel:setString('(0/1)')
    else
        -- 未刷新
        viewData.refreshTimesLabel:setString('(1/1)')
    end
end
--[[
刷新领奖消耗
--]]
function CapsuleRandomPoolDrawView:RefreshDrawConsume( consume )
    local viewData = self:GetViewData()
    -- 显示花费
    display.reloadRichLabel(viewData.costRichLabel, { c  = {
        {text = __('消耗'), fontSize = 22, color = '#ffffff'},
        {text = consume[1].num, fontSize = 22, color = '#d9bc00'},
        {img = _res(CommonUtils.GetGoodsIconPathById(consume[1].goodsId)), scale = 0.18}
    }})
end
--[[
显示奖励
@params dropCards list 抽卡获得卡牌数据
--]]
function CapsuleRandomPoolDrawView:ShowRewards( dropCards )
    if not dropCards then return end
    local viewData = self:GetViewData()
    for i, v in ipairs(dropCards) do
        local cardNode = nil 
        if checkint(v.isGuaranteed) == 1 then
            -- 保底
            cardNode = require('common.GoodNode').new({
                id = v.cardId,
                showAmount = false,
            })
        else
            -- 非保底（只显示稀有度）
            local cardConfig = CommonUtils.GetConfig('cards','card', v.cardId)
            local quality = checkint(cardConfig.qualityId)
            cardNode = display.newButton(0, 0, {n = _res(string.format('ui/home/capsuleNew/randomPool/b_card_%d.png', quality)), cb = function ()
                local cardRare = CommonUtils.GetConfig('cards', 'quality', quality)
                app.uiMgr:ShowInformationTips(string.fmt(__('未知_name_级飨灵'), {['_name_'] = cardRare.quality}))
            end})
        end
        local posX = viewData.size.width / 2 + ((i - 1) % 5 - 2) * 160
        local posY = viewData.size.height / 2 - 30 + (-math.ceil(i / 5) + 2) * 140
        cardNode:setPosition(cc.p(posX, posY))
        viewData.view:addChild(cardNode, 10)
        cardNode:setOpacity(0)
        cardNode:runAction(
            cc.Sequence:create(
                cc.DelayTime:create((i - 1) * 0.05),
                cc.FadeIn:create(0.15)
            )
        )
    end
end
--[[
重载货币栏
--]]
function CapsuleRandomPoolDrawView:ReloadMoneyBar(moneyIdMap, isDisableGain)
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
    local moneyBarBg = self:GetViewData().moneyBarBg
    local moneyLayer = self:GetViewData().moneyLayer
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
    self:UpdateMoneyBar()
end
function CapsuleRandomPoolDrawView:UpdateMoneyBar()
    for _, moneyNode in ipairs(self:GetViewData().moneyLayer:getChildren()) do
        local moneyId = checkint(moneyNode:getName())
        moneyNode:updataUi(moneyId)
    end
end
--[[
获取viewData
--]]
function CapsuleRandomPoolDrawView:GetViewData()
    return self.viewData
end
function CapsuleRandomPoolDrawView:onCleanup()
	display.removeUnusedSpriteFrames()
end
return CapsuleRandomPoolDrawView