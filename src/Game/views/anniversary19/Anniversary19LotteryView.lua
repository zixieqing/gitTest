--[[
 * author : liuzhipeng
 * descpt : 活动 周年庆19 抽奖Mediator
--]]
local Anniversary19LotteryView = class('Anniversary19LotteryView', function ()
    local node = CLayout:create(display.size)
    node.name = 'Game.views.anniversary19.Anniversary19LotteryView'
    node:enableNodeEvents()
    return node
end)
local GoodPurchaseNode = require('common.GoodPurchaseNode')
local RES_DICT = {
    BACK_BTN                        = app.anniversary2019Mgr:GetResPath("ui/common/common_btn_back"),
    COMMON_TITLE                    = app.anniversary2019Mgr:GetResPath('ui/common/common_title.png'),
    COMMON_TIPS       		        = app.anniversary2019Mgr:GetResPath('ui/common/common_btn_tips.png'),
    MONEY_INFO_BAR       		    = app.anniversary2019Mgr:GetResPath('ui/home/nmain/main_bg_money.png'),
    RWEARD_LAYOUT_BG                = app.anniversary2019Mgr:GetResPath('ui/common/common_bg_4.png'),
    LOTTERY_LAYOUT_BG               = app.anniversary2019Mgr:GetResPath('ui/anniversary19/lottery/wonderland_draw_bg_down.png'),
    CARD_IMG                        = app.anniversary2019Mgr:GetResPath('ui/anniversary19/lottery/wonderland_draw_bg_reward_card.png'),
	DRAW_BTN_N                      = app.anniversary2019Mgr:GetResPath("ui/home/capsuleNew/common/summon_newhand_btn_draw.png"),
    DRAW_BTN_D                      = app.anniversary2019Mgr:GetResPath("ui/home/capsuleNew/newPlayerCapsule/summon_newhand_btn_draw_locked.png"),
    LOTTERY_CONSUME_BG              = app.anniversary2019Mgr:GetResPath("ui/anniversary19/lottery/wonderland_draw_label_num.png"),
    LOTTERY_DESCR_LABEL_BG          = app.anniversary2019Mgr:GetResPath("ui/anniversary19/lottery/wonderland_draw_label_text.png"),
    RABBIT_SPINE                    = app.anniversary2019Mgr:GetSpinePath('ui/anniversary19/effects/wonderland_draw_rabbit'),
    REWARD_SPINE                    = app.anniversary2019Mgr:GetSpinePath('ui/anniversary19/effects/wonderland_draw_box'),
    DRAW_PROBABILITY_BTN            = app.anniversary2019Mgr:GetResPath('ui/home/capsule/draw_probability_btn.png'),
    COMMON_BG_GOODS                 = app.anniversary2019Mgr:GetResPath('ui/common/common_bg_goods'),
    RARE_REWARDS_BTN                = app.anniversary2019Mgr:GetResPath('ui/common/tower_btn_quit.png'),
    RARE_REWARDS_BTN_NOTICE         = app.anniversary2019Mgr:GetResPath('avatar/ui/restaurant_btn_festival_notice'),
    SPLIT_LINE                      = app.anniversary2019Mgr:GetResPath('ui/anniversary19/lottery/wonderland_draw_line_subtitle.png'),
    LIST_VIEW_SPLIT_LINE            = app.anniversary2019Mgr:GetResPath('ui/common/season_loots_line_1'),
    REWARD_CELL_COMMON              = app.anniversary2019Mgr:GetResPath('ui/home/activity/seasonlive/season_loots_label_goods'),
    REWARD_CELL_RARE                = app.anniversary2019Mgr:GetResPath('ui/anniversary19/lottery/season_loots_label_goods_rare.png'),
    REWARD_CELL_DISABLE             = app.anniversary2019Mgr:GetResPath('ui/home/activity/seasonlive/season_loots_label_goods_bk'),
}
function Anniversary19LotteryView:ctor( ... )
    self:InitUI()
end
--[[
init ui
--]]
function Anniversary19LotteryView:InitUI()
    local function CreateView()
		local size = display.size
		local view = CLayout:create(size)
		view:setPosition(size.width / 2, size.height / 2)
		-- 标题版
		local tabNameLabel = display.newButton(display.SAFE_L + 130, display.height, {n = RES_DICT.COMMON_TITLE, enable = true,ap = cc.p(0, 1)})
		display.commonLabelParams(tabNameLabel, {ttf = true, font = TTF_GAME_FONT, text = app.anniversary2019Mgr:GetPoText(__('抽奖')), fontSize = 30, color = '473227',offset = cc.p(0,-8)})
		self:addChild(tabNameLabel, 20)
		-- 提示按钮
		local tabtitleTips = display.newImageView(RES_DICT.COMMON_TIPS, 242, 28)
        tabNameLabel:addChild(tabtitleTips, 1)

		----------------------
        ---- rewardLayout ----
        local rewardLayoutSize = cc.size(695, 640)
        local rewardLayout = CLayout:create(rewardLayoutSize)
        view:addChild(rewardLayout, 1)
        rewardLayout:setPosition(cc.p(display.cx - 280, display.cy - 40))
        local rewardLayoutBg = display.newImageView(RES_DICT.RWEARD_LAYOUT_BG, rewardLayoutSize.width / 2, rewardLayoutSize.height / 2, {scale9 = true, size = rewardLayoutSize})
        rewardLayout:addChild(rewardLayoutBg, 1)
        -- 轮数
        local turnLabel = display.newLabel(35, rewardLayoutSize.height - 24, {text = '', fontSize = 24, color = '#765b4e', ap = display.LEFT_CENTER})
        rewardLayout:addChild(turnLabel, 5)
        -- 分割线
        local line = display.newImageView(RES_DICT.SPLIT_LINE, 35, rewardLayoutSize.height - 40, {ap = display.LEFT_CENTER})
        rewardLayout:addChild(line, 5)
        -- 剩余数量
        local leftNumLabel = display.newLabel(35, rewardLayoutSize.height - 56, {text = '', color = '#714300', fontSize = 20, ap = display.LEFT_CENTER})
        rewardLayout:addChild(leftNumLabel, 5)
        -- 概率
        local probabilityBtn = display.newButton(360, rewardLayoutSize.height - 38, {ap = cc.p(1, 0.5) ,  n = RES_DICT.DRAW_PROBABILITY_BTN , scale9 = true })
        rewardLayout:addChild(probabilityBtn, 5)
        display.commonLabelParams(probabilityBtn, fontWithColor(18, {text = app.anniversary2019Mgr:GetPoText(__('概率')) ,safeW = 120 , paddingW = 20   }))
        -- 稀有奖励
        local rareRewardBtn = display.newButton(rewardLayoutSize.width - 10, rewardLayoutSize.height - 38, { scale9 =true  ,  n = RES_DICT.RARE_REWARDS_BTN, ap = display.RIGHT_CENTER})
        display.commonLabelParams(rareRewardBtn, {text = app.anniversary2019Mgr:GetPoText(__('稀有奖励一览')), fontSize = 22, color = '#ffffff' ,safeW = 200 , paddingW = 20  })
        rewardLayout:addChild(rareRewardBtn, 5)
        local forenoticeImg = display.newImageView(RES_DICT.RARE_REWARDS_BTN_NOTICE, -10, 16)
        rareRewardBtn:addChild(forenoticeImg, 5)
        forenoticeImg:runAction(
            cc.RepeatForever:create(
                cc.Sequence:create(
                    cc.RotateTo:create(0.1, 15),
                    cc.RotateTo:create(0.2, -15),
                    cc.RotateTo:create(0.2, 15),
                    cc.RotateTo:create(0.2, -15),
                    cc.RotateTo:create(0.1, 0),
                    cc.DelayTime:create(2)
                )
            )
        )
        -- 列表背景
        local rewardListViewSize = cc.size(645, 540)
        local listViewBg = display.newImageView(RES_DICT.COMMON_BG_GOODS, rewardLayoutSize.width / 2, 28
        , { size = rewardListViewSize, scale9 = true, ap = display.CENTER_BOTTOM})
        rewardLayout:addChild(listViewBg, 1)
        -- 列表
        local rewardListView = CListView:create(rewardListViewSize)
        rewardListView:setDirection(eScrollViewDirectionVertical)
        display.commonUIParams(rewardListView, {po = cc.p(rewardLayoutSize.width / 2, 28), ap = display.CENTER_BOTTOM})
        rewardLayout:addChild(rewardListView, 5)
        ---- rewardLayout ----
        ----------------------
        
        -----------------------
        ---- lotteryLayout ----
        local lotteryLayoutSize = cc.size(560, 382)
        local lotteryLayout = CLayout:create(lotteryLayoutSize)
        lotteryLayout:setPosition(cc.p(display.cx + 360, display.cy - 170))
        view:addChild(lotteryLayout, 1)
        local lotteryUILayout = CLayout:create(lotteryLayoutSize)
        lotteryUILayout:setPosition(cc.p(lotteryLayoutSize.width / 2, lotteryLayoutSize.height / 2))
        lotteryLayout:addChild(lotteryUILayout, 5)
        local lotteryLayoutBg = display.newImageView(RES_DICT.LOTTERY_LAYOUT_BG, lotteryLayoutSize.width / 2, lotteryLayoutSize.height / 2)
        lotteryLayout:addChild(lotteryLayoutBg, 1)
        -- 抽奖描述
        local lotteryDescrLabelBg = display.newImageView(RES_DICT.LOTTERY_DESCR_LABEL_BG, lotteryLayoutSize.width / 2, lotteryLayoutSize.height - 38)
        lotteryUILayout:addChild(lotteryDescrLabelBg, 5)
        local lotteryDescrLabel = display.newLabel(lotteryLayoutSize.width / 2, lotteryLayoutSize.height - 38, {text = '', fontSize = 24, color = '#58463c'})
        lotteryUILayout:addChild(lotteryDescrLabel, 5)
        -- 抽一次按钮
        local drawOneBtn = display.newButton(380, 250, {n = RES_DICT.DRAW_BTN_N})
        display.commonLabelParams(drawOneBtn, {text = app.anniversary2019Mgr:GetPoText(__('换1个')), fontSize = 24, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#5c5c5c', outlineSize = 2})
        lotteryUILayout:addChild(drawOneBtn, 5)
        local drawOneConsumeBg = display.newImageView(RES_DICT.LOTTERY_CONSUME_BG, 380, 180)
        lotteryUILayout:addChild(drawOneConsumeBg, 4)
        local drawOneConsumeLabel = display.newRichLabel(380, 183)
        lotteryUILayout:addChild(drawOneConsumeLabel, 4)
        -- 抽十次按钮
        local drawTenBtn = display.newButton(380, 95, {n = RES_DICT.DRAW_BTN_N})
        display.commonLabelParams(drawTenBtn, {text = app.anniversary2019Mgr:GetPoText(__('换10个')), fontSize = 24, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#5c5c5c', outlineSize = 2})
        lotteryUILayout:addChild(drawTenBtn, 5)
        local drawTenConsumeBg = display.newImageView(RES_DICT.LOTTERY_CONSUME_BG, 380, 25)
        lotteryUILayout:addChild(drawTenConsumeBg, 4)
        local drawTenConsumeLabel = display.newRichLabel(380, 28)
        lotteryUILayout:addChild(drawTenConsumeLabel, 4)
        -- 兔子spine
        local rabbitSpine = sp.SkeletonAnimation:create(
            RES_DICT.RABBIT_SPINE.json,
            RES_DICT.RABBIT_SPINE.atlas,
        1)
        rabbitSpine:setAnimation(0, 'play', false)
        rabbitSpine:addAnimation(0, 'idle', true)
        local changeData = app.anniversary2019Mgr:GetChangeSkinData()
        local spinePos = display.center
        if changeData.spineChangeData and changeData.spineChangeData.rabbitSpine then
            spinePos = changeData.spineChangeData.rabbitSpine.pos or display.center
        end
        local pos = lotteryLayout:convertToNodeSpace(spinePos)
        rabbitSpine:setPosition(pos)
        lotteryLayout:addChild(rabbitSpine, 3)
        ---- lotteryLayout ----
        -----------------------

        ----------------------
        ----- cardLayout -----
        local cardLayoutSize = cc.size(560, 300)
        local cardLayout = CLayout:create(cardLayoutSize)
        view:addChild(cardLayout, 1)
        cardLayout:setPosition(cc.p(display.cx + 360, display.cy + 180))
        -- 卡牌切图
        local cardLayoutBg = display.newImageView(RES_DICT.CARD_IMG, cardLayoutSize.width / 2, cardLayoutSize.height / 2)
        cardLayout:addChild(cardLayoutBg, 1)
        -- 卡牌预览
        local cardPreviewBtn = require("common.CardPreviewEntranceNode").new({confId = 200001})
        display.commonUIParams(cardPreviewBtn, {ap = display.RIGHT_BOTTOM, po = cc.p(cardLayoutSize.width - 2, 10)})
        cardLayout:addChild(cardPreviewBtn, 5)
        cardPreviewBtn:addChild(display.newLabel(105, 8, fontWithColor(14, {ap = display.RIGHT_CENTER, text = app.anniversary2019Mgr:GetPoText(__('卡牌详情'))})))
        ----- cardLayout -----
        ----------------------
        local rewardLayer = CColorView:create(cc.c4b(0, 0, 0, 255 * 0.6))
        rewardLayer:setTouchEnabled(true)
        rewardLayer:setContentSize(display.size)
        rewardLayer:setPosition(cc.p(display.cx, display.cy))
        rewardLayer:setVisible(false)
        view:addChild(rewardLayer, 10)
        local rewardSpine = sp.SkeletonAnimation:create(
            RES_DICT.REWARD_SPINE.json,
            RES_DICT.REWARD_SPINE.atlas,
        1)
        rewardSpine:setPosition(display.center)
        rewardLayer:addChild(rewardSpine, 10)

        -- top ui layer 
		local topUILayer = display.newLayer()
		topUILayer:setPositionY(190)
		view:addChild(topUILayer, 10)
		-- money barBg
		local moneyBarBg = display.newImageView(app.anniversary2019Mgr:GetResPath(RES_DICT.MONEY_INFO_BAR), display.width, display.height, {ap = display.RIGHT_TOP, scale9 = true, size = cc.size(1, 54)})
		topUILayer:addChild(moneyBarBg)
		-- money layer
		local moneyLayer = display.newLayer()
        topUILayer:addChild(moneyLayer)
        -- 返回按钮
        local backBtn = display.newButton(display.SAFE_L + 15, display.height - 55,
                {
                    ap = display.LEFT_CENTER,
                    n = RES_DICT.BACK_BTN,
                    scale9 = true, size = cc.size(90, 70),
                    enable = true,
                })
        view:addChild(backBtn, 10)
        return {
            view                = view,
            rewardLayout        = rewardLayout,
            turnLabel           = turnLabel,
            leftNumLabel        = leftNumLabel,
            tabNameLabel        = tabNameLabel,
            probabilityBtn      = probabilityBtn,
            rareRewardBtn       = rareRewardBtn,
            rewardListViewSize  = rewardListViewSize,
            rewardListView      = rewardListView,
            lotteryLayout       = lotteryLayout,
            lotteryUILayout     = lotteryUILayout,
            lotteryLayoutBg     = lotteryLayoutBg,
            drawOneBtn          = drawOneBtn,
            drawTenBtn          = drawTenBtn,
            rabbitSpine         = rabbitSpine,
            cardLayout          = cardLayout,
            cardPreviewBtn      = cardPreviewBtn,
			topUILayer		    = topUILayer,
			moneyBarBg          = moneyBarBg,
            moneyLayer          = moneyLayer,
            backBtn             = backBtn,    
            forenoticeImg       = forenoticeImg, 
            lotteryDescrLabel   = lotteryDescrLabel,
            drawOneConsumeLabel = drawOneConsumeLabel,
            drawTenConsumeLabel = drawTenConsumeLabel,
            rewardLayer         = rewardLayer,
            rewardSpine         = rewardSpine,
        }
    end
    -- eaterLayer
    local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 255 * 0.6))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setPosition(cc.p(display.cx, display.cy))
    self:addChild(eaterLayer, -1)
    self.eaterLayer = eaterLayer
    xTry(function ( )
        self.viewData = CreateView( )
        self:addChild(self.viewData.view)
        self.viewData.view:setPosition(display.center)
        -- 隐藏UI
        self:HideUI()
        self:EnterAction()
    end, __G__TRACKBACK__)
end
--[[
隐藏UI
--]]
function Anniversary19LotteryView:HideUI()
    local viewData = self:GetViewData()
    viewData.tabNameLabel:setVisible(false)
    viewData.rewardLayout:setOpacity(0)
    viewData.cardLayout:setOpacity(0)
    viewData.lotteryLayoutBg:setOpacity(0)
    viewData.lotteryUILayout:setOpacity(0)
end
--[[
进入动画
--]]
function Anniversary19LotteryView:EnterAction(  )
    -- 添加点击屏蔽
    app.uiMgr:GetCurrentScene():AddViewForNoTouch()
    
    local viewData = self:GetViewData()
    viewData.tabNameLabel:setVisible(true)
    local tabNameLabelPos = cc.p(viewData.tabNameLabel:getPosition())
    viewData.tabNameLabel:setPositionY(display.height + 100)
    local action = cc.EaseBounceOut:create(cc.MoveTo:create(1, tabNameLabelPos))
    self:runAction(
        cc.Sequence:create(
            cc.DelayTime:create(0.5),
            cc.Spawn:create(
                cc.TargetedAction:create(viewData.tabNameLabel, action),
                cc.TargetedAction:create(viewData.topUILayer, cc.MoveTo:create(0.4, cc.p(0, 0))),
                cc.TargetedAction:create(viewData.rewardLayout, cc.FadeIn:create(0.4)),
                cc.TargetedAction:create(viewData.cardLayout, cc.FadeIn:create(0.4)),
                cc.TargetedAction:create(viewData.lotteryLayoutBg, cc.FadeIn:create(0.4)),
                cc.TargetedAction:create(viewData.lotteryUILayout, cc.FadeIn:create(0.4))
            ),
            cc.CallFunc:create(function()
                -- 移除点击屏蔽
                app.uiMgr:GetCurrentScene():RemoveViewForNoTouch()
            end)
        )
    )
end
--[[
刷新道具数量
--]]
function Anniversary19LotteryView:UpdateGoodsNum()
	self:UpdateMoneyBar()
end
--[[
重载货币栏
--]]
function Anniversary19LotteryView:ReloadMoneyBar(moneyIdMap, isDisableGain)
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
		local isShowHpTips = (moneyId == HP_ID or moneyId == app.anniversary2019Mgr:GetHPGoodsId()) and 1 or -1
        local isDisable = moneyId ~= GOLD_ID and moneyId ~= DIAMOND_ID and isDisableGain
        local moneyNode = GoodPurchaseNode.new({id = moneyId, animate = true, disable = isDisable, isEnableGain = not isDisableGain, isShowHpTips = isShowHpTips})
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
	self:UpdateMoneyBar()
end
--[[
刷新货币栏
--]]
function Anniversary19LotteryView:UpdateMoneyBar()
    for _, moneyNode in ipairs(self:GetViewData().moneyLayer:getChildren()) do
        local moneyId = checkint(moneyNode:getName())
        moneyNode:updataUi(moneyId)
	end
end
--[[
刷新抽奖Layout
@params map {
    consume map {
        goodsId  int 抽奖道具id
        num int 抽奖1次消耗道具数量
    }
    leftNum int 剩余数量
}
--]]
function Anniversary19LotteryView:RefreshLotteryLayout( params )
    local viewData = self:GetViewData()
    local goodsConf = CommonUtils.GetConfig('goods', 'goods', params.consume.goodsId)
    --viewData.lotteryDescrLabel:setString(string.fmt(__('你愿意用_name_交换兔子先生的礼物盒吗？'), {['_name_'] = goodsConf.name}))
    display.commonLabelParams(viewData.lotteryDescrLabel , {
        text = string.fmt(app.anniversary2019Mgr:GetPoText(__('你愿意用_name_交换兔子先生的礼物盒吗？')), {['_name_'] = goodsConf.name}) , w = 500,hAlign = display.TAC
    })
    display.reloadRichLabel(viewData.drawOneConsumeLabel, {c = {
        {text = string.fmt(app.anniversary2019Mgr:GetPoText(__('消耗_num_')), {['_num_'] = params.consume.num}), fontSize = 20, color = '#ffffff'},
        {img = CommonUtils.GetGoodsIconPathById(params.consume.goodsId), scale = 0.18}
    }})
    display.reloadRichLabel(viewData.drawTenConsumeLabel, {c = {
        {text = string.fmt(app.anniversary2019Mgr:GetPoText(__('消耗_num_')), {['_num_'] = checkint(params.consume.num) * 10}), fontSize = 20, color = '#ffffff'},
        {img = CommonUtils.GetGoodsIconPathById(params.consume.goodsId), scale = 0.18}
    }})
    if params.leftNum < 10 then
        viewData.drawTenBtn:setEnabled(false)
        viewData.drawTenBtn:setNormalImage(RES_DICT.DRAW_BTN_D)
        viewData.drawTenBtn:setSelectedImage(RES_DICT.DRAW_BTN_D)
    else
        viewData.drawTenBtn:setEnabled(true)
        viewData.drawTenBtn:setNormalImage(RES_DICT.DRAW_BTN_N)
        viewData.drawTenBtn:setSelectedImage(RES_DICT.DRAW_BTN_N)
    end
end
--[[
刷新奖励Layout
@params map {
    rewardsData list 抽奖数据
    round       int  轮数
    totalNum    int  奖励总数
    leftNum     int  奖励剩余数量
    
}
--]]
function Anniversary19LotteryView:RefreshRewardLayout( params )
    local viewData = self:GetViewData()
    viewData.turnLabel:setString(string.fmt(app.anniversary2019Mgr:GetPoText(__('第_num_轮')), {['_num_'] = params.round}))
    viewData.leftNumLabel:setString(string.fmt(app.anniversary2019Mgr:GetPoText(__('剩余：_num1_/_num2_')), {['_num1_'] = params.leftNum, ['_num2_'] = params.totalNum}))
    self:RefreshRewardListView(params.lotteryData)
end
--[[
刷新奖励列表
@params rewardsData list 抽奖数据
--]]
function Anniversary19LotteryView:RefreshRewardListView( lotteryData )
    local viewData = self:GetViewData()
    local rewardListView = viewData.rewardListView
    rewardListView:removeAllNodes()
    rewardListView:insertNodeAtLast(self:CreateRewardsLayout(lotteryData.rareRewards, true))
    rewardListView:insertNodeAtLast(self:CreateRewardsLayout(lotteryData.commonRewards, false))
    rewardListView:reloadData()
end
--[[
刷新卡牌列表
@params cardId int 卡牌Id
--]]
function Anniversary19LotteryView:RefreshCardLayout( cardId )
    local viewData = self:GetViewData()
    viewData.cardPreviewBtn:RefreshUI({confId = cardId})
end
--[[
创建列表
@params rewardsData list 列表数据
@Params isRare      bool 是否为稀有
--]]
function Anniversary19LotteryView:CreateRewardsLayout( rewardsData, isRare )
    local viewData = self:GetViewData()
    local cellSize = cc.size(120, 151)
    local width    = viewData.rewardListViewSize.width
    local distance = ( viewData.rewardListViewSize.width - cellSize.width * 5) / 2
    local layout = nil
    local str = app.anniversary2019Mgr:GetPoText(__('普通'))
    if isRare then
        str  = app.anniversary2019Mgr:GetPoText(__('稀有'))
    end
    local count = #rewardsData
    if count > 0 then
        local fiveCount = math.ceil(count /5)  * 5
        local height =  math.ceil(count /5)* cellSize.height + 35
        local layoutSize = cc.size(width,height)
        layout = display.newLayer(width/2 , height, {color1 = cc.r4b() , size =layoutSize })
        local label = display.newLabel(distance -5 , height -20 , fontWithColor('8' ,{ap = display.LEFT_CENTER ,  text = str}))
        layout:addChild(label)
        local line = display.newImageView(RES_DICT.LIST_VIEW_SPLIT_LINE, width/2 , height -35)
        layout:addChild(line)
        for i, v in pairs(rewardsData) do
            local gridCellLayout = self:CreateGridCell(v, isRare)
            local heightline  = math.floor(((fiveCount -  i-0.5 + 1)/5))+0.5
            local widthline = (i-0.5 )%5
            gridCellLayout:setPosition(cc.p( cellSize.width*widthline  +distance , heightline *cellSize.height ))
            layout:addChild(gridCellLayout)
        end
    end
    return layout or CLayout:create(cc.size(0,0))
end
--[[
创建列表Cell
--]]
function Anniversary19LotteryView:CreateGridCell(data, isRare)
    data  = data or {}
    local bgImage = nil
    if isRare then
        bgImage = display.newImageView(RES_DICT.REWARD_CELL_RARE) 
    else
        bgImage = display.newImageView(RES_DICT.REWARD_CELL_COMMON) 
    end
    local bgSize = bgImage:getContentSize()
    local bgLayout = display.newLayer(bgSize.width/2 ,bgSize.height/2 ,{ap = display.CENTER , size = bgSize , color1 = cc.r4b()})
    bgLayout:addChild(bgImage)
    bgImage:setPosition(cc.p(bgSize.width/2 ,bgSize.height/2))
    local goodsNode = require("common.GoodNode").new({id = data.rewards[1].goodsId ,showAmount = true , num = checkint(data.rewards[1].num) })
    bgLayout:addChild(goodsNode)
    goodsNode:setScale(0.8)
    goodsNode:setPosition(cc.p(bgSize.width/2 , bgSize.height -60))
    local numLabel = display.newLabel(bgSize.width/2 , 25 ,fontWithColor('6',
                             { text = string.format("%d/%d" , checkint(data.stock), checkint(data.num))}))
    bgLayout:addChild(numLabel)
    display.commonUIParams(goodsNode, {animate = false, cb = function (sender)
        app.uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = data.rewards[1].goodsId, type = 1})
    end})
    if checkint(data.stock) == 0 then
        local blackImage = display.newImageView(RES_DICT.REWARD_CELL_DISABLE, bgSize.width/2 ,bgSize.height/2)
        bgLayout:addChild(blackImage)
    end
    return bgLayout
end
--[[
显示奖励spine
--]]
function Anniversary19LotteryView:ShowRewardSpine(animationName)
    local viewData = self:GetViewData()
    viewData.rewardLayer:setVisible(true)
    viewData.rewardSpine:update(0)
   	viewData.rewardSpine:setToSetupPose()
   	viewData.rewardSpine:setAnimation(0,animationName, false)
end
--[[
隐藏奖励spine
--]]
function Anniversary19LotteryView:HideRewardSpine()
    local viewData = self:GetViewData()
    viewData.rewardLayer:setVisible(false)

end
--[[
获取viewData
--]]
function Anniversary19LotteryView:GetViewData()
    return self.viewData
end
return Anniversary19LotteryView