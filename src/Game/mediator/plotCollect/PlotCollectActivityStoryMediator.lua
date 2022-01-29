--[[
活动剧情回顾mediator
--]]
local Mediator = mvc.Mediator
---@class PlotCollectActivityStoryMediator :Mediator
local PlotCollectActivityStoryMediator = class("PlotCollectActivityStoryMediator", Mediator)
local NAME = "plotCollect.PlotCollectActivityStoryMediator"

------------ define ------------
local uiMgr = app.uiMgr
local ACTIVITY_STORY_TYPE_DATA = CommonUtils.GetConfigAllMess('historyActivityStoryType', 'plot') or {}
local ACTIVITY_CATALOGUE_DATA = CommonUtils.GetConfigAllMess('historyActivityCatalogue', 'plot') or {}
local ACTIVITY_STORY_CATALOGUE_DATA = CommonUtils.GetConfigAllMess('historyActivityStoryCatalogue', 'plot') or {}
local HISTORY_ACTIVITY_STORY_INCLUDE_DATA = CommonUtils.GetConfigAllMess('historyActivityStoryInclude', 'plot') or {}

------------ define ------------

function PlotCollectActivityStoryMediator:ctor(param ,  viewComponent )
    self.super:ctor(NAME,viewComponent)
end

function PlotCollectActivityStoryMediator:InterestSignals()
    local signals = {
    }
    return signals
end

function PlotCollectActivityStoryMediator:ProcessSignal( signal )
    local name = signal:GetName()
end

function PlotCollectActivityStoryMediator:Initial( key )
    self.super.Initial(self, key)

    self.datas = {}
    self.curSelectTabIndex = 1
    self.curSelectActivityIndex = 1
    self.curSelectChapterIndex = 1

    ---@type PlotCollectActivityStoryView
    local viewComponent  = require('Game.views.plotCollect.PlotCollectActivityStoryView').new()
    self.viewData_      = viewComponent:getViewData()
    self:SetViewComponent(viewComponent)
    display.commonUIParams(viewComponent, {ap = display.CENTER, po = display.center})

    self.ownerScene_ = uiMgr:GetCurrentScene()
    self:GetOwnerScene():AddDialog(viewComponent)

    self:InitData_()

    self:InitView_()

end

function PlotCollectActivityStoryMediator:CleanupView()
    local viewComponent = self:GetViewComponent()
    if self.ownerScene_ and viewComponent and not tolua.isnull(viewComponent) then
        self.ownerScene_:RemoveDialog(viewComponent)
        self.ownerScene_ = nil
    end
end

function PlotCollectActivityStoryMediator:OnRegist()
end

function PlotCollectActivityStoryMediator:OnUnRegist()

end

---------------------------------------------------
--- init data begin --
---------------------------------------------------

function PlotCollectActivityStoryMediator:InitData_()

    --  init tab data
    local tabDatas = {}
    for i, conf in pairs(ACTIVITY_STORY_TYPE_DATA) do
        table.insert(tabDatas, conf)
    end

    local sortFunc = function(a, b)
        return checkint(a.sort) < checkint(b.sort)
    end

    if next(tabDatas) then
        table.sort(tabDatas, sortFunc)
    end
    self.tabDatas = tabDatas

    self.catalogueDatas = ACTIVITY_CATALOGUE_DATA

    self.storyChapterConfDatas = ACTIVITY_STORY_CATALOGUE_DATA

    self.storyConfDatas = HISTORY_ACTIVITY_STORY_INCLUDE_DATA
end

---------------------------------------------------
--- init data end --
---------------------------------------------------

---------------------------------------------------
--- ui logic begin --
---------------------------------------------------

function PlotCollectActivityStoryMediator:InitView_()
    local viewData     = self:GetViewData()
    local shallowLayer = viewData.shallowLayer
    display.commonUIParams(shallowLayer, {cb = handler(self, self.OnCloseAction)})

    local labelCount = #self.tabDatas
    local labelTableView  = viewData.labelTableView
    labelTableView:setDataSourceAdapterScriptHandler(handler(self, self.OnLabelTableViewDataAdapter))
    labelTableView:setCountOfCell(labelCount)
    labelTableView:setBounceable(labelCount >= 5)
    labelTableView:reloadData()


    local storyTableView  = viewData.storyTableView
    storyTableView:setDataSourceAdapterScriptHandler(handler(self, self.OnStoryTableViewDataAdapter))

    self:InitExpandableListView()
end

---InitExpandableListView
---初始化活动列表
function PlotCollectActivityStoryMediator:InitExpandableListView()
    local viewData           = self:GetViewData()
    local expandableListView = viewData.expandableListView
    expandableListView:removeAllExpandableNodes()

    local tabData = self.tabDatas[self.curSelectTabIndex] or {}
    local catalogueData = self.catalogueDatas[tostring(tabData.id)] or {}
    local groupCeltSize = cc.size(410, 105)
    local viewComponent = self:GetViewComponent()

    for i, v in ipairs(catalogueData) do
        local storyChapterData = self.storyChapterConfDatas[tostring(v.id)] or {}
        local expandableNode = viewComponent:CreateActivityTypeCell(groupCeltSize)
        local expandableNodeViewData = expandableNode.viewData
        local touchView = expandableNodeViewData.touchView
        touchView:setTag(i)
        display.commonUIParams(touchView, {cb = handler(self, self.OnClickGroupCellAction)})
        expandableListView:insertExpandableNodeAtLast(expandableNode)

        local storyChapterCount = #storyChapterData
        viewComponent:UpdateGroupCell(expandableNodeViewData, v, storyChapterCount)
        --- 默认展开
        if i == self.curSelectActivityIndex then
            self:UpdateExpandableNodeShowState(expandableNode, storyChapterCount, i, storyChapterData)
        end
    end
    expandableListView:reloadData()
end

---UpdateExpandableNodeShowState
---
---@param expandableNode userdata      活动列表节点
---@param storyChapterCount number   剧情组个数
---@param groupIndex number            是否选中
---@param storyChapterData table
function PlotCollectActivityStoryMediator:UpdateExpandableNodeShowState(expandableNode, storyChapterCount, groupIndex, storyChapterData)
    local expandableNodeViewData = expandableNode.viewData

    local viewComponent = self:GetViewComponent()
    local isSelect = self.curSelectActivityIndex == groupIndex
    if isSelect then
        if storyChapterCount > 1 then
            self:UpdateActivityCellExpandState(expandableNode, storyChapterData, storyChapterCount)
        else
            self:UpdateStoryListShowState(self:GetStoryIncludeList(self.curSelectChapterIndex))
            expandableNode:setExpanded(false)
            expandableNodeViewData.arrowIcon:setRotation(0)
        end
    else
        expandableNode:setExpanded(false)
        expandableNodeViewData.arrowIcon:setRotation(0)
    end
    expandableNodeViewData.selectImg:setVisible(isSelect)
end

---UpdateStoryListShowState
---更新剧情列表显示状态
---@param storyIncludeData table
function PlotCollectActivityStoryMediator:UpdateStoryListShowState(storyIncludeData)
    self:GetViewComponent():UpdateStoryList(storyIncludeData)
end

---CreateItemNode
---创建章节节点
---@param expandableNode userdata  活动cell节点
---@param storyChapterCount number 剧情章节个数
function PlotCollectActivityStoryMediator:CreateItemNode(expandableNode, storyChapterCount)
    local viewComponent = self:GetViewComponent()
    local height = 103 * storyChapterCount
    local groupCeltSize = expandableNode:getContentSize()
    local size = cc.size(groupCeltSize.width, height)
    local childNode = viewComponent:CreateChapterBg(size)
    for index = 1, storyChapterCount do
        local node = viewComponent:CreateChapterCell(cc.size(groupCeltSize.width - 15, 103))
        display.commonUIParams(node, {ap = display.CENTER_TOP, po = cc.p(size.width * 0.5, (storyChapterCount - index + 1) * 103 )})
        node:setTag(index)
        childNode:addChild(node)
        local nodeTouchView = node.viewData.touchView
        display.commonUIParams(nodeTouchView, {cb = handler(self, self.OnClickChapterCellAction)})
        nodeTouchView:setTag(index)
    end

    expandableNode:insertItemNodeAtLast(childNode)

    return childNode
end

---UpdateActivityCellExpandState
---更新活动cell展开状态
---@param expandableNode userdata  活动cell节点
---@param storyChapterData table     活动章节列表
---@param storyChapterCount number 活动章节个数
function PlotCollectActivityStoryMediator:UpdateActivityCellExpandState(expandableNode, storyChapterData, storyChapterCount)
    local itemNode = expandableNode:getItemNodeAtIndex(0)
    if itemNode == nil then
        itemNode = self:CreateItemNode(expandableNode, storyChapterCount)
    end

    local viewComponent = self:GetViewComponent()
    for i = 1, storyChapterCount do
        local chapterData = storyChapterData[i]
        local itemCell = itemNode:getChildByTag(i)
        --itemCell:setUserTag(chapterData.id)
        local storyIncludeData = self.storyConfDatas[tostring(chapterData.id)] or {}
        viewComponent:UpdateChapterCell(itemCell.viewData, chapterData, #storyIncludeData)

        local isSelectItem = self.curSelectChapterIndex == i
        if isSelectItem then
            self:UpdateStoryListShowState(storyIncludeData)
        end
        viewComponent:UpdateChapterBg(itemCell.viewData, isSelectItem)
    end

    local expandableNodeViewData = expandableNode.viewData
    expandableNodeViewData.arrowIcon:setRotation(90)
    expandableNode:setExpanded(true)
end

---------------------------------------------------
--- ui logic end --
---------------------------------------------------

---------------------------------------------------
--- data adapter begin --
---------------------------------------------------

---OnLabelTableViewDataAdapter
---活动类型数据适配器
---@param p_convertview userdata 活动类型cell
---@param idx number 下标 从0开始
function PlotCollectActivityStoryMediator:OnLabelTableViewDataAdapter(p_convertview, idx )
    local pCell = p_convertview
    local index = idx + 1

    local viewComponent = self:GetViewComponent()
    if pCell == nil then
        local labelTableView = self:GetViewData().labelTableView
        pCell = viewComponent:CreateLabelCell(labelTableView:getSizeOfCell())

        local tabBtn = pCell:getChildByName('tabBtn')
        display.commonUIParams(tabBtn, {cb = handler(self, self.OnClickTabBtnAction)})
    end

    local tabData = self.tabDatas[index]
    local tabBtn = pCell:getChildByName('tabBtn')
    tabBtn:setTag(index)
    viewComponent:UpdateTabBtn(tabBtn, index == self.curSelectTabIndex, tostring(tabData.name))

    return pCell
end

---OnStoryTableViewDataAdapter
---剧情列表数据适配器
---@param p_convertview userdata cell
---@param idx number 下标 从0开始
function PlotCollectActivityStoryMediator:OnStoryTableViewDataAdapter(p_convertview, idx )
    local pCell = p_convertview
    local index = idx + 1
    local viewComponent = self:GetViewComponent()
    if pCell == nil then
        local storyTableView = self:GetViewData().storyTableView
        pCell = viewComponent:CreateStoryCell(storyTableView:getSizeOfCell())
        display.commonUIParams(pCell.viewData.touchView, {cb = handler(self, self.OnClickStoryCellAction)})
    end

    xTry(function()

        local storyList = self:GetStoryIncludeList(self.curSelectChapterIndex)
        local viewData = pCell.viewData
        local data = storyList[index]
        viewComponent:UpdateStoryCell(viewData, storyList[index])

        viewData.touchView:setTag(checkint(data.id))
    end,__G__TRACKBACK__)

    return pCell
end

---------------------------------------------------
--- data adapter end --
---------------------------------------------------


---------------------------------------------------
--- click handler begin --
---------------------------------------------------

---OnClickTabBtnAction
---活动类型标签选择事件
---@param sender userdata 活动类型按钮
function PlotCollectActivityStoryMediator:OnClickTabBtnAction(sender)
    local index  = sender:getTag()
    if index == self.curSelectTabIndex then
        return
    end

    local viewComponent = self:GetViewComponent()
    local labelTableView = self:GetViewData().labelTableView
    local oldCell = labelTableView:cellAtIndex(self.curSelectTabIndex - 1)
    if oldCell then
        viewComponent:UpdateTabBtn(oldCell:getChildByName('tabBtn'), false)
    end

    local cell = labelTableView:cellAtIndex(index - 1)
    if cell then
        viewComponent:UpdateTabBtn(cell:getChildByName('tabBtn'), true)
    end
    self.curSelectTabIndex = index
    self.curSelectActivityIndex = 1
    self.curSelectChapterIndex = 1

    --- todo 刷新活动列表
    self:InitExpandableListView()
end


---OnClickGroupCellAction
---@param sender userdata
function PlotCollectActivityStoryMediator:OnClickGroupCellAction(sender)
    local index  = sender:getTag()
    if index == self.curSelectActivityIndex then return end

    local oldGroupIndex = self.curSelectActivityIndex
    self.curSelectActivityIndex = index
    self.curSelectChapterIndex = 1

    local tabData = self.tabDatas[self.curSelectTabIndex] or {}
    local catalogueData = self.catalogueDatas[tostring(tabData.id)] or {}
    local chapterId = catalogueData[index].id
    local storyChapterData = self.storyChapterConfDatas[tostring(chapterId)] or {}

    local viewData           = self:GetViewData()
    local expandableListView = viewData.expandableListView
    --- 收起旧的活动类型节点
    local oldExpandableNode = expandableListView:getExpandableNodeAtIndex(oldGroupIndex - 1)
    if oldExpandableNode then
        local oldNodeViewData = oldExpandableNode.viewData
        oldExpandableNode:setExpanded(false)
        oldNodeViewData.selectImg:setVisible(false)
        oldExpandableNode.viewData.arrowIcon:setRotation(0)
    end

    --- 展开新的活动类型节点 （多章节数据才展开）
    local newExpandableNode = expandableListView:getExpandableNodeAtIndex(index - 1)
    if newExpandableNode then
        local newNodeViewData = newExpandableNode.viewData
        newNodeViewData.selectImg:setVisible(true)

        local storyChapterCount = #storyChapterData
        if storyChapterCount > 1 then
            self:UpdateActivityCellExpandState(newExpandableNode, storyChapterData, storyChapterCount)
            
        else
            local storyIncludeId = checktable(storyChapterData[self.curSelectChapterIndex]).id
            local storyList = self.storyConfDatas[tostring(storyIncludeId)] or {}
            self:UpdateStoryListShowState(storyList)
        end
    end

    expandableListView:reloadData()
end

function PlotCollectActivityStoryMediator:OnClickChapterCellAction(sender)
    local index  = sender:getTag()
    if self.curSelectChapterIndex == index then return end

    local oldChapterIndex = self.curSelectChapterIndex
    self.curSelectChapterIndex = index

    local viewData           = self:GetViewData()
    local expandableListView = viewData.expandableListView
    local expandableNode = expandableListView:getExpandableNodeAtIndex(self.curSelectActivityIndex - 1)
    if expandableNode then
        local itemNode = expandableNode:getItemNodeAtIndex(0)
        local viewComponent = self:GetViewComponent()

        local oldCell = itemNode:getChildByTag(oldChapterIndex)
        if oldCell then
            viewComponent:UpdateChapterBg(oldCell.viewData, false)
        end

        local newCell = itemNode:getChildByTag(index)
        if newCell then
            viewComponent:UpdateChapterBg(newCell.viewData, true)
        end
    end

    local storyList = self:GetStoryIncludeList(index)
    self:UpdateStoryListShowState(storyList)
end

---OnClickStoryCellAction
---点击剧情cell事件
---@param sender userdata
function PlotCollectActivityStoryMediator:OnClickStoryCellAction(sender)
    local tabData = self.tabDatas[self.curSelectTabIndex]
    local storyName = tabData.tableName
    local storyId = checkint(sender:getTag())
    local path = string.format("conf/%s/plot/%s%s.json", i18n.getLang(), storyName, math.ceil(storyId / 100))
    local stage = require( "Frame.Opera.OperaStage" ).new({id = storyId, path = path, isReview = true, cb = function() end, isHideBackBtn = true})
    stage:setPosition(cc.p(display.cx,display.cy))
    sceneWorld:addChild(stage, GameSceneTag.Dialog_GameSceneTag)
end

---OnCloseAction
---关闭界面事件
---@param sender userdata 空白区域
function PlotCollectActivityStoryMediator:OnCloseAction(sender)
    app:UnRegsitMediator(NAME)
end

---------------------------------------------------
--- click handler end --
---------------------------------------------------

---------------------------------------------------
--- get set begin --
---------------------------------------------------

function PlotCollectActivityStoryMediator:GetViewData()
    return self.viewData_
end

function PlotCollectActivityStoryMediator:GetOwnerScene()
    return self.ownerScene_
end

---GetStoryIncludeList
---@param index number story catalogue index
---@return table story include list
function PlotCollectActivityStoryMediator:GetStoryIncludeList(index)
    local tabData = self.tabDatas[self.curSelectTabIndex] or {}
    local catalogueData = self.catalogueDatas[tostring(tabData.id)] or {}
    local chapterId = catalogueData[self.curSelectActivityIndex].id
    local storyChapterData = self.storyChapterConfDatas[tostring(chapterId)] or {}
    local storyIncludeId = storyChapterData[index].id
    local storyList = self.storyConfDatas[tostring(storyIncludeId)] or {}
    return storyList
end

---------------------------------------------------
--- get set end --
---------------------------------------------------

return PlotCollectActivityStoryMediator
