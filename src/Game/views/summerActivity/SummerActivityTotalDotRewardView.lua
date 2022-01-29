local VIEW_SIZE = cc.size(950, 590)
local SummerActivityTotalDotRewardView = class('SummerActivityTotalDotRewardView', function ()
	local node = CLayout:create(VIEW_SIZE)
	node.name = 'Game.views.summerActivity.SummerActivityTotalDotRewardView'
	node:enableNodeEvents()
	return node
end)

local RES_DIR_ = {
    BTN_RANK      = _res('ui/home/nmain/main_btn_rank.png'),
    -- SUMMER_ACTIVITY_RANK_BG_CARD       = _res('ui/home/activity/summerActivity/entrance/summer_activity_rank_bg_card.png'),
    SUMMER_ACTIVITY_RANK_BG_CARD_2       = _res('ui/home/activity/summerActivity/entrance/summer_activity_rank_bg_card_2.png'),
    SUMMER_ACTIVITY_ENTRANCE_LABEL_1   = _res("ui/home/activity/summerActivity/entrance/summer_activity_entrance_label_1.png"),

    SUMMER_ACTIVITY_ICO_POINT          = _res('ui/home/activity/summerActivity/entrance/summer_activity_ico_point.png'),
}
local RES_DIR = {}

local CreateView = nil
local CreateCell_ = nil

local summerActMgr = app.summerActMgr

function SummerActivityTotalDotRewardView:ctor( ... )
    RES_DIR = summerActMgr:resetResPath(RES_DIR_)

    self.args = unpack({...})
    self:initialUI()
end

function SummerActivityTotalDotRewardView:initialUI()
    xTry(function ( )
        self.viewData = CreateView(VIEW_SIZE)
        self:addChild(self.viewData.view)
        display.commonUIParams(self.viewData.view, {ap = display.CENTER, po = cc.p(VIEW_SIZE.width / 2, VIEW_SIZE.height / 2)})
        self:initView()
	end, __G__TRACKBACK__)
end

function SummerActivityTotalDotRewardView:initView()
    
end

function SummerActivityTotalDotRewardView:refreshUI(data)
    
end

function SummerActivityTotalDotRewardView:updateUI(data)
    
end

function SummerActivityTotalDotRewardView:updateCell(viewData, data)
    -- logInfo.add(5, 'updateCell -- >>>')
    local rankRewardCell = viewData.rankRewardCell
    local rankRewardText = nil
    local isMinStage = data.isMinStage
    if isMinStage then
        rankRewardText = summerActMgr:getThemeTextByText(__('参与奖'))
    end
    rankRewardCell:refreshUI(data.pointRankConfData, 1, data.isCurRank, rankRewardText)

    local lowerLimit       = checkint(data.lowerLimit)
    local lowerLimitRankLv = checkint(data.lowerLimitRankLv)
    local lowerLimitValue  = checkint(data.lowerLimitValue)
    local dotIcon          = viewData.dotIcon
    local curDotLabel      = viewData.curDotLabel
    
    local isShow = lowerLimit ~= 0 and lowerLimitValue ~= 0 and not isMinStage
    dotIcon:setVisible(isShow)
    curDotLabel:setVisible(isShow)

    if isShow then
        display.commonLabelParams(curDotLabel, {text = string.format(summerActMgr:getThemeTextByText(__("第%s名当前点数: %s")), tostring(lowerLimitRankLv), tostring(lowerLimitValue))})
        local curDotLabelSize = display.getLabelContentSize(curDotLabel)

        local dotIconSize = cc.size(dotIcon:getContentSize().width * dotIcon:getScale(),dotIcon:getContentSize().height * dotIcon:getScale())
        
        dotIcon:setPositionX(249 + curDotLabelSize.width / 2)
        curDotLabel:setPositionX(249 - dotIconSize.width / 2)
    end
end

CreateView = function (size)
    local view = display.newLayer(0, 0, {size = size})

    view:addChild(display.newImageView(RES_DIR.SUMMER_ACTIVITY_RANK_BG_CARD_2, 100, size.height / 2 + 10, {ap = display.CENTER}))

    local gridViewSize = cc.size(505, size.height - 20)
    local gridViewCellSize = cc.size(gridViewSize.width, 160)
    local gridView = CGridView:create(gridViewSize)
    gridView:setPosition(cc.p(size.width / 2 + 46, size.height / 2))
    -- gridView:setBackgroundColor(cc.c3b(100,100,200))
    gridView:setAnchorPoint(display.CENTER)
    gridView:setSizeOfCell(gridViewCellSize)
    gridView:setColumns(1)
    view:addChild(gridView)

    local rankBtn = nil
    --  排行榜
    if CommonUtils.GetModuleAvailable(MODULE_SWITCH.RANKING) then
        rankBtn = display.newButton(size.width - 70, size.height - 50, {n = RES_DIR.BTN_RANK, ap = display.CENTER})
		display.commonLabelParams(rankBtn, fontWithColor(14, {outline = '#491d1d', outlineSize = 2, fontSize = 22, text = summerActMgr:getThemeTextByText(__('排行榜')), offset = cc.p(0, -38)}))
        view:addChild(rankBtn)
    end

    local curRankBgSize = cc.size(150, 29)
    local curRankBg = display.newImageView(RES_DIR.SUMMER_ACTIVITY_ENTRANCE_LABEL_1, size.width - 4, size.height - 126 + 15, {scale9 = true, size = curRankBgSize, ap = display.RIGHT_TOP})
    view:addChild(curRankBg)
    
    local curRankLabel = display.newLabel(150, 14.5, fontWithColor(5, {w = 130, fontSize = 20, text = summerActMgr:getThemeTextByText(__('当前排名')), color = '#ffffff', ap = display.RIGHT_CENTER}))
    curRankBg:addChild(curRankLabel)

    local curRankLabelSize = display.getLabelContentSize(curRankLabel)
    if (curRankLabelSize.height - 15) > curRankBgSize.height then
        curRankBgSize = cc.size(curRankBgSize.width, curRankLabelSize.height + 5)
        curRankBg:setContentSize(curRankBgSize)
        display.commonUIParams(curRankLabel, {po = cc.p(curRankLabel:getPositionX(), curRankBgSize.height / 2)})
    end
    
    local rankLabel = display.newLabel(size.width - 20, curRankBg:getPositionY() - curRankBgSize.height - 20, fontWithColor(5, {text = '---', fontSize = 20, color = '#bc8f43', ap = display.RIGHT_CENTER}))
    view:addChild(rankLabel)

    local curDotBgSize = cc.size(150, 29)
    local curDotBg = display.newImageView(RES_DIR.SUMMER_ACTIVITY_ENTRANCE_LABEL_1, curRankBg:getPositionX(), rankLabel:getPositionY() - 20, {scale9 = true, size = curDotBgSize, ap = display.RIGHT_TOP})
    view:addChild(curDotBg)

    local curDotLabel = display.newLabel(150, 14.5, fontWithColor(5, {w = 130, fontSize = 20, text = summerActMgr:getThemeTextByText(__('当前点数')), color = '#ffffff', ap = display.RIGHT_CENTER}))
    curDotBg:addChild(curDotLabel)

    local curDotLabelSize = display.getLabelContentSize(curDotLabel)
    if (curDotLabelSize.height - 15) > curDotBgSize.height then
        curDotBgSize = cc.size(curDotBgSize.width, curDotLabelSize.height + 5)
        curDotBg:setContentSize(curDotBgSize)
        display.commonUIParams(curDotLabel, {po = cc.p(curDotLabel:getPositionX(), curDotBgSize.height / 2)})
    end

    local dotLabel = display.newLabel(size.width - 20, curDotBg:getPositionY() - curDotBgSize.height - 20, fontWithColor(5, {fontSize = 20, color = '#bc8f43', text = '0', ap = display.RIGHT_CENTER}))
    view:addChild(dotLabel)

    return {
        view      = view,
        gridView  = gridView,
        rankBtn   = rankBtn,
        rankLabel = rankLabel,
        dotLabel  = dotLabel,
    }
end

CreateCell_ = function ()
    local cell = CGridViewCell:new()
    local size = cc.size(497, 160)
    
    -- local touchView = display.newLayer(size.width / 2, size.height, {ap = display.CENTER, size = size, enable = true, color = cc.c4b(0,0,0,0)})
    -- cell:addChild(touchView)

    local rankRewardCell = require('Game.views.summerActivity.SummerActivityRankRewardCell').new({state = 1})
    display.commonUIParams(rankRewardCell, {ap = display.CENTER_TOP, po = cc.p(size.width / 2, size.height)})
    cell:addChild(rankRewardCell)

    local curDotLabel = display.newLabel(0, 15, {fontSize = 20, color = '#ad8136', ap = display.CENTER})
    cell:addChild(curDotLabel)

    local dotIcon = display.newImageView(RES_DIR.SUMMER_ACTIVITY_ICO_POINT, 0, 15, {ap = display.CENTER})
    dotIcon:setScale(0.15)
    cell:addChild(dotIcon)

    cell.viewData = {
        dotIcon     = dotIcon,
        rankRewardCell = rankRewardCell,
        curDotLabel = curDotLabel,
    }
    return cell
end

function SummerActivityTotalDotRewardView:CreateCell()
    return CreateCell_()
end

function SummerActivityTotalDotRewardView:getViewData()
    return self.viewData
end

return SummerActivityTotalDotRewardView