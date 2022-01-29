--[[
 * author : kaishiqi
 * descpt : 2020周年庆 - 剧情回顾 视图
]]
local Anniversary20StoryView = class('Anniversary20StoryView', function ()
    return ui.layer({name = 'Game.views.anniversary20.Anniversary20StoryView', enableNodeEvents = true})
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


function Anniversary20StoryView:ctor()
    -- create view
    self.viewData_ = Anniversary20StoryView.CreateView()
    self:addChild(self.viewData_.view)
end


function Anniversary20StoryView:getViewData()
    return self.viewData_
end


-------------------------------------------------
-- chapter cell

function Anniversary20StoryView:updateChapterInfo(customerCellVD, chapterId, chapterName)
    local iconPath = _res(string.format('ui/anniversary20/story/%s.png', 'wonderland_plot_icon_' .. (chapterId + 1)))
    customerCellVD.iconLayer:addAndClear(ui.image({img = iconPath}))
    customerCellVD.titleLabel:updateLabel({text = tostring(chapterName)})
end


function Anniversary20StoryView:updateChapterSelectState(customerCellVD, isSelect)
    customerCellVD.normalImg:setVisible(isSelect ~= true)
    customerCellVD.selectImg:setVisible(isSelect == true)
end


function Anniversary20StoryView:updateChapterStoryCount(customerCellVD, allStoryCount, unlockStoryCount)
    customerCellVD.countLabel:updateLabel({text = string.fmt('%1 / %2', unlockStoryCount, allStoryCount)})
end


-------------------------------------------------
-- story cell

function Anniversary20StoryView:updateStoryUnlockStatus(storyCellVD, isUnlocked)
    local isUnlockedStatus = isUnlocked == true
    storyCellVD.playIcon:setVisible(isUnlockedStatus)
    storyCellVD.lockIcon:setVisible(not isUnlockedStatus)
    storyCellVD.frameNormal:setVisible(isUnlockedStatus)
    storyCellVD.frameDisable:setVisible(not isUnlockedStatus)
end


function Anniversary20StoryView:updateStoryTitle(storyCellVD, title)
    storyCellVD.titleLabel:updateLabel({text = tostring(title)})
end


-------------------------------------------------------------------------------
-- view struct
-------------------------------------------------------------------------------

function Anniversary20StoryView.CreateView()
    local view = ui.layer()
    local size = view:getContentSize()
    local cpos = cc.sizep(size, ui.cc)

    -- black / block layer
    local backGroundGroup = view:addList({
        ui.layer({color = cc.c4b(0,0,0,150)}),
        ui.layer({color = cc.r4b(0), enable = true}),
    })


    ------------------------------------------------- [center]
    local centerLayer = ui.layer()
    view:addChild(centerLayer)

    -- view frame
    local viewFrameNode = ui.layer({p = cc.rep(cpos, 0, -30), bg = RES_DICT.VIEW_FRAME, ap = ui.cc, enable = true})
    local viewFrameSize = viewFrameNode:getContentSize()
    centerLayer:add(viewFrameNode)

    -- title label
    local titleLabel = ui.label():updateLabel({fnt = FONT.D2, color = '#5b3c25', text = __('剧情目录')})
    viewFrameNode:addList(titleLabel):alignTo(nil, ui.ct, {offsetX = -245, offsetY = -30})

    
    -- chapter tableView
    local chapterTableSize = cc.size(465, 520)
    local chapterTableView = ui.tableView({size = chapterTableSize, csizeH = 100, dir = display.SDIR_V})
    viewFrameNode:addList(chapterTableView):alignTo(nil, ui.cc, {offsetX = -245, offsetY = -10})
    chapterTableView:setCellCreateHandler(Anniversary20StoryView.CreateChapterCell)
    
    
    -- story group [frame | tableView] 
    local storyFrameSize  = cc.size(475, 530)
    local storyTableGroup = viewFrameNode:addList({
        ui.image({img = RES_DICT.COMMON_BG_GOODS, size = storyFrameSize, scale9 = true}),
        ui.tableView({size = cc.resize(storyFrameSize, -10, -10), csizeH = 95, dir = display.SDIR_V}),
    })
    ui.flowLayout(cc.rep(cc.sizep(viewFrameSize, ui.cc), 245, -10), storyTableGroup, {type = ui.flowC, ap = ui.cc})
    storyTableGroup[2]:setCellCreateHandler(Anniversary20StoryView.CreateStoryCell)


    return {
        view             = view,
        blockLayer       = backGroundGroup[2],
        storyTableView   = storyTableGroup[2],
        chapterTableView = chapterTableView,
    }
end


function Anniversary20StoryView.CreateChapterCell(cellParent)
    local view = cellParent
    local size = view:getContentSize()
    local cpos = cc.sizep(size, ui.cc)

    local frameGroup = view:addList({
        ui.image({img = RES_DICT.CUSTOMER_CELL_BG}),
        ui.image({img = RES_DICT.CUSTOMER_CELL_SELECT}),
    })
    ui.flowLayout(cpos, frameGroup, {type = ui.flowC, ap = ui.cc})

    local iconLayer = ui.layer({size = SizeZero, scale = 0.4})
    view:addList(iconLayer):alignTo(nil, ui.lc, {offsetX = 55, offsetY = 1})

    local titleLabel = ui.label({fnt = FONT.D16, ap = ui.lc, w = size.width - 170})
    view:addList(titleLabel):alignTo(iconLayer, ui.lc, {offsetX = 60})
    
    local countLabel = ui.label({fnt = FONT.D16, ap = ui.rc})
    view:addList(countLabel):alignTo(nil, ui.rc, {offsetX = -30})
    
    local clickArea = ui.layer({size = size, color = cc.r4b(0), enable = true})
    view:add(clickArea)
    
    return {
        view       = view,
        normalImg  = frameGroup[1],
        selectImg  = frameGroup[2],
        iconLayer  = iconLayer,
        titleLabel = titleLabel,
        countLabel = countLabel,
        clickArea  = clickArea,
    }
end


function Anniversary20StoryView.CreateStoryCell(cellParent)
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
        titleLabel   = titleLabel,
        playIcon     = iconGroup[1],
        lockIcon     = iconGroup[2],
        clickArea    = clickArea,
    }
end


return Anniversary20StoryView
