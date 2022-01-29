--[[
 * author : kaishiqi
 * descpt : 2020周年庆 - 剧情回顾 中介者
]]
local Anniversary20StoryView     = require('Game.views.anniversary20.Anniversary20StoryView')
local Anniversary20StoryMediator = class('Anniversary20StoryMediator', mvc.Mediator)

local CHAPTER_UPDATE_TYPE = {
    SELECT = 'select',
    COUNT  = 'count',
}

local STORY_UPDATE_TYPE = {
}


function Anniversary20StoryMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'Anniversary20StoryMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance

function Anniversary20StoryMediator:Initial(key)
    self.super.Initial(self, key)

    -- init vars
    self.chapterArray_   = {}
    self.isControllable_ = true

    -- create view
    self.viewNode_ = Anniversary20StoryView.new()
    self:SetViewComponent(self:getViewNode())
    app.uiMgr:GetCurrentScene():AddDialog(self:getViewNode())

    -- add listener
    ui.bindClick(self:getViewData().blockLayer, handler(self, self.onClickCloseButtonHandler_))
    self:getViewData().chapterTableView:setCellUpdateHandler(handler(self, self.onUpdateChapterCellHandler_))
    self:getViewData().chapterTableView:setCellInitHandler(function(cellViewData)
        ui.bindClick(cellViewData.clickArea, handler(self, self.onClickChapterCellHandler_))
    end)
    self:getViewData().storyTableView:setCellUpdateHandler(handler(self, self.onUpdateStoryCellHandler_))
    self:getViewData().storyTableView:setCellInitHandler(function(cellViewData)
        ui.bindClick(cellViewData.clickArea, handler(self, self.onClickStoryCellHandler_))
    end)

    -- init data
    self:initAllStoryData_()
    self:setSelectChapterIndex(1)
end


function Anniversary20StoryMediator:CleanupView()
    if self:getViewNode() and not tolua.isnull(self:getViewNode()) then
        self:getViewNode():removeFromParent()
        self.viewNode_ = nil
    end
end


function Anniversary20StoryMediator:OnRegist()
end


function Anniversary20StoryMediator:OnUnRegist()
end


function Anniversary20StoryMediator:InterestSignals()
    return {}
end
function Anniversary20StoryMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()
end


-------------------------------------------------
-- get / set

function Anniversary20StoryMediator:getViewNode()
    return  self.viewNode_
end
function Anniversary20StoryMediator:getViewData()
    return self:getViewNode():getViewData()
end


function Anniversary20StoryMediator:getChapterArray()
    return checktable(self.chapterArray_)
end


function Anniversary20StoryMediator:getSelectChapterIndex()
    return checkint(self.selectChapterIndex_)
end
function Anniversary20StoryMediator:setSelectChapterIndex(index)
    local oldSelectIndex     = self.selectChapterIndex_
    self.selectChapterIndex_ = checkint(index)
    -- update customer status
    self:getViewData().chapterTableView:updateCellViewData(oldSelectIndex, nil, CHAPTER_UPDATE_TYPE.SELECT)
    self:getViewData().chapterTableView:updateCellViewData(self.selectChapterIndex_, nil, CHAPTER_UPDATE_TYPE.SELECT)
    -- update current storyDatas
    self:getViewData().storyTableView:resetCellCount(#self:getCurrentStoryArray())
end


function Anniversary20StoryMediator:getCurrentStoryArray()
    local chapterData = self:getChapterArray()[self:getSelectChapterIndex()] or {}
    return checktable(chapterData.storyArray)
end


function Anniversary20StoryMediator:getUnlockStoryCount(chapterId)
    local unlockCount = 0
    for chapterIndex, chapterData in ipairs(self:getChapterArray()) do
        if checkint(chapterId) == checkint(chapterData.chapterId) then
            for _, storyData in ipairs(chapterData.storyArray) do
                if storyData.isUnlock then
                    unlockCount = unlockCount + 1
                end
            end
            break
        end
    end
    return unlockCount
end


-------------------------------------------------
-- public

function Anniversary20StoryMediator:close()
    app:UnRegsitMediator(self:GetMediatorName())
end


-------------------------------------------------
-- private

function Anniversary20StoryMediator:initAllStoryData_()
    self.chapterArray_ = {}
    local tempStoryMap = {}
    for _, storyId in ipairs(CONF.ANNIV2020.STORY_COLLECTION:GetIdListUp()) do
        local storyConf = CONF.ANNIV2020.STORY_COLLECTION:GetValue(storyId)
        tempStoryMap[tostring(storyConf.chapterId)] = tempStoryMap[tostring(storyConf.chapterId)] or {}
        table.insert(tempStoryMap[tostring(storyConf.chapterId)], {
            isUnlock  = app.anniv2020Mgr:isStoryUnlocked(storyConf.id),
            storyConf = storyConf,
        })
    end

    local allChapterIdList = table.keys(tempStoryMap)
    table.sort(allChapterIdList, function(a, b)
        return checkint(a) < checkint(b)
    end)
    for index, chapterId in ipairs(allChapterIdList) do
        self.chapterArray_[index] = {
            chapterId  = checkint(chapterId),
            storyArray = tempStoryMap[tostring(chapterId)],
        }
    end

    self:getViewData().chapterTableView:resetCellCount(#self.chapterArray_)
end


-------------------------------------------------
-- handler

function Anniversary20StoryMediator:onClickCloseButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    self:close()
end


function Anniversary20StoryMediator:onUpdateChapterCellHandler_(cellIndex, cellViewData, updateType)
    if cellViewData == nil then return end

    local chapterData = self:getChapterArray()[cellIndex]
    local storyArray  = checktable(chapterData.storyArray)

    if updateType == nil then
        cellViewData.clickArea:setTag(cellIndex)
        self:getViewNode():updateChapterInfo(cellViewData, chapterData.chapterId, checktable(storyArray[1]).storyConf.chapterName)
    end

    if updateType == nil or updateType == CHAPTER_UPDATE_TYPE.SELECT then
        self:getViewNode():updateChapterSelectState(cellViewData, cellIndex == self:getSelectChapterIndex())
    end

    if updateType == nil or updateType == CHAPTER_UPDATE_TYPE.COUNT then
        self:getViewNode():updateChapterStoryCount(cellViewData, #storyArray, self:getUnlockStoryCount(chapterData.chapterId))
    end
end


function Anniversary20StoryMediator:onClickChapterCellHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local chapterIndex = checkint(sender:getTag())
    self:setSelectChapterIndex(chapterIndex)
end


function Anniversary20StoryMediator:onUpdateStoryCellHandler_(cellIndex, cellViewData)
    if cellViewData == nil then return end
    
    local storyData = self:getCurrentStoryArray()[cellIndex]
    local isUnlock  = storyData.isUnlock == true
    local storyConf = storyData.storyConf or {}
    
    cellViewData.clickArea:setTag(cellIndex)
    
    self:getViewNode():updateStoryTitle(cellViewData, storyConf.name)
    
    self:getViewNode():updateStoryUnlockStatus(cellViewData, isUnlock)
end


function Anniversary20StoryMediator:onClickStoryCellHandler_(sender)
    PlayAudioByClickNormal()
    if not self.isControllable_ then return end

    local storyIndex = checkint(sender:getTag())
    local storyData  = self:getCurrentStoryArray()[storyIndex]
    local isUnlock   = storyData.isUnlock == true
    local storyConf  = storyData.storyConf or {}

    if isUnlock then
        app.anniv2020Mgr:playStory(storyConf.storyId)
    else
        app.uiMgr:ShowInformationTips(__('该剧情还未解锁'))
    end
end


return Anniversary20StoryMediator
