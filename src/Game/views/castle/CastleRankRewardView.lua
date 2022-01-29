local CommonDialog = require('common.CommonDialog')
local CastleRankRewardView = class('CastleRankRewardView', CommonDialog)

local RES_DICT = {
    COMMON_BG_4             = app.activityMgr:CastleResEx('ui/common/common_bg_4.png'),
    BTN_RANK      = app.activityMgr:CastleResEx('ui/home/nmain/main_btn_rank.png'),
    SUMMER_ACTIVITY_ENTRANCE_LABEL_1   = app.activityMgr:CastleResEx("ui/home/activity/summerActivity/entrance/summer_activity_entrance_label_1.png"),

    ANNI_REWARDS_BG_LIST            = app.activityMgr:CastleResEx('ui/anniversary/rewardPreview/anni_rewards_bg_list.png'),
    CASTLE_REWARDS_BG_CARD_200096_7 =  app.activityMgr:CastleResEx('ui/castle/rank/castle_rewards_bg_card.png')

}

local CreateView = nil
local CreateCell_ = nil

function CastleRankRewardView:InitialUI( )
    
    xTry(function ( )
        self.viewData = CreateView()
        
        self:InitView()
	end, __G__TRACKBACK__)
end

function CastleRankRewardView:InitView()
    
end

function CastleRankRewardView:UpdateRankLabel(rank)
    local rankLabel = self:GetViewData().rankLabel
    rank = checkint(rank)
    local rankText = (rank == 0) and app.activityMgr:GetCastleText(__('未入榜')) or rank
    display.commonLabelParams(rankLabel, {text = rankText})
end

function CastleRankRewardView:UpdateDotLabel(score)
    local dotLabel = self:GetViewData().dotLabel
    score = tonumber(score)
    display.commonLabelParams(dotLabel, {text = score == nil and 0 or score})
end

--==============================--
--desc: 更新排行奖励列表
--@params datas         table  剧情奖励数据列表
--==============================--
function CastleRankRewardView:UpdateTableView(datas)
    local tableView = self:GetViewData().tableView
    tableView:setCountOfCell(#datas)
    tableView:reloadData()
end

function CastleRankRewardView:UpdateCell(viewData, data)
    local rankRewardCell = viewData.rankRewardCell
    rankRewardCell:refreshUI(data.confData, 1, data.isCurRank)
end

CreateView = function ()
    local size = cc.size(950, 590)
    local view = display.newLayer(0, 0, {size = size})

    view:addChild(display.newImageView(RES_DICT.COMMON_BG_4, size.width / 2, size.height / 2, {size = size, scale9 = true, ap = display.CENTER}))

    view:addChild(display.newImageView(RES_DICT.CASTLE_REWARDS_BG_CARD_200096_7, 100, size.height / 2 + 10, {ap = display.CENTER}))

    local listSize = cc.size(505, size.height - 20)
    local cellSize = cc.size(listSize.width, 140)
    local tableView = CTableView:create(listSize)
    tableView:setPosition(cc.p(size.width / 2 + 46, size.height / 2))
    -- tableView:setBackgroundColor(cc.c3b(100,100,200))
    tableView:setAnchorPoint(display.CENTER)
    tableView:setDirection(eScrollViewDirectionVertical)
    -- tableView:setBackgroundColor(cc.c4b(23, 67, 128, 128))
    tableView:setSizeOfCell(cellSize)
    view:addChild(tableView)

    local rankBtn = nil
    --  排行榜
    if CommonUtils.GetModuleAvailable(MODULE_SWITCH.RANKING) then
        rankBtn = display.newButton(size.width - 70, size.height - 50, {n = RES_DICT.BTN_RANK, ap = display.CENTER})
		display.commonLabelParams(rankBtn, fontWithColor(14, {outline = '#491d1d', outlineSize = 2, fontSize = 22, text = app.activityMgr:GetCastleText(__('排行榜')), offset = cc.p(0, -38)}))
        view:addChild(rankBtn)
    end

    local curRankBg = display.newImageView(RES_DICT.SUMMER_ACTIVITY_ENTRANCE_LABEL_1, size.width - 4, size.height - 126, {ap = display.RIGHT_CENTER})
    view:addChild(curRankBg)
    curRankBg:addChild(display.newLabel(150, 14.5, fontWithColor(5, {fontSize = 20, text = app.activityMgr:GetCastleText(__('当前排名')), color = '#ffffff', ap = display.RIGHT_CENTER})))
    
    local rankLabel = display.newLabel(size.width - 20, size.height - 152, fontWithColor(5, {fontSize = 20, color = '#bc8f43', ap = display.RIGHT_CENTER}))
    view:addChild(rankLabel)

    local curDotBg = display.newImageView(RES_DICT.SUMMER_ACTIVITY_ENTRANCE_LABEL_1, curRankBg:getPositionX(), size.height - 181, {ap = display.RIGHT_CENTER})
    view:addChild(curDotBg)
    curDotBg:addChild(display.newLabel(150, 14.5, fontWithColor(5, {fontSize = 20, text = app.activityMgr:GetCastleText(__('累计伤害')), color = '#ffffff', ap = display.RIGHT_CENTER})))

    local dotLabel = display.newLabel(size.width - 20, size.height - 210, fontWithColor(5, {fontSize = 20, color = '#bc8f43', ap = display.RIGHT_CENTER}))
    view:addChild(dotLabel)

    return {
        view      = view,
        tableView = tableView,
        rankBtn   = rankBtn,
        rankLabel = rankLabel,
        dotLabel  = dotLabel,
    }

end

CreateCell_ = function (size)
    local cell = CTableViewCell:new()
    local rankRewardCell = require('Game.views.summerActivity.SummerActivityRankRewardCell').new({state = 1})
    display.commonUIParams(rankRewardCell, {ap = display.CENTER, po = cc.p(size.width / 2, size.height / 2)})
    cell:addChild(rankRewardCell)
    rankRewardCell:updateBg(RES_DICT.ANNI_REWARDS_BG_LIST)

    cell.viewData = {
        rankRewardCell = rankRewardCell,
    }
    return cell
end

function CastleRankRewardView:CreateCell(size)
    return CreateCell_(size)
end

function CastleRankRewardView:GetViewData()
    return self.viewData
end

function CastleRankRewardView:CloseHandler()
    app:UnRegsitMediator(self.args.mediatorName)
end

return  CastleRankRewardView
