local AirShipHomeView = class('AirShipHomeView', function ()
	local node = CLayout:create(display.size)
	node.name = 'Game.views.AirShipHomeView'
	node:enableNodeEvents()
	return node
end)

local GoodNode = require('common.GoodNode')

local ACCELERATELADE_CONF = CommonUtils.GetConfigAllMess('accelerateLade', 'airship') or {}

local RES_DIR = {
    SHIP_BOTTOM_BG = _res("ui/airship/ship_order_bg_dock.png"),  
    SHIP_AIR_SHIP_BG = _res("ui/airship/ship_order_ico_ship.png"), 
    SHIP_AIR_SHIP_BG_1 = _res("ui/airship/ship_order_ico_ship1.png"), 
    SHIP_ORDER_PRIZE_BG = _res("ui/airship/ship_order_bg_order_prize.png"), 
    SHIP_AIR_SHIP_DOOR = _res("ui/airship/ship_order_ico_door.png"), 
    -- SHIP_ORDER_BG_BLANK = _res("ui/airship/order_bg_blank.png"), 

    SHIP_ORDER_BG_ROLE_NAME = _res("ui/airship/ship_order_bg_role_name.png"), 
    SHIP_ORDER_ICO_LINE = _res("ui/airship/ship_order_ico_line.png"), 
    

    -----------------------------------  订单  -------------------------------------------
    SHIP_GOODS_READY = _res("ui/airship/ship_order_ico_goods_ready.png"), 
    SHIP_NO_GOODS = _res("ui/airship/ship_order_ico_no_goods_.png"), 
    SHIP_BOARD = _res("ui/airship/ship_order_ico_board.png"), 
    SHIP_RULE = _res("ui/airship/common_btn_tips.png"), 
    SHIP_GOODS_FINISHED = _res("ui/airship/ship_order_ico_goods_finished.png"), 

    SHIP_FINISHED_BOX = _res("ui/airship/ship_order_ico_goods_finished.png"), 
    SHIP_EMPTY_BOX = _res("ui/airship/ship_order_ico_box.png"), 
    SHIP_GOOD_BG_N = _res("ui/airship/ship_ico_label_goods_tag.png"), 
    SHIP_GOOD_BG_S = _res("ui/airship/ship_ico_label_goods_tag_selected.png"), 
    SHIP_GOOD_NUM_BG = _res("ui/airship/ship_order_label_goods_num.png"), 
    

    -----------------------------------  订单奖励  -------------------------------------------
    SHIP_ORDER_REWARD_BG = _res("ui/common/common_bg_goods.png"),
    SHIP_ORDER_REWARD_TITLE = _res("ui/common/common_title_5.png"),
    SHIP_DECORATE_KNIFE = _res("ui/common/common_decorate_knife.png"),
    SHIP_DECORATE_FORK = _res("ui/common/common_decorate_fork.png"),
    
    -----------------------------------  装箱  -------------------------------------------
    SHIP_PACK_BG = _res("ui/common/common_bg_4.png"),
    SHIP_PACK_TITLE = _res("ui/tower/ready/tower_label_title.png"),
    SHIP_PACK_ORDER_BG = _res("ui/home/raidMain/raid_mode_bg_active.png"),
    SHIP_PACK_ORDER_BG_SHADOW = _res("ui/airship/ship_order_bg_shadow.png"),
    SHIP_PACK_ORDER_REWARD_BG = _res("ui/airship/ship_order_bg_timenum.png"),
    SHIP_PACK_GRADE_BAR_1  = _res('ui/home/kitchen/cooking_bar_1.png'),
    SHIP_PACK_GRADE_BAR_2  = _res('ui/home/kitchen/cooking_bar_2.png'),    

    -----------------------------------  装载预告  -------------------------------------------
    SHIP_NOTICE_BG = _res("ui/common/common_bg_2.png"),
    SHIP_NOTICE_TITLE = _res("ui/common/common_bg_title_2.png"),
    SHIP_NOTICE_NO_GOODS = _res("ui/airship/ship_order_prebg_no_goods.png"), 
    SHIP_NOTICE_ORDER_LOCKED_BG = _res("ui/home/raidMain/raid_mode_bg_locked.png"),
    SHIP_NOTICE_WAIT_ORDER_BG_1 = _res("ui/airship/ship_order_bg_wait_ship.png"), 
    SHIP_NOTICE_WAIT_ORDER_TIME_BG = _res("ui/airship/ship_order_bg_wait_time.png"), 
    SHIP_NOTICE_WAIT_ORDER_TIME_NUM_BG = _res("ui/airship/ship_order_bg_timenum.png"), 
        

    SHIP_BUTTON_N = _res("ui/common/common_btn_orange.png"),
    SHIP_BUTTON_D = _res("ui/common/common_btn_orange_disable.png"),
    SHIP_BUTTON_N_GREEN = _res("ui/common/common_btn_green.png"),


    SHIP_ORDER_FG_1 = _res("ui/airship/ship_order_fg_1.png"), 

    COMMON_BTN_WHITE_DEFAULT = _res('ui/common/common_btn_white_default.png'),
    
}

local AIR_SHIP_ACTION_STATE = {
    SHOW_AIR_SHIP                    = 1,           -- 显示飞船
    HIDE_AIR_SHIP                    = 2,           -- 隐藏飞船
    SHOW_LOADING_NOTICE              = 3,           -- 显示装载预告
    HIDE_LOADING_NOTICE              = 4,           -- 隐藏装载预告
    SHOW_PACKING                     = 5,           -- 显示装载预告
    HIDE_PACKING                     = 6,           -- 隐藏装载预告
    SHOW_LOADING_NOTICE_POP_REWARD   = 7,           -- 在弹出奖励后显示装载预告
}

local CCB = cc.c3b(100,100,200)

local PATH_AIR_SHIP_CRAB_LID = "effects/airship/crabLid"
local PATH_AIR_SHIP_CRAB_BODY = "effects/airship/crabBody"

local CreateAirShipBgView = nil
-- 飞船UI
local CreateAirShipView = nil
-- 开船奖励UI
local CreateOrderPrizeView = nil
-- 飞船上的道具
local CreatePackGoodCell = nil
-- 装箱
local CreatePackingView = nil
-- 装箱奖励
local CreatePickReward = nil
-- 装载预告
local CreateLoadingNoticeView = nil
-- 活动卡牌视图
local CreateActivityCardView = nil
-- 卡牌spine
local CreateCardSpine = nil

function AirShipHomeView:ctor( ... )
    self.args = unpack({...})
    self:InitialUI()
end


function AirShipHomeView:InitialUI()
    local function CreateView()

        -- cc.c4b(0, 0, 0, 130)
        local view = display.newLayer(0, 0, {ap = display.LEFT_BOTTOM, size = display.size})
        local touchView = display.newLayer(0, 0, {color = cc.c4b(0, 0, 0, 130), enable = true, size = display.size, ap = display.LEFT_BOTTOM})

        self:addChild(touchView)
        self:addChild(view)

        local spineCrabBody = sp.SkeletonAnimation:create(string.format("%s.json", PATH_AIR_SHIP_CRAB_LID),string.format('%s.atlas', PATH_AIR_SHIP_CRAB_LID), 1)
        local spineCrabLid = sp.SkeletonAnimation:create(string.format("%s.json", PATH_AIR_SHIP_CRAB_BODY),string.format('%s.atlas', PATH_AIR_SHIP_CRAB_BODY), 1)
        
        spineCrabBody:setAnchorPoint(display.CENTER_BOTTOM)
        spineCrabLid:setAnchorPoint(display.CENTER_BOTTOM)
        
        spineCrabBody:setPosition(cc.p(display.width / 2, 64))
        spineCrabLid:setPosition(cc.p(display.width / 2, 64))

        spineCrabBody:setToSetupPose()
        spineCrabLid:setToSetupPose()

        local bgBlankSize = cc.size(240 + display.SAFE_L, 643)
        local bgBlankLeftView = display.newLayer(0, display.height, {color = cc.c4b(0, 0, 0, 0), enable = true, size = bgBlankSize, ap = display.LEFT_TOP, cb = handler(self, self.CloseHandler)})
        view:addChild(bgBlankLeftView)

        local bgBlankRightView = display.newLayer(display.width, display.height, {color = cc.c4b(0, 0, 0, 0), enable = true, size = bgBlankSize, ap = display.RIGHT_TOP, cb = handler(self, self.CloseHandler)})
        view:addChild(bgBlankRightView)
        
        --  排行榜
        local rankBtn = nil
        if CommonUtils.GetModuleAvailable(MODULE_SWITCH.RANKING) then
            rankBtn = display.newButton(display.SAFE_R - 10, display.height - 140, {ap = display.RIGHT_BOTTOM, n = _res('ui/home/teamformation/choosehero/team_btn_selection_unused.png') , scale9 = true })
            display.commonLabelParams(rankBtn, fontWithColor('14', {text = __('排行榜')}))
            local rankBtnLabelSize = rankBtn:getLabel():getContentSize()
            rankBtn:setContentSize(cc.size(rankBtnLabelSize.width+10 , 40) )
        end

        local timeLimitActivityBg = display.newSprite(RES_DIR.SHIP_ORDER_FG_1, display.width / 2, display.cy + 80, {ap = display.CENTER_TOP})
        local bottomBg = display.newImageView(RES_DIR.SHIP_BOTTOM_BG, display.cx, -120, {ap = display.CENTER_BOTTOM})
        
        local airShipViewData = CreateAirShipView()
        local orderPrizeViewData = CreateOrderPrizeView()
        local packingViewData = CreatePackingView()
        local loadingNoticeViewData = CreateLoadingNoticeView()
        local cardPreviewViewData = CreateActivityCardView()
        
        
        local airShipLayer = airShipViewData.airShipLayer        
        local orderPrizeLayer = orderPrizeViewData.orderPrizeLayer
        local packingLayer = packingViewData.packingLayer
        local loadingNoticeView = loadingNoticeViewData.view
        local cardPreviewView   = cardPreviewViewData.view

        view:addChild(spineCrabBody)
        view:addChild(airShipLayer)
        view:addChild(spineCrabLid)
        view:addChild(timeLimitActivityBg)
        view:addChild(bottomBg)
        if rankBtn then view:addChild(rankBtn) end
        view:addChild(orderPrizeLayer)
        view:addChild(loadingNoticeView)
        view:addChild(packingLayer)
        view:addChild(cardPreviewView)
        

        spineCrabBody:setVisible(false)
        spineCrabLid:setVisible(false)
        timeLimitActivityBg:setVisible(false)
        bottomBg:setVisible(false)
        airShipLayer:setVisible(false)
        orderPrizeLayer:setVisible(false)
        packingLayer:setVisible(false)
        loadingNoticeView:setVisible(false)
        -- cardPreviewView:setVisible(false)
        
        return {
            view                  = view,
            bottomBg              = bottomBg,
            airShipViewData       = airShipViewData,
            orderPrizeViewData    = orderPrizeViewData,
            packingViewData       = packingViewData,
            loadingNoticeViewData = loadingNoticeViewData,
            cardPreviewViewData   = cardPreviewViewData,
            timeLimitActivityBg   = timeLimitActivityBg,
            rankBtn               = rankBtn,
            -- spine 动画 
            spineCrabBody         = spineCrabBody,
            spineCrabLid          = spineCrabLid,
        }
    end

    xTry(function ( )
		self.viewData = CreateView( )
	end, __G__TRACKBACK__)
end

function AirShipHomeView:updateTimeLimitActivityBg(rareCardBg)
    local timeLimitActivityBg = self.viewData.timeLimitActivityBg
    if rareCardBg then
        local path = _res(string.format( "ui/airship/%s.png", rareCardBg))
        local isShowBg = utils.isExistent(path)
        if isShowBg then
            timeLimitActivityBg:setTexture(path)
        end
        timeLimitActivityBg:setVisible(isShowBg)
    else
        timeLimitActivityBg:setVisible(false)
    end
end

function AirShipHomeView:updateActivityCardView(rareCardId)
    rareCardId = checkint(rareCardId)
    if rareCardId <= 0 then
        return
    end

    local cardPreviewViewData = self.viewData.cardPreviewViewData
    self:updateCardPreviewSpine(rareCardId)

    local cardConf = CardUtils.GetCardConfig(rareCardId) or {}
    local roleName        = cardPreviewViewData.roleName
    display.commonLabelParams(roleName, {text = tostring(cardConf.name), reqW = 168})

    local cardPreviewBtn  = cardPreviewViewData.cardPreviewBtn
    cardPreviewBtn:RefreshUI({confId = rareCardId})

    -- self.viewData.cardPreviewViewData.view:setVisible(false)
end

function AirShipHomeView:updateCardPreviewSpine(rareCardId)
    local cardPreviewViewData = self.viewData.cardPreviewViewData
    local cardPreviewView = cardPreviewViewData.view
    local qAvatar = cardPreviewViewData.qAvatar
    if qAvatar == nil then
        qAvatar = CreateCardSpine(rareCardId)
        qAvatar:setPosition(cc.p(display.SAFE_L + 230, 25))
        qAvatar:setTag(rareCardId)
        cardPreviewView:addChild(qAvatar)
        cardPreviewViewData.qAvatar = qAvatar
    else
        local confId = checkint(qAvatar:getTag())
        if confId ~= rareCardId then
            qAvatar:setVisible(false)
            qAvatar:runAction(cc.RemoveSelf:create())
            
            qAvatar = CreateCardSpine(rareCardId)
            qAvatar:setPosition(cc.p(display.SAFE_L + 230, 25))
            qAvatar:setTag(rareCardId)
            cardPreviewView:addChild(qAvatar)
            cardPreviewViewData.qAvatar = qAvatar
        end
    end
end

function AirShipHomeView:updateOnKeyBtnShowState(isCanPack)
    local oneKeyPackBtn = self.viewData.airShipViewData.oneKeyPackBtn
    local img = isCanPack and RES_DIR.SHIP_BUTTON_N_GREEN or RES_DIR.SHIP_BUTTON_D
    oneKeyPackBtn:setNormalImage(img)
    oneKeyPackBtn:setSelectedImage(img)
end

CreateAirShipView = function ()
    
    local bgSize = display.size
    local layer = display.newLayer(0, 0, {size = bgSize, ap = display.LEFT_BOTTOM})

    local ruleBtn = display.newButton(bgSize.width / 2 - 120, 575, {n = RES_DIR.SHIP_RULE, ap = display.CENTER_BOTTOM})
    layer:addChild(ruleBtn)

    local titleLabel = display.newLabel(bgSize.width / 2 - 100, ruleBtn:getPositionY() + 20, fontWithColor(1, {ap = display.LEFT_CENTER,  text = __("巨钳蟹货船"),reqW= 200 }))
    layer:addChild(titleLabel)
    local titleLabelSize = display.getLabelContentSize(titleLabel)
    if  titleLabelSize.width >  350 then
        display.commonLabelParams(titleLabel , {w = 290 , reqW  = 210 })
    end

    local touchView = display.newLayer(0, 0, {color = cc.c4b(0, 0, 0, 0), enable = true, size = cc.size(bgSize.width - 387, bgSize.height), ap = display.LEFT_BOTTOM})
    touchView:setVisible(false)
    layer:addChild(touchView)

    local cells = {}
    for i = 1, 8 do
        local cell = CreatePackGoodCell()
        local params = {index = i, goodNodeSize = cell:getContentSize(), midPointX = bgSize.width / 2, midPointY = 410, col = 4, maxCol = 4, scale = 1, goodGap = 12}
        local pos = CommonUtils.getGoodPos(params)
        -- dump(pos, 'cellcell')
        display.commonUIParams(cell, {po = pos})
        table.insert(cells, cell)
        local z = i <= 4 and 2 or 1
        layer:addChild(cell, z)
    end

    local oneKeyPackBtn = display.newButton(bgSize.width / 2, 205, {n = RES_DIR.SHIP_BUTTON_N_GREEN , scale9 = true })
    display.commonLabelParams(oneKeyPackBtn, fontWithColor(14, {text = __('全部装箱')  ,paddingW =  20 }))
    layer:addChild(oneKeyPackBtn, 1)

    local board = display.newImageView(RES_DIR.SHIP_BOARD, bgSize.width / 2, 430)
    layer:addChild(board, 1)
    
    return {
        airShipLayer = layer,
        touchView = touchView,
        ruleBtn = ruleBtn,
        oneKeyPackBtn = oneKeyPackBtn,
        cells = cells,
    }
end

CreateOrderPrizeView = function ()
    local orderPrizeBg = display.newImageView(RES_DIR.SHIP_ORDER_PRIZE_BG, 0, 0, {ap = display.LEFT_BOTTOM})
    local orderPrizeBgSize = orderPrizeBg:getContentSize()
    local layer = display.newLayer(display.SAFE_R, 0, {size = orderPrizeBgSize, ap = display.RIGHT_BOTTOM})
    layer:addChild(orderPrizeBg)

    -- scale9, size
    local rewardBgSize = cc.size(425, 134)
    local rewardBg = display.newImageView(RES_DIR.SHIP_ORDER_REWARD_BG, orderPrizeBgSize.width * 0.1, 8, {scale9 = true, size = rewardBgSize,ap = display.LEFT_BOTTOM})
    layer:addChild(rewardBg)

    local titleBg = display.newButton( rewardBgSize.width / 2, rewardBgSize.height * 0.98, {enable = false ,  n = RES_DIR.SHIP_ORDER_REWARD_TITLE ,  ap = display.CENTER_TOP, scale9 = true })
    display.commonLabelParams(titleBg , fontWithColor(5, {text = __("开船奖励") , paddingW = 30 }))
    --local titleLabel = display.newLabel(0, 0, fontWithColor(5, {text = __("开船奖励")}))
    --display.commonUIParams(titleLabel, {po = cc.p(utils.getLocalCenter(titleBg))})

    --titleBg:addChild(titleLabel)
    rewardBg:addChild(titleBg)

    local rewardListSize = cc.size(385, 100)
    local rewardList = CListView:create(rewardListSize)
    rewardList:setDirection(eScrollViewDirectionHorizontal)
    rewardList:setAnchorPoint(display.CENTER_BOTTOM)
    rewardList:setPosition(rewardBg:getPositionX() + rewardBgSize.width / 2, rewardBg:getPositionY())
    layer:addChild(rewardList)
    
    local sailBtn = display.newButton(orderPrizeBgSize.width * 0.83, orderPrizeBgSize.height * 0.45, {n = RES_DIR.SHIP_BUTTON_N, d = RES_DIR.SHIP_BUTTON_D})
    display.commonLabelParams(sailBtn, fontWithColor(14, {text = __("开船")}))
    local sailBtnLabelSize = display.getLabelContentSize(sailBtn:getLabel())
    local sailBtnSize = sailBtn:getContentSize()
    if sailBtnLabelSize.width > 150  then
        display.commonLabelParams(sailBtn, fontWithColor(14, {text = __("开船"), w = 150, hAlign = display.TAC}))
        sailBtn:setContentSize(cc.size(160 ,sailBtnLabelSize.height * 2 +  15  ))
    else
        display.commonLabelParams(sailBtn, fontWithColor(14, {text = __("开船"), paddingW = 10}))
    end
    layer:addChild(sailBtn)

    return {
        orderPrizeLayer = layer,
        rewardList      = rewardList,
        -- goodsNodes = goodsNodes,
        sailBtn = sailBtn
    }
end

CreatePackingView = function ()
    local viewSize = cc.size(387, display.height)
    local view = display.newLayer(display.SAFE_R, 0, {size = viewSize, ap = display.RIGHT_BOTTOM})
    local touchView = display.newLayer(viewSize.width, 0, {color = cc.c4b(0, 0, 0, 0), enable = true, size = viewSize, ap = display.RIGHT_BOTTOM})
    view:addChild(touchView)
    
    local shadowBg = display.newImageView(RES_DIR.SHIP_PACK_ORDER_BG_SHADOW, 5, 0, {ap = display.CENTER_BOTTOM})
    view:addChild(shadowBg)

    local packingViewBgSize = cc.size(387, display.height * 0.9)
    local packingViewBg = display.newImageView(RES_DIR.SHIP_PACK_BG, 0, 0, {size = packingViewBgSize, scale9 = true, ap = display.LEFT_BOTTOM})
    local layer = display.newLayer(viewSize.width, 0, {size = packingViewBgSize, ap = display.RIGHT_BOTTOM})
    view:addChild(layer)
    layer:addChild(packingViewBg)

    local titleBg = display.newImageView(RES_DIR.SHIP_PACK_TITLE, packingViewBgSize.width / 2, packingViewBgSize.height * 0.98, {ap = display.CENTER_TOP})
    local titleLabel = display.newLabel(0, 0, fontWithColor(5, {text = __("装箱")}))
    display.commonUIParams(titleLabel, {po = cc.p(utils.getLocalCenter(titleBg))})
    titleBg:addChild(titleLabel)
    packingViewBg:addChild(titleBg)

    local tipLabel = display.newLabel(packingViewBgSize.width / 2, packingViewBgSize.height * 0.915, fontWithColor(6, {text = __("tips: 填装对应道具可获得装箱奖励。"), ap = display.CENTER, w = 346}))
    local tipLabelSize  =  display.getLabelContentSize(tipLabel)
    local tipLayoutSize = cc.size(350 , 80 )
    local tipLayout = display.newLayer(0,0, {size =  tipLabelSize})
    tipLabel:setPosition(tipLabelSize.width/2 , tipLabelSize.height/2)
    tipLayout:addChild(tipLabel)
    local tipListView = CListView:create(tipLayoutSize)
    tipListView:setDirection(eScrollViewDirectionVertical)
    tipListView:setAnchorPoint(display.CENTER_TOP)
    tipListView:setPosition(cc.p(packingViewBgSize.width / 2, packingViewBgSize.height * 0.915))
    tipListView:insertNodeAtLast(tipLayout)
    layer:addChild(tipListView,2)
    tipListView:reloadData()

    local orderBg = display.newImageView(RES_DIR.SHIP_PACK_ORDER_BG, 0, 0, {ap = display.LEFT_BOTTOM})
    local orderBgSize = orderBg:getContentSize()
    local orderBgLayer = display.newLayer(titleBg:getPositionX(), packingViewBgSize.height * 0.82, {size = orderBgSize, ap = display.CENTER_TOP})
    orderBgLayer:addChild(orderBg)
    layer:addChild(orderBgLayer)

    local recipeNameLabel = display.newLabel(orderBgSize.width / 2, orderBgSize.height * 0.75, fontWithColor(11, {text = ''}))
    orderBgLayer:addChild(recipeNameLabel)

    local goodNodeCallBack = function (sender)
        -- AppFacade.GetInstance():GetManager("UIManager"):ShowInformationTipsBoard({targetNode = sender, iconId = sender.goodId, type = 1})
        AppFacade.GetInstance():GetManager("UIManager"):AddDialog("common.GainPopup", {goodId = sender.goodId, isFrom = 'AirShipHomeMediator'})
    end
    local goodNode = GoodNode.new({id = 150061, showAmount = false, callBack = goodNodeCallBack})
    goodNode:setPosition(cc.p(orderBgSize.width / 2, orderBgSize.height / 2))
    orderBgLayer:addChild(goodNode)

    local progressBar = CProgressBar:create(RES_DIR.SHIP_PACK_GRADE_BAR_1)
    progressBar:setBackgroundImage(RES_DIR.SHIP_PACK_GRADE_BAR_2)
    progressBar:setDirection(eProgressBarDirectionLeftToRight)
    -- progressBar:setMaxValue(100)
    -- progressBar:setValue(0)
    progressBar:setShowValueLabel(true)
    progressBar:setPosition(cc.p(orderBgSize.width / 2, orderBgSize.height * 0.25))
    progressBar:setAnchorPoint(display.CENTER)
    orderBgLayer:addChild(progressBar)

    display.commonLabelParams(progressBar:getLabel(),fontWithColor('9',{ text = '0/100'}))
    local pickRewardBgSize = cc.size(341, 137)
    local pickRewardBgLayer = display.newLayer(titleBg:getPositionX(), packingViewBgSize.height * 0.13, {size = pickRewardBgSize, ap = display.CENTER_BOTTOM})
    local pickRewardBg = display.newImageView(RES_DIR.SHIP_ORDER_REWARD_BG, pickRewardBgSize.width / 2, 0, {size = cc.size(341, 137), scale9 = true,ap = display.CENTER_BOTTOM})
    pickRewardBgLayer:addChild(pickRewardBg)
    layer:addChild(pickRewardBgLayer)

    local rewardTitleBg = display.newButton( pickRewardBgSize.width / 2, pickRewardBgSize.height * 0.97, {n = RES_DIR.SHIP_ORDER_REWARD_TITLE, enable = false ,  ap = display.CENTER_TOP})
    --local rewardTitleLabel = display.newLabel(0, 0, fontWithColor(5, {text = __("装箱奖励")}))
    --display.commonUIParams(rewardTitleLabel, {po = cc.p(utils.getLocalCenter(rewardTitleBg))})
    --rewardTitleBg:addChild(rewardTitleLabel)
    display.commonLabelParams(rewardTitleBg ,  fontWithColor(5, {text = __("装箱奖励") , paddingW = 30 }) )
    pickRewardBg:addChild(rewardTitleBg)

    local pickRewardLayerSize = cc.size(pickRewardBgSize.width, pickRewardBgSize.height / 2)
    local pickRewardLayer = display.newLayer(0, 0, {ap = display.LEFT_BOTTOM, size = pickRewardLayerSize})
    pickRewardBgLayer:addChild(pickRewardLayer)

    local packBtn = display.newButton(titleBg:getPositionX(), 22, {n = RES_DIR.SHIP_BUTTON_N, d = RES_DIR.SHIP_BUTTON_D, ap = display.CENTER_BOTTOM})
    display.commonLabelParams(packBtn, fontWithColor(14, {text = __("装箱")}))
    layer:addChild(packBtn)

    return {
        -- packingLayer = layer,
        packingLayer = view,
        pickRewardLayer = pickRewardLayer,
        recipeNameLabel = recipeNameLabel,
        progressBar = progressBar,
        goodNode = goodNode,
        packBtn = packBtn,
    }
end

CreatePickReward = function (parent, pickRewards)
    if pickRewards == nil then return end
    if parent and parent:getChildrenCount() > 0 then parent:removeAllChildren() end
    
    local parentSize = parent:getContentSize()
    local pickRewardLen = #pickRewards

    local params = {parent = parent, midPointX = parentSize.width * 0.5, midPointY = parentSize.height * 0.75, maxCol= 3, scale = 0.8, rewards = pickRewards, hideCustomizeLabel = true}
    local goodsNodes = CommonUtils.createPropList(params)
end

CreateLoadingNoticeView = function ()
    local view = display.newLayer(0, 0, {ap = display.LEFT_BOTTOM, size = display.size})
    -- local touchLayer = display.newLayer(0, 0, {color = cc.c4b(0, 0, 0, 0), enable = true, ap = display.LEFT_BOTTOM, size = display.size, cb = function ()
    --     view:removeFromParent()
    -- end})
    -- view:addChild(touchLayer)
    
    local bg = display.newImageView(RES_DIR.SHIP_NOTICE_BG, 0, 0, {ap = display.LEFT_BOTTOM})
    local bgSize = bg:getContentSize()
    local layer = display.newLayer(display.cx + 56, display.cy, { size = bgSize, ap = display.CENTER})
    local dTouchLayer = display.newLayer(0, 0, {color = cc.c4b(0, 0, 0, 0), enable = true, ap = display.LEFT_BOTTOM, size = bgSize})
    layer:addChild(dTouchLayer)
    layer:addChild(bg)
    view:addChild(layer)

    local titleBg = display.newImageView(RES_DIR.SHIP_NOTICE_TITLE, bgSize.width / 2, bgSize.height * 0.99, {ap = display.CENTER_TOP})
    local titleLabel = display.newLabel(0, 0, fontWithColor(3, {text = __("装载预告")}))
    display.commonUIParams(titleLabel, {po = cc.p(utils.getLocalCenter(titleBg))})
    titleBg:addChild(titleLabel)
    layer:addChild(titleBg)

    local tipLabel = display.newLabel(bgSize.width * 0.5, bgSize.height * 0.92, fontWithColor(5, {text = __("快去准备下一单的食物吧，当然奖励也是丰厚的!"), ap = display.CENTER_TOP}))
    layer:addChild(tipLabel)

    local noticeOrderBgSize = cc.size(bgSize.width * 0.9, bgSize.height * 0.59)
    local noticeOrderBg = display.newImageView(RES_DIR.SHIP_ORDER_REWARD_BG, 0, 0, {scale9 = true, size = noticeOrderBgSize, ap = display.LEFT_BOTTOM})
    local noticeOrderBgLayer = display.newLayer(bgSize.width / 2, bgSize.height * 0.87, {size = noticeOrderBgSize, ap = display.CENTER_TOP})
    noticeOrderBgLayer:addChild(noticeOrderBg)
    layer:addChild(noticeOrderBgLayer)

    local function CreateNoticeOrderCell()
        local scale = 0.52
        local activeBg = display.newImageView(RES_DIR.SHIP_PACK_ORDER_BG, 0, 0, {scale = scale, ap = display.CENTER_TOP})
        local cellBgSize = activeBg:getContentSize()
        cellBgSize = cc.size(cellBgSize.width * scale, cellBgSize.height * scale)
        local orderCell = display.newLayer(0, 0, {size = cellBgSize, ap = display.CENTER_TOP})
        display.commonUIParams(activeBg, {po = cc.p(cellBgSize.width / 2, cellBgSize.height)})
        orderCell:addChild(activeBg)
        
        local goodNodeCallBack = function (sender)
            AppFacade.GetInstance():GetManager("UIManager"):AddDialog("common.GainPopup", {goodId = sender.goodId, isFrom = 'AirShipHomeMediator'})
        end
        local goodNode = GoodNode.new({id = 150061, showName = true, showAmount = false, callBack = goodNodeCallBack})
        goodNode.fragmentImg:setVisible(false)
        goodNode.bg:setVisible(false)
        goodNode.icon:setScale(0.8)
        local  nameLabel = goodNode.nameLabel
        local namePos = cc.p(nameLabel:getPosition())
        nameLabel:setPositionY(namePos.y + 30)
        display.commonUIParams(goodNode, {po = cc.p(cellBgSize.width / 2, cellBgSize.height * 0.55)})
		orderCell:addChild(goodNode)

        local noGoodBg = display.newImageView(RES_DIR.SHIP_NOTICE_NO_GOODS, cellBgSize.width / 2, cellBgSize.height, {ap = display.CENTER_TOP})
        noGoodBg:setVisible(false)
		orderCell:addChild(noGoodBg)

        orderCell.viewData = {
            activeBg = activeBg,
            goodNode = goodNode,
            noGoodBg = noGoodBg,
        }
        return orderCell
    end

    local orderCells = {}
    for i=1,8 do
        local orderCell = CreateNoticeOrderCell()
        local params = {index = i, goodNodeSize = orderCell:getContentSize(), midPointX = bgSize.width / 2, midPointY =  bgSize.height * 0.87, col = 4, maxCol = 4, scale = 1, goodGap = 6}
        local pos = CommonUtils.getGoodPos(params)
        display.commonUIParams(orderCell, {po = pos})
        layer:addChild(orderCell)

        table.insert(orderCells, orderCell)
    end

    local countDownBg = display.newImageView(RES_DIR.SHIP_NOTICE_WAIT_ORDER_BG_1, 0, 0, {ap = display.LEFT_BOTTOM})
    local countDownBgSize = countDownBg:getContentSize()
    local countDownLayer = display.newLayer(bgSize.width / 2, bgSize.width * 0.03, {size = countDownBgSize, ap = display.CENTER_BOTTOM})
    countDownLayer:addChild(countDownBg)
    layer:addChild(countDownLayer)
    local countDownTipLb = display.newLabel(countDownBgSize.width / 2, countDownBgSize.height * 0.9, fontWithColor(16, {text = __("下一艘飞艇进港还需要等到："), ap = display.CENTER_TOP}))
    countDownLayer:addChild(countDownTipLb)

    local timeBg = display.newImageView(RES_DIR.SHIP_NOTICE_WAIT_ORDER_TIME_BG, countDownBgSize.width * 0.5, countDownBgSize.height / 2, {ap = display.CENTER})
    local timeBgSize = timeBg:getContentSize()
    countDownLayer:addChild(timeBg)

    local function CreateTimeNum(parent)
        local timeNumBg = display.newImageView(RES_DIR.SHIP_NOTICE_WAIT_ORDER_TIME_NUM_BG, 0, 0)
        local timeNumLabel = display.newLabel(0, 0, fontWithColor(3, {text = '0'}))
        display.commonUIParams(timeNumLabel, {po = utils.getLocalCenter(timeNumBg)})
        timeNumBg:addChild(timeNumLabel)
        parent:addChild(timeNumBg)
        return timeNumBg, timeNumLabel
    end 

    local timeNumConf = {
        1, 1, 0, 1, 1, 0, 1, 1
    }
    local timeNums = {}
    local posX = timeBgSize.width * 0.22
    for i,v in ipairs(timeNumConf) do
        if v == 1 then
            local timeNumBg, timeNumLabel = CreateTimeNum(timeBg)
            display.commonUIParams(timeNumBg, {po = cc.p(posX, timeBgSize.height / 2)})
            posX = posX + 32
            table.insert(timeNums, timeNumLabel)
        else
            local lb = display.newLabel(posX - 7, timeBgSize.height / 2, fontWithColor(3, {text = ':'}))
            timeBg:addChild(lb)
            posX = posX + 16
        end
    end

    -- 创建加速按钮
    local accelerateBtns = {}
    local btnSize = cc.size(123, 59)
    local accelerateConf = {}
    local btnCount = 0
    for key, value in pairs(ACCELERATELADE_CONF) do
        table.insert(accelerateConf, value)
        btnCount = btnCount + 1
    end
    local diamondId = DIAMOND_ID
    table.sort(accelerateConf, function (a, b)
        local aPriority = checkint(a.goodsId) == diamondId and 1 or 0
        local bPriority = checkint(b.goodsId) == diamondId and 1 or 0
        return aPriority < bPriority
    end)

    for index, conf in pairs(accelerateConf) do
        local goodsId = checkint(conf.goodsId)
        local img = goodsId == diamondId and RES_DIR.SHIP_BUTTON_N_GREEN or RES_DIR.COMMON_BTN_WHITE_DEFAULT
        local pos = CommonUtils.getGoodPos({index = index, goodNodeSize = btnSize, midPointX = countDownBgSize.width * 0.5, midPointY = 50, col = btnCount, maxCol = btnCount, goodGap = 100})
        local btn = display.newButton(pos.x, 50, {n = img, scale9 = true, size = btnSize, ap = display.CENTER_TOP})
        countDownLayer:addChild(btn)

        local richLabel = display.newRichLabel(btnSize.width * 0.5, btnSize.height * 0.5, {})
        richLabel:setTag(2000)
        btn:addChild(richLabel)

        accelerateBtns[goodsId] = btn
    end

    return {
        view               = view,
        layer              = layer,
        timeNums           = timeNums,
        orderCells         = orderCells,
        accelerateBtns     = accelerateBtns,
    }
end

--  0: 未完成 1: 已完成 2:无状态
CreatePackGoodCell = function ()
    local layer = display.newLayer(0, 0, {color = cc.c4b(0, 0, 0, 0), enable = true, ap = display.CENTER_BOTTOM})
    -- SHIP_FINISHED_BOX
    -- SHIP_EMPTY_BOX
    local orderRes = {
        [0] = RES_DIR.SHIP_EMPTY_BOX,
        [1] = RES_DIR.SHIP_FINISHED_BOX,
        [2] = RES_DIR.SHIP_EMPTY_BOX,
    }

    local orderImgs = {}

    local imgSize = nil
    for i,v in pairs(orderRes) do
        local imgView = display.newImageView(v, 0, 0, {ap = display.LEFT_BOTTOM})
        if imgSize == nil then
            imgSize = imgView:getContentSize() 
            layer:setContentSize(imgSize)
        end
        imgView:setVisible(false)
        layer:addChild(imgView)
        orderImgs[i] = imgView
    end
    
    local goodBgN = display.newImageView(RES_DIR.SHIP_GOOD_BG_N, imgSize.width / 2, imgSize.height * 0.16, {ap = display.CENTER_BOTTOM})
    local goodBgS = display.newImageView(RES_DIR.SHIP_GOOD_BG_S, imgSize.width / 2, imgSize.height * 0.16, {ap = display.CENTER_BOTTOM})
    goodBgS:setVisible(false)
    goodBgN:setVisible(false)
    orderImgs[0]:addChild(goodBgS)
    orderImgs[0]:addChild(goodBgN)

    local goodNode = GoodNode.new({id = 150061, showAmount = false})
    goodNode.fragmentImg:setVisible(false)
    goodNode.bg:setVisible(false)
    display.commonUIParams(goodNode,{po = cc.p(imgSize.width / 2, imgSize.height * 0.22), ap = display.CENTER_BOTTOM})
    orderImgs[0]:addChild(goodNode)

    -----------------  数字  ------------------
    local numBg = display.newImageView(RES_DIR.SHIP_GOOD_NUM_BG, imgSize.width / 2, imgSize.height * 0.08, {ap = display.CENTER_BOTTOM})
    local numBgSize = numBg:getContentSize()
    orderImgs[0]:addChild(numBg) 
    -- local nextEnergyLabel = display.newRichLabel(numBgSize.width / 2, numBgSize.height / 2, {ap = cc.p(0.5, 0.55)})
    -- numBg:addChild(nextEnergyLabel)

    local ownNumLabel = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '10')
    ownNumLabel:setHorizontalAlignment(display.TAR)
    ownNumLabel:setAnchorPoint(display.CENTER)
    ownNumLabel:setPosition(numBgSize.width / 2, numBgSize.height / 2)
    -- ownNumLabel:setScale(0.9)
    numBg:addChild(ownNumLabel)

    local needNumLabel = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '10')
    needNumLabel:setHorizontalAlignment(display.TAR)
    needNumLabel:setAnchorPoint(display.CENTER)
    needNumLabel:setPosition(numBgSize.width / 2, numBgSize.height / 2)
    -- needNumLabel:setScale(0.9)
    numBg:addChild(needNumLabel)

    layer.viewData = {
        goodBgN = goodBgN,
        goodBgS = goodBgS,
        goodNode = goodNode,
        orderImgs = orderImgs,
        ownNumLabel = ownNumLabel,
        needNumLabel = needNumLabel,
        -- nextEnergyLabel = nextEnergyLabel,

        numBgSize = numBgSize,
    }

    return layer
end

CreateActivityCardView = function ()
    local view = display.newLayer()
    view:setCascadeOpacityEnabled(true)

    view:addChild(display.newLayer(display.SAFE_L + 205, 10, {ap = display.CENTER_BOTTOM, size = cc.size(300, 300), color = cc.c4b(0,0,0,0), enable = true}))

    local roleNameBg = display.newImageView(RES_DIR.SHIP_ORDER_BG_ROLE_NAME, display.SAFE_L + 230, 25, {ap = display.CENTER_BOTTOM})
    roleNameBg:setCascadeOpacityEnabled(true)
    view:addChild(roleNameBg, 1)
    
    roleNameBg:addChild(display.newLabel(134, 60, {text = __("本期嘉宾"), reqW = 180, fontSize = 22, color = '#ddc99f'}), 1)
    
    roleNameBg:addChild(display.newSprite(RES_DIR.SHIP_ORDER_ICO_LINE, 134, 43), 1)

    local roleName = display.newLabel(134, 20, fontWithColor(19, {reqW = 168}), 1)
    roleNameBg:addChild(roleName)

    local cardPreviewBtn = require("common.CardPreviewEntranceNode").new()
    display.commonUIParams(cardPreviewBtn, {ap = display.CENTER, po = cc.p(display.SAFE_L + 96, 66)})
    view:addChild(cardPreviewBtn, 1)
    
    -- view:setOpacity(0)
    -- view:runAction(cc.FadeIn:create(2))

    return {
        view           = view,
        -- qAvatar        = qAvatar,
        roleName       = roleName,
        cardPreviewBtn = cardPreviewBtn,
    }
end

CreateCardSpine = function (confId)
    local qAvatar = AssetsUtils.GetCardSpineNode({confId = confId, scale = 0.7})
    qAvatar:update(0)
    qAvatar:setToSetupPose()
    qAvatar:setAnimation(0, 'idle', true)
    return qAvatar
end

function AirShipHomeView:showUiAction(state, cb)
    local action = nil

    local bottomBg = self.viewData.bottomBg
    local spineCrabBody = self.viewData.spineCrabBody
    local spineCrabLid = self.viewData.spineCrabLid

    local airShipLayer = self.viewData.airShipViewData.airShipLayer
    local touchView = self.viewData.airShipViewData.touchView

    local orderPrizeLayer = self.viewData.orderPrizeViewData.orderPrizeLayer
    local packingLayer = self.viewData.packingViewData.packingLayer
    
    local loadingNoticeView = self.viewData.loadingNoticeViewData.view
    local loadingNoticeLayer = self.viewData.loadingNoticeViewData.layer
    -- local loadingNoticeRoleLayer = self.viewData.loadingNoticeViewData.roleLayer
    
    local cardPreviewViewData = self.viewData.cardPreviewViewData
    local cardPreviewView = cardPreviewViewData.view

    local bottomBgPosx, bottomBgPosy = bottomBg:getPosition()
    local airShipLayerPosx, airShipLayerPosy = airShipLayer:getPosition()
    local orderPrizeLayerPosx, orderPrizeLayerPosy = orderPrizeLayer:getPosition()
    local packingLayerPosx, packingLayerPosy = packingLayer:getPosition()
    
    -- 装载预告 POS 
    local loadingNoticeLayerPosX, loadingNoticeLayerPosY = loadingNoticeLayer:getPosition()
    -- local loadingNoticeRoleLayerPosX, loadingNoticeRoleLayerPosY = loadingNoticeRoleLayer:getPosition()
    
    if state == AIR_SHIP_ACTION_STATE.SHOW_AIR_SHIP then

        bottomBg:setPosition(cc.p(display.cx, -bottomBg:getContentSize().height))
        bottomBg:setVisible(true)

        orderPrizeLayer:setPosition(cc.p(display.SAFE_L + orderPrizeLayerPosx + orderPrizeLayer:getContentSize().width, orderPrizeLayerPosy))
        orderPrizeLayer:setVisible(true)
        cardPreviewView:setOpacity(0)

        action = cc.Sequence:create({
            cc.Spawn:create({
                cc.MoveBy:create(0.1, cc.p(1, 1)),
                cc.CallFunc:create(function() 
                    spineCrabBody:setAnimation(0, 'stop', false)
                    spineCrabBody:addAnimation(0, 'idle', true)
                    spineCrabBody:setVisible(true)
                end),
                cc.CallFunc:create(function()
                    spineCrabLid:setAnimation(0, 'stop', false)
                    spineCrabLid:addAnimation(0, 'idle', true)
                    spineCrabLid:setVisible(true)
                end), 
            }),
            -- cc.DelayTime:create(1),
            cc.TargetedAction:create(bottomBg, cc.EaseCubicActionOut:create(cc.MoveTo:create(1.8, cc.p(bottomBgPosx, bottomBgPosy)))),
            cc.CallFunc:create(function()
                airShipLayer:setVisible(true)
            end),
            cc.DelayTime:create(0.2),
            cc.TargetedAction:create(orderPrizeLayer, cc.MoveTo:create(0.4, cc.p(orderPrizeLayerPosx, orderPrizeLayerPosy))),
            cc.TargetedAction:create(cardPreviewView, cc.FadeIn:create(0.3)),
            cc.CallFunc:create(function()
                -- if cardPreviewViewData then
                --     cardPreviewViewData.view:setVisible(true)
                -- end
                if cb then cb() end
            end),
        })
    elseif state == AIR_SHIP_ACTION_STATE.HIDE_AIR_SHIP then
        
        airShipLayer:setVisible(true)
        bottomBg:setVisible(true)
        orderPrizeLayer:setVisible(true)
        
        loadingNoticeLayer:setVisible(false)
        -- loadingNoticeRoleLayer:setVisible(false)

        action = cc.Sequence:create({
            cc.Spawn:create({
                cc.MoveBy:create(0.1, cc.p(1, 1)),
                cc.CallFunc:create(function() 
                    spineCrabBody:setVisible(true)
                    spineCrabBody:setAnimation(0, 'play', false)
                end),
                cc.CallFunc:create(function()
                    spineCrabLid:setVisible(true)
                    spineCrabLid:setAnimation(0, 'play', false)
                end), 
            }),
            cc.DelayTime:create(0.4),
            cc.CallFunc:create(function()
                airShipLayer:setVisible(false)
                loadingNoticeView:setVisible(true)
            end),
            cc.DelayTime:create(4),
            cc.CallFunc:create(function()
                if cb then cb() end
            end),

        })
        
    elseif state == AIR_SHIP_ACTION_STATE.SHOW_LOADING_NOTICE then
        bottomBg:setPosition(cc.p(display.cx, -bottomBg:getContentSize().height))
        bottomBg:setVisible(true)

        loadingNoticeLayer:setPosition(cc.p(display.width + loadingNoticeLayer:getContentSize().width / 2, loadingNoticeLayerPosY))
        -- loadingNoticeRoleLayer:setPosition(cc.p(display.width * 0.4, loadingNoticeRoleLayerPosY))
        -- loadingNoticeView:setVisible(true)
        cardPreviewView:setOpacity(0)
        action = cc.Sequence:create({
            cc.TargetedAction:create(bottomBg, cc.MoveTo:create(0.5, cc.p(bottomBgPosx, bottomBgPosy))),
            cc.TargetedAction:create(loadingNoticeLayer, cc.MoveTo:create(0.5, cc.p(loadingNoticeLayerPosX, loadingNoticeLayerPosY))),
            cc.TargetedAction:create(cardPreviewView, cc.FadeIn:create(0.3)),
            -- cc.Spawn:create({
            --     -- cc.TargetedAction:create(loadingNoticeRoleLayer, cc.MoveTo:create(0.5, cc.p(loadingNoticeRoleLayerPosX, loadingNoticeRoleLayerPosY))),
            -- }),
            cc.CallFunc:create(function() 
                if cb then cb() end
            end),
        })

    elseif state == AIR_SHIP_ACTION_STATE.HIDE_LOADING_NOTICE then
        bottomBg:setVisible(true)
        loadingNoticeView:setVisible(true)

        
        orderPrizeLayer:setPosition(cc.p(orderPrizeLayerPosx + orderPrizeLayer:getContentSize().width, orderPrizeLayerPosy))
        orderPrizeLayer:setVisible(true)
        
        action = cc.Sequence:create({
            cc.TargetedAction:create(loadingNoticeLayer, cc.MoveTo:create(0.4, cc.p(display.width + loadingNoticeLayer:getContentSize().width / 2, loadingNoticeLayerPosY))),
            -- cc.Spawn:create({
            --     -- cc.TargetedAction:create(loadingNoticeRoleLayer, cc.MoveTo:create(0.4, cc.p(display.width * 0.4, loadingNoticeRoleLayerPosY))),
            -- }),
            cc.Spawn:create({
                cc.CallFunc:create(function()
                    spineCrabBody:setToSetupPose()
                    spineCrabBody:addAnimation(0, 'stop', false)
                    spineCrabBody:addAnimation(0, 'idle', true)
                    spineCrabBody:setVisible(true)
                end),
                cc.CallFunc:create(function()
                    spineCrabLid:setToSetupPose()
                    spineCrabLid:addAnimation(0, 'stop', false)
                    spineCrabLid:addAnimation(0, 'idle', true)
                    spineCrabLid:setVisible(true)
                end),
            }),
            cc.DelayTime:create(2),
            cc.CallFunc:create(function()
                airShipLayer:setVisible(true)
            end),
            cc.DelayTime:create(0.3),
            cc.TargetedAction:create(orderPrizeLayer, cc.MoveTo:create(0.4, cc.p(orderPrizeLayerPosx, orderPrizeLayerPosy))),
            cc.CallFunc:create(function()
                if cardPreviewViewData then
                    cardPreviewViewData.view:setVisible(true)
                end
                loadingNoticeView:setVisible(false)
                loadingNoticeLayer:setPosition(cc.p(loadingNoticeLayerPosX, loadingNoticeLayerPosY))
                -- loadingNoticeRoleLayer:setPosition(cc.p(loadingNoticeRoleLayerPosX, loadingNoticeRoleLayerPosY))
                if cb then cb() end
            end),

        })
    elseif state == AIR_SHIP_ACTION_STATE.SHOW_PACKING then
        packingLayer:setPosition(cc.p(packingLayerPosx + packingLayer:getContentSize().width, packingLayerPosy))
        packingLayer:setVisible(true)
        touchView:setVisible(true)
        action = cc.Sequence:create({
            cc.Spawn:create({
                cc.TargetedAction:create(orderPrizeLayer, cc.MoveTo:create(0.2, cc.p(orderPrizeLayerPosx + orderPrizeLayer:getContentSize().width, orderPrizeLayerPosy))),
                cc.TargetedAction:create(packingLayer, cc.MoveTo:create(0.2, cc.p(packingLayerPosx, packingLayerPosy))),
            }),
            cc.CallFunc:create(function()
                orderPrizeLayer:setPosition(cc.p(orderPrizeLayerPosx, orderPrizeLayerPosy))
                orderPrizeLayer:setVisible(false)
                if cb then cb() end
            end),
        })
    elseif state == AIR_SHIP_ACTION_STATE.HIDE_PACKING then
        touchView:setVisible(false)
        orderPrizeLayer:setPosition(cc.p(orderPrizeLayerPosx + orderPrizeLayer:getContentSize().width, orderPrizeLayerPosy))
        orderPrizeLayer:setVisible(true)
        action = cc.Sequence:create({
            cc.Spawn:create({
                cc.TargetedAction:create(orderPrizeLayer, cc.MoveTo:create(0.2, cc.p(orderPrizeLayerPosx, orderPrizeLayerPosy))),
                cc.TargetedAction:create(packingLayer, cc.MoveTo:create(0.2, cc.p(packingLayerPosx + packingLayer:getContentSize().width, packingLayerPosy))),
            }),
            cc.CallFunc:create(function()
                packingLayer:setPosition(cc.p(packingLayerPosx, packingLayerPosy))
                packingLayer:setVisible(false)
                if cb then cb() end
            end),
        })
    elseif state == AIR_SHIP_ACTION_STATE.SHOW_LOADING_NOTICE_POP_REWARD then
        loadingNoticeLayer:setVisible(true)
        --  loadingNoticeRoleLayer:setVisible(true)
        loadingNoticeLayer:setPosition(cc.p(display.width + loadingNoticeLayer:getContentSize().width / 2, loadingNoticeLayerPosY))
        -- loadingNoticeRoleLayer:setPosition(cc.p(display.width * 0.4, loadingNoticeRoleLayerPosY))
        action = cc.Sequence:create({
            cc.TargetedAction:create(orderPrizeLayer, cc.MoveTo:create(0.4, cc.p(orderPrizeLayerPosx + orderPrizeLayer:getContentSize().width, orderPrizeLayerPosy))),
            cc.TargetedAction:create(loadingNoticeLayer, cc.MoveTo:create(0.5, cc.p(loadingNoticeLayerPosX, loadingNoticeLayerPosY))),
            -- cc.TargetedAction:create(loadingNoticeRoleLayer, cc.MoveTo:create(0.5, cc.p(loadingNoticeRoleLayerPosX, loadingNoticeRoleLayerPosY))),
            cc.CallFunc:create(function()
                orderPrizeLayer:setVisible(false)
                orderPrizeLayer:setPosition(cc.p(orderPrizeLayerPosx, orderPrizeLayerPosy))
                if cb then cb() end
            end),
        })
    end

    self:runAction(action)
end

function AirShipHomeView:CreatePickReward(parent, pickRewards)
    return CreatePickReward(parent, pickRewards)
end

function AirShipHomeView:getArgs()
	return self.args
end

function AirShipHomeView:CloseHandler()
	local args = self:getArgs()
	local mediatorName = args.mediatorName
	local mediator = AppFacade.GetInstance():RetrieveMediator(mediatorName)
	if mediator and mediator.isControllable_ then
		AppFacade.GetInstance():UnRegsitMediator(mediatorName)
	end
	
end

return AirShipHomeView