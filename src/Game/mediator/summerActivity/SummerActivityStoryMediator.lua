--[[
剧情任务图鉴会看Mediator
--]]
local Mediator = mvc.Mediator
local NAME = 'summerActivity.SummerActivityStoryMediator'
---@class SummerActivityStoryMediator :Mediator
local SummerActivityStoryMediator = class(NAME, Mediator)

local appIns = AppFacade.GetInstance() 
---@type UIManager
local uiMgr = appIns:GetManager("UIManager")
---@type GameManager
local gameMgr = appIns:GetManager("GameManager")
---@type SummerActivityManager
local summerActMgr = appIns:GetManager("SummerActivityManager")

local TAB_TAG = {
    STORY   = 1,
    BRANCH  = 2,
}

local StoryMissionsCell = require('home.StoryMissionsCell')
function SummerActivityStoryMediator:ctor(params, viewComponent)
    self.super:ctor(NAME,viewComponent)
    self.ctorArgs_ = checktable(params)
    -- logInfo.add(5, tableToString(self.ctorArgs_))

    self.mainStory = self.ctorArgs_.mainStory or {}
    self.branchStory = self.ctorArgs_.branchStory or {}

	self.storyDatas = {} --主线。支线本地数据
	
	self.clickTag = 1 --点击显示1 主线剧情，或者 2 支线剧情任务
	self.preIndex = 1
    
end


function SummerActivityStoryMediator:InterestSignals()
	local signals = {
	}

	return signals
end

function SummerActivityStoryMediator:ProcessSignal(signal )
	local name = signal:GetName() 
end

function SummerActivityStoryMediator:Initial( key )
	self.super.Initial(self,key)
	local scene = uiMgr:GetCurrentScene()
	local viewComponent  = require('Game.views.summerActivity.SummerActivityStoryView').new()
	self:SetViewComponent(viewComponent)
    display.commonUIParams(viewComponent, {po = display.center, ap = display.CENTER})
    scene:AddDialog(viewComponent)
    
    self.viewData_ = viewComponent:getViewData()

    self.chapterId = '1'

    -- init view
    self:initView_()
end

function SummerActivityStoryMediator:initView_()
    local viewData = self:getViewData()
    local closeBtn = viewData.closeBtn
    display.commonUIParams(closeBtn, {cb = handler(self, self.onCloseViewAction)})

    local reviewBtn    = viewData.reviewBtn
    display.commonUIParams(reviewBtn, {cb = handler(self, self.onReviewBtnAction)})

    local gridView     = viewData.gridView
    gridView:setDataSourceAdapterScriptHandler(handler(self,self.onDataSourceAction))

    local listView     = viewData.listView

    local tabs         = viewData.tabs
    for tag, tab in pairs(tabs) do
        display.commonUIParams(tab, {cb = handler(self,self.tabButtonAction)})
        tab:setTag(checkint(tag))

        if checkint(tag) == self.clickTag then
            self:GetViewComponent():updateTab(tab, true)
            self:updateList(self.clickTag)
            self:GetViewComponent():updateDesLabel(self:getDes(self.preIndex))

        end
    end
    
end

function SummerActivityStoryMediator:initBranchList()
    local viewData = self:getViewData()
    local listView = viewData.listView
    local datas = self.storyDatas[self.clickTag]

    for i, data in ipairs(datas) do
        local chapterId = data.chapterId
        local chapterData = summerActMgr:GetSummerChapterByChapterId(chapterId)
        local chapterCell = self:GetViewComponent():CreateChapterCell()
        local chapterCellViewData = chapterCell.viewData
        local btnImg = chapterCellViewData.btnImg
        display.commonUIParams(btnImg, {cb = handler(self, self.onClickBtnImgAction)})
        btnImg:setTag(i)
        btnImg:setUserTag(i)

        local titleLabel = chapterCellViewData.titleLabel
        display.commonLabelParams(titleLabel, {text = tostring(chapterData.name)})

        listView:insertNodeAtLast(chapterCell)
    end
    listView:reloadData()
end

function SummerActivityStoryMediator:updateBranchList(chapterIndex)
    local viewData = self:getViewData()
    local listView = viewData.listView
    
    if checkint(self.selectChapterIndex) == checkint(chapterIndex) then
        return
    end
    self.selectChapterIndex = chapterIndex
	self.selectSecondModel = 0
    if self.insertNode then
		-- print('removeNode')
		listView:removeNode(self.insertNode)
		self.insertNode = nil
	end

    local datas = self.storyDatas[self.clickTag]

    if datas == nil then return end
    -- 
    local chapterData = datas[chapterIndex]
    local branchStoryConfData = chapterData.branchStoryConfData
    -- logInfo.add(5, tableToString(branchStoryConfData))

    local num = table.nums(branchStoryConfData)
    if num == 0 then return end

    local size = cc.size(435, 90)
    local cellSize = cc.size(size.width, size.height * num)
    local cell = CLayout:create(cellSize)
    -- cell:setBackgroundColor(cc.c4b(23, 67, 128, 128))
    for i, v in ipairs(branchStoryConfData) do
        local missionCell = StoryMissionsCell.new()
        display.commonUIParams(missionCell, {ap = display.CENTER_BOTTOM, po = cc.p(cellSize.width * 0.5 - 2, cellSize.height - i * size.height)})
        missionCell.redPointImg:setVisible(false)
        missionCell.toggleView:setOnClickScriptHandler(handler(self,self.branchCellButtonAction))
        missionCell.toggleView:setTag(i)
        missionCell.eventnode:setPosition(cc.p(size.width* 0.5 - 2, size.height * 0.5))
        display.commonLabelParams(missionCell.labelName, {text = string.format('%s%s', summerActMgr:getThemeTextByText(__('【支线】 ')), tostring(v.name))})

        missionCell:setTag(i)
        cell:addChild(missionCell)
        
        local isLock = checktable(self.branchStory[tostring(chapterData.chapterId)])[tostring(v.storyId)] ~= nil
        missionCell.unlockImg:setVisible(not isLock)
        missionCell.lockImg:setVisible(not isLock)
    end

    self.insertNode = cell
    self.insertNode:setTag(chapterIndex)
    listView:insertNode(cell, chapterIndex)
    listView:reloadData()
end

function SummerActivityStoryMediator:onDataSourceAction(p_convertview,idx)
    local pCell = p_convertview
    local pButton = nil
    local index = idx + 1
    local viewData = self:getViewData()

    if pCell == nil then
        local sizee = cc.size(440,90)
        pCell = StoryMissionsCell.new()
        pCell.toggleView:setOnClickScriptHandler(handler(self,self.cellButtonAction))
        pCell.eventnode:setPosition(cc.p(sizee.width* 0.5 - 2,sizee.height * 0.5))
        pCell.redPointImg:setVisible(false)

        display.commonUIParams(pCell.labelName, {ap = display.LEFT_CENTER, po = cc.p(24, 0)})
        -- pCell.labelName:setPositionY(pCell:getContentSize().height - 10)
    else
        -- pCell.selectImg:setVisible(false)
        -- pCell.eventnode:setPosition(cc.p(sizee.width* 0.5 - 2,sizee.height * 0.5))
    end
    xTry(function()
        pCell.toggleView:setTag(index)
        pCell:setTag(index)
        
        pCell.selectImg:setVisible(index == self.preIndex)
        
        local datas = self.storyDatas[self.clickTag]
        if datas then
            local data = datas[index] or {}
            display.commonLabelParams(pCell.labelName, {fontSize = 18, text = string.format('%s%s',summerActMgr:getThemeTextByText( __('【主线】 ')), tostring(data.name)), w = 340, h = 150})

            local isLock = self.mainStory[tostring(data.storyId)] ~= nil
            pCell.unlockImg:setVisible(not isLock)
            pCell.lockImg:setVisible(not isLock)
        end

    end,__G__TRACKBACK__)
    return pCell
    
end

function SummerActivityStoryMediator:updateList(tag)
    local data, isFirstInit = self:getStoryDataByTag(tag)
    if next(data) == nil then return end

    local viewData = self:getViewData()
    local gridView = viewData.gridView
    local listView = viewData.listView
    
    if tag == TAB_TAG.STORY then
        gridView:setVisible(true)
        listView:setVisible(false)
        
        if isFirstInit then
            gridView:setCountOfCell(#data)
            gridView:reloadData()
        else
            self:GetViewComponent():updateRightUIShowState(true)
            self:GetViewComponent():updateDesLabel(self:getDes(self.preIndex))
        end
        
    elseif tag == TAB_TAG.BRANCH then
        gridView:setVisible(false)
        listView:setVisible(true)
        
        self:GetViewComponent():updateRightUIShowState(false)
        if isFirstInit then
            self:initBranchList()
        elseif checkint(self.selectSecondModel) > 0 then
            self:GetViewComponent():updateRightUIShowState(true)
            self:GetViewComponent():updateDesLabel(self:getDes(self.selectSecondModel))
        end
        
    end
end

function SummerActivityStoryMediator:getStoryDataByTag(tag)
    if self.storyDatas[tag] then return self.storyDatas[tag] end

    if tag == TAB_TAG.STORY then
        self.storyDatas[tag] = summerActMgr:GetMainStoryConfDatas()
    elseif tag == TAB_TAG.BRANCH then
        self.storyDatas[tag] = summerActMgr:GetBranchStoryConfDatas()
    end
    return self.storyDatas[tag], true
end

function SummerActivityStoryMediator:CleanupView()
    local viewComponent = self:GetViewComponent()
    local scene =  uiMgr:GetCurrentScene()
    if scene and viewComponent and not tolua.isnull(viewComponent) then
        scene:RemoveDialog(viewComponent)
    end
end

function SummerActivityStoryMediator:OnRegist(  )
end
function SummerActivityStoryMediator:OnUnRegist(  )
    self.storyDatas = nil
end

function SummerActivityStoryMediator:getViewData()
    return self.viewData_
end

function SummerActivityStoryMediator:tabButtonAction(sender)
    local tag = sender:getTag()
    if self.clickTag == tag then return end
    local senderLabel = sender:getChildByTag(1)
    if self:getViewData().tabs[tostring(self.clickTag)] then
        self:GetViewComponent():updateTab(self:getViewData().tabs[tostring(self.clickTag)], false)
    end
    self:GetViewComponent():updateTab(sender, true)
    self.clickTag = tag

    -- self:GetViewComponent():updateRightUIShowState(tag == TAB_TAG.STORY)

    self:updateList(tag)
end

function SummerActivityStoryMediator:onClickBtnImgAction(sender)
    local chapterIndex = sender:getTag()
    
    local viewData = self:getViewData()
    local listView = viewData.listView
    if checkint(self.selectChapterIndex) == checkint(chapterIndex) then
        if self.insertNode then
            
            listView:removeNode(self.insertNode)
            self.insertNode = nil

            listView:reloadData()

            local node = listView:getNodeAtIndex(checkint(chapterIndex) - 1)
            if node and node.viewData then
                self:GetViewComponent():updateSwitchImg(node.viewData, false)
            end

            self:GetViewComponent():updateRightUIShowState(false)
            self.selectChapterIndex = 0
            self.selectSecondModel = 0
        end

        return 
    end
    
    local nodes = listView:getNodes()
    for i, node in ipairs(nodes) do
        local chapterCellViewData = node.viewData
        if chapterCellViewData and chapterCellViewData.btnImg then
            local btnImg = chapterCellViewData.btnImg
            local cIndex = checkint(btnImg:getUserTag())
            if cIndex == checkint(self.selectChapterIndex) then
                self:GetViewComponent():updateSwitchImg(chapterCellViewData, false)
            elseif cIndex == checkint(chapterIndex) then
                self:GetViewComponent():updateSwitchImg(chapterCellViewData, true)
            end
        end
    end
    self:updateBranchList(chapterIndex)
    listView:setContentOffsetToTop()
    
    self.selectSecondModel = 1
    local cell = self.insertNode:getChildByTag(self.selectSecondModel)
    if cell then
        cell.selectImg:setVisible(true)
    end

    self:GetViewComponent():updateRightUIShowState(true)
    self:GetViewComponent():updateDesLabel(self:getDes(self.selectSecondModel))
    
end

--[[
列表的单元格按钮的事件处理逻辑
@param sender button对象
--]]
function SummerActivityStoryMediator:cellButtonAction(sender)
	local viewData = self:getViewData()
	local gridView = viewData.gridView
    local index = sender:getTag()
    if index == self.preIndex then return end
    local cell = gridView:cellAtIndex(index- 1)
    if cell then
        cell.selectImg:setVisible(true)
    end 
    --更新按钮状态
    local oldCell = gridView:cellAtIndex(self.preIndex - 1)
    if oldCell then
        oldCell.selectImg:setVisible(false)
    end
    self.preIndex = index
    self:GetViewComponent():updateDesLabel(self:getDes(index))

end

function SummerActivityStoryMediator:branchCellButtonAction(sender)
    local tag = checkint(sender:getTag())

    if checkint(self.selectSecondModel) == tag then return end
    
    if self.insertNode == nil then return end
    
    local cell = self.insertNode:getChildByTag(tag)
    if cell then
        cell.selectImg:setVisible(true)
    end 
    
    local oldCell = self.insertNode:getChildByTag(self.selectSecondModel)
    if oldCell then
        oldCell.selectImg:setVisible(false)
    end

    self.selectSecondModel = tag

    self:GetViewComponent():updateDesLabel(self:getDes(tag))
end

function SummerActivityStoryMediator:getDes(index)
    local des = ''
    
    local storyData = self.storyDatas[self.clickTag]
    local storyId = nil
    local isLock = false
    if self.clickTag == TAB_TAG.STORY then
        local data = storyData[index]
        des = data.resume
        storyId = data.storyId
        isLock = self.mainStory[tostring(storyId)] ~= nil
    elseif self.clickTag == TAB_TAG.BRANCH then
        local data = storyData[self.selectChapterIndex] or {}
        local branchStoryConfData = data.branchStoryConfData or {}

        if next(branchStoryConfData) ~= nil then
            local confData = branchStoryConfData[index]
            des = confData.resume
            storyId = confData.storyId
            
            isLock = checktable(self.branchStory[tostring(data.chapterId)])[tostring(storyId)] ~= nil
        end
    end

    local viewData = self:getViewData()
    local reviewBtn = viewData.reviewBtn
    reviewBtn:setVisible(isLock)



    self.storyId = storyId

    return des
end

function SummerActivityStoryMediator:onReviewBtnAction(sender)
    -- local path = string.format("conf/%s/summerActivity/summerStory.json",i18n.getLang())
    -- self:showOperaStage(self.storyId, path)
    summerActMgr:ShowOperaStage(self.storyId, nil, 1)
end

function SummerActivityStoryMediator:onCloseViewAction(sender)
    appIns:UnRegsitMediator(NAME)
end

return SummerActivityStoryMediator
