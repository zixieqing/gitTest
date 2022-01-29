--[[
成长基金活动view
--]]
local VIEW_SIZE = cc.size(1035, 637)
local ActivityGrowthFundView = class('ActivityGrowthFundView', function ()
    local node = CLayout:create(VIEW_SIZE)
    node.name = 'home.view.activity.growthFund.ActivityGrowthFundView'
    node:enableNodeEvents()
    return node
end)

local CreateView  = nil
local CreateCell_ = nil
local CreateGoodNode = nil

local RES_DICT = {
    COMMON_BG_GOODS                 = _res('ui/home/activity/growthFund/common_bg_goods.png'),
    COMMON_BTN_TIPS                 = _res('ui/common/common_btn_tips.png'),
    COMMON_BTN_GREEN                = _res('ui/common/common_btn_green.png'),
    COMMON_BTN_DRAWN                = _res('ui/common/activity_mifan_by_ico.png'),
    ACTIVITY_FUND_AD_BG_WORDS       = _res("ui/home/activity/growthFund/activity_fund_ad_bg_words.png"),
    ACTIVITY_FUND_BG_FARME_UNLOCK   = _res("ui/home/activity/growthFund/activity_fund_bg_farme_unlock.png"),
    ACTIVITY_FUND_BG_FARME          = _res("ui/home/activity/growthFund/activity_fund_bg_farme.png"),
    ACTIVITY_FUND_BG_GOODS          = _res("ui/home/activity/growthFund/activity_fund_bg_goods.png"),
    ACTIVITY_FUND_BG                = _res("ui/home/activity/growthFund/activity_fund_bg.png"),
    ACTIVITY_FUND_ROLE              = _res("ui/home/activity/growthFund/activity_fund_role.png"),
    ACTIVITY_FUND_TITLE_WORDS       = _res('ui/home/activity/growthFund/activity_fund_title_words.png'),
    ACTIVITY_FUND_SLOGAN_1          = _res('ui/home/activity/growthFund/activity_fund_slogan_1.png'),
    ACTIVITY_FUND_SLOGAN_2          = _res('ui/home/activity/growthFund/activity_fund_slogan_2.png'),
    SPINE_CJJL_LINGHUOZHONG         = _spn('ui/home/activity/passTicket/spine/cjjl_linghuozhong'),
}

local BOX_STATE = {
	LOCK      = 0,
	NORMAL    = 1,
	PURCHASED = 2,
}

function ActivityGrowthFundView:ctor( ... )
    self.args = unpack({...})
    self:InitUI()
end
--[[
init ui
--]]
function ActivityGrowthFundView:InitUI()
    xTry(function ( )
        self.viewData_ = CreateView(VIEW_SIZE)
        self:addChild(self.viewData_.view)
	end, __G__TRACKBACK__)
end

function ActivityGrowthFundView:refreshUI(datas)
    local viewData = self:getViewData()
    self:updateTableView(viewData, datas.payLevelRewards or {})
    self:updateRechangeBtn(viewData, datas, datas.isPayLevelRewardsOpen)
end

function ActivityGrowthFundView:updateRechangeBtn(viewData, datas, isPayLevelRewardsOpen)
    local isHasPayLevelRewardsOpen = checkint(isPayLevelRewardsOpen) > 0 

    local rechangeBtn = viewData.rechangeBtn
    local rechangeBtnLabel = rechangeBtn:getLabel()
    local img = nil
    rechangeBtnLabel:setVisible(not isHasPayLevelRewardsOpen)
    viewData.btnSpine:setVisible(not isHasPayLevelRewardsOpen)
    viewData.receivedLabel:setVisible(isHasPayLevelRewardsOpen)

    if isHasPayLevelRewardsOpen then
        img = RES_DICT.COMMON_BTN_DRAWN
    else
        img = RES_DICT.COMMON_BTN_GREEN
        if isElexSdk() then
            local price = CommonUtils.GetCurrentAndOriginPriceDByPriceData(datas)
            display.commonLabelParams(rechangeBtn, {text = price} )
        else
            local price = datas.price
            display.commonLabelParams(rechangeBtn, {text = string.fmt( __('￥_num1_'),{_num1_ = tostring(price)} )})
        end

    end
    rechangeBtn:setNormalImage(img)
    rechangeBtn:setSelectedImage(img)
    rechangeBtn:setEnabled(not isHasPayLevelRewardsOpen)
end

function ActivityGrowthFundView:updateTableView(viewData, payLevelRewards)
    local tableView = viewData.tableView
    tableView:setCountOfCell(#payLevelRewards)
    tableView:reloadData()
end

function ActivityGrowthFundView:updateCell(viewData, data, isPayLevelRewardsOpen)
    
    display.commonLabelParams(viewData.targetLabel, {text = string.fmt(__('_num_级'), {['_num_'] = tostring(data.target)})})

    display.commonLabelParams(viewData.worthLabel, {text = tostring(data.valueDescr)})

    self:updateGoodsLayer(viewData, data)

    self:updateDrawState(viewData, data, isPayLevelRewardsOpen)

end

function ActivityGrowthFundView:updateGoodsLayer(viewData, data)
    local rewards = data.rewards or {}
    
    local hasDrawn = checkint(data.hasDrawn)

    local goodsLayer  = viewData.goodsLayer
    local goodNodes = viewData.goodNodes
    local goodsBgs  = viewData.goodsBgs
    local rewardCount    = #rewards
    local goodsNodeCount = #goodNodes

    local count = math.max(goodsNodeCount,  rewardCount)
    for i = 1, count do
        local reward = rewards[i]
        local goodNode = goodNodes[i]
        if reward then
            if goodNode == nil then
                goodNode = CreateGoodNode(reward)
                local goodsBg = goodsBgs[i]
                display.commonUIParams(goodNode, {ap = display.LEFT_CENTER, po = cc.p(goodsBg:getPositionX(), goodsBg:getPositionY())})
                goodNode:setScale(0.75)
                goodsLayer:addChild(goodNode)
                table.insert(goodNodes, goodNode)
                goodNode:setVisible(false)
            end
            
            goodNode:RefreshSelf(reward)
            goodNode:setVisible(true)
        elseif goodNode then
            goodNode:setVisible(false)
        end
    end
end

function ActivityGrowthFundView:updateDrawState(viewData, data, isPayLevelRewardsOpen)
    local drawState = 1
    if checkint(isPayLevelRewardsOpen) > 0 then
        if checkint(data.hasDrawn) > 0 then
            drawState = 3
        elseif checkint(data.progress) >= checkint(data.target) then
            drawState = 2
        end
    end

    local isNotDraw = drawState < 3
    local drawBtn = viewData.drawBtn
    drawBtn:RefreshUI({drawState = drawState})
    drawBtn:SetButtonEnable(isNotDraw)
    drawBtn:setUserTag(drawState)

    viewData.unlockImg:setVisible(not isNotDraw)
end

CreateView = function (size)
    local view = display.newLayer(size.width / 2, size.height / 2, {size = size, ap = display.CENTER})

    local adBg = display.newImageView(RES_DICT.ACTIVITY_FUND_BG, size.width / 2, size.height / 2)
    view:addChild(adBg)

    local adRole = display.newImageView(RES_DICT.ACTIVITY_FUND_ROLE, size.width / 2, size.height / 2)
    view:addChild(adRole)

    local adWordsBg = display.newNSprite(RES_DICT.ACTIVITY_FUND_AD_BG_WORDS, 10, 10, {ap = display.LEFT_BOTTOM})
    view:addChild(adWordsBg)

    local titleWords = display.newImageView(RES_DICT.ACTIVITY_FUND_TITLE_WORDS, 200, size.height / 2 - 12)
    view:addChild(titleWords)

    local slogan1 = display.newImageView(RES_DICT.ACTIVITY_FUND_SLOGAN_1, size.width - 300, size.height - 70)
    view:addChild(slogan1, 1)

    local slogan2 = display.newImageView(RES_DICT.ACTIVITY_FUND_SLOGAN_2, 100, size.height / 2 - 60)
    view:addChild(slogan2, 1)

    local descrViewSize  = cc.size(340, 160)
	local descrContainer = cc.ScrollView:create()
    descrContainer:setPosition(cc.p(24 + 10, 12))
	descrContainer:setDirection(eScrollViewDirectionVertical)
	descrContainer:setAnchorPoint(display.LEFT_BOTTOM)
    descrContainer:setViewSize(descrViewSize)
    view:addChild(descrContainer)

    local adWordsTipLabel = display.newLabel(20, 160, fontWithColor(18, {w = 340, text = __('初始投入68元基金后，便可在游戏等级达到要求时，领取总计价值超过4000元的海量奖励！终生仅有1次机会，绝对超值！')}))
    descrContainer:setContainer(adWordsTipLabel)
    local descrScrollTop = descrViewSize.height - display.getLabelContentSize(adWordsTipLabel).height
    descrContainer:setContentOffset(cc.p(0, descrScrollTop))
    
    local tipsBtn = display.newButton(45, size.height - 37,
    {
        n = RES_DICT.COMMON_BTN_TIPS, 
        ap = display.CENTER,
    })
    view:addChild(tipsBtn)

    local rechangeBtn = display.newButton(200, size.height / 2 - 86, {ap = display.CENTER, scale9 = true, n = RES_DICT.COMMON_BTN_GREEN})
    display.commonLabelParams(rechangeBtn, fontWithColor(14))
    view:addChild(rechangeBtn)

    local receivedLabel = display.newLabel(0, 0, fontWithColor(7, {fontSize = 24, text = __('已购买')}))
    display.commonUIParams(receivedLabel, {po = utils.getLocalCenter(rechangeBtn), ap = display.CENTER})
    rechangeBtn:addChild(receivedLabel)
    receivedLabel:setVisible(false)

    local btnSpine = sp.SkeletonAnimation:create(RES_DICT.SPINE_CJJL_LINGHUOZHONG.json, RES_DICT.SPINE_CJJL_LINGHUOZHONG.atlas, 1.05)
    btnSpine:update(0)
    btnSpine:addAnimation(0, 'idle', true)
    btnSpine:setPosition(utils.getLocalCenter(rechangeBtn))
    rechangeBtn:addChild(btnSpine, 5)

    -- 列表Layout
    local tableViewLayoutSize = cc.size(626, 616)
    local tableViewLayout = CLayout:create(tableViewLayoutSize)
    display.commonUIParams(tableViewLayout, {po = cc.p(size.width / 2 - 120, size.height / 2), ap = display.LEFT_CENTER})
    view:addChild(tableViewLayout)

    -- 列表背景
    local tableViewBg = display.newImageView(RES_DICT.COMMON_BG_GOODS, tableViewLayoutSize.width / 2, tableViewLayoutSize.height / 2 - 57
    , { size = cc.size(tableViewLayoutSize.width, tableViewLayoutSize.height - 100), scale9 = true})
    tableViewLayout:addChild(tableViewBg)

    local tableViewSize = cc.size(tableViewLayoutSize.width - 6, tableViewLayoutSize.height - 110)
    local tableViewCellSize = cc.size(tableViewLayoutSize.width, 180)
    local tableView = CTableView:create(tableViewSize)
    tableView:setDirection(eScrollViewDirectionVertical)
    tableView:setSizeOfCell(tableViewCellSize)
    display.commonUIParams(tableView, {ap = display.CENTER, po = cc.p(tableViewLayoutSize.width / 2, tableViewLayoutSize.height / 2 - 57)})
	-- tableView:setBackgroundColor(cc.c4b(178, 63, 88, 100))
    tableViewLayout:addChild(tableView)
    -- tableView:setVisible(false)

    return {
        view          = view,
        tipsBtn       = tipsBtn,
        rechangeBtn   = rechangeBtn,
        receivedLabel = receivedLabel,
        tableView     = tableView,
        btnSpine      = btnSpine
    }

end

CreateCell_ = function (size)
    local cell = CTableViewCell:new()
    cell:setContentSize(size)

    local img = display.newNSprite(RES_DICT.ACTIVITY_FUND_BG_FARME, size.width / 2, size.height / 2, {ap = display.CENTER})
    cell:addChild(img)

    local descTipsLabel = display.newLabel(45, size.height - 40, {fontSize = 22, color = '#93572b', text = __('主角等级到达') ,w = 200,hAlign= display.TAC, ap = display.LEFT_CENTER})
    cell:addChild(descTipsLabel)

    local targetLabel = display.newLabel(110, size.height / 2 - 20, fontWithColor(7, {fontSize = 26, color = '#d23d3d', ap = display.CENTER}))
    cell:addChild(targetLabel)

    local rewardsTipsLabel = display.newLabel(size.width / 2 + 16, size.height - 40, {fontSize = 22, color = '#93572b', text = __('奖励'), ap = display.CENTER})
    cell:addChild(rewardsTipsLabel)

    local goodsLayerSize = cc.size(270, 90)
    local goodsLayer = display.newLayer(size.width / 2 + 20, targetLabel:getPositionY(), {ap = display.CENTER, size = goodsLayerSize})
    cell:addChild(goodsLayer)

    local goodsBgs = {}
    for i = 1, 3 do
        local goodsBg = display.newNSprite(RES_DICT.ACTIVITY_FUND_BG_GOODS, (i - 1) * 90, goodsLayerSize.height / 2, {ap = display.LEFT_CENTER})
        goodsLayer:addChild(goodsBg)
        table.insert(goodsBgs, goodsBg)
    end

    local worthLabel = display.newLabel(size.width - 36, size.height - 40, {ap = display.RIGHT_CENTER, fontSize = 22, color = '#d05800'})
    cell:addChild(worthLabel)

    local drawBtn = require('common.CommonDrawButton').new({btnParams = {
        ap = display.CENTER,
        scale9 = true, size = cc.size(123, 62),
        enable = true,
    }})
    display.commonUIParams(drawBtn, {po = cc.p(size.width - 86, targetLabel:getPositionY()), ap = display.CENTER})
    cell:addChild(drawBtn)

    local unlockImg = display.newNSprite(RES_DICT.ACTIVITY_FUND_BG_FARME_UNLOCK, size.width / 2, size.height / 2, {ap = display.CENTER})
    cell:addChild(unlockImg)
    unlockImg:setVisible(false)

    cell.viewData = {
        targetLabel = targetLabel,
        goodsLayer  = goodsLayer,
        drawBtn     = drawBtn,
        unlockImg   = unlockImg,
        goodsBgs    = goodsBgs,
        worthLabel  = worthLabel,

        goodNodes   = {},
    }

    return cell
end

CreateGoodNode = function (goodsData)
    local goodsNode = require('common.GoodNode').new({
        id = checkint(goodsData.goodsId),
        amount = checkint(goodsData.num),
        showAmount = true,
        highlight = 1,
        callBack = function (sender)
            app.uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = sender.goodId, type = 1})
        end
    })
    return goodsNode
end

function ActivityGrowthFundView:CreateCell(size)
    return CreateCell_(size)
end

function ActivityGrowthFundView:getViewData()
    return self.viewData_
end

return ActivityGrowthFundView