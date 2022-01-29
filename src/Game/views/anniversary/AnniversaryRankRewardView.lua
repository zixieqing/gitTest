local VIEW_SIZE = cc.size(1000, 640)
local AnniversaryRankRewardView = class('common.AnniversaryRankRewardView', function ()
	local node = CLayout:create(VIEW_SIZE)
	node.name = 'Game.views.anniversary.AnniversaryRankRewardView'
	node:enableNodeEvents()
	return node
end)

local RES_DICT = {
    COMMON_BTN_TIPS                 = app.anniversaryMgr:GetResPath('ui/common/common_btn_tips.png'),
    TUJIAN_SELECTION_LINE           = app.anniversaryMgr:GetResPath('ui/common/tujian_selection_line.png'),
    TUJIAN_SELECTION_SELECT_BTN_FILTER_SELECTED = app.anniversaryMgr:GetResPath('ui/common/tujian_selection_select_btn_filter_selected_2.png'),
    CELL_SELECT                     = app.anniversaryMgr:GetResPath('ui/mail/common_bg_list_selected.png'),
    ANNI_ICO_POINT                  = app.anniversaryMgr:GetResPath('ui/anniversary/rewardPreview/anni_ico_point.png'),
    ANNI_REWARDS_BG_LIST_2          = app.anniversaryMgr:GetResPath('ui/anniversary/rewardPreview/anni_rewards_bg_list_2.png'),
    ANNI_REWARDS_BG_LIST_1        = app.anniversaryMgr:GetResPath('ui/anniversary/rewardPreview/anni_rewards_bg_list_1.png'),
    ANNI_REWARDS_BG_RANK            = app.anniversaryMgr:GetResPath('ui/anniversary/rewardPreview/anni_rewards_bg_rank.png'),
    ANNI_REWARDS_LABEL_RANK         = app.anniversaryMgr:GetResPath('ui/anniversary/rewardPreview/anni_rewards_label_rank.png'),
    ANNI_REWARDS_LINE_3             = app.anniversaryMgr:GetResPath('ui/anniversary/rewardPreview/anni_rewards_line_3.png'),
    ANNI_REWARDS_BG_LIST            = app.anniversaryMgr:GetResPath('ui/anniversary/rewardPreview/anni_rewards_bg_list.png'),
    ANNI_REWARDS_LABEL_PRESENT      = app.anniversaryMgr:GetResPath('ui/anniversary/rewardPreview/anni_rewards_label_present.png'),
    ANNI_REWARDS_BG_200115          = app.anniversaryMgr:GetResPath('ui/anniversary/rewardPreview/anni_rewards_bg_200115.png'),
}

local RANK_TAGS = {
    DAILY_OPERATE = 200,
    TOTAL_OPERATE = 201,
    INTEGRAL      = 202,
}

local REWARD_BG_CONF = {
    [RANK_TAGS.DAILY_OPERATE] = RES_DICT.ANNI_REWARDS_BG_LIST_2,
    [RANK_TAGS.TOTAL_OPERATE] = RES_DICT.ANNI_REWARDS_BG_LIST_2,
    [RANK_TAGS.INTEGRAL]      = RES_DICT.ANNI_REWARDS_BG_LIST_1,
}


local CreateView = nil
local CreateRankTabCell = nil
local CreateCell_ = nil
local CreateGoodNode = nil

function AnniversaryRankRewardView:ctor( ... )
    self.args = unpack({...}) or {}
    xTry(function ( )
        self.viewData = CreateView(VIEW_SIZE, self.args.tabConfs or {})
        self:addChild(self.viewData.view)
	end, __G__TRACKBACK__)
end

function AnniversaryRankRewardView:updateUI(data, tag)
    local viewData = self:getViewData()

    local rankList = data.rankList or {}
    local tableView = viewData.tableView
    tableView:setCountOfCell(#rankList)
    tableView:reloadData()

    -- todo update icon
    local integralIcon = viewData.integralIcon

    local integralLabel  = viewData.integralLabel
    local score          = checkint(data.score)
    display.commonLabelParams(integralLabel, {text = score})

    local rankLabel      = viewData.rankLabel
    local rank           = checkint(data.rank)
    local rankText = rank == 0 and app.anniversaryMgr:GetPoText(__('未入榜')) or rank
    display.commonLabelParams(rankLabel, {text = rankText})

    self:updateIntergralInfo(viewData, tag)
    self:updateRewardBg(viewData, tag)
end

function AnniversaryRankRewardView:updateTabCellShowState(tabCell, isShow)
    local selectImg = tabCell:getChildByName('selectImg')
    if  selectImg then
        selectImg:setVisible(isShow)
    end
end

function AnniversaryRankRewardView:updateCell(viewData, data, rangeId)
    
    local confData      = data.confData or {}
    
    local titleLabel    = viewData.titleLabel
    display.commonLabelParams(titleLabel, {text = tostring(confData.name)})

    self:updateRewardLayer(viewData, data)

    self:updateSelectState(viewData, rangeId == checkint(confData.id))

end

function AnniversaryRankRewardView:updateIntergralInfo(viewData, tag)
    local GOOD_ICON_CONF = {
        [RANK_TAGS.DAILY_OPERATE] = {iconPath = CommonUtils.GetGoodsIconPathById(app.anniversaryMgr:GetIncomeCurrencyID()), text = app.anniversaryMgr:GetPoText(__('今日庆典代币'))},
        [RANK_TAGS.TOTAL_OPERATE] = {iconPath = CommonUtils.GetGoodsIconPathById(app.anniversaryMgr:GetIncomeCurrencyID()), text = app.anniversaryMgr:GetPoText(__('庆典代币'))},
        [RANK_TAGS.INTEGRAL]      = {iconPath = RES_DICT.ANNI_ICO_POINT, text = app.anniversaryMgr:GetPoText(__('庆典积分'))},
    }
    local integralIcon         = viewData.integralIcon
    local integralTipLabel     = viewData.integralTipLabel
    
    local conf = GOOD_ICON_CONF[tag] or {}
    integralIcon:setTexture(conf.iconPath)
    display.commonLabelParams(integralTipLabel, {text = tostring(conf.text)})
end

function AnniversaryRankRewardView:updateRewardBg(viewData, tag)
    local rewardBg = viewData.rewardBg
    rewardBg:setVisible(true)
    rewardBg:setTexture(REWARD_BG_CONF[tag])
end

function AnniversaryRankRewardView:updateRewardLayer(viewData, data)
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
            local params = {index = i, goodNodeSize = rewardNode:getContentSize(), midPointX = rewardLayerSize.width / 2, midPointY = rewardLayerSize.height / 2, col = rewardCount, maxCol = 5, scale = 0.8, goodGap = 10}
            local pos = CommonUtils.getGoodPos(params)
            display.commonUIParams(rewardNode, {po = pos})
        elseif rewardNode then
            rewardNode:setVisible(false)
        end
    end
end

function AnniversaryRankRewardView:updateSelectState(viewData, isSelect)
    local cellSelectImg = viewData.cellSelectImg
    local tipsBg        = viewData.tipsBg
    cellSelectImg:setVisible(isSelect)
    tipsBg:setVisible(isSelect)
end


function AnniversaryRankRewardView:getViewData()
    return self.viewData
end

function AnniversaryRankRewardView:CreateCell(size)
    return CreateCell_(size)
end

CreateView = function (size, tabConfs)
    local view  = display.newLayer(size.width / 2, size.height / 2, {ap = display.CENTER, size = size})

    local rewardBg = display.newNSprite(RES_DICT.ANNI_REWARDS_BG_200129, 30, 586, {ap = display.LEFT_TOP})
    view:addChild(rewardBg)
    rewardBg:setVisible(false)

    local listSize = cc.size(504, 524)
    local listCellSize = cc.size(listSize.width, 148)
    local tableView = CTableView:create(listSize)
    display.commonUIParams(tableView, {po = cc.p(561, 276), ap = display.CENTER})
    tableView:setDirection(eScrollViewDirectionVertical)
    -- tableView:setBackgroundColor(cc.c4b(23, 67, 128, 128))
    tableView:setSizeOfCell(listCellSize)
    view:addChild(tableView)

    view:addChild(display.newNSprite(RES_DICT.ANNI_REWARDS_BG_RANK, 140, 522, {ap = display.CENTER}))

    local integralTipBg = display.newNSprite(RES_DICT.ANNI_REWARDS_LABEL_RANK, 37, 563, {ap = display.LEFT_CENTER})
    view:addChild(integralTipBg)

    local integralIcon = display.newNSprite(RES_DICT.ANNI_ICO_POINT, 0, 14, {ap = display.LEFT_CENTER,})
    integralIcon:setScale(0.2)
    integralTipBg:addChild(integralIcon)

    local integralTipLabel= display.newLabel(33, 12,
    {
        ap = display.LEFT_CENTER,
        fontSize = 20,
        color = '#fee1b3',
    })
    integralTipBg:addChild(integralTipLabel)

    local integralLabel = display.newLabel(68, 533,
    {
        ap = display.LEFT_CENTER,
        fontSize = 20,
        color = '#ffffff',
    })
    view:addChild(integralLabel)

    local rankTipBg = display.newNSprite(RES_DICT.ANNI_REWARDS_LABEL_RANK, 33, 507,
    {
        ap = display.LEFT_CENTER,
    })
    view:addChild(rankTipBg)

    rankTipBg:addChild(display.newLabel(33, 12,
    {
        text = app.anniversaryMgr:GetPoText(__('当前排名')),
        ap = display.LEFT_CENTER,
        fontSize = 20,
        color = '#fee1b3',
    }))

    local rankLabel = display.newLabel(68, 480,
    {
        ap = display.LEFT_CENTER,
        fontSize = 20,
        color = '#ffffff',
    })
    view:addChild(rankLabel)

    local ruleBtn = display.newButton(792, 561, {n = RES_DICT.COMMON_BTN_TIPS, ap = display.CENTER})
    view:addChild(ruleBtn)

    view:addChild(display.newLabel(773, 559,
    {
        text = app.anniversaryMgr:GetPoText(__('排名规则')),
        ap = display.RIGHT_CENTER,
        fontSize = 20,
        color = '#967541',
    }))

    view:addChild(display.newNSprite(RES_DICT.ANNI_REWARDS_LINE_3, 815, 295, {ap = display.CENTER}))

    view:addChild(display.newNSprite(RES_DICT.TUJIAN_SELECTION_LINE, 897, 387, {ap = display.CENTER}))

    local tabCells = {}
    for i, v in ipairs(tabConfs) do
        local tabCell = CreateRankTabCell(v.name)
        display.commonUIParams(tabCell, {po = cc.p(897, 357 - (i - 1) * 75)})
        view:addChild(tabCell)

        view:addChild(display.newNSprite(RES_DICT.TUJIAN_SELECTION_LINE, tabCell:getPositionX(), tabCell:getPositionY() - 38, {ap = display.CENTER}))

        tabCells[tostring(v.tag)] = tabCell
    end
    
    return {
        view                 = view,
        rewardBg             = rewardBg,
        tableView            = tableView,
        integralIcon         = integralIcon,
        integralTipLabel     = integralTipLabel,
        integralLabel        = integralLabel,
        rankLabel            = rankLabel,
        ruleBtn              = ruleBtn,
        tabCells             = tabCells,
    }
end

CreateRankTabCell = function (text)
    local layerSize = cc.size(140, 75)
    local layer = display.newLayer(0, 0, {ap = display.CENTER, color = cc.c4b(0, 0, 0, 0), enable = true, size = layerSize})

    local selectImg = display.newNSprite(RES_DICT.TUJIAN_SELECTION_SELECT_BTN_FILTER_SELECTED, layerSize.width / 2, layerSize.height / 2, {ap = display.CENTER , scale9 = true , size = layerSize})
    selectImg:setName('selectImg')
    layer:addChild(selectImg)
    selectImg:setVisible(false)
    layer:addChild(display.newLabel(layerSize.width / 2, layerSize.height / 2,
    {
        w = 130 , hAlign = display.TAC ,
        text = text,
        ap = display.CENTER,
        fontSize = 20,
        color = '#ad8136',
    }))

    return layer
end

CreateCell_ = function (size)
    local cell = CTableViewCell:new()
    cell:setContentSize(size)

    local bg = display.newNSprite(RES_DICT.ANNI_REWARDS_BG_LIST, 242, 75,
    {
        ap = display.CENTER,
    })
    cell:addChild(bg)

    local titleLabel = display.newLabel(243, 122,
    {
        ap = display.CENTER,
        fontSize = 20,
        color = '#aa7522',
    })
    cell:addChild(titleLabel)

    local rewardLayer = display.newLayer(242, 59,
    {
        ap = display.CENTER,
        size = cc.size(460, 100),
    })
    cell:addChild(rewardLayer)

    local cellSelectImg = display.newImageView(RES_DICT.CELL_SELECT, size.width / 2 - 2, size.height / 2, {ap = display.CENTER, scale9 = true, size = cc.size(size.width - 26, 145)})
    cell:addChild(cellSelectImg)
    cellSelectImg:setVisible(false)
    
    local tipsBg = display.newNSprite(RES_DICT.ANNI_REWARDS_LABEL_PRESENT, 507, 124.5,
    {
        ap = display.RIGHT_CENTER,
    })
    cell:addChild(tipsBg)
    tipsBg:setVisible(false)

    tipsBg:addChild(display.newLabel(60, 15,
    {
        text = app.anniversaryMgr:GetPoText(__('当前')),
        ap = display.CENTER,
        fontSize = 20,
        color = '#ffffff',
    }))

    cell.viewData = {
        titleLabel    = titleLabel,
        rewardLayer   = rewardLayer,
        cellSelectImg = cellSelectImg,
        tipsBg        = tipsBg,
        rewardNodes   = {},
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

return  AnniversaryRankRewardView