--[[
活动剧情回顾视图
--]]
local VIEW_SIZE = display.size
---@class PlotCollectActivityStoryView
local PlotCollectActivityStoryView = class('PlotCollectActivityStoryView', function ()
	local node = CLayout:create(VIEW_SIZE)
	node.name = 'Game.views.summerActivity.PlotCollectActivityStoryView'
	node:enableNodeEvents()
	return node
end)

local CreateView           = nil
local CreateLabelCell_     = nil
local CreateActivityTypeCell_     = nil
local CreateChapterBg_   = nil
local CreateChapterCell_ = nil
local CreateStoryCell_     = nil

local RES_DICT = {
    COMMON_BG_GOODS                      = _res('ui/common/common_bg_goods.png'),
    ANNI_PLOT_BOOKS_BG                   = _res('ui/anniversary/story/anni_plot_books_bg.png'),
    ANNI_PLOT_ICON_1                     = _res('ui/anniversary/story/anni_plot_icon_1.png'),
    TASK_BTN_PLAYBACK                    = _res('ui/home/story/task_btn_playback.png'),
    ANNI_PLOT_REVIEW_UNLOCK              = _res('ui/anniversary/story/anni_plot_review_unlock.png'),
    ANNI_PLOT_REVIEW_DEFAULT             = _res('ui/anniversary/story/anni_plot_review_default.png'),
    PLOT_BTN_TAB_SELECT                  = _res('ui/home/plotCollect/plot_btn_tab_select.png'),
    PLOT_BTN_TAB_DEFAULT                 = _res('ui/home/plotCollect/plot_btn_tab_default.png'),
    PLOT_COLLECT_BTN_PLOT                = _res('ui/home/plotCollect/plot_collect_btn_plot.png'),
    PLOT_FRAME_CHAPTER_BG_SELECT         = _res('ui/home/plotCollect/plot_frame_chapter_bg_select.png'),
    PLOT_FRAME_CHAPTER_BG                = _res('ui/home/plotCollect/plot_frame_chapter_bg.png'),
    PLOT_ICON_ARROW                      = _res('ui/home/plotCollect/plot_icon_arrow.png'),
    COMMON_BG_LIST_SELECTED              = _res('ui/mail/common_bg_list_selected.png'),
}

function PlotCollectActivityStoryView:ctor( ... )
    self.args = unpack({...}) or {}
    self:initialUI()
end

function PlotCollectActivityStoryView:initialUI()
    xTry(function ( )
        self.viewData_ = CreateView()
        self:addChild(self.viewData_.view)
	end, __G__TRACKBACK__)
end


---UpdateLabelBg
---@param tabBtn userdata   按钮
---@param isSelect  boolean 是否选择
function PlotCollectActivityStoryView:UpdateTabBtn(tabBtn, isSelect, text)
    local path = isSelect and RES_DICT.PLOT_BTN_TAB_SELECT or RES_DICT.PLOT_BTN_TAB_DEFAULT
    tabBtn:setNormalImage(path)
    tabBtn:setSelectedImage(path)

    local textFont = isSelect and fontWithColor(16) or {fontSize = 22, color = '#f9d9b3'}
    if text then
        textFont.text = text
    end
    display.commonLabelParams(tabBtn, textFont)
end

---UpdateStoryList
---更新剧情列表
---@param storyDatas table 剧情列表数据
function PlotCollectActivityStoryView:UpdateStoryList(storyDatas)
    local storyTableView = self:getViewData().storyTableView
    storyTableView:setCountOfCell(#storyDatas)
    storyTableView:reloadData()
end

---UpdateGroupCell
---@param viewData table        视图数据
---@param data table            活动类型数据
---@param chapterCount number   章节个数
function PlotCollectActivityStoryView:UpdateGroupCell(viewData, data, chapterCount)
    --- 更新标题
    display.commonLabelParams(viewData.storyTitleLabel, {text = tostring(data.name)})

    --- 更新进度
    display.commonLabelParams(viewData.progressLabel, {text = string.format( "%s/%s", chapterCount, chapterCount)})

    --- 更新图标
    viewData.groupIcon:setTexture(_res(string.format( "ui/home/plotCollect/icon/%s", tostring(data.icon))))

    viewData.arrowIcon:setVisible(chapterCount > 1)
end

---UpdateChapterCell
---@param viewData table
---@param chapterData table   章节数据
---@param storyCount number   剧情个数
function PlotCollectActivityStoryView:UpdateChapterCell(viewData, chapterData, storyCount)
     display.commonLabelParams(viewData.chapterName, {text = tostring(chapterData.name)})
     display.commonLabelParams(viewData.progressLabel, {text = string.format( "%s/%s", storyCount, storyCount)})
end

---UpdateChapterBg
---@param viewData table
---@param isSelect boolean 是否选择
function PlotCollectActivityStoryView:UpdateChapterBg(viewData, isSelect)
    viewData.bg:setTexture(isSelect and RES_DICT.PLOT_FRAME_CHAPTER_BG_SELECT or RES_DICT.PLOT_FRAME_CHAPTER_BG)
end

---UpdateStoryCell
---更新剧情cell
---@param viewData table
---@param data table       剧情数据
function PlotCollectActivityStoryView:UpdateStoryCell(viewData, data)
    local titleLabel  = viewData.titleLabel
    display.commonLabelParams(titleLabel, {text = tostring(data.name)})

end

function PlotCollectActivityStoryView:CreateLabelCell(size)
    return CreateLabelCell_(size)
end

function PlotCollectActivityStoryView:CreateActivityTypeCell(size)
    return CreateActivityTypeCell_(size)
end

function PlotCollectActivityStoryView:CreateChapterBg(size, posX)
    return CreateChapterBg_(size, posX)
end

function PlotCollectActivityStoryView:CreateChapterCell(size)
    return CreateChapterCell_(size)
end

function PlotCollectActivityStoryView:CreateStoryCell(size)
    return CreateStoryCell_(size)
end

CreateView = function ()
    local view = display.newLayer()

    local shallowLayer = display.newLayer(0, 0, {color = cc.c4b(0, 0, 0, 150), enable = true})
    view:addChild(shallowLayer)

    local size = cc.size(1038, 666)
    local labelLayerSize = cc.size(141, 666)
    local labelLayer = display.newLayer(display.cx - size.width * 0.5 + 23, display.cy - 1, {
        ap = display.RIGHT_CENTER, size = labelLayerSize})
    view:addChild(labelLayer,1)

    local labelTableView = CTableView:create(cc.size(labelLayerSize.width, 500))
    display.commonUIParams(labelTableView, {po = cc.p(labelLayerSize.width * 0.5, labelLayerSize.height * 0.5), ap = display.CENTER})
    labelTableView:setDirection(eScrollViewDirectionVertical)
    -- labelTableView:setBackgroundColor(cc.c4b(23, 67, 128, 128))
    labelTableView:setSizeOfCell(cc.size(labelLayerSize.width, 120))
    labelLayer:addChild(labelTableView)

    ------------------panel start-------------------
    local panel = display.newLayer(display.cx - 2, display.cy - 1,
    {
        ap = display.CENTER,
        size = cc.size(1038, 666),
        -- color = cc.c3b(100,100,100)
    })
    view:addChild(panel)

    panel:addChild(display.newLayer(0,0,{size = cc.size(size.width + labelLayerSize.width, size.height), ap = display.LEFT_BOTTOM, color = cc.c4b(0,0,0,0), enable = true}))

    local bg = display.newNSprite(RES_DICT.ANNI_PLOT_BOOKS_BG, 519, 333,
    {
        ap = display.CENTER,
    })
    panel:addChild(bg)

    local titleLabel = display.newLabel(272, 615,
    {
        text = __('活动列表'),
        ap = display.CENTER,
        fontSize = 26,
        color = '#5b3c25',
        font = TTF_GAME_FONT, ttf = true,
    })
    panel:addChild(titleLabel)

    -- local groupTableView = CTableView:create(goupListSize)
    -- display.commonUIParams(groupTableView, {po = cc.p(275, 323), ap = display.CENTER})
    -- groupTableView:setDirection(eScrollViewDirectionVertical)
    -- -- groupTableView:setBackgroundColor(cc.c4b(23, 67, 128, 128))
    -- groupTableView:setSizeOfCell(cc.size(goupListSize.width, 100))
    -- panel:addChild(groupTableView)

    local goupListSize = cc.size(410, 520)
    local expandableListView = CExpandableListView:create(goupListSize)
    expandableListView:setDirection(eScrollViewDirectionVertical)
    expandableListView:setName('expandableListView')
    display.commonUIParams(expandableListView, {po = cc.p(275, 323), ap = display.CENTER})
    panel:addChild(expandableListView)


    local storyListSize = cc.size(474, 520)
    local storyBg = display.newImageView(RES_DICT.COMMON_BG_GOODS, 765, 323,
    {
        ap = display.CENTER,
        scale9 = true, size = cc.size(storyListSize.width, storyListSize.height + 10),
    })
    panel:addChild(storyBg)

    local storyTableView = CTableView:create(storyListSize)
    display.commonUIParams(storyTableView, {po = cc.p(765, 323), ap = display.CENTER})
    storyTableView:setDirection(eScrollViewDirectionVertical)
    -- storyTableView:setBackgroundColor(cc.c4b(23, 67, 128, 128))
    storyTableView:setSizeOfCell(cc.size(storyListSize.width, 94))
    panel:addChild(storyTableView)
    --local storyTableView = CTableView:create(storyListSize)
    --display.commonUIParams(storyTableView, {po = cc.p(765, 323), ap = display.CENTER})
    --storyTableView:setDirection(eScrollViewDirectionVertical)
    ---- storyTableView:setBackgroundColor(cc.c4b(23, 67, 128, 128))
    --storyTableView:setSizeOfCell(cc.size(storyListSize.width, 94))
    --panel:addChild(storyTableView)

    -------------------panel end--------------------
    return {
        view               = view,
        shallowLayer       = shallowLayer,
        labelLayer         = labelLayer,
        labelTableView     = labelTableView,
        panel              = panel,
        bg                 = bg,
        titleLabel         = titleLabel,
    -- groupTableView     = groupTableView,
        expandableListView = expandableListView,
        storyBg            = storyBg,
        storyTableView     = storyTableView,
        
    }
end

CreateLabelCell_ = function (size)
    local cell = CTableViewCell:new()
    cell:setContentSize(size)

    local tabBtn = display.newButton(size.width, size.height * 0.5, {
        n = RES_DICT.PLOT_BTN_TAB_DEFAULT,
        ap = display.RIGHT_CENTER
    })
    tabBtn:setName('tabBtn')
    -- fontWithColor('17', {reqW = 120}
    display.commonLabelParams(tabBtn, {offset = cc.p(10, 0), fontSize = 22, color = '#f9d9b3'})
    cell:addChild(tabBtn)

    return cell 
end

CreateActivityTypeCell_ = function (size)
    local groupCell = CExpandableNode:new()
    groupCell:setContentSize(size)

    local touchView = display.newLayer(size.width * 0.5, size.height * 0.5, {size = size, enable = true, color = cc.c4b(0,0,0,0), ap = display.CENTER})
    groupCell:addChild(touchView)
    
    -----------------groupCell start------------------

    local cellBg = display.newNSprite(RES_DICT.PLOT_COLLECT_BTN_PLOT, size.width * 0.5, size.height * 0.5,
    {
        ap = display.CENTER,
    })
    groupCell:addChild(cellBg)

    local groupIcon = display.newNSprite(RES_DICT.ANNI_PLOT_ICON_1, 54, size.height * 0.5,
    {
        ap = display.CENTER,
    })
    groupCell:addChild(groupIcon)

    local storyTitleLabel = display.newLabel(106, 50, fontWithColor(16, {
        ap = display.LEFT_CENTER,
        w = 210
    }))
    groupCell:addChild(storyTitleLabel)

    local progressLabel = display.newLabel(size.width - 50 , 50, fontWithColor(16, {
        ap = display.RIGHT_CENTER,
    }))
    groupCell:addChild(progressLabel)

    local arrowIcon = display.newImageView(RES_DICT.PLOT_ICON_ARROW, size.width - 25, size.height * 0.5)
    --arrowIcon:setRotation(90)
    groupCell:addChild(arrowIcon)

    local selectImg = display.newImageView(RES_DICT.COMMON_BG_LIST_SELECTED, size.width * 0.5, size.height * 0.5, {
        scale9 = true, ap = display.CENTER, size = size
    })
    groupCell:addChild(selectImg)
    selectImg:setVisible(false)
    ------------------groupCell end-------------------

    groupCell.viewData = {
        touchView       = touchView,
        cellBg          = cellBg,
        groupIcon       = groupIcon,
        storyTitleLabel = storyTitleLabel,
        progressLabel   = progressLabel,
        arrowIcon       = arrowIcon,
        selectImg       = selectImg,
    }
    return groupCell
end

CreateChapterBg_ = function(size)
    local layer = display.newLayer(size.width * 0.5, size.height * 0.5, {ap = display.CENTER, size = size})
    local bg = display.newImageView(RES_DICT.COMMON_BG_GOODS, size.width * 0.5, size.height * 0.5,
            {scale9 = true, ap = display.CENTER, size = cc.size(size.width - 15, size.height)})
    layer:addChild(bg)
    return layer
end

CreateChapterCell_ = function(size)
    local middleWidth, middleHeight = size.width * 0.5, size.height * 0.5
    local layer = display.newLayer(0, 0, {size = size})

    local touchView = display.newLayer(middleWidth, middleHeight, {size = size, color = cc.c4b(0,0,0,0), enable = true, ap = display.CENTER})
    layer:addChild(touchView)

    local bg = display.newImageView(RES_DICT.PLOT_FRAME_CHAPTER_BG, middleWidth, middleHeight)
    layer:addChild(bg)

    local chapterName = display.newLabel(30, middleHeight, fontWithColor(16, {ap = display.LEFT_CENTER, w = 230}))
    layer:addChild(chapterName)

    local progressLabel = display.newLabel(size.width - 30 , middleHeight, fontWithColor(16, {
        ap = display.RIGHT_CENTER,
    }))
    layer:addChild(progressLabel)

    layer.viewData = {
        bg            = bg,
        touchView     = touchView,
        chapterName   = chapterName,
        progressLabel = progressLabel,
    }

    return layer
end

CreateStoryCell_ = function (size)
    local storyCell = CTableViewCell:new()
    storyCell:setContentSize(size)

    local touchView = display.newLayer(size.width * 0.5, size.height * 0.5, {size = cc.size(460, 86), color = cc.c4b(0,0,0,0), enable = true, ap = display.CENTER})
    storyCell:addChild(touchView)
    
    local cellBg = display.newNSprite(RES_DICT.ANNI_PLOT_REVIEW_DEFAULT, size.width * 0.5, size.height * 0.5,
    {
        ap = display.CENTER,
    })
    storyCell:addChild(cellBg)
 
    local titleLabel = display.newLabel(35, 47, fontWithColor(16, {
        ap = display.LEFT_CENTER,
        w = 300
    }))
    storyCell:addChild(titleLabel)

    local playImg = display.newNSprite(RES_DICT.TASK_BTN_PLAYBACK, 428, 46,
    {
        ap = display.CENTER,
    })
    storyCell:addChild(playImg)

    storyCell.viewData = {
        touchView   = touchView,
        titleLabel  = titleLabel,
        playImg     = playImg,
        cellBg      = cellBg,
    }

    return storyCell
end

function PlotCollectActivityStoryView:getViewData()
    return self.viewData_
end

return PlotCollectActivityStoryView
