--[[
剧情任务弹窗
--]]
local VIEW_SIZE = display.size
---@class AnniversaryStoryView
local AnniversaryStoryView = class('AnniversaryStoryView', function ()
	local node = CLayout:create(display.size)
	node.name = 'Game.views.summerActivity.AnniversaryStoryView'
	node:enableNodeEvents()
	return node
end)

local CreateView       = nil
local CreateGroupCell_ = nil
local CreateStoryCell_ = nil


local RES_DICT = {
    COMMON_BG_GOODS                 = app.anniversaryMgr:GetResPath('ui/common/common_bg_goods.png'),
    COMMON_ICO_LOCK                 = app.anniversaryMgr:GetResPath('ui/common/common_ico_lock.png'),
    COMMON_ICO_RED_POINT            = app.anniversaryMgr:GetResPath('ui/common/common_ico_red_point.png'),
    SUMMER_ACTIVITY_EGG_EXTRA_BAR_GREY = app.anniversaryMgr:GetResPath('ui/home/activity/summerActivity/carnie/summer_activity_egg_extra_bar_grey.png'),
    SUMMER_ACTIVITY_EGG_EXTRA_BAR_ACTIVE = app.anniversaryMgr:GetResPath('ui/home/activity/summerActivity/carnie/summer_activity_egg_extra_bar_active.png'),
    ANNI_PLOT_BOOKS_BG              = app.anniversaryMgr:GetResPath('ui/anniversary/story/anni_plot_books_bg.png'),
    ANNI_PLOT_ICON_1                = app.anniversaryMgr:GetResPath('ui/anniversary/story/anni_plot_icon_1.png'),
    ANNI_PLOT_ZHIXIAN_BG            = app.anniversaryMgr:GetResPath('ui/anniversary/story/anni_plot_zhixian_bg.png'),
    ANNI_PLOT_ZHUXIAN_BG            = app.anniversaryMgr:GetResPath('ui/anniversary/story/anni_plot_zhuxian_bg.png'),
    TASK_BTN_PLAYBACK               = app.anniversaryMgr:GetResPath('ui/home/story/task_btn_playback.png'),
    ANNI_PLOT_REVIEW_UNLOCK         = app.anniversaryMgr:GetResPath('ui/anniversary/story/anni_plot_review_unlock.png'),
    ANNI_PLOT_REVIEW_DEFAULT        = app.anniversaryMgr:GetResPath('ui/anniversary/story/anni_plot_review_default.png'),
}

function AnniversaryStoryView:ctor( ... )
    self.args = unpack({...}) or {}
    self:initialUI()
end

function AnniversaryStoryView:initialUI()
    xTry(function ( )
        self.viewData_ = CreateView()
        self:addChild(self.viewData_.view)
	end, __G__TRACKBACK__)
end

--==============================--
--desc: 更新剧情列表
--@params storyDatas table 剧情数据列表
--@return
--==============================--
function AnniversaryStoryView:updateStoryList(storyDatas)
    local storyTableView = self:getViewData().storyTableView
    storyTableView:setCountOfCell(#storyDatas)
    storyTableView:reloadData()
end

--==============================--
--desc: 更新剧情组cell
--@params viewData table 视图数据
--@params data     table 剧情组数据
--@return
--==============================--
function AnniversaryStoryView:updateGroupCell(viewData, data, iconPath)

    self:updateGroupIcon(viewData, data, iconPath)

    local groupConfData = data.groupConfData or {}
    local storyTitleLabel = viewData.storyTitleLabel
    display.commonLabelParams(storyTitleLabel, {text = tostring(groupConfData.name)})

    local storyCount = data.storyCount
    local unlockStoryCount = data.unlockStoryCount
    local progressLabel   = viewData.progressLabel
    display.commonLabelParams(progressLabel, {text = string.format( "%s/%s", unlockStoryCount, storyCount)})

end

function AnniversaryStoryView:updateGroupIcon(viewData, data, iconPath)
    local groupId       = data.groupId
    local groupIcon     = viewData.groupIcon
    groupIcon:setTexture(iconPath or app.anniversaryMgr:GetResPath(string.format( "ui/anniversary/story/anni_plot_icon_%s", groupId)))
end

--==============================--
--desc: 通过剧情组下标更新剧情组背景
--@params index    int  剧情组下标
--@params isSelect bool 是否选择
--@return
--==============================--
function AnniversaryStoryView:updateGroupBgByIndex(index, isSelect)
    local groupTableView = self:getViewData().groupTableView
    local cell = groupTableView:cellAtIndex(index - 1)
    if cell then
        self:updateGroupCellBg(cell.viewData, isSelect)
    end
end

--==============================--
--desc: 更新剧情组背景
--@params viewData table 视图数据
--@params isSelect bool 是否选择
--@return
--==============================--
function AnniversaryStoryView:updateGroupCellBg(viewData, isSelect)
    local cellBg        = viewData.cellBg
    cellBg:setTexture(isSelect and RES_DICT.ANNI_PLOT_ZHUXIAN_BG or RES_DICT.ANNI_PLOT_ZHIXIAN_BG)
end

--==============================--
--desc: 更新剧情cell
--@params viewData table 视图数据
--@params data     table 剧情数据
--@return
--==============================--
function AnniversaryStoryView:updateStoryCell(viewData, data)
    local storyConfData = data.storyConfData or {}
    local titleLabel  = viewData.titleLabel
    display.commonLabelParams(titleLabel, {text = tostring(storyConfData.name)})

    local unlockStoryId = data.unlockStoryId
    local tipsImg     = viewData.tipsImg
    
    local isUnlock = unlockStoryId ~= nil
    tipsImg:setTexture(isUnlock and RES_DICT.TASK_BTN_PLAYBACK or RES_DICT.COMMON_ICO_LOCK)

    self:updateStoryCellBg(viewData, isUnlock)
end

--==============================--
--desc: 更新剧情cell背景
--@params viewData table 视图数据
--@params isUnlock bool  是否解锁
--@return
--==============================--
function AnniversaryStoryView:updateStoryCellBg(viewData, isUnlock)
    local cellBg = viewData.cellBg
    cellBg:setTexture(isUnlock and RES_DICT.ANNI_PLOT_REVIEW_DEFAULT or RES_DICT.ANNI_PLOT_REVIEW_UNLOCK)
    
end

function AnniversaryStoryView:CreateGroupCell(size)
    return CreateGroupCell_(size)
end

function AnniversaryStoryView:CreateStoryCell(size)
    return CreateStoryCell_(size)
end

CreateView = function ()
    local view = display.newLayer()

    local shallowLayer = display.newLayer(0, 0, {color = cc.c4b(0, 0, 0, 150), enable = true})
    view:addChild(shallowLayer)

    ------------------panel start-------------------
    local size = cc.size(1038, 666)
    local panel = display.newLayer(display.cx - 2, display.cy - 1,
    {
        ap = display.CENTER,
        size = cc.size(1038, 666),
    })
    view:addChild(panel)

    panel:addChild(display.newLayer(0,0,{size = size, ap = display.LEFT_BOTTOM, color = cc.c4b(0,0,0,0), enable = true}))

    local bg = display.newNSprite(RES_DICT.ANNI_PLOT_BOOKS_BG, 519, 333,
    {
        ap = display.CENTER,
    })
    panel:addChild(bg)

    local titleLabel = display.newLabel(272, 615,
    {
        text = app.anniversaryMgr:GetPoText(__('剧情目录')),
        ap = display.CENTER,
        fontSize = 26,
        color = '#5b3c25',
        font = TTF_GAME_FONT, ttf = true,
    })
    panel:addChild(titleLabel)


    local goupListSize = cc.size(474, 520)
    local groupTableView = CTableView:create(goupListSize)
    display.commonUIParams(groupTableView, {po = cc.p(275, 323), ap = display.CENTER})
    groupTableView:setDirection(eScrollViewDirectionVertical)
    -- groupTableView:setBackgroundColor(cc.c4b(23, 67, 128, 128))
    groupTableView:setSizeOfCell(cc.size(goupListSize.width, 100))
    panel:addChild(groupTableView)

    -- local collectTipLabel = display.newLabel(587, 585, fontWithColor(16, {
    --     text = app.anniversaryMgr:GetPoText(__('收集奖励')),
    --     ap = display.CENTER,
    -- }))
    -- panel:addChild(collectTipLabel)

    -- local collectProgressBar = CProgressBar:create(RES_DICT.SUMMER_ACTIVITY_EGG_EXTRA_BAR_ACTIVE)
    -- collectProgressBar:setBackgroundImage(RES_DICT.SUMMER_ACTIVITY_EGG_EXTRA_BAR_GREY)
    -- collectProgressBar:setAnchorPoint(display.CENTER)
    -- collectProgressBar:setMaxValue(100)
    -- collectProgressBar:setValue(100)
    -- collectProgressBar:setDirection(eProgressBarDirectionLeftToRight)
    -- collectProgressBar:setPosition(cc.p(753, 585))
    -- panel:addChild(collectProgressBar)

    local storyBg = display.newImageView(RES_DICT.COMMON_BG_GOODS, 765, 323,
    {
        ap = display.CENTER,
        scale9 = true, size = cc.size(goupListSize.width, goupListSize.height + 10),
    })
    panel:addChild(storyBg)

    -- local storyListSize = cc.size(474, 485)
    local storyTableView = CTableView:create(goupListSize)
    display.commonUIParams(storyTableView, {po = cc.p(765, 323), ap = display.CENTER})
    storyTableView:setDirection(eScrollViewDirectionVertical)
    -- storyTableView:setBackgroundColor(cc.c4b(23, 67, 128, 128))
    storyTableView:setSizeOfCell(cc.size(goupListSize.width, 94))
    panel:addChild(storyTableView)

   
    -------------------panel end--------------------
    return {
        view                    = view,
        shallowLayer            = shallowLayer,
        panel                   = panel,
        bg                      = bg,
        titleLabel              = titleLabel,
        groupTableView          = groupTableView,
        -- collectTipLabel         = collectTipLabel,
        -- collectProgressBar      = collectProgressBar,
        storyBg                 = storyBg,
        storyTableView          = storyTableView,
        
    }
end

CreateGroupCell_ = function (size)
    local groupCell = CTableViewCell:new()
    groupCell:setContentSize(size)

    local touchView = display.newLayer(size.width / 2, size.height / 2, {size = cc.size(460, 90), enable = true, color = cc.c4b(0,0,0,0), ap = display.CENTER})
    groupCell:addChild(touchView)
    
    -----------------groupCell start------------------

    local cellBg = display.newNSprite(RES_DICT.ANNI_PLOT_ZHIXIAN_BG, size.width / 2, size.height / 2,
    {
        ap = display.CENTER,
    })
    groupCell:addChild(cellBg)

    local groupIcon = display.newNSprite(RES_DICT.ANNI_PLOT_ICON_1, 54, 49,
    {
        ap = display.CENTER,
    })
    groupCell:addChild(groupIcon)

    local storyTitleLabel = display.newLabel(106, 50, fontWithColor(16, {
        ap = display.LEFT_CENTER,
        w = 282
    }))
    groupCell:addChild(storyTitleLabel)

    local progressLabel = display.newLabel(430, 50, fontWithColor(16, {
        ap = display.CENTER,
    }))
    groupCell:addChild(progressLabel)

    -- local redPointImg = display.newNSprite(RES_DICT.COMMON_ICO_RED_POINT, 458, 86,
    -- {
    --     ap = display.CENTER,
    -- })
    -- redPointImg:setScale(0.75)
    -- groupCell:addChild(redPointImg)

    ------------------groupCell end-------------------

    groupCell.viewData = {
        touchView               = touchView,
        cellBg                  = cellBg,
        groupIcon               = groupIcon,
        storyTitleLabel         = storyTitleLabel,
        progressLabel           = progressLabel,
        -- redPointImg             = redPointImg,
    }
    return groupCell
end

CreateStoryCell_ = function (size)
    local storyCell = CTableViewCell:new()
    storyCell:setContentSize(size)

    local touchView = display.newLayer(size.width / 2, size.height / 2, {size = cc.size(460, 86), color = cc.c4b(0,0,0,0), enable = true, ap = display.CENTER})
    storyCell:addChild(touchView)
    
    local cellBg = display.newNSprite(RES_DICT.ANNI_PLOT_REVIEW_UNLOCK, size.width / 2, size.height / 2,
    {
        ap = display.CENTER,
    })
    storyCell:addChild(cellBg)
 
    local titleLabel = display.newLabel(35, 47, fontWithColor(16, {
        ap = display.LEFT_CENTER,
        w = 300
    }))
    storyCell:addChild(titleLabel)

    -- local playBtn = display.newButton(428, 46,
    -- {
    --     ap = display.CENTER,
    --     n = RES_DICT.TASK_BTN_PLAYBACK,
    --     scale9 = true, size = cc.size(74, 74),
    --     enable = true,
    -- })
    -- storyCell:addChild(playBtn)
    
    local tipsImg = display.newNSprite(RES_DICT.COMMON_ICO_LOCK, 428, 46,
    {
        ap = display.CENTER,
    })
    storyCell:addChild(tipsImg)

    -- local lockImg = display.newNSprite(RES_DICT.COMMON_ICO_LOCK, 428, 52,
    -- {
    --     ap = display.CENTER,
    -- })
    -- storyCell:addChild(lockImg)


    storyCell.viewData = {
        touchView   = touchView,
        titleLabel  = titleLabel,
        tipsImg     = tipsImg,   
        cellBg      = cellBg,      
        -- playBtn                 = playBtn,
        -- lockImg                 = lockImg,
    }

    return storyCell
end

function AnniversaryStoryView:getViewData()
    return self.viewData_
end

return AnniversaryStoryView
