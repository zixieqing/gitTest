--[[
 * author : liuzhipeng
 * descpt : 杀人案（19夏活）积分奖励View
--]]
local CommonDialog = require('common.CommonDialog')
local MurderPointRewardsView = class('MurderPointRewardsView', CommonDialog)

local RES_DICT = {
    COMMON_BTN_ORANGE               = app.murderMgr:GetResPath('ui/common/common_btn_orange.png'),
    CASTLE_BG_COMMON_BOARD          = app.murderMgr:GetResPath('ui/common/common_bg_4.png'),
    CASTLE_POINT_BG_BOARD           = app.murderMgr:GetResPath('ui/home/activity/murder/murder_point_bg_board.png'),
    CASTLE_POINT_BTN_PLAY_LOCK      = app.murderMgr:GetResPath('ui/home/activity/murder/murder_point_btn_play_lock.png'),
    CASTLE_POINT_LINE_TITLE         = app.murderMgr:GetResPath('ui/castle/plotReward/castle_point_line_title.png'),
    CASTLE_POINT_LIST_BG_SP         = app.murderMgr:GetResPath('ui/home/activity/murder/murder_point_list_bg_sp.png'),
    CASTLE_POINT_LIST_LABEL         = app.murderMgr:GetResPath('ui/home/activity/murder/murder_point_list_label.png'),
    CASTLE_POINT_LIST_LINE          = app.murderMgr:GetResPath('ui/home/activity/murder/murder_point_list_line.png'),
    CASTLE_POINT_LIST_BG_DEFAULT    = app.murderMgr:GetResPath('ui/home/activity/murder/murder_point_list_bg_default.png'),
    CASTLE_POINT_BG_CARD_200096     = app.murderMgr:GetResPath('ui/home/activity/murder/pointBg/murder_point_bg_card_200122.png'),
    CASTLE_POINT_BTN_PLAY_NEW       = app.murderMgr:GetResPath('ui/home/activity/murder/murder_point_btn_play_new.png'),
    CASTLE_POINT_BTN_PLAY_DEFAULT   = app.murderMgr:GetResPath('ui/home/activity/murder/murder_point_btn_play_default.png'),
    CASTLE_POINT_BG_PATH_LOCK       = app.murderMgr:GetResPath('ui/home/activity/murder/murder_point_bg_path_lock.png'),
    CASTLE_POINT_BG_PATH_DEFAULT    = app.murderMgr:GetResPath('ui/home/activity/murder/murder_point_bg_path_default.png'),
    CASTLE_POINT_LABEL_NUM_1        = app.murderMgr:GetResPath('ui/home/activity/murder/murder_point_label_num_1.png'),
    CASTLE_POINT_LABEL_NUM_2        = app.murderMgr:GetResPath('ui/home/activity/murder/murder_point_label_num_2.png'),
    MURDER_POINT_BG_GAINED          = app.murderMgr:GetResPath('ui/home/activity/murder/murder_point_label_gained.png'),
    MASK_BG                         = app.murderMgr:GetResPath('ui/home/activity/murder/murder_point_cover_lock.png'),
    
    ANNI_REWARDS_LABEL_CARD_PREVIEW = app.murderMgr:GetResPath('ui/anniversary/rewardPreview/anni_rewards_label_card_preview.png'),
    
}

local CreateView = nil
local CreateCell_ = nil
local CreateGoodNode = nil
local CreatePlotCell = nil

function MurderPointRewardsView:InitialUI( )
    
    xTry(function ( )
        self.viewData = CreateView()
        
        self:InitView()
	end, __G__TRACKBACK__)
end

function MurderPointRewardsView:InitView()
    -- self:InitPlotListView()
end

--==============================--
--desc: 初始化剧情列表
--@params datas    table   剧情数据列表
--==============================--
function MurderPointRewardsView:InitPlotListView(datas)
    local viewData = self:GetViewData()
    local plotListView = viewData.plotListView
    local listSize = plotListView:getContentSize()
    local plotLayer = display.newLayer(0,0,{size = listSize})
    
    local maxCount = #datas
    local width = listSize.width
    local middleWidth = width /  2
    local height = listSize.height
    local posY = height

    -- 时钟等级锁定
    local lockIndex = nil
    local maskLayerH = 50
    local clockLevel = app.murderMgr:GetClockLevel()
    for i, v in ipairs(datas) do
        if clockLevel < checkint(v.unlockClockLevel) then
            lockIndex = i
            break
        end
    end
    for i = 1, maxCount do
        
        local data = datas[i] or {}
        local targetGoodsId = data.targetGoodsId
        local targetNum = data.targetNum
        local storyId = data.storyId
        local plotUnlockState = data.state

        if i >= checkint(lockIndex) then
            maskLayerH = maskLayerH + 48
        end
        local singular = i % 2 ~= 0 and 1 or -1 
        posY = posY - 48
        local plotCell = CreatePlotCell(data)
        display.commonUIParams(plotCell, {po = cc.p(middleWidth + 70 * singular, posY), ap = display.CENTER})
        plotLayer:addChild(plotCell, 1)
        plotCell:setTag(i)
        
        if i ~= maxCount then
            if i >= checkint(lockIndex) then
                maskLayerH = maskLayerH + 33
            end
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

    -- maskLayer 用来屏蔽未解锁的剧情按钮的点击时间
    if lockIndex then
        local maskSize = cc.size(width, maskLayerH)
        local maskLayer = CColorView:create(cc.c4b(0, 0, 0, 0))
        maskLayer:setTouchEnabled(true)
        maskLayer:setContentSize(maskSize)
        maskLayer:setPosition(cc.p(middleWidth, 0))
        maskLayer:setAnchorPoint(display.CENTER_BOTTOM)
        plotLayer:addChild(maskLayer, 10)
        local maskBg = display.newImageView(RES_DICT.MASK_BG, middleWidth, 0, {scale9 = true, size = maskSize, capInsets = cc.rect(20, 20, 24, 24), ap = display.CENTER_BOTTOM})
        maskLayer:addChild(maskBg) 
        local icon = display.newImageView(app.murderMgr:GetResPath(string.format('ui/home/activity/murder/murder_chess_img_clock_%d.png', checkint(datas[lockIndex].unlockClockLevel))), middleWidth, maskSize.height - 80)
        icon:setScale(0.5)
        maskLayer:addChild(icon, 5)
        local unlockClockLevelPoint  = app.murderMgr:GetNumTimes(checkint(datas[lockIndex].unlockClockLevel) * 2)
        local unlockLabel = display.newLabel(20, maskSize.height - 140, {fontSize = 20, text = string.fmt(app.murderMgr:GetPoText(__('时针指向_num_点解锁')), {['_num_'] = unlockClockLevelPoint }), color = '#ffffff', w = 200, ap = display.LEFT_TOP, hAlign = cc.TEXT_ALIGNMENT_CENTER})
        maskLayer:addChild(unlockLabel, 5)
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
function MurderPointRewardsView:UpdatePlotListNodeByIndex(index, data)
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
function MurderPointRewardsView:UpdatePlotCell(plotCell, targetGoodsId, targetNum, plotUnlockState)
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
function MurderPointRewardsView:UpdateTableView(datas)
    local tableView = self:GetViewData().tableView
    tableView:setCountOfCell(#datas)
    tableView:reloadData()
end

--==============================--
--desc: 更新剧情奖励cell
--@params viewData      userdata 视图数据
--@params data          table     剧情奖励数据
--==============================--
function MurderPointRewardsView:UpdateCell(viewData, data)
    self:UpdateRewardCell_(viewData, data)
end

--==============================--
--desc: 更新剧情稀有奖励cell
--@params data          table     剧情稀有奖励数据
--==============================--
function MurderPointRewardsView:UpdateRareReward(data)
    local viewData = self:GetViewData()
    self:UpdateRewardCell_(viewData, data)

    local confData = data.confData or {}
    -- local cardPreviewBtn = viewData.cardPreviewBtn
    local rewards = confData.rewards or {}
    local confId = nil
    for i, v in ipairs(rewards) do
        if CommonUtils.GetGoodTypeById(v.goodsId) == GoodsType.TYPE_CARD then
            confId = v.goodsId
            break
        end
    end
    -- cardPreviewBtn:RefreshUI({confId = confId})
end

--==============================--
--desc: 更新剧情积分拥有数量
--@params curPoint        int     剧情积分拥有数量
--==============================--
function MurderPointRewardsView:UpdateNumLabel(curPoint)
    display.commonLabelParams(self:GetViewData().numLabel, {text = curPoint})
end

--==============================--
--desc: 更新剧情奖励cell
--@params viewData      userdata 视图数据
--@params data          table     剧情奖励数据
--==============================--
function MurderPointRewardsView:UpdateRewardCell_(viewData, data)
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
function MurderPointRewardsView:UpdateRewardLayer_(viewData, data)
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
function MurderPointRewardsView:GetPlotPathByState(plotUnlockState)
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
    local tipsLabel = display.newLabel(137, 34, {text = app.murderMgr:GetPoText(__('收集调查点数来解锁更多线索吧!')), fontSize = 20, color = '#ffffff', w = 245})
    plotBgLayer:addChild(tipsLabel, 5)
    -- local plotListView = CListView:create(cc.size(244, 482))
    -- plotListView:setPosition(cc.p(15, 126))
    local plotListView = CListView:create(cc.size(244, 510))
    plotListView:setPosition(cc.p(15, 100))
    plotListView:setAnchorPoint(display.LEFT_BOTTOM)
    plotListView:setDirection(eScrollViewDirectionVertical)
    plotBgLayer:addChild(plotListView)
    -- plotListView:setBackgroundColor(cc.c4b(64, 128, 255, 100))]

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
        scale9 = true, size = cc.size(1126, 635), capInsets = cc.rect(120, 120, 30, 30)
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
    plotRewardLayer:addChild(tableView, 5)

    local cardBg = display.newNSprite(RES_DICT.CASTLE_POINT_BG_CARD_200096, 763, 323,
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

    local spBg = display.newNSprite(RES_DICT.CASTLE_POINT_LIST_BG_SP, 310, plotRareRewardLayerSize.height / 2,
    {
        ap = display.CENTER,
    })
    plotRareRewardLayer:addChild(spBg)

    local achieveLabel = display.newLabel(23, 90,
    {
        text = app.murderMgr:GetPoText(__('达到')),
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

    local pointIcon = display.newNSprite(CommonUtils.GetGoodsIconPathById(app.murderMgr:GetPointGoodsId()), 123, 56,
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
    local collBg = display.newImageView(RES_DICT.MURDER_POINT_BG_GAINED,740, 612)
    plotRewardLayer:addChild(collBg)
    local collLabel = display.newLabel(810, 615,
    {
        text = app.murderMgr:GetPoText(__('已获得调查点数')),
        ap = display.RIGHT_CENTER,
        fontSize = 20,
        color = '#ffcfa0',
    })
    plotRewardLayer:addChild(collLabel)

    local titleLine = display.newNSprite(RES_DICT.CASTLE_POINT_LINE_TITLE, 740, 600,
    {
        ap = display.CENTER,
    })
    plotRewardLayer:addChild(titleLine)

    local numLabel = display.newLabel(766, 586,
    {
        ap = display.RIGHT_CENTER,
        fontSize = 20,
        color = '#ffffff',
        font = TTF_GAME_FONT, ttf = true,
    })
    plotRewardLayer:addChild(numLabel)

    local fragmentIcon = display.newNSprite(CommonUtils.GetGoodsIconPathById(app.murderMgr:GetPointGoodsId()), 786, 587,
    {
        ap = display.CENTER,
    })
    fragmentIcon:setScale(0.2, 0.2)
    plotRewardLayer:addChild(fragmentIcon)
    local cardId = 200110
    local skinData = app.murderMgr:GetChangeSkinData()
    local replaceImage = skinData.replaceImage
    if replaceImage and replaceImage.DETAIL_CARDID then
        cardId  = replaceImage.DETAIL_CARDID
    end
    -- card preview btn
    local cardPreviewBtn = require("common.CardPreviewEntranceNode").new({confId = cardId})
    display.commonUIParams(cardPreviewBtn, {ap = display.RIGHT_BOTTOM, po = cc.p(size.width - 10, 16)})
    view:addChild(cardPreviewBtn, 5)

    local cardPreviewTip = display.newImageView(RES_DICT.ANNI_REWARDS_LABEL_CARD_PREVIEW, -155, 8, {ap = display.RIGHT_CENTER})
    cardPreviewTip:setScaleX(-1)
    cardPreviewBtn:addChild(cardPreviewTip)
    
    cardPreviewBtn:addChild(display.newLabel(105, 8, fontWithColor(14, {ap = display.RIGHT_CENTER, text = app.murderMgr:GetPoText(__('卡牌详情'))})))

    return {
        view             = view,
        plotBgLayer             = plotBgLayer,
        boardBg                 = boardBg,
        plotListView            = plotListView,
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
        numLabel                = numLabel,
        -- cardPreviewBtn          = cardPreviewBtn,

        rewardNodes             = {},
    }

end

CreateCell_ = function (size)
    local cell = CTableViewCell:new()
    cell:setContentSize(size)

    cell:addChild(display.newNSprite(RES_DICT.CASTLE_POINT_LIST_BG_DEFAULT, size.width / 2, size.height / 2, {ap = display.CENTER}))

    cell:addChild(display.newLabel(16, 91, {text = app.murderMgr:GetPoText(__('达到')), ap = display.LEFT_CENTER, fontSize = 20, color = '#ffffff'}))

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

    local pointIcon = display.newNSprite(CommonUtils.GetGoodsIconPathById(app.murderMgr:GetPointGoodsId()), 110, 58,
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

function MurderPointRewardsView:CreateCell(size)
    return CreateCell_(size)
end

function MurderPointRewardsView:GetViewData()
    return self.viewData
end

function MurderPointRewardsView:CloseHandler()
    app:UnRegsitMediator(self.args.mediatorName)
end

return  MurderPointRewardsView