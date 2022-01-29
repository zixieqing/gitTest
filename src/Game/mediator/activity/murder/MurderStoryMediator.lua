--[[
 * author : liuzhipeng
 * descpt : 杀人案（19夏活）剧情预览Mediator
--]]
local Mediator = mvc.Mediator
---@class MurderStoryMeditaor :Mediator
local MurderStoryMeditaor = class("MurderStoryMeditaor", Mediator)
local NAME = "Game.mediator.activity.murder.MurderStoryMeditaor"

local uiMgr = app.uiMgr

function MurderStoryMeditaor:ctor(params,  viewComponent )
    self.super:ctor(NAME,viewComponent)
    self.ctorArgs_ = checktable(params)
end

function MurderStoryMeditaor:InterestSignals()
    local signals = {
        POST.MURDER_STORY_UNLOCK.sglName
    }
    return signals
end

function MurderStoryMeditaor:ProcessSignal( signal )
    local name = signal:GetName()
    local body = signal:GetBody() or {}
    if POST.MURDER_STORY_UNLOCK.sglName == name then
        local requestData = body.requestData or {}
        local groupIndex = requestData.groupIndex
        local storyIndex = requestData.storyIndex
        local groupData   = self.datas[groupIndex] or {}
        local storyDatas  = groupData.storyDatas or {}
        local data        = storyDatas[storyIndex] or {}
        data.isNotUnlocked = nil
        app.murderMgr:UnlockStory(requestData.storyId)
    end
end

function MurderStoryMeditaor:Initial( key )
    self.super:Initial(key)
    
    self.datas = {}
    self.curSelectGroupIndex = 1

    local viewComponent  = require('Game.views.activity.murder.MurderStoryView').new()
    self.viewData_      = viewComponent:getViewData()
    self:SetViewComponent(viewComponent)
    display.commonUIParams(viewComponent, {ap = display.CENTER, po = display.center})

    self.ownerScene_ = uiMgr:GetCurrentScene()
    self:getOwnerScene():AddDialog(viewComponent)
    local homedata = app.murderMgr:GetHomeData()
    self:initGroupData_(homedata or {})
    self:initView_()

end

-------------------------------------------------
-- private method

function MurderStoryMeditaor:initGroupData_(homeData)
    local serPlotPointRewards = {}
    -- 时钟解锁剧情
    local clockStoryUnlockState = {}
    local clockConfig = CommonUtils.GetConfigAllMess('building', 'newSummerActivity') or {}
    local clockLevel = app.murderMgr:GetClockLevel()
    for k, v in pairs(clockConfig) do
        if checkint(k) < clockLevel then
            clockStoryUnlockState[tostring(v.storyId1)] = v.storyId1
            if v.storyId2 and v.storyId2 ~= '' then
                clockStoryUnlockState[tostring(v.storyId2)] = v.storyId2
            end
        elseif checkint(k) == clockLevel then
            -- 当前等级时钟等级需要判断boss是否通过
            clockStoryUnlockState[tostring(v.storyId1)] = v.storyId1
            if app.murderMgr:IsStoryUnlock(v.storyId2) then
                clockStoryUnlockState[tostring(v.storyId2)] = checkint(v.storyId2)
            end
        end
    end
    -- 基础剧情
    local paramConfig = CommonUtils.GetConfig('newSummerActivity', 'param', 1) or {}
    if paramConfig.story1 then -- 首次进入剧情
        clockStoryUnlockState[tostring(paramConfig.story1)] = paramConfig.story1
    end
    if clockLevel >= 1 or app.murderMgr:UnlockStory(checkint(paramConfig.story2)) then
        clockStoryUnlockState[tostring(paramConfig.story2)] = paramConfig.story2
    end
    -- 通过点数 检查剧情是否解锁
    local curPoint = nil    
    -- 通过服务端缓存数据 检查剧情是否解锁
    local serStory = homeData.unlockStoryInfo or {}
    local serUnlockStory = {}
    for i, v in ipairs(serStory) do
        serUnlockStory[tostring(v)] = v
    end
    for i, v in pairs(serUnlockStory) do
        if checkint(paramConfig.story3) == v or checkint(paramConfig.story4) == v then
            clockStoryUnlockState[tostring(v)] = checkint(v)
        end
    end
    local plotConfs = CommonUtils.GetConfigAllMess('storyDamagePoint', 'newSummerActivity') or {}
    local plotTable = {}
    for index, value in pairs(plotConfs) do
        plotTable[tostring(value.storyId)] = value
    end

    local storyCollectConfs = CommonUtils.GetConfigAllMess('branchStoryCollection', 'newSummerActivity') or {}

    local groupDatas = {}
    local groupIds = {}
    for i, storyCollectConf in orderedPairs(storyCollectConfs) do
        local storyId   = tostring(storyCollectConf.storyId)
        local chapterId = storyCollectConf.chapterId
        if groupDatas[chapterId] == nil then
            groupDatas[chapterId] = {}
            groupDatas[chapterId].storyCount = 0
            groupDatas[chapterId].unlockStoryCount = 0
            groupDatas[chapterId].groupId = chapterId
            groupDatas[chapterId].storyDatas = {}
            -- todo 获取 配表数据
            local chapterName = storyCollectConf.chapterName
            groupDatas[chapterId].groupConfData = {name = chapterName, title = chapterName, descr = chapterName}
            table.insert(groupIds, chapterId)
        end
        groupDatas[chapterId].storyCount = groupDatas[chapterId].storyCount + 1
        table.insert(groupDatas[chapterId].storyDatas, {
            storyConfData = storyCollectConf
        })

        local plotData = plotTable[storyId]
        local isUnlocked = serUnlockStory[storyId]
        
        if plotData then
            local goodsId  = app.murderMgr:GetPointGoodsId()
            local goodsNum = plotData.targetNum
            if curPoint == nil then
                curPoint = app.murderMgr:GetPointNum()
            end
            if curPoint >= checkint(goodsNum) then
                groupDatas[chapterId].storyDatas[groupDatas[chapterId].storyCount].unlockStoryId = storyId
                groupDatas[chapterId].storyDatas[groupDatas[chapterId].storyCount].isNotUnlocked = not isUnlocked
                groupDatas[chapterId].unlockStoryCount = groupDatas[chapterId].unlockStoryCount + 1
            end
        else 
            if clockStoryUnlockState[tostring(storyId)] then
                groupDatas[chapterId].storyDatas[groupDatas[chapterId].storyCount].unlockStoryId = storyId
                groupDatas[chapterId].unlockStoryCount = groupDatas[chapterId].unlockStoryCount + 1
            end
        end
    end

    table.sort(groupIds, function (a, b)
        return checkint(a) < checkint(b)
    end)
    
    self.datas = {}
    for i, chapterId in ipairs(groupIds) do
        table.insert(self.datas, groupDatas[chapterId])
    end
end

function MurderStoryMeditaor:initView_()
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

function MurderStoryMeditaor:groupTableViewwDataAdapter(p_convertview, idx )
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
        self:GetViewComponent():updateGroupCell(viewData, data, app.murderMgr:GetResPath(string.format("ui/home/activity/murder/plotIcon/murder_plot_icon_%s", checkint(data.groupId))))
        self:GetViewComponent():updateGroupCellBg(viewData, self.curSelectGroupIndex == index)
        viewData.touchView:setTag(index)
    end,__G__TRACKBACK__)
    return pCell
end

function MurderStoryMeditaor:storyTableViewDataAdapter(p_convertview, idx )
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

function MurderStoryMeditaor:onClickGroupCellAction(sender)
    local tag  = sender:getTag()

    local viewComponent = self:GetViewComponent()
    viewComponent:updateGroupBgByIndex(self.curSelectGroupIndex, false)
    viewComponent:updateGroupBgByIndex(tag, true)

    self.curSelectGroupIndex = tag
    local data = self.datas[tag] or {}
    viewComponent:updateStoryList(data.storyDatas or {})

end

function MurderStoryMeditaor:onClickStoryCellAction(sender)
    local tag = sender:getTag()
    -- todo 进入剧情
    local groupData   = self.datas[self.curSelectGroupIndex] or {}
    local storyDatas  = groupData.storyDatas or {}
    local data        = storyDatas[tag] or {}
    local unlockStoryId = data.unlockStoryId
    local isNotUnlocked = data.isNotUnlocked
    if unlockStoryId then
        local path = string.format("conf/%s/newSummerActivity/story.json",i18n.getLang())
        local stage = require( "Frame.Opera.OperaStage" ).new({id = unlockStoryId, path = path, guide = false, isHideBackBtn = true, cb = function ()
            -- play bg music
            PlayBGMusic(app.murderMgr:GetBgMusic(AUDIOS.GHOST.Food_ghost_dancing.id))

            if isNotUnlocked ~= nil and isNotUnlocked ~= false then
                self:SendSignal(POST.MURDER_STORY_UNLOCK.cmdName , {
                    storyId = unlockStoryId, groupIndex = self.curSelectGroupIndex, storyIndex = tag
                })
            end
        end})
        stage:setPosition(cc.p(display.cx, display.cy))
        sceneWorld:addChild(stage, GameSceneTag.Dialog_GameSceneTag)
    else
        local conf = data.storyConfData or {}
        uiMgr:ShowInformationTips(tostring(conf.resume))
    end

end

function MurderStoryMeditaor:onCloseAction(sender)
    app:UnRegsitMediator(NAME)
end

-------------------------------------------------
-- get / set

function MurderStoryMeditaor:getViewData()
    return self.viewData_
end

function MurderStoryMeditaor:getOwnerScene()
    return self.ownerScene_
end

function MurderStoryMeditaor:cleanupView()
    local viewComponent = self:GetViewComponent()
    if self.ownerScene_ and viewComponent and not tolua.isnull(viewComponent) then
        self.ownerScene_:RemoveDialog(viewComponent)
        self.ownerScene_ = nil
    end
end

function MurderStoryMeditaor:OnRegist()
    regPost(POST.MURDER_STORY_UNLOCK)
end

function MurderStoryMeditaor:OnUnRegist()
    self:cleanupView()
end

return MurderStoryMeditaor
