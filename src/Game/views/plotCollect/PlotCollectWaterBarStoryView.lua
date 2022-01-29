--[[
 * author : kaishiqi
 * descpt : 酒吧 - 剧情回顾 视图
]]
local PlotCollectWaterBarStoryView = class('PlotCollectWaterBarStoryView', function ()
    return ui.layer({name = 'Game.views.plotCollect.PlotCollectWaterBarStoryView', enableNodeEvents = true})
end)

local RES_DICT = {
    VIEW_FRAME           = _res('ui/anniversary/story/anni_plot_books_bg.png'),
    COMMON_BG_GOODS      = _res('ui/common/common_bg_goods.png'),
    --                   = customer cell
    CUSTOMER_CELL_BG     = _res('ui/anniversary/story/anni_plot_zhixian_bg.png'),
    CUSTOMER_CELL_SELECT = _res('ui/anniversary/story/anni_plot_zhuxian_bg.png'),
    --                   = story cell
    STORY_CELL_FRAME_N   = _res('ui/anniversary/story/anni_plot_review_default.png'),
    STORY_CELL_FRAME_D   = _res('ui/anniversary/story/anni_plot_review_unlock.png'),
    STORY_PLAY_ICON      = _res('ui/home/story/task_btn_playback.png'),
    STORY_LOCK_ICON      = _res('ui/common/common_ico_lock.png'),
}


function PlotCollectWaterBarStoryView:ctor()
    -- create view
    self.viewData_ = PlotCollectWaterBarStoryView.CreateView()
    self:addChild(self.viewData_.view)
end


function PlotCollectWaterBarStoryView:getViewData()
    return self.viewData_
end


-------------------------------------------------
-- customer cell

function PlotCollectWaterBarStoryView:updateCustomerSelectStatus(customerCellVD, isSelect)
    customerCellVD.normalImg:setVisible(isSelect ~= true)
    customerCellVD.selectImg:setVisible(isSelect == true)
end


function PlotCollectWaterBarStoryView:updateCustomerCardInfo(customerCellVD, cardId)
    customerCellVD.headNode:RefreshUI({cardData = {cardId = cardId}})
    customerCellVD.titleLabel:updateLabel({text = tostring(CardUtils.GetCardConfig(cardId).name)})
end


function PlotCollectWaterBarStoryView:updateCustomerStoryCount(customerCellVD, allStoryList, unlockStoryList)
    customerCellVD.countLabel:updateLabel({text = string.fmt('%1 / %2', #checktable(allStoryList), #checktable(unlockStoryList))})
end


-------------------------------------------------
-- story cell

function PlotCollectWaterBarStoryView:updateStoryUnlockStatus(storyCellVD, isUnlocked)
    local isUnlockedStatus = isUnlocked == true
    storyCellVD.playIcon:setVisible(isUnlockedStatus)
    storyCellVD.lockIcon:setVisible(not isUnlockedStatus)
    storyCellVD.frameNormal:setVisible(isUnlockedStatus)
    storyCellVD.frameDisable:setVisible(not isUnlockedStatus)
end


function PlotCollectWaterBarStoryView:updateStoryTitle(storyCellVD, title)
    storyCellVD.titleLabel:updateLabel({text = tostring(title)})
end


-------------------------------------------------------------------------------
-- view struct
-------------------------------------------------------------------------------

function PlotCollectWaterBarStoryView.CreateView()
    local view = ui.layer()
    local size = view:getContentSize()
    local cpos = cc.sizep(size, ui.cc)

    -- black layer
    view:add(ui.layer({color = cc.c4b(0,0,0,150)}))

    -- block layer
    local blockLayer = ui.layer({color = cc.r4b(0), enable = true})
    view:add(blockLayer)


    ------------------------------------------------- [center]
    local centerLayer = ui.layer()
    view:addChild(centerLayer)

    -- view frame
    local viewFrameNode = ui.layer({p = cc.rep(cpos, 0, -30), bg = RES_DICT.VIEW_FRAME, ap = ui.cc, enable = true})
    local viewFrameSize = viewFrameNode:getContentSize()
    centerLayer:add(viewFrameNode)

    -- title label
    local titleLabel = ui.label():updateLabel({fnt = FONT.D2, color = '#5b3c25', text = __('水吧趣闻')})
    viewFrameNode:addList(titleLabel):alignTo(nil, ui.ct, {offsetX = -245, offsetY = -30})

    
    -- customer tableView
    local customerTableSize = cc.size(460, 520)
    local customerTableView = ui.tableView({size = customerTableSize, csizeH = 100, dir = display.SDIR_V})
    viewFrameNode:addList(customerTableView):alignTo(nil, ui.cc, {offsetX = -245, offsetY = -10})
    customerTableView:setCellCreateHandler(PlotCollectWaterBarStoryView.CreateCustomerCell)
    
    
    -- story frameImage
    local storyFrameSize  = cc.size(475, 530)
    local storyTableGroup = viewFrameNode:addList({
        ui.image({img = RES_DICT.COMMON_BG_GOODS, size = storyFrameSize, scale9 = true}),
        ui.tableView({size = cc.resize(storyFrameSize, -10, -10), csizeH = 95, dir = display.SDIR_V}),
    })
    ui.flowLayout(cc.rep(cc.sizep(viewFrameSize, ui.cc), 245, -10), storyTableGroup, {type = ui.flowC, ap = ui.cc})
    storyTableGroup[2]:setCellCreateHandler(PlotCollectWaterBarStoryView.CreateStoryCell)


    return {
        view              = view,
        blockLayer        = blockLayer,
        storyTableView    = storyTableGroup[2],
        customerTableView = customerTableView,
    }
end


function PlotCollectWaterBarStoryView.CreateCustomerCell(cellParent)
    local view = cellParent
    local size = view:getContentSize()
    local cpos = cc.sizep(size, ui.cc)

    local frameGroup = view:addList({
        ui.image({img = RES_DICT.CUSTOMER_CELL_BG}),
        ui.image({img = RES_DICT.CUSTOMER_CELL_SELECT}),
    })
    ui.flowLayout(cpos, frameGroup, {type = ui.flowC, ap = ui.cc})

    local headNode = ui.cardHeadNode({scale = 0.4})
    view:addList(headNode):alignTo(nil, ui.lc, {offsetX = 15, offsetY = 1})

    local titleLabel = ui.label({fnt = FONT.D16, ap = ui.lc, w = size.width - 170})
    view:addList(titleLabel):alignTo(headNode, ui.lc, {offsetX = 90})
    
    local countLabel = ui.label({fnt = FONT.D16, ap = ui.rc})
    view:addList(countLabel):alignTo(nil, ui.rc, {offsetX = -30})
    
    local clickArea = ui.layer({size = size, color = cc.r4b(0), enable = true})
    view:add(clickArea)
    
    return {
        view       = view,
        normalImg  = frameGroup[1],
        selectImg  = frameGroup[2],
        headNode   = headNode,
        titleLabel = titleLabel,
        countLabel = countLabel,
        clickArea  = clickArea,
    }
end


function PlotCollectWaterBarStoryView.CreateStoryCell(cellParent)
    local view = cellParent
    local size = view:getContentSize()
    local cpos = cc.sizep(size, ui.cc)

    local frameGroup = view:addList({
        ui.image({p = cpos, img = RES_DICT.STORY_CELL_FRAME_N}),
        ui.image({p = cpos, img = RES_DICT.STORY_CELL_FRAME_D}),
    })
    ui.flowLayout(cpos, frameGrup, {type = ui.flowC, ap = ui.cc})

    local titleLabel = ui.label({fnt = FONT.D16, ap = ui.lc, w = size.width - 120})
    view:addList(titleLabel):alignTo(nil, ui.lc, {offsetX = 35})

    local iconGroup = view:addList({
        ui.image({img = RES_DICT.STORY_PLAY_ICON}),
        ui.image({img = RES_DICT.STORY_LOCK_ICON}),
    })
    ui.flowLayout(cc.rep(cc.sizep(size, ui.rc), -50, 0), iconGroup, {type = ui.flowC, ap = ui.cc})

    local clickArea = ui.layer({size = size, color = cc.r4b(0), enable = true})
    view:add(clickArea)

    return {
        view         = view,
        frameNormal  = frameGroup[1],
        frameDisable = frameGroup[2],
        clickArea    = clickArea,
        titleLabel   = titleLabel,
        playIcon     = iconGroup[1],
        lockIcon     = iconGroup[2],
    }
end


return PlotCollectWaterBarStoryView
