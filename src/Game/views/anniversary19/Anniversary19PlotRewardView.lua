local CommonDialog = require('common.CommonDialog')
local Anniversary19PlotRewardView = class('Anniversary19PlotRewardView', CommonDialog)

local RES_DICT = {
    ANNI_REWARDS_LABEL_CARD_PREVIEW = app.anniversary2019Mgr:GetResPath('ui/anniversary/rewardPreview/anni_rewards_label_card_preview.png'),
    WONDERLAND_POINT_BG_BOARD        = app.anniversary2019Mgr:GetResPath('ui/anniversary19/plotRewards/wonderland_point_bg_board.png'),
    WONDERLAND_POINT_BG_REWARD_CARD  = app.anniversary2019Mgr:GetResPath('ui/anniversary19/plotRewards/wonderland_point_bg_reward_card.png'),
    WONDERLAND_POINT_BG              = app.anniversary2019Mgr:GetResPath('ui/anniversary19/plotRewards/wonderland_point_bg.png'),
    WONDERLAND_POINT_LINE_BOARD      = app.anniversary2019Mgr:GetResPath('ui/anniversary19/plotRewards/wonderland_point_line_board.png'),
    WONDERLAND_POINT_LINE_TITLE      = app.anniversary2019Mgr:GetResPath('ui/anniversary19/plotRewards/wonderland_point_line_title.png'),
    WONDERLAND_POINT_LIST_BG_DEFAULT = app.anniversary2019Mgr:GetResPath('ui/anniversary19/plotRewards/wonderland_point_list_bg_default.png'),
    WONDERLAND_POINT_LIST_BG_SP      = app.anniversary2019Mgr:GetResPath('ui/anniversary19/plotRewards/wonderland_point_list_bg_sp.png'),
    WONDERLAND_POINT_LIST_LABEL      = app.anniversary2019Mgr:GetResPath('ui/anniversary19/plotRewards/wonderland_point_list_label.png'),
    WONDERLAND_POINT_LIST_LINE       = app.anniversary2019Mgr:GetResPath('ui/anniversary19/plotRewards/wonderland_point_list_line.png'),
    CASTLE_POINT_BTN_STORY           = app.anniversary2019Mgr:GetResPath('ui/castle/plotReward/castle_point_btn_story.png'),
    RNAK_IMG                         = app.anniversary2019Mgr:GetResPath('ui/home/nmain/main_btn_rank.png'),
}

local display = display

local CreateView = nil
local CreateCell_ = nil
local CreateGoodNode = nil
local CreateBaseRewardsCell = nil
local CreateAdvanceRewardsCell = nil

local RANK_REWARD_TYPE = {
    BASE    = 0,
    ADVANCE = 1,
}

function Anniversary19PlotRewardView:InitialUI( )
    xTry(function ( )
        self.viewData = CreateView(app.anniversary2019Mgr:GetIntegralGoodsId())
        self:InitView()
        
	end, __G__TRACKBACK__)
end

function Anniversary19PlotRewardView:InitData_()
end

function Anniversary19PlotRewardView:InitView()
end

---InitRankRewardListView
---初始化排行奖励列表
---@param rankRewards table 排行奖励列表
function Anniversary19PlotRewardView:InitRankRewardListView(rankRewards)
    local rankRewardListView = self:GetViewData().rankRewardListView
    local cell
    for index, value in ipairs(rankRewards) do
        local rewardType = value.type
        if rewardType == RANK_REWARD_TYPE.BASE then
            cell = CreateBaseRewardsCell(value)
        elseif rewardType == RANK_REWARD_TYPE.ADVANCE then
            cell = CreateAdvanceRewardsCell(value)
        end
        rankRewardListView:insertNodeAtLast(cell)

    end

    rankRewardListView:reloadData()
end

function Anniversary19PlotRewardView:UpdateCollLabel(viewData, goodsId)
    local goodsConf = CommonUtils.GetConfig('goods', 'goods', goodsId) or {}
    display.commonLabelParams(viewData.collLabel, {text = string.format(app.anniversary2019Mgr:GetPoText(__('已收集%s')), tostring(goodsConf.name))})
end

--==============================--
--desc: 更新剧情奖励列表
--@params datas         table  剧情奖励数据列表
--==============================--
function Anniversary19PlotRewardView:UpdateTableView(datas)
    local tableView = self:GetViewData().tableView
    tableView:setCountOfCell(#datas)
    tableView:reloadData()
end

--==============================--
--desc: 更新剧情奖励cell
--@params viewData      userdata 视图数据
--@params data          table     剧情奖励数据
--==============================--
function Anniversary19PlotRewardView:UpdateCell(viewData, data)
    self:UpdateRewardCell_(viewData, data)
end

--==============================--
--desc: 更新剧情稀有奖励cell
--@params data          table     剧情稀有奖励数据
--==============================--
function Anniversary19PlotRewardView:UpdateRareReward(data)
    local viewData = self:GetViewData()
    self:UpdateRewardCell_(viewData, data)

    local confData = data.confData or {}
    local cardPreviewBtn = viewData.cardPreviewBtn
    local rewards = confData.rewards or {}
    local confId = nil
    local skinId = nil
    for i, v in ipairs(rewards) do
        if CommonUtils.GetGoodTypeById(v.goodsId) == GoodsType.TYPE_CARD then
            confId = v.goodsId
            break
        elseif CommonUtils.GetGoodTypeById(v.goodsId) == GoodsType.TYPE_CARD_SKIN then
            skinId = v.goodsId
            break
        end
    end
    cardPreviewBtn:RefreshUI({confId = confId, skinId = skinId})
end

--==============================--
--desc: 更新剧情积分拥有数量
--@params curPoint        int     剧情积分拥有数量
--==============================--
function Anniversary19PlotRewardView:UpdateNumLabel(curPoint)
    display.commonLabelParams(self:GetViewData().numLabel, {text = curPoint})
end

--==============================--
--desc: 更新剧情奖励cell
--@params viewData      userdata 视图数据
--@params data          table     剧情奖励数据
--==============================--
function Anniversary19PlotRewardView:UpdateRewardCell_(viewData, data)
    display.commonLabelParams(viewData.integralNumLabel, {text = tostring(data.consumeNum)})
    viewData.drawBtn:RefreshUI({drawState = data.state})
    self:UpdateRewardLayer_(viewData, data)
end

--==============================--
--desc: 更新奖励层
--@params viewData table 视图数据
--@params data     table cell数据
--==============================--
function Anniversary19PlotRewardView:UpdateRewardLayer_(viewData, data)
    local rewardLayer      = viewData.rewardLayer
    local rewardNodes      = viewData.rewardNodes
    local confData         = data.confData or {}
    local rewards          = confData.rewards or {}
    local rewardCount      = #rewards
    local maxCount = math.max(rewardCount, #rewardNodes)
    local rewardLayerSize = rewardLayer:getContentSize()
    for i = 1, maxCount do
        local reward = rewards[i]
        local rewardNode = rewardNodes[i]
        
        if reward then
            if rewardNode then
                rewardNode:setVisible(true)
                rewardNode:RefreshSelf(reward)
            else
                rewardNode = CreateGoodNode(reward)
                rewardLayer:addChild(rewardNode)
                table.insert(rewardNodes, rewardNode)
            end
            display.commonUIParams(rewardNode, {po = cc.p(36 + (i - 1) * 93, rewardLayerSize.height / 2)})
        elseif rewardNode then
            rewardNode:setVisible(false)
        end
    end
end

CreateView = function (goodsId)
    local size = cc.size(1133, 648)
    local view = display.newLayer(0, 0, {size = size})

    ----------------------------------------------
    --- 排行奖励相关UI
    local rankBgLayer = display.newLayer(274, 325,
    {
        ap = display.RIGHT_CENTER,
        size = cc.size(274, 650),
        enable = true,
    })
    view:addChild(rankBgLayer, 2)

    local boardBg = display.newNSprite(RES_DICT.WONDERLAND_POINT_BG_BOARD, 137, 323,
    {
        ap = display.CENTER,
    })
    rankBgLayer:addChild(boardBg)

    -- 排行奖励列表
    local rankRewardListView = CListView:create(cc.size(244, 538))
    rankRewardListView:setPosition(cc.p(15, 94))
    rankRewardListView:setAnchorPoint(display.LEFT_BOTTOM)
    rankRewardListView:setDirection(eScrollViewDirectionVertical)
    rankBgLayer:addChild(rankRewardListView)
    -- rankRewardListView:setBackgroundColor(cc.c4b(64, 128, 255, 100))

    -- 排行榜按钮
    local rankBtnSize = cc.size(230, 56)
    local rankBtn = display.newButton(137, 39,
    {
        ap = display.CENTER,
        n = RES_DICT.CASTLE_POINT_BTN_STORY,
        scale9 = true, size = rankBtnSize,
    })
    display.commonLabelParams(rankBtn, fontWithColor(20, {outline = '#4d2222', fontSize = 20, text = app.anniversary2019Mgr:GetPoText(__('排行榜'))}))
    rankBgLayer:addChild(rankBtn)

    local rankImg = display.newNSprite(RES_DICT.RNAK_IMG, rankBtnSize.width - 20, -12,
            {ap = display.CENTER_BOTTOM})
    rankBtn:addChild(rankImg)

    --- 排行奖励相关UI
    ----------------------------------------------

    ----------------------------------------------
    --- 剧情奖励相关UI
    local plotRewardLayer = display.newLayer(270, 2,
    {
        ap = display.LEFT_BOTTOM,
        size = cc.size(864, 645),

        enable = true,
    })
    view:addChild(plotRewardLayer, 1)

    local plotRewardBg = display.newImageView(RES_DICT.WONDERLAND_POINT_BG, 875, 323,
    {
        ap = display.RIGHT_CENTER,
        scale9 = true, size = cc.size(1126, 666), capInsets = cc.rect(120, 120, 30, 30)
    })
    plotRewardLayer:addChild(plotRewardBg)

    -- 剧情普通奖励列表
    local listSize = cc.size(548, 486)
    local cellSize = cc.size(listSize.width, 112)
    local tableView = CTableView:create(listSize)
    tableView:setPosition(cc.p(20, 621))
    -- tableView:setBackgroundColor(cc.c3b(100,100,200))
    tableView:setAnchorPoint(display.LEFT_TOP)
    tableView:setDirection(eScrollViewDirectionVertical)
    tableView:setSizeOfCell(cellSize)
    plotRewardLayer:addChild(tableView)

    local cardBg = display.newNSprite(RES_DICT.WONDERLAND_POINT_BG_REWARD_CARD, 745, 323,
    {
        ap = display.CENTER,
    })
    plotRewardLayer:addChild(cardBg)

    ------------plotRareRewardLayer start------------
    local plotRareRewardLayerSize = cc.size(624, 116)
    local plotRareRewardLayer = display.newLayer(19, 13,
    {
        ap = display.LEFT_BOTTOM,
        size = plotRareRewardLayerSize,
        -- color = cc.c4b(0, 0, 0, 130)
    })
    plotRewardLayer:addChild(plotRareRewardLayer)

    local spBg = display.newNSprite(RES_DICT.WONDERLAND_POINT_LIST_BG_SP, 306, plotRareRewardLayerSize.height * 0.5,
    {
        ap = display.CENTER,
    })
    plotRareRewardLayer:addChild(spBg)

    local achieveLabel = display.newLabel(23, 90,
    {
        text = app.anniversary2019Mgr:GetPoText(__('达到')),
        ap = display.LEFT_CENTER,
        fontSize = 20,
        color = '#ffffff',
    })
    plotRareRewardLayer:addChild(achieveLabel)

    plotRareRewardLayer:addChild(display.newNSprite(RES_DICT.WONDERLAND_POINT_LIST_LINE, 23, 77,
    {
        ap = display.LEFT_CENTER,
    }))

    plotRareRewardLayer:addChild(display.newNSprite(RES_DICT.WONDERLAND_POINT_LIST_LABEL, 23, 55,
    {
        ap = display.LEFT_CENTER,
    }))

    local integralNumLabel = display.newLabel(27, 55,
    {
        ap = display.LEFT_CENTER,
        fontSize = 20,
        color = '#ffffff',
        outline = '#382323', outlineSize = 1,
        font = TTF_GAME_FONT, ttf = true,
    })
    plotRareRewardLayer:addChild(integralNumLabel)
    
    local pointIcon = display.newNSprite(CommonUtils.GetGoodsIconPathById(goodsId), 123, 56,
    {
        ap = display.LEFT_CENTER
    })
    pointIcon:setScale(0.2)
    plotRareRewardLayer:addChild(pointIcon)

    local canGetLabel = display.newLabel(23, 20,
    {
        text = __('可获得: '),
        ap = display.LEFT_CENTER,
        fontSize = 20,
        color = '#ffffff',
    })
    plotRareRewardLayer:addChild(canGetLabel)

    local rewardLayerSize = cc.size(286, 100)
    local rewardLayer = display.newLayer(180, plotRareRewardLayerSize.height / 2, {ap = display.LEFT_CENTER, size = rewardLayerSize})
    plotRareRewardLayer:addChild(rewardLayer)

    -- 稀有奖励领取按钮
    local btnParams = {
        ap = display.CENTER,
        scale9 = true, size = cc.size(123, 62),
        enable = true,
    }
    local drawBtn = require('common.CommonDrawButton').new({btnParams = btnParams})
    display.commonUIParams(drawBtn, {po = cc.p(542, 51), ap = display.CENTER})
    plotRareRewardLayer:addChild(drawBtn)

    -------------plotRareRewardLayer end-------------

    --- 剧情奖励相关UI
    ----------------------------------------------
   
    local collLabel = display.newLabel(781, 591,
    {
        ap = display.RIGHT_CENTER,
        fontSize = 20,
        color = '#ffcfa0',
    })
    plotRewardLayer:addChild(collLabel)

    local titleLine = display.newNSprite(RES_DICT.WONDERLAND_POINT_LINE_TITLE, 706, 574,
    {
        ap = display.CENTER,
    })
    plotRewardLayer:addChild(titleLine)

    -- 积分数量标签
    local numLabel = display.newLabel(746, 558,
    {
        ap = display.RIGHT_CENTER,
        fontSize = 20,
        color = '#ffffff',
        font = TTF_GAME_FONT, ttf = true,
    })
    plotRewardLayer:addChild(numLabel)
    
    
    local fragmentIcon = display.newNSprite(CommonUtils.GetGoodsIconPathById(goodsId), 766, 557,
    {
        ap = display.CENTER,
    })
    fragmentIcon:setScale(0.2, 0.2)
    plotRewardLayer:addChild(fragmentIcon)

    -- card preview btn
    local cardPreviewBtn = require("common.CardPreviewEntranceNode").new()
    display.commonUIParams(cardPreviewBtn, {ap = display.RIGHT_BOTTOM, po = cc.p(size.width - 10, 16)})
    view:addChild(cardPreviewBtn, 5)

    local cardPreviewTip = display.newImageView(RES_DICT.ANNI_REWARDS_LABEL_CARD_PREVIEW, -155, 8, {ap = display.RIGHT_CENTER})
    cardPreviewTip:setScaleX(-1)
    cardPreviewBtn:addChild(cardPreviewTip)
    
    cardPreviewBtn:addChild(display.newLabel(105, 8, fontWithColor(14, {ap = display.RIGHT_CENTER, text = app.anniversary2019Mgr:GetPoText(__('卡牌详情'))})))

    return {
        view                = view,
        -- rankBgLayer         = rankBgLayer,
        -- boardBg             = boardBg,
        rankRewardListView  = rankRewardListView,
        rankBtn             = rankBtn,
        plotRewardLayer     = plotRewardLayer,
        plotRewardBg        = plotRewardBg,
        tableView           = tableView,
        plotRareRewardLayer = plotRareRewardLayer,
        spBg                = spBg,
        pointIcon           = pointIcon,
        integralNumLabel    = integralNumLabel,
        rewardLayer         = rewardLayer,
        drawBtn             = drawBtn,
        collLabel           = collLabel,
        titleLine           = titleLine,
        fragmentIcon        = fragmentIcon,
        numLabel            = numLabel,
        cardPreviewBtn      = cardPreviewBtn,

        rewardNodes         = {},
    }

end

CreateCell_ = function (size)
    local cell = CTableViewCell:new()
    cell:setContentSize(size)

    cell:addChild(display.newNSprite(RES_DICT.WONDERLAND_POINT_LIST_BG_DEFAULT, size.width / 2, size.height / 2, {ap = display.CENTER}))

    cell:addChild(display.newLabel(16, 91, {text = app.anniversary2019Mgr:GetPoText(__('达到')), ap = display.LEFT_CENTER, fontSize = 20, color = '#ffffff'}))

    cell:addChild(display.newNSprite(RES_DICT.WONDERLAND_POINT_LIST_LINE, 90, 76, {ap = display.CENTER}))

    cell:addChild(display.newNSprite(RES_DICT.WONDERLAND_POINT_LIST_LABEL, 89, 55, {ap = display.CENTER}))

    local integralNumLabel = display.newLabel(18, 57,
    {
        text = 511,
        ap = display.LEFT_CENTER,
        fontSize = 20,
        color = '#ffffff',
        outline = '#382323', outlineSize = 1,
        font = TTF_GAME_FONT, ttf = true,
    })
    cell:addChild(integralNumLabel)

    local pointIcon = display.newNSprite('', 110, 58,
    {
        ap = display.LEFT_CENTER
    })
    pointIcon:setScale(0.2)
    cell:addChild(pointIcon)

    cell:addChild(display.newLabel(18, 25, {text = __('可获得: '), ap = display.LEFT_CENTER, fontSize = 20, color = '#ffffff'}))

    local rewardLayerSize = cc.size(226, 100)
    local rewardLayer = display.newLayer(160, size.height / 2, {ap = display.LEFT_CENTER, size = rewardLayerSize})
    cell:addChild(rewardLayer)

    local btnParams = {
        ap = display.CENTER,
        scale9 = true, size = cc.size(123, 62),
        enable = true,
    }
    local drawBtn = require('common.CommonDrawButton').new({btnParams = btnParams})
    display.commonUIParams(drawBtn, {po = cc.p(464, 57), ap = display.CENTER})
    cell:addChild(drawBtn)

    cell.viewData = {
        integralNumLabel = integralNumLabel,
        pointIcon        = pointIcon,
        rewardLayer      = rewardLayer,
        rewardNodes      = {},
        drawBtn          = drawBtn,
    }
    return cell
end

CreateGoodNode = function (reward)
    local goodNode = require('common.GoodNode').new({id = reward.goodsId, amount = reward.num, showAmount = true, callBack = function (sender)
        app.uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = sender.goodId, type = 1})
    end})
    goodNode:setScale(0.8)
    return goodNode
end

CreateBaseRewardsCell = function (data)
    local size = cc.size(244, 1)
    local cell = display.newLayer(0, 0, {size = size})

    local height = 8
    local line = display.newNSprite(RES_DICT.WONDERLAND_POINT_LINE_BOARD, size.width * 0.5, height,
    {
        ap = display.CENTER_BOTTOM,
    })
    cell:addChild(line)

    height = height + 8

    local rewards = data.rewards or {}
    local rewardCount = #rewards
    local rewardLayerSize = cc.size(size.width, 90 * math.ceil(rewardCount * 0.5))
    local rewardLayer = display.newLayer(size.width * 0.5, height, 
        {ap = display.CENTER_BOTTOM, size = rewardLayerSize})
    cell:addChild(rewardLayer)

    for i = 1, rewardCount do
        local reward = rewards[i]
        local goodNode = CreateGoodNode(reward)
        local pos = CommonUtils.getGoodPos({index = i, goodNodeSize = goodNode:getContentSize(), scale = goodNode:getScale(), midPointX = rewardLayerSize.width * 0.5, midPointY = rewardLayerSize.height - 45, col = 2, maxCol = 2, goodGap = 5})
        
        display.commonUIParams(goodNode, {po = pos, ap = display.CENTER})
        rewardLayer:addChild(goodNode)
    end

    height = height + rewardLayerSize.height + 8

    local descLabel = display.newLabel(10, height,
    {
        text = data.desc,
        ap = display.LEFT_BOTTOM,
        fontSize = 20,
        color = '#39431f',
        w = size.width - 20
    })
    cell:addChild(descLabel)

    size.height = height + display.getLabelContentSize(descLabel).height + 8
    cell:setContentSize(size)

    return cell
end

CreateAdvanceRewardsCell = function (data)
    local size = cc.size(244, 1)
    local middleX = size.width * 0.5
    local cell = display.newLayer(0, 0, {size = size})

    local height = 8
    local line = display.newNSprite(RES_DICT.WONDERLAND_POINT_LINE_BOARD, middleX, height,
    {
        ap = display.CENTER_BOTTOM,
    })
    cell:addChild(line)

    height = height + 8

    local rewards = data.rewards or {}
    local rewardCount = #rewards
    local singleRewardHeight = 175
    local rewardLayerSize = cc.size(size.width, singleRewardHeight * rewardCount)
    local rewardLayer = display.newLayer(size.width * 0.5, height, 
        {ap = display.CENTER_BOTTOM, size = rewardLayerSize})
    cell:addChild(rewardLayer)
    local startY = rewardLayerSize.height - singleRewardHeight * 0.5 + 25
    for i = 1, rewardCount do
        local reward = rewards[i]
        local goodsId = reward.goodsId
        -- 头像
        local headNode = require("root.CCHeaderNode").new({pre = goodsId, url = app.gameMgr:GetUserInfo().avatar, isPre = true, isSelf = false})
        local headNodeScale = 0.7
        headNode:setScale(headNodeScale)

        display.commonUIParams(headNode, {ap = display.CENTER, 
            po = cc.p(middleX, startY - (i - 1) * singleRewardHeight)})
        cell:addChild(headNode)

        local headNodeSize = headNode:getContentSize()
        local touchView = display.newLayer(headNodeSize.width * 0.5, headNodeSize.height * 0.5, {animate = false, ap = display.CENTER, enable = true, size = cc.size(140, 140), color = cc.c4b(0,0,0,0), cb = function (sender)
            app.uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = goodsId, type = 1})
        end})
        headNode:addChild(touchView,20)

        local goodsConf = CommonUtils.GetConfig('goods', 'goods', goodsId) or {}
        local headName = display.newLabel(middleX, headNode:getPositionY() - singleRewardHeight * 0.5 + 3, {text = tostring(goodsConf.name), fontSize = 20, color = '#eefdc3'})
        cell:addChild(headName)
    end

    height = height + rewardLayerSize.height + 8

    local descLabel = display.newLabel(10, height,
    {
        text = data.desc,
        ap = display.LEFT_BOTTOM,
        fontSize = 20,
        color = '#39431f',
        w = size.width - 20
    })
    cell:addChild(descLabel)

    size.height = height + display.getLabelContentSize(descLabel).height + 8
    cell:setContentSize(size)

    return cell
end

function Anniversary19PlotRewardView:CreateCell(size)
    return CreateCell_(size)
end

function Anniversary19PlotRewardView:GetViewData()
    return self.viewData
end

function Anniversary19PlotRewardView:CloseHandler()
    app:UnRegsitMediator(self.args.mediatorName)
end

return  Anniversary19PlotRewardView