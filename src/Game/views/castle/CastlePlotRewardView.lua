local CommonDialog = require('common.CommonDialog')
local CastlePlotRewardView = class('CastlePlotRewardView', CommonDialog)

local RES_DICT = {
    GOODS_ICON_880164               = app.activityMgr:CastleResEx('arts/goods/goods_icon_880164.png'),
    COMMON_BTN_ORANGE               = app.activityMgr:CastleResEx('ui/common/common_btn_orange.png'),
    CASTLE_BG_COMMON_BOARD          = app.activityMgr:CastleResEx('ui/castle/common/castle_bg_common_board.png'),
    CASTLE_POINT_BG_BOARD           = app.activityMgr:CastleResEx('ui/castle/plotReward/castle_point_bg_board.png'),
    CASTLE_POINT_BTN_PLAY_LOCK      = app.activityMgr:CastleResEx('ui/castle/plotReward/castle_point_btn_play_lock.png'),
    CASTLE_POINT_BTN_STORY          = app.activityMgr:CastleResEx('ui/castle/plotReward/castle_point_btn_story.png'),
    CASTLE_POINT_LINE_TITLE         = app.activityMgr:CastleResEx('ui/castle/plotReward/castle_point_line_title.png'),
    CASTLE_POINT_LIST_BG_SP         = app.activityMgr:CastleResEx('ui/castle/plotReward/castle_point_list_bg_sp.png'),
    CASTLE_POINT_LIST_LABEL         = app.activityMgr:CastleResEx('ui/castle/plotReward/castle_point_list_label.png'),
    CASTLE_POINT_LIST_LINE          = app.activityMgr:CastleResEx('ui/castle/plotReward/castle_point_list_line.png'),
    CASTLE_POINT_LIST_BG_DEFAULT    = app.activityMgr:CastleResEx('ui/castle/plotReward/castle_point_list_bg_default.png'),
    CASTLE_POINT_BG_CARD_200096     = app.activityMgr:CastleResEx('ui/castle/plotReward/castle_point_bg_card.png'),
    CASTLE_POINT_BTN_PLAY_NEW       = app.activityMgr:CastleResEx('ui/castle/plotReward/castle_point_btn_play_new.png'),
    CASTLE_POINT_BTN_PLAY_DEFAULT   = app.activityMgr:CastleResEx('ui/castle/plotReward/castle_point_btn_play_default.png'),
    CASTLE_POINT_BG_PATH_LOCK       = app.activityMgr:CastleResEx('ui/castle/plotReward/castle_point_bg_path_lock.png'),
    CASTLE_POINT_BG_PATH_DEFAULT    = app.activityMgr:CastleResEx('ui/castle/plotReward/castle_point_bg_path_default.png'),
    CASTLE_POINT_LABEL_NUM_1        = app.activityMgr:CastleResEx('ui/castle/plotReward/castle_point_label_num_1.png'),
    CASTLE_POINT_LABEL_NUM_2        = app.activityMgr:CastleResEx('ui/castle/plotReward/castle_point_label_num_2.png'),
    ANNI_REWARDS_LABEL_CARD_PREVIEW = app.activityMgr:CastleResEx('ui/anniversary/rewardPreview/anni_rewards_label_card_preview.png'),
}

local CreateView = nil
local CreateCell_ = nil
local CreateGoodNode = nil
local CreatePlotCell = nil

function CastlePlotRewardView:InitialUI( )
    
    xTry(function ( )
        self.viewData = CreateView()
        self:InitView()
        self:UpdateFragmentIcon()
	end, __G__TRACKBACK__)
end

function CastlePlotRewardView:InitView()
    -- self:InitPlotListView()
end

--==============================--
--desc: 初始化剧情列表
--@params datas    table   剧情数据列表
--==============================--
function CastlePlotRewardView:InitPlotListView(datas)
    
    local viewData = self:GetViewData()
    local plotListView = viewData.plotListView
    local listSize = plotListView:getContentSize()
    local plotLayer = display.newLayer(0,0,{size = listSize})
    
    local maxCount = #datas
    local width = listSize.width
    local middleWidth = width /  2
    local height = listSize.height
    local posY = height

    for i = 1, maxCount do
        
        local data = datas[i] or {}
        local targetGoodsId = data.targetGoodsId
        local targetNum = data.targetNum
        local storyId = data.storyId
        local plotUnlockState = data.state

        local singular = i % 2 ~= 0 and 1 or -1 
        posY = posY - 48
        local plotCell = CreatePlotCell(data)
        display.commonUIParams(plotCell, {po = cc.p(middleWidth + 70 * singular, posY), ap = display.CENTER})
        plotLayer:addChild(plotCell, 1)
        plotCell:setTag(i)
        -- plotCell:setUserTag(plotUnlockState)
        
        if i ~= maxCount then
            posY = posY - 33
            local plotPath = display.newNSprite(self:GetPlotPathByState(plotUnlockState), middleWidth, posY, {ap = display.CENTER})
            plotPath:setScaleX(singular)
            plotLayer:addChild(plotPath)
            -- plotCell.viewData.plotPath = plotPath
        end
        
        self:UpdatePlotCell(plotCell, targetGoodsId, targetNum, plotUnlockState)
    end
    if posY < 0 then
        height = height - posY + 45
        plotLayer:setContentSize(cc.size(width, height))

        for i, node in ipairs(plotLayer:getChildren()) do
            node:setPositionY(node:getPositionY() - posY + 45)
        end
    end

    viewData.plotLayer = plotLayer
    plotLayer:setPositionY(-5)

    plotListView:insertNodeAtLast(plotLayer)
    plotListView:reloadData()

end

--==============================--
--desc: 通过列表界定啊下标更新剧情节点
--@params index    int   节点下标
--@params data     table 节点数据
--==============================--
function CastlePlotRewardView:UpdatePlotListNodeByIndex(index, data)
    local viewData = self:GetViewData()
    local node = viewData.plotLayer
    -- 所有的子节点都放到 plotLayer 中了  list 中只有一个node
    if node then
        local targetGoodsId = data.targetGoodsId
        local targetNum = data.targetNum
        local plotUnlockState = data.state
        local plotCell = node:getChildByTag(index)
        if plotCell then
            self:UpdatePlotCell(plotCell, targetGoodsId, targetNum, plotUnlockState)
        end
    end
end

--==============================--
--desc: 更新剧情列表cell
--@params plotCell      userdata   剧情列表cell
--@params targetGoodsId int        需求道具id
--@params targetNum     int        需求数量
--@params plotUnlockState         int        0 不满足条件 1 满足条件 2  满足条件并且是最新解锁剧情
--==============================--
function CastlePlotRewardView:UpdatePlotCell(plotCell, targetGoodsId, targetNum, plotUnlockState)
    local viewData      = plotCell.viewData
    local plotNumBg     = viewData.plotNumBg
    local plotStateIcon = viewData.plotStateIcon
    local goodsIcon     = viewData.goodsIcon

    if goodsIcon then goodsIcon:setVisible(false) end

    if plotUnlockState == 1 then
        plotStateIcon:setTexture(RES_DICT.CASTLE_POINT_BTN_PLAY_DEFAULT)
        plotNumBg:setNormalImage(RES_DICT.CASTLE_POINT_LABEL_NUM_1)
        plotNumBg:setSelectedImage(RES_DICT.CASTLE_POINT_LABEL_NUM_1)
        display.commonLabelParams(plotNumBg, {text = tostring(plotCell:getTag())})
        display.commonUIParams(plotNumBg:getLabel(), {ap = display.CENTER, po = cc.p(plotNumBg:getContentSize().width / 2, plotNumBg:getContentSize().height / 2)})
    elseif plotUnlockState == 2 then
        plotStateIcon:setTexture(RES_DICT.CASTLE_POINT_BTN_PLAY_NEW)
        plotNumBg:setNormalImage(RES_DICT.CASTLE_POINT_LABEL_NUM_1)
        plotNumBg:setSelectedImage(RES_DICT.CASTLE_POINT_LABEL_NUM_1)
        display.commonLabelParams(plotNumBg, {text = tostring(plotCell:getTag())})
        display.commonUIParams(plotNumBg:getLabel(), {ap = display.CENTER, po = cc.p(plotNumBg:getContentSize().width / 2, plotNumBg:getContentSize().height / 2)})
    else
        plotStateIcon:setTexture(RES_DICT.CASTLE_POINT_BTN_PLAY_LOCK)
        plotNumBg:setNormalImage(RES_DICT.CASTLE_POINT_LABEL_NUM_2)
        plotNumBg:setSelectedImage(RES_DICT.CASTLE_POINT_LABEL_NUM_2)

        if goodsIcon == nil then
            viewData.goodsIcon = display.newNSprite(CommonUtils.GetGoodsIconPathById(targetGoodsId), 0, 0, {ap = display.CENTER})
            viewData.goodsIcon:setScale(0.2)
            viewData.goodsIcon:setPosition(cc.p(72, 12))
            plotNumBg:addChild(viewData.goodsIcon)
        else
            goodsIcon:setVisible(true)
        end

        display.commonUIParams(plotNumBg:getLabel(), {ap = display.RIGHT_CENTER, po = cc.p(plotNumBg:getContentSize().width - 30, plotNumBg:getContentSize().height / 2)})
        display.commonLabelParams(plotNumBg, {text = tostring(targetNum)})
    end
    
end

--==============================--
--desc: 更新剧情奖励列表
--@params datas         table  剧情奖励数据列表
--==============================--
function CastlePlotRewardView:UpdateTableView(datas)
    local tableView = self:GetViewData().tableView
    tableView:setCountOfCell(#datas)
    tableView:reloadData()
end

--==============================--
--desc: 更新剧情奖励cell
--@params viewData      userdata 视图数据
--@params data          table     剧情奖励数据
--==============================--
function CastlePlotRewardView:UpdateCell(viewData, data)
    self:UpdateRewardCell_(viewData, data)
end

--==============================--
--desc: 更新剧情稀有奖励cell
--@params data          table     剧情稀有奖励数据
--==============================--
function CastlePlotRewardView:UpdateRareReward(data)
    local viewData = self:GetViewData()
    self:UpdateRewardCell_(viewData, data)

    local confData = data.confData or {}
    local cardPreviewBtn = viewData.cardPreviewBtn
    local rewards = confData.rewards or {}
    local confId = nil
    for i, v in ipairs(rewards) do
        if CommonUtils.GetGoodTypeById(v.goodsId) == GoodsType.TYPE_CARD then
            confId = v.goodsId
            break
        end
    end
    cardPreviewBtn:RefreshUI({confId = confId})
end

--==============================--
--desc: 更新剧情积分拥有数量
--@params curPoint        int     剧情积分拥有数量
--==============================--
function CastlePlotRewardView:UpdateNumLabel(curPoint)
    display.commonLabelParams(self:GetViewData().numLabel, {text = curPoint})
end

--==============================--
--desc: 更新剧情奖励cell
--@params viewData      userdata 视图数据
--@params data          table     剧情奖励数据
--==============================--
function CastlePlotRewardView:UpdateRewardCell_(viewData, data)
    viewData.pointIcon:setTexture(CommonUtils.GetGoodsIconPathById(data.consumeGoodsId))
    display.commonLabelParams(viewData.integralNumLabel, {text = tostring(data.consumeNum)})
    viewData.drawBtn:RefreshUI({drawState = data.state})
    self:UpdateRewardLayer_(viewData, data)
end

--==============================--
--desc: 更新奖励层
--@params viewData table 视图数据
--@params data     table cell数据
--==============================--
function CastlePlotRewardView:UpdateRewardLayer_(viewData, data)
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

--==============================--
--desc: 通过剧情解锁装填获得剧情图片路径
--@params plotUnlockState    int   0 不满足条件 1 满足条件 2  满足条件并且是最新解锁剧情
--==============================--
function CastlePlotRewardView:GetPlotPathByState(plotUnlockState)
    local img = nil
    if plotUnlockState > 0 then
        img = RES_DICT.CASTLE_POINT_BG_PATH_DEFAULT
    else
        img = RES_DICT.CASTLE_POINT_BG_PATH_LOCK
    end
    return img
end

CreateView = function ()
    local size = cc.size(1133, 648)
    local view = display.newLayer(0, 0, {size = size})

    -- ----------------plotBgLayer start-----------------
    local plotBgLayer = display.newLayer(274, 325,
    {
        ap = display.RIGHT_CENTER,
        size = cc.size(274, 650),
        enable = true,
    })
    view:addChild(plotBgLayer, 2)

    local boardBg = display.newNSprite(RES_DICT.CASTLE_POINT_BG_BOARD, 137, 323,
    {
        ap = display.CENTER,
    })
    plotBgLayer:addChild(boardBg)

    -- local plotListView = CListView:create(cc.size(244, 482))
    -- plotListView:setPosition(cc.p(15, 126))
    local plotListView = CListView:create(cc.size(244, 510))
    plotListView:setPosition(cc.p(15, 100))
    plotListView:setAnchorPoint(display.LEFT_BOTTOM)
    plotListView:setDirection(eScrollViewDirectionVertical)
    plotBgLayer:addChild(plotListView)
    -- plotListView:setBackgroundColor(cc.c4b(64, 128, 255, 100))]

    local lookPlotBtn = display.newButton(137, 46,
    {
        ap = display.CENTER,
        n = RES_DICT.CASTLE_POINT_BTN_STORY,
        scale9 = true, size = cc.size(227, 56),
        enable = true,
    })
    display.commonLabelParams(lookPlotBtn, fontWithColor(14, {text = app.activityMgr:GetCastleText(__('查看所有剧情'))}))
    plotBgLayer:addChild(lookPlotBtn)

    -----------------plotBgLayer end------------------
    --------------plotRewardLayer start---------------
    local plotRewardLayer = display.newLayer(270, 2,
    {
        ap = display.LEFT_BOTTOM,
        size = cc.size(864, 645),
        enable = true,
    })
    view:addChild(plotRewardLayer, 1)

    local plotRewardBg = display.newImageView(RES_DICT.CASTLE_BG_COMMON_BOARD, 875, 323,
    {
        ap = display.RIGHT_CENTER,
        scale9 = true, size = cc.size(1126, 666), capInsets = cc.rect(120, 120, 30, 30)
    })
    plotRewardLayer:addChild(plotRewardBg)

    local listSize = cc.size(548, 486)
    local cellSize = cc.size(listSize.width, 112)
    local tableView = CTableView:create(listSize)
    tableView:setPosition(cc.p(20, 621))
    -- tableView:setBackgroundColor(cc.c3b(100,100,200))
    tableView:setAnchorPoint(display.LEFT_TOP)
    tableView:setDirection(eScrollViewDirectionVertical)
    tableView:setSizeOfCell(cellSize)
    plotRewardLayer:addChild(tableView)

    local cardBg = display.newNSprite(RES_DICT.CASTLE_POINT_BG_CARD_200096, 745, 323,
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
    })
    plotRewardLayer:addChild(plotRareRewardLayer)

    local spBg = display.newNSprite(RES_DICT.CASTLE_POINT_LIST_BG_SP, 280, plotRareRewardLayerSize.height / 2 + 50,
    {
        ap = display.CENTER,
    })
    plotRareRewardLayer:addChild(spBg)

    local achieveLabel = display.newLabel(23, 90,
    {
        text = app.activityMgr:GetCastleText(__('达到')),
        ap = display.LEFT_CENTER,
        fontSize = 20,
        color = '#ffffff',
    })
    plotRareRewardLayer:addChild(achieveLabel)

    plotRareRewardLayer:addChild(display.newNSprite(RES_DICT.CASTLE_POINT_LIST_LINE, 23, 77,
    {
        ap = display.LEFT_CENTER,
    }))

    plotRareRewardLayer:addChild(display.newNSprite(RES_DICT.CASTLE_POINT_LIST_LABEL, 23, 55,
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

    local pointIcon = display.newNSprite(RES_DICT.GOODS_ICON_880164, 123, 56,
    {
        ap = display.LEFT_CENTER
    })
    pointIcon:setScale(0.2)
    plotRareRewardLayer:addChild(pointIcon)

    local canGetLabel = display.newLabel(23, 20,
    {
        text = app.activityMgr:GetCastleText(__('可获得: ')),
        ap = display.LEFT_CENTER,
        fontSize = 20,
        color = '#ffffff',
    })
    plotRareRewardLayer:addChild(canGetLabel)

    local rewardLayerSize = cc.size(286, 100)
    local rewardLayer = display.newLayer(180, plotRareRewardLayerSize.height / 2, {ap = display.LEFT_CENTER, size = rewardLayerSize})
    plotRareRewardLayer:addChild(rewardLayer)

    local btnParams = {
        ap = display.CENTER,
        scale9 = true, size = cc.size(123, 62),
        enable = true,
    }
    local drawBtn = require('common.CommonDrawButton').new({btnParams = btnParams})
    display.commonUIParams(drawBtn, {po = cc.p(542, 51), ap = display.CENTER})
    plotRareRewardLayer:addChild(drawBtn)

    -------------plotRareRewardLayer end-------------
    ---------------plotRewardLayer end----------------
   
    local collLabel = display.newLabel(781, 591,
    {
        text = app.activityMgr:GetCastleText(__('已收集记忆碎片')),
        ap = display.RIGHT_CENTER,
        fontSize = 20,
        color = '#ffcfa0',
    })
    plotRewardLayer:addChild(collLabel)

    local titleLine = display.newNSprite(RES_DICT.CASTLE_POINT_LINE_TITLE, 706, 574,
    {
        ap = display.CENTER,
    })
    plotRewardLayer:addChild(titleLine)

    local numLabel = display.newLabel(746, 558,
    {
        ap = display.RIGHT_CENTER,
        fontSize = 20,
        color = '#ffffff',
        font = TTF_GAME_FONT, ttf = true,
    })
    plotRewardLayer:addChild(numLabel)

    local fragmentIcon = display.newNSprite(RES_DICT.GOODS_ICON_880164, 766, 557,
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
    
    cardPreviewBtn:addChild(display.newLabel(105, 8, fontWithColor(14, {ap = display.RIGHT_CENTER, text = app.activityMgr:GetCastleText(__('卡牌详情'))})))

    return {
        view             = view,
        plotBgLayer             = plotBgLayer,
        boardBg                 = boardBg,
        plotListView            = plotListView,
        lookPlotBtn             = lookPlotBtn,
        plotRewardLayer         = plotRewardLayer,
        plotRewardBg            = plotRewardBg,
        tableView               = tableView,
        plotRareRewardLayer     = plotRareRewardLayer,
        spBg                    = spBg,
        pointIcon               = pointIcon,
        integralNumLabel        = integralNumLabel,
        rewardLayer             = rewardLayer,
        drawBtn                 = drawBtn,
        collLabel               = collLabel,
        titleLine               = titleLine,
        fragmentIcon            = fragmentIcon ,
        numLabel                = numLabel,
        cardPreviewBtn          = cardPreviewBtn,

        rewardNodes             = {},
    }

end

CreateCell_ = function (size)
    local cell = CTableViewCell:new()
    cell:setContentSize(size)

    cell:addChild(display.newNSprite(RES_DICT.CASTLE_POINT_LIST_BG_DEFAULT, size.width / 2, size.height / 2, {ap = display.CENTER}))

    cell:addChild(display.newLabel(16, 91, {text = app.activityMgr:GetCastleText(__('达到')), ap = display.LEFT_CENTER, fontSize = 20, color = '#ffffff'}))

    cell:addChild(display.newNSprite(RES_DICT.CASTLE_POINT_LIST_LINE, 90, 76, {ap = display.CENTER}))

    cell:addChild(display.newNSprite(RES_DICT.CASTLE_POINT_LIST_LABEL, 89, 55, {ap = display.CENTER}))

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

    local pointIcon = display.newNSprite(RES_DICT.GOODS_ICON_880164, 110, 58,
    {
        ap = display.LEFT_CENTER
    })
    pointIcon:setScale(0.2)
    cell:addChild(pointIcon)

    cell:addChild(display.newLabel(18, 25, {text = app.activityMgr:GetCastleText(__('可获得: ')), ap = display.LEFT_CENTER, fontSize = 20, color = '#ffffff'}))

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

CreatePlotCell = function (data)
    
    local plotCellSize = cc.size(73, 91)
    local plotCell = display.newLayer(0, 0, {color = cc.c4b(0,0,0,0), enable = true, size = plotCellSize})
    
    local plotStateIcon = display.newNSprite(RES_DICT.CASTLE_POINT_BTN_PLAY_LOCK, plotCellSize.width / 2, 61,
    {
        ap = display.CENTER,
    })
    plotCell:addChild(plotStateIcon)

    local plotNumBg = display.newButton(plotCellSize.width / 2, 3, {ap = display.CENTER_BOTTOM, n = RES_DICT.CASTLE_POINT_LABEL_NUM_2})
    display.commonLabelParams(plotNumBg, fontWithColor(18))
    plotCell:addChild(plotNumBg)
    
    plotCell.viewData = {
        plotStateIcon  = plotStateIcon,
        plotNumBg = plotNumBg,
    }

    return plotCell
end

function CastlePlotRewardView:CreateCell(size)
    return CreateCell_(size)
end

function CastlePlotRewardView:GetViewData()
    return self.viewData
end
function CastlePlotRewardView:UpdateFragmentIcon()
    ---@type SpringActivityConfigParser
    local SpringActivityConfigParser = require('Game.Datas.Parser.SpringActivityConfigParser').new()
    local goodsPointMainShowConfig = CommonUtils.GetConfigAllMess(SpringActivityConfigParser.TYPE.GOODS_POINT_MAIN_SHOW , "springActivity")
    local goodsId  = DIAMOND_ID
    local totalValue = 100
    for key , goodsData  in pairs(goodsPointMainShowConfig) do
        totalValue = checkint(goodsData.limit)
        goodsId = goodsData.goodsId
        break
    end
    local goodsPath = CommonUtils.GetGoodsIconPathById(goodsId)
    self.viewData.fragmentIcon:setTexture(goodsPath)
end
function CastlePlotRewardView:CloseHandler()
    app:UnRegsitMediator(self.args.mediatorName)
end

return  CastlePlotRewardView
