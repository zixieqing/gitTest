       --[[
游乐园（夏活）今日蛋池view 
--]]
local AnniversaryCapsulePoolView = class('AnniversaryCapsulePoolView', function ()
    local node = CLayout:create(display.size)
    node.name = 'anniversary.AnniversaryCapsulePoolView'
    node:enableNodeEvents()
    return node
end)

local RES_DICT = {
    COMMON_BG_4                          = app.anniversaryMgr:GetResPath('ui/common/common_bg_4'),
    COMMON_TITLE_5                      = app.anniversaryMgr:GetResPath('ui/common/common_title_5'),
    COMMON_BG_GOODS                     = app.anniversaryMgr:GetResPath('ui/common/common_bg_goods'),
    SEASON_LOOTS_LINE_1                 = app.anniversaryMgr:GetResPath('ui/common/season_loots_line_1.png'),
    ANNI_REWARDS_LABEL_CARD_PREVIEW     = app.anniversaryMgr:GetResPath('ui/anniversary/rewardPreview/anni_rewards_label_card_preview.png'),
    DRAW_PROBABILITY_BTN                = app.anniversaryMgr:GetResPath('ui/home/capsule/draw_probability_btn.png'),
    ANNI_DRAW_REWARDS_BG_CARD           = app.anniversaryMgr:GetResPath('ui/anniversary/capsule/anni_draw_rewards_bg_card.png'),

}

local REWARD_PREVIEW_RATE_CONF = {
    1,      -- 稀有
    0,      -- 普通
}

local uiMgr = app.uiMgr

local CreateView = nil

function AnniversaryCapsulePoolView:ctor( ... )
    self.args = unpack({...}) or {}
    self:InitUI()
end
--[[
init ui
--]]
function AnniversaryCapsulePoolView:InitUI()
    -- eaterLayer
    local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 255*0.6))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setPosition(cc.p(display.cx, display.cy))
    self:addChild(eaterLayer, -1)
    eaterLayer:setOnClickScriptHandler(function()
        PlayAudioByClickClose()
        local scene = uiMgr:GetCurrentScene()
        if scene then
            scene:RemoveDialog(self)
        end
    end)

    xTry(function ( )
        self.viewData = CreateView( )
        self:addChild(self.viewData.view)
        self.viewData.view:setPosition(display.center)

        self:initView()
    end, __G__TRACKBACK__)
end

function AnniversaryCapsulePoolView:initView()
    local viewData = self:getViewData()
    local probabilityBtn     = viewData.probabilityBtn
    display.commonUIParams(probabilityBtn, {cb = handler(self, self.onClickProbabilityBtnAction)})

    local rewardListView     = viewData.rewardListView
    local rewardPreviewDatas = self.args.rewardPreviewDatas or {}
    
    for i, rateField in pairs(REWARD_PREVIEW_RATE_CONF) do
        local rewardPreviewData = rewardPreviewDatas[rateField]
        if rewardPreviewData and next(rewardPreviewData) ~= nil  then
            local cell = self:CreateListCell(rewardPreviewData)
            rewardListView:insertNodeAtLast(cell)
        end
    end
    rewardListView:reloadData()

    if self.args.confId or self.args.skinId then
        local cardPreviewBtn     = viewData.cardPreviewBtn
        cardPreviewBtn:setVisible(true)
        local cardPreviewData = {confId = self.args.confId, skinId = self.args.skinId}
        cardPreviewBtn:RefreshUI(cardPreviewData)
    end

    local roleImg = viewData.roleImg
    local roleBgPath = self.args.roleBgPath
    if roleBgPath then
        roleImg:setTexture(roleBgPath)
    end
    roleImg:setVisible(true)
end

function AnniversaryCapsulePoolView:updateRoleImg(roleImg, roleBg)

end

function AnniversaryCapsulePoolView:CreateListCell(rewardPreviewData)
    
    local viewData = self:getViewData()
    local listViewLayoutSize = viewData.listViewLayoutSize
    local rewardList  = rewardPreviewData.list
    local rewardCount = #rewardList
    local goodCellSize = cc.size(120, 118)
    local maxCol      = 5
    local maxRow      = math.ceil(rewardCount / maxCol)
    local gap         = 10
    local distance    = (listViewLayoutSize.width - (goodCellSize.width) * 5) / 2
    local layerSize   = cc.size(listViewLayoutSize.width, maxRow * goodCellSize.height + 80)
    
    local layer = display.newLayer(0, 0, {size = layerSize})

    local width, height = layerSize.width, layerSize.height

    local label = display.newLabel(16 , height -20 , fontWithColor('8' ,{ap = display.LEFT_CENTER,  text = rewardPreviewData.title}))
    layer:addChild(label)
    local line = display.newImageView(RES_DICT.SEASON_LOOTS_LINE_1, width/2, height -35)
    layer:addChild(line)

    local x, y = distance, height - 50
    for i = 1, rewardCount do
        local rewardData = rewardList[i]
        if rewardData then
            local goodNode = self:CreateGoodCell(rewardData.reward)
            display.commonUIParams(goodNode, {po = cc.p(x, y), ap = display.LEFT_TOP})
            -- goodNode:setScale(0.92)
            layer:addChild(goodNode)

            if (i % 5) == 0 then
                x = distance
                y = y - goodCellSize.height
            else
                x = goodCellSize.width + x
            end
            
        end
    end

    return layer
end

function AnniversaryCapsulePoolView:CreateGoodCell(reward)
    local goodNode = require('common.GoodNode').new({id = reward.goodsId, amount = reward.num, showAmount = true, callBack = function (sender)
        uiMgr:ShowInformationTipsBoard({ targetNode = sender, iconId = sender.goodId, type = 1 })
    end})

    return goodNode
end

function AnniversaryCapsulePoolView:onClickProbabilityBtnAction()
    PlayAudioByClickNormal()
    local capsuleProbabilityView = require( 'Game.views.drawCards.CapsuleProbabilityView' ).new({rate = self.args.rate or {}})
    local scene = uiMgr:GetCurrentScene()
    scene:AddDialog(capsuleProbabilityView)
end

CreateView = function ()
    local bgSize = cc.size(982, 652)
    local view = CLayout:create(bgSize)
    -- mask
    local mask = CColorView:create(cc.c4b(0, 0, 0, 0))
    mask:setTouchEnabled(true)
    mask:setContentSize(bgSize)
    mask:setAnchorPoint(cc.p(0.5, 0.5))
    mask:setPosition(cc.p(bgSize.width/2, bgSize.height/2))
    view:addChild(mask, -1)
    -- 背景
    local bgImg = display.newImageView(RES_DICT.COMMON_BG_4, bgSize.width / 2, bgSize.height / 2, {scale9 = true, size = bgSize})
    bgImg:setPosition(cc.p(bgSize.width / 2, bgSize.height / 2))
    view:addChild(bgImg, 1)
    -- 分割线
    local linePos = cc.p(680, bgSize.height/2)
    local lineImg = display.newImageView(RES_DICT.SEASON_LOOTS_LINE_1, linePos.x, linePos.y)
    lineImg:setRotation(90)
    view:addChild(lineImg, 3)
    -- 左侧Layout -- 
    local leftLayoutSize = cc.size(linePos.x, bgSize.height)
    local leftLayout = CLayout:create(leftLayoutSize)
    display.commonUIParams(leftLayout, {po = cc.p(0, bgSize.height / 2), ap = cc.p(0, 0.5)})
    view:addChild(leftLayout, 5)
    -- 标题
    local leftLayoutTitle = display.newButton(leftLayoutSize.width / 2, leftLayoutSize.height - 35, {n = RES_DICT.COMMON_TITLE_5, scale9 = true})
    leftLayout:addChild(leftLayoutTitle, 1)
    display.commonLabelParams(leftLayoutTitle, fontWithColor('6', {text = app.anniversaryMgr:GetPoText(__('奖励一览')), paddingW = 40}))

    -- 概率
    local probabilityBtn = display.newButton(660, bgSize.height - 46, {ap = cc.p(1, 0.5), n = RES_DICT.DRAW_PROBABILITY_BTN, scale9 = true})
    leftLayout:addChild(probabilityBtn, 10)
    display.commonLabelParams(probabilityBtn, fontWithColor(18, {text = app.anniversaryMgr:GetPoText(__('概率')), paddingW = 20}))
    -- probabilityBtn:setVisible(false)

    -- 列表Layout
    local listViewLayoutSize = cc.size(645, 540)
    local listViewLayout = CLayout:create(listViewLayoutSize)
    display.commonUIParams(listViewLayout, {po = cc.p(leftLayoutSize.width/2, 42), ap = cc.p(0.5, 0)})
    leftLayout:addChild(listViewLayout, 5)
    -- 列表背景
    local listViewBg = display.newImageView(RES_DICT.COMMON_BG_GOODS, listViewLayoutSize.width / 2, listViewLayoutSize.height / 2
    , { size = cc.size(listViewLayoutSize.width, listViewLayoutSize.height + 4), scale9 = true } )
    listViewLayout:addChild(listViewBg)
    -- 列表
    local rewardListView = CListView:create(listViewLayoutSize)
    rewardListView:setDirection(eScrollViewDirectionVertical)
    rewardListView:setPosition(cc.p(listViewLayoutSize.width / 2, listViewLayoutSize.height / 2))
    listViewLayout:addChild(rewardListView)
    -- 左侧Layout -- 

    -- 右侧Layout --
    local rightLayoutSize = cc.size(bgSize.width - leftLayoutSize.width, bgSize.height)
    local rightLayout = CLayout:create(rightLayoutSize)
    display.commonUIParams(rightLayout, {po = cc.p(leftLayoutSize.width, bgSize.height / 2), ap = cc.p(0, 0.5)})
    view:addChild(rightLayout, 5)
    
    local roleImg = display.newImageView(RES_DICT.ANNI_DRAW_REWARDS_BG_CARD, 7, 2, {ap = cc.p(0, 0)})
    rightLayout:addChild(roleImg, 5)
    roleImg:setVisible(false)

    -- card preview btn
    local cardPreviewBtn = require("common.CardPreviewEntranceNode").new()
    display.commonUIParams(cardPreviewBtn, {ap = display.RIGHT_BOTTOM, po = cc.p(rightLayoutSize.width - 10, 24)})
    rightLayout:addChild(cardPreviewBtn, 5)
    cardPreviewBtn:setVisible(false)

    local cardPreviewTip = display.newImageView(RES_DICT.ANNI_REWARDS_LABEL_CARD_PREVIEW, -155, 8, {ap = display.RIGHT_CENTER})
    cardPreviewTip:setScaleX(-1)
    cardPreviewBtn:addChild(cardPreviewTip)
    
    cardPreviewBtn:addChild(display.newLabel(105, 8, fontWithColor(14, {ap = display.RIGHT_CENTER, text = app.anniversaryMgr:GetPoText(__('卡牌详情'))})))
    -- 右侧Layout --

    return {
        view               = view,
        probabilityBtn     = probabilityBtn,
        rewardListView     = rewardListView,
        listViewLayoutSize = listViewLayoutSize,
        roleImg            = roleImg,
        cardPreviewBtn     = cardPreviewBtn,
    }
end

function AnniversaryCapsulePoolView:getViewData()
    return self.viewData
end

return AnniversaryCapsulePoolView