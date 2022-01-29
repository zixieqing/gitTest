--[[
飨灵投票初赛投票view
--]]
local display                      = display
local VIEW_SIZE                    = display.size
---@type ActivityCardMatchVoteCardNode
local ActivityCardMatchVoteCardNode = require('Game.views.activity.cardMatch.ActivityCardMatchVoteCardNode')
local ActivityCardMatchVoteView = class('ActivityCardMatchVoteView', function ()
    local node = CLayout:create(VIEW_SIZE)
    node.name = 'Game.views.activity.cardMatch.ActivityCardMatchVoteView'
    node:enableNodeEvents()
    return node
end)

local CreateView     = nil
local CreateCell_  = nil
local CreateGoodNode = nil

local RES_DICT = {
    COMMON_ARROW                  = _res('ui/common/common_arrow.png'),
    COMMON_BTN_ORANGE        = _res('ui/common/common_btn_orange.png'),
    BTN_REFRESH              = _res('ui/home/commonShop/shop_btn_refresh.png'),
    CARDMATCH_PRELIMINARY_BG = _res('ui/home/activity/cardMatch/cardmatch_preliminary_bg.png'),
    CARDMATCH_HEAD_BG        = _res('ui/home/activity/cardMatch/cardmatch_head_bg.png'),
    CARDMATCH_BTN_VOTE       = _res('ui/home/activity/cardMatch/cardmatch_btn_vote.png'),
    CARDMATCH_CARD_BG        = _res('ui/home/activity/cardMatch/cardmatch_card_bg.png'),
    CARDMATCH_TICKET_NUMBER_BG        = _res('ui/home/activity/cardMatch/cardmatch_ticket_number_bg.png'),
    CARDMATCH_TOP2_BG        = _res('ui/home/activity/cardMatch/cardmatch_top2_bg.png'),
    CARDMATCH_TOP1_BG        = _res('ui/home/activity/cardMatch/cardmatch_top1_bg.png'),
    CARDMATCH_VOTE_BAR_1        = _res('ui/home/activity/cardMatch/cardmatch_vote_bar_1.png'),
    CARDMATCH_VOTE_BAR_2        = _res('ui/home/activity/cardMatch/cardmatch_vote_bar_2.png'),
    CARDMATCH_VOTE_BAR_BG        = _res('ui/home/activity/cardMatch/cardmatch_vote_bar_bg.png'),
}

function ActivityCardMatchVoteView:ctor( ... )
    self.args = unpack({...})

    self:InitUI()
end

--[[
init ui
--]]
function ActivityCardMatchVoteView:InitUI()
    xTry(function ( )
        self.viewData_ = CreateView(VIEW_SIZE)
        self:addChild(self.viewData_.view)
	end, __G__TRACKBACK__)
    
end

---UpdateRewardsDrawTimes
---每日领取投票奖励所需次数
---@param viewData table 视图数据
---@param data table     选票信息
function ActivityCardMatchVoteView:UpdateRewardsDrawTimes(viewData, data)
    local rewardsDrawTimes = viewData.rewardsDrawTimes
    display.commonLabelParams(rewardsDrawTimes, {
        text = string.format(__('每日投票奖励%s/%s'), data.times, data.targetNum)})
end

---UpdateRewardsLayer
---更新奖励层
---@param viewData table 视图数据
---@param data table     选票信息
function ActivityCardMatchVoteView:UpdateRewardsLayer(viewData, data)
    local rewards = data.rewards
    local rewardsLayer = viewData.rewardsLayer
    local isDrawPrize = checkint(data.hasPrize) > 0
    if rewardsLayer:getChildrenCount() == 0 then
        for i, reward in ipairs(rewards) do
            local goodNode = CreateGoodNode(reward)
            display.commonUIParams(goodNode, {ap = display.LEFT_CENTER, po = cc.p((i - 1) * 100, 40)})
            rewardsLayer:addChild(goodNode)
            goodNode.hasIcon:setVisible(isDrawPrize)
        end
    else
        for i, goodNode in ipairs(rewardsLayer:getChildren()) do
            goodNode.hasIcon:setVisible(isDrawPrize)
        end
    end
end

---UpdateVoteTicket
---更新投票券
---@param viewData table 视图数据
---@param data table     选票信息
function ActivityCardMatchVoteView:UpdateVoteTicket(viewData, data)
    local ticketIcon = viewData.ticketIcon
    local voteGoodsId = data.voteGoodsId
    ticketIcon:setTexture(CommonUtils.GetGoodsIconPathById(voteGoodsId))

    local ticketNumLabel = viewData.ticketNumLabel
    display.commonLabelParams(ticketNumLabel, {text = CommonUtils.GetCacheProductNum(voteGoodsId)})
end


---UpdategridView
---更新卡牌列表
---@param viewData table 视图数据
---@param data table     选票信息
function ActivityCardMatchVoteView:UpdateGridView(viewData, data)
    local gridView = viewData.gridView
    local cards = data.cards or {}
    gridView:setCountOfCell(#cards)
    gridView:reloadData()
end

---------------------------------------
---更新cell 相关界面

---UpdateCell
---@param viewData table cell视图数据
---@param data table
function ActivityCardMatchVoteView:UpdateCell(viewData, data, cardId)
    local cardNode     = viewData.cardNode
    cardNode:RefreshUI(data, cardId)

    local voteBtn = viewData.voteBtn
end

---更新cell 相关界面
---------------------------------------

CreateView = function (size)
    local middleX, middleY = size.width * 0.5, size.height * 0.5
    local view = display.newLayer(middleX, middleY, {size = size, ap = display.CENTER})
    
    local blockLayer = display.newLayer(middleX, middleY, {size = size, ap = display.CENTER, enable = true, color = cc.c4b(0,0,0,130)})
    view:addChild(blockLayer)

    local bgSize = cc.size(1222, 692)
    local bgLayer = display.newLayer(middleX, middleY, {size = bgSize, ap = display.CENTER})
    view:addChild(bgLayer)

    bgLayer:addChild(display.newLayer(0,0,{size = bgSize, color = cc.c4b(0,0,0, 0), enable = true}))

    local bg = display.newNSprite(RES_DICT.CARDMATCH_PRELIMINARY_BG, bgSize.width * 0.5, bgSize.height * 0.5)
    bgLayer:addChild(bg)
    
    -- 投票奖励领取次数
    local rewardsDrawTimes = display.newLabel(20, bgSize.height - 38, {
        ap = display.LEFT_CENTER, w = 160, hAlign = display.TAC, fontSize = 26, color = '#5b3c25'})
    bgLayer:addChild(rewardsDrawTimes)

    local rewardsLayer = display.newLayer(rewardsDrawTimes:getPositionX() + 180, rewardsDrawTimes:getPositionY() + 6, {
        size = cc.size(500, 80), ap = display.LEFT_CENTER})
    bgLayer:addChild(rewardsLayer)

    -- 兑换券图标
    local ticketIcon = display.newNSprite(CommonUtils.GetGoodsIconPathById(DIAMOND_ID), bgSize.width - 250, rewardsDrawTimes:getPositionY() - 5)
    ticketIcon:setScale(0.35)
    bgLayer:addChild(ticketIcon, 1)

    local ticketNumBg = display.newNSprite(RES_DICT.CARDMATCH_TICKET_NUMBER_BG, ticketIcon:getPositionX() + 55, ticketIcon:getPositionY())
    bgLayer:addChild(ticketNumBg)

    local ticketNumLabel = display.newLabel(68, 17, fontWithColor(18, {text = 1111, ap = display.CENTER}))
    ticketNumBg:addChild(ticketNumLabel)

    -- 刷新按钮
    local refreshBtn = display.newButton(bgSize.width - 8, rewardsDrawTimes:getPositionY(), {n = RES_DICT.BTN_REFRESH, ap = display.RIGHT_CENTER})
    bgLayer:addChild(refreshBtn)

    local gridViewSize = cc.size(bgSize.width - 46, 580)
    local gridViewCellSize = cc.size(gridViewSize.width * 0.25, 144)
    local gridView = CGridView:create(gridViewSize)
    -- gridView:setDirection(eScrollViewDirectionHorizontal)
    gridView:setSizeOfCell(gridViewCellSize)
    gridView:setColumns(4)
    -- gridView:setBackgroundColor(cc.c4b(178, 63, 88, 100))
    display.commonUIParams(gridView, {ap = display.CENTER, po = cc.p(bgSize.width * 0.5, 315)})
    bgLayer:addChild(gridView)

    return {
        view             = view,
        blockLayer       = blockLayer,
        rewardsDrawTimes = rewardsDrawTimes,
        rewardsLayer     = rewardsLayer,
        ticketIcon       = ticketIcon,
        ticketNumLabel   = ticketNumLabel,
        refreshBtn       = refreshBtn,
        gridView         = gridView,
    }
end

CreateCell_ = function (size)
    local cell = CGridViewCell:new()
    cell:setContentSize(size)

    local cardNode = ActivityCardMatchVoteCardNode.new({size = size})
    display.commonUIParams(cardNode, {ap = display.CENTER, po = cc.p(size.width * 0.5, size.height * 0.5)})
    cell:addChild(cardNode)

    local voteBtn = display.newButton(210, 24, {n = RES_DICT.CARDMATCH_BTN_VOTE, ap = display.CENTER})
    display.commonLabelParams(voteBtn, fontWithColor(16, {text = __('投票')}))
    cell:addChild(voteBtn)

    cell.viewData = {
        cardNode     = cardNode,
        voteBtn      = voteBtn,
    }
    return cell
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
    goodsNode:setScale(0.8)
    local goodsNodeSize = goodsNode:getContentSize()
    local hasIcon = display.newNSprite(RES_DICT.COMMON_ARROW, goodsNodeSize.width * 0.5, goodsNodeSize.height * 0.5, {ap = display.CENTER})
    goodsNode.hasIcon = hasIcon
    goodsNode:addChild(hasIcon, 20)
    hasIcon:setVisible(false)
    return goodsNode
end

function ActivityCardMatchVoteView:CreateCell(size)
    return CreateCell_(size)
end

function ActivityCardMatchVoteView:GetViewData()
    return self.viewData_
end

return ActivityCardMatchVoteView