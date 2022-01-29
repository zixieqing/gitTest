--[[
剧情任务弹窗
--]]
local VIEW_SIZE = display.size
local SummerActivityStoryView = class('SummerActivityStoryView', function ()
	local node = CLayout:create(display.size)
	node.name = 'Game.views.summerActivity.SummerActivityStoryView'
	node:enableNodeEvents()
	return node
end)

local CreateView = nil
local CreateTab  = nil

local RES_DIR_ = {
    TAB_UNUSED    = _res('ui/common/comment_tab_unused.png'),
    TAB_SELECTED  = _res('ui/common/comment_tab_selected.png'),
    TASK_TITLE    = _res('ui/home/activity/summerActivity/entrance/summer_activity_task_title.png'),
    TASK_UNLOCK   = _res('ui/home/activity/summerActivity/entrance/summer_activity_task_unlock.png'),
    CLOSE         =  _res('ui/backpack/materialCompose/item_compose_bg_close.png'),
    OPEN          =  _res('ui/backpack/materialCompose/item_compose_bg_open.png'),
    SUMMER_ACTIVITY_QBAN = _res('ui/home/activity/summerActivity/entrance/summer_activity_qban.png'),
}
local RES_DIR = {}

local TAB_TAG = {
    STORY   = 1,
    BRANCH  = 2,
}

local summerActMgr = app.summerActMgr

function SummerActivityStoryView:ctor( ... )
    RES_DIR = summerActMgr:resetResPath(RES_DIR_)
    self.args = unpack({...}) or {}
    self:initialUI()
end

function SummerActivityStoryView:initialUI()
    xTry(function ( )
        self.viewData_ = CreateView()
        self:addChild(self.viewData_.view)
	end, __G__TRACKBACK__)
end

function SummerActivityStoryView:updateTab(tab, isChecked)
    local fontTag = isChecked and 16 or 18
    local img = isChecked and RES_DIR.TAB_SELECTED or RES_DIR.TAB_UNUSED
    tab:setNormalImage(img)
    tab:setSelectedImage(img)
    
    display.commonLabelParams(tab, fontWithColor(fontTag, {fontSize = 18}))
    tab:setEnabled(not isChecked)
end

function SummerActivityStoryView:updateDesLabel(desc)
    local viewData = self:getViewData()
    local desLabel = viewData.desLabel
    display.commonLabelParams(desLabel, {text = tostring(desc)})
end

function SummerActivityStoryView:updateSwitchImg(viewData, isSelect)
    local switchImg = viewData.switchImg
    switchImg:setTexture(isSelect and RES_DIR.CLOSE or RES_DIR.OPEN)
end

function SummerActivityStoryView:updateRightUIShowState(isShowDesc)
    local viewData = self:getViewData()
    local descLayer = viewData.descLayer
    local reviewBtn = viewData.reviewBtn

    descLayer:setVisible(isShowDesc)
    reviewBtn:setVisible(isShowDesc)

    local emptyLayer = viewData.emptyLayer
    emptyLayer:setVisible(not isShowDesc)
end

CreateView = function ()
    local view = display.newLayer()
    view:addChild(display.newLayer(0, 0, {color = cc.c4b(0, 0, 0, 150), enable = true}))
    
    local size = cc.size(1046,637)
    local cview = display.newLayer(display.cx, display.cy, {ap = display.CENTER, size = size})
    view:addChild(cview)

    local bg = display.newImageView(_res("ui/home/story/task_bg.png"), size.width* 0.5 - 20, size.height* 0.5)
	cview:addChild(bg)

    local closeBtn = display.newButton(size.width, size.height, {n = _res('ui/home/story/task_btn_quit.png')})
    display.commonUIParams(closeBtn, {ap = display.RIGHT_TOP,po = cc.p(size.width + 36, size.height - 28)})
    cview:addChild(closeBtn, 10)

    local tabs = {}

    --主线剧情
    local storyButton = CreateTab(summerActMgr:getThemeTextByText(__('主线 剧情')))
    display.commonUIParams(storyButton, {ap = display.LEFT_BOTTOM, po = cc.p(62, 558)})
    tabs[tostring(TAB_TAG.STORY)] = storyButton
    cview:addChild(storyButton)

    --支线剧情  
    local branchButton = CreateTab(summerActMgr:getThemeTextByText(__('支线 剧情')))
    display.commonUIParams(branchButton, {ap = display.LEFT_BOTTOM, po = cc.p(storyButton:getPositionX() + 218, 558)})
    tabs[tostring(TAB_TAG.BRANCH)] = branchButton
    cview:addChild(branchButton)

    local listLayoutSize = cc.size(435, 506)
    local listLayout = CLayout:create(listLayoutSize)
    listLayout:setAnchorPoint(display.LEFT_BOTTOM)
    listLayout:setPosition(cc.p(55, 50))
    cview:addChild(listLayout)
    -- listLayout:setBackgroundColor(cc.c4b(0, 100, 0, 255))

    --滑动层背景图 
    local listBg = display.newImageView(_res('ui/home/story/commcon_bg_text.png'), 0, 0, {ap = display.LEFT_BOTTOM})	
    listLayout:addChild(listBg)

    -- 添加列表功能
    local taskListSize = cc.size(listLayoutSize.width , listLayoutSize.height - 10)
    local taskListCellSize = cc.size(taskListSize.width, 90)
    local gridView = CGridView:create(taskListSize)
    gridView:setSizeOfCell(taskListCellSize)
    gridView:setColumns(1)
    gridView:setAutoRelocate(true)
    listLayout:addChild(gridView)
    display.commonUIParams(gridView, {ap = display.LEFT_BOTTOM, po = cc.p(listBg:getPositionX() + 1, listBg:getPositionY()  + 2 )})
    gridView:setVisible(false)
    -- gridView:setBackgroundColor(cc.c4b(0, 128, 0, 100))

    local listView = CListView:create(taskListSize)
    listView:setDirection(eScrollViewDirectionVertical)
    listView:setBounceable(true)
    listLayout:addChild(listView)
    listView:setAnchorPoint(display.LEFT_BOTTOM)
    listView:setPosition(cc.p(listBg:getPositionX() + 1, listBg:getPositionY()  + 2 ))
    listView:setVisible(false)

    -------------------------------------------
    -- 右侧描述

    local messLayoutSize = cc.size(444, 460)
    local messLayout = CLayout:create(messLayoutSize)
    messLayout:setAnchorPoint(display.LEFT_BOTTOM)
    messLayout:setPosition(cc.p(510, 130))
    -- messLayout:setBackgroundColor(cc.c4b(23, 67, 128, 128))
    cview:addChild(messLayout)

    local desbg = display.newImageView(_res('ui/home/story/gut_task_bg_task_details.png'),0, 0,
        {ap = display.LEFT_BOTTOM, scale9 = true, size = messLayoutSize})
    messLayout:addChild(desbg)

    local descLayer = display.newLayer(messLayoutSize.width / 2, messLayoutSize.height / 2, {ap = display.CENTER, size = messLayoutSize})
    messLayout:addChild(descLayer)

    local desLabel = display.newLabel(messLayoutSize.width * 0.5, messLayoutSize.height - 60,
        fontWithColor(6,{text = ' ', ap = cc.p(0.5, 1), w = messLayoutSize.width - 100, h = messLayoutSize.height - 80}))
    descLayer:addChild(desLabel, 6)

    local tempLabelSize = cc.size(239,37)
    local tempLabel = display.newButton(messLayoutSize.width / 2 + 40, messLayoutSize.height - 40,{n = _res('ui/home/story/task_bg_title.png'), enable = false, scale9 = true, size = tempLabelSize, ap = display.CENTER_BOTTOM})
    display.commonLabelParams(tempLabel, fontWithColor(4, {text = summerActMgr:getThemeTextByText(__('剧情描述')), offset = cc.p(-40, 0)}))
    descLayer:addChild(tempLabel)
    
    local tempLabelSize1 = display.getLabelContentSize(tempLabel:getLabel())
    if (tempLabelSize1.width + 80) > tempLabelSize.width then
        tempLabel:setContentSize(cc.size(tempLabelSize1.width + 100, tempLabelSize.height))
    end

    local emptyLayer = display.newLayer(messLayoutSize.width / 2, messLayoutSize.height / 2, {ap = display.CENTER, size = messLayoutSize})
    messLayout:addChild(emptyLayer)
    emptyLayer:setVisible(false)

    emptyLayer:addChild(display.newImageView(RES_DIR.SUMMER_ACTIVITY_QBAN, messLayoutSize.width / 2, messLayoutSize.height / 2, {ap = display.CENTER}))
    emptyLayer:addChild(display.newLabel(messLayoutSize.width / 2, 60, fontWithColor(16, {text = summerActMgr:getThemeTextByText(__('请选择剧情'))})))

    local reviewBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_orange.png')})
    display.commonLabelParams(reviewBtn, fontWithColor(14, {text = summerActMgr:getThemeTextByText(__('回看'))}))
    display.commonUIParams(reviewBtn, {ap = display.CENTER_BOTTOM, po = cc.p(732 ,50)})
    cview:addChild(reviewBtn)
    
    -- -- right UI empty
    -- local rightUIEmptyLayout = display.newLayer(display.cx, display.cy, {ap = display.CENTER, size = size})
    -- view:addChild(rightUIEmptyLayout)



    return {
        view          = view,
        closeBtn      = closeBtn,
        gridView      = gridView,
        listView      = listView,
        messLayout    = messLayout,
        reviewBtn     = reviewBtn,
        tabs          = tabs,
        desLabel      = desLabel,
        emptyLayer    = emptyLayer,
        descLayer     = descLayer
    }
end

CreateTab = function (text)
    local tab = display.newButton(0, 0, {n = RES_DIR.TAB_UNUSED, scale9 = true, size = cc.size(218, 50)})
    display.commonLabelParams(tab, fontWithColor(16, {text = text, ap = cc.p(0.5, 0.5), fontSize = 18, w = 200, hAlign = display.TAC}))
    return tab
end

function SummerActivityStoryView:CreateChapterCell()
    local size = cc.size(435, 56)
    local cell = display.newLayer(0,0,{ap = display.CENTER, size = size})
    -- cell:setBackgroundColor(cc.c4b(23, 67, 128, 128))

    local btnImg = display.newButton(size.width / 2 - 2, size.height / 2, {n = RES_DIR.TASK_TITLE, ap = display.CENTER})
    cell:addChild(btnImg)

    local titleLabel = display.newLabel(44, size.height / 2, {fontSize = 22, color = '#9c4f16', ap = display.LEFT_CENTER})
    cell:addChild(titleLabel)

    local switchImg = display.newImageView(RES_DIR.OPEN, size.width - 40, size.height / 2, {ap = display.CENTER})
    cell:addChild(switchImg)

    cell.viewData = {
        btnImg  = btnImg,
        titleLabel  = titleLabel,
        switchImg  = switchImg,
    }

    return cell
end

function SummerActivityStoryView:getViewData()
    return self.viewData_
end

return SummerActivityStoryView
