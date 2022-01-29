--[[
 * descpt : 新游戏商店 - 月卡商店 - 商品节点
]]
local GoodNode = require('common.GoodNode')
local MonthCardStoreCell = class('MonthCardStoreCell', function()
    return display.newLayer(0, 0, {name = 'MonthCardStoreCell'})
end)

local VIEW_SIZE = cc.size(1080, 235)

local RES_DICT = {
    RAID_BOSS_BTN_SEARCH            = _res('ui/common/raid_boss_btn_search.png'),
    SHOP_BTN_CARD_DEFAULT           = _res('ui/stores/month/shop_btn_card_default.png'),
    SHOP_DIAMONDS_ICO_CARD_1        = _res('ui/stores/month/shop_diamonds_ico_card_1.png'),
    SHOP_DIAMONDS_ICO_CARD_2        = _res('ui/stores/month/shop_diamonds_ico_card_2.png'),
    SHOP_DIAMONDS_ICO_CARD_3        = _res('ui/stores/month/shop_diamonds_ico_card_3.png'),
    SHOP_LINE_3                     = _res("ui/stores/month/shop_line_3.png"),
    SHOP_CARD_LABEL_BUY             = _res('ui/stores/month/shop_card_label_buy.png'),
    SHOP_RECHARGE_LIGHT_RED         = _res('ui/home/commonShop/shop_recharge_light_red.png'),
    SHOP_CARD_ICO_DETAILS_1         = _res('ui/stores/month/shop_card_ico_details_1.png'),
    SHOP_CARD_ICO_DETAILS_2         = _res('ui/stores/month/shop_card_ico_details_2.png'),
    SHOP_CARD_ICO_DETAILS_3         = _res('ui/stores/month/shop_card_ico_details_3.png'),
}


local CreateView = nil
local CreateGoodNode = nil

-------------------------------------------------
-- life cycle

function MonthCardStoreCell:ctor( ... )
    local args = unpack({...}) or {}
    self.isControllable_ = true

    self:setContentSize(args.size or VIEW_SIZE)

    self.timeFormatList = {}

    -- create view
    self.viewData_ = CreateView(self:getContentSize())
    self:addChild(self.viewData_.view)

    self:initView()
end

function MonthCardStoreCell:initView()
    local viewData       = self:getViewData()
    display.commonUIParams(viewData.privilegeLayer, {cb = handler(self, self.onClickPrivilegeLayerAction)})
    display.commonUIParams(viewData.purchaseLayer, {cb = handler(self, self.onClickPurchaseLayerAction)})
end

function MonthCardStoreCell:updateCell(data, dataTimestamp)

    self.data_ = data or {}
    self.dataTimestamp_ = dataTimestamp

    local viewData       = self:getViewData()
    local memberCardName = viewData.memberCardName
    local vipConf        = data.vipConf or {}
    local memberData     = data.memberData or {}
    local memberId       = memberData.memberId

    display.commonLabelParams(memberCardName, {text = tostring(vipConf.vipName) , w = 260 , hAlign = display.TAC})
    viewData.memberIcon:setTexture(self:getMemberIconByMemberId(memberId))
    viewData.memberDescIcon:setTexture(self:getMemberDetailsIconByMemberId(memberId))
    local price = nil
    if isElexSdk() then
        price =  CommonUtils.GetCurrentAndOriginPriceDByPriceData(memberData)
    else
        price =  string.format(__("￥%s") ,memberData.price )
    end
    display.commonLabelParams(viewData.priceLabel, {text = price })
    self:updatePurchaseReward(vipConf)
    self:updateDailyReward(vipConf)
    self:updateMemberInfoLabel(memberData, self.dataTimestamp_)
end

function MonthCardStoreCell:updatePurchaseReward(vipConf)
    local viewData       = self:getViewData()
    local purchaseRewardNodes = viewData.purchaseRewardNodes
    local rewards = {{goodsId = checktable(GAME_MODULE_OPEN).DUAL_DIAMOND and PAID_DIAMOND_ID or DIAMOND_ID, type = 90, num = vipConf.diamond}}
    self:updateGoodList( rewards, purchaseRewardNodes, cc.p(329, 105))

    local vipLevel = vipConf.vipLevel
    local isOwnMember = checkint(app.gameMgr:GetUserInfo().member[tostring(vipLevel)]) > 0
    local goodState = isOwnMember and -1 or 1
    for i, goodNode in ipairs(purchaseRewardNodes) do
        goodNode:setState(goodState)
        goodNode.arrow:setVisible(goodState == -1)
    end
end

function MonthCardStoreCell:updateDailyReward(vipConf)
    local viewData       = self:getViewData()
    local dailyRewardNodes = viewData.dailyRewardNodes
    local rewards          = vipConf.rewards or {}
    self:updateGoodList( rewards, dailyRewardNodes, cc.p(554, 104))
end

function MonthCardStoreCell:updateMemberInfoLabel(memberData)
    local viewData       = self:getViewData()
    local leftTimeLabel = viewData.leftTimeLabel
    local purchaseLabel   = viewData.purchaseLabel
    local memberId = memberData.memberId

    local member = app.gameMgr:GetUserInfo().member
    local memberInfo = member[tostring(memberId)]

    local richTextList = nil
    local text = nil
    if memberInfo then
        richTextList = self:getTimeFontInfoBySeconds(checkint(memberInfo.leftSeconds))
        text = __('立即续费')
    else
        text = __('立即购买')
    end
    
    display.commonLabelParams(purchaseLabel, {text = text})

    local isShowLeftTime = richTextList ~= nil
    leftTimeLabel:setVisible(isShowLeftTime)
    if isShowLeftTime then
        display.reloadRichLabel(leftTimeLabel, {c = richTextList})
        CommonUtils.AddRichLabelTraceEffect(leftTimeLabel, '#663022', 2)
        CommonUtils.SetNodeScale(leftTimeLabel , {width = 120})
    end
end

function MonthCardStoreCell:updateGoodList(rewards, goodNodes, startPosition)
    local viewData       = self:getViewData()
    local layer          = viewData.layer
    local goodScale      = 0.85
    local rewardCount    = #rewards
    local goodsNodeCount = #goodNodes
    local count = math.max(goodsNodeCount,  rewardCount)

    for i = 1, count do
        local reward = rewards[i]
        local goodNode = goodNodes[i]
        if reward then
            if goodNode then
                goodNode:setVisible(true)
                goodNode:RefreshSelf(reward)
            else
                goodNode = CreateGoodNode(reward)
                local goodNodeSize = goodNode:getContentSize()
                local pos = CommonUtils.getGoodPos({index = i, goodNodeSize = goodNodeSize, scale = goodScale, midPointX = startPosition.x, midPointY = startPosition.y, col = rewardCount, maxCol = 3, goodGap = 8})
                display.commonUIParams(goodNode, {ap = display.CENTER, po = pos})
                goodNode:setScale(goodScale)
                layer:addChild(goodNode)
                table.insert(goodNodes, goodNode)
            end
        elseif goodNode then
            goodNode:setVisible(false)
        end
    end

end

CreateView = function (size)
    local view = display.newLayer(0,0,{size = size})

    -------------------layer start--------------------
    local layerSize = cc.size(1028, 221)
    local layer = display.newLayer(size.width / 2, size.height / 2,
    {
        ap = display.CENTER,
        size = layerSize,
    })
    view:addChild(layer)

    local bg = display.newNSprite(RES_DICT.SHOP_BTN_CARD_DEFAULT, 577, 112,
    {
        ap = display.CENTER,
    })
    layer:addChild(bg)

    local memberIcon = display.newNSprite(RES_DICT.SHOP_DIAMONDS_ICO_CARD_1, 0, 107,
    {
        ap = display.LEFT_CENTER,
    })
    layer:addChild(memberIcon)

    local linePosXConf = {
        417, 699, 891
    }
    for i, v in ipairs(linePosXConf) do
        layer:addChild(display.newNSprite(RES_DICT.SHOP_LINE_3, v, 194, {ap = display.CENTER_TOP}))
    end

    local buyBg = display.newNSprite(RES_DICT.SHOP_CARD_LABEL_BUY, 39, 26,
    {
        ap = cc.p(0, 0),
    })
    layer:addChild(buyBg)

    local memberCardName = display.newLabel(130, 52,
    {
        ap = display.CENTER,
        fontSize = 28,
        color = '#ffffff',
        font = TTF_GAME_FONT, ttf = true,
        outline = '#664e0e',
        outlineSize = 2,
    })
    layer:addChild(memberCardName)

    local purchaseTipTitle = display.newLabel(329, 180,
    {
        text = __('立即获得'),
        ap = display.CENTER,
        fontSize = 20,
        color = '#ffffff',
    })
    layer:addChild(purchaseTipTitle)

    local dailyRewardTitle = display.newLabel(551, 180,
    {
        text = __('每日奖励'),
        ap = display.CENTER,
        fontSize = 20,
        color = '#ffffff',
    })
    layer:addChild(dailyRewardTitle)

    local privilegeTitle = display.newLabel(789, 180,
    {
        text = __('御侍特权'),
        ap = display.CENTER,
        fontSize = 20,
        color = '#ffffff',
    })
    layer:addChild(privilegeTitle, 1)

    local privilegeLayerSize = cc.size(90, 90)
    local privilegeLayer = display.newLayer(789, 103,
    {
        color = cc.c4b(0,0,0,0),
        ap = display.CENTER,
        size = privilegeLayerSize,
        enable = true,
    })
    layer:addChild(privilegeLayer)

    local lightImg = display.newNSprite(RES_DICT.SHOP_RECHARGE_LIGHT_RED, privilegeLayerSize.width / 2, privilegeLayerSize.height / 2)
    privilegeLayer:addChild(lightImg)
    lightImg:setScale(0.9)

    local memberDescIcon = display.newNSprite(RES_DICT.SHOP_CARD_ICO_DETAILS_1, privilegeLayerSize.width / 2, privilegeLayerSize.height / 2)
    privilegeLayer:addChild(memberDescIcon)

    local searchIcon = display.newNSprite(RES_DICT.RAID_BOSS_BTN_SEARCH, privilegeLayerSize.width, 5, {ap = display.RIGHT_BOTTOM})
    privilegeLayer:addChild(searchIcon)

    local leftTimeLabel = display.newRichLabel(786, 46, {ap = display.CENTER})
    layer:addChild(leftTimeLabel)

    local priceLabel = display.newLabel(946, 115,
    {
        ap = display.CENTER,
        fontSize = 26,
        color = '#ffffff',
        font = TTF_GAME_FONT, ttf = true,
        outline = '#9d631e',
        outlineSize = 2,
    })
    layer:addChild(priceLabel)

    ---------------purchaseLayer start----------------
    local purchaseLayer = display.newLayer(942, 27,
    {
        color = cc.c4b(0,0,0,0),
        ap = display.CENTER_BOTTOM,
        size = cc.size(160, 49),
        enable = true,
    })
    layer:addChild(purchaseLayer)

    local purchaseLabel = display.newLabel(90, 28,
    {
        text = __('立即购买'),
        ap = display.CENTER,
        fontSize = 22,
        color = '#ffffff',
        font = TTF_GAME_FONT, ttf = true,
        outline = '#663022',
        outlineSize = 2,
    })
    purchaseLayer:addChild(purchaseLabel)

    ----------------purchaseLayer end-----------------
    --------------------layer end---------------------
    
    return {
        view                    = view,
        layer                   = layer,
        purchaseTipTitle        = purchaseTipTitle,
        -- purchaseRewardsLayer    = purchaseRewardsLayer,
        dailyRewardTitle        = dailyRewardTitle,
        -- dailyRewardsLayer       = dailyRewardsLayer,
        privilegeTitle          = privilegeTitle,
        privilegeLayer          = privilegeLayer,
        leftTimeLabel           = leftTimeLabel,
        priceLabel              = priceLabel,
        purchaseLayer           = purchaseLayer,
        purchaseLabel           = purchaseLabel,
        memberIcon              = memberIcon,
        memberCardName          = memberCardName,
        memberDescIcon          = memberDescIcon,

        purchaseRewardNodes     = {},
        dailyRewardNodes        = {}
    }
end

-- 创建道具
CreateGoodNode = function (reward)
	local function callBack(sender)
        app.uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = sender.goodId, type = 1})
    end

    local goodNode = GoodNode.new({id = reward.goodsId, amount = reward.num, showAmount = true, callBack = callBack})
    goodNode.arrow = display.newImageView(RES_DICT.COMMON_ARROW, goodNode:getContentSize().width / 2, goodNode:getContentSize().height / 2)
    goodNode.arrow:setVisible(false)
    goodNode:addChild(goodNode.arrow, 10)

   return goodNode
end


function MonthCardStoreCell:getMemberIconByMemberId(memberId)
    return string.format(_res('ui/stores/month/shop_diamonds_ico_card_%s.png'), tostring(memberId))
end

function MonthCardStoreCell:getMemberDetailsIconByMemberId(memberId)
    return string.format(_res('ui/stores/month/shop_card_ico_details_%s.png'), tostring(memberId))
end

function MonthCardStoreCell:getTimeFormatBySeconds(seconds)
    local DAY = 86400
    local HOUR = 3600
    local MINUTES = 60
    seconds = checkint(seconds)
    local time = 0
    local timeList = nil
    if seconds > DAY then
        if self.timeFormatList['1'] == nil then
            self.timeFormatList['1'] = string.split(__('剩余_num1_天'), '_')
        end
        timeList = self.timeFormatList['1']
        time = math.floor(seconds / DAY)
    elseif seconds <= DAY and seconds > HOUR then
        if self.timeFormatList['2'] == nil then
            self.timeFormatList['2'] = string.split(__('剩余_num1_小时'), '_')
        end
        timeList = self.timeFormatList['2']
        time = math.floor(seconds / HOUR)
    elseif seconds <= HOUR and seconds > MINUTES then
        if self.timeFormatList['3'] == nil then
            self.timeFormatList['3'] = string.split(__('剩余_num1_分钟'), '_')
        end
        timeList = self.timeFormatList['3']
        time = math.floor((seconds / MINUTES) % MINUTES)
    else
        if self.timeFormatList['4'] == nil then
            self.timeFormatList['4'] = string.split(__('剩余_num1_秒'), '_')
        end
        timeList = self.timeFormatList['4']
        time = seconds
    end

    return timeList, time
end

function MonthCardStoreCell:getTimeFontInfoBySeconds(seconds)
    local timeList, time = self:getTimeFormatBySeconds(seconds)

    local timeFontInfo = {}
    for i, v in ipairs(timeList) do
        if v == 'num1' then
            table.insert(timeFontInfo, {
                text = time,
                fontSize = 22,
                color = '#ffd36c',
                font = TTF_GAME_FONT, ttf = true,
            })
        else
            table.insert(timeFontInfo, {
                text = v,
                fontSize = 22,
                color = '#ffffff',
                font = TTF_GAME_FONT, ttf = true,
            })
        end
    end

    return timeFontInfo
end

function MonthCardStoreCell:getViewData()
    return self.viewData_
end

function MonthCardStoreCell:getData()
    return self.data_ or {}
end

function MonthCardStoreCell:onClickPrivilegeLayerAction(sender)
    -- 克隆下数据 并 更新下 倒计时
    local memberData = clone(self:getData().memberData or {})
    memberData.leftSeconds = math.max(self.dataTimestamp_ + checkint(memberData.leftSeconds) - os.time(), 0)

    local MemberShopViewMediator = require( 'Game.mediator.MemberShopViewMediator' )
    local mediator = MemberShopViewMediator.new({data = memberData})
    app:RegistMediator(mediator)
end 

function MonthCardStoreCell:onClickPurchaseLayerAction(sender)
    local memberData = self:getData().memberData or {}
    app:DispatchSignal(COMMANDS.COMMANDS_All_Shop_GetPayOrder, {
        productId = memberData.productId, 
        name = 'MonthCardStoreMediator', 
        price_ = memberData.price, 
        channelProductId_ = memberData.channelProductId
    })
end 


return MonthCardStoreCell
