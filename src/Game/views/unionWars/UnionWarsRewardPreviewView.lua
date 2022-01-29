local VIEW_SIZE = cc.size(1000, 640)
local UnionWarsRewardPreviewView = class('common.UnionWarsRewardPreviewView', function ()
	local node = CLayout:create(VIEW_SIZE)
	node.name = 'unionWars.UnionWarsRewardPreviewView'
	node:enableNodeEvents()
	return node
end)


local RES_DICT = {
    ANNI_REWARDS_BG_LIST            = _res('ui/anniversary/rewardPreview/anni_rewards_bg_list.png'),
    ANNI_REWARDS_BG_LIST_1          = _res('ui/anniversary/rewardPreview/anni_rewards_bg_list_1.png'),
    STARPLAN_MAIN_FRAME_BTN_NAME    = _res('ui/home/activity/ptDungeon/activity_ptfb_main_frame_btn_name.png'),
    MAIN_BTN_RANK                   = _res('ui/home/nmain/main_btn_rank.png'),
}

local CreateView  = nil
local CreateCell_ = nil

function UnionWarsRewardPreviewView:ctor()
    xTry(function ( )
        self.viewData = CreateView(VIEW_SIZE)
        self:addChild(self.viewData.view)

        self:InitView()
	end, __G__TRACKBACK__)
end

function UnionWarsRewardPreviewView:InitView()
    local viewData = self:GetViewData()
    local tableView = viewData.tableView
    tableView:setDataSourceAdapterScriptHandler(handler(self, self.OnTableViewAdapter))

    -- display.commonUIParams(viewData.rankingBtn, {cb = handler(self, self.OnClickRankAction)})
   
end

function UnionWarsRewardPreviewView:UpdateTableView(datas)
    local viewData = self:GetViewData()
    local tableView = viewData.tableView
    tableView:setCountOfCell(#datas)
    tableView:reloadData()
end

function UnionWarsRewardPreviewView:RefreshUI(datas, skinId)
    self.datas = datas
    
    self:UpdateTableView(datas)
    self:UpdateCardImg(skinId)
end

function UnionWarsRewardPreviewView:UpdateCardImg(skinId)
    local viewData = self:GetViewData()
    local cardImg = viewData.cardImg
    local skinConf = CardUtils.GetCardSkinConfig(skinId)
    cardImg:setTexture(_res('ui/home/capsule/activityCapsule/summon_pre_img_' .. tostring(skinConf.drawId)))
    
end

function UnionWarsRewardPreviewView:UpdateCell(viewData, data)
    viewData.rewardCell:refreshUI(data, 1, false, tostring(data.name))
end

function UnionWarsRewardPreviewView:OnTableViewAdapter(p_convertview, idx)
    local pCell = p_convertview
    local index = idx + 1
    if pCell == nil then
        local viewData = self:GetViewData()
        pCell = CreateCell_(viewData.tableView:getSizeOfCell())
    end

    self:UpdateCell(pCell.viewData, self.datas[index])
    return pCell
end

function UnionWarsRewardPreviewView:GetViewData()
    return self.viewData
end

function UnionWarsRewardPreviewView:CreateCell(size)
    return CreateCell_(size)
end

CreateView = function (size)
    local view  = display.newLayer(size.width / 2, size.height / 2, {ap = display.CENTER, size = size})

    local cardImg = display.newNSprite('', 30, 3, {ap = display.LEFT_BOTTOM})
    cardImg:setScale(0.8)
    view:addChild(cardImg)

    local listSize = cc.size(600, 510)
    local listCellSize = cc.size(listSize.width, 140)
    local tableView = CTableView:create(listSize)
    display.commonUIParams(tableView, {po = cc.p(659, 267), ap = display.CENTER})
    tableView:setDirection(eScrollViewDirectionVertical)
    -- tableView:setBackgroundColor(cc.c4b(23, 67, 128, 128))
    tableView:setSizeOfCell(listCellSize)
    view:addChild(tableView)

    return {
        view                 = view,
        tableView            = tableView,
        cardImg              = cardImg
    }
end

CreateCell_ = function (size)
    local cell = CTableViewCell:new()
    cell:setContentSize(size)

    local rewardCell = require('Game.views.summerActivity.SummerActivityRankRewardCell').new({state = 1})
    display.commonUIParams(rewardCell, {ap = display.CENTER, po = cc.p(size.width / 2, size.height / 2)})
    rewardCell:updateBg(RES_DICT.ANNI_REWARDS_BG_LIST)
    rewardCell:updateRankTipLabelColor('#aa7522')
    cell:addChild(rewardCell)

    cell.viewData = {
        rewardCell = rewardCell
    }
    return cell
end

function UnionWarsRewardPreviewView:OnClickRankAction()
    -- body
end

return  UnionWarsRewardPreviewView