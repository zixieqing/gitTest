local PassTicketListCell = class('PassTicketListCell', function ()
    local node = CLayout:create(display.size)
	node.name = 'Game.views.pass.PassTicketListCell'
	node:enableNodeEvents()
	return node
end)

local GoodNode = require('common.GoodNode')
local CreateGoodNode = nil

local RES_DICT = {
    COMMON_BG_LIST                  = _res('ui/common/common_bg_list.png'),
    COMMON_BTN_ORANGE               = _res('ui/common/common_btn_orange.png'),
    ACTIVITY_LOVE_LUNCH_ICO_HAVE    = _res('ui/home/activity/activity_love_lunch_ico_have.png'),
    ACTIVITY_DIARY_BTN_LOCK         = _res('ui/common/activity_diary_btn_lock.png'),
    ACTIVITY_DIARY_FARME_ASH        = _res('ui/home/activity/passTicket/activity_diary_farme_ash.png'),
}

function PassTicketListCell:ctor( ... )
    self.args = unpack({...}) or {}
    local size = self.args.size or cc.size(614, 104)
    self:setContentSize(size)

    local cellBgSize = cc.size(610, 98)
    local view = display.newLayer(size.width / 2, size.height / 2, {ap = display.CENTER, size = cellBgSize})
    self:addChild(view)

    local cellBg = display.newImageView(RES_DICT.COMMON_BG_LIST, cellBgSize.width / 2, cellBgSize.height / 2,
    {
        ap = display.CENTER,
        scale9 = true,
        size = cellBgSize
    })
    view:addChild(cellBg)
    self.cellBg = cellBg

    local cellLv = display.newButton(46, cellBgSize.height / 2,
    {
        ap = display.CENTER,
        n = RES_DICT.ACTIVITY_DIARY_FARME_ASH,
        scale9 = true, size = cc.size(79, 88),
        enable = false,
    })
    display.commonLabelParams(cellLv, {text = '1', fontSize = 22, color = '#5b3c25'})
    view:addChild(cellLv)
    self.cellLv = cellLv
    
    local baseRewardBgSize = cc.size(108, 88)
    local baseRewardBgLayer = display.newLayer(143, cellLv:getPositionY(), {ap = display.CENTER, size = baseRewardBgSize})
    view:addChild(baseRewardBgLayer)
    self.baseRewardBgLayer = baseRewardBgLayer

    local baseRewardBg = display.newImageView(RES_DICT.ACTIVITY_DIARY_FARME_ASH, baseRewardBgSize.width / 2, baseRewardBgSize.height / 2,
    {
        ap = display.CENTER,
        scale9 = true, size = baseRewardBgSize,
    })
    baseRewardBgLayer:addChild(baseRewardBg)
    self.baseRewardBg = baseRewardBg
    
    local superRewardBgSize = cc.size(254, 88)
    local superRewardBgLayer = display.newLayer(329, cellLv:getPositionY(), {ap = display.CENTER, size = superRewardBgSize})
    view:addChild(superRewardBgLayer)
    self.superRewardBgLayer = superRewardBgLayer

    local superRewardBg = display.newImageView(RES_DICT.ACTIVITY_DIARY_FARME_ASH, superRewardBgSize.width / 2, superRewardBgSize.height / 2,
    {
        ap = display.CENTER,
        scale9 = true, size = superRewardBgSize,
    })
    superRewardBgLayer:addChild(superRewardBg)
    self.superRewardBg = superRewardBg

    local drawBtnBg = display.newImageView(RES_DICT.ACTIVITY_DIARY_FARME_ASH, 460, cellLv:getPositionY(),
    {
        ap = display.LEFT_CENTER,
        scale9 = true, size = cc.size(147, 88),
    })
    view:addChild(drawBtnBg)
    self.drawBtnBg = drawBtnBg
    
    local drawBtn = display.newButton(539, 52,
    {
        ap = display.CENTER,
        n = RES_DICT.ACTIVITY_DIARY_BTN_LOCK,
        scale9 = true, size = cc.size(110.7, 55.8),
        enable = true,
    })
    display.commonLabelParams(drawBtn, fontWithColor(14, {text = __('领取'), fontSize = 22}))
    view:addChild(drawBtn)
    self.drawBtn = drawBtn

    local receivedLabel = display.newLabel(0, 0, fontWithColor(7, {fontSize = 22, text = __('已领取')}))
    display.commonUIParams(receivedLabel, {po = utils.getLocalCenter(drawBtn), ap = display.CENTER})
    drawBtn:addChild(receivedLabel)
    receivedLabel:setVisible(false)
    self.receivedLabel = receivedLabel

    local numLabel = display.newLabel(61, 31, fontWithColor(18, {ap = display.CENTER}))
    drawBtn:addChild(numLabel)
    numLabel:setVisible(false)
    self.numLabel = numLabel

    local goodsIcon = display.newNSprite(RES_DICT.GOODS_ICON_880108, 61, 31,
    {
        ap = display.CENTER,
    })
    goodsIcon:setScale(0.2)
    drawBtn:addChild(goodsIcon)
    goodsIcon:setVisible(false)
    self.goodsIcon = goodsIcon

    self.baseRewardGoodNodes  = {}
    self.superRewardGoodNodes = {}
end


function PassTicketListCell:updateBaseReward(data)
    local baseRewards = data.baseRewards or {}
    local hasDrawn = checkint(data.hasDrawn)

    local baseRewardBgLayer   = self.baseRewardBgLayer
    local baseRewardGoodNodes = self.baseRewardGoodNodes
    
    local baseRewardBgLayerSize = baseRewardBgLayer:getContentSize()
    local rewardCount    = #baseRewards
    local goodsNodeCount = #baseRewardGoodNodes

    local count = math.max(goodsNodeCount,  rewardCount)
    for i = 1, count do
        local reward = baseRewards[i]
        local goodNode = baseRewardGoodNodes[i]
        if reward then
            -- goodNode:setVisible(false)
            -- self:updateGoodNode(goodNode, reward, baseRewardGoodNodes)
            if goodNode then
                goodNode:setVisible(true)
                goodNode:RefreshSelf(reward)
            else
                goodNode = CreateGoodNode(reward)
                display.commonUIParams(goodNode, {ap = display.CENTER, po = cc.p(baseRewardBgLayerSize.width / 2, baseRewardBgLayerSize.height / 2)})
                goodNode:setScale(0.7)
                baseRewardBgLayer:addChild(goodNode)
                table.insert(baseRewardGoodNodes, goodNode)
            end

            local hasIcon = goodNode.hasIcon
            if hasIcon then
                hasIcon:setVisible(hasDrawn > 0)
            end

        elseif goodNode then
            goodNode:setVisible(false)
        end
    end

end

function PassTicketListCell:updateAdditionalReward(additionalRewards)
    local superRewardBgLayer   = self.superRewardBgLayer
    local superRewardGoodNodes = self.superRewardGoodNodes
    local superRewardBgLayerSize = superRewardBgLayer:getContentSize()

    local rewardCount    = #additionalRewards
    local goodsNodeCount = #superRewardGoodNodes
    
    local count = math.max(goodsNodeCount,  rewardCount)
    for i = 1, count do
        local reward = additionalRewards[i]
        local goodNode = superRewardGoodNodes[i]
        if reward then
            -- goodNode:setVisible(false)
            -- self:updateGoodNode(goodNode, reward, baseRewardGoodNodes)
            if goodNode then
                goodNode:setVisible(true)
                goodNode:RefreshSelf(reward)
            else
                goodNode = CreateGoodNode(reward)
                display.commonUIParams(goodNode, {ap = display.CENTER, po = cc.p(48 + (i-1) * 80, superRewardBgLayerSize.height / 2)})
                goodNode:setScale(0.65)
                superRewardBgLayer:addChild(goodNode)
                table.insert(superRewardGoodNodes, goodNode)
            end
        elseif goodNode then
            goodNode:setVisible(false)
        end
    end
end

CreateGoodNode = function (goodsData)
    local goodsNode = require('common.GoodNode').new({
        id = checkint(goodsData.goodsId),
        amount = checkint(goodsData.num),
        showAmount = true,
        callBack = function (sender)
            app.uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = sender.goodId, type = 1})
        end
    })

    local goodsNodeSize = goodsNode:getContentSize()
    local hasIcon = display.newNSprite(RES_DICT.ACTIVITY_LOVE_LUNCH_ICO_HAVE, goodsNodeSize.width / 2, goodsNodeSize.height / 2, {ap = display.CENTER})
    goodsNode.hasIcon = hasIcon
    goodsNode:addChild(hasIcon, 20)
    hasIcon:setVisible(false)
    return goodsNode
end

return PassTicketListCell