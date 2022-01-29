--[[
 * author : kaishiqi
 * descpt : 打牌游戏 - PVE列表视图
]]
local GoodPurchaseNode  = require('common.GoodPurchaseNode')
local TTGamePveListView = class('TripleTriadGamePveListView', function()
    return display.newLayer(0, 0, {name = 'TripleTriadGamePveListView'})
end)

local RES_DICT = {
    COM_TITLE_BAR    = _res('ui/common/common_title.png'),
    COM_TIPS_ICON    = _res('ui/common/common_btn_tips.png'),
    COM_BACK_BTN     = _res('ui/common/common_btn_back.png'),
    BG_IMAGE         = _res('arts/stage/bg/main_bg_69.jpg'),
    COM_LOCK_ICON    = _res('ui/common/common_ico_lock.png'),
    COM_WARN_ICON    = _res('ui/common/common_btn_warning.png'),
    PVE_RULE_BAR     = _res('ui/ttgame/common/cardgame_common_label_kingsrule.png'),
    NPC_BORDER_FRAME = _res('ui/ttgame/pveList/cardgame_pve_npc_frame.png'),
    NPC_REWARD_BG    = _res('ui/ttgame/pveList/cardgame_pve_npc_bg_reward.png'),
    NPC_LOCK_COVER   = _res('ui/ttgame/pveList/cardgame_pve_npc_cover_lock.png'),
    NPC_LOCK_TITLE   = _res('ui/ttgame/pveList/cardgame_pve_npc_label_lock.png'),
    NPC_NAME_TITLE   = _res('ui/ttgame/pveList/cardgame_pve_npc_label_name.png'),
    NPC_REWARD_LINE  = _res('ui/ttgame/pveList/cardgame_pve_npc_line_reward.png'),
}

local MoneyListDefine = {
    {disable = true,  id = TTGAME_DEFINE.CURRENCY_ID},
    {disable = false, id = GOLD_ID},
    {disable = false, id = DIAMOND_ID},
}

local CreateView    = nil
local CreatePveCell = nil


function TTGamePveListView:ctor(args)
    -- create view
    self.viewData_ = CreateView()
    self:addChild(self.viewData_.view)

    -- update views
    self:updateMoneyBar()
end


CreateView = function()
    local view = display.newLayer()
    local size = view:getContentSize()

    -- block layer
    view:addChild(display.newImageView(RES_DICT.BG_IMAGE, size.width/2, size.height/2))
    view:addChild(display.newLayer(0, 0, {color = cc.c4b(0,0,0,150), enable = true}))

    local pveBgImgLayer = display.newLayer(size.width/2, size.height/2)
    view:addChild(pveBgImgLayer)


    ------------------------------------------------- [top]
    local topLayer = display.newLayer()
    view:addChild(topLayer)

    -- back button
    local backBtn = display.newButton(display.SAFE_L + 75, size.height - 52, {n = RES_DICT.COM_BACK_BTN})
    topLayer:addChild(backBtn)

    -- title button
    local titleBtn = display.newButton(display.SAFE_L + 120, size.height, {n = RES_DICT.COM_TITLE_BAR, ap = display.LEFT_TOP})
    display.commonLabelParams(titleBtn, fontWithColor(1, {text = __('挑战牌王'),reqW = 200 , offset = cc.p(-20,-10)}))
    topLayer:addChild(titleBtn)


    local titleSize = titleBtn:getContentSize()
    titleBtn:addChild(display.newImageView(RES_DICT.COM_TIPS_ICON, titleSize.width - 50, titleSize.height/2 - 10))

    -- money barBg
    local moneyBarBg = display.newImageView(_res(RES_DICT.MONEY_INFO_BAR), display.width, display.height, {ap = display.RIGHT_TOP, scale9 = true, size = cc.size(1, 54)})
    topLayer:addChild(moneyBarBg)

    -- money layer
    local moneyLayer = display.newLayer()
    topLayer:addChild(moneyLayer)

    -- update moneyLayer
    local MONEY_NODE_GAP = 16
    local moneyLayerSize = moneyLayer:getContentSize()
    local moneryBarSize  = cc.size(20, moneyBarBg:getContentSize().height)
    for i = #MoneyListDefine, 1, -1 do
        local moneyId   = checkint(MoneyListDefine[i].id)
        local isDisable = MoneyListDefine[i].disable == true
        local moneyNode = GoodPurchaseNode.new({id = moneyId, animate = true, disable = isDisable})
        moneyNode:setPosition(display.SAFE_R - moneryBarSize.width, moneyLayerSize.height - 26)
        moneyNode:setAnchorPoint(display.RIGHT_CENTER)
        moneyNode:setName(moneyId)
        moneyNode.viewData.touchBg:setTag(checkint(moneyId))
        moneyLayer:addChild(moneyNode)

        moneryBarSize.width = moneryBarSize.width + moneyNode:getContentSize().width + MONEY_NODE_GAP
    end

    -- update moneyBarBg
    moneryBarSize.width = 40 + moneryBarSize.width + (display.width - display.SAFE_R)
    moneyBarBg:setContentSize(moneryBarSize)


    ------------------------------------------------- [center]
    local centerLayer = display.newLayer()
    view:addChild(centerLayer)
    
    local PVE_COLUMNS = 2
    local pveGridSize = cc.size(1326, size.height - 90)
    local pveGridView = CGridView:create(pveGridSize)
    pveGridView:setSizeOfCell(cc.size(math.floor(pveGridSize.width / PVE_COLUMNS), 290))
    pveGridView:setAnchorPoint(display.CENTER_BOTTOM)
    pveGridView:setPosition(size.width/2, 0)
    pveGridView:setColumns(PVE_COLUMNS)
    -- pveGridView:setBackgroundColor(cc.c4b(100,100,50,255))
    centerLayer:addChild(pveGridView)

    return {
        view            = view,
        topLayer        = topLayer,
        topLayerHidePos = cc.p(topLayer:getPositionX(), 100),
        topLayerShowPos = cc.p(topLayer:getPosition()),
        titleBtn        = titleBtn,
        titleBtnHidePos = cc.p(titleBtn:getPositionX(), titleBtn:getPositionY() + 190),
        titleBtnShowPos = cc.p(titleBtn:getPosition()),
        backBtn         = backBtn,
        moneyLayer      = moneyLayer,
        centerLayer     = centerLayer,
        pveGridView     = pveGridView,
        pveBgImgLayer   = pveBgImgLayer,
    }
end


CreatePveCell = function(size)
    local view = CGridViewCell:new()
    view:setContentSize(size)

    -- block layer
    view:addChild(display.newLayer(0, 0, {color = cc.r4b(0), enable = true}))
    
    -- npcImg layer
    local npcImgLayer = display.newLayer(size.width/2, size.height/2)
    view:addChild(npcImgLayer)
    
    -- front frame
    view:addChild(display.newImageView(RES_DICT.NPC_BORDER_FRAME, size.width/2, size.height/2))
    
    -- rewards layer
    local rewardsLayer = display.newLayer()
    view:addChild(rewardsLayer)
    rewardsLayer:addChild(display.newImageView(RES_DICT.NPC_REWARD_BG, size.width - 27, size.height - 30, {ap = display.RIGHT_TOP}))
    rewardsLayer:addChild(display.newImageView(RES_DICT.NPC_REWARD_LINE, size.width - 37, size.height - 60, {ap = display.RIGHT_TOP}))
    
    local rewardCardList = {}
    for i = 1, 4 do
        local cardNode = TTGameUtils.GetBattleCardNode({zoomModel = 's'})
        cardNode:setAnchorPoint(display.RIGHT_TOP)
        cardNode:setPositionY(size.height - 65)
        cardNode:setPositionX(size.width - 30 - (i-1) * (cardNode:getContentSize().width+5))
        rewardsLayer:addChild(cardNode, 5-i)
        table.insert(rewardCardList, cardNode)
    end
    
    
    -------------------------------------------------[unlock]
    local unlockLayer = display.newLayer()
    view:addChild(unlockLayer)

    unlockLayer:addChild(display.newImageView(RES_DICT.NPC_NAME_TITLE, 10, 50, {ap = display.LEFT_CENTER}))
    
    local nameLabel = display.newLabel(40, 50, fontWithColor(20, {fontSize = 24, outline = '#917a2c', ap = display.LEFT_CENTER, text = '----'}))
    unlockLayer:addChild(nameLabel)
    
    local rewardsIntro = display.newLabel(size.width - 40, size.height - 47, fontWithColor(5, {ap = display.RIGHT_CENTER, color = '#fbd238', text = __('稀有奖励')}))
    unlockLayer:addChild(rewardsIntro)
    
    
    -- ruleTips layer
    local ruleTipsLayer = display.newButton(size.width - 35, nameLabel:getPositionY(), {n = RES_DICT.PVE_RULE_BAR, ap = display.RIGHT_CENTER, scale9 = true, enable = false})
    display.commonLabelParams(ruleTipsLayer, fontWithColor(9, {text = __('使用牌王规则'),reqW = 370, paddingW =10 , offset= cc.p(-20, 0 )}))
    ruleTipsLayer:addChild(display.newImageView(RES_DICT.COM_WARN_ICON, ruleTipsLayer:getContentSize().width*1 - 20, ruleTipsLayer:getContentSize().height/2))
    view:addChild(ruleTipsLayer)
    

    -------------------------------------------------[lock]
    local lockLayer = display.newLayer()
    view:addChild(lockLayer)

    lockLayer:addChild(display.newImageView(RES_DICT.NPC_LOCK_COVER, size.width/2, size.height/2))
    lockLayer:addChild(display.newImageView(RES_DICT.NPC_LOCK_TITLE, 10, 50, {ap = display.LEFT_CENTER}))

    local lockIcon = display.newImageView(RES_DICT.COM_LOCK_ICON, 40, nameLabel:getPositionY()+2, {ap = display.LEFT_CENTER})
    lockLayer:addChild(lockIcon)
    
    local cardsLabel = display.newLabel(lockIcon:getPositionX() + 50, lockIcon:getPositionY(), fontWithColor(3, {fontSize = 30, ap = display.LEFT_CENTER, text = '-- / --'}))
    lockLayer:addChild(cardsLabel)

    local unlockLabel = display.newLabel(rewardsIntro:getPositionX(), rewardsIntro:getPositionY(), fontWithColor(18, {ap = display.RIGHT_CENTER, color = '#dfdfdf', text = '----'}))
    lockLayer:addChild(unlockLabel)


    local hotspot = display.newLayer(size.width/2, size.height/2, {size = size, color = cc.r4b(0), ap = display.CENTER, enable = true})
    view:addChild(hotspot)

    return {
        view           = view,
        hotspot        = hotspot,
        npcImgLayer    = npcImgLayer,
        unlockLayer    = unlockLayer,
        lockLayer      = lockLayer,
        nameLabel      = nameLabel,
        cardsLabel     = cardsLabel,
        unlockLabel    = unlockLabel,
        ruleTipsLayer  = ruleTipsLayer,
        rewardCardList = rewardCardList,
    }
end


function TTGamePveListView:getViewData()
    return self.viewData_
end


function TTGamePveListView.CreatePveCell(size)
    return CreatePveCell(size)
end


function TTGamePveListView:updateMoneyBar()
    for _, moneyNode in ipairs(self:getViewData().moneyLayer:getChildren()) do
        local moneyId = checkint(moneyNode:getName())
        moneyNode:updataUi(moneyId)
    end
end


function TTGamePveListView:updateBgImage(imageName)
    local bgImagePath = _res(string.fmt('arts/stage/bg/%1.jpg', imageName))
    self:getViewData().pveBgImgLayer:removeAllChildren()
    self:getViewData().pveBgImgLayer:addChild(display.newImageView(bgImagePath))
end


return TTGamePveListView
