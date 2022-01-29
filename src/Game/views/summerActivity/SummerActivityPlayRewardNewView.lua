local VIEW_SIZE = cc.size(950, 590)
local SummerActivityPlayRewardNewView = class('SummerActivityPlayRewardNewView', function ()
	local node = CLayout:create(VIEW_SIZE)
	node.name = 'Game.views.summerActivity.SummerActivityPlayRewardNewView'
	node:enableNodeEvents()
	return node
end)

local RES_DIR_ = {
    COMMON_BTN           = _res('ui/common/common_btn_orange.png'),
    COMMON_BTN_DISABLE   = _res('ui/common/common_btn_orange_disable.png'),
    COMMON_BTN_DRAWN     = _res('ui/common/activity_mifan_by_ico.png'),
    TIPS_ICON            = _res('ui/common/common_btn_tips.png'),
    SUMMER_ACTIVITY_RANK_BG_CARD          = _res('ui/home/activity/summerActivity/entrance/summer_activity_rank_bg_card.png'),
    SUMMER_ACTIVITY_RANK_BG_WORDS         = _res('ui/home/activity/summerActivity/entrance/summer_activity_rank_bg_words.png'),
    SUMMER_ACTIVITY_ENTRANCE_RANK_LIST    = _res("ui/home/activity/summerActivity/entrance/summer_activity_entrance_rank_list.png"),
    SUMMER_ACTIVITY_RANK_BG_QBOSS         = _res('ui/home/activity/summerActivity/entrance/summer_activity_rank_bg_Qboss.png'),
    SEASON_POINT_BG_FRAME_DEFAULT_2       = _res('ui/home/activity/summerActivity/entrance/season_point_bg_frame_default_2.png'),
    SUMMER_ACTIVITY_EGG_BG_EXTRA_SHADOW   = _res('ui/home/activity/summerActivity/carnie/summer_activity_egg_bg_extra_shadow.png'),
    SUMMER_ACTIVITY_EGG_EXTRA_BAR_GREY    = _res('ui/home/activity/summerActivity/carnie/summer_activity_egg_extra_bar_grey.png'),
    SUMMER_ACTIVITY_EGG_EXTRA_BAR_ACTIVE  = _res('ui/home/activity/summerActivity/carnie/summer_activity_egg_extra_bar_active.png'),
    

    ANNI_REWARDS_LABEL_CARD_PREVIEW       = _res('ui/anniversary/rewardPreview/anni_rewards_label_card_preview.png'),
}

local RES_DIR = {}

local summerActMgr    = app.summerActMgr
local RANK_CELL_SIZE  = cc.size(580, 138)
local CreateView      = nil
local CreateCellLayer = nil

function SummerActivityPlayRewardNewView:ctor( ... )
    RES_DIR = summerActMgr:resetResPath(RES_DIR_)

    self.args = unpack({...})
    self:initialUI()
end

function SummerActivityPlayRewardNewView:initialUI()
    xTry(function ( )
        self.viewData = CreateView(VIEW_SIZE)
        self:addChild(self.viewData.view)
        display.commonUIParams(self.viewData.view, {ap = display.CENTER, po = cc.p(VIEW_SIZE.width / 2, VIEW_SIZE.height / 2)})
        self:initView()
	end, __G__TRACKBACK__)
end

function SummerActivityPlayRewardNewView:initView()
    
end

function SummerActivityPlayRewardNewView:refreshUI(data)
    
end

function SummerActivityPlayRewardNewView:updateUI(data)
    
end

function SummerActivityPlayRewardNewView:updateJokerImg(viewData, bossId)

end

function SummerActivityPlayRewardNewView:updateCell(viewData, data)
    local rewardCell   = viewData.rewardCell
    local drawBtn      = viewData.drawBtn
    local conf         = data.conf
    rewardCell:refreshUI(conf, 1, false, string.format(summerActMgr:getThemeTextByText(__('完成小丑关卡%s次可获得')), tostring(conf.times)))
    drawBtn:RefreshUI({drawState = data.state})
end

CreateView = function (size)
    local view = display.newLayer(0, 0, {size = size})

    local cardBg = display.newImageView(RES_DIR.SUMMER_ACTIVITY_RANK_BG_CARD, 100, size.height / 2 + 10, {ap = display.CENTER}) 
    view:addChild(cardBg)

    
    local rankRewardCell = CreateCellLayer(RANK_CELL_SIZE)
    display.commonUIParams(rankRewardCell, {ap = display.RIGHT_TOP, po = cc.p(size.width - 20, size.height - 15)})
    view:addChild(rankRewardCell)

    local rewardCell = rankRewardCell:getChildByName('rewardCell')

    local drawBtn = rankRewardCell:getChildByName('drawBtn')

    local jokerImg = display.newImageView(RES_DIR.SUMMER_ACTIVITY_RANK_BG_QBOSS, 40, 0, {ap = display.CENTER_BOTTOM})
    rankRewardCell:addChild(jokerImg)
    -- 进度条
    local progressBarBg = display.newImageView(RES_DIR.SUMMER_ACTIVITY_EGG_BG_EXTRA_SHADOW, 40, 14)
    rankRewardCell:addChild(progressBarBg, 3)
    progressBarBg:setScaleX(0.7)
    local progressBar = CProgressBar:create(RES_DIR.SUMMER_ACTIVITY_EGG_EXTRA_BAR_ACTIVE)
    progressBar:setBackgroundImage(RES_DIR.SUMMER_ACTIVITY_EGG_EXTRA_BAR_GREY)
    progressBar:setDirection(eProgressBarDirectionLeftToRight)
    progressBar:setPosition(cc.p(40, 14))
    progressBar:setScaleX(0.7)
    rankRewardCell:addChild(progressBar, 5)
    local progressLabel = display.newLabel(37, 14, {fontSize = 20, color = '#ffffff'})
    rankRewardCell:addChild(progressLabel, 10)


    local tableView = CTableView:create(cc.size(RANK_CELL_SIZE.width, 260))
    tableView:setSizeOfCell(cc.size(RANK_CELL_SIZE.width, 172))
    tableView:setDirection(eScrollViewDirectionVertical)
    tableView:setAnchorPoint(display.CENTER_TOP)
    -- tableView:setBackgroundColor(cc.c3b(100,100,100))
    view:addList(tableView,1):alignTo(rankRewardCell, ui.cb, {offsetY = -10})

    -- 对话
    local dialogueBg = display.newImageView(RES_DIR.SUMMER_ACTIVITY_RANK_BG_WORDS, size.width / 2, 28, {ap = cc.p(0.5, 0)})
    view:addChild(dialogueBg, 5)
    -- dialogueBg:setVisible(false)

    local tipsIcon = display.newImageView(RES_DIR.TIPS_ICON, 50 , 90)
    dialogueBg:addChild(tipsIcon)

    local scrollViewSize = cc.size(540, 70)
    local scrollView = cc.ScrollView:create()
    scrollView:setPosition(cc.p(120, 60))
	scrollView:setDirection(eScrollViewDirectionVertical)
	scrollView:setAnchorPoint(display.LEFT_TOP)
    scrollView:setViewSize(scrollViewSize)
    view:addChild(scrollView, 5)
    
    local moduleExplainConf = checktable(CommonUtils.GetConfigAllMess('moduleExplain'))['-6'] or {}
    local ruleLabel = display.newLabel(0, scrollViewSize.height, fontWithColor(15, {text = tostring(moduleExplainConf.descr), hAlign = display.TAL, w = scrollViewSize.width}))
    scrollView:setContainer(ruleLabel)
    local descrScrollTop = scrollViewSize.height - display.getLabelContentSize(ruleLabel).height
    scrollView:setContentOffset(cc.p(0, descrScrollTop))
    -- 卡牌预览
    -- card preview btn
    local cardPreviewBtn = require("common.CardPreviewEntranceNode").new()
    display.commonUIParams(cardPreviewBtn, {ap = display.RIGHT_BOTTOM, po = cc.p(size.width - 24, 45)})
    view:addChild(cardPreviewBtn, 5)
    -- cardPreviewBtn:setVisible(false)

    local cardPreviewTip = display.newImageView(RES_DIR.ANNI_REWARDS_LABEL_CARD_PREVIEW, -155, 8, {ap = display.RIGHT_CENTER})
    cardPreviewTip:setScaleX(-1)
    cardPreviewBtn:addChild(cardPreviewTip)
    
    cardPreviewBtn:addChild(display.newLabel(105, 8, fontWithColor(14, {ap = display.RIGHT_CENTER, text = __('卡牌详情')})))

    return {
        view          = view,
        cardBg        = cardBg,
        drawBtn       = drawBtn,
        progressBar   = progressBar,
        progressLabel = progressLabel,
        tableView     = tableView,
        rewardCell    = rewardCell,
        cardPreviewBtn  = cardPreviewBtn,
    }
end

function SummerActivityPlayRewardNewView:CreateCell(size)
    local cell = CTableViewCell:new()
    cell:setContentSize(size)

    local rewardLayout = CreateCellLayer(RANK_CELL_SIZE)
    cell:addList(rewardLayout):alignTo(nil, ui.cc)

    local rewardCell = rewardLayout:getChildByName('rewardCell')
    rewardCell:updateBg(RES_DIR.SEASON_POINT_BG_FRAME_DEFAULT_2)
    -- 
    local drawBtn = rewardLayout:getChildByName('drawBtn')
    cell.viewData = {
        rewardLayout = rewardLayout,
        rewardCell   = rewardCell,
        drawBtn      = drawBtn,
    }
    return cell
end

function SummerActivityPlayRewardNewView:getViewData()
    return self.viewData
end

CreateCellLayer = function (rewardLayoutSize)
    local rewardLayout = display.newLayer(0, 0, {size = rewardLayoutSize})

    local rewardCell = require('Game.views.summerActivity.SummerActivityRankRewardCell').new({state = 1})
    rewardCell:setName('rewardCell')
    display.commonUIParams(rewardCell, {ap = display.RIGHT_CENTER, po = cc.p(rewardLayoutSize.width - 40, rewardLayoutSize.height * 0.5)})
    rewardLayout:addChild(rewardCell)

    local drawBtn = require('common.CommonDrawButton').new({btnParams = {
        ap = display.CENTER,
        scale9 = true, size = cc.size(123, 62),
        enable = true,
    }})
    drawBtn:setName('drawBtn')
    display.commonUIParams(drawBtn, {po = cc.p(rewardLayoutSize.width - 5, drawBtn:getContentSize().height * 0.5 + 5), ap = display.RIGHT_CENTER})
    rewardLayout:addChild(drawBtn)
    
    return rewardLayout
end

return SummerActivityPlayRewardNewView