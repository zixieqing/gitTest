--[[
 * author : kaishiqi
 * descpt : 新游戏商店 - 月卡商店视图
]]
local MonthCardStoreView   = class('MonthCardStoreView', function()
    return display.newLayer(0, 0, {name = 'Game.views.stores.MonthCardStoreView'})
end)

local GoodNode = require('common.GoodNode')
local MonthCardStoreCell         = require('Game.views.stores.MonthCardStoreCell')
local MonthCardStoreActivityCell = require('Game.views.stores.MonthCardStoreActivityCell')

local RES_DICT = {
    COMMON_BTN_ORANGE     = _res('ui/common/common_btn_orange.png'),
    COMMON_TITLE_5        = _res('ui/common/common_title_5.png'),
    COMMON_TITLE_5_YELLOW = _res('ui/common/common_title_5_yellow.png'),
    COMMON_ARROW          = _res("ui/common/common_arrow.png"),
    BG_FRAME              = _res('ui/stores/month/shop_bg_goods.png'),
}

local CreateView    = nil
local CreateCell_   = nil
local CreateActivityView = nil

function MonthCardStoreView:ctor(size)
    self:setContentSize(size)

    -- create view
    self.viewData_ = CreateView(size)
    self:addChild(self.viewData_.view)
end

function MonthCardStoreView:refreshUI(datas, dataTimestamp)
    local activityData = datas.activityData or {}
    local isShowActView = next(activityData) ~= nil

    local viewData = self:getViewData()
    local tableView = viewData.tableView
    local view = viewData.view
    local size = view:getContentSize()

    if isShowActView then
        if viewData.actView == nil then
            local actViewData = CreateActivityView(size)
            table.merge(viewData, actViewData)
            view:addChild(actViewData.actView)
        end
        local activityList = viewData.activityList
        activityList:removeAllNodes()
        local activityDataCount = #activityData
        local actViewSize = cc.size(size.width, 144)
        for i = 1, activityDataCount do
            local actData = activityData[i]
            local actCell = MonthCardStoreActivityCell.new({size = actViewSize})
            actCell:setTag(i)
            actCell:updateCell(actData, dataTimestamp)
            activityList:insertNodeAtLast(actCell)
        end
        if isElexSdk() then
            activityList:setContentSize(cc.size(size.width, 288))
            tableView:setContentSize(cc.size(size.width, size.height - 10 - actViewSize.height - 144))
        else
            tableView:setContentSize(cc.size(size.width, size.height - 10 - actViewSize.height))
            activityList:setContentSize(actViewSize)
        end
        activityList:setBounceable(activityDataCount > 1)
        activityList:reloadData()
    else
        tableView:setContentSize(cc.size(size.width, size.height - 10))
        if viewData.actView then
            viewData.actView:setVisible(false)
        end
    end

    self:updateTableView(viewData, datas.memberDatas or {})
end


function MonthCardStoreView:updateTableView(viewData, memberDatas)
    local tableView = viewData.tableView
    tableView:setCountOfCell(#memberDatas)
    tableView:reloadData()
    tableView:setVisible(true)
end


function MonthCardStoreView:updateCell(viewData, data, dataTimestamp)
    local storeCell = viewData.storeCell
    storeCell:updateCell(data, dataTimestamp)
end

CreateView = function(size)
    local view = display.newLayer(0, 0, {size = size})
    view:add(ui.image({img = RES_DICT.BG_FRAME, ap = ui.lb, scale9 = true, size = size}))

    local tableViewSize = cc.size(size.width, size.height - 6)
    if isElexSdk() then
        tableViewSize =  cc.size(size.width, size.height - 6 - 144)
    end
    local tableView = CTableView:create(cc.size(size.width, size.height - 10))
    display.commonUIParams(tableView, {po = cc.p(size.width / 2, 3), ap = display.CENTER_BOTTOM})
    tableView:setDirection(eScrollViewDirectionVertical)
    tableView:setSizeOfCell(cc.size(tableViewSize.width, 235))
    -- tableView:setBackgroundColor(cc.c4b(178, 63, 88, 100))
    view:addChild(tableView)
    tableView:setVisible(false)


    return {
        view                = view,
        -- actView             = actView,
        tableView           = tableView,

        defultTableViewSize = tableViewSize
    }
end

CreateCell_ = function (size)
    local cell = CTableViewCell:new()
    cell:setContentSize(size)

    local storeCell = MonthCardStoreCell.new({size = size})
    cell:addChild(storeCell)
    
    cell.viewData = {
        storeCell = storeCell
    }

    return cell
end

CreateActivityView = function (size)
    local actViewSize = cc.size(size.width, 144)
    local eScrollWay =  eScrollViewDirectionHorizontal
    if isElexSdk() then
        eScrollWay = eScrollViewDirectionVertical
        actViewSize = cc.size(size.width, 288)
    end
    local actView = display.newLayer(size.width / 2, size.height - 2, {ap = display.CENTER_TOP, size = actViewSize})
    
    local activityList = CListView:create(actViewSize)
    activityList:setDirection(eScrollWay)
    activityList:setAnchorPoint(display.CENTER)
    activityList:setPosition(actViewSize.width / 2, actViewSize.height / 2)
    -- activityList:setBackgroundColor(cc.r4b(255))
    actView:addChild(activityList)

    return {
        actView      = actView,
        activityList = activityList,
    }
end

function MonthCardStoreView:CreateCell(size)
    return CreateCell_(size)
end

function MonthCardStoreView:getViewData()
    return self.viewData_
end


return MonthCardStoreView
