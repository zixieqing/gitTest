--[[
周年庆剧情mediator
--]]
local Mediator = mvc.Mediator
---@class AnniversaryStoryMeditaor :Mediator
local AnniversaryStoryMeditaor = class("AnniversaryStoryMeditaor", Mediator)
local NAME = "anniversary.AnniversaryStoryMeditaor"

local uiMgr = app.uiMgr
local anniversaryManager = app.anniversaryMgr

function AnniversaryStoryMeditaor:ctor(param ,  viewComponent )
    self.super:ctor(NAME,viewComponent)
end

function AnniversaryStoryMeditaor:InterestSignals()
    local signals = {
    }
    return signals
end

function AnniversaryStoryMeditaor:ProcessSignal( signal )
    local name = signal:GetName()
end

function AnniversaryStoryMeditaor:Initial( key )
    self.super:Initial(key)
    
    self.datas = {}
    self.curSelectGroupIndex = 1

    ---@type AnniversaryStoryView
    local viewComponent  = require('Game.views.anniversary.AnniversaryStoryView').new()
    self.viewData_      = viewComponent:getViewData()
    self:SetViewComponent(viewComponent)
    display.commonUIParams(viewComponent, {ap = display.CENTER, po = display.center})

    self.ownerScene_ = uiMgr:GetCurrentScene()
    self:getOwnerScene():AddDialog(viewComponent)

    self:initGroupData_()
    self:initView_()

end

-------------------------------------------------
-- private method

function AnniversaryStoryMeditaor:initGroupData_()
    local homeData = anniversaryManager:GetHomeData()
    local stroyRewards = homeData.stroyRewards or {}
    local stroyRewardsMap = {}
    for i, groupId in pairs(stroyRewards) do
        stroyRewardsMap[tostring(groupId)] = groupId
    end
    local storyMap = homeData.story or {}
    dump( homeData.story )
    local parserConfig = anniversaryManager:GetConfigParse()
    local groupConfDatas = anniversaryManager:GetConfigDataByName(parserConfig.TYPE.STORY_COLLECTION_GROUP) or {}
    if next(groupConfDatas) == nil then return end
    local storyCollectionConf = anniversaryManager:GetConfigDataByName(parserConfig.TYPE.STORY_COLLECTION) or {}
    local storyRewardsConf = anniversaryManager:GetConfigDataByName(parserConfig.TYPE.STORY_REWARDS) or {}
    local chapterId  =  anniversaryManager.homeData.chapters['1']
    local mianlineStoryMap = {}
    local chapterConfig = anniversaryManager:GetConfigDataByName(parserConfig.TYPE.CHAPTER)
    for i =1 , checkint(chapterId)  do
        local chapterOneConfig = chapterConfig[tostring(i)]
        mianlineStoryMap[tostring(chapterOneConfig.startStoryId)] = chapterOneConfig.startStoryId
        mianlineStoryMap[tostring(chapterOneConfig.inBossStoryId)] = chapterOneConfig.inBossStoryId
        mianlineStoryMap[tostring(chapterOneConfig.endBossStoryId)] = chapterOneConfig.endBossStoryId
    end
    for groupId, storyIds in orderedPairs(groupConfDatas) do
        local storyCount = 0
        local unlockStoryCount = 0
        local storyDatas = {}
        for i, storyId in ipairs(storyIds) do
            storyCount = storyCount + 1
            local storyConfData = storyCollectionConf[tostring(storyId)] or {}
            local data = {
                storyConfData = storyConfData
            }
            local unlockStoryId = storyMap[tostring(storyId)]
            if not  unlockStoryId then
                unlockStoryId = mianlineStoryMap[tostring(storyId)]
            end
            if unlockStoryId then
                unlockStoryCount   = unlockStoryCount + 1
                data.unlockStoryId = unlockStoryId
            end
            table.insert(storyDatas, data)
        end

        table.insert(self.datas, {
            storyDatas       = storyDatas,
            groupConfData    = storyRewardsConf[tostring(groupId)] or {},
            groupId          = groupId,
            storyCount       = storyCount,
            unlockStoryCount = unlockStoryCount,
        })
    end
    
end

function AnniversaryStoryMeditaor:initView_()
    local viewData     = self:getViewData()
    local shallowLayer = viewData.shallowLayer
    display.commonUIParams(shallowLayer, {cb = handler(self, self.onCloseAction)})
    
    local groupTableView  = viewData.groupTableView
    groupTableView:setDataSourceAdapterScriptHandler(handler(self, self.groupTableViewwDataAdapter))
    groupTableView:setCountOfCell(#self.datas)
    groupTableView:reloadData()

    local storyTableView  = viewData.storyTableView
    storyTableView:setDataSourceAdapterScriptHandler(handler(self, self.storyTableViewDataAdapter))
    self:GetViewComponent():updateStoryList(checktable(self.datas[self.curSelectGroupIndex]).storyDatas or {})
end

function AnniversaryStoryMeditaor:groupTableViewwDataAdapter(p_convertview, idx )
    local pCell = p_convertview
    local index = idx + 1
    if pCell == nil then
        local groupTableView = self:getViewData().groupTableView
        pCell = self:GetViewComponent():CreateGroupCell(groupTableView:getSizeOfCell())
        display.commonUIParams(pCell.viewData.touchView, {cb = handler(self, self.onClickGroupCellAction)})
    end

    xTry(function()
        local data = self.datas[index] or {}
        local viewData = pCell.viewData
        self:GetViewComponent():updateGroupCell(viewData, data)
        self:GetViewComponent():updateGroupCellBg(viewData, self.curSelectGroupIndex == index)
        viewData.touchView:setTag(index)
    end,__G__TRACKBACK__)
    return pCell
end

function AnniversaryStoryMeditaor:storyTableViewDataAdapter(p_convertview, idx )
    local pCell = p_convertview
    local index = idx + 1
    if pCell == nil then
        local storyTableView = self:getViewData().storyTableView
        pCell = self:GetViewComponent():CreateStoryCell(storyTableView:getSizeOfCell())
        display.commonUIParams(pCell.viewData.touchView, {cb = handler(self, self.onClickStoryCellAction)})
    end

    xTry(function()
        local groupData   = self.datas[self.curSelectGroupIndex] or {}
        local storyDatas  = groupData.storyDatas or {}
        local data        = storyDatas[index] or {}
        local viewData = pCell.viewData
        self:GetViewComponent():updateStoryCell(viewData, data)
        
        viewData.touchView:setTag(index)
    end,__G__TRACKBACK__)

    return pCell
end

function AnniversaryStoryMeditaor:onClickGroupCellAction(sender)
    local tag  = sender:getTag()

    local viewComponent = self:GetViewComponent()
    viewComponent:updateGroupBgByIndex(self.curSelectGroupIndex, false)
    viewComponent:updateGroupBgByIndex(tag, true)

    self.curSelectGroupIndex = tag
    local data = self.datas[tag] or {}
    viewComponent:updateStoryList(data.storyDatas or {})

end

function AnniversaryStoryMeditaor:onClickStoryCellAction(sender)
    local tag = sender:getTag()
    -- todo 进入剧情
    local groupData   = self.datas[self.curSelectGroupIndex] or {}
    local storyDatas  = groupData.storyDatas or {}
    local data        = storyDatas[tag] or {}
    local unlockStoryId = data.unlockStoryId
    
    if unlockStoryId then
        anniversaryManager:ShowOperaStage(unlockStoryId)
    else
        local conf = data.storyConfData or {}
        uiMgr:ShowInformationTips(tostring(conf.resume))
    end

end

function AnniversaryStoryMeditaor:onCloseAction(sender)
    app:UnRegsitMediator(NAME)
end

-------------------------------------------------
-- get / set

function AnniversaryStoryMeditaor:getViewData()
    return self.viewData_
end

function AnniversaryStoryMeditaor:getOwnerScene()
    return self.ownerScene_
end

function AnniversaryStoryMeditaor:CleanupView()
    local viewComponent = self:GetViewComponent()
    if self.ownerScene_ and viewComponent and not tolua.isnull(viewComponent) then
        self.ownerScene_:RemoveDialog(viewComponent)
        self.ownerScene_ = nil
    end
end

function AnniversaryStoryMeditaor:OnRegist()
end

function AnniversaryStoryMeditaor:OnUnRegist()
    
end

return AnniversaryStoryMeditaor
