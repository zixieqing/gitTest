--[[
高级米饭心意活动view
--]]
local VIEW_SIZE = cc.size(1035, 637)
local ActivityPayLoginRewardView = class('ActivityPayLoginRewardView', function ()
    local node = CLayout:create(VIEW_SIZE)
    node.name = 'home.view.activity.payLoginReward.ActivityPayLoginRewardView'
    node:enableNodeEvents()
    return node
end)

local CreateView     = nil
local CreateGoodNode = nil

local RES_DICT = {
    COMMON_ARROW                  = _res('ui/common/common_arrow.png'),
    COMMON_BTN_ORANGE            = _res('ui/common/common_btn_orange.png'),
    COMMON_BTN_GREEN             = _res('ui/common/common_btn_green.png'),
    COMMON_BTN_TIPS              = _res('ui/common/common_btn_tips.png'),
    COMMON_BTN_DRAWN             = _res('ui/common/activity_mifan_by_ico.png'),
    COMMON_BTN_WHITE_DEFAULT     = _res('ui/common/common_btn_white_default.png'),
    NOVICE_SIGNIN_ALL_REWARD_BTN = _res('ui/home/activity/payLoginReward/novice_signin_all_reward_btn.png'),
    NOVICE_SIGNIN_BTN_LOCK       = _res('ui/home/activity/payLoginReward/novice_signin_btn_lock.png'),
    NOVICE_SIGNIN_BTN_RECHARGE   = _res('ui/home/activity/payLoginReward/novice_signin_btn_recharge.png'),
    NOVICE_SIGNIN_BG             = _res('ui/home/activity/payLoginReward/novice_signin_bg.png'),
    NOVICE_SIGNIN_FRAME_REWARD   = _res('ui/home/activity/payLoginReward/novice_signin_frame_reward.png'),
    NOVICE_SIGNIN_FRAME          = _res('ui/home/activity/payLoginReward/novice_signin_frame.png'),
    ACTIVITY_NSI_TITLE           = _res('ui/home/activity/payLoginReward/activity_nsi_title.png'),

    SPINE_CJJL_LINGHUOZHONG      = _spn('ui/home/activity/passTicket/spine/cjjl_linghuozhong'),
    
}

local SIGNIN_STATE = {
	SIGNIN_TIMES_INSUFFICIENT         = 0,      --签到次数不足
	ALREADY_PAID_CAN_SIGNIN           = 1,      --已付费可签到
	NO_PAYMENT_CAN_SIGNIN             = 2,      --未付费可签到
	ALREADY_PAID_SUPPLEMENTARY_SIGNIN = 3,      --已付费 补签
	ALREADY_SIGNIN                    = 4,      --已签到
}

function ActivityPayLoginRewardView:ctor( ... )
    self.args = unpack({...})

    self:InitUI()
end
--[[
init ui
--]]
function ActivityPayLoginRewardView:InitUI()
    xTry(function ( )
        self.viewData_ = CreateView(VIEW_SIZE)
        self:addChild(self.viewData_.view)
	end, __G__TRACKBACK__)
    
end

function ActivityPayLoginRewardView:UpdateLeftTimeLabel(leftTime)
    local viewData      = self:GetViewData()
    local leftTimeLabel = viewData.leftTimeLabel
    local countdownLabel = viewData.countdownLabel
    local isVisible     = checkint(leftTime) > 0
    leftTimeLabel:setVisible(isVisible)
    countdownLabel:setVisible(isVisible)

    if isVisible then
        display.commonLabelParams(countdownLabel, {text = CommonUtils.getTimeFormatByType(leftTime)})
    end
end

function ActivityPayLoginRewardView:UpdateUIShowState(isTimeEnd)
    local viewData                = self:GetViewData()
    local overdueTipLabel         = viewData.overdueTipLabel
    overdueTipLabel:setVisible(isTimeEnd)
    local tableView               = viewData.tableView
    tableView:setVisible(not isTimeEnd)
    
end

function ActivityPayLoginRewardView:UpdateTableView(viewData, datas)
    local tableView = viewData.tableView
    tableView:setCountOfCell(#datas)
    tableView:reloadData()
end

function ActivityPayLoginRewardView:UpdateCardImg(viewData, pictureId)
    viewData.cardImg:setTexture(string.format('ui/home/activity/payLoginReward/%s', pictureId))
end

function ActivityPayLoginRewardView:UpdateRechargeBtn(viewData, data)
    local rechargeBtn      = viewData.rechargeBtn
    local rechargeBtnLabel = rechargeBtn:getLabel()
    local receivedLabel    = viewData.receivedLabel
    local btnSpine         = viewData.btnSpine

    local isPurchased = checkint(data.hasPurchased) > 0
    rechargeBtn:setVisible(true)
    receivedLabel:setVisible(isPurchased)
    rechargeBtnLabel:setVisible(not isPurchased)
    btnSpine:setVisible(not isPurchased)
    local img
    if isPurchased then
        img = RES_DICT.COMMON_BTN_DRAWN
    else
        img = RES_DICT.NOVICE_SIGNIN_BTN_RECHARGE
        display.commonLabelParams(rechargeBtn, {text = string.fmt(__('购买特权\n￥_num1_'),{_num1_ = tostring(data.price)} )})
    end
    rechargeBtn:setNormalImage(img)
    rechargeBtn:setSelectedImage(img)
end

function ActivityPayLoginRewardView:UpdateDayLabel(viewData, day)
    display.commonLabelParams(viewData.dayLabel, {text = string.format(__('第%s天'), CommonUtils.GetChineseNumber(day))})
end

function ActivityPayLoginRewardView:UpdateSigninState(viewData, data, state, index)
    -- state 0.未到达所在天数 1 已付费可签到, 2. 未付费可签到, 3 已付费 补签 , 4 已签到 
    local drawBtn       = viewData.drawBtn
    local drawBtnLabel  = drawBtn:getLabel()
    local drawLabel     = viewData.drawLabel
    local currencyLabel = viewData.currencyLabel
    local buyTipLabel   = viewData.buyTipLabel
    -- local shadowCover   = viewData.shadowCover
    currencyLabel:setVisible(false)
    buyTipLabel:setVisible(false)
    drawLabel:setVisible(false)
    drawBtnLabel:setVisible(true)

    local img = nil
    local str = nil
    local enabled = true
    local isVisibleDrawBtn = true
    local scale = 1
    if state == SIGNIN_STATE.ALREADY_PAID_CAN_SIGNIN then
        img = RES_DICT.COMMON_BTN_ORANGE
        str = __('签到')
    elseif state == SIGNIN_STATE.NO_PAYMENT_CAN_SIGNIN then
        buyTipLabel:setVisible(true)
        isVisibleDrawBtn = false
        
    elseif state == SIGNIN_STATE.ALREADY_PAID_SUPPLEMENTARY_SIGNIN then
        img = RES_DICT.COMMON_BTN_GREEN
        currencyLabel:setVisible(true)
        self:UpdateCurrencyLabel(currencyLabel, data)
        str = __('补签')
    elseif state == SIGNIN_STATE.ALREADY_SIGNIN then
        img = RES_DICT.COMMON_BTN_DRAWN
        enabled = false
        drawBtnLabel:setVisible(false)
        drawLabel:setVisible(true)
        scale = 0.9
    else
        img = RES_DICT.NOVICE_SIGNIN_BTN_LOCK
        str = __('签到')
        enabled = false
    end

    if str then
        display.commonLabelParams(drawBtn, {text = str})
    end

    drawBtn:setVisible(isVisibleDrawBtn)
    drawBtn:setNormalImage(img)
    drawBtn:setSelectedImage(img)
    -- logInfo.add(5, scale)
    drawBtn:setScale(scale)
    drawBtn:setEnabled(enabled)

    drawBtn:setTag(index)
    drawBtn:setUserTag(state)
end

function ActivityPayLoginRewardView:UpdateRewardLayer(viewData, data)
    local rewardLayer = viewData.rewardLayer
    local rewards     = data.rewards or {}
    
    local rewardNodes = viewData.rewardNodes
    
    local nodeCount = table.nums(rewardNodes)
    local rewardCount = #rewards
    local rewardLayerSize = rewardLayer:getContentSize()

    local times = math.max(nodeCount, rewardCount)
    for i = 1, times do
        local reward = rewards[i]
        local rewardNode = rewardNodes[i]
        if reward then
            if rewardNode then
                rewardNode:setVisible(true)
            else
                rewardNode = CreateGoodNode(reward)
                rewardNode:setScale(0.75)
                rewardLayer:addChild(rewardNode)
                table.insert(rewardNodes, rewardNode)
            end
            reward.highlight = checkint(reward.highlight)
            rewardNode:RefreshSelf(reward)
            display.commonUIParams(rewardNode, {po = cc.p(50 + (i-1) * 90, rewardLayerSize.height/2)})
        else
            if rewardNode then
                rewardNode:setVisible(false)
            end
        end
    end
end

function ActivityPayLoginRewardView:UpdateCumulativeRewardDrawBtn(viewData, state, index)
    local cumulativeRewardDrawBtn = viewData.cumulativeRewardDrawBtn
    cumulativeRewardDrawBtn:RefreshUI({drawState = state})
    cumulativeRewardDrawBtn:setTag(index)
    cumulativeRewardDrawBtn:SetButtonEnable(state == 2)
end

function ActivityPayLoginRewardView:UpdateCumulativeTimesLabel(viewData, times, needTimes) 
    display.commonLabelParams(viewData.cumulativeTimesLabel, {text = string.format(__('累计签到%s/%s天'), times, needTimes)})
end

function ActivityPayLoginRewardView:UpdateCurrencyLabel(currencyLabel, data)
    local dailyConsume = data.dailyConsume or {}
    
    local richTable
    for index, value in ipairs(dailyConsume) do
        local num     = value.num
        local goodsId = value.goodsId
        if richTable == nil then
            richTable = {
                fontWithColor('14',{ text = num}),
                {img = CommonUtils.GetGoodsIconPathById(goodsId), scale = 0.15}
            }
        else
            table.insert(richTable, fontWithColor('14', {text = ',' .. num}))
            table.insert(richTable, {img = CommonUtils.GetGoodsIconPathById(goodsId), scale = 0.15})
        end
    end
    if richTable and next(richTable) ~= nil then
        display.reloadRichLabel(currencyLabel, {c = richTable})
        CommonUtils.AddRichLabelTraceEffect(currencyLabel)
    end
end

function ActivityPayLoginRewardView:UpdateCumulativeRewards(viewData, data, isFinalRewards)
    local rewardLayer = viewData.cumulativeRewardLayer
    local rewards     = data.rewards or {}
    local rewardNodes = viewData.rewardNodes
    local hasDraw     = checkint(data.hasDrawn) > 0
    
    local nodeCount = table.nums(rewardNodes)
    local rewardCount = #rewards
    local rewardLayerSize = rewardLayer:getContentSize()
    local midPointX = rewardLayerSize.width * 0.5
    local midPointY = rewardLayerSize.height * 0.5
    local goodNodeSize
    local scale = 0.9
    local times = math.max(nodeCount, rewardCount)
    for i = 1, times do
        local reward = rewards[i]
        local rewardNode = rewardNodes[i]
        if reward then
            if rewardNode then
                rewardNode:setVisible(true)
            else
                rewardNode = CreateGoodNode(reward)
                rewardLayer:addChild(rewardNode)
                table.insert(rewardNodes, rewardNode)
            end
            rewardNode:setScale(scale)
            -- 累计奖励 写死高亮 by zxb
            reward.highlight = 1
            rewardNode:RefreshSelf(reward)

            if goodNodeSize == nil then
                goodNodeSize = rewardNode:getContentSize()
            end
            local params = {index = i, goodNodeSize = goodNodeSize, midPointX = midPointX, midPointY = midPointY, col = rewardCount, maxCol = 2, scale = scale, goodGap = 5}
            display.commonUIParams(rewardNode, {po = CommonUtils.getGoodPos(params)})

            if isFinalRewards and hasDraw then
                -- add right img
                if rewardNode.rightArrow == nil then
                    rewardNode.rightArrow = display.newNSprite(RES_DICT.COMMON_ARROW, goodNodeSize.width * 0.5 * scale, goodNodeSize.height * 0.5 * scale, {ap = display.CENTER})
                    rewardNode:addChild(rewardNode.rightArrow, 100)
                end
                rewardNode:setState(-1)
                rewardNode.rightArrow:setVisible(true)
                
            elseif rewardNode.rightArrow then
                rewardNode:setState(1)
                rewardNode.rightArrow:setVisible(false)
            end
        else
            if rewardNode then
                rewardNode:setVisible(false)
            end
        end

    end
end

CreateView = function (size)
    local view = display.newLayer(size.width / 2, size.height / 2, {size = size, ap = display.CENTER})
    
    local widthMiddle = size.width * 0.5
    local heightMiddle = size.height * 0.5

    local bg = display.newNSprite(RES_DICT.ACTIVITY_NSI_TITLE, widthMiddle, heightMiddle, {ap = display.CENTER})
    view:addChild(bg, 1)

    local titleLabel = display.newLabel(35, size.height - 30, fontWithColor(18, {text = __('当错过登陆时间，可补签'), ap = display.LEFT_CENTER}))
    view:addChild(titleLabel, 1)

    local ruleBtn = display.newButton(titleLabel:getPositionX() + display.getLabelContentSize(titleLabel).width, titleLabel:getPositionY(), {n = RES_DICT.COMMON_BTN_TIPS, ap = display.LEFT_CENTER})
    view:addChild(ruleBtn, 1)

    local leftTimeLabel = display.newLabel(size.width - 140, titleLabel:getPositionY(), 
        fontWithColor(18, {ap = display.RIGHT_CENTER, text = __('剩余时间: ')}))
    view:addChild(leftTimeLabel, 1)

    local countdownLabel = display.newLabel(size.width - 140, titleLabel:getPositionY(), 
        fontWithColor(18, {ap = display.LEFT_CENTER, color = '#ffdb49'}))
    view:addChild(countdownLabel, 1)

    local cardImg = display.newNSprite(RES_DICT.NOVICE_SIGNIN_BG, widthMiddle, heightMiddle, {ap = display.CENTER})
    view:addChild(cardImg)

    local rechargeBtn = display.newButton(210, 140, {n = RES_DICT.NOVICE_SIGNIN_BTN_RECHARGE, ap = display.CENTER})
    display.commonLabelParams(rechargeBtn, fontWithColor(14, {hAlign = display.TAC, fontSize = 22, outline = '#5b3c25', outlineSize = 1}))
    view:addChild(rechargeBtn)
    rechargeBtn:setVisible(false)

    local receivedLabel = display.newLabel(0, 0, fontWithColor(7, {fontSize = 22, text = __('特权授权')}))
    display.commonUIParams(receivedLabel, {po = cc.p(68, 34), ap = display.CENTER})
    rechargeBtn:addChild(receivedLabel)
    receivedLabel:setVisible(false)

    local btnSpine = sp.SkeletonAnimation:create(RES_DICT.SPINE_CJJL_LINGHUOZHONG.json, RES_DICT.SPINE_CJJL_LINGHUOZHONG.atlas, 1.4)
    btnSpine:update(0)
    btnSpine:addAnimation(0, 'idle', true)
    btnSpine:setPosition(utils.getLocalCenter(rechargeBtn))
    rechargeBtn:addChild(btnSpine, 5)
    
    local overdueTipLabel = display.newLabel(size.width - 316, size.height * 0.5, fontWithColor(14, {text = __('活动已过期'), ap = display.CENTER}))
    view:addChild(overdueTipLabel)
    overdueTipLabel:setVisible(false)
    
    -- 144
    local tableViewSize = cc.size(624, 417)
    local tableViewCellSize = cc.size(tableViewSize.width, 125)
    local tableView = CTableView:create(tableViewSize)
    tableView:setDirection(eScrollViewDirectionVertical)
    tableView:setSizeOfCell(tableViewCellSize)
    display.commonUIParams(tableView, {ap = display.CENTER_TOP, po = cc.p(size.width - 316, size.height - 60)})
    -- tableView:setBackgroundColor(cc.c3b(100, 100, 100))
    view:addChild(tableView)

    -------------------------------------------
    -- cumulative reward
    local cumulativeLoginRewardBgLayerSize = cc.size(618, 144)

    -- 为了做动画 套个 listview
    local listView = CListView:create(cumulativeLoginRewardBgLayerSize)
    listView:setBounceable(false)
    listView:setDirection(eScrollViewDirectionVertical)
    listView:setPosition(cc.p(
        widthMiddle - 119, 18
    ))
    listView:setAnchorPoint(display.LEFT_BOTTOM)
    view:addChild(listView)

    -- local cumulativeLoginRewardBgLayer = display.newLayer(widthMiddle - 119, 18, {size = cumulativeLoginRewardBgLayerSize, ap = display.LEFT_BOTTOM})
    local cumulativeLoginRewardBgLayer = display.newLayer(0, 0, {size = cumulativeLoginRewardBgLayerSize, ap = display.LEFT_BOTTOM})
    -- view:addChild(cumulativeLoginRewardBgLayer)
    listView:insertNodeAtLast(cumulativeLoginRewardBgLayer)
    listView:reloadData()
    -- cumulativeLoginRewardBgLayer:setVisible(false)

    local cumulativeLoginRewardBg =  display.newNSprite(RES_DICT.NOVICE_SIGNIN_FRAME_REWARD, cumulativeLoginRewardBgLayerSize.width * 0.5, 0, {ap = display.CENTER_BOTTOM})
    cumulativeLoginRewardBgLayer:addChild(cumulativeLoginRewardBg)

    local cumulativeRewardTip = display.newLabel(102, 80, 
        fontWithColor(7, {ap = display.CENTER_BOTTOM, color = '#a95c23', w = 140, fontSize = 22, text = __('累计签到奖励')}))
    cumulativeLoginRewardBgLayer:addChild(cumulativeRewardTip)

    local lookRewardBtn = display.newButton(102, 72, {n = RES_DICT.NOVICE_SIGNIN_ALL_REWARD_BTN, ap = display.CENTER_TOP})
    display.commonLabelParams(lookRewardBtn, fontWithColor(16, {color = '#994b12', text = __('全部奖励')}))
    cumulativeLoginRewardBgLayer:addChild(lookRewardBtn)

    local cumulativeRewardLayer = display.newLayer(cumulativeLoginRewardBgLayerSize.width * 0.5, cumulativeLoginRewardBgLayerSize.height * 0.5 - 4, {
        size = cc.size(210, 110), ap = display.CENTER})
    cumulativeLoginRewardBgLayer:addChild(cumulativeRewardLayer)

    local cumulativeRewardDrawBtn = require('common.CommonDrawButton').new({
        drawStateImgs = {
            [1] = RES_DICT.NOVICE_SIGNIN_BTN_LOCK,
            [2] = RES_DICT.COMMON_BTN_ORANGE,
            [3] = RES_DICT.COMMON_BTN_DRAWN,
        },
        btnParams = {
        ap = display.CENTER,
        scale9 = true, size = cc.size(123, 62),
        enable = true,
    }})
    display.commonUIParams(cumulativeRewardDrawBtn, {po = cc.p(cumulativeLoginRewardBgLayerSize.width - 93, 81), ap = display.CENTER})
    cumulativeLoginRewardBgLayer:addChild(cumulativeRewardDrawBtn)

    local cumulativeTimesLabel = display.newLabel(cumulativeLoginRewardBgLayerSize.width - 93, 28, {hAlign = display.TAC, fontSize = 20, color = '#5b3c25', ap = display.CENTER, w = 170})
    cumulativeLoginRewardBgLayer:addChild(cumulativeTimesLabel)

    -- cumulative reward
    -------------------------------------------

    local particle = cc.ParticleSystemQuad:create('ui/home/activity/payLoginReward/lizidiandian.plist')
    particle:setAutoRemoveOnFinish(true)
    particle:setPosition(cc.p(size.width * 0.5, size.height * 0.5))
    view:addChild(particle)

    return {
        view                         = view,
        ruleBtn                      = ruleBtn,
        leftTimeLabel                = leftTimeLabel,
        countdownLabel               = countdownLabel,
        overdueTipLabel              = overdueTipLabel,
        tableView                    = tableView,
        rechargeBtn                  = rechargeBtn,
        receivedLabel                = receivedLabel,
        btnSpine                     = btnSpine,
        lookRewardBtn                = lookRewardBtn,
        cumulativeLoginRewardBgLayer = cumulativeLoginRewardBgLayer,
        cumulativeRewardLayer        = cumulativeRewardLayer,
        cumulativeRewardDrawBtn      = cumulativeRewardDrawBtn,
        cumulativeTimesLabel         = cumulativeTimesLabel,

        rewardNodes = {}
    }

end

CreateGoodNode = function (reward)
    local node = require('common.GoodNode').new({
        id = checkint(reward.goodsId),
        amount = checkint(reward.num),
        showAmount = true,
        highlight = 1,
        callBack = function (sender)
            app.uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = sender.goodId, type = 1})
        end
    })
    return node
end

function ActivityPayLoginRewardView:CreateCell(size)
    local cell = CTableViewCell:new()
    cell:setContentSize(size)

    local bg = display.newNSprite(RES_DICT.NOVICE_SIGNIN_FRAME, size.width * 0.5, size.height * 0.5, {ap = display.CENTER})
    cell:addChild(bg)

    local dayLabel = display.newLabel(90, size.height / 2, fontWithColor(16, {w = 100, hAlign = display.TAC, ap = display.CENTER}))
    cell:addChild(dayLabel)

    local rewardLayerSize = cc.size(280, 96)
    local rewardLayer = display.newLayer(158, size.height * 0.5, {size = rewardLayerSize, ap = display.LEFT_CENTER})
    cell:addChild(rewardLayer)

    local buyTipLabel = display.newLabel(size.width - 100, size.height * 0.5, fontWithColor(6, {
        w = 125, ap = display.CENTER, hAlign = display.TAC, text = __('购买特权\n获得签到许可'), fontSize = 20, color = '#bf9a79'}))
    cell:addChild(buyTipLabel)
    buyTipLabel:setVisible(false)
    
    local drawBtn = display.newButton(size.width - 35, size.height * 0.5, {ap = display.RIGHT_CENTER, n = RES_DICT.NOVICE_SIGNIN_BTN_LOCK})
    display.commonLabelParams(drawBtn, fontWithColor(14))
    cell:addChild(drawBtn) 
    drawBtn:setVisible(false)

    local drawLabel = display.newLabel(0, 0, fontWithColor(2, {fontSize = 22, color = '#ffffff',  text = __('已签到')}))
    display.commonUIParams(drawLabel, {po = cc.p(68, 34), ap = display.CENTER})
    drawBtn:addChild(drawLabel)
    drawLabel:setVisible(false)
    
    local currencyLabel = display.newRichLabel(size.width - 85, 20, {ap = display.CENTER})
    currencyLabel:setVisible(false)
    cell:addChild(currencyLabel)

    cell.viewData = {
        bg            = bg,
        dayLabel      = dayLabel,
        rewardLayer   = rewardLayer,
        buyTipLabel   = buyTipLabel,
        drawBtn       = drawBtn,
        drawLabel     = drawLabel,
        currencyLabel = currencyLabel,
        rewardNodes   = {},
    }
    return cell
end

function ActivityPayLoginRewardView:ShowCumulativeRewardAction(viewData, curData, isFinalRewards)
    app.uiMgr:GetCurrentScene():AddViewForNoTouch()
    local tableView = viewData.tableView
    local tableViewSize = tableView:getContentSize()
    local layer = viewData.cumulativeLoginRewardBgLayer
    local layerSize = layer:getContentSize()
    local orginLayerPosX = layer:getPositionX()
    local orginLayerPosY = layer:getPositionY()
    local orginContentOffset  = tableView:getContentOffset()

    tableView:setContentSize(cc.size(tableViewSize.width, tableViewSize.height + layerSize.height))
    tableView:setContentOffset(cc.p(0, orginContentOffset.y + layerSize.height))
    
    layer:runAction(cc.Sequence:create({
        cc.MoveBy:create(0.2, cc.p(0, -300)),
        cc.CallFunc:create(function()
            self:UpdateCumulativeRewards(viewData, curData, isFinalRewards)
        end),
        cc.MoveBy:create(0.2, cc.p(0, 300)),
        cc.CallFunc:create(function()
            tableView:setContentSize(tableViewSize)
            tableView:setContentOffset(orginContentOffset)
            
            app.uiMgr:GetCurrentScene():RemoveViewForNoTouch()
        end),
    }))
end

function ActivityPayLoginRewardView:GetViewData()
    return self.viewData_
end

return ActivityPayLoginRewardView