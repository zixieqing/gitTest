--[[
周年庆剧情mediator
--]]
local Mediator = mvc.Mediator
---@class Anniversary19StoryMeditaor :Mediator
local Anniversary19StoryMeditaor = class("Anniversary19StoryMeditaor", Mediator)
local NAME = "anniversary19.Anniversary19StoryMeditaor"

local uiMgr = app.uiMgr
local anniversaryManager = app.anniversaryMgr

function Anniversary19StoryMeditaor:ctor(param ,  viewComponent )
    self.super:ctor(NAME,viewComponent)
end

function Anniversary19StoryMeditaor:InterestSignals()
    local signals = {
    }
    return signals
end

function Anniversary19StoryMeditaor:ProcessSignal( signal )
    local name = signal:GetName()
end

function Anniversary19StoryMeditaor:Initial( key )
    self.super:Initial(key)
    
    self.datas = {}
    self.curSelectGroupIndex = 1

    ---@type Anniversary19StoryView
    local viewComponent  = require('Game.views.anniversary19.Anniversary19StoryView').new()
    self.viewData_      = viewComponent:GetViewData()
    self:SetViewComponent(viewComponent)
    display.commonUIParams(viewComponent, {ap = display.CENTER, po = display.center})

    self.ownerScene_ = uiMgr:GetCurrentScene()
    self:GetOwnerScene():AddDialog(viewComponent)

    self:InitGroupData_()
    self:InitView_()

end

-------------------------------------------------
-- private method

function Anniversary19StoryMeditaor:InitGroupData_()

    local mgr            = app.anniversary2019Mgr
    local homeData       = mgr:GetHomeData()
    local unlockStoryMap = homeData.unlockStoryMap or {}

    local datas = {}
	local storyCollectionConf = CommonUtils.GetConfigAllMess('storyCollection', 'anniversary2') or {}
    local tempGroupDatas = {}
    local chapterIds = {}
	for index, conf in orderedPairs(storyCollectionConf) do
        local chapterId = conf.chapterId
        local storyId = conf.storyId

        if tempGroupDatas[chapterId] == nil then
            table.insert(chapterIds, checknumber(chapterId))

            tempGroupDatas[chapterId] = {
                storyDatas       = {},
                storyCount       = 0,
                unlockStoryCount = 0,
                chapterId        = conf.chapterId,
                icon             = conf.icon,
                chapterName      = conf.chapterName,
            }
        end

        local storyDatas = tempGroupDatas[chapterId].storyDatas
        local storyData = {
            storyId = conf.storyId,
            name    = conf.name,
            resume  = conf.resume,
        }
        local unlockStoryId = unlockStoryMap[tostring(storyId)]
        if unlockStoryId then
            storyData.unlockStoryId = unlockStoryId
            tempGroupDatas[chapterId].unlockStoryCount = tempGroupDatas[chapterId].unlockStoryCount + 1
        end
        tempGroupDatas[chapterId].storyCount = tempGroupDatas[chapterId].storyCount + 1
        
        table.insert(storyDatas, storyData)
    end

    table.sort(chapterIds)

    for index, chapterId in ipairs(chapterIds) do
        table.insert(datas, tempGroupDatas[tostring(chapterId)])
    end
    self.datas = datas

end

function Anniversary19StoryMeditaor:InitView_()
    local viewData     = self:GetViewData()
    local shallowLayer = viewData.shallowLayer
    display.commonUIParams(shallowLayer, {cb = handler(self, self.OnCloseAction), animate = false})
    PlayAudioByClickClose()
    
    local groupTableView  = viewData.groupTableView
    groupTableView:setDataSourceAdapterScriptHandler(handler(self, self.GroupTableViewwDataAdapter))
    groupTableView:setCountOfCell(#self.datas)
    groupTableView:reloadData()

    viewData.storyTableView:setDataSourceAdapterScriptHandler(handler(self, self.StoryTableViewDataAdapter))
    self:GetViewComponent():UpdateStoryList(checktable(self.datas[self.curSelectGroupIndex]).storyDatas or {})
end

function Anniversary19StoryMeditaor:GroupTableViewwDataAdapter(p_convertview, idx )
    local pCell = p_convertview
    local index = idx + 1
    local viewComponent = self:GetViewComponent()
    if pCell == nil then
        local groupTableView = self:GetViewData().groupTableView
        pCell = viewComponent:CreateGroupCell(groupTableView:getSizeOfCell())
        display.commonUIParams(pCell.viewData.touchView, {cb = handler(self, self.OnClickGroupCellAction)})
    end

    xTry(function()
        local data = self.datas[index] or {}
        local viewData = pCell.viewData
        viewComponent:UpdateGroupCell(viewData, data, app.anniversary2019Mgr:GetResPath(string.format('ui/anniversary19/story/%s.png', 'wonderland_plot_icon_'..index)))
        viewComponent:UpdateGroupCellBg(viewData, self.curSelectGroupIndex == index)
        viewData.touchView:setTag(index)
    end,__G__TRACKBACK__)
    return pCell
end

function Anniversary19StoryMeditaor:StoryTableViewDataAdapter(p_convertview, idx )
    local pCell = p_convertview
    local index = idx + 1
    local viewComponent = self:GetViewComponent()
    if pCell == nil then
        local storyTableView = self:GetViewData().storyTableView
        pCell = viewComponent:CreateStoryCell(storyTableView:getSizeOfCell())
        display.commonUIParams(pCell.viewData.touchView, {cb = handler(self, self.OnClickStoryCellAction)})
    end

    xTry(function()
        local groupData  = self.datas[self.curSelectGroupIndex] or {}
        local storyDatas = groupData.storyDatas or {}
        local data       = storyDatas[index] or {}
        local viewData   = pCell.viewData
        viewComponent:UpdateStoryCell(viewData, data)
        
        viewData.touchView:setTag(index)
    end,__G__TRACKBACK__)

    return pCell
end

function Anniversary19StoryMeditaor:OnClickGroupCellAction(sender)
    PlayAudioByClickNormal()

    local tag  = sender:getTag()

    local viewComponent = self:GetViewComponent()
    viewComponent:UpdateGroupBgByIndex(self.curSelectGroupIndex, false)
    viewComponent:UpdateGroupBgByIndex(tag, true)

    self.curSelectGroupIndex = tag
    local data = self.datas[tag] or {}
    viewComponent:UpdateStoryList(data.storyDatas or {})

end

function Anniversary19StoryMeditaor:OnClickStoryCellAction(sender)
    PlayAudioByClickNormal()
    
    local tag = sender:getTag()
    -- todo 进入剧情
    local groupData   = self.datas[self.curSelectGroupIndex] or {}
    local storyDatas  = groupData.storyDatas or {}
    local data        = storyDatas[tag] or {}
    local unlockStoryId = data.unlockStoryId
    
    if unlockStoryId then
        app.anniversary2019Mgr:ShowOperaStage(unlockStoryId)
    else
        uiMgr:ShowInformationTips(tostring(data.resume))
    end

end

function Anniversary19StoryMeditaor:OnCloseAction()
    PlayAudioByClickClose()
    app:UnRegsitMediator(NAME)
end

-------------------------------------------------
-- get / set

function Anniversary19StoryMeditaor:GetViewData()
    return self.viewData_
end

function Anniversary19StoryMeditaor:GetOwnerScene()
    return self.ownerScene_
end

function Anniversary19StoryMeditaor:CleanupView()
    local viewComponent = self:GetViewComponent()
    if self.ownerScene_ and viewComponent and not tolua.isnull(viewComponent) then
        self.ownerScene_:RemoveDialog(viewComponent)
        self.ownerScene_ = nil
    end
end

function Anniversary19StoryMeditaor:OnRegist()
end

function Anniversary19StoryMeditaor:OnUnRegist()
    
end

return Anniversary19StoryMeditaor
