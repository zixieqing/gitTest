--[[
 * author : kaishiqi
 * descpt : 武道会 - 奖励预览弹窗
]]
local CommonDialog   = require('common.CommonDialog')
local ChampionshipRewardPreviewPopup = class('ChampionshipRewardPreviewPopup', CommonDialog)

local RES_DICT = {
    BG_FRAME     = _res('ui/common/common_bg_4.png'),
    COM_TITLE    = _res('ui/common/common_title_3.png'),
    REWARD_FRAME = _res('ui/common/common_bg_goods.png'),
    CUTTING_LINE = _res('ui/common/common_ico_line_1.png'),
}

local REWARD_CONF = {
    CONF.CHAMPIONSHIP.AUDITION_REWARD,  -- 海选赛奖励
    CONF.CHAMPIONSHIP.KNOCKOUT_REWARD,  -- 晋级赛奖励
}


function ChampionshipRewardPreviewPopup:InitialUI()
    local rewardType = checkint(self.args.type)
    self.rewardConf_ = REWARD_CONF[rewardType]

    -- init vars
    self.rewardIdList_ = self.rewardConf_ and self.rewardConf_:GetIdListUp() or {}

    -- create view
    self.viewData = ChampionshipRewardPreviewPopup.CreateView()

    -- add listens
    self:getViewData().rewardsTableView:setCellUpdateHandler(handler(self, self.onUpdateRewardsCellHandler_))

    -- update view
    self:getViewData().rewardsTableView:resetCellCount(#self.rewardIdList_)
end


function ChampionshipRewardPreviewPopup:getViewData()
    return self.viewData
end


function ChampionshipRewardPreviewPopup:onUpdateRewardsCellHandler_(cellIndex, cellViewData, changedVoDefine)
    if cellViewData == nil then return end

    local rewardsId  = checkint(self.rewardIdList_[cellIndex])
    local rewardConf = self.rewardConf_ and self.rewardConf_:GetValue(rewardsId) or {}
    
    -- update title
    local rankText  = ''
    local rankUpper = checkint(rewardConf.upper)
    local rankLower = checkint(rewardConf.lower)
    if rankUpper == 0 or rankUpper == rankLower then
        rankText = string.fmt(__('排名：第_num_名'), {_num_ = rankLower})
    elseif rankLower < 0 then
        rankText = string.fmt(__('排名：第_num_名及以下'), {_num_ = rankUpper})
    else
        rankText = string.fmt(__('排名：第_upper_ - _lower_名'), {_upper_ = rankUpper, _lower_ = rankLower})
    end
    cellViewData.rankLabel:updateLabel({text = rankText})
    
    -- update rewards
    local goodsNodeList = {}
    for goodsIndex, goodsNode in ipairs(cellViewData.goodsNodeList) do
        local goodsData = checktable(rewardConf.rewards)[goodsIndex] or {}
        goodsNode:RefreshSelf({goodsId = goodsData.goodsId, num = goodsData.num})
        goodsNode:setVisible(next(goodsData) ~= nil)
    end
end


-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------

function ChampionshipRewardPreviewPopup.CreateView()
    local size = cc.size(580, 650)
    local view = ui.layer({size = size, bg = RES_DICT.BG_FRAME, scale9 = true})
    local cpos = cc.sizep(size, ui.cc)

    local titleBar = ui.title({img = RES_DICT.COM_TITLE}):updateLabel({fnt = FONT.D16, text = __('奖励预览'), paddingW = 60, safeW = 80})
    view:addList(titleBar):alignTo(nil, ui.ct, {offsetY = -15})

    local tipsText  = __('奖励发放形式：通过邮件统一发放\n奖励发放时间：活动结束后两小时')
    local tipsLabel = ui.label({fnt = FONT.D15, hAlign = display.TAL, text = tipsText})
    view:addList(tipsLabel):alignTo(titleBar, ui.cb, {offsetY = -10})

    local rewardsSize  = cc.resize(size, -50, -130)
    local rewardsGroup = view:addList({
        ui.image({img = RES_DICT.REWARD_FRAME, size = rewardsSize, scale9 = true}),
        ui.tableView({size = cc.resize(rewardsSize, -6, -6), csizeH = 185, dir = display.SDIR_V}),
    })
    ui.flowLayout(cc.rep(cpos, 0, -45), rewardsGroup, {type = ui.flowC, ap = ui.cc})
    rewardsGroup[2]:setCellCreateHandler(ChampionshipRewardPreviewPopup.CreateRewardsCell)

    return {
        view             = view,
        rewardsTableView = rewardsGroup[2],
    }
end


function ChampionshipRewardPreviewPopup.CreateRewardsCell(cellParent)
    local view = cellParent
    local size = cellParent:getContentSize()
    local cpos = cc.sizep(size, ui.cc)

    local infoGroup = view:addList({
        ui.label({fnt = FONT.D5, ap = ui.lc, mb = 18}),
        ui.image({img = RES_DICT.CUTTING_LINE, scale9 = true, size = cc.size(size.width, 2)}),
        ui.layer({size = cc.resize(size, -20, -45), color1 = cc.r4b(50)})
    })
    ui.flowLayout(cc.p(10, 5), infoGroup, {type = ui.flowV, ap = ui.lt})


    local goodsNodeList  = {}
    local goodsNodeLayer = infoGroup[3]
    for goodsIndex = 1, 4 do
        goodsNodeList[goodsIndex] = ui.goodsNode({showAmount = true, defaultCB = true})
    end
    goodsNodeLayer:addList(goodsNodeList)
    ui.flowLayout(cc.rep(cc.sizep(goodsNodeLayer, ui.lc), 15, 0), goodsNodeList, {type = ui.flowH, ap = ui.lc, gapW = 15})
    
    return {
        view          = view,
        rankLabel     = infoGroup[1],
        goodsNodeList = goodsNodeList,
    }
end


return ChampionshipRewardPreviewPopup
