--[[
 * author : kaishiqi
 * descpt : 水吧 - 营业报告弹窗
]]
local CommonDialog          = require('common.CommonDialog')
local WaterBarBusinessPopup = class('WaterBarBusinessPopup', CommonDialog)

local RES_DICT = {
    JIAZI_IMG   = _res('ui/privateRoom/menu_img_jiazi.png'),
    BG_FRAME    = _res('ui/home/kitchen/cooking_bg.png'),
    GOODS_FRAME = _res('ui/common/common_bg_goods.png'),
    LIST_FRAME  = _res('ui/waterBar/business/bar_bg_list.png'),
}

local BUSINESS_PROXY_NAME   = FOOD.WATER_BAR.BUSINESS.PROXY_NAME
local BUSINESS_PROXY_STRUCT = FOOD.WATER_BAR.BUSINESS.PROXY_STRUCT


function WaterBarBusinessPopup:InitialUI()
    self.rewardsCustomerIdList_ = {}

    -- create view
    self.viewData = WaterBarBusinessPopup.CreateView()
    self:getViewData().businessTableView:setCellUpdateHandler(handler(self, self.onUpdateBusinessCellHandler_))

    -- init model
    self.businessProxy_ = regVoProxy(BUSINESS_PROXY_NAME, BUSINESS_PROXY_STRUCT)
    self.businessProxy_:set(BUSINESS_PROXY_STRUCT, app.waterBarMgr:getBusinessRewards())
    self:updateBusinessRewardsData_()

    -- update view
    self:updateBusinessRewardsView_()
end


function WaterBarBusinessPopup:onCleanup()
    unregVoProxy(BUSINESS_PROXY_NAME)
    self:cleanBusinessRewardsData_()
end


function WaterBarBusinessPopup:getViewData()
    return self.viewData
end


-------------------------------------------------
-- private

function WaterBarBusinessPopup:cleanBusinessRewardsData_()
    -- 用完就清除数据，防止再次弹窗会再次增加奖励的可能
    app.waterBarMgr:setBusinessRewards(nil)
end


function WaterBarBusinessPopup:updateBusinessRewardsData_()
    -- update customer rewards
    local rewardDataList = {}
    local REWARD_STRUCT  = BUSINESS_PROXY_STRUCT.REWARD_MAP
    for customerId, _ in pairs(self.businessProxy_:get(REWARD_STRUCT):getData()) do
        local rewardsData = self.businessProxy_:get(REWARD_STRUCT.REWARDS, customerId):getData()
        table.insertto(rewardDataList, rewardsData)
    end
    CommonUtils.DrawRewards(rewardDataList)
    
    -- upate frequency point
    local POINT_MAP = BUSINESS_PROXY_STRUCT.FREQUENCY_MAP
    for customerId, pointNum in pairs(self.businessProxy_:get(POINT_MAP):getData()) do
        app.waterBarMgr:addCustomerPoint(customerId, pointNum)
    end
end


function WaterBarBusinessPopup:updateBusinessRewardsView_()
    self.rewardsCustomerIdList_ = table.keys(self.businessProxy_:get(BUSINESS_PROXY_STRUCT.REWARD_MAP):getData())
    self:getViewData().businessTableView:resetCellCount(#self.rewardsCustomerIdList_)
end


-------------------------------------------------
-- handler

function WaterBarBusinessPopup:onUpdateBusinessCellHandler_(cellIndex, cellViewData)
    if cellViewData == nil then return end

    -- get cell data
    local customerId  = self.rewardsCustomerIdList_[cellIndex]
    local CELL_STRUCT = BUSINESS_PROXY_STRUCT.REWARD_MAP.REWARDS
    local cellVoProxy = self.businessProxy_:get(CELL_STRUCT, customerId)

    -- update customerHead
    local customerConf = CONF.BAR.CUSTOMER:GetValue(customerId)
    cellViewData.customerHead:RefreshUI({cardData = {cardId = customerConf.cardId}})

    -- update rewardGoods
    local rewardsDataSize = cellVoProxy:size(CELL_STRUCT)
    local REWARDSS_STRUCT = CELL_STRUCT.GOODS_DATA
    for index = 1, #cellViewData.rewardGoodsList do
        local goodsNode = cellViewData.rewardGoodsList[index]
        if index <= rewardsDataSize then
            local consumrsVoProxy  = cellVoProxy:get(REWARDSS_STRUCT, index)
            local consumrsGoodsId  = consumrsVoProxy:get(REWARDSS_STRUCT.GOODS_ID)
            local consumrsGoodsNum = consumrsVoProxy:get(REWARDSS_STRUCT.GOODS_NUM)
            goodsNode:setVisible(true)
            goodsNode:RefreshSelf({
                goodsId = consumrsGoodsId,
                amount  = consumrsGoodsNum,
            })
        else
            goodsNode:setVisible(false)
        end
    end
end


-------------------------------------------------------------------------------
-- view struct
-------------------------------------------------------------------------------

function WaterBarBusinessPopup.CreateView()
    local size = cc.size(480, 674)
    local view = ui.layer({size = size, bg = RES_DICT.BG_FRAME, scale9 = true})
    local cpos = cc.sizep(size, ui.cc)


    local topGroup = view:addList({
        ui.image({img = RES_DICT.JIAZI_IMG, mb = 5}),
        ui.label({fnt = FONT.TTF28, color = '#ba5c5c', text = __('昨日招待顾客结算')}),
    })
    ui.flowLayout(cc.p(cpos.x, size.height + 35), topGroup, {type = ui.flowV, ap = ui.cb})


    local centerSize  = cc.size(size.width-40, 570)
    local centerGroup = view:addList({
        ui.image({img = RES_DICT.GOODS_FRAME, size = centerSize, scale9 = true}),
        ui.tableView({size = cc.resize(centerSize, -4, -4), csizeH = 115, dir = display.SDIR_V, ml = 1, mb = 2})
    })
    ui.flowLayout(cc.rep(cpos, 0, -25), centerGroup, {type = ui.flowC, ap = ui.cc})
    centerGroup[2]:setCellCreateHandler(WaterBarBusinessPopup.CreateBusinessCell)
    
    return {
        view              = view,
        businessTableView = centerGroup[2],
    }
end


function WaterBarBusinessPopup.CreateBusinessCell(cellParent)
    local view = cellParent
    local size = cellParent:getContentSize()
    local cpos = cc.sizep(size, ui.cc)
    view:addList(ui.image({img = RES_DICT.LIST_FRAME, cut = cc.dir(15,15,15,15), size = cc.resize(size, -6, -6)})):alignTo(nil, ui.cc, {offsetY = -2})

    local customerHead = ui.cardHeadNode({p = cc.p(65, cpos.y-2), scale = 0.45})
    view:add(customerHead)

    local rewardGoodsList = {}
    for index = 1, 3 do
        rewardGoodsList[index] = ui.goodsNode({scale = 0.75, showAmount = true, defaultCB = true})
    end
    view:addList(rewardGoodsList)
    ui.flowLayout(cc.p(size.width-25, cpos.y-2), rewardGoodsList, {ap = ui.rc, gapW = 15})

    return {
        view            = view,
        customerHead    = customerHead,
        rewardGoodsList = rewardGoodsList,
    }
end


return WaterBarBusinessPopup
