-------------------------------------------------------------------------------
-- 个人信息 - 领取级奖励 奖励预览弹窗
-- 
-- Author: kaishiqi <zhangkai@funtoygame.com>
-- 
-- Create: 2021-07-27 16:34:12
-------------------------------------------------------------------------------
local CommonDialog = require('common.CommonDialog')
local PersonInformationRewardsPreviewPopup = class('PersonInformationRewardsPreviewPopup', CommonDialog)

local RES_DICT = {
    BG_FRAME     = _res('ui/common/common_bg_9.png'),
    COM_TITLE    = _res('ui/common/common_bg_title_2.png'),
    REWARD_LINE  = _res('ui/home/activity/summerActivity/carnie/summer_activity_egg_preview_line_1.png'),
    REWARD_LIGHT = _res('ui/home/activity/summerActivity/carnie/summer_activity_egg_bg_preview.png'),
}


function PersonInformationRewardsPreviewPopup:InitialUI()
    local derivativeId = checkint(self.args.derivativeId)
    local rewardsConf  = CONF.DERIVATIVE.REWARDS:GetValue(derivativeId)
    self.virtualRewardList_ = {}
    self.realityRewardList_ = {}
    for _, rewardConf in ipairs(rewardsConf) do
        if checkint(rewardConf.rewardType) == 2 then
            table.insert(self.realityRewardList_, rewardConf)
        else
            table.insert(self.virtualRewardList_, rewardConf)
        end
    end
    
    -- create view
    self.viewData = PersonInformationRewardsPreviewPopup.CreateView()

    -- update view
    self:updateVirtualRewardList_()
    self:updateRealityRewardList_()
end


function PersonInformationRewardsPreviewPopup:getViewData()
    return self.viewData
end


function PersonInformationRewardsPreviewPopup:updateVirtualRewardList_()
    local virtualRewardLayer = self:getViewData().virtualRewardLayer
    virtualRewardLayer:removeAllChildren()

    local rewardColNum  = 4
    local rewardRowNum  = math.ceil(#self.virtualRewardList_ / rewardColNum)
    local rewardBasePos = cc.sizep(virtualRewardLayer, ui.ct)
    for row = 1, rewardRowNum do
        local rewardNodes = {}
        for col = 1, rewardColNum do
            local rewardIndex = (row-1) * rewardColNum + col
            local rewardData  = self.virtualRewardList_[rewardIndex]
            if rewardData then
                local goodsId    = checkint(rewardData.goodsId)
                local goodsNum   = checkint(rewardData.num)
                local rewardNode = ui.goodsNode({id = goodsId, num = goodsNum, showAmount = true, defaultCB = true, scale = 0.8})
                table.insert(rewardNodes, rewardNode)
            end
        end
        virtualRewardLayer:addList(rewardNodes)
        ui.flowLayout(cc.rep(rewardBasePos, 0, -5 + (row-0.5) * -96), rewardNodes, {type = ui.flowH, ap = ui.ct, gapW = 10})
    end
end


function PersonInformationRewardsPreviewPopup:updateRealityRewardList_()
    local realityRewardLayer = self:getViewData().realityRewardLayer
    realityRewardLayer:removeAllChildren()

    local rewardBasePos = cc.sizep(realityRewardLayer, ui.cc)
    local rewardNodes = {}
    for _, rewardData in ipairs(self.realityRewardList_) do
        local goodsId    = checkint(rewardData.goodsId)
        local goodsNum   = checkint(rewardData.num)
        local rewardNode = ui.goodsNode({id = goodsId, num = goodsNum, showAmount = true, defaultCB = true, scale = 0.8})
        table.insert(rewardNodes, rewardNode)
    end
    realityRewardLayer:addList(rewardNodes)
    ui.flowLayout(cc.rep(rewardBasePos, 0, 0), rewardNodes, {type = ui.flowH, ap = ui.cc, gapW = 10})
end


-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------

function PersonInformationRewardsPreviewPopup.CreateView()
    local size = cc.size(560, 640)
    local view = ui.layer({size = size, bg = RES_DICT.BG_FRAME, scale9 = true})
    local cpos = cc.sizep(size, ui.cc)

    local titleBar = ui.title({img = RES_DICT.COM_TITLE}):updateLabel({fnt = FONT.D3, text = __('礼包奖励一览'), paddingW = 60, safeW = 120, offset = cc.p(0,-2)})
    view:addList(titleBar):alignTo(nil, ui.ct, {offsetY = -4})

    
    local realityRewardSize  = cc.size(525, 180)
    local realityRewardGroup = view:addList({
        ui.image({img = RES_DICT.REWARD_LIGHT}),
        ui.label({fnt = FONT.D4, text = __('周边礼包'), mb = 52}),
        ui.image({img = RES_DICT.REWARD_LINE, size = cc.size(realityRewardSize.width - 60, 4), scale9 = true, mb = 35}),
        ui.layer({size = cc.resize(realityRewardSize, -40, -80), mt = 18}),
    })
    ui.flowLayout(cc.p(cpos.x, size.height - 125), realityRewardGroup, {ap = ui.cc, type = ui.flowC})


    local virtualRewardSize  = cc.size(525, 500-10)
    local virtualRewardGroup = view:addList({
        ui.label({fnt = FONT.D4, text = __('游戏道具'), mb = 162}),
        ui.image({img = RES_DICT.REWARD_LINE, size = cc.size(virtualRewardSize.width - 60, 4), scale9 = true, mb = 145}),
        ui.layer({size = cc.resize(virtualRewardSize, -40, -80), mt = 18}),
    })
    ui.flowLayout(cc.p(cpos.x, cpos.y - 80), virtualRewardGroup, {ap = ui.cc, type = ui.flowC})

    return {
        view               = view,
        realityRewardLayer = realityRewardGroup[4],
        virtualRewardLayer = virtualRewardGroup[3],
    }
end


return PersonInformationRewardsPreviewPopup
